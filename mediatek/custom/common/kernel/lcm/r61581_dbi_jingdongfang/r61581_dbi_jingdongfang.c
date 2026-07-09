#include <linux/kernel.h>
#include <linux/string.h>

#include "lcm_drv.h"

#define FRAME_WIDTH  (320)
#define FRAME_HEIGHT (480)

static LCM_UTIL_FUNCS lcm_util = {0};

#define SET_RESET_PIN(v) (lcm_util.set_reset_pin((v)))
#define MDELAY(n)        (lcm_util.mdelay(n))

static __inline unsigned int HIGH_BYTE(unsigned int value)
{
    return (value >> 8) & 0xff;
}

static __inline unsigned int LOW_BYTE(unsigned int value)
{
    return value & 0xff;
}

static __inline void send_ctrl_cmd(unsigned int cmd)
{
    lcm_util.send_cmd(cmd);
}

static __inline void send_data_cmd(unsigned int data)
{
    lcm_util.send_data(data & 0xff);
}

static void set_addr_window(unsigned int x0, unsigned int y0,
                            unsigned int x1, unsigned int y1)
{
    send_ctrl_cmd(0x2A);
    send_data_cmd(HIGH_BYTE(x0));
    send_data_cmd(LOW_BYTE(x0));
    send_data_cmd(HIGH_BYTE(x1));
    send_data_cmd(LOW_BYTE(x1));

    send_ctrl_cmd(0x2B);
    send_data_cmd(HIGH_BYTE(y0));
    send_data_cmd(LOW_BYTE(y0));
    send_data_cmd(HIGH_BYTE(y1));
    send_data_cmd(LOW_BYTE(y1));
}

static void sw_fill_panel(unsigned int color)
{
    unsigned int i;

    set_addr_window(0, 0, FRAME_WIDTH - 1, FRAME_HEIGHT - 1);
    send_ctrl_cmd(0x2C);

    for (i = 0; i < FRAME_WIDTH * FRAME_HEIGHT; i++)
        lcm_util.send_data(color);
}

static void init_lcm_registers(void)
{
    send_ctrl_cmd(0xB0);
    send_data_cmd(0x1E);

    send_ctrl_cmd(0xB0);
    send_data_cmd(0x00);

    send_ctrl_cmd(0xB3);
    send_data_cmd(0x02);
    send_data_cmd(0x00);
    send_data_cmd(0x00);
    send_data_cmd(0x10);

    send_ctrl_cmd(0xB4);
    send_data_cmd(0x00);

    send_ctrl_cmd(0xC0);
    send_data_cmd(0x03);
    send_data_cmd(0x3B);
    send_data_cmd(0x00);
    send_data_cmd(0x00);
    send_data_cmd(0x00);
    send_data_cmd(0x01);
    send_data_cmd(0x00);
    send_data_cmd(0x43);

    send_ctrl_cmd(0xC1);
    send_data_cmd(0x08);
    send_data_cmd(0x15);
    send_data_cmd(0x08);
    send_data_cmd(0x08);

    send_ctrl_cmd(0xC4);
    send_data_cmd(0x15);
    send_data_cmd(0x03);
    send_data_cmd(0x03);
    send_data_cmd(0x01);

    send_ctrl_cmd(0xC6);
    send_data_cmd(0x02);

    send_ctrl_cmd(0xC8);
    send_data_cmd(0x0C);
    send_data_cmd(0x05);
    send_data_cmd(0x0A);
    send_data_cmd(0x6B);
    send_data_cmd(0x04);
    send_data_cmd(0x06);
    send_data_cmd(0x15);
    send_data_cmd(0x10);
    send_data_cmd(0x00);
    send_data_cmd(0x60);

    send_ctrl_cmd(0x36);
    send_data_cmd(0x0A);

    send_ctrl_cmd(0x0C);
    send_data_cmd(0x55);

    send_ctrl_cmd(0x3A);
    send_data_cmd(0x55);

    send_ctrl_cmd(0x38);

    send_ctrl_cmd(0xD0);
    send_data_cmd(0x07);
    send_data_cmd(0x07);
    send_data_cmd(0x14);
    send_data_cmd(0xA2);

    send_ctrl_cmd(0xD1);
    send_data_cmd(0x03);
    send_data_cmd(0x5A);
    send_data_cmd(0x10);

    send_ctrl_cmd(0xD2);
    send_data_cmd(0x03);
    send_data_cmd(0x04);
    send_data_cmd(0x04);

    send_ctrl_cmd(0x11);
    MDELAY(150);

    send_ctrl_cmd(0x13);
    MDELAY(20);

    set_addr_window(0, 0, FRAME_WIDTH - 1, FRAME_HEIGHT - 1);

    MDELAY(100);

    send_ctrl_cmd(0x29);
    MDELAY(30);

    send_ctrl_cmd(0x2C);
    MDELAY(30);
}

