-- Rogue with Friends - a 2D, real-time, multiplayer roguelike
-- ---------------------------------------------------------------
-- Released under the GNU AGPLv3 or later. See README.md for info.

-- A Player object is used by the Server to manage a Connection and its
-- associated player-specific information, such as an assigned ID.
--
-- Construct a Player with Player.new, then access parameters with Player:get*
-- and Player:set*.
--
-- Send messages with Player:send*, receive with Player:receive, and manage
-- the underlying connection with Player:isConnected and Player:disconnect.

local Player =  {}

Player.mt = {__index = Player}

-- Construct a new Player from the given prototype. `proto` should contain the
-- following fields:
-- {
--   connection = <Connection>,
--   id = <number> or nil
-- }
function Player.new(proto)
	return setmetatable(proto, Player.mt)
end

-- Return the ID associated with this Player, if there is one.
function Player:getId()
	return self.id
end

-- Set the ID associated with this Player.
function Player:setId(id)
	self.id = id
end

-- Get the state of the underlying connection, returning true for open and
-- false for closed.
function Player:isConnected()
	return self.connection:isOpen()
end

-- Close the underlying connection.
function Player:disconnect()
	self.connection:close()
end

-- [private] Send a message (a plain Lua table) to this Player. See below for
-- more specific, public versions of this function.
local function sendMessage(player, msg)
	player.connection:send(msg)
end

-- Send an identity message.
function Player:sendIdentity(id)
	sendMessage(self, {
		type = "Identity",
		id = id
	})
end

-- Send a perception message.
function Player:sendPerception(perception)
	local tiles, entities = {}, {}
	local msg = {type = "Perception", tiles = tiles, entities = entities}
	local area = perception:getArea()
	msg.area = area and area:getId()
	for pos,tile in perception:getTiles() do
		local entity = tile:getEntity()
		tiles[pos] = {
			type = tile:getType():getName(),
			entity = entity and entity:getId()
		}
	end
	for entity in perception:getEntities() do
		local action = entity:getAction()
		entities[#entities + 1] = {
			id = entity:getId(),
			type = entity:getType():getName(),
			hitPoints = entity:getHitPoints(),
			maxHitPoints = entity:getType():getHitPoints(),
			action = action and {
				type = action:getType(),
				subtype = action:getSubtype(),
				direction = action:getDirection(),
				progress = action:getProgress()
			}
		}
	end
	msg.death = perception:isDeath() and true or nil
	sendMessage(self, msg)
end

-- Receive a message.
function Player:receive()
	return self.connection:receive()
end

return Player
