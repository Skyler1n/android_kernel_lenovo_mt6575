#include <linux/kernel.h>
#include <linux/interrupt.h>
#include <linux/wakelock.h>
#include <linux/module.h>
#include <asm/delay.h>
#include <linux/device.h>
#include <linux/platform_device.h>

#include <linux/leds-mt65xx.h>
#include "mach/ca9_slt.h"

#if defined(SLT_LOOP_CNT)
static unsigned int g_Max_L2C_PASS_CNT = 0;
#elif defined(SLT_LOOP_LED)
static unsigned int g_LED_DELAY_L2C = SLT_LOOP_LED;
#endif

/*
* L2C has 16KB in each way and 16KB test range can ensure
* some 16KB full-set of lines, maybe in different ways,
* to be toggled.
*/
#define L2C_TEST_SIZE   (16 * 1024)

#if !defined(__SLT_USE_GFP__)
static unsigned int g_l2cTest[L2C_TEST_SIZE / sizeof(unsigned int)];
#endif

static unsigned int *g_l2cMem;
static int g_iL2CPassFail;

void config_mem_l2cacheability(void)
{
    // set the whole range to inner-noncacheable & outer-WB-WA
#if defined(__SLT_USE_GFP__)
    // restore 4KB-page pointed to by g_pTestMem to L1C NC, L2C WBWA
    slt_get_section(1);
#endif
}

void restore_mem_l2cacheability(void)
{
#if defined(__SLT_USE_GFP__)
    // restore MMU attributes of the section pointed to by g_pTestMem to Linux original setting
    slt_free_section();
#endif
}

static unsigned int l2c_test(void)
{
    unsigned int iI;

#if defined(__SLT_USE_GFP__)
    g_l2cMem = (unsigned int *) SLT_VA;
#else
    g_l2cMem = g_l2cTest;
#endif

    // set 4KB-page pointed to by g_l2cMem to L1C NC, L2C WBWA
    config_mem_l2cacheability();

    for (iI = 0; iI < L2C_TEST_SIZE / sizeof(unsigned int); iI++) {
        g_l2cMem[iI] = iI;  // pMem is L2 WB-WA cachable region, this will WA a cacheline in L2 cache

        if (g_l2cMem[iI] != iI) {
            return 0;   // fail
        }
    }

    // restore 4KB-page pointed to by g_l2cMem to L1C NC, L2C WBWA
    restore_mem_l2cacheability();

    return 1;   // pass
}

static struct device_driver slt_ca9_l2c_drv =
{
    .name = "ca9_l2c_test",
    .bus = &platform_bus_type,
    .owner = THIS_MODULE,
};

static ssize_t slt_ca9_l2c_test_show(struct device_driver *driver, char *buf)
{
#if defined(SLT_LOOP_CNT)
    return snprintf(buf, PAGE_SIZE, "CA9_L2C - %s\n", g_Max_L2C_PASS_CNT != SLT_LOOP_CNT ? "FAIL" : "PASS");
#elif defined(SLT_LOOP_LED)
    return snprintf(buf, PAGE_SIZE, "CA9_L2C(SLT_LOOP_LED) - %s\n", g_iL2CPassFail != g_LED_DELAY_L2C ? "FAIL" : "PASS");
#else
    return snprintf(buf, PAGE_SIZE, "%d\n", g_iL2CPassFail);
#endif
}

static ssize_t slt_ca9_l2c_test_store(struct device_driver *driver, const char *buf, size_t count)
{
#if defined(SLT_LOOP_CNT)
    int i;

    g_Max_L2C_PASS_CNT = 0;

    for (i = 0; i < SLT_LOOP_CNT; i++) {
        g_Max_L2C_PASS_CNT += l2c_test();  // 1: PASS, 0:Fail
    }

    return count;
#elif defined(SLT_LOOP_LED)
    int i;

    mt65xx_leds_brightness_set(MT65XX_LED_TYPE_RED, 0);

    for (i = 0, g_iL2CPassFail = 0; i < g_LED_DELAY_L2C; i++) {
        g_iL2CPassFail += l2c_test();  // 1: PASS, 0:Fail
    }

    if (g_iL2CPassFail == g_LED_DELAY_L2C) {
        printk("\n>> CA9 L2C test(SLT_LOOP_LED) - PASS <<\n");
    }else {
        printk("\n>> CA9 L2C test(SLT_LOOP_LED) - FAIL <<\n");

        while (1);
    }

    return count;
#else
    g_iL2CPassFail = l2c_test();  // 1: PASS, 0:Fail

    if (g_iL2CPassFail == 1) {
        printk("\n>> CA9 L2C test - PASS <<\n");
    }else {
        printk("\n>> CA9 L2C test - FAIL <<\n");
    }

    return count;
#endif
}

DRIVER_ATTR(slt_ca9_l2c, 0644, slt_ca9_l2c_test_show, slt_ca9_l2c_test_store);

int __init slt_ca9_l2c_test_init(void)
{
    int ret;

    g_iL2CPassFail = 0;

    ret = driver_register(&slt_ca9_l2c_drv);
    if (ret) {
        printk("fail to create CA9 L2C SLT driver\n");
    }

    ret = driver_create_file(&slt_ca9_l2c_drv, &driver_attr_slt_ca9_l2c);
    if (ret) {
        printk("fail to create CA9 L2C SLT sysfs files\n");
    }

    return 0;
}

arch_initcall(slt_ca9_l2c_test_init);
