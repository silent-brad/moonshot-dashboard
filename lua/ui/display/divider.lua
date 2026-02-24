local Divider = {}
Divider.__index = Divider

function Divider.new(props)
    local self = setmetatable({}, Divider)
    self.orientation = props.orientation or "horizontal"  -- horizontal | vertical
    self.color = props.color       -- nil = use theme border
    self.thickness = props.thickness or 1
    self.margin = props.margin or 8
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    return self
end

function Divider:measure(max_width, max_height)
    if self.orientation == "horizontal" then
        return max_width, self.thickness + self.margin * 2
    else
        return self.thickness + self.margin * 2, max_height
    end
end

function Divider:layout(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
end

function Divider:draw(theme)
    local color = self.color or theme.colors.border

    if self.orientation == "horizontal" then
        local line_y = self.y + self.margin + math.floor(self.thickness / 2)
        display.line(
            math.floor(self.x),
            math.floor(line_y),
            math.floor(self.x + self.width),
            math.floor(line_y),
            color
        )
    else
        local line_x = self.x + self.margin + math.floor(self.thickness / 2)
        display.line(
            math.floor(line_x),
            math.floor(self.y),
            math.floor(line_x),
            math.floor(self.y + self.height),
            color
        )
    end
end

return Divider
