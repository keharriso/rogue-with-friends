-- Rogue with Friends - a 2D, real-time, multiplayer roguelike
-- ---------------------------------------------------------------
-- Released under the GNU AGPLv3 or later. See README.md for info.

-- An Area associates Tiles with Positions.

local Area = {}

Area.mt = {__index = Area}

-- Construct a new Area with the given prototype. `proto` should provide the
-- following fields:
-- {
--   id = <number>,
--   tiles = <table> or nil
-- }
--
-- `id` is the unique identifier for this Area.
-- `tiles`, when not nil, is a map from encoded Positions to Tiles
--
-- `proto` is consumed and should not be reused or modified.
function Area.new(proto)
	if proto.tiles == nil then
		proto.tiles = {}
	end
	return setmetatable(proto, Area.mt)
end

-- Return the ID associated with this Area.
function Area:getId()
	return self.id
end

-- Return an iterator over all (Position, Tile) associations in this Area.
function Area:getTiles()
	return pairs(self.tiles)
end

-- Return the Tile associated with the given Position, or nil if there is no
-- such Tile.
function Area:getTile(pos)
	return self.tiles[pos:encode()]
end

-- Associates the given Tile with the given Position, replacing any existing
-- tile at that position.
function Area:setTile(pos, tile)
	self.tiles[pos:encode()] = tile
end

-- Return the World that this Area is a part of, if any.
function Area:getWorld()
	return self.world
end

-- Set the World that this Area is a part of, if any. Use World:addArea
-- instead to properly add an Area to a World.
function Area:setWorld(world)
	self.world = world
end

return Area
