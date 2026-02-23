/*
 * RGB Display Driver for CrowPanel ESP32-S3 5-inch
 * 
 * Uses ESP-IDF esp_lcd_panel_rgb for parallel RGB interface
 */

#include <string.h>
#include "rgb_display.h"
#include "driver/gpio.h"
#include "driver/ledc.h"
#include "esp_lcd_panel_ops.h"
#include "esp_lcd_panel_rgb.h"
#include "esp_heap_caps.h"
#include "esp_log.h"

static const char *TAG = "RGB_DISPLAY";

// CrowPanel 5-inch GPIO Pin Configuration (RGB565)
// Blue pins (B0-B4)
#define PIN_B0  GPIO_NUM_8
#define PIN_B1  GPIO_NUM_3
#define PIN_B2  GPIO_NUM_46
#define PIN_B3  GPIO_NUM_9
#define PIN_B4  GPIO_NUM_1

// Green pins (G0-G5)
#define PIN_G0  GPIO_NUM_5
#define PIN_G1  GPIO_NUM_6
#define PIN_G2  GPIO_NUM_7
#define PIN_G3  GPIO_NUM_15
#define PIN_G4  GPIO_NUM_16
#define PIN_G5  GPIO_NUM_4

// Red pins (R0-R4)
#define PIN_R0  GPIO_NUM_45
#define PIN_R1  GPIO_NUM_48
#define PIN_R2  GPIO_NUM_47
#define PIN_R3  GPIO_NUM_21
#define PIN_R4  GPIO_NUM_14

// Control pins
#define PIN_DE      GPIO_NUM_40   // Data Enable (HENABLE)
#define PIN_VSYNC   GPIO_NUM_41
#define PIN_HSYNC   GPIO_NUM_39
#define PIN_PCLK    GPIO_NUM_0
#define PIN_BL      GPIO_NUM_2    // Backlight PWM

// Timing parameters for CrowPanel 5-inch (800x480)
#define PCLK_FREQ_HZ        (12 * 1000 * 1000)  // 12 MHz pixel clock
#define HSYNC_BACK_PORCH    43
#define HSYNC_FRONT_PORCH   8
#define HSYNC_PULSE_WIDTH   4
#define VSYNC_BACK_PORCH    12
#define VSYNC_FRONT_PORCH   8
#define VSYNC_PULSE_WIDTH   4

// Backlight PWM configuration
#define BL_LEDC_TIMER       LEDC_TIMER_0
#define BL_LEDC_MODE        LEDC_LOW_SPEED_MODE
#define BL_LEDC_CHANNEL     LEDC_CHANNEL_0
#define BL_LEDC_DUTY_RES    LEDC_TIMER_8_BIT
#define BL_LEDC_FREQ_HZ     5000

// Internal state
static esp_lcd_panel_handle_t s_panel = NULL;
static uint16_t *s_framebuffer = NULL;
static bool s_initialized = false;

