/*
 * Lua RTOS for CrowPanel ESP32-S3 5-inch Display
 * Main entry point - Moonshot Cyberpunk Dashboard
 */

#include <stdio.h>
#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_system.h"
#include "esp_log.h"
#include "esp_heap_caps.h"
#include "nvs_flash.h"

#include "rgb_display.h"
#include "lua_core.h"
#include "lua_modules.h"

static const char *TAG = "LuaRTOS";

extern const uint8_t dashboard_main_lua_start[] asm("_binary_main_lua_start");
extern const uint8_t dashboard_main_lua_end[] asm("_binary_main_lua_end");

extern const uint8_t dashboard_init_lua_start[] asm("_binary_init_lua_start");
extern const uint8_t dashboard_init_lua_end[] asm("_binary_init_lua_end");

extern const uint8_t dashboard_weather_lua_start[] asm("_binary_weather_lua_start");
extern const uint8_t dashboard_weather_lua_end[] asm("_binary_weather_lua_end");

extern const uint8_t dashboard_btc_lua_start[] asm("_binary_btc_lua_start");
extern const uint8_t dashboard_btc_lua_end[] asm("_binary_btc_lua_end");

extern const uint8_t dashboard_verse_lua_start[] asm("_binary_verse_lua_start");
extern const uint8_t dashboard_verse_lua_end[] asm("_binary_verse_lua_end");

extern const uint8_t config_lua_start[] asm("_binary_config_lua_start");
extern const uint8_t config_lua_end[] asm("_binary_config_lua_end");

extern const uint8_t env_start[] asm("_binary__env_start");
extern const uint8_t env_end[] asm("_binary__env_end");

static void register_embedded_module(lua_State *L, const char *name,
                                      const uint8_t *start, const uint8_t *end)
{
    size_t len = end - start;
    char *code = malloc(len + 1);
    if (code) {
        memcpy(code, start, len);
        code[len] = '\0';
        
        lua_getglobal(L, "package");
        lua_getfield(L, -1, "preload");
        
        if (luaL_loadstring(L, code) == LUA_OK) {
            lua_setfield(L, -2, name);
            ESP_LOGI(TAG, "Registered module: %s", name);
        } else {
            ESP_LOGE(TAG, "Failed to load module %s: %s", name, lua_tostring(L, -1));
            lua_pop(L, 1);
        }
        
        lua_pop(L, 2);
        free(code);
    }
}

static void register_embedded_string(lua_State *L, const char *name,
                                      const uint8_t *start, const uint8_t *end)
{
    size_t len = end - start;
    char *content = malloc(len + 1);
    if (content) {
        memcpy(content, start, len);
        content[len] = '\0';
        
        lua_getglobal(L, "package");
        lua_getfield(L, -1, "preload");
        
        lua_pushfstring(L, "return [[%s]]", content);
        if (luaL_loadstring(L, lua_tostring(L, -1)) == LUA_OK) {
            lua_remove(L, -2);
            lua_setfield(L, -2, name);
            ESP_LOGI(TAG, "Registered string: %s", name);
        } else {
            ESP_LOGE(TAG, "Failed to register string %s: %s", name, lua_tostring(L, -1));
            lua_pop(L, 2);
        }
        
        lua_pop(L, 2);
        free(content);
    }
}

void app_main(void)
{
    ESP_LOGI(TAG, "Moonshot Cyberpunk Dashboard");
    
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);

    ESP_LOGI(TAG, "Free heap: %u bytes", (unsigned int)esp_get_free_heap_size());
    ESP_LOGI(TAG, "Free PSRAM: %u bytes", (unsigned int)heap_caps_get_free_size(MALLOC_CAP_SPIRAM));

    ESP_LOGI(TAG, "Initializing RGB display...");
    ret = rgb_display_init();
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to initialize RGB display: %s", esp_err_to_name(ret));
    } else {
        ESP_LOGI(TAG, "RGB display initialized successfully");
        rgb_display_clear(RGB565_BLACK);
    }

    ESP_LOGI(TAG, "Starting Lua REPL...");
    lua_core_init();
    
    lua_State *L = lua_core_get_state();
    if (L) {
        lua_modules_init(L);
        
        ESP_LOGI(TAG, "Loading config and modules...");
        
        register_embedded_string(L, "config.env", env_start, env_end);
        register_embedded_module(L, "config", config_lua_start, config_lua_end);
        
        register_embedded_module(L, "dashboard.init", 
                                  dashboard_init_lua_start, dashboard_init_lua_end);
        register_embedded_module(L, "dashboard.weather", 
                                  dashboard_weather_lua_start, dashboard_weather_lua_end);
        register_embedded_module(L, "dashboard.btc", 
                                  dashboard_btc_lua_start, dashboard_btc_lua_end);
        register_embedded_module(L, "dashboard.verse", 
                                  dashboard_verse_lua_start, dashboard_verse_lua_end);
        
        ESP_LOGI(TAG, "Running Moonshot Dashboard...");
        size_t main_len = dashboard_main_lua_end - dashboard_main_lua_start;
        char *main_code = malloc(main_len + 1);
        if (main_code) {
            memcpy(main_code, dashboard_main_lua_start, main_len);
            main_code[main_len] = '\0';
            lua_core_dostring(main_code);
            free(main_code);
            
            lua_core_dostring("dashboard.run()");
        }
    }
    
    lua_core_run_repl();
}
