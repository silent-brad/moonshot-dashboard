--[[
Weather Component - Fetches and displays weather data
Uses OpenWeatherMap API
--]]

local weather = {}

weather.data = nil
weather.last_update = 0

weather.icons = {
	clear = "☀",
	clouds = "☁",
	rain = "🌧",
	snow = "❄",
	thunder = "⚡",
	mist = "🌫",
}

local function url_encode(str)
	if str then
		str = string.gsub(str, " ", "%%20")
		str = string.gsub(str, ",", "%%2C")
	end
	return str
end

function weather.fetch(api_key, city, country, units)
	units = units or "imperial"

	local encoded_city = url_encode(city)
	local url = string.format(
		"http://api.openweathermap.org/data/2.5/weather?q=%s,%s&appid=%s&units=%s",
		encoded_city,
		country,
		api_key,
		units
	)

	local ok, response = pcall(function()
		return http.get(url)
	end)

	if ok and response then
		weather.data = weather.parse(response)
		weather.last_update = os.time()
		return weather.data
	end

	return nil
end

function weather.parse(json_str)
	local data = {
		temp = 0,
		feels_like = 0,
		humidity = 0,
		description = "N/A",
		icon = "clear",
		city = "Unknown",
	}

	local temp = json_str:match('"temp":([%d%.%-]+)')
	local feels = json_str:match('"feels_like":([%d%.%-]+)')
	local humidity = json_str:match('"humidity":(%d+)')
	local desc = json_str:match('"description":"([^"]+)"')
	local main = json_str:match('"main":"([^"]+)"')
	local name = json_str:match('"name":"([^"]+)"')

	if temp then
		data.temp = math.floor(tonumber(temp))
	end
	if feels then
		data.feels_like = math.floor(tonumber(feels))
	end
	if humidity then
		data.humidity = tonumber(humidity)
	end
	if desc then
		data.description = desc
	end
	if name then
		data.city = name
	end

	if main then
		main = main:lower()
		if main:find("clear") then
			data.icon = "clear"
		elseif main:find("cloud") then
			data.icon = "clouds"
		elseif main:find("rain") or main:find("drizzle") then
			data.icon = "rain"
		elseif main:find("snow") then
			data.icon = "snow"
		elseif main:find("thunder") then
			data.icon = "thunder"
		else
			data.icon = "mist"
		end
	end

	return data
end

function weather.draw(x, y, w, h, theme)
	x, y, w, h = math.floor(x), math.floor(y), math.floor(w), math.floor(h)
	local data = weather.data

	if not data then
		display.text_font(x, y + 20, "NO DATA", theme.text_secondary, display.FONT_INTER_20)
		display.text_font(x, y + 45, "Check WiFi/API", theme.accent_orange, display.FONT_INTER_20)
		return
	end

	local temp_str = string.format("%dF", data.temp)
	display.text_font(x + 5, y + 10, temp_str, theme.accent_cyan, display.FONT_INTER_20)

	display.text_font(x + 80, y + 10, data.city, theme.text_primary, display.FONT_GARAMOND_20)

	display.text_font(x + 5, y + 40, data.description, theme.text_secondary, display.FONT_INTER_20)

	local feels_str = string.format("Feels: %dF", data.feels_like)
	display.text_font(x + 5, y + 65, feels_str, theme.text_secondary, display.FONT_INTER_20)

	local humid_str = string.format("Humidity: %d%%", data.humidity)
	display.text_font(x + 5, y + 90, humid_str, theme.text_secondary, display.FONT_INTER_20)

	weather.draw_icon(x + w - 60, y + 10, data.icon, theme)

	local age = os.time() - weather.last_update
	local age_str = string.format("Updated: %ds ago", age)
	display.text_font(x + 5, y + h - 25, age_str, theme.border, display.FONT_INTER_20)
end

function weather.draw_icon(x, y, icon_type, theme)
	local color = theme.accent_yellow

	if icon_type == "clear" then
		display.circle(x + 20, y + 20, 15, color, true)
		for i = 0, 7 do
			local angle = i * math.pi / 4
			local x1 = x + 20 + math.cos(angle) * 20
			local y1 = y + 20 + math.sin(angle) * 20
			local x2 = x + 20 + math.cos(angle) * 28
			local y2 = y + 20 + math.sin(angle) * 28
			display.line(math.floor(x1), math.floor(y1), math.floor(x2), math.floor(y2), color)
		end
	elseif icon_type == "clouds" then
		display.circle(x + 15, y + 25, 12, theme.text_secondary, true)
		display.circle(x + 30, y + 20, 15, theme.text_secondary, true)
		display.circle(x + 40, y + 28, 10, theme.text_secondary, true)
	elseif icon_type == "rain" then
		display.circle(x + 25, y + 15, 12, theme.text_secondary, true)
		for i = 0, 3 do
			local lx = x + 10 + i * 12
			display.line(lx, y + 30, lx - 5, y + 45, theme.accent_cyan)
		end
	elseif icon_type == "snow" then
		for i = 0, 5 do
			local sx = x + 5 + (i % 3) * 15
			local sy = y + 10 + math.floor(i / 3) * 20
			display.text_font(sx, sy, "*", theme.text_primary, display.FONT_INTER_20)
		end
	elseif icon_type == "thunder" then
		display.circle(x + 25, y + 12, 10, theme.text_secondary, true)
		display.line(x + 25, y + 22, x + 20, y + 32, theme.accent_yellow)
		display.line(x + 20, y + 32, x + 28, y + 32, theme.accent_yellow)
		display.line(x + 28, y + 32, x + 22, y + 45, theme.accent_yellow)
	else
		for i = 0, 2 do
			display.line(x + 5, y + 15 + i * 10, x + 45, y + 15 + i * 10, theme.text_secondary)
		end
	end
end

return weather
