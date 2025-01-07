local QG = require('qgraph')
local PF = require('pathfinder')

local function find_path(start_node, end_node)
	local reachable = {start_node}
	local explored = {}

	while not empty(reachable) do
		-- Choose some node we know how to reach
		local node = choose_node(reachable)

		-- If we just got to the goal node, build and return the path
		if node == end_node then
			return build_path(end_node)
		end

		-- Don't repeat ourselves
		remove(reachable, node)
		add(explored, node)

		-- Where can we get from here?
		local neighbour = get_adjacent_nodes(node) - explored
		for adjacent in neighbour do
			if not has(reachable, adjacent) then
				addPrevious(adjacent, node)  -- Remember how we got there
				add(reachable, adjacent)
			end
		end
	end
	return nil -- If we get here, no path was found
end

local random = math.random

local function fillRandom(self, value, count)
	for i = 1,count do
		--local l = math.random(5)
		local x = random(self.maxx)
		local y = random(self.maxy)
		local max = max or 100
		local n = 0
		while not self:get(x,y) and n <= max do
			x = random(self.maxx)
			y = random(self.maxy)
			n = n + 1
		end
		self[x][y] = value
	end
end

print('=== Start test ===')

local SX = 32
local SY = 32
local OBSTACLES	 = 50

local qg = QG.new(SX, SY)
qg:clear(true)
fillRandom(qg, false, OBSTACLES)
--qg:print()

local pf = PF.new(qg)
local calls_count = 0
pf:setPassable(
	function(g,x,y)
		calls_count = calls_count + 1
		local gx = g[x]
		if gx then return gx[y] end
	end)

local path = pf:getPath(1, 1, SX-1, SY)
if path then
	print('Add path')
	for i = 1,#path do
		local p = path[i]
		qg[p[1] ][p[2] ] = i
	end
end
print('calls_count:', calls_count)
qg:print()

print('=== Finish test ===')