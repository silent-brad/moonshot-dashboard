local swipe = {}

local config = {
	min_distance = 50, -- Minimum swipe distance in pixels
	max_duration = 500, -- Maximum swipe duration in ms
	direction_threshold = 0.7, -- Ratio for directional detection
}

local touch_start = nil

function swipe.init(opts)
	if opts then
		for k, v in pairs(opts) do
			config[k] = v
		end
	end
end

function swipe.on_touch_start(x, y)
	touch_start = {
		x = x,
		y = y,
		time = os.clock() * 1000,
	}
end

function swipe.on_touch_end(x, y)
	if not touch_start then
		return nil
	end

	local dx = x - touch_start.x
	local dy = y - touch_start.y
	local duration = (os.clock() * 1000) - touch_start.time
	local distance = math.sqrt(dx * dx + dy * dy)

	touch_start = nil

	if distance < config.min_distance then
		return nil
	end
	if duration > config.max_duration then
		return nil
	end

	local abs_dx = math.abs(dx)
	local abs_dy = math.abs(dy)

	-- Determine swipe direction
	if abs_dx > abs_dy * config.direction_threshold then
		return dx > 0 and "right" or "left"
	elseif abs_dy > abs_dx * config.direction_threshold then
		return dy > 0 and "down" or "up"
	end

	return nil
end

function swipe.get_velocity(x, y)
	if not touch_start then
		return 0, 0
	end
	local duration = (os.clock() * 1000) - touch_start.time
	if duration == 0 then
		return 0, 0
	end
	return (x - touch_start.x) / duration, (y - touch_start.y) / duration
end

return swipe
