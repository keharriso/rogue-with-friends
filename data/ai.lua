-- Rogue with Friends - a 2D, real-time, multiplayer roguelike
-- ---------------------------------------------------------------
-- Released under the GNU AGPLv3 or later. See README.md for info.

local Intent = require "Intent"

return  {

Aggressive = {
	generateIntent = function (self, entity)
		local faction = entity:getFaction()
		local area, pos = entity:getArea(), entity:getPosition()
		local intent = entity:getIntent()
		if (intent == nil or intent:getType() ~= "Attack")
				and area ~= nil and pos ~= nil then
			for id,target in entity:getWorld():getEntities() do
				local tFaction = target:getFaction()
				local tArea = target:getArea()
				local tPos = target:getPosition()
				local enemies = tFaction == nil
						or tFaction ~= faction
				local triggerAttack = enemies
						and tArea == area
						and tPos ~= nil
						and pos:getDistance(tPos) < 10
				if triggerAttack then
					intent = Intent.new {
						type = "Attack",
						target = target
					}
				end
			end
		end
		return intent
	end
};

}
