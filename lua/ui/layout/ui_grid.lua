local Grid = {}
Grid.__index = Grid

function Grid.new(props)
	local self = setmetatable({}, Grid)
	self.children = props.children or {}
	self.columns = props.columns or 2
	self.rows = props.rows -- nil = auto-calculate
	self.gap = props.gap or 8
	self.row_gap = props.row_gap or props.gap or 8
	self.col_gap = props.col_gap or props.gap or 8
	self.x = 0
	self.y = 0
	self.width = 0
	self.height = 0
	return self
end

function Grid:measure(max_width, max_height)
	local row_count = self.rows or math.ceil(#self.children / self.columns)
	local col_width = (max_width - self.col_gap * (self.columns - 1)) / self.columns
	local row_height = (max_height - self.row_gap * (row_count - 1)) / row_count
	return max_width, max_height
end

function Grid:layout(x, y, w, h)
	self.x = x
	self.y = y
	self.width = w
	self.height = h

	local row_count = self.rows or math.ceil(#self.children / self.columns)
	local col_width = (w - self.col_gap * (self.columns - 1)) / self.columns
	local row_height = (h - self.row_gap * (row_count - 1)) / row_count

	for i, child in ipairs(self.children) do
		local col = (i - 1) % self.columns
		local row = math.floor((i - 1) / self.columns)

		local cx = x + col * (col_width + self.col_gap)
		local cy = y + row * (row_height + self.row_gap)

		child:layout(cx, cy, col_width, row_height)
	end
end

function Grid:draw(theme)
	for _, child in ipairs(self.children) do
		child:draw(theme)
	end
end

return Grid
