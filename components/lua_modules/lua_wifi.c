/*
 * Lua WiFi Module for ESP32
 */

#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"
#include "esp_wifi.h"
#include "esp_event.h"
#include "esp_log.h"
#include "esp_netif.h"

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

static const char *TAG = "lua_wifi";

#define WIFI_CONNECTED_BIT BIT0
#define WIFI_FAIL_BIT      BIT1
#define WIFI_MAX_RETRY     5

static EventGroupHandle_t s_wifi_event_group = NULL;
static esp_netif_t *s_sta_netif = NULL;
static int s_retry_num = 0;
static bool s_wifi_initialized = false;
static bool s_wifi_connected = false;

static void wifi_event_handler(void* arg, esp_event_base_t event_base,
                               int32_t event_id, void* event_data)
{
    if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_START) {
        esp_wifi_connect();
    } else if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_DISCONNECTED) {
        s_wifi_connected = false;
        if (s_retry_num < WIFI_MAX_RETRY) {
            esp_wifi_connect();
            s_retry_num++;
            ESP_LOGI(TAG, "Retry to connect to the AP");
        } else {
            xEventGroupSetBits(s_wifi_event_group, WIFI_FAIL_BIT);
        }
        ESP_LOGI(TAG, "Connect to the AP fail");
    } else if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP) {
        ip_event_got_ip_t* event = (ip_event_got_ip_t*) event_data;
        ESP_LOGI(TAG, "Got IP:" IPSTR, IP2STR(&event->ip_info.ip));
        s_retry_num = 0;
        s_wifi_connected = true;
        xEventGroupSetBits(s_wifi_event_group, WIFI_CONNECTED_BIT);
    }
}

// Pre-initialize WiFi (called from main.c BEFORE display init)
// This reserves internal DMA memory for WiFi buffers before the display grabs it
void wifi_preinit(void)
{
    if (s_wifi_initialized) {
        return;
    }

    // Check if WiFi is already running (from previous boot cycle)
    wifi_mode_t mode;
    if (esp_wifi_get_mode(&mode) == ESP_OK) {
        ESP_LOGI(TAG, "WiFi already initialized from previous cycle");
        s_wifi_initialized = true;
        if (s_wifi_event_group == NULL) {
            s_wifi_event_group = xEventGroupCreate();
        }
        return;
    }

    s_wifi_event_group = xEventGroupCreate();

    // Initialize netif - ignore if already done
    esp_err_t ret = esp_netif_init();
    if (ret != ESP_OK && ret != ESP_ERR_INVALID_STATE) {
        ESP_LOGE(TAG, "esp_netif_init failed: %s", esp_err_to_name(ret));
        return;
    }

    // Create event loop - ignore if already done
    ret = esp_event_loop_create_default();
    if (ret != ESP_OK && ret != ESP_ERR_INVALID_STATE) {
        ESP_LOGE(TAG, "esp_event_loop_create_default failed: %s", esp_err_to_name(ret));
        return;
    }

    if (s_sta_netif == NULL) {
        s_sta_netif = esp_netif_create_default_wifi_sta();
    }

    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ret = esp_wifi_init(&cfg);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "esp_wifi_init failed: %s", esp_err_to_name(ret));
        return;
    }

    esp_event_handler_instance_t instance_any_id;
    esp_event_handler_instance_t instance_got_ip;
    ret = esp_event_handler_instance_register(WIFI_EVENT,
                                              ESP_EVENT_ANY_ID,
                                              &wifi_event_handler,
                                              NULL,
                                              &instance_any_id);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to register WIFI_EVENT handler: %s", esp_err_to_name(ret));
    }

    ret = esp_event_handler_instance_register(IP_EVENT,
                                              IP_EVENT_STA_GOT_IP,
                                              &wifi_event_handler,
                                              NULL,
                                              &instance_got_ip);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to register IP_EVENT handler: %s", esp_err_to_name(ret));
    }

    s_wifi_initialized = true;
    ESP_LOGI(TAG, "WiFi pre-initialized successfully");
}

static int lua_wifi_init(lua_State *L)
{
    if (s_wifi_initialized) {
        lua_pushboolean(L, 1);
        return 1;
    }

    // Fallback: do full init if preinit wasn't called
    wifi_preinit();
    lua_pushboolean(L, s_wifi_initialized ? 1 : 0);
    return 1;
}

