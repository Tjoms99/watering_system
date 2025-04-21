#include "bluetooth.h"
#include "plant_common.h"

#include <zephyr/kernel.h>
#include <zephyr/sys/byteorder.h>
#include <zephyr/logging/log.h>
#include <zephyr/bluetooth/bluetooth.h>
#include <zephyr/bluetooth/uuid.h>
#include <zephyr/bluetooth/gatt.h>
#include <zephyr/bluetooth/hci.h>

LOG_MODULE_REGISTER(watering_service, LOG_LEVEL_INF);

// Define 128-bit UUIDs for the custom service and its characteristics
#define BT_UUID_WATERING_SERVICE_VAL BT_UUID_128_ENCODE(0xDEAD0000, 0xC634, 0x45D2, 0xA209, 0xC636967B81B2)
#define BT_UUID_WATERING_MODE_VAL BT_UUID_128_ENCODE(0xDEAD0001, 0xC634, 0x45D2, 0xA209, 0xC636967B81B2)
#define BT_UUID_WATERING_INTERVAL_VAL BT_UUID_128_ENCODE(0xDEAD0002, 0xC634, 0x45D2, 0xA209, 0xC636967B81B2)
#define BT_UUID_WATERING_AMOUNT_VAL BT_UUID_128_ENCODE(0xDEAD0003, 0xC634, 0x45D2, 0xA209, 0xC636967B81B2)
#define BT_UUID_WATERING_NOW_VAL BT_UUID_128_ENCODE(0xDEAD0004, 0xC634, 0x45D2, 0xA209, 0xC636967B81B2)
#define BT_UUID_WATERING_STATUS_VAL BT_UUID_128_ENCODE(0xDEAD0005, 0xC634, 0x45D2, 0xA209, 0xC636967B81B2)
#define BT_UUID_WATERING_LAST_VAL BT_UUID_128_ENCODE(0xDEAD0006, 0xC634, 0x45D2, 0xA209, 0xC636967B81B2)

#define BT_UUID_WATERING_SERVICE BT_UUID_DECLARE_128(BT_UUID_WATERING_SERVICE_VAL)
#define BT_UUID_WATERING_MODE BT_UUID_DECLARE_128(BT_UUID_WATERING_MODE_VAL)
#define BT_UUID_WATERING_INTERVAL BT_UUID_DECLARE_128(BT_UUID_WATERING_INTERVAL_VAL)
#define BT_UUID_WATERING_AMOUNT BT_UUID_DECLARE_128(BT_UUID_WATERING_AMOUNT_VAL)
#define BT_UUID_WATERING_NOW BT_UUID_DECLARE_128(BT_UUID_WATERING_NOW_VAL)
#define BT_UUID_WATERING_STATUS BT_UUID_DECLARE_128(BT_UUID_WATERING_STATUS_VAL)
#define BT_UUID_WATERING_LAST BT_UUID_DECLARE_128(BT_UUID_WATERING_LAST_VAL)

static struct plant_config *cfg_ptr;
static struct plant_status *status_ptr;
static struct bt_conn *current_conn = NULL;

/* --- READ CALLBACKS --- */

static ssize_t read_mode(struct bt_conn *conn, const struct bt_gatt_attr *attr,
                         void *buf, uint16_t len, uint16_t offset)
{
    uint8_t mode = (uint8_t)cfg_ptr->mode;
    LOG_INF("Read: Mode = %u", mode);
    return bt_gatt_attr_read(conn, attr, buf, len, offset, &mode, sizeof(mode));
}

static ssize_t read_interval(struct bt_conn *conn, const struct bt_gatt_attr *attr,
                             void *buf, uint16_t len, uint16_t offset)
{
    LOG_INF("Read: Interval = %u", cfg_ptr->interval_min);
    return bt_gatt_attr_read(conn, attr, buf, len, offset, &cfg_ptr->interval_min, sizeof(cfg_ptr->interval_min));
}

static ssize_t read_amount(struct bt_conn *conn, const struct bt_gatt_attr *attr,
                           void *buf, uint16_t len, uint16_t offset)
{
    LOG_INF("Read: Amount = %u", cfg_ptr->amount_ml);
    return bt_gatt_attr_read(conn, attr, buf, len, offset, &cfg_ptr->amount_ml, sizeof(cfg_ptr->amount_ml));
}

static ssize_t read_status(struct bt_conn *conn, const struct bt_gatt_attr *attr,
                           void *buf, uint16_t len, uint16_t offset)
{
    uint8_t status = status_ptr->watering ? 1 : 0;
    LOG_INF("Read: Watering status = %u", status);
    return bt_gatt_attr_read(conn, attr, buf, len, offset, &status, sizeof(status));
}

