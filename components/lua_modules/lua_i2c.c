/*
 * Lua I2C Module - I2C bindings for Lua
 * 
 * Usage in Lua:
 *   i2c.init(0, 19, 20, 400000)  -- port, sda, scl, freq
 *   i2c.write(0, 0x14, {0x00})   -- port, addr, data
 *   data = i2c.read(0, 0x14, 5)  -- port, addr, len -> returns table
 */

#include <string.h>
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include "driver/i2c.h"
#include "esp_log.h"

static const char *TAG = "LUA_I2C";

#define I2C_TIMEOUT_MS  1000

// Track which I2C ports are initialized
static bool i2c_initialized[I2C_NUM_MAX] = {false};

// i2c.init(port, sda_pin, scl_pin, freq_hz)
static int l_i2c_init(lua_State *L)
{
    int port = luaL_checkinteger(L, 1);
    int sda_pin = luaL_checkinteger(L, 2);
    int scl_pin = luaL_checkinteger(L, 3);
    int freq_hz = luaL_optinteger(L, 4, 100000);
    
    if (port < 0 || port >= I2C_NUM_MAX) {
        return luaL_error(L, "Invalid I2C port: %d", port);
    }
    
    // Uninstall if already installed
    if (i2c_initialized[port]) {
        i2c_driver_delete(port);
        i2c_initialized[port] = false;
    }
    
    i2c_config_t conf = {
        .mode = I2C_MODE_MASTER,
        .sda_io_num = sda_pin,
        .scl_io_num = scl_pin,
        .sda_pullup_en = GPIO_PULLUP_ENABLE,
        .scl_pullup_en = GPIO_PULLUP_ENABLE,
        .master.clk_speed = freq_hz,
    };
    
    esp_err_t ret = i2c_param_config(port, &conf);
    if (ret != ESP_OK) {
        return luaL_error(L, "I2C config failed: %d", ret);
    }
    
    ret = i2c_driver_install(port, I2C_MODE_MASTER, 0, 0, 0);
    if (ret != ESP_OK) {
        return luaL_error(L, "I2C driver install failed: %d", ret);
    }
    
    i2c_initialized[port] = true;
    ESP_LOGI(TAG, "I2C%d initialized: SDA=%d, SCL=%d, freq=%d Hz", 
             port, sda_pin, scl_pin, freq_hz);
    
    lua_pushboolean(L, 1);
    return 1;
}

// i2c.deinit(port)
static int l_i2c_deinit(lua_State *L)
{
    int port = luaL_checkinteger(L, 1);
    
    if (port < 0 || port >= I2C_NUM_MAX) {
        return luaL_error(L, "Invalid I2C port: %d", port);
    }
    
    if (i2c_initialized[port]) {
        i2c_driver_delete(port);
        i2c_initialized[port] = false;
    }
    
    return 0;
}

// i2c.write(port, addr, data)
// data can be a table of bytes or a string
static int l_i2c_write(lua_State *L)
{
    int port = luaL_checkinteger(L, 1);
    int addr = luaL_checkinteger(L, 2);
    
    if (port < 0 || port >= I2C_NUM_MAX || !i2c_initialized[port]) {
        return luaL_error(L, "I2C port %d not initialized", port);
    }
    
    uint8_t *data = NULL;
    size_t data_len = 0;
    
    if (lua_istable(L, 3)) {
        data_len = lua_rawlen(L, 3);
        data = malloc(data_len);
        if (!data) {
            return luaL_error(L, "Memory allocation failed");
        }
        
        for (size_t i = 0; i < data_len; i++) {
            lua_rawgeti(L, 3, i + 1);
            data[i] = (uint8_t)lua_tointeger(L, -1);
            lua_pop(L, 1);
        }
    } else if (lua_isstring(L, 3)) {
        data = (uint8_t *)lua_tolstring(L, 3, &data_len);
    } else {
        return luaL_error(L, "Expected table or string for data");
    }
    
    i2c_cmd_handle_t cmd = i2c_cmd_link_create();
    i2c_master_start(cmd);
    i2c_master_write_byte(cmd, (addr << 1) | I2C_MASTER_WRITE, true);
    if (data_len > 0) {
        i2c_master_write(cmd, data, data_len, true);
    }
    i2c_master_stop(cmd);
    
    esp_err_t ret = i2c_master_cmd_begin(port, cmd, pdMS_TO_TICKS(I2C_TIMEOUT_MS));
    i2c_cmd_link_delete(cmd);
    
    if (lua_istable(L, 3)) {
        free(data);
    }
    
    if (ret != ESP_OK) {
        lua_pushboolean(L, 0);
        lua_pushinteger(L, ret);
        return 2;
    }
    
    lua_pushboolean(L, 1);
    return 1;
}

