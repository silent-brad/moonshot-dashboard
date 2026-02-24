local registry = {
	plugins = {},
	loaded = {},
}

function registry.discover()
	local builtin = {
		"weather",
		"btc",
		"verse",
		"calendar",
		"clock",
		"system",
		"todo",
	}

	for _, name in ipairs(builtin) do
		local ok, plugin = pcall(require, "plugins.builtin." .. name)
		if ok then
			registry.register(plugin)
		end
	end
end

function registry.register(plugin)
	if registry.plugins[plugin.name] then
		print("Warning: Plugin '" .. plugin.name .. "' already registered")
		return false
	end
	registry.plugins[plugin.name] = plugin
	return true
end

function registry.get(name)
	return registry.plugins[name]
end

function registry.list()
	local names = {}
	for name, _ in pairs(registry.plugins) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

function registry.load(name, config)
	local plugin_def = registry.get(name)
	if not plugin_def then
		return nil, "Plugin not found: " .. name
	end

	local instance = setmetatable({}, { __index = plugin_def })
	instance:init(config)

	registry.loaded[name] = instance
	return instance
end

function registry.unload(name)
	local instance = registry.loaded[name]
	if instance then
		instance:destroy()
		registry.loaded[name] = nil
	end
end

return registry
