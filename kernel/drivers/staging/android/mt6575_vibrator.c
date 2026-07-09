/*
 * MediaTek MT6575 vibrator timed_output driver.
 *
 * Matches the MT6573/MT6575 vendor behavior: expose Android's
 * /sys/class/timed_output/vibrator/enable node and drive the motor from
 * the PMIC VIBR LDO through the normal hwPowerOn/hwPowerDown refcount path.
 */

#include <linux/hrtimer.h>
#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/spinlock.h>
#include <linux/time.h>
#include <linux/workqueue.h>

#include <mach/mt6575_pm_ldo.h>

#include "timed_output.h"

#define VIBRATOR_NAME		"Vibrator"
#define VIBRATOR_MAX_TIMEOUT	15000

static struct hrtimer vibrator_timer;
static DEFINE_SPINLOCK(vibrator_lock);
static struct work_struct vibrator_work;
static int vibrator_state;
static int vibrator_powered;

static void vibr_Enable(void)
{
	printk(KERN_INFO "[vibrator]vibr_Enable\n");
	hwPowerOn(MT65XX_POWER_LDO_VIBR, VOL_2800, VIBRATOR_NAME);
}

static void vibr_Disable(void)
{
	printk(KERN_INFO "[vibrator]vibr_Disable\n");
	hwPowerDown(MT65XX_POWER_LDO_VIBR, VIBRATOR_NAME);
}

static void vibrator_update(struct work_struct *work)
{
	unsigned long flags;
	int state;
	int power_on = 0;
	int power_off = 0;

	spin_lock_irqsave(&vibrator_lock, flags);
	state = vibrator_state;

	if (state && !vibrator_powered) {
		vibrator_powered = 1;
		power_on = 1;
	} else if (!state && vibrator_powered) {
		vibrator_powered = 0;
		power_off = 1;
	}
	spin_unlock_irqrestore(&vibrator_lock, flags);

	if (power_on)
		vibr_Enable();
	else if (power_off)
		vibr_Disable();
}

static enum hrtimer_restart vibrator_timer_func(struct hrtimer *timer)
{
	unsigned long flags;

	spin_lock_irqsave(&vibrator_lock, flags);
	vibrator_state = 0;
	spin_unlock_irqrestore(&vibrator_lock, flags);

	schedule_work(&vibrator_work);

	return HRTIMER_NORESTART;
}

static int vibrator_get_time(struct timed_output_dev *dev)
{
	struct timeval time;
	ktime_t remaining;

	if (!hrtimer_active(&vibrator_timer))
		return 0;

	remaining = hrtimer_get_remaining(&vibrator_timer);
	time = ktime_to_timeval(remaining);

	return time.tv_sec * 1000 + time.tv_usec / 1000;
}

static void vibrator_enable(struct timed_output_dev *dev, int value)
{
	unsigned long flags;

	hrtimer_cancel(&vibrator_timer);

	spin_lock_irqsave(&vibrator_lock, flags);

	if (value <= 0) {
		vibrator_state = 0;
	} else {
		if (value > VIBRATOR_MAX_TIMEOUT)
			value = VIBRATOR_MAX_TIMEOUT;

		vibrator_state = 1;
		hrtimer_start(&vibrator_timer,
				ktime_set(value / 1000, (value % 1000) * 1000000),
				HRTIMER_MODE_REL);
	}

	spin_unlock_irqrestore(&vibrator_lock, flags);

	schedule_work(&vibrator_work);
}

static struct timed_output_dev mt6575_vibrator = {
	.name = "vibrator",
	.get_time = vibrator_get_time,
	.enable = vibrator_enable,
};

static int __init mt6575_vibrator_init(void)
{
	int ret;

	printk(KERN_INFO "MediaTek MT6575 vibrator driver register, version 1.0\n");

	hrtimer_init(&vibrator_timer, CLOCK_MONOTONIC, HRTIMER_MODE_REL);
	vibrator_timer.function = vibrator_timer_func;
	INIT_WORK(&vibrator_work, vibrator_update);

	ret = timed_output_dev_register(&mt6575_vibrator);
	if (ret)
		printk(KERN_ERR "mt6575_vibrator: timed_output register failed: %d\n", ret);

	return ret;
}

static void __exit mt6575_vibrator_exit(void)
{
	unsigned long flags;

	hrtimer_cancel(&vibrator_timer);

	spin_lock_irqsave(&vibrator_lock, flags);
	vibrator_state = 0;
	spin_unlock_irqrestore(&vibrator_lock, flags);

	cancel_work_sync(&vibrator_work);
	vibrator_update(&vibrator_work);
	timed_output_dev_unregister(&mt6575_vibrator);
}

module_init(mt6575_vibrator_init);
module_exit(mt6575_vibrator_exit);

MODULE_DESCRIPTION("MediaTek MT6575 vibrator timed_output driver");
MODULE_LICENSE("GPL");
