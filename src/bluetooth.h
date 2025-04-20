#ifndef BLUETOOTH_H
#define BLUETOOTH_H
#include "plant_common.h"
#include <zephyr/bluetooth/gatt.h>

// Forward declaration of the GATT service
extern const struct bt_gatt_service_static watering_svc;

/* Attribute positions in the GATT service */
enum watering_char_position
{
    WATERING_STATUS_ATTR_POS = 10, // Status characteristic value
    LAST_WATERED_ATTR_POS = 13     // Last watered characteristic value
};

// Function to notify clients about characteristic changes
void notify_clients(const struct bt_gatt_attr *attr, const void *data, uint16_t len);

/**
 * @brief Initialize Bluetooth and register services
 *
 * @param config Pointer to plant configuration
 * @param status Pointer to plant status
 * @return 0 on success, negative error code on failure
 */
int bluetooth_init(struct plant_config *config, struct plant_status *status);

#endif /* BLUETOOTH_H */