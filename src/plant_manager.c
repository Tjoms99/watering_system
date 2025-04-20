#include "plant_manager.h"
#include "motor_control.h"
#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>

LOG_MODULE_REGISTER(plant_manager);

static struct plant_config *cfg;
static struct plant_status *stat;

static struct k_work_delayable plant_work;

// Helper function to handle mode-specific deinitialization
static void deinit_mode(plant_mode_t mode)
{
    switch (mode)
    {
    case PLANT_MODE_OFF:
        break;
    case PLANT_MODE_MANUAL:
        motor_control_stop();
        break;
    case PLANT_MODE_SCHEDULED:
        k_work_cancel_delayable(&plant_work);
        break;
    default:
        break;
    }
}

// Helper function to handle mode-specific initialization
static void init_mode(plant_mode_t mode)
{
    switch (mode)
    {
    case PLANT_MODE_OFF:
        motor_control_stop();
        break;
    case PLANT_MODE_MANUAL:
        motor_run(cfg->enabled);
        break;
    case PLANT_MODE_SCHEDULED:
        LOG_INF("Scheduling watering in %u minutes", cfg->interval_min);
        k_work_schedule(&plant_work, K_MINUTES(cfg->interval_min));
        break;
    default:
        break;
    }
}

// Watering task
static void perform_watering(struct k_work *work)
{
    if (stat->watering)
        return;

    uint32_t duration_ms = cfg->amount_ml * 100; // Placeholder formula
    motor_control_start(duration_ms);

    k_work_schedule(&plant_work, K_MINUTES(cfg->interval_min));

    stat->last_watered_ms = k_uptime_get_32();
    stat->watering = true;
}

// Initialization function
void plant_manager_init(struct plant_config *config, struct plant_status *status)
{
    cfg = config;
    stat = status;

    motor_control_init();
    k_work_init_delayable(&plant_work, perform_watering);
}

// Periodic tick function
void plant_manager_tick(void)
{
    static plant_mode_t last_mode = PLANT_MODE_OFF;

    // Update watering status
    stat->watering = motor_control_is_running();

    // Handle manual mode
    if (cfg->mode == PLANT_MODE_MANUAL)
    {
        motor_run(cfg->enabled);
    }

    // Skip if mode hasn't changed
    if (cfg->mode == last_mode)
        return;

    LOG_INF("Switching from mode %d to mode %d", last_mode, cfg->mode);

    // Handle mode transition
    deinit_mode(last_mode);
    init_mode(cfg->mode);
    last_mode = cfg->mode;
}
