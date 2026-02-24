/*
 * Lua Display Module - RGB Display bindings for Lua
 * 
 * Usage in Lua:
 *   display.init()
 *   display.clear(display.BLACK)
 *   display.line(0, 0, 100, 100, display.WHITE)
 *   display.rect(10, 10, 50, 30, display.RED, true)
 *   display.circle(200, 200, 50, display.GREEN, false)
 *   display.text(10, 400, "Hello World", display.YELLOW)
 */

#include <string.h>
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include "rgb_display.h"
#include "fonts.h"

// display.init()
static int l_display_init(lua_State *L)
{
    esp_err_t ret = rgb_display_init();
    if (ret != ESP_OK) {
        return luaL_error(L, "Display init failed: %d", ret);
    }
    lua_pushboolean(L, 1);
    return 1;
}

// display.clear(color)
static int l_display_clear(lua_State *L)
{
    uint16_t color = (uint16_t)luaL_optinteger(L, 1, RGB565_BLACK);
    rgb_display_clear(color);
    return 0;
}

// display.pixel(x, y, color)
static int l_display_pixel(lua_State *L)
{
    int x = luaL_checkinteger(L, 1);
    int y = luaL_checkinteger(L, 2);
    uint16_t color = (uint16_t)luaL_checkinteger(L, 3);
    rgb_display_draw_pixel(x, y, color);
    return 0;
}

// color = display.getpixel(x, y)
static int l_display_getpixel(lua_State *L)
{
    int x = luaL_checkinteger(L, 1);
    int y = luaL_checkinteger(L, 2);
    uint16_t color = rgb_display_read_pixel(x, y);
    lua_pushinteger(L, color);
    return 1;
}

// display.line(x0, y0, x1, y1, color)
static int l_display_line(lua_State *L)
{
    int x0 = luaL_checkinteger(L, 1);
    int y0 = luaL_checkinteger(L, 2);
    int x1 = luaL_checkinteger(L, 3);
    int y1 = luaL_checkinteger(L, 4);
    uint16_t color = (uint16_t)luaL_checkinteger(L, 5);
    rgb_display_draw_line(x0, y0, x1, y1, color);
    return 0;
}

// display.hline(x, y, w, color)
static int l_display_hline(lua_State *L)
{
    int x = luaL_checkinteger(L, 1);
    int y = luaL_checkinteger(L, 2);
    int w = luaL_checkinteger(L, 3);
    uint16_t color = (uint16_t)luaL_checkinteger(L, 4);
    rgb_display_draw_hline(x, y, w, color);
    return 0;
}

// display.vline(x, y, h, color)
static int l_display_vline(lua_State *L)
{
    int x = luaL_checkinteger(L, 1);
    int y = luaL_checkinteger(L, 2);
    int h = luaL_checkinteger(L, 3);
    uint16_t color = (uint16_t)luaL_checkinteger(L, 4);
    rgb_display_draw_vline(x, y, h, color);
    return 0;
}

// display.rect(x, y, w, h, color [, filled])
static int l_display_rect(lua_State *L)
{
    int x = luaL_checkinteger(L, 1);
    int y = luaL_checkinteger(L, 2);
    int w = luaL_checkinteger(L, 3);
    int h = luaL_checkinteger(L, 4);
    uint16_t color = (uint16_t)luaL_checkinteger(L, 5);
    bool filled = lua_toboolean(L, 6);
    rgb_display_draw_rect(x, y, w, h, color, filled);
    return 0;
}

// display.circle(cx, cy, r, color [, filled])
static int l_display_circle(lua_State *L)
{
    int cx = luaL_checkinteger(L, 1);
    int cy = luaL_checkinteger(L, 2);
    int r = luaL_checkinteger(L, 3);
    uint16_t color = (uint16_t)luaL_checkinteger(L, 4);
    bool filled = lua_toboolean(L, 5);
    rgb_display_draw_circle(cx, cy, r, color, filled);
    return 0;
}

