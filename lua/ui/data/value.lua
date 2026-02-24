local Value = {}
Value.__index = Value

function Value.new(props)
    local self = setmetatable({}, Value)
    self.value = props.value or 0
    self.prefix = props.prefix or ""     -- "$", "£", etc.
    self.suffix = props.suffix or ""     -- "%", "°F", etc.
    self.decimals = props.decimals or 0
    self.size = props.size or "large"    -- small | medium | large | xlarge
    self.trend = props.trend             -- nil | "up" | "down"
    self.trend_value = props.trend_value
    self.color = props.color
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    return self
end

function Value:format()
    local num = self.value
    if type(num) == "number" then
        if self.decimals > 0 then
            num = string.format("%." .. self.decimals .. "f", num)
        else
            num = tostring(math.floor(num))
        end
        -- Add thousands separators
        num = num:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    end
    return self.prefix .. tostring(num) .. self.suffix
end

function Value:measure(max_width, max_height)
    local sizes = {
        small = { char_width = 8, height = 20 },
        medium = { char_width = 10, height = 28 },
        large = { char_width = 14, height = 36 },
        xlarge = { char_width = 18, height = 48 },
    }
    local size = sizes[self.size] or sizes.large
    local text_width = #self:format() * size.char_width

    if self.trend then
        text_width = text_width + 60
    end

    return math.min(text_width, max_width), size.height
end

function Value:layout(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
end

function Value:draw(theme)
    local fonts = {
        small = theme.fonts.body,
        medium = theme.fonts.title,
        large = theme.fonts.heading,
        xlarge = theme.fonts.heading,
    }

    local color = self.color or theme.colors.text_primary
    display.text_font(self.x, self.y, self:format(), color, fonts[self.size])

    -- Draw trend indicator
    if self.trend then
        local trend_color = self.trend == "up"
            and theme.colors.accent_success
            or theme.colors.accent_error
        local arrow = self.trend == "up" and "↑" or "↓"
        local trend_str = arrow .. " " .. tostring(self.trend_value or "")
        display.text_font(
            self.x + self.width - 50,
            self.y,
            trend_str,
            trend_color,
            theme.fonts.small
        )
    end
end

return Value
