local Text = {}
Text.__index = Text

function Text.new(props)
    local self = setmetatable({}, Text)
    self.content = props.content or props[1] or ""
    self.color = props.color           -- nil = use theme text_primary
    self.font = props.font             -- nil = use theme body font
    self.align = props.align or "left" -- left | center | right
    self.wrap = props.wrap or false
    self.max_lines = props.max_lines
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    return self
end

function Text:measure(max_width, max_height)
    -- Approximate: 8px per character for default font
    local char_width = 8
    local line_height = 20
    local text_width = #self.content * char_width

    if self.wrap and text_width > max_width then
        local lines = math.ceil(text_width / max_width)
        if self.max_lines then
            lines = math.min(lines, self.max_lines)
        end
        return max_width, lines * line_height
    end

    return math.min(text_width, max_width), line_height
end

function Text:layout(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
end

function Text:draw(theme)
    local color = self.color or theme.colors.text_primary
    local font = self.font or theme.fonts.body

    local text_x = self.x
    if self.align == "center" then
        local text_width = #self.content * 8
        text_x = self.x + (self.width - text_width) / 2
    elseif self.align == "right" then
        local text_width = #self.content * 8
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

return Text
