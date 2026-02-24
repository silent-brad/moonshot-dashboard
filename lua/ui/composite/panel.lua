local Panel = {}
Panel.__index = Panel

function Panel.new(props)
    local self = setmetatable({}, Panel)
    self.title = props.title or ""
    self.children = props.children or {}
    self.style = props.style or "default"  -- default | minimal | glow
    self.padding = props.padding
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    return self
end

function Panel:measure(max_width, max_height)
    return max_width, max_height
end

function Panel:layout(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
end

function Panel:draw(theme)
    local x, y, w, h = self.x, self.y, self.width, self.height
    local padding = self.padding or theme.panel_padding

    -- Background
    display.rect(x, y, w, h, theme.colors.bg_panel, true)

    -- Border based on style
    if self.style == "glow" then
        -- Outer glow effect
        display.rect(x-1, y-1, w+2, h+2, theme.colors.glow, false)
        display.rect(x, y, w, h, theme.colors.accent_primary, false)
        display.line(x, y, x + w, y, theme.colors.accent_primary)
        display.line(x, y, x, y + h, theme.colors.accent_primary)
    elseif self.style == "minimal" then
        display.line(x, y, x + w, y, theme.colors.border)
    else
        display.rect(x, y, w, h, theme.colors.border, false)
    end

    -- Title
    if self.title ~= "" then
        local title_bg_w = #self.title * 10 + 10
        display.rect(x + 5, y - 2, title_bg_w, 20, theme.colors.bg_panel, true)
        display.text_font(
            x + 10, y + 2,
            self.title,
            theme.colors.accent_secondary,
            theme.fonts.title
        )
    end

    -- Layout and draw children
    local content_x = x + padding
    local content_y = y + (self.title ~= "" and 20 or 0) + padding
    local content_w = w - padding * 2
    local content_h = h - (self.title ~= "" and 20 or 0) - padding * 2

    for _, child in ipairs(self.children) do
        child:layout(content_x, content_y, content_w, content_h)
        child:draw(theme)
    end
end

return Panel
