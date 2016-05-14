-- Rogue with Friends - a 2D, real-time, multiplayer roguelike
-- ---------------------------------------------------------------
-- Released under the GNU AGPLv3 or later. See README.md for info.

require "love.timer"

local socket = require "socket"

local AI = require "AI"
local Connection = require "Connection"
local Effect = require "Effect"
local Intent = require "Intent"
local Perception = require "Perception"
local Player = require "Player"
local Position = require "Position"

-- A Server is responsible for providing a central simulation of the game
-- world. It interacts with players, both local and remote, by sending and
-- receiving messages.
--
-- This script can be run with the following arguments:
--   Server.lua host [<port>] [<channel-in>] [<channel-out>]
--
-- <port> specifies the port to accept connections on. If <port> is negative,
-- then don't bind to any port. If <channel-in> and <channel-out> are
-- specified, they are taken to be the names of LÖVE channels, and are used to
-- construct a Connection, which is in turn added as a Player.

local Server = {}

Server.mt = {__index = Server}

-- Construct a new empty Server.
function Server.new()
	return setmetatable({
		alive = true,
		frequency = 10,
		players = {}
	}, Server.mt)
end

-- Return the World associated with this Server, if there is one.
function Server:getWorld()
	return self.world
end

-- Set the World associated with this Server.
function Server:setWorld(world)
	self.world = world
end

-- Return the frequency of updates to use for Server:run.
function Server:getFrequency()
	return self.frequency
end

-- Set the frequency of updates to use for Server:run.
function Server:setFrequency(freq)
	self.frequency = freq
end

-- Return the port that this Server accepts connections on, or nil if the
-- Server isn't bound to any port.
function Server:getPort()
	return self.port
end

-- Start accepting connections on the given port. If the Server is already
-- bound, this method throws an error. If the bind succeeds, it returns true,
-- otherwise it returns nil followed by an error message.
function Server:bind(port)
	assert(self.socket == nil, "binding an already bound server")
	local sock, err = socket.bind("*", port)
	if sock ~= nil then
		sock:settimeout(0)
		self.port = port
		self.socket = sock
		return true
	else
		return nil, err
	end
end

-- Return an iterator over all Players on this Server.
function Server:getPlayers()
	local i, n = 0, #self.players
	return function ()
		i = i + 1
		return i <= n and self.players[i] or nil
	end
end

-- [private] Assign a player to an entity.
local function assignEntity(world, player)
	local entity = world:newEntity {
		type = "Human",
		faction = "Players"
	}
	player:setEntity(entity)
	player:sendIdentity(entity:getId())
	-- Place the entity on some free tile.
	local area = world:getArea(1)
	for pos,tile in area:getTiles() do
		if entity:getMovement(tile) ~= nil then
			world:apply {
				type = "Move",
				entity = entity,
				area = area,
				position = Position.decode(pos)
			}
			break
		end
	end
end

