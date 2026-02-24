--[[
Moonshot Dashboard Configuration
--]]

local get_env = require("getenv").get

local config = {}

config.env = get_env

config.wifi = {
	ssid = get_env("WIFI_SSID", "YOUR_WIFI_SSID"),
	password = get_env("WIFI_PASSWORD", "YOUR_WIFI_PASSWORD"),
}

config.display = {
	width = 800,
	height = 480,
	header_height = 30,
	refresh_interval = tonumber(get_env("DISPLAY_REFRESH_INTERVAL", "300")),
}

config.theme = "minimal"
config.layout = "default"

config.panels = {
	weather = { x = 10, y = 40, w = 250, h = 200 },
	btc = { x = 270, y = 40, w = 250, h = 200 },
	verse = { x = 10, y = 250, w = 780, h = 220 },
}

-- Load plugins from config/plugins/ directory
-- Each plugin file returns { enabled, slot, config }
local plugin_files = {
	"weather",
	"btc",
	"verse",
	"todo",
	"calendar",
	"clock",
	"system",
}

config.plugins = {}
config.plugin_config = {}

for _, name in ipairs(plugin_files) do
	local ok, plugin_cfg = pcall(require, "config.plugins." .. name)
	if ok and plugin_cfg.enabled then
		table.insert(config.plugins, {
			name = name,
			slot = plugin_cfg.slot,
			config = plugin_cfg.config,
		})
		config.plugin_config[name] = plugin_cfg.config
	end
end

return config
