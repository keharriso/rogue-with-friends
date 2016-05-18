-- Rogue with Friends - a 2D, real-time, multiplayer roguelike
-- ---------------------------------------------------------------
-- Released under the GNU AGPLv3 or later. See README.md for info.

local Position = require "Position"
local Area = require "Area"

local Astar = {}

local INF = 1/0
local cachedPaths = nil

--get a cost estimate for a pair of positions
--Needs to be updated for tile movement speeds in future
local function heuristicCostEstimate(posA, posB)
	return posA:getDistance(posB)
end


--return the position in the set with the lowest f-score
local function lowestFScore(set, fScore)
	local lowest, bestPos = INF, nil
	for _, pos in pairs (set) do
		local score = fScore[pos:encode()]
		if score < lowest then
			lowest, bestPos = score, pos
		end
	end
	return bestPos
end

--return all neighbor tiles that can be walked on
local function getValidNeighbors(area, posA)
	local neighbors = {}
	local tempNeighbors = posA:getNeighbors()
	for dir, pos in pairs(tempNeighbors) do
		if area:getTile(pos) ~= nil and not area:getTile(pos):getType():isSolid() then
			table.insert(neighbors, pos)
		end
	end
	
	return neighbors
end



local function notIn(set, pos)
	for _, node in ipairs ( set ) do
		if node == pos then return false end
	end
	return true
end

--remove 'pos' from the set
local function removePos( set, pos )
	for i, node in ipairs ( set ) do
		if node == pos then 
			set [ i ] = set [ #set ]
			set [ #set ] = nil
			break
		end
	end	
end

--return a path from the current position to the target
local function unwindPath ( path, parentset, currentPos )
	if currentPos ~= nil and parentset[currentPos:encode()] then
		table.insert ( path, 1, parentset [ currentPos:encode() ] ) 
		return unwindPath ( path, parentset, parentset [ currentPos:encode() ] )
	else
		return path
	end
end

--count number of pairs in table
local function tableNum (set)
	local count = 0
	for k, v in pairs(set) do
		count = count + 1
	end
	return count
end

--compute the astar path
local function astar(start, target, area)
	
	local closedset = {}
	local openset = { start }
	local parentset = {}
	

	local gScore, fScore = {}, {}
	gScore[start:encode()] = 0
	fScore[start:encode()] = gScore[start:encode()] + heuristicCostEstimate(start, target)
	
	while #openset > 0 do


		local current = lowestFScore(openset, fScore)
		if current == target then
			local path = unwindPath({}, parentset, target)
			table.insert(path, target)
			return path
		end

		removePos(openset, current)
		table.insert(closedset, current)
		local neighbors = getValidNeighbors(area, current)
		for _, neighbor in ipairs(neighbors) do
			if notIn(closedset, neighbor) then

				local tempGScore = gScore[current:encode()] + current:getDistance(neighbor)
				
				if notIn (openset, neighbor) or tempGScore < gScore[neighbor:encode()] then
					parentset[neighbor:encode()] = current
					gScore[neighbor:encode()] = tempGScore
					fScore[neighbor:encode()] = gScore[neighbor:encode()] + heuristicCostEstimate(neighbor, target)

					if notIn (openset, neighbor) then
						table.insert(openset, neighbor)
					end
				end
			end
		end
	end
	return nil --no path found
end

function Astar.clearCachedPaths()
	cachedPaths = nil
end

--return a path from start to target for a given area
--returns nil if no valid paths exist
function Astar.path(start, target, area, ignoreCache)
	if not cachedPaths then cachedPaths = {} end
	if not cachedPaths[start] then
		cachedPaths[start] = {}
	elseif cachedPaths[start][target] and not ignoreCache then
		return cachedPaths[start][target]
	end
	return astar(start, target, area)
end

function tprint(tb)
	for k, v in pairs(tb) do
		print("[" .. k .."] -> ".. v:encode())
   	end
end

return Astar