--[[
BTC Price Component - Fetches and displays Bitcoin price
Uses CoinGecko API (free, no API key required)
--]]

local btc = {}

btc.data = nil
btc.last_update = 0
btc.price_history = {}
btc.max_history = 20

function btc.fetch()
	local url = "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd&include_24hr_change=true"

	print("BTC: Fetching from " .. url)

	local response, err = http.get(url)

	if response then
		print("BTC: Got response: " .. string.sub(response, 1, 100))
		btc.data = btc.parse(response)
		btc.last_update = os.time()

		if btc.data and btc.data.price then
			table.insert(btc.price_history, btc.data.price)
			if #btc.price_history > btc.max_history then
				table.remove(btc.price_history, 1)
			end
		end

		return btc.data
	else
		print("BTC: HTTP error: " .. tostring(err))
	end

	return nil
end

function btc.parse(json_str)
	local data = {
		price = 0,
		change_24h = 0,
	}

	local price = json_str:match('"usd":([%d%.]+)')
	local change = json_str:match('"usd_24h_change":([%d%.%-]+)')

	if price then
		data.price = tonumber(price)
	end
	if change then
		data.change_24h = tonumber(change)
	end

	return data
end

function btc.format_price(price)
	if price >= 1000000 then
		return string.format("$%.2fM", price / 1000000)
	elseif price >= 1000 then
		return string.format("$%.1fK", price / 1000)
	else
		return string.format("$%.2f", price)
	end
end

function btc.draw(x, y, w, h, theme)
	x, y, w, h = math.floor(x), math.floor(y), math.floor(w), math.floor(h)
	local data = btc.data

	display.text_font(x + 5, y + 5, "BTC", theme.accent_orange, display.FONT_GARAMOND_20)
	display.circle(x + 60, y + 14, 8, theme.accent_orange, false)
	display.text_font(x + 56, y + 5, "B", theme.accent_orange, display.FONT_INTER_20)

	if not data then
		display.text_font(x + 5, y + 35, "NO DATA", theme.text_secondary, display.FONT_INTER_20)
		display.text_font(x + 5, y + 60, "Check connection", theme.accent_orange, display.FONT_INTER_20)
		return
	end

	local price_str = btc.format_price(data.price)
	display.text_font(x + 5, y + 35, price_str, theme.accent_cyan, display.FONT_INTER_20)

	local change_color = theme.accent_cyan
	local change_symbol = ""
	if data.change_24h > 0 then
		change_color = display.rgb(0, 255, 100)
		change_symbol = "+"
	elseif data.change_24h < 0 then
		change_color = display.rgb(255, 80, 80)
		change_symbol = ""
	end

	local change_str = string.format("%s%.2f%%", change_symbol, data.change_24h)
	display.text_font(x + 5, y + 65, "24h:", theme.text_secondary, display.FONT_INTER_20)
	display.text_font(x + 50, y + 65, change_str, change_color, display.FONT_INTER_20)

	btc.draw_chart(x + 5, y + 95, w - 20, h - 125, theme)

	local age = os.time() - btc.last_update
	local age_str = string.format("Updated: %ds ago", age)
	display.text_font(x + 5, y + h - 25, age_str, theme.border, display.FONT_INTER_20)
end

function btc.draw_chart(x, y, w, h, theme)
	x, y, w, h = math.floor(x), math.floor(y), math.floor(w), math.floor(h)
	if #btc.price_history < 2 then
		--display.text(x, math.floor(y + h / 2 - 5), "Collecting data...", theme.text_secondary)
		return
	end

	display.rect(x, y, w, h, theme.border, false)

	local min_price = math.huge
	local max_price = -math.huge
	for _, price in ipairs(btc.price_history) do
		if price < min_price then
			min_price = price
		end
		if price > max_price then
			max_price = price
		end
	end

	local range = max_price - min_price
	if range == 0 then
		range = 1
	end

	local step_x = (w - 4) / (#btc.price_history - 1)
	local prev_x, prev_y = nil, nil

	for i, price in ipairs(btc.price_history) do
		local px = x + 2 + (i - 1) * step_x
		local py = y + h - 2 - ((price - min_price) / range) * (h - 4)

		if prev_x then
			display.line(math.floor(prev_x), math.floor(prev_y), math.floor(px), math.floor(py), theme.accent_cyan)
		end

		prev_x, prev_y = px, py
	end

	if prev_x then
		display.circle(math.floor(prev_x), math.floor(prev_y), 3, theme.accent_magenta, true)
	end
end

return btc
