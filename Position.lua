-- Rogue with Friends - a 2D, real-time, multiplayer roguelike
-- ---------------------------------------------------------------
-- Released under the GNU AGPLv3 or later. See README.md for info.

local Point = require "Point"

local concat = table.concat

-- A Position represents the location of a game object in an Area.
--
-- A Position is also a Point, and supports all Point methods.
--
-- Positions can be converted back and forth between an encoded form (number
-- or string) and decoded form (Position object) [see Position:encode,
-- Position.decode].
--
-- Positions have neighboring positions. These exist as offsets in a
-- particular direction. [see Position:getDirection, Position.getDirections,
-- Position:getNeighbor, Position:getNeighbors].

local Position = setmetatable({}, {__index = Point})

Position.mt = {__index = Position}

-- Two Positions are equal if their encodings are equal.
function Position.mt.__eq(a, b)
	return a:encode() == b:encode()
end

-- [private] Neighbor coordinate offset array.
local neighbors = {N = {0, -1}, NE = { 1, -1}, E = { 1, 0}, SE = { 1,  1},
                   S = {0,  1}, SW = {-1,  1}, W = {-1, 0}, NW = {-1, -1}}

-- [private] Array of possible directions.
local directions = {}
for dir,_ in pairs(neighbors) do
	directions[#directions+1] = dir
end

-- Returns an iterator over all possible directions.
function Position.getDirections()
	local i, n = 0, #directions
	return function ()
		i = i + 1
		return i <= n and directions[i] or nil
	end
end

-- [private] Cache the encoding for a Position.
local function reencode(pos)
	pos[3] = nil
	pos[3] = concat(pos, ",")
end

-- Construct a new Position from the given coordinates. `coords` should be an
-- array of {x, y}. `coords` is consumed by this function and should not be
-- reused or modified.
function Position.new(coords)
	setmetatable(coords, Position.mt)
	reencode(coords)
	return coords
end

-- Construct a new Position with the same coordinates as this one.
function Position:clone()
	local x, y = self:unpack()
	return setmetatable({x, y, self:encode()}, Position.mt)
end

-- Decode a Position from a value returned by Position:encode().
function Position.decode(code)
	local pos = setmetatable({nil, nil, code}, Position.mt)
	local x, y = code:match "([^,]+),([^,]+)"
	pos[1], pos[2] = tonumber(x), tonumber(y)
	return pos
end

-- Encode a Position as a number or string.
function Position:encode()
	-- Return the cached encoding.
	return self[3]
end

-- Set this Position's x component.
function Position:setX(x)
	Point.setX(self, x)
	-- Recompute the cached encoding.
	reencode(self)
end

-- Set this Position's y component.
function Position:setY(y)
	Point.setY(self, y)
	-- Recompute the cached encoding.
	reencode(self)
end

-- Set this Position's components (x, y).
function Position:pack(x, y)
	Point.pack(self, x, y)
	-- Recompute the cached encoding.
	reencode(self)
end

-- Return the nearest direction from this Position to the given one, or nil if
-- this position is closer than any of its neighbors.
function Position:getDirection(p)
	if self == p then return nil end
	local best, bestDist = nil, math.huge
	for dir,n in pairs(self:getNeighbors()) do
		local dist = self:getDistance(n) + n:getDistance(p)
		if dist < bestDist then
			best, bestDist = dir, dist
		end
	end
	return best
end

-- Return true if the given Position is a neighbor of this one, and false if
-- it is not.
function Position:isNeighbor(p)
	local dx = p:getX() - self:getX()
	local dy = p:getY() - self:getY()
	return self ~= p and dx >= -1 and dx <= 1 and dy >= -1 and dy <= 1
end

-- Calculate the Position of a single neighbor in the given direction. The
-- given direction should be in Position.getDirections().
--
-- If cache is not nil, it is assumed to be an existing point object and is
-- recycled.
function Position:getNeighbor(dir, cache)
	local x, y = self:unpack()
	local offset = neighbors[dir]
	x, y = x + offset[1], y + offset[2]
	if cache ~= nil then
		cache:pack(x, y)
		return cache
	else
		return Position.new {x, y}
	end
end

-- Generate a mapping between directions and neighboring positions. The keys
-- of the returned table are the directions in Position.getDirections(). The
-- values are the neighboring positions in the corresponding directions.
--
-- If cache is not nil, it is assumed to be a table previously returned from
-- this function. The table and its component Position objects are recycled.
function Position:getNeighbors(cache)
	if cache == nil then
		cache = {}
	end
	for dir in Position.getDirections() do
		cache[dir] = self:getNeighbor(dir, cache[dir])
	end
	return cache
end

return Position
