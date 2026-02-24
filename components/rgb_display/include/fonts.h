/*
 * Font System for RGB Display
 * 
 * Supports multiple bitmap fonts with different sizes
 */

#ifndef FONTS_H
#define FONTS_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Font IDs
typedef enum {
    FONT_DEFAULT = 0,      // Default font (Inter 20px)
    FONT_INTER_20,         // Inter 20px (body text)
    FONT_GARAMOND_20,      // EB Garamond 20px (headings)
    FONT_COUNT
} font_id_t;

// Font glyph descriptor
typedef struct {
    uint16_t bitmap_offset;  // Offset into bitmap array
    uint8_t width;           // Glyph width in pixels
    uint8_t height;          // Glyph height in pixels  
    int8_t x_offset;         // X offset for rendering
    int8_t y_offset;         // Y offset from baseline
    uint8_t x_advance;       // Horizontal advance to next char
} font_glyph_t;

// Font descriptor
typedef struct {
    const uint8_t *bitmap;       // Glyph bitmap data
    const font_glyph_t *glyphs;  // Glyph descriptors (indexed by char - first_char)
    uint8_t first_char;          // First ASCII character
    uint8_t last_char;           // Last ASCII character
    uint8_t line_height;         // Line height in pixels
    uint8_t baseline;            // Baseline offset from top
} font_t;

// Get font by ID
const font_t* font_get(font_id_t id);

// Get glyph for a character
const font_glyph_t* font_get_glyph(const font_t *font, char c);

// Calculate string width in pixels
int font_string_width(const font_t *font, const char *str);

// Set current font for text rendering
void rgb_display_set_font(font_id_t id);

// Get current font
font_id_t rgb_display_get_font(void);

// Draw text with specified font
void rgb_display_draw_text_font(int x, int y, const char *text, uint16_t color, font_id_t font_id);

#ifdef __cplusplus
}
#endif

#endif // FONTS_H
