-- Rogue with Friends - a 2D, real-time, multiplayer roguelike
-- ---------------------------------------------------------------
-- Released under the GNU AGPLv3 or later. See README.md for info.

local json = require "json"

local len = string.len
local insert = table.insert
local remove = table.remove
local concat = table.concat
local encode = json.encode
local decode = json.decode

-- A Connection is an abstraction of a two-way message stream. It provides
-- asynchronous send and receive operations with plain Lua tables as the
-- messages. All Connections support the following operations:
--   Connection:send(msg) - [non-blocking] Queue a message for transmission
--       across this Connection, then try to send all undelivered messages. If
--       `msg` is nil, skip queueing it (just try to send old messages).
--   Connection:receive() - [non-blocking] Return the next message sent from
--       the other end of this Connection, or nil if it hasn't arrived yet.
--   Connection:isOpen() - Return true if this Connection is open, and false
--       if it is closed.
--   Connection:close() - Close both ends of this Connection. If the
--       Connection is already closed, this method does nothing.

local Connection = {}

-- [private] A Connection backed by a TCP socket.
local TcpSocketConnection = {}

TcpSocketConnection.mt = {__index = TcpSocketConnection}

-- Construct a Connection from a TCP socket. The socket must be open.
function Connection.fromTcpSocket(sock)
	sock:settimeout(0)
	return setmetatable({
		_isOpen = true,
		socket = sock,
		sendQueue = {},
		recvBuffer = {}
	}, TcpSocketConnection.mt)
end

function TcpSocketConnection:send(msg)
	if self:isOpen() then
		assert(type(msg) == "table", "sending non-table value")
		local queue = self.sendQueue
		if msg ~= nil then
			insert(queue, {encode(msg).."\n", 1})
		end
		while #queue > 0 do
			local progress = queue[1]
			local msg, i = unpack(progress)
			local j, err, k = self.socket:send(msg, i)
			if err == nil then
				if j == len(msg) then
					remove(queue, 1)
				else
					progress[2] = j + 1
					break
				end
			else
				if err == "closed" then
					self:close()
				else
					progress[2] = k + 1
				end
				break
			end
		end
	end
end

function TcpSocketConnection:receive()
	if self:isOpen() then
		local buffer = self.recvBuffer
		local a, err, b = self.socket:receive()
		if err == nil then
			insert(buffer, a)
			local str = concat(buffer)
			self.recvBuffer = {}
			local success, msg = pcall(decode, str)
			if success then
				return msg
			else
				return self:receive()
			end
		elseif err == "closed" then
			self:close()
		else
			insert(buffer, b)
		end
	end
end

function TcpSocketConnection:isOpen()
	return self._isOpen
end

function TcpSocketConnection:close()
	self._isOpen = false
	self.sendQueue = nil
	self.recvBuffer = nil
	self.socket:close()
end

-- A Connection backed by two LÖVE channels.
local LoveChannelConnection = {}

LoveChannelConnection.mt = {__index = LoveChannelConnection}

-- Construct a Connection from two LÖVE channels. `channelIn` is used for
-- receiving, and `channelOut` is used for sending. If either arguments are
-- strings, they are assumed to be the names of the channels to use.
function Connection.fromLoveChannels(channelIn, channelOut)
	if type(channelIn) == "string" then
		channelIn = love.thread.getChannel(channelIn)
	end
	if type(channelOut) == "string" then
		channelOut = love.thread.getChannel(channelOut)
	end
	return setmetatable({
		_isOpen = true,
		channelIn = channelIn,
		channelOut = channelOut
	}, LoveChannelConnection.mt)
end

function LoveChannelConnection:send(msg)
	if self:isOpen() then
		self.channelOut:push(encode(msg))
	end
end

function LoveChannelConnection:receive()
	if self:isOpen() then
		local str = self.channelIn:pop()
		if str == "(close)" then
			self:close()
		elseif str ~= nil then
			local success, msg = pcall(decode, str)
			if success then
				return msg
			else
				return self:receive()
			end
		end
	end
end

function LoveChannelConnection:isOpen()
	return self._isOpen
end

function LoveChannelConnection:close()
	self._isOpen = false
	self.channelIn = nil
	self.channelOut = nil
end

return Connection
