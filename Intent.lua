-- Rogue with Friends - a 2D, real-time, multiplayer roguelike
-- ---------------------------------------------------------------
-- Released under the GNU AGPLv3 or later. See README.md for info.

local Action = require "Action"
local Astar = require "Astar"
local Position = require "Position"

-- An Intent represents a medium-term goal that generates short-term Actions
-- in pursuit of that goal. When an Entity has an Intent, but no Action, it
-- attempts to generate an action from its intent.
--
-- All Intents support the following abstract method:
--   Intent:generateAction(entity) - Return a new Action that helps the given
--       Entity achieve this Intent. Returns nil when this Intent is complete.

local Intent = {}

Intent.mt = {__index = Intent}

-- [private] Intent type table.
local IntentType = {}

-- Construct a new Intent from the given prototype. `proto` should provide the
-- following fields:
-- {
--   type = <string>
-- }
--
-- `type` should be the name of a valid Intent type. See below for the
-- different Intent types.
--
-- `proto` is consumed, and should not be reused or modified.
function Intent.new(proto)
	return setmetatable(proto, IntentType[proto.type].mt)
end

-- Return the type of this Intent as a string.
function Intent:getType()
	return self.type
end

-- A Move Intent tries to move an Entity to a target Position as quickly as
-- possible using Move Actions. Parameters:
-- {
--   type = "Move",
--   target = <Position> or nil
-- }
IntentType.Move = setmetatable({}, Intent.mt)

IntentType.Move.mt = {__index = IntentType.Move}

-- Return the Position that this Move intent is targeting.
function IntentType.Move:getTarget()
	return self.target
end

-- Set the Position that this Move intent is targeting.
function IntentType.Move:setTarget(pos)
	self.target = pos
end

function IntentType.Move:generateAction(entity)
	local current = entity:getPosition()
	local target = self:getTarget()
	local area = entity:getArea()
	local usePathFinding = true	--enable or disable A* pathfinding
	
	if current ~= nil and target ~= nil then
		local dir = nil
		local path = nil

		if usePathFinding then
			path = Astar.path (current, target, area, false)
		end

		if path ~= nil and #path > 1 and usePathFinding then
			dir = current:getDirection(path[2])
		else
			dir = current:getDirection(target)
		end
		
		return Action.new {
			type = "Move",
			direction = dir
		}
	end
end

<<<<<<< HEAD
=======
-- An Attack intent tries to move an Entity within range of a target Entity
-- and then generate Attack actions until the target is deceased. Parameters:
-- {
--   type = "Attack",
--   target = <Entity> or nil
-- }
IntentType.Attack = setmetatable({}, Intent.mt)

IntentType.Attack.mt = {__index = IntentType.Attack}

-- Return the Entity that this Attack intent is targeting.
function IntentType.Attack:getTarget()
	return self.target
end

-- Set the Entity that this Attack intent is targeting.
function IntentType.Attack:setTarget(entity)
	self.target = entity
end

function IntentType.Attack:generateAction(entity)
	local currentArea = entity:getArea()
	local currentPos = entity:getPosition()
	local target = self:getTarget()
	local targetArea = target and target:getArea()
	local targetPos = target and target:getPosition()
	if currentArea ~= nil and currentArea == targetArea
			and currentPos ~= nil and targetPos ~= nil then
		if currentPos:getDistance(targetPos) < 1.5 then
			return Action.new {
				type = "Attack",
				target = target
			}
		else
			local moveIntent = self.moveIntent
			if moveIntent == nil then
				moveIntent = Intent.new {
					type = "Move"
				}
				self.moveIntent = moveIntent
			end
			moveIntent:setTarget(targetPos)
			return moveIntent:generateAction(entity)
		end
	end
end

-- An Interact intent tries to move an Entity within range of a target
-- Structure and then generate an Interact action. Parameters:
-- {
--   type = "Interact",
--   target = <Structure> or nil
-- }
IntentType.Interact = setmetatable({}, Intent.mt)

IntentType.Interact.mt = {__index = IntentType.Interact}

-- Return the Structure that this Interact intent is targeting.
function IntentType.Interact:getTarget()
	return self.target
end

-- Set the Structure that this Interact intent is targeting.
function IntentType.Interact:setTarget(entity)
	self.target = entity
end

function IntentType.Interact:generateAction(entity)
	local currentArea = entity:getArea()
	local currentPos = entity:getPosition()
	local target = self:getTarget()
	local targetArea = target and target:getArea()
	local targetPos = target and target:getPosition()
	if currentArea ~= nil and currentArea == targetArea
			and currentPos ~= nil and targetPos ~= nil
			and not self.done then
		if currentPos == targetPos then
			self.done = true
			return Action.new {
				type = "Interact",
				target = target
			}
		else
			local moveIntent = self.moveIntent
			if moveIntent == nil then
				moveIntent = Intent.new {
					type = "Move"
				}
				self.moveIntent = moveIntent
			end
			moveIntent:setTarget(targetPos)
			return moveIntent:generateAction(entity)
		end
	end
end
>>>>>>> refs/remotes/origin/develop

return Intent
