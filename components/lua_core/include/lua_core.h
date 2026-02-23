/*
 * Lua Core - Minimal Lua VM wrapper for ESP32-S3
 */

#ifndef LUA_CORE_H
#define LUA_CORE_H

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Initialize Lua VM
 * 
 * @return 0 on success, -1 on failure
 */
int lua_core_init(void);

/**
 * Get the Lua state
 * 
 * @return Pointer to the Lua state, or NULL if not initialized
 */
lua_State* lua_core_get_state(void);

/**
 * Run the Lua REPL (Read-Eval-Print Loop)
 * This function runs in a loop and processes Lua commands from UART
 */
void lua_core_run_repl(void);

/**
 * Execute a Lua string
 * 
 * @param code Lua code to execute
 * @return 0 on success, error code on failure
 */
int lua_core_dostring(const char *code);

/**
 * Execute a Lua file
 * 
 * @param filename Path to Lua file
 * @return 0 on success, error code on failure
 */
int lua_core_dofile(const char *filename);

/**
 * Register a custom C function in Lua
 * 
 * @param name Function name in Lua
 * @param func C function pointer
 */
void lua_core_register_function(const char *name, lua_CFunction func);

/**
 * Register a Lua module
 * 
 * @param name Module name
 * @param funcs Array of luaL_Reg defining the module functions
 */
void lua_core_register_module(const char *name, const luaL_Reg *funcs);

#ifdef __cplusplus
}
#endif

#endif // LUA_CORE_H
