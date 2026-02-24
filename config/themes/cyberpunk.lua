return {
    name = "cyberpunk",

    colors = {
        bg_primary     = 0x0000,   -- Black
        bg_secondary   = 0x0841,   -- Dark blue-gray
        bg_panel       = 0x1082,   -- Slightly lighter

        accent_primary   = 0x07FF, -- Cyan
        accent_secondary = 0xF81F, -- Magenta
        accent_tertiary  = 0xFFE0, -- Yellow
        accent_warning   = 0xFD20, -- Orange
        accent_error     = 0xF800, -- Red
        accent_success   = 0x07E0, -- Green

        text_primary   = 0xFFFF,   -- White
        text_secondary = 0xC618,   -- Light gray
        text_muted     = 0x8410,   -- Dark gray

        border         = 0x4A69,   -- Cyan-tinted gray
        glow           = 0x001F,   -- Deep blue
    },

    fonts = {
        heading = 2,  -- FONT_GARAMOND_20 (only available large font)
        title   = 2,  -- FONT_GARAMOND_20
        body    = 1,  -- FONT_INTER_20
        small   = 0,  -- FONT_DEFAULT
        mono    = 0,  -- FONT_DEFAULT
    },

    spacing = {
        xs = 4,
        sm = 8,
        md = 16,
        lg = 24,
        xl = 32,
    },

    border_radius = 4,
    panel_padding = 10,
}
