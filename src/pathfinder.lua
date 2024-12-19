local JPS = require('jumpPointSearch')
local StarS = require('starSearch')

local this = {}

local abs = math.abs
local SQRT2 = math.sqrt(2)

local function distanceStright(self, x1, y1, x2, y2)
	--print('distance x1, y1, x2, y2:', x1, x2, y1, y2)
	local dx = abs(x2 - x1)
	local dy = abs(y2 - y1)
	local d = abs(dx - dy)
	local min = dx
	if dx > dy then min = dy end
	return min * SQRT2 + d
end

local function distanceSqr(x1, y1, x2, y2)
	return (x2 - x1)*(x2 - x1) + (y2 - y1)*(y2 - y1)
end

function this:getNoObstacleXYRandom(obstacle, max)
	local x = math.random(self.sizex)
	local y = math.random(self.sizey)
	local max = max or 100
	local n = 0
	while obstacle(self[x][y]) and n <= max do
		x = math.random(self.sizex)
		y = math.random(self.sizey)
		n = n + 1
	end
	return x,y
end

function this:buildRandom()
	for i = 1,25 do
		--local l = math.random(5)
		getNoObstacleXYRandom(self, function(v) return v end)
	end
end

local function buildPathByGrid(grid, goal_x, goal_y, inversed)
	if not grid then
		print('pathfinder error: bad grid for buildPathByGrid')
		return {}
	end
	local inversedPath = {
		{goal_x, goal_y},
	}
	local i = 1
	local gx = grid[goal_x]
	if not gx then 
		print('buildPathByGrid: NO PATH or goal_x is out of bounds:', goal_x) 
		return
	end
	local p = gx[goal_y]
	if not p then 
		print('buildPathByGrid: NO PATH or goal_y is out of bounds:', goal_y) 
		return
	end
	while p[1] ~= 0 and p[2] ~= 0 and p[3] > 0 do
		print('buildPathByGrid:', p[1], p[2], p[3])
		i = i + 1
		inversedPath[i] = {p[1], p[2]}
		if not grid[p[1]] then print('bad grid[x][]', p[1], p[2])
		elseif not grid[p[1]][p[2]] then print('bad grid[x][y]', p[1], p[2])
		end
		p = grid[p[1]][p[2]]
	end
	if inversed then return inversedPath end

	local path = {}
	i = 0
	for j = #inversedPath,1,-1 do
		i = i + 1
		path[i] = inversedPath[j]
	end
	return path
end

function this.new(graph)
	if not graph or not graph.maxx then
		print('pathfinder.new error: bad graph')
		return 
	end
	local pathfind = {
		graph = graph,
		search = JPS,
		getDistance = distanceStright,
		isPassable = graph.get or function(g, x, y)
			local gx = graph[x]
			if gx then 	return gx[y] end
		end,
	}
	return setmetatable(pathfind, {__index = this})
end

function this:setDistance(fun)
	self.getDistance = fun
end

function this:setPassable(fun)
	self.isPassable = fun
end

local function isXYCorrect(g, x, y)
	if x and x >= g.minx and x <= g.maxx and
		 y and y >= g.miny and y <= g.maxy then return true
	end
end

function this:getPath(start_x, start_y, goal_x, goal_y)
	if not isXYCorrect(self.graph, start_x, start_y) or 
		 not isXYCorrect(self.graph, goal_x, goal_y) then
		print('pathfinder error: not correct start X,Y =', start_x, start_y ,'goal X,Y =', goal_x, goal_y)
		return
	end
	local obstacle_start = not self.isPassable(self.graph, start_x, start_y)
	local obstacle_goal = not self.isPassable(self.graph, goal_x, goal_y)
	if obstacle_start or obstacle_goal then
		print('STOP search warning: obstacle on start =', obstacle_start, ', obstacle on goal =', obstacle_goal)
		return
	end

	local grid = self.search(self.graph, start_x, start_y, goal_x, goal_y, self.isPassable, self.getDistance)

	return buildPathByGrid(grid, goal_x, goal_y)
end

return this