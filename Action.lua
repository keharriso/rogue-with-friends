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
--   direction = <string> or nil
-- }
--
-- `type` should be the name of a valid Action type. See below for the
-- different Action types.
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

-- A Move action moves an entity to a neighboring Position in the same Area.
-- Parameters:
-- {
--   type = "Move",
--   direction = <string>
-- }
ActionType.Move = setmetatable({}, Action.mt)

ActionType.Move.mt = {__index = ActionType.Move}

-- [private] Return the movement speed for the given Entity and Tiles.
local function Move_getSpeed(entity, tile, targetTile)
	if targetTile == nil or targetTile:getEntity() ~= nil
			or targetTile:getType():isSolid() then
		return 0
	else
		return 3
	end
end

-- [private] Cache useful information about this Action in the given context.
local function Move_cache(self, entity)
	local dir = self:getDirection()
	local area = entity:getArea()
	local pos = entity:getPosition()
	local tile = area and pos and area:getTile(pos)
	local targetPos = pos and dir and pos:getNeighbor(dir)
	local targetTile = area and targetPos and area:getTile(targetPos)
	self.area = area
	self.position = pos
	self.tile = tile
	self.targetPosition = targetPos
	self.targetTile = targetTile
	self.distance = pos and targetPos and pos:getDistance(targetPos)
	self.speed = Move_getSpeed(entity, tile, targetTile)
end

function ActionType.Move:isLegal(entity)
	Move_cache(self, entity)
	return self.speed > 0
end

function ActionType.Move:update(entity, dt)
	local world = entity:getWorld()
	if self:isLegal(entity) then
		local progress = self:getProgress()
		local tickDist = self.speed * dt
		local tickProgress = tickDist / self.distance
		local newProgress = math.min(progress + tickProgress, 1)
		local realProgress = newProgress - progress
		local tickElapsed = dt * realProgress / tickProgress
		world:apply {
			type = "Progress",
			entity = entity,
			progress = newProgress,
			direction = self:getDirection()
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

return Action
