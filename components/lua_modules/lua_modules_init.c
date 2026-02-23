/*
 * Lua Modules Initialization
 */

#include "lua_modules.h"
#include "lauxlib.h"
#include "lualib.h"

void lua_modules_init(lua_State *L)
{
    if (!L) return;
    
    // Register display module
    luaL_requiref(L, "display", luaopen_display, 1);
    lua_pop(L, 1);
    
    // Register I2C module
    luaL_requiref(L, "i2c", luaopen_i2c_module, 1);
    lua_pop(L, 1);
}
