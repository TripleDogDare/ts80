/********************* (C) COPYRIGHT 2017 e-Design Co.,Ltd. ********************
File Name :      main.c
Version :        TS080 APP 1.02
Description:
Author :         Ning
Data:            2017/11/06
History:
2017/10/09       不同状态下选择不同电压；
2017/10/16       初始化待机时间
2017/11/24       加速计硬件判断;
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
extern u8 MarkAd_pos;

u32 Resistance = 0;//内阻
/*******************************************************************************
函数名: main
函数作用:主循环
输入参数:NULL
返回参数:NULL
*******************************************************************************/
void main(void)
{
    RCC_Config();                       //时钟初始化
    NVIC_Config(0x4000);                //中断初始化
    Init_Timer3();                      //初始化定时器3
    GPIO_Config();                      //配置GPIO
    GPIO_Vol_Init(1);                   //电压控制脚初始化
    USB_Port(DISABLE);
    Delay_Ms(200);
    Vol_Set(0);
    GPIO_Vol_Init(0);                   //电压控制脚初始化
    USB_Port(ENABLE);
    USB_Init();                         //USB初始化
    I2C_Configuration();                //配置I2C
    Ad_Init();                          //初始化 AD
    Is_ST_LIS2DH12();                   //加速计判断
    StartUp_Accelerated();              //设置Reg数据
    System_Init();                      //系统初始化
    Disk_BuffInit();                    //磁盘数据初始化
    Config_Read();                      //启动虚拟U盘
    Init_Gtime();                       //初始化计时器
    APP_Init();                         //开机状态初始化
    Init_Oled();                        //初始化LED设置
    Clear_Screen();
    Pid_Init();                         //PID数据初始化
    Start_Watchdog(3000);               //初始化开门狗
    Set_CurLimit(MAX_VOL, MIN_VOL);     //配置电压看门狗
    Init_Timer2();                      //初始化定时器2
    Set_LongKeyFlag(1);                 //设置长按键标志
    
    Get_gKey();
    while (1)
    {
        Clear_MMA_INT();                //获取加速度传感器静动状态
        Clear_Watchdog();               //重置开门狗计数
        Status_Tran();                  //根据当前状态，配合按键与控制时间转换
    }
}
/******************************** END OF FILE *********************************/
