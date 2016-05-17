-- Rogue with Friends - a 2D, real-time, multiplayer roguelike
-- ---------------------------------------------------------------
-- Released under the GNU AGPLv3 or later. See README.md for info.

local Data = require "Data"
local Position = require "Position"

-- An Effect represents an instantaneous change to the game model. It has a
-- type, represented by a string, which determines the changes that it incurs.
-- The completion of an effect causes side effects to a World object,
-- along with causing any number of additional Effects. In this way, Effects
-- can set off chain reactions. After being applied, an Effect can be
-- observed by an Entity, thus adding to a Perception.

local Effect = {}

Effect.mt = {__index = Effect}

-- [private] Effect type table.
local EffectType = {}

-- Construct a new Effect from the given prototype. `proto` should provide the
-- following fields:
-- {
--   type = <string>
-- }
--
-- `type` should be the name of a valid Effect type. See below for the
-- different Effect types.
--
-- `proto` is consumed and should not be reused or modified.
function Effect.new(proto)
	return setmetatable(proto, EffectType[proto.type].mt)
end

-- Return the type of this Effect as a string.
function Effect:getType()
	return self.type
end

-- Apply this Effect, possibly causing additional Effects as a result, and
-- accumulate all of the Effects onto the end of the given Effect.List.
function Effect:apply(effects)
	effects:add(self)
	local apply = self.applyEffect
	if apply ~= nil then
		apply(self, effects)
	end
end

-- Observe this Effect from the perspective of the given Entity, adding to the
-- given Perception.
function Effect:observe(entity, perception)
	local observe = self.observeEffect
	if observe ~= nil then
		observe(self, entity, perception)
	end
end

-- [private] Observe an Entity at a particular Area and Position.
local function observeEntity(effect, entity, perception)
	local area = entity:getArea()
	if area ~= nil and area == effect.area and effect.position ~= nil then
		perception:addEntity(effect.entity)
	end
end

-- A Start Effect starts an Action and assigns it to an Entity. Parameters:
-- {
--   type = "Start",
--   entity = <Entity>,
--   action = <Action> or nil
-- }
--
-- If `action` is nil, then cancel the Entity's current action, if any.
EffectType.Start = setmetatable({}, Effect.mt)

EffectType.Start.mt = {__index = EffectType.Start}

function EffectType.Start:applyEffect(effects)
	local entity = self.entity
	self.area = entity:getArea()
	self.position = entity:getPosition()
	local action = self.action
	if action ~= nil then
		action:setProgress(0)
	end
	entity:setAction(action)
end

EffectType.Start.observeEffect = observeEntity

-- A Progress Effect updates the progress of an Action, and completes the
-- Action if the `progress` 1 or greater. Parameters:
-- {
--   type = "Progress",
--   entity = <Entity>,
--   progress = <number>
-- }
EffectType.Progress = setmetatable({}, Effect.mt)

EffectType.Progress.mt = {__index = EffectType.Progress}

function EffectType.Progress:applyEffect(effects)
	local entity = self.entity
	self.area = entity:getArea()
	self.position = entity:getPosition()
	local action = entity:getAction()
	if action ~= nil then
		local progress = self.progress
		if progress >= 1 - 1e-6 then
			effects:apply {
				type = "Complete",
				entity = entity
			}
		else
			action:setProgress(progress)
		end
	end
end

EffectType.Start.observeEffect = observeEntity

-- A Complete Effect completes an action, causing its effects. Parameters:
-- {
--   type = "Complete",
--   entity = <Entity>
-- }
EffectType.Complete = setmetatable({}, Effect.mt)

EffectType.Complete.mt = {__index = EffectType.Complete}

function EffectType.Complete:applyEffect(effects)
	local entity = self.entity
	self.area = entity:getArea()
	self.position = entity:getPosition()
	local action = entity:getAction()
	if action ~= nil then
		entity:setAction(nil)
		action:complete(entity)
	end
end

EffectType.Complete.observeEffect = observeEntity

-- A Move effect updates the position and area of an entity. Parameters:
-- {
--   type = "Move",
--   entity = <Entity>,
--   area = <Area> or nil,
--   position = <Position> or nil
-- }
EffectType.Move = setmetatable({}, Effect.mt)

EffectType.Move.mt = {__index = EffectType.Move}

function EffectType.Move:applyEffect(effects)
	local entity = self.entity
	local oldArea = entity:getArea()
	local oldPos = entity:getPosition()
	-- Save the old location so the move can be observed later.
	self.oldArea, self.oldPosition = oldArea, oldPos
	local newArea, newPos = self.area, self.position
	local areaChanged = newArea ~= oldArea
	local posChanged = newPos ~= oldPos
	if (areaChanged or posChanged) then
		if oldArea ~= nil and oldPos ~= nil then
			-- Remove the entity from the old tile.
			local oldTile = oldArea:getTile(oldPos)
			if oldTile ~= nil then
				oldTile:setEntity(nil)
			end
		end
		if newArea ~= nil and newPos ~= nil then
			-- Add the entity to the new tile.
			local newTile = newArea:getTile(newPos)
			if newTile ~= nil then
				newTile:setEntity(entity)
			end
		end
		-- Update the entity's fields.
		entity:setArea(newArea)
		entity:setPosition(newPos)
	end