// display.fill_circle(cx, cy, r, color)
// Convenience function - draws a filled circle
static int l_display_fill_circle(lua_State *L)
{
    int cx = luaL_checkinteger(L, 1);
    int cy = luaL_checkinteger(L, 2);
    int r = luaL_checkinteger(L, 3);
    uint16_t color = (uint16_t)luaL_checkinteger(L, 4);
    rgb_display_draw_circle(cx, cy, r, color, true);
    return 0;
}

// display.triangle(x0, y0, x1, y1, x2, y2, color [, filled])
static int l_display_triangle(lua_State *L)
{
    int x0 = luaL_checkinteger(L, 1);
    int y0 = luaL_checkinteger(L, 2);
    int x1 = luaL_checkinteger(L, 3);
    int y1 = luaL_checkinteger(L, 4);
    int x2 = luaL_checkinteger(L, 5);
    int y2 = luaL_checkinteger(L, 6);
    uint16_t color = (uint16_t)luaL_checkinteger(L, 7);
    bool filled = lua_toboolean(L, 8);
    rgb_display_draw_triangle(x0, y0, x1, y1, x2, y2, color, filled);
    return 0;
}

// display.text(x, y, text, color [, bgcolor])
static int l_display_text(lua_State *L)
{
    int x = luaL_checkinteger(L, 1);
    int y = luaL_checkinteger(L, 2);
    const char *text = luaL_checkstring(L, 3);
    uint16_t color = (uint16_t)luaL_checkinteger(L, 4);
    
    if (lua_gettop(L) >= 5) {
        uint16_t bgcolor = (uint16_t)luaL_checkinteger(L, 5);
        rgb_display_draw_text_bg(x, y, text, color, bgcolor);
    } else {
        rgb_display_draw_text(x, y, text, color);
    }
    return 0;
}

// display.image(x, y, w, h, data)
// data is a Lua string containing raw RGB565 pixel data
static int l_display_image(lua_State *L)
{
    int x = luaL_checkinteger(L, 1);
    int y = luaL_checkinteger(L, 2);
    int w = luaL_checkinteger(L, 3);
    int h = luaL_checkinteger(L, 4);
    
    size_t len;
    const char *data = luaL_checklstring(L, 5, &len);
    
    size_t expected_len = w * h * 2;  // 2 bytes per RGB565 pixel
    if (len < expected_len) {
        return luaL_error(L, "Image data too short: expected %d bytes, got %d", 
                          expected_len, len);
    }
    
    rgb_display_draw_image(x, y, w, h, (const uint16_t *)data);
    return 0;
}

// display.backlight(brightness)
// brightness: 0-100
static int l_display_backlight(lua_State *L)
{
    int brightness = luaL_checkinteger(L, 1);
    if (brightness < 0) brightness = 0;
    if (brightness > 100) brightness = 100;
    rgb_display_set_backlight(brightness);
    return 0;
}

// display.size()
// Returns width, height
static int l_display_size(lua_State *L)
{
    lua_pushinteger(L, RGB_DISPLAY_WIDTH);
    lua_pushinteger(L, RGB_DISPLAY_HEIGHT);
    return 2;
}

// display.rgb(r, g, b)
// Converts RGB888 to RGB565
static int l_display_rgb(lua_State *L)
{
    int r = luaL_checkinteger(L, 1);
    int g = luaL_checkinteger(L, 2);
    int b = luaL_checkinteger(L, 3);
    
    r = (r < 0) ? 0 : (r > 255) ? 255 : r;
    g = (g < 0) ? 0 : (g > 255) ? 255 : g;
    b = (b < 0) ? 0 : (b > 255) ? 255 : b;
    
    uint16_t color = RGB565(r, g, b);
    lua_pushinteger(L, color);
    return 1;
}

// display.setfont(font_id)
// Font IDs: 0=default, 1=inter12, 2=inter16, 3=garamond20, 4=garamond28
static int l_display_setfont(lua_State *L)
{
    int font_id = luaL_checkinteger(L, 1);
    if (font_id < 0 || font_id >= FONT_COUNT) {
        return luaL_error(L, "Invalid font ID: %d (valid: 0-%d)", font_id, FONT_COUNT - 1);
    }
    rgb_display_set_font((font_id_t)font_id);
    return 0;
}