static ssize_t read_last_watered(struct bt_conn *conn, const struct bt_gatt_attr *attr,
                                 void *buf, uint16_t len, uint16_t offset)
{
    uint32_t now = k_uptime_get_32() / 1000; // Convert to seconds
    uint32_t since_seconds = now - status_ptr->last_watered_seconds;
    LOG_INF("Read: Time since last watering = %u seconds", since_seconds);
    return bt_gatt_attr_read(conn, attr, buf, len, offset, &since_seconds, sizeof(since_seconds));
}

/* --- WRITE CALLBACKS --- */

static ssize_t write_mode(struct bt_conn *conn, const struct bt_gatt_attr *attr,
                          const void *buf, uint16_t len, uint16_t offset, uint8_t flags)
{
    if (offset != 0 || len != 1)
    {
        return BT_GATT_ERR(BT_ATT_ERR_INVALID_ATTRIBUTE_LEN);
    }

    uint8_t new_mode = *(const uint8_t *)buf;
    if (new_mode > PLANT_MODE_SCHEDULED)
    {
        return BT_GATT_ERR(BT_ATT_ERR_WRITE_REQ_REJECTED);
    }

    cfg_ptr->mode = (plant_mode_t)new_mode;
    LOG_INF("Write: Mode = %u", cfg_ptr->mode);
    return len;
}

static ssize_t write_interval(struct bt_conn *conn, const struct bt_gatt_attr *attr,
                              const void *buf, uint16_t len, uint16_t offset, uint8_t flags)
{
    if (offset != 0 || len != sizeof(cfg_ptr->interval_min))
    {
        return BT_GATT_ERR(BT_ATT_ERR_INVALID_ATTRIBUTE_LEN);
    }
    cfg_ptr->interval_min = sys_get_le16(buf);
    LOG_INF("Write: Interval = %u min", cfg_ptr->interval_min);
    return len;
}

static ssize_t write_amount(struct bt_conn *conn, const struct bt_gatt_attr *attr,
                            const void *buf, uint16_t len, uint16_t offset, uint8_t flags)
{
    if (offset != 0 || len != sizeof(cfg_ptr->amount_ml))
    {
        return BT_GATT_ERR(BT_ATT_ERR_INVALID_ATTRIBUTE_LEN);
    }
    cfg_ptr->amount_ml = sys_get_le16(buf);
    LOG_INF("Write: Amount = %u ml", cfg_ptr->amount_ml);
    return len;
}

static ssize_t write_water_now(struct bt_conn *conn, const struct bt_gatt_attr *attr,
                               const void *buf, uint16_t len, uint16_t offset, uint8_t flags)
{
    if (offset != 0 || len != 1)
    {
        return BT_GATT_ERR(BT_ATT_ERR_INVALID_ATTRIBUTE_LEN);
    }

    uint8_t trigger = *(const uint8_t *)buf;
    if (trigger == 1)
    {
        LOG_INF("Manual watering triggered");
        cfg_ptr->water_now = true;
    }
    return len;
}

/* --- NOTIFICATION HANDLING --- */

static void status_ccc_cfg_changed(const struct bt_gatt_attr *attr, uint16_t value)
{
    bool notif_enabled = (value == BT_GATT_CCC_NOTIFY);
    LOG_INF("Watering status notifications %s", notif_enabled ? "enabled" : "disabled");
}

static void last_watered_ccc_cfg_changed(const struct bt_gatt_attr *attr, uint16_t value)
{
    bool notif_enabled = (value == BT_GATT_CCC_NOTIFY);
    LOG_INF("Last watered notifications %s", notif_enabled ? "enabled" : "disabled");
}

void notify_clients(const struct bt_gatt_attr *attr, const void *data, uint16_t len)
{
    if (!current_conn)
    {
        LOG_INF("No notification sent - no active connection");
        return;
    }

    const char *char_name = "unknown";
    const struct bt_gatt_attr *notify_attr = NULL;

    // Determine which characteristic we're notifying
    if (attr == &watering_svc.attrs[WATERING_STATUS_ATTR_POS])
    {
        notify_attr = &watering_svc.attrs[WATERING_STATUS_ATTR_POS];
        char_name = "watering status";
    }
    else if (attr == &watering_svc.attrs[LAST_WATERED_ATTR_POS])
    {
        notify_attr = &watering_svc.attrs[LAST_WATERED_ATTR_POS];
        char_name = "last watered";
    }

    if (!notify_attr)
    {
        LOG_ERR("Invalid attribute for notification");
        return;
    }

    // Check if client is subscribed
    if (!bt_gatt_is_subscribed(current_conn, notify_attr, BT_GATT_CCC_NOTIFY))
    {
        LOG_INF("Client not subscribed for %s notifications", char_name);
        return;
    }

    // Send notification
    LOG_INF("Sending notification for %s", char_name);
    int err = bt_gatt_notify(current_conn, notify_attr, data, len);
    if (err)
    {
        LOG_ERR("Failed to send notification for %s (err %d)", char_name, err);
    }
}

