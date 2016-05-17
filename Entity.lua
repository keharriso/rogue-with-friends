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
--   faction = <string> or nil,
--   area = <Area> or nil,
--   position = <Position> or nil,
--   ai = <AI> or nil,
--   intent = <Intent> or nil,
--   action = <Action> or nil,
--   hitPoints = <number> or nil
-- }
--
-- `proto` is consumed and should not be reused or modified.
function Entity.new(proto)
	if type(proto.type) == "string" then
		proto.type = Entity.Type:require(proto.type)
	end
	if proto.hitPoints == nil then
		proto.hitPoints = proto.type:getHitPoints()
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
	local ai = self:getAI()
	if ai ~= nil then
		ai:update(self, dt)
		self:setIntent(ai:generateIntent(self))
	end
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

-- Return the faction of this Entity as a string.
function Entity:getFaction()
	return self.faction
end

-- Set the faction of this Entity as a string.
function Entity:setFaction(faction)
	self.faction = faction
end

-- Return the AI of this Entity.
function Entity:getAI()
	return self.ai
end

-- Set the AI of this Entity.
function Entity:setAI(ai)
	self.ai = ai
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

-- Return the current hit points of this Entity.
function Entity:getHitPoints()
	return self.hitPoints
end

-- Set the current hit points of this Entity.
function Entity:setHitPoints(hitPoints)
	self.hitPoints = hitPoints
end

-- Return the base hit points for this Entity.
function Entity:getMaxHitPoints(hitPoints)
	if self.maxHitPoints == nil then
		self.maxHitPoints = self:getType():getHitPoints()
		return self.maxHitPoints
	else
		return self.maxHitPoints
	end
end

-- Set the base hit points for this Entity.
function Entity:setMaxHitPoints(maxHitPoints)
	self.maxHitPoints = maxHitPoints
end

-- Return the base attack damage for this Entity.
function Entity:getDamage()
	if self.damage == nil then
		self.damage = self:getType():getDamage()
		return self.damage
	else
		return self.damage
	end
end

-- Set the base attack damage for this Entity.
function Entity:setDamage(damage)
	self.damage = damage
end

-- Return the base attack speed for this Entity.
function Entity:getAttackSpeed()
	if self.attackSpeed == nil then
		self.attackSpeed = self:getType():getAttackSpeed()
		return self.attackSpeed
	else
		return self.attackSpeed
	end
end

-- Set the base attack speed for this Entity.
function Entity:setAttackSpeed(attackSpeed)
	self.attackSpeed = attackSpeed
end


-- Return the best (movement type, speed) pair for moving this Entity to the
-- given Tile.
function Entity:getMovement(tile)
	local bestType, bestSpeed = nil, 0
	if tile ~= nil and not tile:isOccupied() then
		for moveType,baseSpeed in self:getType():getMoveSpeeds() do
			local speed = baseSpeed * tile:getMoveSpeed(moveType)
			if speed > bestSpeed then
				bestType, bestSpeed = moveType, speed
			end
		end
	end
	return bestType, bestSpeed
end

-- A Data type representing the type of an Entity.
Entity.Type = Data.new {
	loadAll = function (self)
		local entityTypes = love.filesystem.load "data/entities.lua"()
		for name,entityType in pairs(entityTypes) do
			entityType.name = name
			if entityType.moveSpeed == nil then
				entityType.moveSpeed = {}
			end
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

-- Return an iterator over all (movement type, base speed) associations for
-- this Entity.Type.
function Entity.Type:getMoveSpeeds()
	return pairs(self.moveSpeed)
end

-- Return the base speed of this Entity.Type for the given movement type.
function Entity.Type:getMoveSpeed(moveType)
	return self.moveSpeed[moveType] or 0
end

-- Return the base hit points for this Entity.Type.
function Entity.Type:getHitPoints()
	return self.hitPoints
end

-- Set the base hit points for this Entity.Type.
function Entity.Type:setHitPoints(hitPoints)
	self.hitPoints = hitPoints
end

-- Return the base attack damage for this Entity.Type.
function Entity.Type:getDamage()
	return self.damage
end

-- Set the base attack damage for this Entity.Type.
function Entity.Type:setDamage(damage)
	print("DAMAGEEE", damage)
	self.damage = damage
end

-- Return the base attack speed for this Entity.Type.
function Entity.Type:getAttackSpeed()
	return self.attackSpeed
end

-- Set the base attack speed for this Entity.Type.
function Entity.Type:setAttackSpeed(attackSpeed)
	self.attackSpeed = attackSpeed
end

return Entity
