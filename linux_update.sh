#!/bin/bash
set -euo pipefail

usage() {
	echo " Usage: $0 <HEXFILE> [UUID:$UUID]"
	echo
	echo 'HEXFILE is the firmware to flash onto the device'
	echo 'UUID specifies the expected device disk UUID'
	echo '	The UUID may differ for other devices. '
	echo '	Execute `lsblk --output NAME,LABEL,UUID,VENDOR,MODEL,MOUNTPOINT` to discover'
	echo
	echo 'Requires jq [https://stedolan.github.io/jq/]'
	[ ! -z ${1:-} ] && {
		exit $1
	}
}

FIRMWARE=${1:-}

# Block device values
UUID="${2:-6CE4-98A2}" # Consistent across normal and boot modes
MODEL_NORM='Disk            ' # Normal mode
MODEL_BOOT='DFU Disk        ' # Bootloader mode
LABEL='BFD096DB'  # Only in bootloader mode
VENDOR_NORM='Mini DSO' # Normal mode
VENDOR_BOOT='Virtual ' # Bootloader mode

# Other constants
HEX_FILE_BASE='ts80'
HEX_FILE="${HEX_FILE_BASE}.hex"


# boot mode strings
MODE_DC='disconnected'
MODE_BOOT='bootloader'
MODE_NORM='normal'

check_dependencies() {
	[ -z "$(which jq)" ] && {
		>&2 echo 'Requires `jq`'
		>&2 echo 'https://stedolan.github.io/jq/'
		exit 1
	}
	true # I don't know why this is needed, but it doesn't work without it
}

device_info() {
	# lsblk -JO | jq '.blockdevices[] | select(.model | startswith("DFU Disk"))'
	lsblk -JO | jq --arg uuid "$UUID" '.blockdevices[] | select(.uuid == $uuid)'
}

get_mount_point() {
	device_info | jq -r 'if .mountpoint == null then "" else .mountpoint end'
}

device_mode() {
	local DEV_INFO=$(device_info)
	[ -z "$DEV_INFO" ] && {
		echo "$MODE_DC"
		return 0
	}
	[ -z "$(jq --arg model "$MODEL_BOOT" 'select(.model == $model)' <<< "$DEV_INFO")" ] && {
		echo "$MODE_NORM"
		return 0
	}
	echo "$MODE_BOOT"
}

mount_device() {
	local MOUNT_POINT=$(get_mount_point)
	>&2 echo "Currently mounted to: $MOUNT_POINT"
	[ ! -z  "$MOUNT_POINT" ] && {
		sudo umount "$MOUNT_POINT"
	}
	local DEVICE="/dev/$(device_info | jq -r '.name')"
	sudo mount -t msdos -o uid=$UID "$DEVICE" "$DIR_TEMP"
}

cleanup() {
	[ -d "$DIR_TEMP" ] && {
		>&2 echo "cleanup $DIR_TEMP"
		sudo umount "$DIR_TEMP" || true
		rmdir "$DIR_TEMP" || true
	}
}

check_file() {
	[ -z "$1" ] && {
		>&2 echo "Firmware file is required"
		>&2 usage 1
	}

	[ ! -f "$1" ] && {
		>&2 echo "Could not find firmware file or it is not a regular file"
		>&2 usage 1
	}

	[ -z "$(grep -vP '^:' "$1")" ] || {
		>&2 echo "Firmware file does not appear to be a valid hex file"
		>&2 usage 1
	}
}

automount_enabled() {
	[ -z "$(which gsettings)" ] && {
		return 1
	}
	local GAUTOMOUNT=$(gsettings get org.gnome.desktop.media-handling automount)
	[ "$GAUTOMOUNT" == "true" ] && {
		return 0
	}
	return 1
}

wait_for_device() {
	[ -z "${1:-}" ] && {
		>&2 echo
		>&2 echo "######################################"
		>&2 echo "#         Waiting for device         #"
		>&2 echo "#                                    #"
		>&2 echo "# Connect the device with the button #"
		>&2 echo "#     closest to the tip pressed     #"
		>&2 echo "######################################"
		>&2 echo
	}
	while [ "$(device_mode)" != "$MODE_BOOT" ]; do
		sleep 0.2
	done
}


main() {
	check_dependencies
	check_file "$FIRMWARE"
	>&2 echo "Selected file: $FIRMWARE"

	# check for bootloader mode
	wait_for_device
	>&2 echo "device found"

	# mount the device
	>&2 echo "Attempting to mount device"
	mount_device

	# copy the firmware file to the device
	local DESTINATION="${DIR_TEMP}/${HEX_FILE}"
	cp "$FIRMWARE" "$DESTINATION"
	sync

	# the device should reboot when completed
	while [ -f "$DESTINATION" ]; do
		>&2 echo "----- $(date) -----"
		sleep 1
	done

	# wait for the device to come back up
	>&2 echo "complete: waiting for device..."
	wait_for_device 1

	# mount if automount is not enabled
	automount_enabled || {
		mount_device
	}

	# wait for mount to complete
	while [ -z "$(get_mount_point)" ]; do sleep 1; done
	>&2 echo "new mount point: $(get_mount_point)"

	# print the status files
	ls -1 "$(get_mount_point)" | grep -v 'System Volume Information'
}

#  ----------------------------
#  ----------------------------
# Last mile config and execute
#  ----------------------------
#  ----------------------------

# Create mount directory
DIR_TEMP=$(mktemp -d)
trap cleanup EXIT

main
