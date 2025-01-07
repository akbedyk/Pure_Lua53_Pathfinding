--[[
Project: GeoScan
Autor: Mintmike
File: qgraph.lua

qgraph - "квадратный граф", описывающий плоскость, разбитую на сетку из элементов qelement

‘ункции:
add  -- добавление элемента
fill -- заполнение графа элементами
getArea -- нахождение непрерывной области из одного элемента (или значени€ callback = true)
getPerimetr -- поиск периметра
print -- распечатка графа
]]

--local QM = require('geoscan.geoclass.qmultitude')

local abs = math.abs

local function normal(v)
	if v > 0 then return 1 elseif v < 0 then return -1 else return 0 end
end

local function distanceSqr(x1, y1, x2, y2)
	return (x2 - x1)*(x2 - x1) + (y2 - y1)*(y2 - y1)
end

local function printTable(t, name)
	if name then print('Table name:', name) end
	for k,v in pairs(t) do
		print(k,v)
		if type(v) == 'table' then
			print('[', k, '] = table:')
			printTable(v)
			print('---')
		end
	end
	print('======')
end

local G = {
	class = 'qgraph',
}

function G.new(x,y)
	local g = {
		sizex = x or 1,
		sizey = y or 1,
	}
	for i = 1, g.sizex do g[i] = {} end
	return setmetatable(g, {__index = G})
end

function G:forAll(fun)
	for x = 1,self.sizex do
		for y = 1,self.sizey do
			fun(x, y, self[x][y])
		end
	end
	return true
end

function G:fill(value, size_x, size_y, start_x, start_y)
	value = value or false
	if size_x and (self.sizex < size_x) then self.sizex = size_x end
	if size_y and (self.sizey < size_y) then self.sizey = size_y end
	for x = start_x or 1, self.sizex do
		local tx = self[x]
		if not tx then
			tx = {}
			for y = start_y or 1, self.sizey do tx[y] = value end
			self[x] = tx
		else
			for y = #tx + 1,size_y do tx[y] = value end
		end
	end
end

function G:clear(value)
	value = value or false
	for x = 1, self.sizex do
		local tx = self[x]
		for y = 1, self.sizey do
			tx[y] = value
		end
	end
end

function G:get(x,y)
	local tx = self[x]
	if tx then return tx[y] end
end

function G:setCallsGetCount(value)
	self.calls_get_count = value or 0
end

function G:add(value, ix, iy)
	if (ix > self.sizex) or (iy > self.sizey) then
		self:fill(value, ix, iy)
		self[ix][iy] = value
	else
		local vx = self[ix]
		if vx then
			if vx[iy] then
				print('Agrph.add warning:', value, 'already exist', ix, iy, vx[iy])
			end
			vx[iy] = value
		else
			print('qgraph.add error: ix,iy', ix, iy, 'sizex,sizey =', self.sizex, self.sizey)
		end
	end
end

local function strN(str, n)
	for i = 1,n do
		if i < 10 then str = str .. ' ' end
		str = str .. i .. ' '
	end
	return str
end

function G:print(prefix)
	print('\n')
	print(strN('   ', self.sizex))
	for y = self.sizey,1,-1 do
		local str = tostring(y)
		if y < 10 then str = str..' :'
		else str = str..':'
		end
		for x = 1, self.sizex do
			local tx = self[x]
			if not tx then
				print('qgraph:print() size error: #v, x', #v, x)
			else
				if tx[y] then
					local s = type(tx[y]):sub(1,3)
					if s == 'boo' then str = str..' . '
					elseif s == 'num' or s == 'str' then
						s = tostring(tx[y])
						if #s == 1 then str = str .. ' ' .. s .. ' '
						elseif #s == 2 then str = str .. ' ' .. s
						else str = str .. s:sub(1,3)
						end
					elseif s == 'tab' then
						str = str .. tostring(s):sub(1,3)
					else 
						str = str .. tostring(s):sub(1,3)
					end
				else 
					str = str..'[ ]'
				end
			end
		end
		print(str)
	end
end

--[[
nextDR - вращение против часовой стрелке
nextDL - вращение по часовой стрелке
¬озвращает следующий сдвиг дл€ [x,y] по частовой стрелке вокруг центра [cx,cy] в зависимости от разницы
dx = сx - x
dy = сy - y
X -----
| . . .
| . c .
| . . .
Y
. -- одна позиций [x,y] квадрата с центром center и радиусом radius
c -- центр квадрата [cx,cy]
]]
local function nextDR(dx, dy, radius)
	if dx == radius then
		if dy < radius then return 0, -1 else return 1, 0 end
	elseif dx == -radius then
		if dy > -radius then return 0, 1 else return -1, 0 end
	else
		if dy > 0 then return 1, 0	else return -1, 0 end
	end
end

local function nextDL(dx, dy, radius)
	if dx == radius then
		if dy >- radius then return 0, 1 else return 1, 0 end
	elseif dx == -radius then
		if dy < radius then return 0, -1 else return -1, 0 end
	else
		if dy > 0 then return -1, 0	else return 1, 0 end
	end
end

--[[
¬озвращает ближайшую к данной точку, где callback(qelement) == true.
ѕоиск начинаетс€ с левого нижнего угла, идет против часовой стрелки.
]]
function G:getClosest(cx, cy, maxradius)--, callback)
	local dx, dy, x, y
	for r = 1, maxradius do
		x, y = cx, cy - r   print('getClosest x, y:', x, y)
		dx = 0
		while (x ~= cx or dx ~= 1) do
			if self[x] == nil then   			print('getClosest self[x] == nil: x =', x)
			elseif self[x][y] == nil then	print('getClosest self[x][y] == nil  x, y =', x, y)
			elseif self[x][y] == false then
				return x, y
			end
			dx, dy = nextDR(cx - x, cy - y, r)
			print('getClosest dx, dy:', dx, dy)
			x = x + dx
			y = y + dy
		end
	end
