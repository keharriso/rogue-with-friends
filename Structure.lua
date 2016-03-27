-- Rogue with Friends - a 2D, real-time, multiplayer roguelike
-- ---------------------------------------------------------------
-- Released under the GNU AGPLv3 or later. See README.md for info.

local Data = require "Data"

-- A Structure is an inanimate, potentially interactive game object that
-- resides on a Tile. Structures have a type, represented by Structure.Type,
-- which determines the effects of interaction.

local Structure = {}

Structure.mt = {__index = Structure}

-- Construct a new Structure from the given prototype. `proto` should provide
-- the following fields:
-- {
--   id = <number>,
--   type = <Structure.Type> or <string>,
--   area = <Area> or nil,
--   position = <Position> or nil
-- }
--
-- `proto` is consumed and should not be reused or modified.
function Structure.new(proto)
	if type(proto.type) == "string" then
		proto.type = Structure.Type:require(proto.type)
	end
	return setmetatable(proto, Structure.mt)
end

-- Return the ID associated with this Structure.
function Structure:getId()
	return self.id
end

-- Return the Structure.Type associated with this Structure.
function Structure:getType()
	return self.type
end

-- Set the Structure.Type associated with this Structure.
function Structure:setType(structureType)
	if type(structureType) == "string" then
		self.type = Structure.Type:require(structureType)
	else
		self.type = structureType
	end
end

-- Return the World that this Structure is a part of, if any.
function Structure:getWorld()
	local area = self:getArea()
	return area and area:getWorld()
end

-- Return the Area that this Structure is currently in, if any.
function Structure:getArea()
	return self.area
end

-- Set the Area that this Structure is in.
function Structure:setArea(area)
	self.area = area
end

-- Return the current Position of this Structure.
function Structure:getPosition()
	return self.position
end

-- Set the Position of this Structure.
function Structure:setPosition(position)
	self.position = position
end

-- Trigger an interaction with this Structure.
function Structure:interact(entity)
	local interact = self:getType().interact
	if interact ~= nil then
		interact(self, entity)
	end
end

-- A Data type representing the type of a Structure.
Structure.Type = Data.new {
	loadAll = function (self)
		local structureTypes = love.filesystem.load "data/structures.lua"()
		for name,structureType in pairs(structureTypes) do
			structureType.name = name
			setmetatable(structureType, Structure.Type.mt)
		end
		return structureTypes
	end
}

Structure.Type.mt = {__index = Structure.Type}

-- Return the name of this Structure.Type.
function Structure.Type:getName()
	return self.name
end

-- Return the interact time for this Structure.Type.
function Structure.Type:getInteractTime()
	return self.interactTime
end

return Structure
