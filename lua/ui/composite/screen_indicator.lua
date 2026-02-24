local ScreenIndicator = {}
ScreenIndicator.__index = ScreenIndicator

function ScreenIndicator.new(props)
    local self = setmetatable({}, ScreenIndicator)
    self.total = props.total or 1
    self.current = props.current or 1
    self.dot_size = props.dot_size or 8
    self.dot_gap = props.dot_gap or 12
    self.position = props.position or "bottom"  -- bottom | top
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    return self
end

function ScreenIndicator:measure(max_width, max_height)
    local width = (self.dot_size * self.total) + (self.dot_gap * (self.total - 1))
    return width, self.dot_size + 8
end

function ScreenIndicator:layout(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
end

function ScreenIndicator:draw(theme)
    local total_width = (self.dot_size * self.total) + (self.dot_gap * (self.total - 1))
    local start_x = self.x + (self.width - total_width) / 2

    for i = 1, self.total do
        local dot_x = start_x + (i - 1) * (self.dot_size + self.dot_gap)
        local color = i == self.current
            and theme.colors.accent_primary
            or theme.colors.text_muted

        display.fill_circle(
            math.floor(dot_x + self.dot_size / 2),
            math.floor(self.y + self.dot_size / 2),
            math.floor(self.dot_size / 2),
            color
        )
    end
end

return ScreenIndicator
