return {
	name = "minimal",

	colors = {
		bg_primary = 0xFFFF, -- White
		bg_secondary = 0xF79E, -- Light gray
		bg_panel = 0xEF5D, -- Slightly darker gray

		accent_primary = 0x4A69, -- Slate blue
		accent_secondary = 0x8410, -- Medium gray
		accent_tertiary = 0x0410, -- Dark teal
		accent_warning = 0xFE00, -- Amber
		accent_error = 0xD000, -- Muted red
		accent_success = 0x0600, -- Muted green

		text_primary = 0x2104, -- Near black
		text_secondary = 0x4A49, -- Dark gray
		text_muted = 0x8410, -- Medium gray

		border = 0xD69A, -- Light border
		glow = 0xFFFF, -- No glow (white)
	},

	fonts = {
		heading = 2,  -- FONT_GARAMOND_20
		title = 2,    -- FONT_GARAMOND_20
		body = 1,     -- FONT_INTER_20
		small = 0,    -- FONT_DEFAULT
		mono = 0,     -- FONT_DEFAULT
	},

	spacing = {
		xs = 4,
		sm = 8,
		md = 16,
		lg = 24,
		xl = 32,
	},

	border_radius = 2,
	panel_padding = 12,
}
