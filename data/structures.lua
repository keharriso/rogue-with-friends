-- Rogue with Friends - a 2D, real-time, multiplayer roguelike
-- ---------------------------------------------------------------
-- Released under the GNU AGPLv3 or later. See README.md for info.

-- A Portal structure moves an Entity across Areas. Parameters:
-- {
--   targetArea = <Area>,
--   targetPosition = <Position>
-- }
local function Portal_interact(self, entity)
	local world = entity:getWorld()
	local area, pos = self.targetArea, self.targetPosition
	local tile = area and pos and area:getTile(pos)
	if (tile == nil or tile:isOccupied())
			and pos ~= nil and area ~= nil then
		-- Can't move to target tile, so try neighbors.
		local neighbors = pos:getNeighbors()
		for dir,n in pairs(neighbors) do
			local ntile = area:getTile(n)
			if entity:getMovement(ntile) ~= nil then
				pos, tile = n, ntile
				break
			end
		end
	end
	if tile ~= nil and not tile:isOccupied() then
		world:apply {
			type = "Move",
			entity = entity,
			area = area,
			position = pos
		}
		entity:setIntent(nil)
		world:apply {
			type = "Start",
			entity = entity,
			action = nil
		}
	end
end

local function Portal(interactTime)
	return {
		interactTime = interactTime,
		interact = Portal_interact
	}
end

return {

StairsUp = Portal(1);

StairsDown = Portal(1);

MacGuffin = {
	interactTime = 0,
	interact = function (self, entity)
		entity:getWorld():apply {
			type = "Win"
		}
	end
};

Damage = {
	interactTime = 1,
	interact = function (self, entity)
		local area, pos = entity:getArea(), entity:getPosition()
		local tile = area:getTile(pos)
		local oldDamage = entity:getDamage()
		print("oldDamage", oldDamage)
		entity:setDamage(oldDamage + 1)
		print("New Damage", entity:getDamage())
		entity:getWorld():apply {
				type = "RemovePowerUp",
				entity = entity,
				structure = self
			}
	end

};

AttackSpeed = {
	interactTime = 1,
	interact = function (self, entity)
		local area, pos = entity:getArea(), entity:getPosition()
		local tile = area:getTile(pos)
		local oldAttackSpeed = entity:getAttackSpeed()
		print("Old attack speed", oldAttackSpeed)
		entity:setAttackSpeed(oldAttackSpeed + 1)
		print("New Attack Speed", entity:getAttackSpeed())
		entity:getWorld():apply {
				type = "RemovePowerUp",
				entity = entity,
				structure = self
			}
	end

};

MaxHitPoints = {
	interactTime = 1,
	interact = function (self, entity)
		local area, pos = entity:getArea(), entity:getPosition()
		local tile = area:getTile(pos)
		local oldMaxHitPoints = entity:getMaxHitPoints()
		print("Old MaxHitPoints", oldMaxHitPoints)
		entity:setMaxHitPoints(oldMaxHitPoints + 1)
		print("New Damage", entity:getMaxHitPoints())
		entity:getWorld():apply {
				type = "RemovePowerUp",
				entity = entity,
				structure = self
			}
	end

}

}
