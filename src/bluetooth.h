#ifndef BLUETOOTH_H
#define BLUETOOTH_H
#include "plant_common.h"

/* Initialize BLE and register services */
void bluetooth_init(struct plant_config *config, struct plant_status *status);

#endif // BLUETOOTH_H