#ifndef BLUETOOTH_H
#define BLUETOOTH_H
#include "plant_common.h"
#include <zephyr/bluetooth/gatt.h>

// Forward declaration of the GATT service
extern const struct bt_gatt_service_static watering_svc;

/* Attribute positions in the GATT service:
 * Service layout:
 * 0: Service declaration
 * 1: Mode characteristic declaration
 * 2: Mode value
 * 3: Interval characteristic declaration
 * 4: Interval value
 * 5: Amount characteristic declaration
 * 6: Amount value
 * 7: Water Now characteristic declaration
 * 8: Water Now value
 * 9: Status characteristic declaration
 * 10: Status value (WATERING_STATUS_ATTR_POS)
 * 11: Status CCC
 * 12: Last Watered characteristic declaration
 * 13: Last Watered value (LAST_WATERED_ATTR_POS)
 * 14: Last Watered CCC
 * 15: Next Watering characteristic declaration
 * 16: Next Watering value (NEXT_WATERING_ATTR_POS)
 * 17: Next Watering CCC
 */
enum watering_char_position
{
    WATERING_STATUS_ATTR_POS = 10, // Status characteristic value
    LAST_WATERED_ATTR_POS = 13,    // Last watered characteristic value
    NEXT_WATERING_ATTR_POS = 16    // Next watering characteristic value
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