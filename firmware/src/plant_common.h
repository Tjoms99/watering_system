#ifndef PLANT_COMMON_H
#define PLANT_COMMON_H

#include <stdint.h>
#include <stdbool.h>

/**
 * @brief Plant watering modes
 *
 * OFF: No watering occurs
 * MANUAL: Watering can be triggered via BLE
 * SCHEDULED: Automatic watering based on interval
 */
typedef enum
{
    PLANT_MODE_OFF = 0,
    PLANT_MODE_MANUAL = 1,
    PLANT_MODE_SCHEDULED = 2,
} plant_mode_t;

/**
 * @brief Plant watering configuration
 */
struct plant_config
{
    plant_mode_t mode;     ///< Operating mode (OFF/MANUAL/SCHEDULED)
    uint16_t interval_min; ///< Watering interval in minutes
    uint16_t amount_ml;    ///< Watering amount in milliliters
    bool water_now;        ///< Flag to trigger immediate watering
};

/**
 * @brief Plant watering status
 */
struct plant_status
{
    uint32_t last_watered_seconds;  ///< Time since last watering in seconds
    uint32_t next_watering_seconds; ///< Time until next scheduled watering in seconds
    bool watering;                  ///< Whether watering is currently in progress
};

#endif /* PLANT_COMMON_H */