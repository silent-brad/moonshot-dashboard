--[[
Moonshot Dashboard Configuration
--]]

local config = {}

local env = {}

local function parse_env(content)
	local vars = {}
	for line in content:gmatch("[^\r\n]+") do
		line = line:match("^%s*(.-)%s*$")

		if line ~= "" and line:sub(1, 1) ~= "#" then
			local key, value = line:match("^([%w_]+)%s*=%s*(.*)$")
			if key and value then
				value = value:match("^['\"]?(.-)['\"]?$")
				vars[key] = value
			end
		end
	end
	return vars
end

local function load_env()
	local ok, content = pcall(function()
		return require("config.env")
	end)

	if ok and content then
		env = parse_env(content)
	else
		print("Warning: Could not load .env file")
	end
end

local function get_env(key, default)
	return env[key] or default
end

load_env()

config.env = get_env

config.wifi = {
	ssid = get_env("WIFI_SSID", "YOUR_WIFI_SSID"),
	password = get_env("WIFI_PASSWORD", "YOUR_WIFI_PASSWORD"),
}

config.weather = {
	api_key = get_env("WEATHER_API_KEY", "YOUR_OPENWEATHERMAP_API_KEY"),
	city = get_env("WEATHER_CITY", "New York"),
	country = get_env("WEATHER_COUNTRY", "US"),
	units = get_env("WEATHER_UNITS", "imperial"),
}

config.display = {
	width = 800,
	height = 480,
	header_height = 30,
	refresh_interval = tonumber(get_env("DISPLAY_REFRESH_INTERVAL", "300")),
}

config.theme = {
	bg_primary = 0x0000,
	bg_secondary = 0x0841,
	accent_cyan = 0x07FF,
	accent_magenta = 0xF81F,
	accent_yellow = 0xFFE0,
	accent_orange = 0xFD20,
	text_primary = 0xFFFF,
	text_secondary = 0xC618,
	border = 0x4A69,
	glow = 0x001F,
}

config.panels = {
	weather = { x = 10, y = 40, w = 250, h = 200 },
	btc = { x = 270, y = 40, w = 250, h = 200 },
	verse = { x = 10, y = 250, w = 780, h = 220 },
}

return config