// data = i2c.read(port, addr, len)
// Returns a table of bytes
static int l_i2c_read(lua_State *L)
{
    int port = luaL_checkinteger(L, 1);
    int addr = luaL_checkinteger(L, 2);
    int len = luaL_checkinteger(L, 3);
    
    if (port < 0 || port >= I2C_NUM_MAX || !i2c_initialized[port]) {
        return luaL_error(L, "I2C port %d not initialized", port);
    }
    
    if (len <= 0 || len > 256) {
        return luaL_error(L, "Invalid read length: %d", len);
    }
    
    uint8_t *data = malloc(len);
    if (!data) {
        return luaL_error(L, "Memory allocation failed");
    }
    
    i2c_cmd_handle_t cmd = i2c_cmd_link_create();
    i2c_master_start(cmd);
    i2c_master_write_byte(cmd, (addr << 1) | I2C_MASTER_READ, true);
    if (len > 1) {
        i2c_master_read(cmd, data, len - 1, I2C_MASTER_ACK);
    }
    i2c_master_read_byte(cmd, data + len - 1, I2C_MASTER_NACK);
    i2c_master_stop(cmd);
    
    esp_err_t ret = i2c_master_cmd_begin(port, cmd, pdMS_TO_TICKS(I2C_TIMEOUT_MS));
    i2c_cmd_link_delete(cmd);
    
    if (ret != ESP_OK) {
        free(data);
        lua_pushnil(L);
        lua_pushinteger(L, ret);
        return 2;
    }
    
    // Return as table
    lua_newtable(L);
    for (int i = 0; i < len; i++) {
        lua_pushinteger(L, data[i]);
        lua_rawseti(L, -2, i + 1);
    }
    
    free(data);
    return 1;
}

// i2c.writeread(port, addr, write_data, read_len)
// Write then read without stop in between
static int l_i2c_writeread(lua_State *L)
{
    int port = luaL_checkinteger(L, 1);
    int addr = luaL_checkinteger(L, 2);
    int read_len = luaL_checkinteger(L, 4);
    
    if (port < 0 || port >= I2C_NUM_MAX || !i2c_initialized[port]) {
        return luaL_error(L, "I2C port %d not initialized", port);
    }
    
    uint8_t *write_data = NULL;
    size_t write_len = 0;
    bool free_write = false;
    
    if (lua_istable(L, 3)) {
        write_len = lua_rawlen(L, 3);
        write_data = malloc(write_len);
        if (!write_data) {
            return luaL_error(L, "Memory allocation failed");
        }
        free_write = true;
        
        for (size_t i = 0; i < write_len; i++) {
            lua_rawgeti(L, 3, i + 1);
            write_data[i] = (uint8_t)lua_tointeger(L, -1);
            lua_pop(L, 1);
        }
    } else if (lua_isstring(L, 3)) {
        write_data = (uint8_t *)lua_tolstring(L, 3, &write_len);
    } else {
        return luaL_error(L, "Expected table or string for write data");
    }
    
    uint8_t *read_data = malloc(read_len);
    if (!read_data) {
        if (free_write) free(write_data);
        return luaL_error(L, "Memory allocation failed");
    }
    
    i2c_cmd_handle_t cmd = i2c_cmd_link_create();
    
    // Write phase
    i2c_master_start(cmd);
    i2c_master_write_byte(cmd, (addr << 1) | I2C_MASTER_WRITE, true);
    if (write_len > 0) {
        i2c_master_write(cmd, write_data, write_len, true);
    }
    
    // Read phase (repeated start)
    i2c_master_start(cmd);
    i2c_master_write_byte(cmd, (addr << 1) | I2C_MASTER_READ, true);
    if (read_len > 1) {
        i2c_master_read(cmd, read_data, read_len - 1, I2C_MASTER_ACK);
    }
    i2c_master_read_byte(cmd, read_data + read_len - 1, I2C_MASTER_NACK);
    i2c_master_stop(cmd);
    
    esp_err_t ret = i2c_master_cmd_begin(port, cmd, pdMS_TO_TICKS(I2C_TIMEOUT_MS));
    i2c_cmd_link_delete(cmd);
    
    if (free_write) free(write_data);
    
    if (ret != ESP_OK) {
        free(read_data);
        lua_pushnil(L);
        lua_pushinteger(L, ret);
        return 2;
    }
    
    // Return as table
    lua_newtable(L);
    for (int i = 0; i < read_len; i++) {
        lua_pushinteger(L, read_data[i]);
        lua_rawseti(L, -2, i + 1);
    }
    
    free(read_data);
    return 1;
}

// devices = i2c.scan(port)
// Scans all addresses and returns a table of responding devices
static int l_i2c_scan(lua_State *L)
{
    int port = luaL_checkinteger(L, 1);
    
    if (port < 0 || port >= I2C_NUM_MAX || !i2c_initialized[port]) {
        return luaL_error(L, "I2C port %d not initialized", port);
    }
    
    lua_newtable(L);
    int found = 0;
    
    for (int addr = 0x08; addr < 0x78; addr++) {
        i2c_cmd_handle_t cmd = i2c_cmd_link_create();
        i2c_master_start(cmd);
        i2c_master_write_byte(cmd, (addr << 1) | I2C_MASTER_WRITE, true);
        i2c_master_stop(cmd);
        
        esp_err_t ret = i2c_master_cmd_begin(port, cmd, pdMS_TO_TICKS(50));
        i2c_cmd_link_delete(cmd);
        
        if (ret == ESP_OK) {
            found++;
            lua_pushinteger(L, addr);
            lua_rawseti(L, -2, found);
        }
    }
    
    return 1;
}

// Module function table
static const luaL_Reg i2c_lib[] = {
    {"init",      l_i2c_init},
    {"deinit",    l_i2c_deinit},
    {"write",     l_i2c_write},
    {"read",      l_i2c_read},
    {"writeread", l_i2c_writeread},
    {"scan",      l_i2c_scan},
    {NULL, NULL}
};

int luaopen_i2c_module(lua_State *L)
{
    luaL_newlib(L, i2c_lib);
    
    // Add I2C port constants
    lua_pushinteger(L, 0); lua_setfield(L, -2, "PORT0");
    lua_pushinteger(L, 1); lua_setfield(L, -2, "PORT1");
    
    return 1;
}
