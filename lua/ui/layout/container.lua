local Container = {}
Container.__index = Container

function Container.new(props)
	local self = setmetatable({}, Container)
	self.children = props.children or {}
	self.theme = props.theme
	self.padding = props.padding or 0
	self.x = 0
	self.y = 0
	self.width = props.width or 800
	self.height = props.height or 480
	return self
end

function Container:measure(max_width, max_height)
	return self.width, self.height
end

function Container:layout(x, y, width, height)
	self.x = x or self.x
	self.y = y or self.y
	self.width = width or self.width
	self.height = height or self.height

	local content_x = self.x + self.padding
	local content_y = self.y + self.padding
	local content_w = self.width - self.padding * 2
	local content_h = self.height - self.padding * 2

	for _, child in ipairs(self.children) do
		child:layout(content_x, content_y, content_w, content_h)
	end
end

function Container:draw(theme)
	local active_theme = theme or self.theme

	if active_theme and active_theme.colors and active_theme.colors.bg_primary then
		display.rect(self.x, self.y, self.width, self.height, active_theme.colors.bg_primary, true)
	end

	for _, child in ipairs(self.children) do
		child:draw(active_theme)
	end
end

function Container:add(child)
	table.insert(self.children, child)
end

return Container
