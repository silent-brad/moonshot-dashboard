/*
 * RGB Display Driver for CrowPanel ESP32-S3 5-inch
 * 
 * Hardware: 800x480 RGB TFT LCD with ILI6122 + ILI5960 driver ICs
 * Interface: 16-bit parallel RGB (RGB565)
 * Touch: GT911 capacitive touch over I2C
 */

#ifndef RGB_DISPLAY_H
#define RGB_DISPLAY_H

#include <stdint.h>
#include <stdbool.h>
#include "esp_err.h"

#ifdef __cplusplus
extern "C" {
#endif

// Display dimensions
#define RGB_DISPLAY_WIDTH   800
#define RGB_DISPLAY_HEIGHT  480

// Color definitions (RGB565 format)
#define RGB565_BLACK        0x0000
#define RGB565_WHITE        0xFFFF
#define RGB565_RED          0xF800
#define RGB565_GREEN        0x07E0
#define RGB565_BLUE         0x001F
#define RGB565_YELLOW       0xFFE0
#define RGB565_CYAN         0x07FF
#define RGB565_MAGENTA      0xF81F
#define RGB565_ORANGE       0xFD20
#define RGB565_PINK         0xFE19
#define RGB565_PURPLE       0x8010
#define RGB565_GRAY         0x8410
#define RGB565_DARKGRAY     0x4208
#define RGB565_LIGHTGRAY    0xC618

// Convert RGB888 to RGB565
#define RGB565(r, g, b) (((r & 0xF8) << 8) | ((g & 0xFC) << 3) | ((b & 0xF8) >> 3))

/**
 * Initialize the RGB display
 * 
 * @return ESP_OK on success
 */
esp_err_t rgb_display_init(void);

/**
 * Deinitialize the RGB display
 */
void rgb_display_deinit(void);

/**
 * Get pointer to the framebuffer
 * 
 * @return Pointer to the RGB565 framebuffer
 */
uint16_t* rgb_display_get_framebuffer(void);

/**
 * Set backlight brightness
 * 
 * @param brightness 0-100 percent
 */
void rgb_display_set_backlight(uint8_t brightness);

// ===================== Drawing Functions =====================

/**
 * Clear the entire screen with a color
 * 
 * @param color RGB565 color value
 */
void rgb_display_clear(uint16_t color);

/**
 * Draw a single pixel
 * 
 * @param x X coordinate
 * @param y Y coordinate
 * @param color RGB565 color value
 */
void rgb_display_draw_pixel(int x, int y, uint16_t color);

/**
 * Read a pixel color
 * 
 * @param x X coordinate
 * @param y Y coordinate
 * @return RGB565 color value at the pixel
 */
uint16_t rgb_display_read_pixel(int x, int y);

/**
 * Draw a line using Bresenham's algorithm
 * 
 * @param x0 Start X coordinate
 * @param y0 Start Y coordinate
 * @param x1 End X coordinate
 * @param y1 End Y coordinate
 * @param color RGB565 color value
 */
void rgb_display_draw_line(int x0, int y0, int x1, int y1, uint16_t color);

/**
 * Draw a horizontal line (optimized)
 * 
 * @param x Start X coordinate
 * @param y Y coordinate
 * @param w Width
 * @param color RGB565 color value
 */
void rgb_display_draw_hline(int x, int y, int w, uint16_t color);

/**
 * Draw a vertical line (optimized)
 * 
 * @param x X coordinate
 * @param y Start Y coordinate
 * @param h Height
 * @param color RGB565 color value
 */
void rgb_display_draw_vline(int x, int y, int h, uint16_t color);

/**
 * Draw a rectangle (outline or filled)
 * 
 * @param x Top-left X coordinate
 * @param y Top-left Y coordinate
 * @param w Width
 * @param h Height
 * @param color RGB565 color value
 * @param filled true for filled, false for outline only
 */
void rgb_display_draw_rect(int x, int y, int w, int h, uint16_t color, bool filled);

/**
 * Draw a circle (outline or filled)
 * 
 * @param cx Center X coordinate
 * @param cy Center Y coordinate
 * @param r Radius
 * @param color RGB565 color value
 * @param filled true for filled, false for outline only
 */
void rgb_display_draw_circle(int cx, int cy, int r, uint16_t color, bool filled);

/**
 * Draw a triangle
 * 
 * @param x0, y0 First vertex
 * @param x1, y1 Second vertex
 * @param x2, y2 Third vertex
 * @param color RGB565 color value
 * @param filled true for filled, false for outline only
 */
void rgb_display_draw_triangle(int x0, int y0, int x1, int y1, int x2, int y2, 
                                uint16_t color, bool filled);

/**
 * Draw text using the built-in 8x16 font
 * 
 * @param x X coordinate
 * @param y Y coordinate
 * @param text Text string to draw
 * @param color RGB565 foreground color
 */
void rgb_display_draw_text(int x, int y, const char *text, uint16_t color);

/**
 * Draw text with background color
 * 
 * @param x X coordinate
 * @param y Y coordinate
 * @param text Text string to draw
 * @param fg_color RGB565 foreground color
 * @param bg_color RGB565 background color
 */
void rgb_display_draw_text_bg(int x, int y, const char *text, 
                               uint16_t fg_color, uint16_t bg_color);

/**
 * Draw a raw RGB565 image
 * 
 * @param x Top-left X coordinate
 * @param y Top-left Y coordinate
 * @param w Image width
 * @param h Image height
 * @param data Pointer to RGB565 pixel data
 */
void rgb_display_draw_image(int x, int y, int w, int h, const uint16_t *data);

#ifdef __cplusplus
}
#endif

#endif // RGB_DISPLAY_H
