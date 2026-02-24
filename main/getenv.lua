--[[
Environment variable loader for Moonshot Dashboard
Parses .env file and provides get_env() function
--]]

local M = {}

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

function M.get(key, default)
	return env[key] or default
end

load_env()

return M
