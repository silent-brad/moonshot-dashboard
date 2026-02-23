/*
 * Lua RTOS for CrowPanel ESP32-S3 5-inch Display
 * Main entry point
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

// Embedded Lua script
extern const uint8_t main_lua_start[] asm("_binary_main_lua_start");
extern const uint8_t main_lua_end[] asm("_binary_main_lua_end");

void app_main(void)
{
    ESP_LOGI(TAG, "Moonshot Display");
    
    // Initialize NVS
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);

    // Log memory info
    ESP_LOGI(TAG, "Free heap: %u bytes", (unsigned int)esp_get_free_heap_size());
    ESP_LOGI(TAG, "Free PSRAM: %u bytes", (unsigned int)heap_caps_get_free_size(MALLOC_CAP_SPIRAM));

    // Initialize RGB display
    ESP_LOGI(TAG, "Initializing RGB display...");
    ret = rgb_display_init();
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to initialize RGB display: %s", esp_err_to_name(ret));
    } else {
        ESP_LOGI(TAG, "RGB display initialized successfully");
        rgb_display_clear(RGB565_BLACK);
    }

    // Start Lua REPL
    ESP_LOGI(TAG, "Starting Lua REPL...");
    lua_core_init();
    
    // Initialize Lua modules (display, i2c, etc.)
    lua_State *L = lua_core_get_state();
    if (L) {
        lua_modules_init(L);
        
        // Run embedded main.lua script
        ESP_LOGI(TAG, "Running Moonshot Display...");
        size_t main_len = main_lua_end - main_lua_start;
        char *main_code = malloc(main_len + 1);
        if (main_code) {
            memcpy(main_code, main_lua_start, main_len);
            main_code[main_len] = '\0';
            lua_core_dostring(main_code);
            free(main_code);
            
            // Run (4 seconds per moonshot, 1 loop)
            lua_core_dostring("moonshot.full(4, 1)");
        }
    }
    
    lua_core_run_repl();
}
