local Plugin = {}
Plugin.__index = Plugin

function Plugin.new(spec)
	local self = setmetatable({}, Plugin)
	self.name = spec.name
	self.version = spec.version or "1.0.0"
	self.description = spec.description or ""
	self.author = spec.author or "Anonymous"
	self.config_schema = spec.config_schema or {}
	self.default_config = spec.default_config or {}
	self.config = {}
	self.data = nil
	self.last_fetch = 0
	self.fetch_interval = spec.fetch_interval or 300
	self.error = nil
	self.on_init = spec.on_init or function() end
	self.on_fetch = spec.on_fetch or function()
		return nil
	end
	self.on_render = spec.on_render or function() end
	self.on_destroy = spec.on_destroy or function() end
	self.sizes = spec.sizes or { "full", "half_v", "half_h", "quarter" }
	return self
end

function Plugin:init(config)
	self.config = {}
	for k, v in pairs(self.default_config) do
		self.config[k] = v
	end
	for k, v in pairs(config or {}) do
		self.config[k] = v
	end
	self:on_init()
end

function Plugin:should_fetch()
	return (os.time() - self.last_fetch) >= self.fetch_interval
end

function Plugin:fetch()
	if not self:should_fetch() then
		return self.data
	end
	local ok, result = pcall(self.on_fetch, self)
	if ok then
		self.data = result
		self.last_fetch = os.time()
		self.error = nil
	else
		self.error = result
	end
	return self.data
end

function Plugin:render(x, y, w, h, theme, size)
	if self.error then
		display.text_font(x + 10, y + 20, "Error", theme.colors.accent_error, theme.fonts.body)
		display.text_font(x + 10, y + 45, tostring(self.error):sub(1, 30), theme.colors.text_muted, theme.fonts.small)
		return
	end
	self:on_render(x, y, w, h, theme, size)
end

function Plugin:destroy()
	self:on_destroy()
end

function Plugin:store(key, value)
	if db then
		db.set(self.name .. ":" .. key, value)
	end
end

function Plugin:retrieve(key)
	if db then
		return db.get(self.name .. ":" .. key)
	end
	return nil
end

return Plugin
