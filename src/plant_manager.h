#ifndef PLANT_MANAGER_H
#define PLANT_MANAGER_H

#include "plant_common.h"

/* Initialize and schedule periodic watering */
void plant_manager_init(struct plant_config *config, struct plant_status *status);

/* Call periodically to check and act */
void plant_manager_tick(void);

#endif // PLANT_MANAGER_H
