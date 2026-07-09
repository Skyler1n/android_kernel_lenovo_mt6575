#include <linux/kernel.h>
#include <linux/interrupt.h>
#include <linux/wakelock.h>
#include <linux/module.h>
#include <asm/delay.h>
#include <linux/device.h>
#include <linux/platform_device.h>
#include <linux/gfp.h>
#include <asm/io.h>
#include <asm/memory.h>
#include <asm/outercache.h>
#include <linux/spinlock.h>

#include <linux/leds-mt65xx.h>
#include "mach/ca9_slt.h"

/*
README:
    Modify 'CONFIG_MAX_DRAM_SIZE_SUPPORT' in 'mediatek/config/mt6575/autoconfig/kconfig/platform' to reserve a region
    mt6575_fixup() in mediatek/platform/mt6575/kernel/core/mt6575_devs.c reference this CONFIG_MAX_DRAM_SIZE_SUPPORT
*/
//#define __SLT_USE_GFP__
#if defined(SLT_LOOP_CNT)
static unsigned int g_Max_PWR_PASS_CNT = 0;
#elif defined(SLT_LOOP_LED)
static unsigned int g_LED_DELAY_SPEED = SLT_LOOP_LED;
#endif

extern int max_power_loop(void);
extern int my_get_ttbcr(void);
extern int speed_indicative_loop(void);

#if !defined(__SLT_USE_GFP__)
static unsigned int g_TestMem[4 * 1024 / sizeof(unsigned int)];
#endif
static unsigned int g_pTestMem = 0;   // must be 4KB aligned, WBWA normal memory
static int g_iFinalResult;
static int g_iPassFail;

int g_iADDR1, g_iADDR2, g_iADDR3, g_iADDR4, g_iADDR5, g_iADDR6, g_iADDR7, g_iADDR8;
int g_iDATA1, g_iDATA5, g_iDATA6;

int ca9_speed_test(void)
{
    spinlock_t lock;
    unsigned long flags;

    int ResultR0, ResultR1, iResult;
    const int ResultR2 = 0x55555555;
    const int ResultR3 = 0x55555555;
    const int ResultR4 = 0xFAFAFAFB;
    const int ResultR10 = 0x5F5F5F60;

    spin_lock_irqsave(&lock, flags);

#if !defined(__SLT_USE_GFP__)
    g_pTestMem = (unsigned int) g_TestMem;
#else
    // set 4KB-page pointed to by g_pTestMem to L1C WBWA, L2C NC
    if (slt_get_section(0) == 0) {
        return 0;
    }

    g_pTestMem = SLT_VA;
#endif

    g_iADDR1 = g_pTestMem + 128;
    g_iADDR2 = g_iADDR1 + 128;
    g_iADDR3 = g_iADDR2 + 128;
    g_iADDR4 = g_iADDR3 + 128;
    g_iADDR5 = g_iADDR4 + 128;
    g_iADDR6 = g_iADDR5 + 128;
    g_iADDR7 = g_iADDR6 + 128;
    g_iADDR8 = g_iADDR7 + 128;

    ResultR0 = g_iADDR1 + 8;
    ResultR1 = g_iADDR2 + 8;

    g_iFinalResult = ResultR0 + ResultR1 + ResultR2 + ResultR3 + ResultR4 + ResultR10;

    iResult = max_power_loop();
 
    if(iResult == g_iFinalResult)
    {
        g_iDATA1 = g_pTestMem;
        g_iDATA5 = g_iDATA1 + 8192;
        g_iDATA6 = g_iDATA5 + 8192;
        
        iResult = speed_indicative_loop();
    }
    else 
        iResult = 0;

#if defined(__SLT_USE_GFP__)
    // restore MMU attributes of the section pointed to by g_pTestMem to Linux original setting
    slt_free_section();
#endif

    spin_unlock_irqrestore(&lock, flags);

    return iResult;
}

static struct device_driver slt_ca9_max_power_drv =
{
    .name = "ca9_max_power",
    .bus = &platform_bus_type,
    .owner = THIS_MODULE,
};

static ssize_t slt_ca9_max_power_show(struct device_driver *driver, char *buf)
{
#if defined(SLT_LOOP_CNT)
    return snprintf(buf, PAGE_SIZE, "CA9_MAX_POWER - %s\n", g_Max_PWR_PASS_CNT != SLT_LOOP_CNT ? "FAIL" : "PASS");
#elif defined(SLT_LOOP_LED)
    return snprintf(buf, PAGE_SIZE, "CA9_MAX_POWER(SLT_LOOP_LED) - %s\n", g_iPassFail != g_LED_DELAY_SPEED ? "FAIL" : "PASS");
#else
    return snprintf(buf, PAGE_SIZE, "%d\n", g_iPassFail);
#endif
}

static ssize_t slt_ca9_max_power_store(struct device_driver *driver, const char *buf, size_t count)
{
#if defined(SLT_LOOP_CNT)
    unsigned int i;

    g_Max_PWR_PASS_CNT = 0;

    for (i = 0; i < SLT_LOOP_CNT; i++) {
        g_Max_PWR_PASS_CNT += ca9_speed_test();
    }

    return count;
#elif defined(SLT_LOOP_LED)
    int i;

    mt65xx_leds_brightness_set(MT65XX_LED_TYPE_RED, 255);

    for (i = 0, g_iPassFail = 0; i < g_LED_DELAY_SPEED; i++) {
        g_iPassFail += ca9_speed_test();
    }

    if (g_iPassFail == g_LED_DELAY_SPEED) {
        printk("\n>> CPU speed test(SLT_LOOP_LED) - PASS <<\n\n"); 
    }else {
        printk("\n>> CPU speed test(SLT_LOOP_LED) - FAIL <<\n\n"); 

        mt65xx_leds_brightness_set(MT65XX_LED_TYPE_RED, 0);

        while (1);
    }

    return count;
#else
    g_iPassFail = ca9_speed_test();

    if (g_iPassFail == 1) {
        printk("\n>> CPU speed test - PASS <<\n\n"); 
    }else {
        printk("\n>> CPU speed test - FAIL <<\n\n"); 
    }

    return count;
#endif
}

DRIVER_ATTR(slt_ca9_max_power, 0644, slt_ca9_max_power_show, slt_ca9_max_power_store);

int __init slt_ca9_max_power_init(void)
{
    int ret;

    g_iPassFail = 0;

    ret = driver_register(&slt_ca9_max_power_drv);
    if (ret) {
        printk("fail to create CA9 max power SLT driver\n");
    }

    ret = driver_create_file(&slt_ca9_max_power_drv, &driver_attr_slt_ca9_max_power);
    if (ret) {
        printk("fail to create CA9 max power sysfs files\n");
    }

    return 0;
}

arch_initcall(slt_ca9_max_power_init);