// display.getfont()
// Returns current font ID
static int l_display_getfont(lua_State *L)
{
    lua_pushinteger(L, rgb_display_get_font());
    return 1;
}

// display.text_font(x, y, text, color, font_id)
// Draw text with specified font
static int l_display_text_font(lua_State *L)
{
    int x = luaL_checkinteger(L, 1);
    int y = luaL_checkinteger(L, 2);
    const char *text = luaL_checkstring(L, 3);
    uint16_t color = (uint16_t)luaL_checkinteger(L, 4);
    int font_id = luaL_optinteger(L, 5, FONT_DEFAULT);
    
    if (font_id < 0 || font_id >= FONT_COUNT) {
        font_id = FONT_DEFAULT;
    }
    
    rgb_display_draw_text_font(x, y, text, color, (font_id_t)font_id);
    return 0;
}

// Module function table
static const luaL_Reg display_lib[] = {
    {"init",      l_display_init},
    {"clear",     l_display_clear},
    {"pixel",     l_display_pixel},
    {"getpixel",  l_display_getpixel},
    {"line",      l_display_line},
    {"hline",     l_display_hline},
    {"vline",     l_display_vline},
    {"rect",      l_display_rect},
    {"circle",      l_display_circle},
    {"fill_circle", l_display_fill_circle},
    {"triangle",    l_display_triangle},
    {"text",      l_display_text},
    {"text_font", l_display_text_font},
    {"setfont",   l_display_setfont},
    {"getfont",   l_display_getfont},
    {"image",     l_display_image},
    {"backlight", l_display_backlight},
    {"size",      l_display_size},
    {"rgb",       l_display_rgb},
    {NULL, NULL}
};

int luaopen_display(lua_State *L)
{
    luaL_newlib(L, display_lib);
    
    // Add color constants
    lua_pushinteger(L, RGB565_BLACK);     lua_setfield(L, -2, "BLACK");
    lua_pushinteger(L, RGB565_WHITE);     lua_setfield(L, -2, "WHITE");
    lua_pushinteger(L, RGB565_RED);       lua_setfield(L, -2, "RED");
    lua_pushinteger(L, RGB565_GREEN);     lua_setfield(L, -2, "GREEN");
    lua_pushinteger(L, RGB565_BLUE);      lua_setfield(L, -2, "BLUE");
    lua_pushinteger(L, RGB565_YELLOW);    lua_setfield(L, -2, "YELLOW");
    lua_pushinteger(L, RGB565_CYAN);      lua_setfield(L, -2, "CYAN");
    lua_pushinteger(L, RGB565_MAGENTA);   lua_setfield(L, -2, "MAGENTA");
    lua_pushinteger(L, RGB565_ORANGE);    lua_setfield(L, -2, "ORANGE");
    lua_pushinteger(L, RGB565_PINK);      lua_setfield(L, -2, "PINK");
    lua_pushinteger(L, RGB565_PURPLE);    lua_setfield(L, -2, "PURPLE");
    lua_pushinteger(L, RGB565_GRAY);      lua_setfield(L, -2, "GRAY");
    lua_pushinteger(L, RGB565_DARKGRAY);  lua_setfield(L, -2, "DARKGRAY");
    lua_pushinteger(L, RGB565_LIGHTGRAY); lua_setfield(L, -2, "LIGHTGRAY");
    
    // Add display dimensions
    lua_pushinteger(L, RGB_DISPLAY_WIDTH);  lua_setfield(L, -2, "WIDTH");
    lua_pushinteger(L, RGB_DISPLAY_HEIGHT); lua_setfield(L, -2, "HEIGHT");
    
    // Add font constants
    lua_pushinteger(L, FONT_DEFAULT);     lua_setfield(L, -2, "FONT_DEFAULT");
    lua_pushinteger(L, FONT_INTER_20);    lua_setfield(L, -2, "FONT_INTER_20");
    lua_pushinteger(L, FONT_GARAMOND_20); lua_setfield(L, -2, "FONT_GARAMOND_20");
    
    return 1;
}
