-- Rogue with Friends - a 2D, real-time, multiplayer roguelike
-- ---------------------------------------------------------------
-- Released under the GNU AGPLv3 or later. See README.md for info.

local Data = require "Data"

-- An AI is an Intent generator for an Entity. AIs have a type, represented by
-- AI.Type, which determines their behavior.

local AI = {}

AI.mt = {__index = AI}

-- Construct a new AI from the given prototype. `proto` should provide the
-- following fields:
-- {
--   type = <AI.Type> or <string>
-- }
--
-- `proto` is consumed and should not be reused or modified.
function AI.new(proto)
	if type(proto.type) == "string" then
		proto.type = AI.Type:require(proto.type)
	end
	return setmetatable(proto, AI.mt)
end

-- Return the AI.Type associated with this AI.
function AI:getType()
	return self.type
end

-- Update this AI in the context of the given Entity.
function AI:update(entity, dt)
	local update = self:getType().update
	if update ~= nil then
		update(self, entity, dt)
	end
end

-- Generate an Intent from this AI.
function AI:generateIntent(entity)
	return self:getType().generateIntent(self, entity)
end

-- A Data type representing the type of an AI.
AI.Type = Data.new {
	loadAll = function (self)
		local aiTypes = love.filesystem.load "data/ai.lua"()
		for name,aiType in pairs(aiTypes) do
			aiType.name = name
			setmetatable(aiType, AI.Type.mt)
		end
		return aiTypes
	end
}

AI.Type.mt = {__index = AI.Type}

-- Return the name of this AI.Type.
function AI.Type:getName()
	return self.name
end

return AI
