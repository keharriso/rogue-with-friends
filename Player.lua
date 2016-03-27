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
--   entity = <Entity> or nil
-- }
function Player.new(proto)
	return setmetatable(proto, Player.mt)
end

-- Return the Entity associated with this Player if there is one.
function Player:getEntity()
	return self.entity
end

-- Set the Entity associated with this Player.
function Player:setEntity(entity)
	self.entity = entity
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
	local tiles, entities, structures = {}, {}, {}
	local msg = {type = "Perception"}
	local area = perception:getArea()
	msg.area = area and area:getId()
	for pos,tile in perception:getTiles() do
		local entity = tile:getEntity()
		local structure = tile:getStructure()
		tiles[pos] = {
			type = tile:getType():getName(),
			entity = entity and entity:getId(),
			structure = structure and structure:getId()
		}
		msg.tiles = tiles
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
		msg.entities = entities
	end
	for structure in perception:getStructures() do
		structures[#structures + 1] = {
			id = structure:getId(),
			type = structure:getType():getName()
		}
		msg.structures = structures
	end
	msg.death = perception:isDeath() and true or nil
	sendMessage(self, msg)
end

-- Receive a message.
function Player:receive()
	return self.connection:receive()
end

return Player
