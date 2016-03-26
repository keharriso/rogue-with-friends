-- Rogue with Friends - a 2D, real-time, multiplayer roguelike
-- ---------------------------------------------------------------
-- Released under the GNU AGPLv3 or later. See README.md for info.

local sqrt = math.sqrt

-- A Point in 2D space (x, y).
--
-- Construct Point objects either with Point.new or Point:clone.
--
-- Get and set coordinate values with Point:get*, Point:set*, Point:unpack,
-- and Point:pack.
--
-- Calculate the distance between two Points with Point:getDistance.

local Point = {}

Point.mt = {__index = Point}

-- Construct a new Point from the given coordinates. `coords` should be an
-- array of {x, y}. `coords` is consumed by this function and should not be
-- reused or modified.
function Point.new(coords)
	return setmetatable(coords, Point.mt)
end

-- Construct a new Point with the same coordinates as this one.
function Point:clone()
	return Point.new {self:unpack()}
end

-- Return the this point's x coordinate.
function Point:getX()
	return self[1]
end

-- Set this point's x coordinate.
function Point:setX(x)
	self[1] = x
end

-- Return this point's y coordinate.
function Point:getY()
	return self[2]
end

-- Set this point's y coordinate.
function Point:setY(y)
	self[2] = y
end

-- Return the individual components of this Point (x, y).
function Point:unpack()
	return self[1], self[2]
end

-- Set this Point's components (x, y).
function Point:pack(x, y)
	self[1], self[2] = x, y
end

-- Calculate the distance between two Points.
function Point:getDistance(other)
	local xA, yA = self:unpack()
	local xB, yB = other:unpack()
	return sqrt((xB - xA)^2 + (yB - yA)^2)
end

return Point
