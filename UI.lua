-- Rogue with Friends - a 2D, real-time, multiplayer roguelike
-- ---------------------------------------------------------------
-- Released under the GNU AGPLv3 or later. See README.md for info.

local Data = require "Data"
local Point = require "Point"
local Position = require "Position"
local Rectangle = require "Rectangle"

-- A UI object represents the graphical interface between the player and the
-- game world. It is responsible for rendering the local view managed by a
-- Client object and uses the same Client object to translate user input into
-- messages to the Server.
--
-- Construct a new UI with UI.new, and access parameters with UI:get* and
-- UI:set*. UI:update will perform the necessary updates to the UI, while
-- UI:draw will render the local view.
--
-- To handle input, UI provides UI:<event-handler> methods, where
-- <event-handler> is one of the standard LÖVE event callbacks (mousepressed,
-- mousereleased, etc.)

local UI = {}

UI.mt = {__index = UI}

-- Construct a new UI from the given prototype. `proto` should provide the
-- following fields:
-- {
--   client = <Client>,
--   bounds = <Rectangle>,
--   tileSize = <number>
-- }
--
-- `client` is the Client to render and interact with.
-- `bounds` describes the position and size of the UI on the game screen.
-- `tileSize` is the length of one side of a tile.
--
-- `proto` is consumed and should not be reused or modified.
function UI.new(proto)
	proto.center = Point.new {0, 0}
	return setmetatable(proto, UI.mt)
end

-- Return the Rectangle that represents this UI's bounds on the game screen.
-- Modifications to the returned bounds will affect this UI.
function UI:getBounds()
	return self.bounds
end

-- Return the center Point of the viewport used by this UI, which represents
-- the center of the rectangular area of the game view that the UI renders.
-- The point's components are measured in tiles, not pixels. Modifications to
-- the returned point will affect this UI.
function UI:getCenter()
	return self.center
end

-- Return the size that tiles are rendered at by this UI.
function UI:getTileSize()
	return self.tileSize
end

-- Set the size that tiles are rendered at by this UI.
function UI:setTileSize()
	return self.tileSize
end

-- Perform UI updates.
function UI:update(dt)
	-- Center the viewport on our entity.
	local me = self.client:getMe()
	if me ~= nil and me.position ~= nil then
		self:getCenter():pack(me.position:unpack())
	end
end

-- [private] Rounds to the nearest integer.
local function round(x)
	return math.floor(x + 0.5)
end

-- [private] Convert from screen coordinates to tile coordinates.
local function screen2tile(ui, sx, sy)
	local bounds = ui:getBounds()
	local center = ui:getCenter()
	local tileSize = ui:getTileSize()
	local tx0, ty0 = center:getX() - (bounds:getWidth() / tileSize) / 2,
	                 center:getY() - (bounds:getHeight() / tileSize) / 2
	return tx0 + (sx - bounds:getX()) / tileSize,
	       ty0 + (sy - bounds:getY()) / tileSize
end

-- [private] Convert from tile coordinates to screen coordinates.
local function tile2screen(ui, tx, ty)
	local bounds = ui:getBounds()
	local center = ui:getCenter()
	local tileSize = ui:getTileSize()
	local sx0, sy0 = bounds:getX() + bounds:getWidth() / 2,
	                 bounds:getY() + bounds:getHeight() / 2
	return sx0 + (tx - center:getX()) * tileSize,
	       sy0 + (ty - center:getY()) * tileSize
end

-- [private] An image Data type.
local Image = Data.new {
	load = function (self, name)
		local path = "data/images/"..name..".png"
		return love.graphics.newImage(path)
	end
}

-- [private] Draw a health bar at the specified coordinates.
local function drawHealthBar(ui, health, sx, sy)
	love.graphics.push "all"
	local width, height = 4, round(ui:getTileSize() / 2)
	local redY, redH = -(height / 2), round((1 - health) * height)
	love.graphics.setColor(255, 0, 0)
	love.graphics.rectangle("fill", sx, sy + redY, width, redH)
	local greenY, greenH = redY + redH, height - redH
	love.graphics.setColor(0, 255, 0)
	love.graphics.rectangle("fill", sx, sy + greenY, width, greenH)
	love.graphics.pop()
