local store = {}
local cache = {}
local dirty = false

function store.init(path)
	store.path = path or "/data/store.json"
	store.load()
	return true
end

function store.load()
	local f = io.open(store.path, "r")
	if f then
		local content = f:read("*a")
		f:close()
		local ok, data = pcall(json.decode, content)
		if ok then
			cache = data
		end
	end
end

function store.save()
	if not dirty then
		return
	end
	local f = io.open(store.path, "w")
	if f then
		f:write(json.encode(cache))
		f:close()
		dirty = false
	end
end

function store.set(key, value)
	cache[key] = value
	dirty = true
end

function store.get(key)
	return cache[key]
end

function store.delete(key)
	cache[key] = nil
	dirty = true
end

return store
