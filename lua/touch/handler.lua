local swipe = require("touch.swipe")
local screen_manager = require("screen_manager")

local handler = {}

function handler.init()
	swipe.init({
		min_distance = 80,
		max_duration = 400,
	})
end

function handler.process_touch(event_type, x, y)
	if event_type == "start" then
		swipe.on_touch_start(x, y)
	elseif event_type == "end" then
		local direction = swipe.on_touch_end(x, y)

		if direction == "left" then
			screen_manager.next()
		elseif direction == "right" then
			screen_manager.prev()
		elseif direction == "up" then
			-- Optional: scroll within widget or show overlay
		elseif direction == "down" then
			-- Optional: refresh current screen or show menu
		end
	end
end

return handler
