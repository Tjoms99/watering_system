#include "bluetooth.h"
#include "plant_manager.h"
#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>

LOG_MODULE_REGISTER(main);

/* Default configuration */
static struct plant_config config = {
    .mode = PLANT_MODE_OFF, // Start in OFF mode
    .interval_min = 1,      // Default: water every hour
    .amount_ml = 100        // Default: 100ml per watering
};

/* System status */
static struct plant_status status = {
    .last_watered_seconds = 0, // Never watered
    .watering = false          // Not watering
};

int main(void)
{
    int err;

    LOG_INF("🌿 Smart Plant Watering System starting...");

    /* Initialize Bluetooth */
    err = bluetooth_init(&config, &status);
    if (err)
    {
        LOG_ERR("Failed to initialize Bluetooth (err %d)", err);
        return err;
    }
    LOG_INF("Bluetooth initialized successfully");

    /* Initialize Plant Manager */
    err = plant_manager_init(&config, &status);
    if (err)
    {
        LOG_ERR("Failed to initialize Plant Manager (err %d)", err);
        return err;
    }
    LOG_INF("Plant Manager initialized successfully");

    LOG_INF("System ready! Current mode: %s",
            config.mode == PLANT_MODE_OFF ? "OFF" : config.mode == PLANT_MODE_MANUAL ? "MANUAL"
                                                                                     : "SCHEDULED");

    /* Main loop */
    while (1)
    {
        plant_manager_tick();
        k_sleep(K_SECONDS(1));
    }

    return 0;
}