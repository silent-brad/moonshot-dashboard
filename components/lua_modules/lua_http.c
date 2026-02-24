/*
 * Lua HTTP Module for ESP32
 */

#include <string.h>
#include <stdlib.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "esp_http_client.h"
#include "esp_tls.h"
#include "esp_crt_bundle.h"

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

static const char *TAG = "lua_http";

#define HTTP_MAX_RESPONSE_SIZE (16 * 1024)

typedef struct {
    char *buffer;
    int buffer_len;
    int buffer_size;
} http_response_t;

static esp_err_t http_event_handler(esp_http_client_event_t *evt)
{
    http_response_t *response = (http_response_t *)evt->user_data;

    switch (evt->event_id) {
        case HTTP_EVENT_ON_DATA:
            if (response && evt->data_len > 0) {
                int new_len = response->buffer_len + evt->data_len;
                if (new_len < response->buffer_size) {
                    memcpy(response->buffer + response->buffer_len, evt->data, evt->data_len);
                    response->buffer_len = new_len;
                    response->buffer[new_len] = '\0';
                }
            }
            break;
        default:
            break;
    }
    return ESP_OK;
}

static int lua_http_get(lua_State *L)
{
    const char *url = luaL_checkstring(L, 1);
    int timeout_ms = 10000;

    if (lua_gettop(L) >= 2 && lua_isnumber(L, 2)) {
        timeout_ms = lua_tointeger(L, 2);
    }

    http_response_t response = {
        .buffer = malloc(HTTP_MAX_RESPONSE_SIZE),
        .buffer_len = 0,
        .buffer_size = HTTP_MAX_RESPONSE_SIZE
    };

    if (!response.buffer) {
        lua_pushnil(L);
        lua_pushstring(L, "Memory allocation failed");
        return 2;
    }

    response.buffer[0] = '\0';

    esp_http_client_config_t config = {
        .url = url,
        .event_handler = http_event_handler,
        .user_data = &response,
        .timeout_ms = timeout_ms,
        .crt_bundle_attach = esp_crt_bundle_attach,
    };

    esp_http_client_handle_t client = esp_http_client_init(&config);
    if (!client) {
        free(response.buffer);
        lua_pushnil(L);
        lua_pushstring(L, "Failed to init HTTP client");
        return 2;
    }

    esp_http_client_set_header(client, "User-Agent", "MoonshotDashboard/1.0 ESP32");

    esp_err_t err = esp_http_client_perform(client);

    if (err == ESP_OK) {
        int status = esp_http_client_get_status_code(client);
        ESP_LOGI(TAG, "HTTP GET Status = %d, content_length = %lld",
                 status, esp_http_client_get_content_length(client));

        if (status >= 200 && status < 300) {
            lua_pushstring(L, response.buffer);
        } else {
            lua_pushnil(L);
            char err_msg[64];
            snprintf(err_msg, sizeof(err_msg), "HTTP error: %d", status);
            lua_pushstring(L, err_msg);
            esp_http_client_cleanup(client);
            free(response.buffer);
            return 2;
        }
    } else {
        ESP_LOGE(TAG, "HTTP GET failed: %s", esp_err_to_name(err));
        lua_pushnil(L);
        lua_pushstring(L, esp_err_to_name(err));
        esp_http_client_cleanup(client);
        free(response.buffer);
        return 2;
    }

    esp_http_client_cleanup(client);
    free(response.buffer);
    return 1;
}

static int lua_http_post(lua_State *L)
{
    const char *url = luaL_checkstring(L, 1);
    const char *post_data = luaL_optstring(L, 2, "");
    const char *content_type = luaL_optstring(L, 3, "application/json");
    int timeout_ms = 10000;

    if (lua_gettop(L) >= 4 && lua_isnumber(L, 4)) {
        timeout_ms = lua_tointeger(L, 4);
    }

    http_response_t response = {
        .buffer = malloc(HTTP_MAX_RESPONSE_SIZE),
        .buffer_len = 0,
        .buffer_size = HTTP_MAX_RESPONSE_SIZE
    };

    if (!response.buffer) {
        lua_pushnil(L);
        lua_pushstring(L, "Memory allocation failed");
        return 2;
    }

    response.buffer[0] = '\0';

    esp_http_client_config_t config = {
        .url = url,
        .event_handler = http_event_handler,
        .user_data = &response,
        .timeout_ms = timeout_ms,
        .method = HTTP_METHOD_POST,
        .crt_bundle_attach = esp_crt_bundle_attach,
    };

    esp_http_client_handle_t client = esp_http_client_init(&config);
    if (!client) {
        free(response.buffer);
        lua_pushnil(L);
        lua_pushstring(L, "Failed to init HTTP client");
        return 2;
    }

    esp_http_client_set_header(client, "Content-Type", content_type);
    esp_http_client_set_post_field(client, post_data, strlen(post_data));

    esp_err_t err = esp_http_client_perform(client);

    if (err == ESP_OK) {
        int status = esp_http_client_get_status_code(client);
        ESP_LOGI(TAG, "HTTP POST Status = %d", status);

        if (status >= 200 && status < 300) {
            lua_pushstring(L, response.buffer);
        } else {
            lua_pushnil(L);
            char err_msg[64];
            snprintf(err_msg, sizeof(err_msg), "HTTP error: %d", status);
            lua_pushstring(L, err_msg);
            esp_http_client_cleanup(client);
            free(response.buffer);
            return 2;
        }
    } else {
        ESP_LOGE(TAG, "HTTP POST failed: %s", esp_err_to_name(err));
        lua_pushnil(L);
        lua_pushstring(L, esp_err_to_name(err));
        esp_http_client_cleanup(client);
        free(response.buffer);
        return 2;
    }

    esp_http_client_cleanup(client);
    free(response.buffer);
    return 1;
}

static const luaL_Reg http_funcs[] = {
    {"get", lua_http_get},
    {"post", lua_http_post},
    {NULL, NULL}
};

int luaopen_http(lua_State *L)
{
    luaL_newlib(L, http_funcs);
    return 1;
}
