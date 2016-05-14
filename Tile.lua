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
--   type = <Tile.Type> or <string>,
--   entity = <Entity or nil>,
--   structure = <Structure or nil>
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
function Tile:setType(tileType)
	if type(tileType) == "string" then
		self.type = Tile.Type:require(tileType)
	else
		self.type = tileType
	end
end

-- Return true if there is an Entity or Structure that occupies the space on
-- this Tile, and false otherwise.
function Tile:isOccupied()
	return self:getEntity() ~= nil
end

-- Return the Entity on this Tile (or nil if there is no such Entity).
function Tile:getEntity()
	return self.entity
end

-- Set the Entity on this Tile.
function Tile:setEntity(entity)
	self.entity = entity
end

-- Return the Structure on this Tile (or nil if there is no Structure).
function Tile:getStructure()
	return self.structure
end

-- Set the Structure on this Tile.
function Tile:setStructure(structure)
	self.structure = structure
end

-- Return the speed factor of this Tile for the given movement type.
function Tile:getMoveSpeed(moveType)
	return self:getType():getMoveSpeed(moveType)
end

-- A Data type representing the type of a Tile.
Tile.Type = Data.new {
	loadAll = function (self)
		local tileTypes = love.filesystem.load "data/tiles.lua"()
		for name,tileType in pairs(tileTypes) do
			tileType.name = name
			if tileType.moveSpeed == nil then
				tileType.moveSpeed = {}
			end
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

-- Return an iterator over all (movement type, speed factor) associations for
-- this Tile.Type.
function Tile.Type:getMoveSpeeds()
	return pairs(self.moveSpeed)
end

-- Return the speed factor of this Tile.Type for the given movement type.
function Tile.Type:getMoveSpeed(moveType)
	return self.moveSpeed[moveType] or 0
end

return Tile