static void lcm_set_util_funcs(const LCM_UTIL_FUNCS *util)
{
    memcpy(&lcm_util, util, sizeof(LCM_UTIL_FUNCS));
}

static void lcm_get_params(LCM_PARAMS *params)
{
    memset(params, 0, sizeof(LCM_PARAMS));

    params->type   = LCM_TYPE_DBI;
    params->ctrl   = LCM_CTRL_PARALLEL_DBI;
    params->width  = FRAME_WIDTH;
    params->height = FRAME_HEIGHT;

    params->io_select_mode = 3;

    params->dbi.port                    = 0;
    params->dbi.clock_freq              = LCM_DBI_CLOCK_FREQ_52M;
    params->dbi.data_width              = LCM_DBI_DATA_WIDTH_18BITS;
    params->dbi.data_format.color_order = LCM_COLOR_ORDER_RGB;
    params->dbi.data_format.trans_seq   = LCM_DBI_TRANS_SEQ_MSB_FIRST;
    params->dbi.data_format.padding     = LCM_DBI_PADDING_ON_MSB;
    params->dbi.data_format.format      = LCM_DBI_FORMAT_RGB666;
    params->dbi.data_format.width       = LCM_DBI_DATA_WIDTH_18BITS;
    params->dbi.cpu_write_bits          = LCM_DBI_CPU_WRITE_32_BITS;
    params->dbi.io_driving_current      = LCM_DRIVING_CURRENT_6575_8MA;

    params->dbi.te_mode                 = LCM_DBI_TE_MODE_DISABLED;
    params->dbi.te_edge_polarity        = LCM_POLARITY_RISING;

    params->dbi.parallel.write_setup    = 1;
    params->dbi.parallel.write_hold     = 1;
    params->dbi.parallel.write_wait     = 3;
    params->dbi.parallel.read_setup     = 1;
    params->dbi.parallel.read_latency   = 31;
    params->dbi.parallel.wait_period    = 2;
    params->dbi.parallel.cs_high_width  = 0;

    printk("[A60_R61581] get_params: DBI parallel port=%u RGB666/18-bit 320x480 te=%u\n",
           params->dbi.port, params->dbi.te_mode);
}

static void lcm_init(void)
{
    printk("[A60_R61581] lcm_init: keep uboot panel registers\n");

    send_ctrl_cmd(0x13);
    MDELAY(20);
    send_ctrl_cmd(0x29);
    MDELAY(30);
    set_addr_window(0, 0, FRAME_WIDTH - 1, FRAME_HEIGHT - 1);
}

static void lcm_suspend(void)
{
    send_ctrl_cmd(0x28);
    MDELAY(20);
    send_ctrl_cmd(0x10);
    MDELAY(120);
}

static void lcm_resume(void)
{
    printk("[A60_R61581] lcm_resume\n");
    send_ctrl_cmd(0x11);
    MDELAY(150);
    send_ctrl_cmd(0x13);
    MDELAY(20);
    send_ctrl_cmd(0x29);
    MDELAY(30);
}

static void lcm_update(unsigned int x, unsigned int y,
                       unsigned int width, unsigned int height)
{
    static unsigned int update_count;
    unsigned int x0 = x;
    unsigned int y0 = y;
    unsigned int x1 = x0 + width - 1;
    unsigned int y1 = y0 + height - 1;

    if (update_count < 8) {
        printk("[A60_R61581] update #%u x=%u y=%u w=%u h=%u\n",
               update_count, x, y, width, height);
        update_count++;
    }

    set_addr_window(x0, y0, x1, y1);
    send_ctrl_cmd(0x29);
    send_ctrl_cmd(0x2C);
}

static void lcm_setbacklight(unsigned int level)
{
    if (level > 255)
        level = 255;

    send_ctrl_cmd(0x51);
    send_data_cmd(level);
}

static unsigned int lcm_compare_id(void)
{
    return 1;
}

LCM_DRIVER r61581_dbi_jingdongfang_lcm_drv =
{
    .name           = "r61581_dbi_jingdongfang",
    .set_util_funcs = lcm_set_util_funcs,
    .get_params     = lcm_get_params,
    .init           = lcm_init,
    .suspend        = lcm_suspend,
    .resume         = lcm_resume,
    .update         = lcm_update,
    .set_backlight  = lcm_setbacklight,
    .compare_id     = lcm_compare_id,
};
