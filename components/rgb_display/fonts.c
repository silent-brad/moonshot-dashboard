/*
 * Font System Implementation
 */

#include <string.h>
#include "fonts.h"
#include "rgb_display.h"

// External font declarations
extern const font_t font_inter_20;
extern const font_t font_garamond_20;

// Default built-in 8x16 font (from rgb_draw.c)
extern const uint8_t font8x16[];

static font_id_t current_font = FONT_DEFAULT;

const font_t* font_get(font_id_t id)
{
    switch (id) {
        case FONT_INTER_20:
        case FONT_DEFAULT:
            return &font_inter_20;
        case FONT_GARAMOND_20:
            return &font_garamond_20;
        default:
            return &font_inter_20;
    }
}

const font_glyph_t* font_get_glyph(const font_t *font, char c)
{
    if (!font) return NULL;
    if (c < font->first_char || c > font->last_char) return NULL;
    return &font->glyphs[c - font->first_char];
}

int font_string_width(const font_t *font, const char *str)
{
    if (!str) return 0;
    
    if (!font) {
        // Default 8x16 font
        return strlen(str) * 8;
    }
    
    int width = 0;
    while (*str) {
        const font_glyph_t *glyph = font_get_glyph(font, *str);
        if (glyph) {
            width += glyph->x_advance;
        } else {
            width += font->line_height / 2;  // Fallback width
        }
        str++;
    }
    return width;
}

void rgb_display_set_font(font_id_t id)
{
    if (id < FONT_COUNT) {
        current_font = id;
    }
}

font_id_t rgb_display_get_font(void)
{
    return current_font;
}

// Column-based rendering for bitmap fonts
// Supports fonts up to 24px tall (3 bytes per column)
static void draw_font_glyph_col(int x, int y, const font_t *font, const font_glyph_t *glyph, uint16_t color)
{
    if (!font || !glyph || !font->bitmap) return;
    
    const uint8_t *bitmap = &font->bitmap[glyph->bitmap_offset];
    int bytes_per_col = (glyph->height + 7) / 8;
    
    for (int col = 0; col < glyph->width; col++) {
        for (int byte_idx = 0; byte_idx < bytes_per_col; byte_idx++) {
            uint8_t column_data = bitmap[col * bytes_per_col + byte_idx];
            for (int bit = 0; bit < 8; bit++) {
                int row = byte_idx * 8 + bit;
                if (row >= glyph->height) break;
                if (column_data & (1 << bit)) {
                    int px = x + col;
                    int py = y + row;
                    rgb_display_draw_pixel(px, py, color);
                }
            }
        }
    }
}

void rgb_display_draw_text_font(int x, int y, const char *text, uint16_t color, font_id_t font_id)
{
    if (!text) return;
    
    const font_t *font = font_get(font_id);
    
    if (!font) {
        // Fall back to default rendering
        rgb_display_draw_text(x, y, text, color);
        return;
    }
    
    int cur_x = x;
    
    while (*text) {
        if (*text == '\n') {
            y += font->line_height;
            cur_x = x;
        } else if (*text == '\r') {
            cur_x = x;
        } else {
            const font_glyph_t *glyph = font_get_glyph(font, *text);
            if (glyph) {
                draw_font_glyph_col(cur_x, y, font, glyph, color);
                cur_x += glyph->x_advance;
            } else {
                // Unknown character - skip
                cur_x += font->line_height / 2;
            }
        }
        text++;
    }
}
