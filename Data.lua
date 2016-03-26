-- Rogue with Friends - a 2D, real-time, multiplayer roguelike
-- ---------------------------------------------------------------
-- Released under the GNU AGPLv3 or later. See README.md for info.

-- A Data object represents a type of game data that can be loaded and
-- accessed by name. Each Data type maintains its own cache mapping names to
-- objects, and provides Data:get(name) to retrive the object associated with
-- a given name.
--
-- Before using a Data type, you must call Data:init in order to set up its
-- cache. For convenience, the base Data class provides Data.init(...), which
-- can take any number of Data types to initialize at once. When called
-- without any arguments, Data.init initializes all uninitialized Data types.

local Data = {}

Data.mt = {__index = Data}

-- [private] Set of data types that need to be initialized.
local needsInit = {}

-- Construct a new Data type from the given prototype. `proto` should
-- contain at least one of the following functions:
--   proto:loadAll() - Load all of this type of game data at once. Return a
--       table mapping names to data objects.
--   proto:load(name) - Load and return the game data object of this type
--       associated with the given name.
--
-- `proto` is consumed and should not be reused or modified.
function Data.new(proto)
	setmetatable(proto, Data.mt)
	if proto.loadAll == nil then
		-- We don't need to defer cache initialization.
		proto:init()
	else
		needsInit[proto] = true
	end
	return proto
end

-- [private] Initialize a single Data type.
local function init(data)
	data.cache = data.loadAll and data:loadAll() or {}
	setmetatable(data.cache, {
		__index = function (cache, name)
			if data.load ~= nil then
				local object = data:load(name)
				cache[name] = object
				return object
			end
		end
	})
	needsInit[data] = nil
end

-- Initialize one or more Data types by constructing their caches and
-- populating them with the result of Data:loadAll, if defined.
function Data.init(...)
	if select("#", ...) == 0 then
		for data,_ in pairs(needsInit) do
			init(data)
		end
	else
		for _,data in ipairs {...} do
			init(data)
		end
	end
end

-- Return the game data object of this type associated with the given name,
-- attempting to load it if it isn't already cached.
function Data:get(name)
	return self.cache[name]
end

-- Attempt to retrieve game data by name, as with Data:get, but throw an error
-- on failure.
function Data:require(name)
	return assert(self:get(name),
			"failed to load data by name `"..name.."`")
end

return Data
