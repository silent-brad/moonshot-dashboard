idf_component_register(
    SRCS 
        "lua_modules_init.c"
        "lua_display.c"
        "lua_i2c.c"
        "lua_sys.c"
        "lua_wifi.c"
        "lua_http.c"
        "lua_touch.c"
    INCLUDE_DIRS "include"
    REQUIRES lua_core rgb_display driver esp_wifi esp_netif esp_http_client esp_event
    PRIV_REQUIRES nvs_flash esp-tls
)
