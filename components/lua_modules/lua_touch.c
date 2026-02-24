/*
 * Lua Touch Module - GT911 capacitive touch controller
 * 
 * CrowPanel 5" uses GT911 via I2C at address 0x5D or 0x14
 * I2C: SDA=19, SCL=20
 * Interrupt: GPIO38
 */

#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/queue.h"
#include "driver/gpio.h"
#include "driver/i2c.h"
#include "esp_log.h"

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

static const char *TAG = "lua_touch";

// GT911 Configuration
#define GT911_I2C_PORT      I2C_NUM_0
#define GT911_SDA_PIN       19
#define GT911_SCL_PIN       20
#define GT911_INT_PIN       38
#define GT911_RST_PIN       -1  // Not used on CrowPanel 5"
#define GT911_I2C_FREQ      400000

// GT911 can be at 0x5D or 0x14 depending on reset sequence
#define GT911_ADDR_PRIMARY  0x5D
#define GT911_ADDR_ALT      0x14

// GT911 Registers
#define GT911_REG_STATUS    0x814E
#define GT911_REG_POINT1    0x8150
#define GT911_REG_CONFIG    0x8047
#define GT911_REG_PRODUCT   0x8140

static bool s_touch_initialized = false;
static uint8_t s_gt911_addr = GT911_ADDR_PRIMARY;
static int s_last_x = 0;
static int s_last_y = 0;
static bool s_touched = false;

static bool gt911_i2c_read(uint16_t reg, uint8_t *data, size_t len)
{
    uint8_t reg_buf[2] = { (reg >> 8) & 0xFF, reg & 0xFF };
    
    i2c_cmd_handle_t cmd = i2c_cmd_link_create();
    i2c_master_start(cmd);
    i2c_master_write_byte(cmd, (s_gt911_addr << 1) | I2C_MASTER_WRITE, true);
    i2c_master_write(cmd, reg_buf, 2, true);
    i2c_master_start(cmd);
    i2c_master_write_byte(cmd, (s_gt911_addr << 1) | I2C_MASTER_READ, true);
    if (len > 1) {
        i2c_master_read(cmd, data, len - 1, I2C_MASTER_ACK);
    }
    i2c_master_read_byte(cmd, data + len - 1, I2C_MASTER_NACK);
    i2c_master_stop(cmd);
    
    esp_err_t ret = i2c_master_cmd_begin(GT911_I2C_PORT, cmd, pdMS_TO_TICKS(100));
    i2c_cmd_link_delete(cmd);
    
    return ret == ESP_OK;
}

static bool gt911_i2c_write(uint16_t reg, uint8_t *data, size_t len)
{
    uint8_t *buf = malloc(2 + len);
    if (!buf) return false;
    
    buf[0] = (reg >> 8) & 0xFF;
    buf[1] = reg & 0xFF;
    if (len > 0 && data) {
        memcpy(buf + 2, data, len);
    }
    
    i2c_cmd_handle_t cmd = i2c_cmd_link_create();
    i2c_master_start(cmd);
    i2c_master_write_byte(cmd, (s_gt911_addr << 1) | I2C_MASTER_WRITE, true);
    i2c_master_write(cmd, buf, 2 + len, true);
    i2c_master_stop(cmd);
    
    esp_err_t ret = i2c_master_cmd_begin(GT911_I2C_PORT, cmd, pdMS_TO_TICKS(100));
    i2c_cmd_link_delete(cmd);
    
    free(buf);
    return ret == ESP_OK;
}

static bool gt911_detect(void)
{
    // Try primary address
    i2c_cmd_handle_t cmd = i2c_cmd_link_create();
    i2c_master_start(cmd);
    i2c_master_write_byte(cmd, (GT911_ADDR_PRIMARY << 1) | I2C_MASTER_WRITE, true);
    i2c_master_stop(cmd);
    esp_err_t ret = i2c_master_cmd_begin(GT911_I2C_PORT, cmd, pdMS_TO_TICKS(50));
    i2c_cmd_link_delete(cmd);
    
    if (ret == ESP_OK) {
        s_gt911_addr = GT911_ADDR_PRIMARY;
        ESP_LOGI(TAG, "GT911 found at 0x%02X", s_gt911_addr);
        return true;
    }
    
    // Try alternate address
    cmd = i2c_cmd_link_create();
    i2c_master_start(cmd);
    i2c_master_write_byte(cmd, (GT911_ADDR_ALT << 1) | I2C_MASTER_WRITE, true);
    i2c_master_stop(cmd);
    ret = i2c_master_cmd_begin(GT911_I2C_PORT, cmd, pdMS_TO_TICKS(50));
    i2c_cmd_link_delete(cmd);
    
    if (ret == ESP_OK) {
        s_gt911_addr = GT911_ADDR_ALT;
        ESP_LOGI(TAG, "GT911 found at 0x%02X", s_gt911_addr);
        return true;
    }
    
    ESP_LOGE(TAG, "GT911 not found");
    return false;
}

