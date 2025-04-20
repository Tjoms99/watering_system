# 🌿 Smart Plant Watering System

A minimalist and elegant Bluetooth-controlled plant watering system, built with:

- Nordic **nRF52840** + **Zephyr (NCS 2.9)** for the firmware
- **Flutter** for the mobile application
- Custom **BLE service** for control + feedback

This project aims to be simple, robust, and flexible — allowing both **manual** and **automated** watering modes.

---

## 📁 Project Structure

```
watering_system/
├── firmware/           # Zephyr firmware for nRF52840
│   ├── src/           # Source code
│   ├── prj.conf       # Build configuration
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
                    │  nRF52840 Firmware   │
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

The nRF52840 advertises a custom **Watering Service** containing these characteristics:

| Name           | UUID Suffix | R/W        | Type     | Description                             |
| -------------- | ----------- | ---------- | -------- | --------------------------------------- |
| `Mode`         | `0001`      | R/W        | `uint8`  | 0 = Off, 1 = Manual, 2 = Scheduled      |
| `Interval`     | `0002`      | R/W        | `uint16` | Interval between waterings (in minutes) |
| `Amount`       | `0003`      | R/W        | `uint16` | Watering amount in milliliters          |
| `Water Now`    | `0004`      | W          | `uint8`  | Write `1` to trigger a manual watering  |
| `Status`       | `0005`      | R / Notify | `uint8`  | 0 = Not watering, 1 = Watering          |
| `Last Watered` | `0006`      | R / Notify | `uint32` | Seconds since last watering             |

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

1. Install Zephyr SDK and NCS
2. Build and flash firmware:
   ```bash
   cd firmware
   west build -b nrf52840dk_nrf52840
   west flash
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
