#ifndef PLANT_MANAGER_H
#define PLANT_MANAGER_H

#include "plant_common.h"

/**
 * @brief Initialize plant manager and schedule periodic watering
 *
 * @param config Pointer to plant configuration
 * @param status Pointer to plant status
 * @return 0 on success, negative error code on failure
 */
int plant_manager_init(struct plant_config *config, struct plant_status *status);

/**
 * @brief Call periodically to check and act on watering needs
 *
 * This function should be called in the main loop to handle:
 * - Mode transitions
 * - Manual watering triggers
 * - Scheduled watering
 */
void plant_manager_tick(void);

#endif /* PLANT_MANAGER_H */
