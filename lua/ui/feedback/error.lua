local Error = {}
Error.__index = Error

function Error.new(props)
    local self = setmetatable({}, Error)
    self.message = props.message or props[1] or "An error occurred"
    self.details = props.details             -- optional detailed error info
    self.code = props.code                   -- optional error code
    self.icon = props.icon ~= false          -- show error icon
    self.retry = props.retry                 -- retry callback function
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    return self
end

function Error:measure(max_width, max_height)
    local height = 40
    if self.details then
        height = height + 20
    end
    if self.code then
        height = height + 16
    end
    return max_width, height
end

function Error:layout(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
end

function Error:draw(theme)
    local x, y, w = self.x, self.y, self.width
    local color = theme.colors.accent_error
    local current_y = y

    -- Error icon (simple X)
    if self.icon then
        local icon_size = 24
        local icon_x = x + 8
        local icon_y = y + 8

        display.line(
            icon_x, icon_y,
            icon_x + icon_size, icon_y + icon_size,
            color
        )
        display.line(
            icon_x + icon_size, icon_y,
            icon_x, icon_y + icon_size,
            color
        )

        x = x + icon_size + 16
    end

    -- Main error message
    display.text_font(
        math.floor(x),
        math.floor(current_y),
        self.message,
        color,
        theme.fonts.body
    )
    current_y = current_y + 24

    -- Error code
    if self.code then
        display.text_font(
            math.floor(x),
            math.floor(current_y),
            "Code: " .. tostring(self.code),
            theme.colors.text_muted,
            theme.fonts.small
        )
        current_y = current_y + 16
    end

    -- Details
    if self.details then
        display.text_font(
            math.floor(x),
            math.floor(current_y),
            self.details,
            theme.colors.text_secondary,
            theme.fonts.small
        )
    end
end

return Error