end

-- возвращает заполненный значени€ми false периметр
function G:buildPerimetr(startx, starty, callback)
	local g = G:new()
	g:fill(true, self.sizex, self.sizey)
	local emptx, empty = self:getClosest(startx, starty, self.sizex)

	local function gperimetr(x, y, cx, cy)
		print('qperimetr x,y =', x, y, 'cx,cy =', cx, cy)
		local dx, dy = nextDR(cx - x, cy - y, 1)
		local nx, ny = x + dx, y + dy

		if self[nx] and self[nx][ny] then
			if (nx == startx) and (ny == starty) then
				return
			else
				g[nx][ny] = false
				gperimetr(nx, ny, cx, cy)
			end
		else
			gperimetr(x, y, nx, ny)
		end
	end

	gperimetr(startx, starty, emptx, empty)
	return g
end

--[[
¬озвращает qgraph, заполненный значени€ми true,
a непрерывна€ область из клеток, где пристутствует элемент
или где callback(qelement) == true, будет заполнена значени€ми false
startx, starty - клетка начала поиска
x,y,h,w - ограничивающа€ поиск область
]]
function G:buildArea(startx, starty, x, y, h, w, callback)
	if not w then
		x = 1
		y = 1
		h = self.sizex
		w = self.sizey
	end
	local g = G:new()
	g:fill(true, x, y, x + h, y + w)

	local area
	if callback then
		area = function(x, y)
			g[x][y] = false
			if     g[x+1] and g[x+1][y] and callback(self[x+1][y]) then area(x+1, y)
			elseif g[x]   and g[x][y+1] and callback(self[x][y+1]) then area(x, y+1)
			elseif g[x-1] and g[x-1][y] and callback(self[x-1][y]) then area(x-1, y)
			elseif g[x]   and g[x][y-1] and callback(self[x][y-1]) then area(x, y-1)
			else return
			end
		end
	else
		area = function(x, y)
			g[x][y] = false
			if     g[x+1] and g[x+1][y] and self[x+1][y] then area(x+1, y)
			elseif g[x]   and g[x][y+1] and self[x][y+1] then area(x, y+1)
			elseif g[x-1] and g[x-1][y] and self[x-1][y] then area(x-1, y)
			elseif g[x]   and g[x][y-1] and self[x][y-1] then area(x, y-1)
			else return
			end
		end
	end
	area(startx, starty)
	return g
end

-- расчитать центр масс значений
function G:getCenterMass(cx, cy, radius, startx, starty)
	local g = self:builfPlain(startx, starty, cx - radius, cy - radius, cx + radius, cy + radius)
	
end

function G:buildRandom(N)
	for i = 1,N do
		--local l = math.random(5)
		local x = math.random(self.sizex)
		local y = math.random(self.sizey)
		local max = max or 100
		local n = 0
		while not G:get(x,y) and n <= max do
			x = math.random(self.sizex)
			y = math.random(self.sizey)
			n = n + 1
		end
		self[x][y] = false
	end
end


local function buildPathByGrid(grid, goal_x, goal_y, inversed)
	local inversedPath = {
		{goal_x, goal_y},
	}
	local i = 1
	local gx = grid[goal_x]
	if not gx then 
		print('buildPathByGrid: NO PATH or goal_x is out of bounds') 
		return
	end
	local p = gx[goal_y]
	if not p then 
		print('buildPathByGrid: NO PATH or goal_y is out of bounds') 
		return
	end
	while p[1] ~= 0 and p[2] ~= 0 and p[3] > 0 do
		i = i + 1
		inversedPath[i] = {p[1], p[2]}
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

local SQRT2 = math.sqrt(2)

