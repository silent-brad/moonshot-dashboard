idf_component_register(
    SRCS "rgb_display.c" "rgb_draw.c"
    INCLUDE_DIRS "include"
    REQUIRES driver esp_lcd
)
