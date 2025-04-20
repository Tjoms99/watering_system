#include "bluetooth.h"
#include "plant_manager.h"
#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>

LOG_MODULE_REGISTER(main);

static struct plant_config config = {
    .enabled = false,
    .interval_min = 60,
    .amount_ml = 100};

static struct plant_status status = {
    .last_watered_ms = 0,
    .watering = false};

void main(void)
{
        LOG_INF("Watering system booting...");

        bluetooth_init(&config, &status);
        plant_manager_init(&config, &status);

        while (1)
        {
                plant_manager_tick();
                k_sleep(K_SECONDS(1));
        }
}