idf_component_register(
    SRCS "rgb_display.c" "rgb_draw.c" "fonts.c" "font_inter.c" "font_garamond.c"
    INCLUDE_DIRS "include"
    REQUIRES driver esp_lcd
)
