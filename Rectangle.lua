-- Rogue with Friends - a 2D, real-time, multiplayer roguelike
-- ---------------------------------------------------------------
-- Released under the GNU AGPLv3 or later. See README.md for info.

local Point = require "Point"

-- A Rectangle is the pairing of a 2D position (x, y), representing the
-- position of the shape, with lengths for both sides (width, height).
--
-- Rectangle supports all Point operations, which act on the position of the
-- rectangle, except that Rectangle:pack and Rectangle:unpack are overriden to
-- support access of all 4 components (x, y, width, height).

local Rectangle = setmetatable({}, {__index = Point})

Rectangle.mt = {__index = Rectangle}

-- Construct a new Rectangle with the given bounds. `bounds` should be an
-- array of {x, y, width, height}. `bounds` is consumed and should not be
-- reused or modified.
function Rectangle.new(bounds)
	return setmetatable(bounds, Rectangle.mt)
end

-- Construct a new Rectangle with the same bounds as this one.
function Rectangle:clone()
	return Rectangle.new {self:unpack()}
end

-- Return the position (x, y) of this Rectangle.
function Rectangle:getPosition()
	return Point.unpack(self)
end

-- Set the position (x, y) of this Rectangle.
function Rectangle:setPosition(x, y)
	Point.pack(self, x, y)
end

-- Return the width of this Rectangle.
function Rectangle:getWidth()
	return self[3]
end

-- Set the width of this Rectangle.
function Rectangle:setWidth(width)
	self[3] = width
end

-- Return the height of this Rectangle.
function Rectangle:getHeight()
	return self[4]
end

-- Set the height of this Rectangle.
function Rectangle:setHeight(height)
	self[4] = height
end

-- Return the size (width, height) of this Rectangle.
function Rectangle:getSize()
	return self[3], self[4]
end

-- Set the size (width, height) of this Rectangle.
function Rectangle:setSize(width, height)
	self[3], self[4] = width, height
end

-- Return all 4 components (x, y, width, height) of this Rectangle.
function Rectangle:unpack()
	return self[1], self[2], self[3], self[4]
end

-- Set all 4 components (x, y, width, height) of this Rectangle.
function Rectangle:pack(x, y, width, height)
	self[1], self[2], self[3], self[4] = x, y, width, height
end

return Rectangle
