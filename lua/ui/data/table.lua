local Table = {}
Table.__index = Table

function Table.new(props)
    local self = setmetatable({}, Table)
    self.columns = props.columns or {}   -- { { key = "name", label = "Name", width = 100 }, ... }
    self.rows = props.rows or {}         -- { { name = "...", value = 123 }, ... }
    self.header = props.header ~= false
    self.striped = props.striped or false
    self.row_height = props.row_height or 24
    self.header_height = props.header_height or 28
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    return self
end

function Table:measure(max_width, max_height)
    local header_h = self.header and self.header_height or 0
    local total_height = header_h + #self.rows * self.row_height
    return max_width, math.min(total_height, max_height)
end

function Table:layout(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
end

function Table:draw(theme)
    local x, y, w = self.x, self.y, self.width
    local current_y = y

    -- Calculate column widths
    local total_specified = 0
    local unspecified_count = 0
    for _, col in ipairs(self.columns) do
        if col.width then
            total_specified = total_specified + col.width
        else
            unspecified_count = unspecified_count + 1
        end
    end
    local remaining = w - total_specified
    local auto_width = unspecified_count > 0 and remaining / unspecified_count or 0

    -- Draw header
    if self.header then
        display.rect(x, current_y, w, self.header_height, theme.colors.bg_secondary, true)

        local col_x = x
        for _, col in ipairs(self.columns) do
            local col_width = col.width or auto_width
            display.text_font(
                math.floor(col_x + 4),
                math.floor(current_y + 4),
                col.label or col.key,
                theme.colors.text_secondary,
                theme.fonts.small
            )
            col_x = col_x + col_width
        end

        current_y = current_y + self.header_height
        display.line(x, current_y, x + w, current_y, theme.colors.border)
    end

    -- Draw rows
    for i, row in ipairs(self.rows) do
        if current_y + self.row_height > y + self.height then
            break
        end

        -- Striped background
        if self.striped and i % 2 == 0 then
            display.rect(x, current_y, w, self.row_height, theme.colors.bg_secondary, true)
        end

        local col_x = x
        for _, col in ipairs(self.columns) do
            local col_width = col.width or auto_width
            local value = row[col.key] or ""
            display.text_font(
                math.floor(col_x + 4),
                math.floor(current_y + 4),
                tostring(value),
                theme.colors.text_primary,
                theme.fonts.small
            )
            col_x = col_x + col_width
        end

        current_y = current_y + self.row_height
    end
end

return Table
