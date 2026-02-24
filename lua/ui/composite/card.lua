local Card = {}
Card.__index = Card

function Card.new(props)
    local self = setmetatable({}, Card)
    self.children = props.children or {}
    self.padding = props.padding or 12
    self.bg_color = props.bg_color       -- nil = bg_panel
    self.border_color = props.border_color
    self.shadow = props.shadow or false
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    return self
end

function Card:measure(max_width, max_height)
    return max_width, max_height
end

function Card:layout(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
end

function Card:draw(theme)
    local x, y, w, h = self.x, self.y, self.width, self.height
    local bg = self.bg_color or theme.colors.bg_panel

    -- Shadow effect
    if self.shadow then
        display.rect(x + 2, y + 2, w, h, theme.colors.bg_secondary, true)
    end

    -- Background
    display.rect(x, y, w, h, bg, true)

    -- Border
    if self.border_color then
        display.rect(x, y, w, h, self.border_color, false)
    end

    -- Layout and draw children
    local content_x = x + self.padding
    local content_y = y + self.padding
    local content_w = w - self.padding * 2
    local content_h = h - self.padding * 2

    for _, child in ipairs(self.children) do
        child:layout(content_x, content_y, content_w, content_h)
        child:draw(theme)
    end
end

return Card