function G:starPath(start_x, start_y, goal_x, goal_y, isPassable, getDistance)

	if not start_x or not start_y or not goal_x or not goal_y then
		print('starPath error: start X,Y =', start_x, start_y ,'goal X,Y =', goal_x, goal_y)
		return
	end
	if not isPassable then 
		isPassable = G.get
	end
	if not getDistance then 
		getDistance = function(x1, y1, x2, y2)
			--print('getDistance x1, y1, x2, y2:', x1, x2, y1, y2)
			local dx = abs(x2 - x1)
			local dy = abs(y2 - y1)
			local d = dy - dx
			local min = dx
			if dx > dy then 
				min = dy
				d = dx - dy
			end
			return min*SQRT2 + d
		end
	end

	local grid = {
	-- grid node data:
	-- [node_x][node_y] = {parent node x, parent node y, distance to start node}
	}
	-- initializing grid:
	for i = 1,self.sizex do	grid[i] = {} end
	grid[start_x][start_y] = {0,0,0} -- start node has no parent

	local openList = { {start_x, start_y},}
	local openLLen = #openList
	local openListNext

	local function addNewNeighbour(x, y, nx, ny)
		if isPassable(self, nx, ny) then
			local data = grid[x][y]
			local parent_x = data[1]
			local parent_y = data[2]
			local dist_to_start = data[3]
			local dist = dist_to_start + getDistance(x, y, nx, ny)

			local n = grid[nx][ny]
			if n then
				if nx ~= parent_x and ny ~= parent_y and n[3] > dist then
					grid[nx][ny] = {x, y, dist}
				end
			else --if not np.closed then
				grid[nx][ny] = {x, y, dist}
				openListNext[#openListNext + 1] = {nx, ny}
				self[nx][ny] = 'x'
				return true
			end
		end
	end

	local function scanNeighbours(x, y)
		--print('--- scanNeighbours --- x,y:', x, y)
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

		--print('Neighbour list length =', #tn)
	end

	local istop = 0

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
		self:print()
		print('#openList', openLLen)
		
		istop = istop + 1
		if istop >= 25 then break end
	end
	return --buildPathByGrid(grid, goal_x, goal_y)
end


local function printPointList(list, name)
	print(name, ':')
	for i = 1,#list do
		local point = list[i]
		local str = ''
		for j = 1,#point do
			str = str..tostring(point[j])..', '
		end
		print(i..' :', str)
	end
	print('-----')
end

local function buildPathByList(list, inversed)
	--printPointList(list, 'list of reached nodes')
	local node = list[#list]
	local inversedPath = {{node[1], node[2]},}
	while node[3] ~= 1 do -- node[3] is the previous node index in list
		node = list[node[3]]
		inversedPath[#inversedPath + 1] = {node[1], node[2]}
	end
	node = list[1] -- path start node
	inversedPath[#inversedPath + 1] = {node[1], node[2]}
	if inversed then return inversedPath end

	local path = {}
	local ip = 0
	for i = #inversedPath,1,-1 do
		ip = ip + 1
		path[ip] = inversedPath[i]
	end
	--printPointList(path, 'Path')
	return path
end

-- Jump Point Search algorithm (JPS)
-- isPassable(self, x, y) is callback function, return true, if node exist and is passable

function G:jumpPointPath(start_x, start_y, goal_x, goal_y, isPassable)
	if not start_x or not start_y or not goal_x or not goal_y then 
		print('jumpPointPath error: start X,Y =', start_x, start_y ,'goal X,Y =', goal_x, goal_y)
		return
	end
	if not isPassable then isPassable = G.get end
	local explored = {}
	for i = 1,self.sizex do
		local ex = {}
		for j = 1,self.sizey do
			ex[j] = false
		end
		explored[i] = ex
	end

	local neighboursList

	-- if node is passable and not explored, then add it to the list
	local function addNewNeighbour(x, y)
		if isPassable(self, x, y) then
			local ex = explored[x]
			if ex and not ex[y] then
				neighboursList[#neighboursList + 1] = {x, y}
			end
		end
	end

	local function scanNeighbours(x, y)
		local dx = normal(goal_x - x)
		local dy = normal(goal_y - y)
		local rotdir = -1

		addNewNeighbour(x + dx, y + dy)
		if dx == 0 then
			if dy == 0 then
				print('jumpPointPath warning: REACHED GOAL NODE, return')
				return
			end
			for d = dy,-dy,-dy do -- for 1,-1,-1 do  |  for -1,1,1 do
				addNewNeighbour(x + 1*rotdir, y + d)
				addNewNeighbour(x - 1*rotdir, y + d)
			end
		elseif dy == 0 then
			for d = dx,-dx,-dx do -- for 1,-1,-1 do  |  for -1,1,1 do
				addNewNeighbour(x + d, y + 1*rotdir)
				addNewNeighbour(x + d, y - 1*rotdir)
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
		--print('Neighbour list length =', #tn)
	end

	local function jump(neighbour_node, dx, dy)
		local nx = neighbour_node[1] + dx
		local ny = neighbour_node[2] + dy
		if not isPassable(self, nx, ny) then return nil end
		if nx == goal_x and ny == goal_y then return {nx, ny} end
		--self[nx][ny] = 'n'

		if dx == 0 then
			if dy == 0 then print('jumpPointPath error: dx,dy = 0,0 for', x, y)
			elseif not isPassable(self, nx + 1, ny) and isPassable(self, nx + 1, ny + dy) then return {nx, ny}
			elseif not isPassable(self, nx - 1, ny) and isPassable(self, nx - 1, ny + dy) then return {nx, ny}
			end
		elseif dy == 0 then
			if not isPassable(self, nx, ny + 1) and isPassable(self, nx + dx, ny + 1) then return {nx, ny}
			elseif not isPassable(self, nx, ny - 1) and isPassable(self, nx + dx, ny - 1) then return {nx, ny}
			end
		else
			if not isPassable(self, nx - dx, ny) and isPassable(self, nx - dx, ny + dy) then return {nx, ny}
			elseif not isPassable(self, nx, ny - dy) and isPassable(self, nx + dx, ny - dy) then return {nx, ny}
			else 
				local jp = jump({nx, ny}, dx, 0) or jump({nx, ny}, 0, dy)
				if jp then
					--print('jp:', jp[1], jp[2], 'np:', nx, ny) 
					return {nx, ny}, jp
				end
			end
		end
		return jump({nx, ny}, dx, dy)
	end

	local startNode = {start_x, start_y, 0, 1}  -- {x, y, previous index in reached, self index in reached}
	local openList = {startNode,} -- list of current opened nodes (points)
	local openListlen = #openList
	local openListNext
	explored[start_x][start_y] = true

	while openListlen > 0 do
		openListNext = {}
		local open_node
		for i = 1,openListlen do
			open_node = openList[i]
			local onx = open_node[1]
			local ony = open_node[2]
			--self[onx][ony] = 'x'
			if onx == goal_x and ony == goal_y then
				print('GOAL IS REACHED, return')
				openListNext = {}
				break
			end
--[[
			local cp = openList[openListlen]-- current node
			local icp = openListlen -- index of current node in openList
			local min_distance = distanceSqr(cp[1], cp[2], goal_x, goal_y) --abs(cp[1] - goalX) + abs(cp[2] - goalY)
			for i = 1,openListlen - 1 do
				cp = openList[i]
				local distance = distanceSqr(cp[1], cp[2], goal_x, goal_y) --abs(cp[1] - goalX) + abs(cp[2] - goalY)
				if distance < min_distance then
					min_distance = distance
					icp = i
				end
			end
			cp = openList[icp]
			openList[icp] = openList[openListlen]
			openList[openListlen] = nil
]]
			neighboursList = {}
			scanNeighbours(onx, ony)
			for i = #neighboursList,1,-1 do
				local neighbour_node = neighboursList[i]
				--print('neighbour:', neighbour_node[1], neighbour_node[2])
				local dx = normal(neighbour_node[1] - onx)
				local dy = normal(neighbour_node[2] - ony)
				local p1, p2 = jump(open_node, dx, dy)
				if p1 then
					local nlen = #openListNext
					openListNext[nlen + 1] = {p1[1], p1[2], open_node[4], nlen + 1}
					explored[p1[1]][p1[2]] = true
					if p2 then
						self[p1[1]][p1[2]] = '>'
						self[p2[1]][p2[2]] = 'o'
						openListNext[nlen + 2] = {p2[1], p2[2], nlen + 1, nlen + 2}
						explored[p2[1]][p2[2]] = true
					else
						self[p1[1]][p1[2]] = 'o'
					end
				end
			end
		end
		openList = openListNext
		openListlen = #openList
		self:print()
		print('#openList', openListlen)
	end
	--return buildPathByList(openList)
end

print('=== Start test ===')

local SX = 32
local SY = 32
local OBSTACLES = 50

local qg = G.new()
qg:fill(true, SX, SY)
qg:buildRandom(OBSTACLES)
--qg:print()
--local path = qg:starPath(2, 15, 15, 1)
local calls_count = 0
local path = qg:jumpPointPath(1, 1, SX, SY,
	function(g,x,y)
		calls_count = calls_count + 1
		local gx = g[x]
		if gx then return gx[y] end
	end)

if path then
	for i = 1,#path do
		local p = path[i]
		qg[p[1] ][p[2] ] = i
	end
end
print('calls_count:', calls_count)
--qg:print()

print('=== Finish test ===')

return G