static int lua_wifi_connect(lua_State *L)
{
    const char *ssid = luaL_checkstring(L, 1);
    const char *password = luaL_checkstring(L, 2);

    if (!s_wifi_initialized) {
        lua_wifi_init(L);
        int init_result = lua_toboolean(L, -1);
        lua_pop(L, 1);
        if (!init_result) {
            ESP_LOGE(TAG, "WiFi init failed, cannot connect");
            lua_pushboolean(L, 0);
            return 1;
        }
    }

    wifi_config_t wifi_config = {
        .sta = {
            .threshold.authmode = WIFI_AUTH_WPA2_PSK,
            .pmf_cfg = {
                .capable = true,
                .required = false
            },
        },
    };

    strncpy((char *)wifi_config.sta.ssid, ssid, sizeof(wifi_config.sta.ssid) - 1);
    strncpy((char *)wifi_config.sta.password, password, sizeof(wifi_config.sta.password) - 1);

    esp_err_t ret;
    ret = esp_wifi_set_mode(WIFI_MODE_STA);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "esp_wifi_set_mode failed: %s", esp_err_to_name(ret));
        lua_pushboolean(L, 0);
        return 1;
    }

    ret = esp_wifi_set_config(WIFI_IF_STA, &wifi_config);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "esp_wifi_set_config failed: %s", esp_err_to_name(ret));
        lua_pushboolean(L, 0);
        return 1;
    }

    ret = esp_wifi_start();
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "esp_wifi_start failed: %s", esp_err_to_name(ret));
        lua_pushboolean(L, 0);
        return 1;
    }

    ESP_LOGI(TAG, "Connecting to %s...", ssid);

    EventBits_t bits = xEventGroupWaitBits(s_wifi_event_group,
            WIFI_CONNECTED_BIT | WIFI_FAIL_BIT,
            pdFALSE,
            pdFALSE,
            pdMS_TO_TICKS(15000));

    if (bits & WIFI_CONNECTED_BIT) {
        ESP_LOGI(TAG, "Connected to %s", ssid);
        lua_pushboolean(L, 1);
    } else if (bits & WIFI_FAIL_BIT) {
        ESP_LOGI(TAG, "Failed to connect to %s", ssid);
        lua_pushboolean(L, 0);
    } else {
        ESP_LOGE(TAG, "Connection timeout");
        lua_pushboolean(L, 0);
    }

    return 1;
}

static int lua_wifi_disconnect(lua_State *L)
{
    esp_wifi_disconnect();
    s_wifi_connected = false;
    lua_pushboolean(L, 1);
    return 1;
}

static int lua_wifi_is_connected(lua_State *L)
{
    lua_pushboolean(L, s_wifi_connected ? 1 : 0);
    return 1;
}

static int lua_wifi_get_ip(lua_State *L)
{
    if (!s_wifi_connected || !s_sta_netif) {
        lua_pushnil(L);
        return 1;
    }

    esp_netif_ip_info_t ip_info;
    if (esp_netif_get_ip_info(s_sta_netif, &ip_info) == ESP_OK) {
        char ip_str[16];
        snprintf(ip_str, sizeof(ip_str), IPSTR, IP2STR(&ip_info.ip));
        lua_pushstring(L, ip_str);
    } else {
        lua_pushnil(L);
    }

    return 1;
}

static int lua_wifi_get_rssi(lua_State *L)
{
    if (!s_wifi_connected) {
        lua_pushnil(L);
        return 1;
    }

    wifi_ap_record_t ap_info;
    if (esp_wifi_sta_get_ap_info(&ap_info) == ESP_OK) {
        lua_pushinteger(L, ap_info.rssi);
    } else {
        lua_pushnil(L);
    }

    return 1;
}

static const luaL_Reg wifi_funcs[] = {
    {"init", lua_wifi_init},
    {"connect", lua_wifi_connect},
    {"disconnect", lua_wifi_disconnect},
    {"is_connected", lua_wifi_is_connected},
    {"get_ip", lua_wifi_get_ip},
    {"get_rssi", lua_wifi_get_rssi},
    {NULL, NULL}
};

int luaopen_wifi(lua_State *L)
{
    luaL_newlib(L, wifi_funcs);
    return 1;
}
