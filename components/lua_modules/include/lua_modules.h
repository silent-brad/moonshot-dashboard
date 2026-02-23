/*
 * Lua Modules for CrowPanel ESP32-S3
 */

#ifndef LUA_MODULES_H
#define LUA_MODULES_H

#include "lua.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Initialize all Lua modules
 * 
 * @param L Lua state
 */
void lua_modules_init(lua_State *L);

// Individual module open functions
int luaopen_display(lua_State *L);
int luaopen_i2c_module(lua_State *L);
int luaopen_sys(lua_State *L);

#ifdef __cplusplus
}
#endif

#endif // LUA_MODULES_H
