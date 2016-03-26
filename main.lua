-- Rogue with Friends - a 2D, real-time, multiplayer roguelike
-- ---------------------------------------------------------------
-- Released under the GNU AGPLv3 or later. See README.md for info.

local socket = require "socket"

local Client = require "Client"
local Connection = require "Connection"
local Rectangle = require "Rectangle"
local UI = require "UI"

-- This file is executed by the LÖVE engine upon starting the game. It
-- performs initialization and registers love.* callbacks with the engine.

local DEFAULT_PORT = 29612

local ui, client, server

function love.load(arg)
	local con
	if arg[2] == "connect" then
		local addr = arg[3] or "localhost"
		local port = tonumber(arg[4]) or DEFAULT_PORT
		local sock = assert(socket.connect(addr, port))
		sock:setoption("tcp-nodelay", true)
		con = Connection.fromTcpSocket(sock)
	else
		local port = nil
		if arg[2] == "host" then
			port = arg[3] or DEFAULT_PORT
		elseif arg[2] ~= nil then
			error("unrecognized command: `"..arg[2].."`")
		end
		server = love.thread.newThread "Server.lua"
		server:start("host", port, "server-in", "server-out")
		con = Connection.fromLoveChannels("server-out", "server-in")
	end
	client = Client.new {connection = con}
	local screenWidth, screenHeight = love.graphics.getDimensions()
	ui = UI.new {
		client = client,
		bounds = Rectangle.new {0, 0, screenWidth, screenHeight},
		tileSize = 32
	}
end

function love.quit()
	client:disconnect()
end

function love.update(dt)
	client:update()
	ui:update(dt)
end

function love.draw()
	ui:draw()
end

function love.threaderror(thread, err)
	error(err)
end

function love.mousepressed(x, y, button)
	ui:mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
	ui:mousereleased(x, y, button)
end
