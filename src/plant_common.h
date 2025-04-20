#ifndef PLANT_COMMON_H
#define PLANT_COMMON_H

#include <stdint.h>
#include <stdbool.h>

typedef enum
{
    PLANT_MODE_OFF = 0,
    PLANT_MODE_MANUAL = 1,
    PLANT_MODE_SCHEDULED = 2,
} plant_mode_t;

struct plant_config
{
    plant_mode_t mode;     // Operating mode
    bool enabled;          // Watering enabled/disabled
    uint16_t interval_min; // Watering interval in minutes
    uint16_t amount_ml;    // Watering amount in milliliters
};

struct plant_status
{
    uint32_t last_watered_ms; // Timestamp since last watering
    bool watering;            // Motor currently running
};

#endif // PLANT_COMMON_H