idf_component_register(
    SRCS 
        "lua_core.c"
        "lua/lapi.c"
        "lua/lauxlib.c"
        "lua/lbaselib.c"
        "lua/lcode.c"
        "lua/lcorolib.c"
        "lua/lctype.c"
        "lua/ldblib.c"
        "lua/ldebug.c"
        "lua/ldo.c"
        "lua/ldump.c"
        "lua/lfunc.c"
        "lua/lgc.c"
        "lua/linit.c"
        "lua/liolib.c"
        "lua/llex.c"
        "lua/lmathlib.c"
        "lua/lmem.c"
        "lua/loadlib.c"
        "lua/lobject.c"
        "lua/lopcodes.c"
        "lua/loslib.c"
        "lua/lparser.c"
        "lua/lstate.c"
        "lua/lstring.c"
        "lua/lstrlib.c"
        "lua/ltable.c"
        "lua/ltablib.c"
        "lua/ltm.c"
        "lua/lundump.c"
        "lua/lutf8lib.c"
        "lua/lvm.c"
        "lua/lzio.c"
    INCLUDE_DIRS "include" "lua"
    REQUIRES driver
)

# Lua defines
target_compile_definitions(${COMPONENT_LIB} PUBLIC
    LUA_USE_C89
)
