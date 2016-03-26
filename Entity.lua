-- Rogue with Friends - a 2D, real-time, multiplayer roguelike
-- ---------------------------------------------------------------
-- Released under the GNU AGPLv3 or later. See README.md for info.

local Data = require "Data"

-- An Entity is an agent in the game world capable of performing actions.
-- Entities have a type, represented by Entity.Type, and maintain a state,
-- including an Intent and an ongoing Action.

local Entity = {}

Entity.mt = {__index = Entity}

-- Construct a new Entity from the given prototype. `proto` should provide the
-- following fields:
-- {
--   id = <number>,
--   type = <Entity.Type> or <string>,
--   area = <Area> or nil,
--   position = <Position> or nil,
--   intent = <Intent> or nil,
--   action = <Action> or nil
-- }
--
-- `proto` is consumed and should not be reused or modified.
function Entity.new(proto)
	if type(proto.type) == "string" then
		proto.type = Entity.Type:require(proto.type)
	end
	return setmetatable(proto, Entity.mt)
end

-- [private] Generate a new Action from this Entity's Intent.
local function generateAction(self)
	local intent = self:getIntent()
	if intent ~= nil then
		local action = intent:generateAction(self)
		if action == nil or not action:isLegal(self) then
			self:setIntent(nil)
		else
			self:getWorld():apply {
				type = "Start",
				entity = self,
				action = action
			}
			return action
		end
	end
end

-- Perform one tick worth of updates to this Entity in the context of the
-- given World object, advancing by `dt` seconds.
function Entity:update(dt)
	local action = self:getAction() or generateAction(self)
	while action ~= nil and dt > 0 do
		dt = dt - action:update(self, dt)
		if dt < 1e-6 then dt = 0 end
		action = self:getAction() or generateAction(self)
	end
end

-- Return the ID associated with this Entity.
function Entity:getId()
	return self.id
end

-- Return the Entity.Type associated with this Entity.
function Entity:getType()
	return self.type
end

-- Set the Entity.Type associated with this Entity.
function Entity:setType(entityType)
	if type(entityType) == "string" then
		self.type = Entity.Type:require(entityType)
	else
		self.type = entityType
	end
end

-- Return the World that this Entity is a part of, if any.
function Entity:getWorld()
	local area = self:getArea()
	return area and area:getWorld()
end

-- Return the Area that this Entity is currently in, if any.
function Entity:getArea()
	return self.area
end

-- Set the Area that this Entity is in.
function Entity:setArea(area)
	self.area = area
end

-- Return the current Position of this Entity.
function Entity:getPosition()
	return self.position
end

-- Set the Position of this Entity.
function Entity:setPosition(position)
	self.position = position
end

-- Return the current Intent of this Entity.
function Entity:getIntent()
	return self.intent
end

-- Set the current Intent of this Entity.
function Entity:setIntent(intent)
	self.intent = intent
end

-- Return the current Action of this Entity.
function Entity:getAction()
	return self.action
end

-- Set the current Action of this Entity.
function Entity:setAction(action)
	self.action = action
end

-- A Data type representing the type of an Entity.
Entity.Type = Data.new {
	loadAll = function (self)
		local entityTypes = love.filesystem.load "data/entities.lua"()
		for name,entityType in pairs(entityTypes) do
			entityType.name = name
			setmetatable(entityType, Entity.Type.mt)
		end
		return entityTypes
	end
}

Entity.Type.mt = {__index = Entity.Type}

-- Return the name of this Entity.Type.
function Entity.Type:getName()
	return self.name
end

return Entity
