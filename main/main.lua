--[[
Moonshot Dashboard
--]]

moonshot = { maxx = 800, maxy = 480, miny = 20 }

-- Initialize display
function moonshot.init()
	display.init()
	moonshot.maxx, moonshot.maxy = display.size()
	return true
end

-- Print header bar
function moonshot.header(title)
	math.randomseed(os.time())
	moonshot.maxx, moonshot.maxy = display.size()
	display.clear(display.BLACK)

	-- Draw header bar
	display.rect(0, 0, moonshot.maxx, moonshot.miny, display.rgb(128, 128, 0), true)
	display.text(math.floor(moonshot.maxx, 2 - #title * 4), 4, title, display.CYAN)
end

-- Random lines demo
function moonshot.lineDemo(sec)
	moonshot.header("LINE DEMO")

	local start = os.time()
	while os.time() - start < sec do
		local x1 = math.random(0, moonshot.maxx - 1)
		local y1 = math.random(moonshot.miny, moonshot.maxy - 1)
		local x2 = math.random(0, moonshot.maxx - 1)
		local y2 = math.random(moonshot.miny, moonshot.maxy - 1)
		local color = math.random(0, 0xFFFF)
		display.line(x1, y1, x2, y2, color)
		sys.sleep(1)
	end
end

-- Random circles demo
function moonshot.circleDemo(sec, dofill)
	local title = "CIRCLE"
	if dofill and dofill > 0 then
		title = "FILLED " .. title
	end
	moonshot.header(title)

	local start = os.time()
	while os.time() - start < sec do
		local x = math.random(20, moonshot.maxx - 20)
		local y = math.random(moonshot.miny + 20, moonshot.maxy - 20)
		local r = math.random(5, 80)
		local color = math.random(0, 0xFFFF)
		local filled = (dofill and dofill > 0)
		display.circle(x, y, r, color, filled)
		sys.sleep(1)
	end
end

-- Random rectangles demo
function moonshot.rectDemo(sec, dofill)
	local title = "RECTANGLE"
	if dofill and dofill > 0 then
		title = "FILLED " .. title
	end
	moonshot.header(title)

	local start = os.time()
	while os.time() - start < sec do
		local x = math.random(0, moonshot.maxx - 50)
		local y = math.random(moonshot.miny, moonshot.maxy - 50)
		local w = math.random(10, 150)
		local h = math.random(10, 100)
		local color = math.random(0, 0xFFFF)
		local filled = (dofill and dofill > 0)
		display.rect(x, y, w, h, color, filled)
		sys.sleep(1)
	end
end

-- Random triangles demo
function moonshot.triangleDemo(sec, dofill)
	local title = "TRIANGLE"
	if dofill and dofill > 0 then
		title = "FILLED " .. title
	end
	moonshot.header(title)

	local start = os.time()
	while os.time() - start < sec do
		local x1 = math.random(0, moonshot.maxx - 1)
		local y1 = math.random(moonshot.miny, moonshot.maxy - 1)
		local x2 = math.random(0, moonshot.maxx - 1)
		local y2 = math.random(moonshot.miny, moonshot.maxy - 1)
		local x3 = math.random(0, moonshot.maxx - 1)
		local y3 = math.random(moonshot.miny, moonshot.maxy - 1)
		local color = math.random(0, 0xFFFF)
		local filled = (dofill and dofill > 0)
		display.triangle(x1, y1, x2, y2, x3, y3, color, filled)
		sys.sleep(1)
	end
end

-- Random pixels demo
function moonshot.pixelDemo(sec)
	moonshot.header("PIXEL DEMO")

	local start = os.time()
	while os.time() - start < sec do
		for i = 1, 500 do
			local x = math.random(0, moonshot.maxx - 1)
			local y = math.random(moonshot.miny, moonshot.maxy - 1)
			local color = math.random(0, 0xFFFF)
			display.pixel(x, y, color)
		end
		sys.sleep(1)
	end
end

-- Intro screen with rainbow
function moonshot.intro(sec)
	moonshot.maxx, moonshot.maxy = display.size()
	display.clear(display.BLACK)

	-- Draw rainbow gradient using horizontal lines
	for y = 0, moonshot.maxy - 1 do
		-- HSV to RGB approximation for rainbow effect
		local hue = (y * 360) / moonshot.maxy
		local r, g, b = 0, 0, 0

		local sector = math.floor(hue / 60)
		local f = (hue / 60) - sector

		if sector == 0 then
			r, g, b = 255, math.floor(255 * f), 0
		elseif sector == 1 then
			r, g, b = math.floor(255 * (1 - f)), 255, 0
		elseif sector == 2 then
			r, g, b = 0, 255, math.floor(255 * f)
		elseif sector == 3 then
			r, g, b = 0, math.floor(255 * (1 - f)), 255
		elseif sector == 4 then
			r, g, b = math.floor(255 * f), 0, 255
		else
			r, g, b = 255, 0, math.floor(255 * (1 - f))
		end

		display.line(0, y, moonshot.maxx - 1, y, display.rgb(r, g, b))
		if y % 50 == 0 then sys.sleep(1) end
	end

	-- Draw centered text
	display.text(300, 200, "ESP32-S3 Lua RTOS", display.BLACK)
	display.text(301, 201, "ESP32-S3 Lua RTOS", display.WHITE)

	display.text(320, 260, "CrowPanel 5-inch", display.BLACK)
	display.text(321, 261, "CrowPanel 5-inch", display.CYAN)

	display.text(350, 320, "TFT Demo", display.BLACK)
	display.text(351, 321, "TFT Demo", display.YELLOW)

	-- Wait
	sys.sleep(sec * 1000)
end

-- Run full sequence
function moonshot.full(sec, rpt)
	rpt = rpt or 1
	sec = sec or 4

	while rpt > 0 do
		moonshot.intro(sec)
		moonshot.lineDemo(sec)
		--moonshot.circleDemo(sec, 0)
		--moonshot.circleDemo(sec, 1)
		--moonshot.rectDemo(sec, 0)
		--moonshot.rectDemo(sec, 1)
		--moonshot.triangleDemo(sec, 0)
		--moonshot.triangleDemo(sec, 1)
		moonshot.pixelDemo(sec)
		rpt = rpt - 1
	end

	-- End screen
	display.clear(display.BLACK)
	display.text(300, 220, "That's all folks!", display.CYAN)
	display.text(280, 280, "Type 'moonshot.fullDemo(4,1)'", display.WHITE)
	display.text(290, 310, "to run demo again", display.WHITE)
end

-- Auto-run on load
if moonshot.init() then
	print("Loaded. Run: moonshot.fullDemo(4, 1)")
end
