return {
    name = "retro",

    colors = {
        bg_primary     = 0x0000,   -- Black
        bg_secondary   = 0x0200,   -- Very dark green
        bg_panel       = 0x0320,   -- Dark green

        accent_primary   = 0x07E0, -- Phosphor green
        accent_secondary = 0xFE00, -- Amber
        accent_tertiary  = 0x07E0, -- Green
        accent_warning   = 0xFE00, -- Amber
        accent_error     = 0xF800, -- Red
        accent_success   = 0x07E0, -- Green

        text_primary   = 0x07E0,   -- Phosphor green
        text_secondary = 0x05E0,   -- Dimmer green
        text_muted     = 0x0380,   -- Dark green

        border         = 0x0460,   -- Green border
        glow           = 0x0200,   -- Subtle green glow
    },

    fonts = {
        heading = 0,  -- FONT_DEFAULT (monospace look)
        title   = 0,  -- FONT_DEFAULT
        body    = 0,  -- FONT_DEFAULT
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

    border_radius = 0,
    panel_padding = 8,
}
