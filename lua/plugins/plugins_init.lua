local registry = require("plugins.registry")

local manager = {}

manager.active_plugins = {}

function manager.init(config)
	print("Plugins manager initializing...")
	registry.discover()
	print("Discovered plugins: " .. table.concat(registry.list(), ", "))

	for _, plugin_cfg in ipairs(config.plugins or {}) do
		local name = plugin_cfg.name
		local slot = plugin_cfg.slot
		local cfg = plugin_cfg.config or {}

		if config.plugin_config and config.plugin_config[name] then
			for k, v in pairs(config.plugin_config[name]) do
				if cfg[k] == nil then
					cfg[k] = v
				end
			end
		end

		local instance, err = registry.load(name, cfg)
		if instance then
			manager.active_plugins[slot] = {
				plugin = instance,
				name = name,
				slot = slot,
			}
			print("Loaded plugin: " .. name .. " -> " .. slot)
		else
			print("Failed to load plugin: " .. name .. " - " .. (err or "unknown error"))
		end
	end
end

function manager.fetch_all()
	for _, entry in pairs(manager.active_plugins) do
		entry.plugin:fetch()
	end
end

function manager.render_slot(slot_or_name, x, y, w, h, theme, size)
	-- Try direct slot lookup first
	local entry = manager.active_plugins[slot_or_name]
	-- Fall back to name lookup
	if not entry then
		for _, e in pairs(manager.active_plugins) do
			if e.name == slot_or_name then
				entry = e
				break
			end
		end
	end
	if entry then
		entry.plugin:render(x, y, w, h, theme, size)
	end
end

function manager.get_plugin(slot_or_name)
	if manager.active_plugins[slot_or_name] then
		return manager.active_plugins[slot_or_name].plugin
	end
	for _, entry in pairs(manager.active_plugins) do
		if entry.name == slot_or_name then
			return entry.plugin
		end
	end
	return nil
end

function manager.shutdown()
	for slot, entry in pairs(manager.active_plugins) do
		entry.plugin:destroy()
	end
	manager.active_plugins = {}
end

return manager
