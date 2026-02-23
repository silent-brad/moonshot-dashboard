/*
 * Lua System Module - sleep, etc.
 */

#include "lua.h"
#include "lauxlib.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

// sys.sleep(ms) - sleep for given milliseconds, yields to FreeRTOS
static int lua_sys_sleep(lua_State *L)
{
    int ms = luaL_checkinteger(L, 1);
    TickType_t ticks = pdMS_TO_TICKS(ms);
    if (ticks == 0) ticks = 1;  // Minimum 1 tick to yield
    vTaskDelay(ticks);
    return 0;
}

static const luaL_Reg sys_lib[] = {
    {"sleep", lua_sys_sleep},
    {NULL, NULL}
};

int luaopen_sys(lua_State *L)
{
    luaL_newlib(L, sys_lib);
    return 1;
}
