-- Rogue with Friends - a 2D, real-time, multiplayer roguelike
-- ---------------------------------------------------------------
-- Released under the GNU AGPLv3 or later. See README.md for info.

local Data = require "Data"

-- A Tile is a unit of space in an Area. Tiles have a type, represented by
-- Tile.Type, and may or may not contain an Entity.

local Tile = {}

Tile.mt = {__index = Tile}

-- Construct a new Tile from the given prototype. `proto` should provide the
-- following fields:
-- {
--   type = <Tile.Type> or <string>
--   entity = <Entity or nil>
-- }
--
-- `proto` is consumed and should not be reused or modified.
function Tile.new(proto)
	if type(proto.type) == "string" then
		proto.type = Tile.Type:require(proto.type)
	end
	return setmetatable(proto, Tile.mt)
end

-- Return the Tile.Type associated with this Tile.
function Tile:getType()
	return self.type
end

-- Set the Tile.Type associated with this Tile.
function Tile:setType(type)
	self.type = type
end

-- Return the Entity on this Tile (or nil if there is no such Entity).
function Tile:getEntity()
	return self.entity
end

-- Set the Entity on this Tile.
function Tile:setEntity(entity)
	self.entity = entity
end

-- A Data type representing the type of a Tile.
Tile.Type = Data.new {
	loadAll = function (self)
		local tileTypes = dofile "data/tiles.lua"
		for name,tileType in pairs(tileTypes) do
			tileType.name = name
			setmetatable(tileType, Tile.Type.mt)
		end
		return tileTypes
	end
}

Tile.Type.mt = {__index = Tile.Type}

-- Return the name of this Tile.Type.
function Tile.Type:getName()
	return self.name
end

-- Return true if this Tile type prevents movement, and false otherwise.
function Tile.Type:isSolid()
	return self.solid
end

return Tile
