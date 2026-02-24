local screen_manager = {}

local screens = {}
local current_screen = 1
local transition_active = false
local transition_offset = 0

function screen_manager.init(screen_list)
	screens = screen_list or {}
	current_screen = 1
end

function screen_manager.add_screen(screen)
	table.insert(screens, screen)
end

function screen_manager.get_current()
	return screens[current_screen]
end

function screen_manager.get_screen_count()
	return #screens
end

function screen_manager.get_current_index()
	return current_screen
end

function screen_manager.go_to(index)
	if index >= 1 and index <= #screens then
		current_screen = index
		return true
	end
	return false
end

function screen_manager.next()
	if current_screen < #screens then
		current_screen = current_screen + 1
		return true
	end
	return false
end

function screen_manager.prev()
	if current_screen > 1 then
		current_screen = current_screen - 1
		return true
	end
	return false
end

return screen_manager
