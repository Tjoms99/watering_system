#include "motor_control.h"
#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>
#include <zephyr/drivers/gpio.h>

LOG_MODULE_REGISTER(motor_control, LOG_LEVEL_INF);

/* Motor control configuration */
#define MOTOR_GPIO_NODE DT_NODELABEL(gpio0)
#define MOTOR_GPIO_PIN 29

static const struct device *gpio_dev = DEVICE_DT_GET(MOTOR_GPIO_NODE);
static struct k_timer motor_timer;
static bool is_running = false;

/* Internal helper function to control motor state */
static int motor_set_state(bool enabled)
{
    if (is_running == enabled)
    {
        return 0;
    }

    int err = gpio_pin_set(gpio_dev, MOTOR_GPIO_PIN, enabled);
    if (err)
    {
        LOG_ERR("Failed to set motor state (err %d)", err);
        return err;
    }

    is_running = enabled;
    LOG_INF("Motor %s", enabled ? "enabled" : "disabled");
    return 0;
}

/* Timer callback for automatic motor stop */
static void motor_timeout(struct k_timer *timer_id)
{
    LOG_INF("Motor timeout – stopping");
    motor_control_stop();
}

int motor_control_init(void)
{
    int err;

    /* Check if GPIO device is ready */
    if (!device_is_ready(gpio_dev))
    {
        LOG_ERR("GPIO device not ready");
        return -ENODEV;
    }

    /* Initialize motor timer */
    k_timer_init(&motor_timer, motor_timeout, NULL);

    /* Configure motor GPIO */
    err = gpio_pin_configure(gpio_dev, MOTOR_GPIO_PIN, GPIO_OUTPUT | GPIO_ACTIVE_HIGH);
    if (err)
    {
        LOG_ERR("Failed to configure motor GPIO (err %d)", err);
        return err;
    }

    /* Ensure motor is off */
    return motor_control_stop();
}

int motor_control_start(uint32_t duration_ms)
{
    int err;

    if (is_running)
    {
        LOG_WRN("Motor already running");
        return -EBUSY;
    }

    LOG_INF("Starting motor for %u ms", duration_ms);

    /* Start motor */
    err = motor_set_state(true);
    if (err)
    {
        return err;
    }

    /* Start timer for automatic stop */
    k_timer_start(&motor_timer, K_MSEC(duration_ms), K_NO_WAIT);
    return 0;
}

int motor_control_stop(void)
{
    int err;

    if (!is_running)
    {
        return 0;
    }

    /* Stop timer */
    k_timer_stop(&motor_timer);

    /* Turn off motor */
    err = motor_set_state(false);
    if (err)
    {
        LOG_ERR("Failed to stop motor (err %d)", err);
        return err;
    }

    return 0;
}

bool motor_control_is_running(void)
{
    return is_running;
}
