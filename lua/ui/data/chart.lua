local Chart = {}
Chart.__index = Chart

function Chart.new(props)
    local self = setmetatable({}, Chart)
    self.data = props.data or {}         -- array of numbers
    self.type = props.type or "line"     -- line | bar | area
    self.color = props.color
    self.fill = props.fill or false
    self.show_grid = props.show_grid or true
    self.show_labels = props.show_labels or false
    self.min = props.min                 -- nil = auto
    self.max = props.max                 -- nil = auto
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    return self
end

function Chart:measure(max_width, max_height)
    return max_width, max_height
end

function Chart:layout(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
end

function Chart:draw(theme)
    local data = self.data
    if #data < 2 then return end

    local color = self.color or theme.colors.accent_primary
    local x, y, w, h = self.x, self.y, self.width, self.height

    -- Calculate data range
    local min_val = self.min or math.huge
    local max_val = self.max or -math.huge
    for _, v in ipairs(data) do
        if v < min_val then min_val = v end
        if v > max_val then max_val = v end
    end
    local range = max_val - min_val
    if range == 0 then range = 1 end

    -- Draw grid
    if self.show_grid then
        for i = 0, 4 do
            local gy = y + (h * i / 4)
            display.line(x, math.floor(gy), x + w, math.floor(gy), theme.colors.border)
        end
    end

    -- Draw data
    local step = w / (#data - 1)
    local prev_px, prev_py

    for i, v in ipairs(data) do
        local px = x + (i - 1) * step
        local py = y + h - ((v - min_val) / range * h)

        if self.type == "line" and prev_px then
            display.line(
                math.floor(prev_px), math.floor(prev_py),
                math.floor(px), math.floor(py),
                color
            )
        elseif self.type == "bar" then
            local bar_w = math.floor(step * 0.8)
            local bar_h = math.floor((v - min_val) / range * h)
            display.rect(
                math.floor(px - bar_w/2),
                math.floor(y + h - bar_h),
                bar_w, bar_h,
                color, true
            )
        elseif self.type == "area" and prev_px then
            display.line(
                math.floor(prev_px), math.floor(prev_py),
                math.floor(px), math.floor(py),
                color
            )
            -- Fill area below line
            for fx = math.floor(prev_px), math.floor(px) do
                local t = (fx - prev_px) / (px - prev_px)
                local fy = prev_py + t * (py - prev_py)
                display.line(fx, math.floor(fy), fx, math.floor(y + h), theme.colors.bg_secondary)
            end
        end

        prev_px, prev_py = px, py
    end

    -- Draw labels
    if self.show_labels then
        local min_label = string.format("%.0f", min_val)
        local max_label = string.format("%.0f", max_val)
        display.text_font(x, y + h + 2, min_label, theme.colors.text_muted, theme.fonts.small)
        display.text_font(x, y - 12, max_label, theme.colors.text_muted, theme.fonts.small)
    end
end

return Chart
