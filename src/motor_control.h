#ifndef MOTOR_CONTROL_H
#define MOTOR_CONTROL_H

#include <stdbool.h>
#include <stdint.h>

/**
 * @brief Initialize motor control subsystem
 *
 * This function:
 * - Configures the motor GPIO pin
 * - Initializes the motor timer
 * - Sets the motor to OFF state
 *
 * @return 0 on success, negative error code on failure
 */
int motor_control_init(void);

/**
 * @brief Start the motor for a specified duration
 *
 * @param duration_ms Duration to run the motor in milliseconds
 * @return 0 on success, negative error code on failure
 */
int motor_control_start(uint32_t duration_ms);

/**
 * @brief Immediately stop the motor
 *
 * @return 0 on success, negative error code on failure
 */
int motor_control_stop(void);

/**
 * @brief Check if the motor is currently running
 *
 * @return true if motor is running, false otherwise
 */
bool motor_control_is_running(void);

#endif /* MOTOR_CONTROL_H */