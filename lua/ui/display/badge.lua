local Badge = {}
Badge.__index = Badge

function Badge.new(props)
    local self = setmetatable({}, Badge)
    self.content = props.content or props[1] or ""
    self.color = props.color             -- nil = use accent_primary
    self.bg_color = props.bg_color       -- nil = derived from color
    self.text_color = props.text_color   -- nil = use bg_primary or white
    self.variant = props.variant or "filled"  -- filled | outline
    self.size = props.size or "small"    -- small | medium
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    return self
end

function Badge:measure(max_width, max_height)
    local char_width = self.size == "small" and 6 or 8
    local padding = self.size == "small" and 8 or 12
    local height = self.size == "small" and 18 or 24

    local text_width = #self.content * char_width + padding * 2
    return math.min(text_width, max_width), height
end

function Badge:layout(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
end

function Badge:draw(theme)
    local accent = self.color or theme.colors.accent_primary
    local bg = self.bg_color or accent
    local text_color = self.text_color or theme.colors.bg_primary

    local char_width = self.size == "small" and 6 or 8
    local padding = self.size == "small" and 4 or 6
    local badge_height = self.size == "small" and 18 or 24
    local badge_width = #self.content * char_width + padding * 2

    local font = self.size == "small" and theme.fonts.small or theme.fonts.body

    if self.variant == "filled" then
        display.rect(
            math.floor(self.x),
            math.floor(self.y),
            math.floor(badge_width),
            badge_height,
            bg,
            true
        )
    else
        display.rect(
            math.floor(self.x),
            math.floor(self.y),
            math.floor(badge_width),
            badge_height,
            accent,
            false
        )
        text_color = accent
    end

    display.text_font(
        math.floor(self.x + padding),
        math.floor(self.y + (badge_height - char_width) / 2),
        self.content,
        text_color,
        font
    )
end

return Badge
