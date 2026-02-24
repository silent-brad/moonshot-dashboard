local Stat = {}
Stat.__index = Stat

function Stat.new(props)
    local self = setmetatable({}, Stat)
    self.label = props.label or ""
    self.value = props.value or ""
    self.unit = props.unit or ""
    self.icon = props.icon               -- optional icon
    self.trend = props.trend             -- nil | "up" | "down"
    self.trend_value = props.trend_value
    self.size = props.size or "medium"   -- small | medium | large
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    return self
end

function Stat:measure(max_width, max_height)
    local sizes = {
        small = 48,
        medium = 64,
        large = 80,
    }
    return max_width, sizes[self.size] or 64
end

function Stat:layout(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
end

function Stat:draw(theme)
    local x, y, w = self.x, self.y, self.width
    local value_fonts = {
        small = theme.fonts.body,
        medium = theme.fonts.title,
        large = theme.fonts.heading,
    }
    local label_fonts = {
        small = theme.fonts.small,
        medium = theme.fonts.small,
        large = theme.fonts.body,
    }

    local icon_offset = 0
    if self.icon then
        -- Draw icon placeholder
        display.rect(x, y, 24, 24, theme.colors.text_muted, false)
        icon_offset = 32
    end

    -- Label
    display.text_font(
        math.floor(x + icon_offset),
        math.floor(y),
        self.label,
        theme.colors.text_secondary,
        label_fonts[self.size]
    )

    -- Value with unit
    local value_str = tostring(self.value) .. self.unit
    local value_y = y + (self.size == "small" and 16 or 24)

    display.text_font(
        math.floor(x + icon_offset),
        math.floor(value_y),
        value_str,
        theme.colors.text_primary,
        value_fonts[self.size]
    )

    -- Trend indicator
    if self.trend then
        local trend_color = self.trend == "up"
            and theme.colors.accent_success
            or theme.colors.accent_error
        local arrow = self.trend == "up" and "↑" or "↓"
        local trend_str = arrow .. " " .. tostring(self.trend_value or "")

        display.text_font(
            math.floor(x + w - 50),
            math.floor(value_y),
            trend_str,
            trend_color,
            theme.fonts.small
        )
    end
end

return Stat
