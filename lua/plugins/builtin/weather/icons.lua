local icons = {}

local icon_chars = {
    clear = "☀",
    cloudy = "☁",
    rain = "🌧",
    storm = "⛈",
    snow = "❄",
    fog = "🌫",
}

function icons.draw(x, y, condition, theme, size)
    local icon = icon_chars[condition] or icon_chars.clear
    local font = size == "small" and theme.fonts.body or theme.fonts.heading
    local color = theme.colors.accent_tertiary

    if condition == "rain" or condition == "storm" then
        color = theme.colors.accent_primary
    elseif condition == "snow" then
        color = theme.colors.text_secondary
    end

    display.text_font(x, y, icon, color, font)
end

function icons.get_char(condition)
    return icon_chars[condition] or icon_chars.clear
end

return icons
