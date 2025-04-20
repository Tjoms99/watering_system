#ifndef MOTOR_CONTROL_H
#define MOTOR_CONTROL_H

#include <stdbool.h>
#include <stdint.h>

int motor_run(bool enabled);

/* Initialize motor GPIO / PWM */
void motor_control_init(void);

/* Start motor for given duration (in ms) */
void motor_control_start(uint32_t duration_ms);

/* Immediately stop the motor */
void motor_control_stop(void);

/* Check if motor is running */
bool motor_control_is_running(void);

#endif // MOTOR_CONTROL_H