-- Add a Player to this Server.
function Server:addPlayer(player)
	self.players[#self.players + 1] = player
	local world = self:getWorld()
	if world ~= nil then
		assignEntity(world, player)
	end
end

-- [private] Remove the Player at the given index.
local function removePlayerAt(server, i)
	local player = table.remove(server.players, i)
	if player ~= nil then
		player:disconnect()
	end
end

-- Remove a Player from this Server, returning true if the given player was
-- found and removed, and false otherwise.
function Server:removePlayer(player)
	for i=#self.players,1,-1 do
		if self.players[i] == player then
			removePlayerAt(self, i)
			return true
		end
	end
	return false
end

-- [private] Incoming message handling table.
local handle = {}

-- [private] Handle an incoming message.
local function handleMessage(server, player, msg)
	if msg.type and handle[msg.type] then
		handle[msg.type](server, player, msg)
	end
end

-- Perform one tick of updates to this Server, advancing the world state by
-- `dt` seconds. This includes handling Player input, updating the World, and
-- sending feedback.
function Server:update(dt)
	-- Handle new connections.
	if self.socket ~= nil then
		local sock = self.socket:accept()
		if sock then
			sock:setoption("tcp-nodelay", true)
			local con = Connection.fromTcpSocket(sock)
			self:addPlayer(Player.new {connection = con})
		end
	end
	-- Update the game world.
	local world = self:getWorld()
	local effects = world:update(dt)
	-- Handle players (backwards, so we can remove properly).
	local players = self.players
	local needsEntity = {}
	for i=#players,1,-1 do
		local player = players[i]
		local entity = player:getEntity()
		-- Handle player messages.
		local msg = player:receive()
		while msg ~= nil do
			handleMessage(self, player, msg)
			msg = player:receive()
		end
		-- Build and send a Perception.
		local perception = Perception.new()
		perception:setArea(entity:getArea())
		for i=1,#effects do
			effects[i]:observe(entity, perception)
		end
		if not perception:isEmpty() then
			player:sendPerception(perception)
		end
		-- Remove disconnected players.
		if not player:isConnected() then
			removePlayerAt(self, i)
			world:apply {
				type = "Kill",
				entity = entity
			}
		elseif entity ~= world:getEntity(entity:getId()) then
			needsEntity[#needsEntity + 1] = player
		end
	end
	for i=1,#needsEntity do
		assignEntity(world, needsEntity[i])
	end
end

-- Run this Server by performing updates at a fixed interval.
function Server:run()
	while true do
		local dt = 1 / self:getFrequency()
		local startTime = love.timer.getTime()
		self:update(dt)
		local elapsed = love.timer.getTime() - startTime
		if elapsed < dt then
			love.timer.sleep(dt - elapsed)
		end
	end
end

-- [private] Intent builder table.
local buildIntent = {}

-- [private] Handle an intent message.
function handle.Intent(server, player, msg)
	local entity = player:getEntity()
	if entity ~= nil then
		local msgIntent = msg.intent
		local intentType = msgIntent and msgIntent.type
		local intentBuilder = intentType and buildIntent[intentType]
		if intentBuilder ~= nil then
			local intent = intentBuilder(server, msgIntent)
			entity:setIntent(intent)
		end
	end
end

-- [private] Build a Move intent from a message.
function buildIntent.Move(server, msgIntent)
	local target = msgIntent.target
	local x = target and tonumber(target[1])
	local y = target and tonumber(target[2])
	if x ~= nil and y ~= nil then
		return Intent.new {
			type = "Move",
			target = Position.new {x, y}
		}
	end
end

-- [private] Build an Attack intent from a message.
function buildIntent.Attack(server, msgIntent)
	local targetId = tonumber(msgIntent.target)
	if targetId ~= nil then
		return Intent.new {
			type = "Attack",
			target = server:getWorld():getEntity(targetId)
		}
	end
end

-- [private] Build an Interact intent from a message.
function buildIntent.Interact(server, msgIntent)
	local targetId = tonumber(msgIntent.target)
	if targetId ~= nil then
		return Intent.new {
			type = "Interact",
			target = server:getWorld():getStructure(targetId)
		}
	end
end


local command = ...

if command == "host" then
	local Area = require "Area"
	local Data = require "Data"
	local Tile = require "Tile"
	local World = require "World"

	local _, port, channelIn, channelOut = ...

	Data.init()
	local server = Server.new()

	-- For now, simply construct a static and boring World.
	local world = World.new()
	local pos = Position.new {0, 0}
	local function newArea(width, height)
		local area = world:newArea {}
		for x=1,width do
			for y=1,height do
				pos:pack(x, y)
				local tileType = "Floor"
				if x == 1 or x == width
						or y == 1 or y == height then
					tileType = "Wall"
				end
				area:setTile(pos, Tile.new {type = tileType})
			end
		end
		return area
	end
	local function setTile(area, x, y, tileType)
		pos:pack(x, y); area:getTile(pos):setType(tileType)
	end
	local function addMonster(area, x, y)
		local monster = world:newEntity {
			type = "Monster",
			faction = "Monsters",
			ai = AI.new {type = "Aggressive"}
		}
		world:apply {
			type = "Move",
			entity = monster,
			area = area,
			position = Position.new {x, y}
		}
	end
	local function addStructure(area, x, y, structure)
		structure = area:getWorld():newStructure(structure)
		structure:setArea(area)
		structure:setPosition(Position.new {x, y})
		pos:pack(x, y); area:getTile(pos):setStructure(structure)
	end
	local area1 = newArea(12, 12)
	setTile(area1, 4, 4, "Wall")
	setTile(area1, 9, 4, "Wall")
	setTile(area1, 4, 9, "Wall")
	setTile(area1, 9, 9, "Wall")
	addMonster(area1, 6, 6)
	local area2 = newArea(8, 8)
	addMonster(area2, 4, 4)
	addStructure(area2, 6, 3, {type = "MacGuffin"})
	addStructure(area1, 7, 7, {
		type = "StairsDown",
		targetArea = area2,
		targetPosition = Position.new {5, 5}
	})
	addStructure(area2, 5, 5, {
		type = "StairsUp",
		targetArea = area1,
		targetPosition = Position.new {7, 7}
	})
	server:setWorld(world)

	-- Bind to port if specified.
	if port then
		assert(server:bind(tonumber(port)))
	end

	-- Add local player if specified.
	if channelIn ~= nil and channelOut ~= nil then
		local con = Connection.fromLoveChannels(channelIn, channelOut)
		server:addPlayer(Player.new {connection = con})
	end

	server:run()
end


return Server