end

function EffectType.Move:observeEffect(entity, perception)
	local oldArea, newArea = self.oldArea, self.area
	local oldPos, newPos = self.oldPosition, self.position
	local areaChanged = oldArea ~= newArea
	local area = entity:getArea()

	-- If you're in the same area, you see it.
	if area ~= nil then
		if area == oldArea and oldPos ~= nil then
			perception:addTileAt(oldPos)
		end
		if area == newArea and newPos ~= nil then
			perception:addTileAt(newPos)
			if areaChanged then
				perception:addEntity(self.entity)
			end
		end
	end

	-- In the special case that an entity is observing its own
	-- area transition, produce a more complete perception.
	if entity == self.entity and area == newArea
			and newArea ~= oldArea and newArea ~= nil then
		for pos,tile in newArea:getTiles() do
			perception:addTileAt(Position.decode(pos))
			local tileEntity = tile:getEntity()
			if tileEntity ~= nil then
				perception:addEntity(tileEntity)
			end
			local tileStructure = tile:getStructure()
			if tileStructure ~= nil then
				perception:addStructure(tileStructure)
			end
		end
	end
end

-- A Damage Effect incurs damage to an Entity, causing a Kill effect if hit
-- points drop to 0. Parameters:
-- {
--   type = "Damage",
--   entity = <Entity>,
--   damage = <number>
-- }
EffectType.Damage = setmetatable({}, Effect.mt)

EffectType.Damage.mt = {__index = EffectType.Damage}

function EffectType.Damage:applyEffect(effects)
	local entity = self.entity
	self.area = entity:getArea()
	self.position = entity:getPosition()
	local hitPoints = entity:getHitPoints() - self.damage
	if hitPoints < 1e-6 then
		effects:apply {
			type = "Kill",
			entity = entity
		}
	else
		entity:setHitPoints(hitPoints)
	end
end

EffectType.Damage.observeEffect = observeEntity

-- A Kill Effect handles Entity death. Parameters:
-- {
--   type = "Kill",
--   entity = <Entity>
-- }
EffectType.Kill = setmetatable({}, Effect.mt)

EffectType.Kill.mt = {__index = EffectType.Kill}

function EffectType.Kill:applyEffect(effects)
	local entity = self.entity
	self.area = entity:getArea()
	self.position = entity:getPosition()
	entity:setHitPoints(0)
	-- Remove the entity from from the area.
	local world = entity:getWorld()
	effects:apply {
		type = "Move",
		entity = entity,
		area = nil
	}
	if world ~= nil then
		world:removeEntity(entity)
	end
end

function EffectType.Kill:observeEffect(entity, perception)
	observeEntity(self, entity, perception)
	if entity == self.entity then
		perception:setDeath(true)
	end
end

-- A Win Effect wins the game. Parameters:
-- {
--   type = "Win"
-- }
EffectType.Win = setmetatable({}, Effect.mt)

EffectType.Win.mt = {__index = EffectType.Win}

function EffectType.Win:observeEffect(entity, perception)
	perception:setWin(true)
end

-- A RemovePowerUp Effect handles Structure removal. Parameters:
-- {
--   type = "RemovePowerUp",
--   entity = <Entity>,
--   structure = <Structure>
-- }
EffectType.RemovePowerUp = setmetatable({}, Effect.mt)

EffectType.RemovePowerUp.mt = {__index = EffectType.RemovePowerUp}

function EffectType.RemovePowerUp:applyEffect(effects)
	print("HERE")
	local structure = self.structure
	self.area = structure:getArea()
	self.position = structure:getPosition()
	-- Remove the structure from from the area.
	local world = structure:getWorld()
	if world ~= nil then
		world:removeStructure(structure)
		local tile = self.area:getTile(self.position)
		if tile ~= nil then
			tile:setStructure(nil)
		end
	end
end

function EffectType.RemovePowerUp:observeEffect(entity, perception)
	perception:setPowerUp(true)
end


-- A List of Effects. Provides the Effect.List:add and Effect.List:apply
-- methods for easy addition and application.
Effect.List = {}

Effect.List.mt = {__index = Effect.List}

-- Construct a new Effect.List from the given array of effects. If any objects
-- in the array aren't Effect objects, they are converted to Effect objects
-- via Effect.new.
function Effect.List.new(array)
	for i=1,#array do
		local effect = array[i]
		if getmetatable(effect) ~= Effect.mt then
			array[i] = Effect.new(effect)
		end
	end
	return setmetatable(array, Effect.List.mt)
end

-- Add the given effect to the end of this Effect.List. If the given effect is
-- not an Effect object, then it is converted to one via Effect.new.
function Effect.List:add(effect)
	if getmetatable(effect) ~= Effect.mt then
		effect = Effect.new(effect)
	end
	self[#self + 1] = effect
end

-- Apply the given effect, accumulating the resulting sequence of Effect
-- objects onto the end of this Effect.List. If the given effect is not an
-- Effect object, then it is converted to one via Effect.new.
function Effect.List:apply(effect)
	if getmetatable(effect) ~= Effect.mt then
		effect = Effect.new(effect)
	end
	effect:apply(self)
end

return Effect
