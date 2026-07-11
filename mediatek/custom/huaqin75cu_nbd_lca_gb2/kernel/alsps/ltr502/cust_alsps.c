#include <linux/types.h>
#include <mach/mt6575_pm_ldo.h>
#include <cust_alsps.h>

/* Lenovo A60+ : LTR-502 ALS/PS (register-compatible with AL3006 driver).
 * I2C bus 0, 7-bit slave addr 0x3A (SEL->VDD).  Polling mode, matching the
 * official A60+ kernel behaviour. */
static struct alsps_hw cust_alsps_hw = {
    .i2c_num    = 0,
    .polling_mode = 1,
    .polling_mode_ps  = 1,
    .polling_mode_als = 1,
    .power_id   = MT65XX_POWER_NONE,
    .power_vol  = VOL_DEFAULT,
    .i2c_addr   = {0x3A, 0x00, 0x00, 0x00},
    /* LTR-502 ALS data is a 6-bit level (0..63) in reg0x05[5:0] */
    .als_level  = {  2,   4,   6,   9,  12,  16,  20,  25,  30,  36,  42,  48,  54,  59,   63},
    .als_value  = { 40,  40,  90,  90, 160, 225, 320, 640,1280,1280,2600,2600,5120,7680,10240,10240},
    .ps_threshold = 10,
    .als_window_loss = 0,
    .ps_threshold_high = 10,
    .ps_threshold_low  = 10,
};

struct alsps_hw *get_cust_alsps_hw(void)
{
    return &cust_alsps_hw;
}
