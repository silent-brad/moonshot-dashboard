local List = {}
List.__index = List

function List.new(props)
    local self = setmetatable({}, List)
    self.items = props.items or {}           -- { "item1", "item2", ... } or { { text = "...", icon = "..." }, ... }
    self.item_height = props.item_height or 32
    self.scroll_offset = props.scroll_offset or 0
    self.show_dividers = props.show_dividers ~= false
    self.numbered = props.numbered or false
    self.bullet = props.bullet              -- nil = no bullet, or "•", "→", etc.
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    return self
end

function List:measure(max_width, max_height)
    local total_height = #self.items * self.item_height
    return max_width, math.min(total_height, max_height)
end

function List:layout(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
end

function List:get_visible_count()
    return math.floor(self.height / self.item_height)
end

function List:scroll_to(index)
    local visible = self:get_visible_count()
    if index <= self.scroll_offset then
        self.scroll_offset = index - 1
    elseif index > self.scroll_offset + visible then
        self.scroll_offset = index - visible
    end
    self.scroll_offset = math.max(0, math.min(self.scroll_offset, #self.items - visible))
end

function List:draw(theme)
    local x, y, w = self.x, self.y, self.width
    local visible_count = self:get_visible_count()
    local start_index = self.scroll_offset + 1
    local end_index = math.min(start_index + visible_count - 1, #self.items)

    for i = start_index, end_index do
        local item = self.items[i]
        local item_y = y + (i - start_index) * self.item_height
        local text = type(item) == "table" and item.text or tostring(item)
        local prefix = ""

        if self.numbered then
            prefix = tostring(i) .. ". "
        elseif self.bullet then
            prefix = self.bullet .. " "
        end

        display.text_font(
            math.floor(x + 8),
            math.floor(item_y + (self.item_height - 16) / 2),
            prefix .. text,
            theme.colors.text_primary,
            theme.fonts.body
        )

        if self.show_dividers and i < end_index then
            display.line(
                x,
                math.floor(item_y + self.item_height - 1),
                x + w,
                math.floor(item_y + self.item_height - 1),
                theme.colors.border
            )
        end
    end

    -- Draw scroll indicator if needed
    if #self.items > visible_count then
        local scrollbar_height = math.floor(self.height * visible_count / #self.items)
        local scrollbar_y = y + math.floor(self.height * self.scroll_offset / #self.items)

        display.rect(
            math.floor(x + w - 4),
            math.floor(scrollbar_y),
            3,
            scrollbar_height,
            theme.colors.text_muted,
            true
        )
    end
end

return List
