local Progress = {}
Progress.__index = Progress

function Progress.new(props)
    local self = setmetatable({}, Progress)
    self.value = props.value or 0        -- 0-100
    self.max = props.max or 100
    self.color = props.color             -- nil = accent_primary
    self.bg_color = props.bg_color       -- nil = bg_secondary
    self.height = props.height or 8
    self.show_label = props.show_label or false
    self.label_format = props.label_format or "%d%%"
    self.rounded = props.rounded ~= false
    self.x = 0
    self.y = 0
    self.width = 0
    self._height = 0
    return self
end

function Progress:measure(max_width, max_height)
    local height = self.height
    if self.show_label then
        height = height + 20
    end
    return max_width, height
end

function Progress:layout(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self._height = height
end

function Progress:draw(theme)
    local bg_color = self.bg_color or theme.colors.bg_secondary
    local fg_color = self.color or theme.colors.accent_primary

    local bar_y = self.y
    if self.show_label then
        local label = string.format(self.label_format, math.floor(self.value / self.max * 100))
        display.text_font(
            math.floor(self.x),
            math.floor(self.y),
            label,
            theme.colors.text_secondary,
            theme.fonts.small
        )
        bar_y = self.y + 16
    end

    -- Background bar
    display.rect(
        math.floor(self.x),
        math.floor(bar_y),
        math.floor(self.width),
        self.height,
        bg_color,
        true
    )

    -- Progress bar
    local progress_width = math.floor(self.width * (self.value / self.max))
    if progress_width > 0 then
        display.rect(
            math.floor(self.x),
            math.floor(bar_y),
            progress_width,
            self.height,
            fg_color,
            true
        )
    end
end

return Progress
