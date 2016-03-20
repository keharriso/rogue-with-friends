-- Rogue with Friends - a 2D, real-time, multiplayer roguelike
-- ---------------------------------------------------------------
-- Released under the GNU AGPLv3 or later. See README.md for info.

local Action = require "Action"

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
	if current ~= nil and target ~= nil then
		local dir = current:getDirection(target)
		return Action.new {
			type = "Move",
			direction = dir
		}
	end
end

return Intent
