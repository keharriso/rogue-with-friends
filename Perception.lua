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
		entities = {},
		structures = {},
		death = false,
		win = false
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

-- [private] Return an iterator over all values in the given table.
local function values(t)
	local k = nil
	return function ()
		local v
		k, v = next(t, k)
		return v
	end
end

-- Return an iterator over all Entity observations.
function Perception:getEntities()
	return values(self.entities)
end

-- Observe the given Entity.
function Perception:addEntity(entity)
	self.entities[entity:getId()] = entity
end

-- Return an iterator over all Structure observations.
function Perception:getStructures()
	return values(self.structures)
end

-- Observe the given Structure.
function Perception:addStructure(structure)
	self.structures[structure:getId()] = structure
end

-- Return whether or not the subject of this Perception died.
function Perception:isDeath()
	return self.death
end

-- Set whether or not the subject of this Perception died.
function Perception:setDeath(death)
	self.death = death
end

-- Set whether or not there is a change in PowerUp visibility
function Perception:setPowerUp(powerUp)
	self.powerUp = powerUp
end

-- Return whether or not this Perception carries a win event.
function Perception:isWin()
	return self.win
end

-- Set whether or not this Perception carries a win event.
function Perception:setWin(win)
	self.win = win
end

-- Return true if this Perception has no observations, and false otherwise.
function Perception:isEmpty()
	return not self.death and not self.win and not self.powerUp
			and next(self.tiles) == nil
			and next(self.entities) == nil
			and next(self.structures) == nil
end

return Perception