esp_err_t rgb_display_init(void)
{
    if (s_initialized) {
        ESP_LOGW(TAG, "Display already initialized");
        return ESP_OK;
    }

    ESP_LOGI(TAG, "Initializing CrowPanel 5-inch RGB display");
    ESP_LOGI(TAG, "Resolution: %dx%d, PCLK: %d Hz", 
             RGB_DISPLAY_WIDTH, RGB_DISPLAY_HEIGHT, PCLK_FREQ_HZ);

    // Configure backlight PWM
    ledc_timer_config_t bl_timer = {
        .speed_mode       = BL_LEDC_MODE,
        .timer_num        = BL_LEDC_TIMER,
        .duty_resolution  = BL_LEDC_DUTY_RES,
        .freq_hz          = BL_LEDC_FREQ_HZ,
        .clk_cfg          = LEDC_AUTO_CLK
    };
    ESP_ERROR_CHECK(ledc_timer_config(&bl_timer));

    ledc_channel_config_t bl_channel = {
        .speed_mode     = BL_LEDC_MODE,
        .channel        = BL_LEDC_CHANNEL,
        .timer_sel      = BL_LEDC_TIMER,
        .intr_type      = LEDC_INTR_DISABLE,
        .gpio_num       = PIN_BL,
        .duty           = 0,
        .hpoint         = 0
    };
    ESP_ERROR_CHECK(ledc_channel_config(&bl_channel));

    // Configure RGB panel
    esp_lcd_rgb_panel_config_t panel_config = {
        .clk_src = LCD_CLK_SRC_DEFAULT,
        .timings = {
            .pclk_hz = PCLK_FREQ_HZ,
            .h_res = RGB_DISPLAY_WIDTH,
            .v_res = RGB_DISPLAY_HEIGHT,
            .hsync_back_porch = HSYNC_BACK_PORCH,
            .hsync_front_porch = HSYNC_FRONT_PORCH,
            .hsync_pulse_width = HSYNC_PULSE_WIDTH,
            .vsync_back_porch = VSYNC_BACK_PORCH,
            .vsync_front_porch = VSYNC_FRONT_PORCH,
            .vsync_pulse_width = VSYNC_PULSE_WIDTH,
            .flags = {
                .pclk_active_neg = true,
                .hsync_idle_low = false,
                .vsync_idle_low = false,
                .de_idle_high = false,
            },
        },
        .data_width = 16,
        .num_fbs = 1,
        .psram_trans_align = 64,
        .hsync_gpio_num = PIN_HSYNC,
        .vsync_gpio_num = PIN_VSYNC,
        .de_gpio_num = PIN_DE,
        .pclk_gpio_num = PIN_PCLK,
        .disp_gpio_num = -1,  // No display enable pin
        .data_gpio_nums = {
            PIN_B0, PIN_B1, PIN_B2, PIN_B3, PIN_B4,  // B0-B4
            PIN_G0, PIN_G1, PIN_G2, PIN_G3, PIN_G4, PIN_G5,  // G0-G5
            PIN_R0, PIN_R1, PIN_R2, PIN_R3, PIN_R4,  // R0-R4
        },
        .flags = {
            .fb_in_psram = true,
            .double_fb = false,
            .no_fb = false,
            .bb_invalidate_cache = false,
        },
    };

    ESP_LOGI(TAG, "Creating RGB panel...");
    esp_err_t ret = esp_lcd_new_rgb_panel(&panel_config, &s_panel);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to create RGB panel: %s", esp_err_to_name(ret));
        return ret;
    }

    ESP_LOGI(TAG, "Resetting panel...");
    ret = esp_lcd_panel_reset(s_panel);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to reset panel: %s", esp_err_to_name(ret));
        return ret;
    }

    ESP_LOGI(TAG, "Initializing panel...");
    ret = esp_lcd_panel_init(s_panel);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to init panel: %s", esp_err_to_name(ret));
        return ret;
    }

    // Get framebuffer pointer from the panel
    void *fb_ptr = NULL;
    esp_lcd_rgb_panel_get_frame_buffer(s_panel, 1, &fb_ptr);
    s_framebuffer = (uint16_t *)fb_ptr;
    
    if (s_framebuffer == NULL) {
        ESP_LOGE(TAG, "Failed to get framebuffer");
        return ESP_ERR_NO_MEM;
    }

    ESP_LOGI(TAG, "Framebuffer at %p, size: %d bytes", 
             s_framebuffer, RGB_DISPLAY_WIDTH * RGB_DISPLAY_HEIGHT * 2);

    // Turn on backlight
    rgb_display_set_backlight(100);

    s_initialized = true;
    ESP_LOGI(TAG, "Display initialization complete");

    return ESP_OK;
}

void rgb_display_deinit(void)
{
    if (!s_initialized) return;

    rgb_display_set_backlight(0);
    
    if (s_panel) {
        esp_lcd_panel_del(s_panel);
        s_panel = NULL;
    }
    
    s_framebuffer = NULL;
    s_initialized = false;
}

uint16_t* rgb_display_get_framebuffer(void)
{
    return s_framebuffer;
}

void rgb_display_set_backlight(uint8_t brightness)
{
    if (brightness > 100) brightness = 100;
    uint32_t duty = (brightness * 255) / 100;
    ledc_set_duty(BL_LEDC_MODE, BL_LEDC_CHANNEL, duty);
    ledc_update_duty(BL_LEDC_MODE, BL_LEDC_CHANNEL);
}

// Basic drawing primitives - see rgb_draw.c for implementation
