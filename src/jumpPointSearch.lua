local function normal(v)
	if v > 0 then return 1 elseif v < 0 then return -1 else return 0 end
end

local function jumpV(parent, dx, dy, graph, v)
		local x = parent[1] + dx
		local y = parent[2] + dy
		if not graph[x][y] == v then return nil end
		if x == goal_x and y == goal_y then return {x, y} end
		if dx == 0 then
			if dy == 0 then
				print('jumpPointPath error: dx, dy = 0, 0, neibour x,y =', x, y)
				return
			elseif not graph[x+1][y] == v and graph[x+1][y+dy] == v then return {x, y}
			elseif not graph[x-1][y] == v and graph[x-1][y+dy] == v then return {x, y}
			end
		elseif dy == 0 then
			if not graph[x][y+1] == v and graph[x+dx][y+1] == v then return {x, y}
			elseif not graph[x][y-1] == v and graph[x+dx][y-1] == v then return {x, y}
			end
		else
			if not graph[x-dx][y] == v and graph[x-dx][y+dy] == v then return {x, y}
			elseif not graph[x][y-dy] == v and graph[x+dx][y-dy] == v then return {x, y}
			else
				local p = {x, y}
				if jump(p, dx, 0, graph, v) then return p end
				if jump(p, 0, dy, graph, v) then return p end
			end
		end
		return jump({x, y}, dx, dy, graph, v)
end

-- Jump Point Search algorithm (JPS)
-- isPassable(graph, x, y) -- is callback function, return true, if node exist and is passable
-- getDistance(x1, y1, x2, y2)
return function(graph, start_x, start_y, goal_x, goal_y, isPassable, getDistance)
--[[
	local explored = {}
	for i = 1,graph.maxx do
		local ex = {}
		for j = 1,graph.maxy do
			ex[j] = false
		end
		explored[i] = ex
	end
]]
	local grid = {
	-- grid node data:
	-- [node_x][node_y] = {parent node x, parent node y, distance to start node}
	}
	-- initializing grid:
	for i = graph.minx, graph.maxx do	grid[i] = {} end
	grid[start_x][start_y] = {start_x, start_y, 0} -- start node has no parent

	local neighboursList

	-- if node is passable and not explored, then add it to the list
	local function addNewNeighbour(nx, ny)
		if isPassable(graph, nx, ny) and not grid[nx][ny] then --explored[nx][ny] then
			neighboursList[#neighboursList + 1] = {nx, ny}
		end
	end

	local function scanNeighbours(x, y)
		local dx = normal(goal_x - x)
		local dy = normal(goal_y - y)

		addNewNeighbour(x + dx, y + dy)
		if dx == 0 then
			if dy == 0 then
				print('jumpPointPath warning: REACHED GOAL NODE, return')
				return
			end
			for d = dy,-dy,-dy do -- for 1,-1,-1 do  |  for -1,1,1 do
				addNewNeighbour(x + 1, y + d)
				addNewNeighbour(x - 1, y + d)
			end
		elseif dy == 0 then
			for d = dx,-dx,-dx do -- for 1,-1,-1 do  |  for -1,1,1 do
				addNewNeighbour(x + d, y + 1)
				addNewNeighbour(x + d, y - 1)
			end
		else
			for d = 0,1 do
				addNewNeighbour(x + dx, y - dy*d)
				addNewNeighbour(x - dx*d, y + dy)	
			end
			addNewNeighbour(x, y - dy)
			addNewNeighbour(x - dx, y)	
		end
		addNewNeighbour(x - dx, y - dy)
	end

	local function jump(parent, dx, dy)
		local x = parent[1] + dx
		local y = parent[2] + dy
		if not isPassable(graph, x, y) then return nil end
		if x == goal_x and y == goal_y then return {x, y} end
		if dx == 0 then
			if dy == 0 then
				print('jumpPointPath error: dx, dy = 0, 0, neibour x,y =', x, y)
				return
			elseif not isPassable(graph, x + 1, y) and isPassable(graph, x + 1, y + dy) then return {x, y}
			elseif not isPassable(graph, x - 1, y) and isPassable(graph, x - 1, y + dy) then return {x, y}
			end
		elseif dy == 0 then
			if not isPassable(graph, x, y + 1) and isPassable(graph, x + dx, y + 1) then return {x, y}
			elseif not isPassable(graph, x, y - 1) and isPassable(graph, x + dx, y - 1) then return {x, y}
			end
		else
			if not isPassable(graph, x - dx, y) and isPassable(graph, x - dx, y + dy) then return {x, y}
			elseif not isPassable(graph, x, y - dy) and isPassable(graph, x + dx, y - dy) then return {x, y}
			else
				local p = {x, y}
				if jump(p, dx, 0) then return p end
				if jump(p, 0, dy) then return p end
			end
		end
		return jump({x, y}, dx, dy)
	end

	local function open(list, x, y, d)
		local mcount = 0
		local len = #list
		local delm = d + getDistance(graph, x, y, goal_x, goal_y)
		if len == 0 then list[1] = {x, y, d} return mcount end
		for i = len,1,-1 do
			local e = list[i]
			local de = e[3] + getDistance(graph, e[1], e[2], goal_x, goal_y)
			if de >= delm then
				for j = len,i+1,-1 do
					list[j+1] = list[j]
					mcount = mcount + 1
				end
				list[i+1] = {x, y, d}
				return mcount
			end
		end
		for i = len,1 do
			list[i+1] = list[i]
			mcount = mcount + 1
		end
		list[1] = {x, y, d}
		return mcount
	end

	local startNode = {start_x, start_y, 0, 1}  -- {x, y, previous index in reached, graph index in reached}
	local openList = {startNode,} -- list of current opened nodes (points)
	local openListlen = #openList
	--explored[start_x][start_y] = true
	local openmcount = 0

	while openListlen > 0 do
		local open_node = openList[openListlen]
		openList[openListlen] = nil
		local onx = open_node[1]
		local ony = open_node[2]
		--print('FOR:', onx, ony)
		--graph[onx][ony] = '0'
		if onx == goal_x and ony == goal_y then
			print('GOAL IS REACHED, return')
			break
		end

		neighboursList = {}
		scanNeighbours(onx, ony)
		for i = #neighboursList,1,-1 do
			local neighbour = neighboursList[i]
			local jp = jump(open_node, normal(neighbour[1] - onx), normal(neighbour[2] - ony))
			if jp then 
				local x = jp[1]
				local y = jp[2]
				if not grid[x][y] then -- explored[x][y]
					local d = grid[onx][ony][3] + getDistance(graph, onx, ony, x, y)
					--local parent = grid[x][y]
					--if parent then
					--	if parent[1] ~= x or parent[2] ~= y and parent[3] > d then
					--		grid[x][y] = {onx, ony, d} -- change parent node
					--		graph[x][y] = 'c'
					--	end
					--else
						grid[x][y] = {onx, ony, d} -- set parent node
						openmcount = openmcount + open(openList, x, y, d)
						--explored[x][y] = true
						graph[x][y] = 'x'
					--end
				end
			end
		end
		openListlen = #openList
		print('#openList, moveInOpenList', openListlen, openmcount)
--[[
		for i = 1,openListlen do
			local p = openList[i]
			print(i..': '..p[1]..', '..p[2]..' dist = '..getDistance(graph, p[1], p[2], goal_x, goal_y))
		end
]]
		--if graph.print then graph:print() end
	end
	return grid
end