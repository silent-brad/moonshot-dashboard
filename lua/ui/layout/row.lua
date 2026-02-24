local Row = {}
Row.__index = Row

function Row.new(props)
    local self = setmetatable({}, Row)
    self.children = props.children or {}
    self.gap = props.gap or 8
    self.align = props.align or "start"     -- start | center | end | stretch
    self.justify = props.justify or "start" -- start | center | end | between | around
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    return self
end

function Row:measure(max_width, max_height)
    local total_width = 0
    local max_child_height = 0

    for i, child in ipairs(self.children) do
        local cw, ch = child:measure(max_width, max_height)
        total_width = total_width + cw
        if ch > max_child_height then
            max_child_height = ch
        end
    end

    total_width = total_width + self.gap * (#self.children - 1)
    return total_width, max_child_height
end

function Row:layout(x, y, w, h)
    self.x = x
    self.y = y
    self.width = w
    self.height = h

    local total_gap = self.gap * (#self.children - 1)
    local available_width = w - total_gap
    local child_widths = {}
    local total_measured_width = 0

    -- First pass: measure children
    for i, child in ipairs(self.children) do
        local cw, ch = child:measure(available_width, h)
        child_widths[i] = cw
        total_measured_width = total_measured_width + cw
    end

    -- Calculate starting x based on justify
    local cx = x
    local spacing = self.gap

    if self.justify == "center" then
        cx = x + (w - total_measured_width - total_gap) / 2
    elseif self.justify == "end" then
        cx = x + w - total_measured_width - total_gap
    elseif self.justify == "between" and #self.children > 1 then
        spacing = (w - total_measured_width) / (#self.children - 1)
    elseif self.justify == "around" and #self.children > 0 then
        spacing = (w - total_measured_width) / (#self.children + 1)
        cx = x + spacing
    end

    -- Second pass: position children
    for i, child in ipairs(self.children) do
        local _, ch = child:measure(child_widths[i], h)
        local cy = y
        local child_h = h

        if self.align == "center" then
            cy = y + (h - ch) / 2
            child_h = ch
        elseif self.align == "end" then
            cy = y + h - ch
            child_h = ch
        elseif self.align == "start" then
            child_h = ch
        end

        child:layout(cx, cy, child_widths[i], child_h)
        cx = cx + child_widths[i] + spacing
    end
end

function Row:draw(theme)
    for _, child in ipairs(self.children) do
        child:draw(theme)
    end
end

return Row