end

-- [private] Draw an entity at the specified coordinates.
local function drawEntity(ui, entity, sx, sy)
	local image = Image:get(entity.type)
	local width, height = image:getWidth(), image:getHeight()
	local cx, cy = width / 2, height / 2
	love.graphics.draw(image, sx - cx, sy - cy)
	local health = entity.hitPoints / entity.maxHitPoints
	if health < 1 - 1e-6 then
		drawHealthBar(ui, health, sx + cx + 2, sy)
	end
end

-- [private] Draw a structure at the specified coordinates.
local function drawStructure(ui, structure, sx, sy)
	local image = Image:get(structure.type)
	local width, height = image:getWidth(), image:getHeight()
	local cx, cy = width / 2, height / 2
	love.graphics.draw(image, sx - cx, sy - cy)
end

-- [private] Draw a tile at the specified coordinates.
local function drawTile(ui, tile, sx, sy)
	local tileCenter = ui:getTileSize() / 2
	local image = Image:get(tile.type)
	love.graphics.draw(image, sx - tileCenter, sy - tileCenter)
	if tile.structure ~= nil then
		local structure = ui.client:getStructure(tile.structure)
		if structure ~= nil then
			drawStructure(ui, structure, sx, sy)
		end
	end
	if tile.entity ~= nil then
		local entity = ui.client:getEntity(tile.entity)
		if entity ~= nil then
			drawEntity(ui, entity, sx, sy)
		end
	end
end

-- [private] Draw a win message.
local winFontSize = 128
local winFont = love.graphics.newFont(winFontSize)
local function drawWin(ui)
	local x, y, width, height = ui:getBounds():unpack()
	y = y + (height - winFontSize) / 2
	love.graphics.push "all"
	love.graphics.setFont(winFont)
	love.graphics.setColor(255, 0, 0)
	love.graphics.printf("You win!", x, y, width, "center")
	love.graphics.pop()
end

-- Render the local view to the game screen.
function UI:draw()
	local bounds = self:getBounds()
	local tileSize = self:getTileSize()
	local tx0, ty0 = screen2tile(self, bounds:getPosition())
	local tx1, ty1 = tx0 + bounds:getWidth() / tileSize,
	                 ty0 + bounds:getHeight() / tileSize
	tx0, ty0, tx1, ty1 = round(tx0), round(ty0), round(tx1), round(ty1)
	local pos = Position.new {0, 0}
	for ty=ty0,ty1 do
		for tx=tx0,tx1 do
			pos:pack(tx, ty)
			local tile = self.client:getTile(pos)
			if tile ~= nil then
				drawTile(self, tile, tile2screen(self, tx, ty))
			end
		end
	end
	if self.client:hasWon() then
		drawWin(self)
	end
end

-- [private] Test if a point is inside the bounds of this UI.
local function contains(ui, x, y)
	local left, top, width, height = ui:getBounds():unpack()
	local x1, y1 = x - left, y - top
	return x1 >= 0 and x1 < width and y1 >= 0 and y1 < height
end

-- [private] Handle a mouse click.
local function mouseclicked(ui, x, y, button)
	local client = ui.client
	local tx, ty = screen2tile(ui, x, y)
	local targetPos = Position.new {round(tx), round(ty)}
	local targetTile = client:getTile(targetPos)
	local targetEntity = targetTile and targetTile.entity
	local targetStructure = targetTile and targetTile.structure
	if targetEntity ~= nil and targetEntity ~= client:getIdentity() then
		client:sendAttackIntent(targetEntity)
	elseif targetStructure ~= nil then
		client:sendInteractIntent(targetStructure)
	else
		client:sendMoveIntent(targetPos)
	end
end

-- Handle a mouse press.
function UI:mousepressed(x, y, button)
	if contains(self, x, y) then
		local time = love.timer.getTime()
		self.mousePress = {x = x, y = y, button = button, time = time}
	end
end

-- Handle a mouse release.
function UI:mousereleased(x, y, button)
	if self.mousePress ~= nil and self.mousePress.button == button then
		if contains(self, x, y) then
			mouseclicked(self, x, y, button)
		end
		self.mousePress = nil
	end
end

return UI
