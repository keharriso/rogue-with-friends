-- Rogue with Friends - a 2D, real-time, multiplayer roguelike
-- ---------------------------------------------------------------
-- Released under the GNU AGPLv3 or later. See README.md for info.

-- An Action represents an atomic action that an Entity is engaged in. It has
-- a type (represented by a string), an optional direction, and a progress,
-- which ranges from 0 to 1. When an action starts, its progress is 0, and
-- its effects are triggered when its progress reaches 1.
--
-- All Actions support the following abstract methods:
--   Action:isLegal(entity) - Return true if this action is legal when
--       performed by the given Entity. This is checked before starting it.
--   Action:update(entity, dt) - Advance this Action's progress by `dt`
--       seconds in the context of the given subject, returning the time
--       elapsed (which might be less than `dt` if the Action completed).
--   Action:complete(entity) - Apply this Action's completion as Effects.

local Action = {}

Action.mt = {__index = Action}

-- [private] Action type table.
local ActionType = {}

-- Construct a new Action from the given prototype. `proto` should provide the
-- following fields:
-- {
--   type = <string>,
--   subtype = <string> or nil,
--   direction = <string> or nil
-- }
--
-- `type` should be the name of a valid Action type. See below for the
-- different Action types.
-- `subtype`, when not nil, refers to an additional action subtype (e.g., the
-- movement type for a Move action).
-- `dir`, when not nil, should be in Position.getDirections.
--
-- `proto` is consumed, and should not be reused or modified.
function Action.new(proto)
	return setmetatable(proto, ActionType[proto.type].mt)
end

-- Return the type of this Action as a string.
function Action:getType()
	return self.type
end

-- Return the subtype of this Action as a string (or nil).
function Action:getSubtype()
	return self.subtype
end

-- Set the subtype of this Action.
function Action:setSubtype(subtype)
	self.subtype = subtype
end

-- Return the direction of this Action, if there is one.
function Action:getDirection()
	return self.direction
end

-- Set the direction of this Action.
function Action:setDirection(dir)
	self.direction = dir
end

-- Return this Action's current progress from 0 to 1, or nil if it hasn't
-- started yet.
function Action:getProgress()
	return self.progress
end

-- Set this Action's progress.
function Action:setProgress(progress)
	self.progress = progress
end

-- [private] Generic update function for actions. Relies on isLegal to cache
-- action speed as `self.speed` in completions per second.
local function genericUpdate(self, entity, dt)
	local world = entity:getWorld()
	if self:isLegal(entity) then
		local progress = self:getProgress()
		local tickProgress = self.speed * dt
		local newProgress = math.min(progress + tickProgress, 1)
		local realProgress = newProgress - progress
		local tickElapsed = dt * realProgress / tickProgress
		world:apply {
			type = "Progress",
			entity = entity,
			progress = newProgress
		}
		return tickElapsed
	else
		-- Cancel the action.
		world:apply {
			type = "Start",
			entity = entity,
			action = nil
		}
		return 0
	end
end

-- A Move action moves an entity to a neighboring Position in the same Area.
-- Parameters:
-- {
--   type = "Move",
--   direction = <string>
-- }
ActionType.Move = setmetatable({}, Action.mt)

ActionType.Move.mt = {__index = ActionType.Move}

-- [private] Cache useful information about this Action in the given context.
local function Move_cache(self, entity)
	local dir = self:getDirection()
	local area = entity:getArea()
	local pos = entity:getPosition()
	local tile = area and pos and area:getTile(pos)
	local Position = require "Position"
	local targetPos = pos and dir and pos:getNeighbor(dir)
	local targetTile = area and targetPos and area:getTile(targetPos)
	self.area = area
	self.position = pos
	self.tile = tile
	self.targetPosition = targetPos
	self.targetTile = targetTile
	local distance = pos and targetPos and pos:getDistance(targetPos)
	local moveType, speed = entity:getMovement(targetTile)
	self:setSubtype(moveType)
	self.distance = distance
	self.speed = (distance and speed and speed / distance) or 0
end

function ActionType.Move:isLegal(entity)
	Move_cache(self, entity)
	return self.speed > 0
end

ActionType.Move.update = genericUpdate

function ActionType.Move:complete(entity)
	if self:isLegal(entity) then
		entity:getWorld():apply {
			type = "Move",
			entity = entity,
			area = self.area,
			position = self.targetPosition
		}
	end
end

-- An Attack action attacks a target Entity. Parameters:
-- {
--   type = "Attack",
--   target = <Entity>
-- }
ActionType.Attack = setmetatable({}, Action.mt)

ActionType.Attack.mt = {__index = ActionType.Attack}

-- [private] Cache useful information about this Action in the given context.
local function Attack_cache(self, entity)
	local area = entity:getArea()
	local pos = entity:getPosition()
	local target = self.target
	local targetArea = target and target:getArea()
	local targetPos = target and target:getPosition()
	if area ~= self.area or pos ~= self.position
			or targetArea ~= self.targetArea
			or targetPos ~= self.targetPosition then
		self.area = area
		self.position = pos
		self.targetArea = targetArea
		self.targetPosition = targetPos
		if area ~= nil and area == targetArea and pos ~= nil
				and targetPos ~= nil then
			self:setDirection(pos:getDirection(targetPos))
			self.distance = pos:getDistance(targetPos)
		else
			self:setDirection(nil)
			self.distance = nil
		end
	end
	if entity ~= self.entity then
		self.entity = entity
		self.speed = entity:getType():getAttackSpeed()
		self.damage = entity:getType():getDamage()
	end
end

function ActionType.Attack:isLegal(entity)
	Attack_cache(self, entity)
	return self.distance ~= nil and self.distance < 1.5 and self.speed > 0
end

ActionType.Attack.update = genericUpdate

function ActionType.Attack:complete(entity)
	if self:isLegal(entity) then
		entity:getWorld():apply {
			type = "Damage",
			entity = self.target,
			damage = self.damage
		}
	end
end

-- An Interact action triggers an interaction with the given Structure.
-- Parameters:
-- {
--   type = "Interact",
--   target = <Structure>
-- }
ActionType.Interact = setmetatable({}, Action.mt)

ActionType.Interact.mt = {__index = ActionType.Interact}

-- [private] Cache useful information about this Action in the given context.
local function Interact_cache(self, entity)
	local area = entity:getArea()
	local pos = entity:getPosition()
	local target = self.target
	local targetArea = target and target:getArea()
	local targetPos = target and target:getPosition()
	if area ~= self.area or pos ~= self.position
			or targetArea ~= self.targetArea
			or targetPos ~= self.targetPosition then
		self.area = area
		self.position = pos
		self.targetArea = targetArea
		self.targetPosition = targetPos
		if area ~= nil and area == targetArea and pos ~= nil
				and targetPos ~= nil then
			self.distance = pos:getDistance(targetPos)
		else
			self.distance = nil
		end
	end
	local interactTime = target:getType():getInteractTime()
	if interactTime == nil then
		self.speed = 0
	elseif interactTime > 0 then
		self.speed = 1 / interactTime
	else
		self.speed = math.huge
	end
end

function ActionType.Interact:isLegal(entity)
	Interact_cache(self, entity)
	return self.distance ~= nil and self.distance < 1e-6 and self.speed > 0
end

ActionType.Interact.update = genericUpdate

function ActionType.Interact:complete(entity)
	if self:isLegal(entity) then
		self.target:interact(entity)
	end
end

return Action
