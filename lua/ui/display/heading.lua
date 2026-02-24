local Heading = {}
Heading.__index = Heading

local HEADING_SIZES = {
    h1 = { char_width = 14, line_height = 32 },
    h2 = { char_width = 12, line_height = 28 },
    h3 = { char_width = 10, line_height = 24 },
    h4 = { char_width = 9, line_height = 22 },
    h5 = { char_width = 8, line_height = 20 },
    h6 = { char_width = 7, line_height = 18 },
}

function Heading.new(props)
    local self = setmetatable({}, Heading)
    self.content = props.content or props[1] or ""
    self.level = props.level or 1  -- 1-6
    self.color = props.color       -- nil = use theme text_primary
    self.align = props.align or "left"
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    return self
end

function Heading:get_size_key()
    return "h" .. math.max(1, math.min(6, self.level))
end

function Heading:measure(max_width, max_height)
    local size = HEADING_SIZES[self:get_size_key()]
    local text_width = #self.content * size.char_width
    return math.min(text_width, max_width), size.line_height
end

function Heading:layout(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
end

function Heading:draw(theme)
    local color = self.color or theme.colors.text_primary
    local size = HEADING_SIZES[self:get_size_key()]

    -- Select font based on level
    local font
    if self.level <= 2 then
        font = theme.fonts.heading
    elseif self.level <= 4 then
        font = theme.fonts.title
    else
        font = theme.fonts.body
    end

    local text_x = self.x
    if self.align == "center" then
        local text_width = #self.content * size.char_width
        text_x = self.x + (self.width - text_width) / 2
    elseif self.align == "right" then
        local text_width = #self.content * size.char_width
        text_x = self.x + self.width - text_width
    end

    display.text_font(
        math.floor(text_x),
        math.floor(self.y),
        self.content,
        color,
        font
    )
end

return Heading