/* --- GATT SERVICE DEFINITION --- */

BT_GATT_SERVICE_DEFINE(watering_svc,
                       BT_GATT_PRIMARY_SERVICE(BT_UUID_WATERING_SERVICE),

                       BT_GATT_CHARACTERISTIC(BT_UUID_WATERING_MODE,
                                              BT_GATT_CHRC_READ | BT_GATT_CHRC_WRITE,
                                              BT_GATT_PERM_READ | BT_GATT_PERM_WRITE,
                                              read_mode, write_mode, NULL),

                       BT_GATT_CHARACTERISTIC(BT_UUID_WATERING_INTERVAL,
                                              BT_GATT_CHRC_READ | BT_GATT_CHRC_WRITE,
                                              BT_GATT_PERM_READ | BT_GATT_PERM_WRITE,
                                              read_interval, write_interval, NULL),

                       BT_GATT_CHARACTERISTIC(BT_UUID_WATERING_AMOUNT,
                                              BT_GATT_CHRC_READ | BT_GATT_CHRC_WRITE,
                                              BT_GATT_PERM_READ | BT_GATT_PERM_WRITE,
                                              read_amount, write_amount, NULL),

                       BT_GATT_CHARACTERISTIC(BT_UUID_WATERING_NOW,
                                              BT_GATT_CHRC_WRITE,
                                              BT_GATT_PERM_WRITE,
                                              NULL, write_water_now, NULL),

                       BT_GATT_CHARACTERISTIC(BT_UUID_WATERING_STATUS,
                                              BT_GATT_CHRC_READ | BT_GATT_CHRC_NOTIFY,
                                              BT_GATT_PERM_READ,
                                              read_status, NULL, NULL),

                       BT_GATT_CCC(status_ccc_cfg_changed,
                                   BT_GATT_PERM_READ | BT_GATT_PERM_WRITE),

                       BT_GATT_CHARACTERISTIC(BT_UUID_WATERING_LAST,
                                              BT_GATT_CHRC_READ | BT_GATT_CHRC_NOTIFY,
                                              BT_GATT_PERM_READ,
                                              read_last_watered, NULL, NULL),

                       BT_GATT_CCC(last_watered_ccc_cfg_changed,
                                   BT_GATT_PERM_READ | BT_GATT_PERM_WRITE));

/* --- CONNECTION HANDLING --- */
static int start_advertising()
{
    const struct bt_data ad[] = {
        BT_DATA_BYTES(BT_DATA_FLAGS, (BT_LE_AD_GENERAL | BT_LE_AD_NO_BREDR)),
        BT_DATA(BT_DATA_NAME_COMPLETE, CONFIG_BT_DEVICE_NAME, sizeof(CONFIG_BT_DEVICE_NAME) - 1)};

    const struct bt_data sd[] = {
        BT_DATA_BYTES(BT_DATA_UUID128_ALL, BT_UUID_WATERING_SERVICE_VAL)};

    int err = bt_le_adv_start(BT_LE_ADV_CONN, ad, ARRAY_SIZE(ad), sd, ARRAY_SIZE(sd));
    if (err)
    {
        LOG_ERR("Advertising start failed (err %d)", err);
        return err;
    }

    LOG_INF("Advertising started (device name: \"%s\")", CONFIG_BT_DEVICE_NAME);
    return 0;
}

static void connected(struct bt_conn *conn, uint8_t err)
{
    if (err)
    {
        LOG_ERR("Connection failed (err %u)", err);
        return;
    }

    LOG_INF("Bluetooth central connected");
    current_conn = conn;
}

static void disconnected(struct bt_conn *conn, uint8_t reason)
{
    LOG_INF("Bluetooth disconnected (reason %u)", reason);
    current_conn = NULL;
    start_advertising();
}

BT_CONN_CB_DEFINE(conn_cb) = {
    .connected = connected,
    .disconnected = disconnected,
};

/* --- INIT FUNCTION --- */

int bluetooth_init(struct plant_config *config, struct plant_status *status)
{
    cfg_ptr = config;
    status_ptr = status;

    LOG_INF("Watering Service starting...");

    int err = bt_enable(NULL);
    if (err)
    {
        LOG_ERR("Bluetooth init failed (err %d)", err);
        return err;
    }

    LOG_INF("Bluetooth initialized");

    start_advertising();

    k_sleep(K_SECONDS(10));

    return 0;
}
