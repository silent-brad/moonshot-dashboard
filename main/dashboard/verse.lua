--[[
Bible Verse Component - Fetches and displays daily verse (KJV)
Uses Bible API
--]]

local verse = {}

verse.data = nil
verse.last_update = 0

verse.fallback_verses = {
	{
		ref = "John 3:16",
		text = "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.",
	},
	{ ref = "Psalm 23:1", text = "The LORD is my shepherd; I shall not want." },
	{
		ref = "Proverbs 3:5",
		text = "Trust in the LORD with all thine heart; and lean not unto thine own understanding.",
	},
	{ ref = "Philippians 4:13", text = "I can do all things through Christ which strengtheneth me." },
	{
		ref = "Romans 8:28",
		text = "And we know that all things work together for good to them that love God, to them who are the called according to his purpose.",
	},
	{
		ref = "Isaiah 41:10",
		text = "Fear thou not; for I am with thee: be not dismayed; for I am thy God: I will strengthen thee; yea, I will help thee; yea, I will uphold thee with the right hand of my righteousness.",
	},
	{
		ref = "Jeremiah 29:11",
		text = "For I know the thoughts that I think toward you, saith the LORD, thoughts of peace, and not of evil, to give you an expected end.",
	},
}

function verse.fetch()
	local url = "https://labs.bible.org/api/?passage=votd&type=json&formatting=plain"

	print("Verse: Fetching from " .. url)

	local response, err = http.get(url)

	if response then
		print("Verse: Got response: " .. string.sub(response, 1, 100))

		verse.data = verse.parse(response)
		verse.last_update = os.time()
		return verse.data
	else
		print("Verse: HTTP error: " .. tostring(err))
	end

	verse.data = verse.get_fallback()
	verse.last_update = os.time()
	return verse.data
end

function verse.parse(json_str)
	local data = {
		ref = "Unknown",
		text = "",
	}

	local bookname = json_str:match('"bookname":"([^"]+)"')
	local chapter = json_str:match('"chapter":"([^"]+)"')
	local verse_num = json_str:match('"verse":"([^"]+)"')
	local text = json_str:match('"text":"([^"]+)"')

	if bookname and chapter and verse_num then
		data.ref = string.format("%s %s:%s", bookname, chapter, verse_num)
	end

	if text then
		text = text:gsub("\\u0027", "'")
		text = text:gsub("\\n", " ")
		text = text:gsub("\\r", "")
		data.text = text
	end

	--[[if #data.text == 0 then
		return verse.get_fallback()
	end
  --]]

	return data
end

function verse.get_fallback()
	math.randomseed(os.date("*t").yday)
	local idx = (os.date("*t").yday % #verse.fallback_verses) + 1
	return verse.fallback_verses[idx]
end

function verse.wrap_text(text, max_chars)
	local lines = {}
	local line = ""

	for word in text:gmatch("%S+") do
		if #line + #word + 1 <= max_chars then
			if #line > 0 then
				line = line .. " " .. word
			else
				line = word
			end
		else
			if #line > 0 then
				table.insert(lines, line)
			end
			line = word
		end
	end

	if #line > 0 then
		table.insert(lines, line)
	end

	return lines
end

function verse.draw(x, y, w, h, theme)
	x, y, w, h = math.floor(x), math.floor(y), math.floor(w), math.floor(h)
	local data = verse.data

	if not data then
		data = verse.get_fallback()
	end

	display.rect(x, y - 5, w, 3, theme.accent_magenta, true)

	local cross_x = x + w - 25
	local cross_y = y + 5
	display.line(cross_x + 5, cross_y, cross_x + 5, cross_y + 20, theme.accent_yellow)
	display.line(cross_x, cross_y + 5, cross_x + 10, cross_y + 5, theme.accent_yellow)

	display.text_font(x + 5, y + 5, data.ref, theme.accent_cyan, display.FONT_INTER_20)

	local char_width = 8
	local max_chars = math.floor((w - 20) / char_width)
	local lines = verse.wrap_text(data.text, max_chars)

	local line_height = 18
	local max_lines = math.floor((h - 50) / line_height)

	for i, line in ipairs(lines) do
		if i > max_lines then
			display.text_font(x + 5, y + 25 + (i - 1) * line_height, "...", theme.text_secondary, display.FONT_INTER_20)
			break
		end
		display.text_font(x + 5, y + 25 + (i - 1) * line_height, line, theme.text_primary, display.FONT_INTER_20)
	end

	display.text_font(x + 5, y + h - 20, "- King James Version", theme.text_secondary, display.FONT_GARAMOND_20)
end

return verse
