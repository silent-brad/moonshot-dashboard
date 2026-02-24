local Header = {}
Header.__index = Header

function Header.new(props)
    local self = setmetatable({}, Header)
    self.title = props.title or ""
    self.subtitle = props.subtitle
    self.show_clock = props.show_clock ~= false
    self.show_wifi = props.show_wifi or false
    self.height = props.height or 40
    self.x = 0
    self.y = 0
    self.width = 0
    self._height = 0
    return self
end

function Header:measure(max_width, max_height)
    return max_width, self.height
end

function Header:layout(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self._height = self.height
end

function Header:get_time_string()
    local time = os.date("*t")
    local hour = time.hour
    local ampm = "AM"

    if hour >= 12 then
        ampm = "PM"
        if hour > 12 then
            hour = hour - 12
        end
    elseif hour == 0 then
        hour = 12
    end

    return string.format("%d:%02d %s", hour, time.min, ampm)
end

function Header:draw(theme)
    local x, y, w = self.x, self.y, self.width

    -- Background
    display.rect(x, y, w, self.height, theme.colors.bg_secondary, true)

    -- Title
    display.text_font(
        math.floor(x + 10),
        math.floor(y + (self.height - 24) / 2),
        self.title,
        theme.colors.text_primary,
        theme.fonts.title
    )

    -- Subtitle
    if self.subtitle then
        local title_width = #self.title * 10
        display.text_font(
            math.floor(x + 20 + title_width),
            math.floor(y + (self.height - 16) / 2),
            self.subtitle,
            theme.colors.text_secondary,
            theme.fonts.small
        )
    end

    -- Clock (right side)
    if self.show_clock then
        local time_str = self:get_time_string()
        local time_width = #time_str * 8
        display.text_font(
            math.floor(x + w - time_width - 10),
            math.floor(y + (self.height - 20) / 2),
            time_str,
            theme.colors.text_secondary,
            theme.fonts.body
        )
    end

    -- WiFi indicator
    if self.show_wifi then
        local wifi_x = x + w - 80
        if self.show_clock then
            wifi_x = wifi_x - 80
        end
        -- Simple WiFi icon placeholder
        display.rect(
            math.floor(wifi_x),
            math.floor(y + (self.height - 16) / 2),
            16, 16,
            theme.colors.accent_success,
            false
        )
    end

    -- Bottom border
    display.line(x, y + self.height - 1, x + w, y + self.height - 1, theme.colors.border)
end

return Header
