local Column = {}
Column.__index = Column

function Column.new(props)
	local self = setmetatable({}, Column)
	self.children = props.children or {}
	self.gap = props.gap or 8
	self.align = props.align or "start" -- start | center | end | stretch
	self.justify = props.justify or "start" -- start | center | end | between | around
	self.x = 0
	self.y = 0
	self.width = 0
	self.height = 0
	return self
end

function Column:measure(max_width, max_height)
	local total_height = 0
	local max_child_width = 0

	for i, child in ipairs(self.children) do
		local cw, ch = child:measure(max_width, max_height)
		total_height = total_height + ch
		if cw > max_child_width then
			max_child_width = cw
		end
	end

	total_height = total_height + self.gap * (#self.children - 1)
	return max_child_width, total_height
end

function Column:layout(x, y, w, h)
	self.x = x
	self.y = y
	self.width = w
	self.height = h

	local total_gap = self.gap * (#self.children - 1)
	local available_height = h - total_gap
	local child_heights = {}
	local total_measured_height = 0

	-- First pass: measure children
	for i, child in ipairs(self.children) do
		local cw, ch = child:measure(w, available_height)
		child_heights[i] = ch
		total_measured_height = total_measured_height + ch
	end

	-- Calculate starting y based on justify
	local cy = y
	local spacing = self.gap

	if self.justify == "center" then
		cy = y + (h - total_measured_height - total_gap) / 2
	elseif self.justify == "end" then
		cy = y + h - total_measured_height - total_gap
	elseif self.justify == "between" and #self.children > 1 then
		spacing = (h - total_measured_height) / (#self.children - 1)
	elseif self.justify == "around" and #self.children > 0 then
		spacing = (h - total_measured_height) / (#self.children + 1)
		cy = y + spacing
	end

	-- Second pass: position children
	for i, child in ipairs(self.children) do
		local cw, _ = child:measure(w, child_heights[i])
		local cx = x
		local child_w = w

		if self.align == "center" then
			cx = x + (w - cw) / 2
			child_w = cw
		elseif self.align == "end" then
			cx = x + w - cw
			child_w = cw
		elseif self.align == "start" then
			child_w = cw
		end

		child:layout(cx, cy, child_w, child_heights[i])
		cy = cy + child_heights[i] + spacing
	end
end

function Column:draw(theme)
	for _, child in ipairs(self.children) do
		child:draw(theme)
	end
end

return Column
