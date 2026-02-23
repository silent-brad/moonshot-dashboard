/*
 * Lua Core - Minimal Lua VM wrapper for ESP32-S3
 */

#include <stdio.h>
#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "esp_system.h"
#include "driver/uart.h"

#include "lua_core.h"

static const char *TAG = "LUA_CORE";

static lua_State *L = NULL;

// UART configuration for console
#define UART_NUM        UART_NUM_0
#define UART_BUF_SIZE   1024
#define LINE_BUF_SIZE   256

// Print function for Lua (writes to console)
static int lua_print(lua_State *L)
{
    int n = lua_gettop(L);
    for (int i = 1; i <= n; i++) {
        size_t len;
        const char *s = luaL_tolstring(L, i, &len);
        if (i > 1) printf("\t");
        printf("%s", s);
        lua_pop(L, 1);
    }
    printf("\n");
    return 0;
}

// Heap info function for Lua
static int lua_heap_info(lua_State *L)
{
    lua_pushinteger(L, esp_get_free_heap_size());
    lua_pushinteger(L, heap_caps_get_free_size(MALLOC_CAP_SPIRAM));
    return 2;
}

// Restart function
static int lua_restart(lua_State *L)
{
    esp_restart();
    return 0;
}

int lua_core_init(void)
{
    ESP_LOGI(TAG, "Initializing Lua VM...");
    
    L = luaL_newstate();
    if (!L) {
        ESP_LOGE(TAG, "Failed to create Lua state");
        return -1;
    }
    
    // Open standard libraries
    luaL_openlibs(L);
    
    // Register custom functions
    lua_register(L, "print", lua_print);
    lua_register(L, "heap", lua_heap_info);
    lua_register(L, "restart", lua_restart);
    
    ESP_LOGI(TAG, "Lua VM initialized");
    return 0;
}

lua_State* lua_core_get_state(void)
{
    return L;
}

int lua_core_dostring(const char *code)
{
    if (!L || !code) return -1;
    
    int result = luaL_dostring(L, code);
    if (result != LUA_OK) {
        const char *err = lua_tostring(L, -1);
        ESP_LOGE(TAG, "Error: %s", err ? err : "unknown error");
        lua_pop(L, 1);
    }
    return result;
}

int lua_core_dofile(const char *filename)
{
    if (!L || !filename) return -1;
    
    int result = luaL_dofile(L, filename);
    if (result != LUA_OK) {
        const char *err = lua_tostring(L, -1);
        ESP_LOGE(TAG, "Error loading %s: %s", filename, err ? err : "unknown error");
        lua_pop(L, 1);
    }
    return result;
}

void lua_core_register_function(const char *name, lua_CFunction func)
{
    if (!L || !name || !func) return;
    lua_register(L, name, func);
}

void lua_core_register_module(const char *name, const luaL_Reg *funcs)
{
    if (!L || !name || !funcs) return;
    
    // Count functions
    int n = 0;
    while (funcs[n].name != NULL) n++;
    
    lua_createtable(L, 0, n);
    luaL_setfuncs(L, funcs, 0);
    lua_setglobal(L, name);
}

// Read a line from UART
static int read_line(char *buf, int max_len)
{
    int pos = 0;
    while (pos < max_len - 1) {
        int c = getchar();
        if (c == EOF) {
            vTaskDelay(pdMS_TO_TICKS(10));
            continue;
        }
        
        if (c == '\n' || c == '\r') {
            printf("\n");
            buf[pos] = '\0';
            return pos;
        }
        
        if (c == '\b' || c == 127) {  // Backspace
            if (pos > 0) {
                pos--;
                printf("\b \b");
            }
            continue;
        }
        
        if (c >= 32 && c < 127) {
            buf[pos++] = c;
            putchar(c);
        }
    }
    buf[pos] = '\0';
    return pos;
}

