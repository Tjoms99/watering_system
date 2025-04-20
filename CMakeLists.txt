cmake_minimum_required(VERSION 3.20.0)
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})

project(watering_system)

target_sources(app PRIVATE src/main.c src/motor_control.c src/bluetooth.c src/plant_manager.c)
