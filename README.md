# 🌿 Smart Plant Watering System

A minimalist and elegant Bluetooth-controlled plant watering system, built with:

- Nordic **nRF52840** + **Zephyr (NCS 2.9)**
- A custom **BLE service** for control + feedback
- An upcoming **Flutter app** to configure and monitor watering behavior

This project aims to be simple, robust, and flexible — allowing both **manual** and **automated** watering modes.

---

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

## 📱 Flutter App Integration

The Flutter app (planned) will:

- Scan and connect to the BLE device
- Read current watering config
- Toggle modes and manually trigger watering
- Receive real-time updates via notifications:
  - Watering status changes (start/stop)
  - Time since last watering (updated every second)

### Libraries (planned):

- [`flutter_blue`](https://pub.dev/packages/flutter_blue) or `flutter_reactive_ble`
- `provider` or `riverpod` for state management

---
