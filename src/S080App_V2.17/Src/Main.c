/********************* (C) COPYRIGHT 2017 e-Design Co.,Ltd. ********************
File Name :      main.c
Version :        TS080 APP 1.02
Description:
Author :         Ning
Data:            2017/11/06
History:
2017/10/09       ��ͬ״̬��ѡ��ͬ��ѹ��
2017/10/16       ��ʼ������ʱ��
2017/11/24       ���ټ�Ӳ���ж�;
*******************************************************************************/
#include <string.h>
#include <stdio.h>
#include "APP_Version.h"
#include "Disk.h"
#include "Bios.h"
#include "USB_lib.h"
#include "I2C.h"
#include "Flash.h"
#include "MMA8652FC.h"
#include "UI.h"
#include "OLed.h"
#include "CTRL.h"
#include "HARDWARE.h"
#include "string.h"
extern u32 slide_data;
extern u8  MarkAd_pos;

u32 Resistance = 0;//����
/*******************************************************************************
������: main
��������:��ѭ��
�������:NULL
���ز���:NULL
*******************************************************************************/
void main(void)
{
    RCC_Config();
    NVIC_Config(0x4000);
    Init_Timer3();
    GPIO_Config();
    USB_Port(DISABLE);
    Delay_Ms(200);
    USB_Port(ENABLE);
    USB_Init();
    I2C_Configuration();
    Ad_Init();
    Is_ST_LIS2DH12();//���ټ��ж�
    StartUp_Accelerated();
    System_Init();
    Disk_BuffInit();
    Config_Read();//��������U��
    Init_Gtime();
    APP_Init();//����״̬��ʼ��
    Init_Oled();
    Clear_Screen();

    Pid_Init();
    Start_Watchdog(3000);
    Set_CurLimit(MAX_VOL, MIN_VOL); //���õ�ѹ���Ź�
    GPIO_Vol_Init(1);
    Vol_Set(0);
    Init_Timer2();
    GPIO_Vol_Init(0);
    Set_LongKeyFlag(1);
    Get_gKey();  //dummy read
    while (1)
    {
        Clear_MMA_INT();
        Clear_Watchdog();
        Status_Tran();                              //���ݵ�ǰ״̬����ϰ��������ʱ��ת��
    }
}
/******************************** END OF FILE *********************************/
