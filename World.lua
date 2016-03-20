-- Rogue with Friends - a 2D, real-time, multiplayer roguelike
-- ---------------------------------------------------------------
-- Released under the GNU AGPLv3 or later. See README.md for info.

local Area = require "Area"
local Effect = require "Effect"
local Entity = require "Entity"

-- World is the top-level game model class. It consists of a collection of
-- interconnected Area objects and keeps track of the mapping between IDs and
-- game objects.
--
-- Construct an empty World with World.new, then access and manage game
-- objects with World:get*, World:add*, and World:remove*.
--
-- The World:new* functions provide convenience constructors for creating game
-- objects with unique IDs.
--
-- World:apply and World:update handle Effects and game logic.

local World = {}

World.mt = {__index = World}

-- Construct an empty World object with no areas.
function World.new()
	return setmetatable({
		areas = {},
		entities = {},
		nextIds = {},
		effects = Effect.List.new {}
	}, World.mt)
end

-- Apply an effect to this World, adding to the Effect.List for the current
-- game tick. `effect` can either be an Effect object or a prototype suitable
-- for application via Effect.List:apply.
function World:apply(effect)
	self.effects:apply(effect)
end

-- Perform one tick worth of updates to this World, advancing the state by
-- `dt` seconds and returning the complete Effect sequence as an Effect.List.
-- The returned list includes any effects applied via World:apply, as well as
-- the new ones caused by the update.
function World:update(dt)
	local effects = self.effects
	for _,entity in self:getEntities() do
		entity:update(dt)
	end
	self.effects = Effect.List.new {}
	return effects
end

-- [private] Return the next unique ID available for the given object set.
function World:nextId(objSet)
	local id = self.nextIds[objSet] or 1
	while objSet[id] ~= nil do
		id = id + 1
	end
	self.nextIds[objSet] = id + 1
	return id
end

-- Return an iterator over all (ID, Area) associations in this World.
function World:getAreas()
	return pairs(self.areas)
end

-- Return the Area with the given ID, or nil if there is no such area.
function World:getArea(areaId)
	return self.areas[areaId]
end

-- Add the given Area to this World. Also adds all entities contained in the
-- area. Replaces any existing area with the same ID.
function World:addArea(area)
	local id = area:getId()
	local old = self:getArea(id)
	if old ~= nil then
		self:removeArea(old)
	end
	area:setWorld(self)
	self.areas[id] = area
	for pos,tile in area:getTiles() do
		local entity = tile:getEntity()
		if entity ~= nil then
			self:addEntity(entity)
		end
	end
end

-- Remove the given Area from this World. Also removes all entities contained
-- in the area.
function World:removeArea(area)
	local id = area:getId()
	if self:getArea(id) == area then
		area:setWorld(nil)
		self.areas[id] = nil
		for pos,tile in area:getTiles() do
			local entity = tile:getEntity()
			if entity ~= nil then
				self:removeEntity(entity)
			end
		end
	end
end

-- Construct a new Area from the given prototype and give it a unique ID. The
-- area is automatically added to this World.
function World:newArea(proto)
	proto.id = self:nextId(self.areas)
	local area = Area.new(proto)
	self:addArea(area)
	return area
end

-- Return an iterator over all (ID, Entity) associations in this World.
function World:getEntities()
	return pairs(self.entities)
end

-- Return the Entity with the given ID, or nil if there is no such entity.
function World:getEntity(entityId)
	return self.entities[entityId]
end

-- Add the given Entity to this World. Replaces any existing entity with the
-- same ID.
function World:addEntity(entity)
	local id = entity:getId()
	local old = self:getEntity(id)
	if old ~= nil then
		self:removeEntity(old)
	end
	self.entities[id] = entity
end

-- Remove the given Entity from this World.
function World:removeEntity(entity)
	local id = entity:getId()
	if self:getEntity(id) == entity then
		self.entities[id] = nil
	end
end

-- Construct a new Entity from the given prototype and give it a unique ID.
-- The entity is automatically added to this World.
function World:newEntity(proto)
	proto.id = self:nextId(self.entities)
	local entity = Entity.new(proto)
	self:addEntity(entity)
	return entity
end

return World
