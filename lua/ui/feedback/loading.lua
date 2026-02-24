local Loading = {}
Loading.__index = Loading

function Loading.new(props)
    local self = setmetatable({}, Loading)
    self.type = props.type or "spinner"      -- spinner | skeleton | dots
    self.size = props.size or 32
    self.color = props.color                 -- nil = accent_primary
    self.message = props.message             -- optional loading text
    self.frame = 0                           -- animation frame
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    return self
end

function Loading:measure(max_width, max_height)
    local h = self.size
    if self.message then
        h = h + 24
    end
    return self.size, h
end

function Loading:layout(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
end

function Loading:advance()
    self.frame = self.frame + 1
end

function Loading:draw(theme)
    local color = self.color or theme.colors.accent_primary
    local center_x = self.x + self.width / 2
    local center_y = self.y + self.size / 2

    if self.type == "spinner" then
        local segments = 8
        local radius = self.size / 2 - 2
        local active_segment = self.frame % segments

        for i = 0, segments - 1 do
            local angle = (i * 2 * math.pi / segments) - math.pi / 2
            local x1 = center_x + math.cos(angle) * (radius * 0.5)
            local y1 = center_y + math.sin(angle) * (radius * 0.5)
            local x2 = center_x + math.cos(angle) * radius
            local y2 = center_y + math.sin(angle) * radius

            local seg_color = i == active_segment and color or theme.colors.text_muted
            display.line(
                math.floor(x1), math.floor(y1),
                math.floor(x2), math.floor(y2),
                seg_color
            )
        end

    elseif self.type == "dots" then
        local dot_count = 3
        local dot_radius = self.size / 8
        local spacing = self.size / 3
        local active_dot = self.frame % dot_count

        for i = 0, dot_count - 1 do
            local dot_x = center_x - spacing + i * spacing
            local r = i == active_dot and dot_radius * 1.5 or dot_radius
            local dot_color = i == active_dot and color or theme.colors.text_muted

            display.fill_circle(
                math.floor(dot_x),
                math.floor(center_y),
                math.floor(r),
                dot_color
            )
        end

    elseif self.type == "skeleton" then
        display.rect(
            math.floor(self.x),
            math.floor(self.y),
            math.floor(self.width),
            math.floor(self.size),
            theme.colors.bg_secondary,
            true
        )
    end

    if self.message then
        local text_y = self.y + self.size + 8
        local text_width = #self.message * 8
        local text_x = center_x - text_width / 2

        display.text_font(
            math.floor(text_x),
            math.floor(text_y),
            self.message,
            theme.colors.text_secondary,
            theme.fonts.small
        )
    end
end

return Loading