// touch.init()
static int lua_touch_init(lua_State *L)
{
    if (s_touch_initialized) {
        lua_pushboolean(L, 1);
        return 1;
    }
    
    // Initialize I2C
    i2c_config_t conf = {
        .mode = I2C_MODE_MASTER,
        .sda_io_num = GT911_SDA_PIN,
        .scl_io_num = GT911_SCL_PIN,
        .sda_pullup_en = GPIO_PULLUP_ENABLE,
        .scl_pullup_en = GPIO_PULLUP_ENABLE,
        .master.clk_speed = GT911_I2C_FREQ,
    };
    
    esp_err_t ret = i2c_param_config(GT911_I2C_PORT, &conf);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "I2C config failed: %s", esp_err_to_name(ret));
        lua_pushboolean(L, 0);
        return 1;
    }
    
    ret = i2c_driver_install(GT911_I2C_PORT, I2C_MODE_MASTER, 0, 0, 0);
    if (ret != ESP_OK && ret != ESP_ERR_INVALID_STATE) {
        ESP_LOGE(TAG, "I2C driver install failed: %s", esp_err_to_name(ret));
        lua_pushboolean(L, 0);
        return 1;
    }
    
    // Configure interrupt pin as input
    gpio_config_t io_conf = {
        .pin_bit_mask = (1ULL << GT911_INT_PIN),
        .mode = GPIO_MODE_INPUT,
        .pull_up_en = GPIO_PULLUP_DISABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    gpio_config(&io_conf);
    
    // Detect GT911
    vTaskDelay(pdMS_TO_TICKS(100));
    if (!gt911_detect()) {
        lua_pushboolean(L, 0);
        return 1;
    }
    
    // Read product ID to verify
    uint8_t product_id[4] = {0};
    if (gt911_i2c_read(GT911_REG_PRODUCT, product_id, 4)) {
        ESP_LOGI(TAG, "GT911 Product ID: %c%c%c%c", 
                 product_id[0], product_id[1], product_id[2], product_id[3]);
    }
    
    s_touch_initialized = true;
    ESP_LOGI(TAG, "Touch initialized successfully");
    
    lua_pushboolean(L, 1);
    return 1;
}

// x, y, touched = touch.read()
static int lua_touch_read(lua_State *L)
{
    if (!s_touch_initialized) {
        lua_pushnil(L);
        lua_pushnil(L);
        lua_pushboolean(L, 0);
        return 3;
    }
    
    // Read status register
    uint8_t status = 0;
    if (!gt911_i2c_read(GT911_REG_STATUS, &status, 1)) {
        lua_pushinteger(L, s_last_x);
        lua_pushinteger(L, s_last_y);
        lua_pushboolean(L, 0);
        return 3;
    }
    
    uint8_t num_points = status & 0x0F;
    bool buffer_ready = (status & 0x80) != 0;
    
    if (buffer_ready && num_points > 0 && num_points < 6) {
        // Read first touch point (8 bytes per point)
        uint8_t point_data[8] = {0};
        if (gt911_i2c_read(GT911_REG_POINT1, point_data, 8)) {
            s_last_x = point_data[1] | (point_data[2] << 8);
            s_last_y = point_data[3] | (point_data[4] << 8);
            s_touched = true;
        }
        
        // Clear status
        uint8_t clear = 0;
        gt911_i2c_write(GT911_REG_STATUS, &clear, 1);
    } else if (buffer_ready) {
        // No touch, clear buffer
        uint8_t clear = 0;
        gt911_i2c_write(GT911_REG_STATUS, &clear, 1);
        s_touched = false;
    }
    
    lua_pushinteger(L, s_last_x);
    lua_pushinteger(L, s_last_y);
    lua_pushboolean(L, s_touched ? 1 : 0);
    return 3;
}

// touched = touch.is_touched()
static int lua_touch_is_touched(lua_State *L)
{
    if (!s_touch_initialized) {
        lua_pushboolean(L, 0);
        return 1;
    }
    
    // Check interrupt pin (active low on GT911)
    int level = gpio_get_level(GT911_INT_PIN);
    lua_pushboolean(L, level == 0 ? 1 : 0);
    return 1;
}

// x, y = touch.get_point()
static int lua_touch_get_point(lua_State *L)
{
    lua_pushinteger(L, s_last_x);
    lua_pushinteger(L, s_last_y);
    return 2;
}

static const luaL_Reg touch_lib[] = {
    {"init",       lua_touch_init},
    {"read",       lua_touch_read},
    {"is_touched", lua_touch_is_touched},
    {"get_point",  lua_touch_get_point},
    {NULL, NULL}
};

int luaopen_touch(lua_State *L)
{
    luaL_newlib(L, touch_lib);
    
    // Add constants
    lua_pushinteger(L, 800); lua_setfield(L, -2, "WIDTH");
    lua_pushinteger(L, 480); lua_setfield(L, -2, "HEIGHT");
    
    return 1;
}