void lua_core_run_repl(void)
{
    if (!L) {
        ESP_LOGE(TAG, "Lua not initialized");
        return;
    }
    
    char line[LINE_BUF_SIZE];
    char multiline[LINE_BUF_SIZE * 4];
    int multiline_len = 0;
    bool in_multiline = false;
    
    printf("\n");
    printf("  _                   ____  _____ ___  ____  \n");
    printf(" | |   _   _  __ _   |  _ \\|_   _/ _ \\/ ___| \n");
    printf(" | |  | | | |/ _` |  | |_) | | || | | \\___ \\ \n");
    printf(" | |__| |_| | (_| |  |  _ <  | || |_| |___) |\n");
    printf(" |_____\\__,_|\\__,_|  |_| \\_\\ |_| \\___/|____/ \n");
    printf("\n");
    printf("Lua RTOS for CrowPanel ESP32-S3\n");
    printf("Type 'help' for commands, 'quit' to exit REPL\n");
    printf("\n");
    
    while (1) {
        if (in_multiline) {
            printf(">> ");
        } else {
            printf("> ");
        }
        fflush(stdout);
        
        int len = read_line(line, sizeof(line));
        
        if (len == 0 && in_multiline) {
            // Empty line in multiline mode - execute
            in_multiline = false;
            if (multiline_len > 0) {
                lua_core_dostring(multiline);
            }
            multiline_len = 0;
            continue;
        }
        
        if (len == 0) continue;
        
        // Check for special commands
        if (!in_multiline && strcmp(line, "quit") == 0) {
            printf("Exiting REPL...\n");
            break;
        }
        
        if (!in_multiline && strcmp(line, "help") == 0) {
            printf("Commands:\n");
            printf("  help     - Show this help\n");
            printf("  quit     - Exit REPL\n");
            printf("  heap()   - Show free heap memory\n");
            printf("  restart()- Restart ESP32\n");
            printf("\n");
            printf("Lua modules:\n");
            printf("  display  - RGB display functions\n");
            printf("\n");
            continue;
        }
        
        // Check if line ends with continuation indicator
        if (line[len-1] == '\\' || 
            (len > 0 && (strstr(line, "function") || strstr(line, "do") || 
                         strstr(line, "if") || strstr(line, "for") || 
                         strstr(line, "while")))) {
            // Start or continue multiline input
            if (!in_multiline) {
                multiline_len = 0;
                in_multiline = true;
            }
            
            if (line[len-1] == '\\') {
                line[len-1] = '\0';
                len--;
            }
            
            if (multiline_len + len + 2 < sizeof(multiline)) {
                strcpy(multiline + multiline_len, line);
                multiline_len += len;
                multiline[multiline_len++] = '\n';
                multiline[multiline_len] = '\0';
            }
            
            // Check if we have a complete statement
            if (strstr(line, "end")) {
                in_multiline = false;
                lua_core_dostring(multiline);
                multiline_len = 0;
            }
            continue;
        }
        
        // Single line execution
        if (in_multiline) {
            if (multiline_len + len + 2 < sizeof(multiline)) {
                strcpy(multiline + multiline_len, line);
                multiline_len += len;
                multiline[multiline_len++] = '\n';
                multiline[multiline_len] = '\0';
            }
        } else {
            // Try to execute as expression first (for things like "1+1")
            char expr_buf[LINE_BUF_SIZE + 16];
            snprintf(expr_buf, sizeof(expr_buf), "return %s", line);
            
            if (luaL_dostring(L, expr_buf) == LUA_OK) {
                // Print result if any
                int n = lua_gettop(L);
                for (int i = 1; i <= n; i++) {
                    const char *s = lua_tostring(L, i);
                    if (s) printf("%s\n", s);
                }
                lua_settop(L, 0);
            } else {
                lua_pop(L, 1);  // Pop error from expression attempt
                // Execute as statement
                lua_core_dostring(line);
            }
        }
    }
}
