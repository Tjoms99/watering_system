#include "plant_manager.h"
#include "motor_control.h"
#include "bluetooth.h"
#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>
#include <zephyr/bluetooth/gatt.h>

LOG_MODULE_REGISTER(plant_manager);

static struct plant_config *cfg;
static struct plant_status *stat;

static struct k_work_delayable plant_work;

// Notify BLE clients about watering status change
static void notify_watering_status(void)
{
    uint8_t status = stat->watering ? 1 : 0;
    LOG_INF("Notifying watering status: %u", status);
    notify_clients(&watering_svc.attrs[WATERING_STATUS_ATTR_POS], &status, sizeof(status));
}

// Notify BLE clients about last watered time
static void notify_last_watered(void)
{
    uint32_t now = k_uptime_get_32() / 1000; // Convert to seconds
    uint32_t since_seconds = now - stat->last_watered_seconds;
    LOG_INF("Notifying last watered: %u seconds ago", since_seconds);
    notify_clients(&watering_svc.attrs[LAST_WATERED_ATTR_POS], &since_seconds, sizeof(since_seconds));
}

/**
 * Compute the pump-on time (in milliseconds) for a given volume (in mL).
 * Piecewise flow rate:
 *   • 0 ≤ volume ≤ 100 mL → 25 mL/s
 *   •       volume > 100 mL → 35 mL/s
 *
 * @param volume_ml  Desired volume in milliliters.
 * @return           Time in milliseconds
 */
static uint32_t pump_time_ms(uint32_t volume_ml)
{
    const uint32_t FLOW_RATE_LOW = 25;  // mL/s for volumes <= 100mL
    const uint32_t FLOW_RATE_HIGH = 35; // mL/s for volumes > 100mL
    const uint32_t THRESHOLD = 100;     // mL threshold between flow rates

    uint32_t rate = (volume_ml <= THRESHOLD) ? FLOW_RATE_LOW : FLOW_RATE_HIGH;

    return (volume_ml * 1000) / rate; // Convert to milliseconds
}

// Watering task
static void perform_watering(struct k_work *work)
{
    if (motor_control_is_running())
    {
        LOG_WRN("Watering already in progress");
        return;
    }

    LOG_INF("Starting watering cycle: %u ml", cfg->amount_ml);

    // Calculate watering duration (25ml per second)
    uint32_t duration_ms = pump_time_ms(cfg->amount_ml);
    int err = motor_control_start(duration_ms);
    if (err)
    {
        LOG_ERR("Failed to start watering (err %d)", err);
        return;
    }

    // Update status and notify
    stat->last_watered_seconds = k_uptime_get_32() / 1000; // Convert to seconds
    stat->watering = true;
    notify_watering_status();
    notify_last_watered();

    // Schedule next watering if in scheduled mode
    if (cfg->mode == PLANT_MODE_SCHEDULED)
    {
        LOG_INF("Next watering scheduled in %u minutes", cfg->interval_min);
        k_work_schedule(&plant_work, K_MINUTES(cfg->interval_min));
    }
}

// Initialization function
int plant_manager_init(struct plant_config *config, struct plant_status *status)
{
    int err;

    cfg = config;
    stat = status;

    err = motor_control_init();
    if (err)
    {
        LOG_ERR("Motor control init failed (err %d)", err);
        return err;
    }

    k_work_init_delayable(&plant_work, perform_watering);

    // Initialize with OFF mode
    cfg->mode = PLANT_MODE_OFF;
    cfg->water_now = false;
    return 0;
}

// Periodic tick function
void plant_manager_tick(void)
{
    static plant_mode_t last_mode = PLANT_MODE_OFF;
    static bool was_watering = false;
    notify_last_watered();

    // Update watering status based on motor state
    bool is_watering = motor_control_is_running();
    if (is_watering != was_watering)
    {
        LOG_INF("Watering state changed: %d -> %d", was_watering, is_watering);
        stat->watering = is_watering;
        was_watering = is_watering;
        notify_watering_status();
    }

    // Handle mode transition
    if (cfg->mode != last_mode)
    {
        LOG_INF("Switching from mode %d to mode %d", last_mode, cfg->mode);

        // Cancel any scheduled watering
        k_work_cancel_delayable(&plant_work);

        // Stop motor if running
        if (stat->watering)
        {
            motor_control_stop();
        }

        // Schedule next watering if in scheduled mode
        if (cfg->mode == PLANT_MODE_SCHEDULED)
        {
            LOG_INF("Scheduling watering in %u minutes", cfg->interval_min);
            k_work_schedule(&plant_work, K_MINUTES(cfg->interval_min));
        }

        last_mode = cfg->mode;
    }

    // Handle manual watering trigger
    if (cfg->mode == PLANT_MODE_MANUAL && cfg->water_now && !stat->watering)
    {
        perform_watering(NULL);
        cfg->water_now = false; // Clear the trigger after use
    }
}
