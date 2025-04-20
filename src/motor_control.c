#include "motor_control.h"
#include <zephyr/kernel.h>

#include <zephyr/logging/log.h>
#include <zephyr/drivers/gpio.h>

LOG_MODULE_REGISTER(motor_run, LOG_LEVEL_INF);

#define GPIO_MOTOR_PIN 29
static const struct device *gpio_battery_dev = DEVICE_DT_GET(DT_NODELABEL(gpio0));

static struct k_timer motor_timer;
static bool is_running = false;

int motor_run(bool enabled)
{

    if (is_running == enabled)
    {
        return 0;
    }

    is_running = enabled;

    LOG_INF("Motor %s", enabled ? "enabled" : "disabled");
    return gpio_pin_set(gpio_battery_dev, GPIO_MOTOR_PIN, enabled);
}

static void motor_timeout(struct k_timer *timer_id)
{
    LOG_INF("Motor timeout – stopping");
    motor_run(false);
    // TODO: Disable motor GPIO
}

void motor_control_init(void)
{
    k_timer_init(&motor_timer, motor_timeout, NULL);

    gpio_pin_configure(gpio_battery_dev, GPIO_MOTOR_PIN, GPIO_OUTPUT | GPIO_ACTIVE_HIGH);
    motor_run(false);
}

void motor_control_start(uint32_t duration_ms)
{
    LOG_INF("Starting motor for %u ms", duration_ms);

    motor_run(true);
    k_timer_start(&motor_timer, K_MSEC(duration_ms), K_NO_WAIT);
}

void motor_control_stop(void)
{
    // LOG_INF("Motor force-stopped");

    motor_run(false);
    k_timer_stop(&motor_timer);
}

bool motor_control_is_running(void)
{
    return is_running;
}
