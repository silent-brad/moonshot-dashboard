idf_component_register(
    SRCS "main.c"
    INCLUDE_DIRS "."
    REQUIRES rgb_display lua_core lua_modules
    PRIV_REQUIRES nvs_flash esp_psram
    EMBED_TXTFILES 
        "dashboard/main.lua"
        "dashboard/init.lua"
        "dashboard/weather.lua"
        "dashboard/btc.lua"
        "dashboard/verse.lua"
        "../config/config.lua"
        "getenv.lua"
        "../config/.env"
)
