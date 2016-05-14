-- Rogue with Friends - a 2D, real-time, multiplayer roguelike
-- ---------------------------------------------------------------
-- Released under the GNU AGPLv3 or later. See README.md for info.

local Position = require "Position"

-- A Client manages a local view of a remote game model. It communicates
-- with a Server through a Connection object.
--
-- Construct a new Client with Client.new.
--
-- Retrieve information about the local view with Client:get*.
--
-- Send messages to the server via Client:send*.
--
-- Handle all pending messages at once with Client:update.
--
-- Manage the underlying Connection with Client:isConnected and
-- Client:disconnect.

local Client = {}

Client.mt = {__index = Client}

-- [private] Reset the local view associated with this Client.
local function resetView(client)
	client.tiles = {}
	client.entities = {}
	client.structures = {}
end

-- Construct a new client from the given prototype. In particular, `proto`
-- should provide the following fields:
-- {
--   connection = <Connection>
-- }
--
-- `proto` is consumed and should not be reused or modified.
function Client.new(proto)
	setmetatable(proto, Client.mt)
	resetView(proto)
	return proto
end

-- Return the ID of the area that this client is currently viewing.
function Client:getAreaId()
	return self.areaId
end

-- Return the ID assigned to this client's Entity object, or nil if one hasn't
-- been assigned yet.
function Client:getIdentity()
	return self.identity
end

-- Return the entity view associated with this Client's assigned identity, or
-- nil if one hasn't been assigned yet or no such view exists.
function Client:getMe()
	return self:getIdentity() and self:getEntity(self:getIdentity())
end

-- Return the view that this Client has of the tile at the given Position in
-- the current view area (or nil if there is no such view). The returned view
-- has the following structure:
-- {
--   type = <string>,
--   entity = <number> or nil
-- }
--
-- The returned view is valid until the next call to Client:update, and it
-- should not be modified.
function Client:getTile(pos)
	return self.tiles[pos:encode()]
end

-- Return the view that this Client has of the entity with the given id (or
-- nil if there is no such view). The returned view has the following
-- structure:
-- {
--   id = <number>,
--   type = <string> or nil,
--   position = <Position> or nil,
--   action = <action-view> or nil,
--   hitPoints = <number>,
--   maxHitPoints = <number>
-- }
--
-- The <action-view>, if there is one, has the following structure:
-- {
--   type = <string>,
--   subtype = <string> or nil,
--   direction = <string> or nil,
--   progress = <number>
-- }
--
-- The returned view is valid until the next call to Client:update, and it
-- should not be modified.
function Client:getEntity(id)
	return self.entities[id]
end

-- Return the view that this Client has of the structure with the given id (or
-- nil if there is no such view). The returned view has the following
-- structure:
-- {
--   id = <number>,
--   type = <string> or nil
-- }
--
-- The returned view is valid until the next call to Client:update, and it
-- should not be modified.
function Client:getStructure(id)
	return self.structures[id]
end

-- Return whether or not the game has been won.
function Client:hasWon()
	return self.won and true or false
end

-- Get the state of the underlying connection, returning true for open and
-- false for closed.
function Client:isConnected()
	return self.connection:isOpen()
end

-- Close the underlying connection.
function Client:disconnect()
	self.connection:close()
end

-- [private] Send a message (which is a plain Lua table) to the connected
-- Server. See below for the more specific, public versions of this function.
local function sendMessage(client, msg)
	client.connection:send(msg)
end

-- [private] Send an intent to the Server. The provided intent should be a
-- plain Lua table (not an Intent object). Again, see below for the public
-- versions of this function.
local function sendIntent(client, intent)
	sendMessage(client, {type = "Intent", intent = intent})
end

-- Send an intent to move to a particular Position in the current area.
function Client:sendMoveIntent(target)
	sendIntent(self, {type = "Move", target = {target:unpack()}})
end

-- Send an intent to attack a given Entity.
function Client:sendAttackIntent(targetId)
	sendIntent(self, {type = "Attack", target = targetId})
end

-- Send an intent to interact with a given structure.
function Client:sendInteractIntent(targetId)
	sendIntent(self, {type = "Interact", target = targetId})
end

-- [private] Incoming message handling table.
local handle = {}

-- [private] Handle an incoming message.
local function handleMessage(client, msg)
	if msg.type and handle[msg.type] then
		handle[msg.type](client, msg)
	end
end

-- Handle all pending messages.
function Client:update()
	local msg = self.connection:receive()
	while msg ~= nil do
		handleMessage(self, msg)
		msg = self.connection:receive()
	end
end

-- [private] Handle an identity message.
function handle.Identity(client, msg)
	client.identity = msg.id
end

-- [private] Handle a perception message.
function handle.Perception(client, msg)
	if msg.area ~= client:getAreaId() or msg.death then
		-- We are viewing a different area than before, reset the
		-- local views.
		client.areaId = msg.area
		resetView(client)
	end

	if msg.win then
		client.won = true
	end

	-- Keep track of which entities need to change their positions.
	local clearPos = {}
	local newPos = {}

	-- Handle tile perceptions.
	if msg.tiles ~= nil then
		for pos,tile in pairs(msg.tiles) do
			local old = client.tiles[pos]
			if old ~= nil and old.entity ~= nil then
				clearPos[old.entity] = true
			end
			if tile.entity ~= nil then
				newPos[tile.entity] = Position.decode(pos)
			end
			client.tiles[pos] = tile
		end
	end

	-- Handle entity perceptions.
	if msg.entities ~= nil then
		for _,entity in ipairs(msg.entities) do
			local old = client.entities[entity.id]
			if old ~= nil then
				entity.position = old.position
			end
			client.entities[entity.id] = entity
		end
	end

	for entityId,pos in pairs(newPos) do
		local entity = client.entities[entityId]
		if entity ~= nil then
			entity.position = pos
		else
			client.entities[entityId] = {
				id = entityId,
				position = pos
			}
		end
		clearPos[entityId] = nil
	end

	for entityId,_ in pairs(clearPos) do
		client.entities[entityId].position = nil
	end

	-- Handle structure perceptions.
	if msg.structures ~= nil then
		for _,structure in ipairs(msg.structures) do
			client.structures[structure.id] = structure
		end
	end
end

return Client
