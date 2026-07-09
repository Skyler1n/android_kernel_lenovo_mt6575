#include <linux/kernel.h>
#include <linux/interrupt.h>
#include <linux/wakelock.h>
#include <linux/module.h>
#include <asm/delay.h>
#include <linux/device.h>
#include <linux/platform_device.h>
#include <linux/spinlock.h>

#include <linux/leds-mt65xx.h>
#include "mach/ca9_slt.h"

#if defined(SLT_LOOP_CNT)
static unsigned int g_Max_NEON_PASS_CNT = 0;
#elif defined(SLT_LOOP_LED)
static unsigned int g_LED_DELAY_NEON = SLT_LOOP_LED;
#endif

int g_iDATA2;

static const unsigned int NEON_TEST_PATTERN[] = {
0x46B94BFB,
0x1C667E81,
0xFF6ABDDF,
0x9E2CFB54,
0x487201BF,
0x37CF1CE1,
0x37200F47,
0x2313DE56,
0x359DAA88,
0xC6756687,
0x6561137B,
0x73CF59EA,
0x9D853C54,
0x1D2D85A1,
0xAAEE655B,
0xD5502F37,
0x3988CCE3,
0x3DA10279,
0xA5F8D999,
0xF1AB768E,
0xF368EE43,
0x88F51F3F,
0x3FAFBEA6,
0xF78E4D0D,
0x48E2DC29,
0xDDA0E486,
0xF56BE170,
0xC6D34EFF,
0x4B135805,
0x6206FB8F,
0xDDCB53CD,
0x690DC509,
0x799452D3,
0x3AA73B48,
0xA9F1EAB5,
0x152E9D06,
0xB98949B2,
0x6C2C0613,
0xE3228831,
0x00171EAC,
0xA95E7136,
0x29C75246,
0xA3951D16,
0x38FD57F6,
0x8F5E987C,
0xCFA38874,
0x0BBD6D71,
0xD1765C41,
0x2593C701,
0xC8EC0F70,
0xB3D691C0,
0x91BA2F33,
0x80D6AB33,
0xA1D1A50D,
0x58F73EE6,
0x78D57E5E,
0x53A0B1C3,
0x868E74A6,
0x0642C7DB,
0x493D11A8,
0xCE14F3BF,
0x6CADE060,
0xFA2AE325,
0x60970067
};

#define __SLT_USE_GFP__

unsigned int g_NeonTestMem;

#if !defined(__SLT_USE_GFP__)
unsigned int g_NeonTestRegion[8 * 1024 / sizeof(unsigned int)];
#endif

extern int ca9_neon(void);
extern int ca9_neon_indicative(void);
static unsigned int g_iNeonPassFail;

int init_ca9_neon_data(unsigned int *pAddr)
{
    unsigned int i;

    if (((unsigned int) pAddr) % 64 != 0) {
        printk("[init_ca9_neon_data(): parameter not 64B aligned !]\n");

        return 0;
    }

    for (i = 0; i < sizeof(NEON_TEST_PATTERN) / sizeof(NEON_TEST_PATTERN[0]); i++) {
        pAddr[i] = NEON_TEST_PATTERN[i];
    }

    return 1;
}

int ca9_neon_test(void)
{
    int iV;
    spinlock_t lock;
    unsigned long flags;

    spin_lock_irqsave(&lock, flags);

#if !defined(__SLT_USE_GFP__)
    g_NeonTestMem = (unsigned int) g_NeonTestRegion;

    g_NeonTestMem = (g_NeonTestMem + 63) / 64 * 64;
#else
    g_NeonTestMem = SLT_VA;

    // set 4KB-page pointed to by g_NeonTestMem to L1C WBWA, L2C NC
    if (slt_get_section(0) == 0) {
        return 0;
    }
#endif

    g_iDATA2 = g_NeonTestMem + 2048;
    if (init_ca9_neon_data((unsigned int *) g_NeonTestMem) == 0) {
        printk("\n>> [init_ca9_neon_data(): fail !] <<\n");

        return -1;
    }

    iV = ca9_neon();
    if (iV == 1)
    {
        iV = ca9_neon_indicative();
    }

#if defined(__SLT_USE_GFP__)
    // restore MMU attributes of the section pointed to by g_pTestMem to Linux original setting
    slt_free_section();
#endif

    spin_unlock_irqrestore(&lock, flags);

    return iV;
}

static struct device_driver slt_ca9_neon_drv =
{
    .name = "ca9_neon",
    .bus = &platform_bus_type,
    .owner = THIS_MODULE,
};

static ssize_t slt_ca9_neon_show(struct device_driver *driver, char *buf)
{
#if defined(SLT_LOOP_CNT)
    return snprintf(buf, PAGE_SIZE, "CA9_NEON - %s\n", g_Max_NEON_PASS_CNT != SLT_LOOP_CNT ? "FAIL" : "PASS");
#elif defined(SLT_LOOP_LED)
    return snprintf(buf, PAGE_SIZE, "CA9_NEON(SLT_LOOP_LED) - %s\n", g_iNeonPassFail == g_LED_DELAY_NEON ? "PASS" : "FAIL");
#else
    return snprintf(buf, PAGE_SIZE, "%d\n", g_iNeonPassFail);
#endif
}

static ssize_t slt_ca9_neon_store(struct device_driver *driver, const char *buf, size_t count)
{
#if defined(SLT_LOOP_CNT)
    int i;

    g_Max_NEON_PASS_CNT = 0;

    for (i = 0; i < SLT_LOOP_CNT; i++) {
        g_Max_NEON_PASS_CNT += ca9_neon_test();
    }

    return count;
#elif defined(SLT_LOOP_LED)
    int i;

    mt65xx_leds_brightness_set(MT65XX_LED_TYPE_RED, 255);

    for (i = 0, g_iNeonPassFail = 0; i < g_LED_DELAY_NEON; i++) {
        g_iNeonPassFail += ca9_neon_test();  // 1: PASS, 0:Fail
    }

    if (g_iNeonPassFail == g_LED_DELAY_NEON) {
        printk("\n>> CA9 NEON test(SLT_LOOP_LED) - PASS <<\n");
    }else {
        printk("\n>> CA9 NEON test(SLT_LOOP_LED) - FAIL <<\n");

        mt65xx_leds_brightness_set(MT65XX_LED_TYPE_RED, 0);

        while (1);
    }

    return count;
#else
    g_iNeonPassFail = ca9_neon_test();  // 1: PASS, 0:Fail

    if (g_iNeonPassFail == 1) {
        printk("\n>> CA9 NEON test - PASS <<\n");
    }else {
        printk("\n>> CA9 NEON test - FAIL <<\n");
    }

    return count;
#endif
}

DRIVER_ATTR(slt_ca9_neon, 0644, slt_ca9_neon_show, slt_ca9_neon_store);

int __init slt_ca9_neon_init(void)
{
    int ret;

    g_iNeonPassFail = 0;

    ret = driver_register(&slt_ca9_neon_drv);
    if (ret) {
        printk("fail to create CA9 NEON SLT driver\n");
    }

    ret = driver_create_file(&slt_ca9_neon_drv, &driver_attr_slt_ca9_neon);
    if (ret) {
        printk("fail to create CA9 NEON SLT sysfs files\n");
    }

    return 0;
}

arch_initcall(slt_ca9_neon_init);
