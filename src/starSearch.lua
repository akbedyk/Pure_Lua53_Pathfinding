local function normal(v)
	if v > 0 then return 1 elseif v < 0 then return -1 else return 0 end
end

-- Star Search algorithm
-- graph                       -- the grid graph[sizex; sizey]
-- isPassable(graph, x, y)     -- is callback function, return true, if the grath node exist and is passable (isn`t obstacle)
-- getDistance(x1, y1, x2, y2) -- distance on the graph

return function(graph, start_x, start_y, goal_x, goal_y, isPassable, getDistance)

	local grid = {
	-- grid node data:
	-- [node_x][node_y] = {parent node x, parent node y, distance to start node}
	}
	-- initializing grid:
	for i = 1,graph.sizex do	grid[i] = {} end
	grid[start_x][start_y] = {0,0,0} -- start node has no parent

	local openList = { {start_x, start_y},}
	local openLLen = #openList
	local openListNext

	local function addNewNeighbour(x, y, nx, ny)
		if isPassable(graph, nx, ny) then
			local data = grid[x][y]
			local parent_x = data[1]
			local parent_y = data[2]
			local dist_to_start = data[3]
			local dist = dist_to_start + getDistance(graph, x, y, nx, ny)

			local n = grid[nx][ny]
			if n then
				if nx ~= parent_x or ny ~= parent_y and n[3] > dist then
					grid[nx][ny] = {x, y, dist}
				end
			else --if not np.closed then
				grid[nx][ny] = {x, y, dist}
				openListNext[#openListNext + 1] = {nx, ny}
				graph[nx][ny] = 'x'
				return true
			end
		end
	end

	local function scanNeighbours(x, y)
		local dx = normal(goal_x - x)
		local dy = normal(goal_y - y)
		local rotdir = 1

		addNewNeighbour(x, y, x + dx, y + dy)

		if dx == 0 then
			if dy == 0 then
				print('scanNeighbours warning: REACHED GOAL NODE, return')
				return
			end
			for d = dy,-dy,-dy do -- for 1,-1,-1 do  |  for -1,1,1 do
				--addNewNeighbour(x, y, x + 1*rotdir, y + d)
				--addNewNeighbour(x, y, x - 1*rotdir, y + d)
			end
		elseif dy == 0 then
			for d = dx,-dx,-dx do -- for 1,-1,-1 do  |  for -1,1,1 do
				--addNewNeighbour(x, y, x + d, y + 1*rotdir)
				--addNewNeighbour(x, y, x + d, y - 1*rotdir)
			end
		else
			for d = 0,1 do
				addNewNeighbour(x, y, x + dx, y - dy*d)
				addNewNeighbour(x, y, x - dx*d, y + dy)
			end
			addNewNeighbour(x, y, x, y - dy)
			addNewNeighbour(x, y, x - dx, y)
		end
		addNewNeighbour(x, y, x - dx, y - dy)
	end

	while openLLen > 0 do
		openListNext = {}
		local open_node
		for i = 1,openLLen do
			open_node = openList[i] -- current
			scanNeighbours(open_node[1], open_node[2], openListNext)
			--if open_node[1] == goal_x and open_node[2] == goal_y then
			--	return buildPathByGrid(grid, goal_x, goal_y)
			--end
		end
		openList = openListNext
		openLLen = #openList
		graph:print()
		print('#openList', openLLen)
	end
	return grid
end