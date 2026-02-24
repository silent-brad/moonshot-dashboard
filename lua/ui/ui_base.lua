local Component = {}
Component.__index = Component

function Component.new(props)
	local self = setmetatable({}, Component)
	self.props = props or {}
	self.x = 0
	self.y = 0
	self.width = 0
	self.height = 0
	return self
end

function Component:measure(max_width, max_height)
	return self.width, self.height
end

function Component:layout(x, y, width, height)
	self.x = x
	self.y = y
	self.width = width
	self.height = height
end

function Component:draw(theme)
	-- Override in subclass
end

return Component
