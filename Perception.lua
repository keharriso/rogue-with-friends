-- Rogue with Friends - a 2D, real-time, multiplayer roguelike
-- ---------------------------------------------------------------
-- Released under the GNU AGPLv3 or later. See README.md for info.

-- A Perception represents what an Entity observes in the presence of a number
-- of Effects. It is used by a Server to determine what to send to a Player.

local Perception = {}

Perception.mt = {__index = Perception}

-- Construct a new Perception with no observations.
function Perception.new()
	return setmetatable({
		area = nil,
		tiles = {},
		entities = {}
	}, Perception.mt)
end

-- Return the Area that this Perception is observing, or nil if there is none.
function Perception:getArea()
	return self.area
end

-- Set the Area that this Perception is observing.
function Perception:setArea(area)
	self.area = area
end

-- Return an iterator over all (encoded position, Tile) observations.
function Perception:getTiles()
	return pairs(self.tiles)
end

-- Observe the Tile at the given Position in the current observation Area.
function Perception:addTileAt(pos)
	self.tiles[pos:encode()] = self:getArea():getTile(pos)
end

-- Return an iterator over all Entity observations.
function Perception:getEntities()
	local entities = self.entities
	local id = nil
	return function ()
		id, entity = next(entities, id)
		return entity
	end
end

-- Observe the given Entity.
function Perception:addEntity(entity)
	self.entities[entity:getId()] = entity
end

-- Return true if this Perception has no observations, and false otherwise.
function Perception:isEmpty()
	return next(self.tiles) == nil and next(self.entities) == nil
end

return Perception