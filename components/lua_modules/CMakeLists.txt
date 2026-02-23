idf_component_register(
    SRCS 
        "lua_modules_init.c"
        "lua_display.c"
        "lua_i2c.c"
        "lua_sys.c"
    INCLUDE_DIRS "include"
    REQUIRES lua_core rgb_display driver
)
