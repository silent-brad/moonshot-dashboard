local Icon = {}
Icon.__index = Icon

function Icon.new(props)
    local self = setmetatable({}, Icon)
    self.name = props.name or props[1] or ""
    self.bitmap = props.bitmap       -- raw bitmap data
    self.size = props.size or 24     -- icon size in pixels
    self.color = props.color         -- nil = use theme text_primary
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    return self
end

function Icon:measure(max_width, max_height)
    return self.size, self.size
end

function Icon:layout(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
end

function Icon:draw(theme)
    local color = self.color or theme.colors.text_primary

    if self.bitmap then
        -- Draw bitmap icon if provided
        display.bitmap(
            math.floor(self.x),
            math.floor(self.y),
            self.bitmap,
            self.size,
            self.size,
            color
        )
    else
        -- Placeholder: draw a simple square
        display.rect(
            math.floor(self.x),
            math.floor(self.y),
            self.size,
            self.size,
            color,
            false
        )
    end
end

return Icon
