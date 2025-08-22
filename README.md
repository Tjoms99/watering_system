# 🌿 Smart Plant Watering System

A minimalist and elegant Bluetooth-controlled plant watering system, built with:

- Zephyr for the firmware
   - Nordic **nRF52840** + **Zephyr (NCS 2.9)**
   - Texas Instruments **CC2340R53** + **Zephyr 3.7 (ti-9.10)**
- **Flutter** for the mobile application
- Custom **BLE service** for control + feedback

This project aims to be simple, robust, and flexible — allowing both **manual** and **automated** watering modes.

---

## 📁 Project Structure

```
watering_system/
├── firmware/               # Zephyr firmware
│   ├── src/                # Source code
│   ├── prj.conf            # Build configuration (default)
│   ├── boards/             # Board-specific .conf and .overlay files
│   │   ├── <board>.conf
│   │   ├── <board>.overlay
│   │   └── ...
│   └── ...
├── app/               # Flutter mobile application
│   ├── lib/           # Dart source code
│   ├── pubspec.yaml   # Dependencies
│   └── ...
└── README.md          # Project documentation
```

## 🧠 System Overview

```
                    ┌────────────────────┐
                    │   Flutter App      │
                    │  (BLE Central)     │
                    └────────┬───────────┘
                             │
                             ▼
                 BLE Connection & GATT Interface
                             │
                             ▼
                    ┌──────────────────────┐
                    │      Firmware        │
                    │  (BLE Peripheral)    │
                    └────────┬─────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        ▼                    ▼                    ▼
┌────────────────┐    ┌────────────────┐    ┌────────────────────┐
│ Plant Config   │    │ Plant Manager  │    │  Motor Control     │
│ (BLE state)    │    │ - Scheduler    │    │ - GPIO             │
│ - Mode         │    │ - Water Trigger│    │ - Timer Off Switch │
| - Water Now    │    └────────────────┘    └────────────────────┘
│ - Interval     │
│ - Amount       │
└────────────────┘
```

## 📡 BLE GATT Overview

The wireless MCU advertises a custom **Watering Service** containing these characteristics:

| Name            | UUID Suffix | R/W        | Type     | Description                             |
| --------------- | ----------- | ---------- | -------- | --------------------------------------- |
| `Mode`          | `0001`      | R/W        | `uint8`  | 0 = Off, 1 = Manual, 2 = Scheduled      |
| `Interval`      | `0002`      | R/W        | `uint16` | Interval between waterings (in minutes) |
| `Amount`        | `0003`      | R/W        | `uint16` | Watering amount in milliliters          |
| `Water Now`     | `0004`      | W          | `uint8`  | Write `1` to trigger a manual watering  |
| `Status`        | `0005`      | R / Notify | `uint8`  | 0 = Not watering, 1 = Watering          |
| `Last Watered`  | `0006`      | R / Notify | `uint32` | Seconds since last watering             |
| `Next Watering` | `0007`      | R / Notify | `uint32` | Seconds to next watering                |

- All characteristics are under a custom 128-bit UUID base
- Central apps (like the Flutter app) can read/update settings and trigger watering
- Notifications are enabled for real-time UI updates on watering status and last watered time

---

## 🧩 Modes of Operation

| Mode        | Behavior                                           |
| ----------- | -------------------------------------------------- |
| `OFF`       | No watering occurs                                 |
| `MANUAL`    | Flutter app can trigger one-time watering manually |
| `SCHEDULED` | Plant is watered automatically on interval         |

---

## 📱 Flutter App

The Flutter app provides a user-friendly interface to:

- Scan and connect to the watering device
- Monitor watering status in real-time
- Configure watering settings
- Trigger manual watering
- View watering history

### Features

- Real-time status updates via BLE notifications
- Intuitive mode selection
- Watering schedule configuration
- Manual watering trigger
- Last watered time display

### Dependencies

- `flutter_reactive_ble` for BLE communication
- `provider` for state management
- `intl` for time formatting
- `flutter_blue_plus` for enhanced BLE functionality

---

## 🔧 Development Setup

### Firmware
> **Note:** Overlay files are used to support different boards. The GPIO pin used to control the motor is defined in the corresponding overlay file for each board.

> **Tip:** You do **not** need to manually specify overlay files when building. Zephyr will automatically use the overlay and configuration files that match the board name.

#### Nordic boards
1. Install Zephyr SDK from Nordic.

   Follow the instructions from 
   [Installing the nRF Connect SDK](https://docs.nordicsemi.com/bundle/ncs-latest/page/nrf/installation/install_ncs.html).

2. Build and flash firmware:
   
   For nRF52840DK
   ```bash
   cd firmware
   west build -b nrf52840dk/nrf52840
   west flash
   ```

   For XIAO BLE Sense
   ```bash
   cd firmware
   west build -b xiao_ble/nrf52840/sense
   ```
#### Texas Instruments boards
1. Install Zephyr SDK from TI.

   Follow the instruction from the 
   [Zephyr - Getting Started Guide **3.7.0**](https://docs.zephyrproject.org/3.7.0/develop/getting_started/index.html), 
   but replace the following step
   ``` bash
   west init ~/zephyrproject
   ```

   with TI Zephyr repository
   ``` bash
   west init -m https://github.com/TexasInstruments/simplelink-zephyr --mr vv3.7.0-ti-9.10.00_ea zephyrproject
   ```

   More info is provided in [TI - SimpleLink Academy - Getting started](https://dev.ti.com/tirex/explore/content/simplelink_academy_for_cc23xx_8_40_01_00/_build_simplelink_academy_for_cc23xx_8_40_01_00/source/zephyr/cc23xx_zephyr_getting_started.html)

2. Build and flash firmware:

   For LP_EM_CC5340R53
   ```bash
   cd firmware
   west build -b lp_em_cc2340r53
   ```

### Flutter App

1. Install Flutter SDK
2. Install dependencies:
   ```bash
   cd app
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

---

## 📚 Documentation

- [Firmware Documentation](firmware/README.md)
- [App Documentation](app/README.md)
- [BLE Protocol Documentation](docs/ble_protocol.md)
- [TI - Zephyr Project Environmet Setup](https://dev.ti.com/tirex/explore/node?node=A__Abn1NAQObvrVu7R5iV50Lw__SIMPLELINK-ACADEMY-CC23XX__gsUPh5j__LATEST)
- [TI Zephyr repository](https://github.com/TexasInstruments/simplelink-zephyr/)
- [TI - SimpleLink Academy - Getting started](https://dev.ti.com/tirex/explore/content/simplelink_academy_for_cc23xx_8_40_01_00/_build_simplelink_academy_for_cc23xx_8_40_01_00/source/zephyr/cc23xx_zephyr_getting_started.html)
