local Spacer = {}
Spacer.__index = Spacer

function Spacer.new(props)
    local self = setmetatable({}, Spacer)
    self.flex = props.flex or 1
    self.min_size = props.min_size or 0
    self.max_size = props.max_size
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    return self
end

function Spacer:measure(max_width, max_height)
    local w = self.min_size
    local h = self.min_size

    if self.max_size then
        w = math.min(max_width, self.max_size)
        h = math.min(max_height, self.max_size)
    end

    return w, h
end

function Spacer:layout(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
end

function Spacer:draw(theme)
    -- Spacer is invisible, no rendering
end

return Spacer
