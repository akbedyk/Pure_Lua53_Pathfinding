--[[
Project: GeoScan
File: qgraph.lua

qgraph - "квадратный граф", описывающий плоскость, разбитую на сетку из элементов qelement

Функции:
add  -- добавление элемента
fill -- заполнение графа элементами
print -- распечатка графа
getClosest -- возвращает ближайшую к данной точку
buildArea -- нахождение непрерывной области из одного элемента (или значения callback = true)
buildPerimetr -- поиск периметра, возвращает заполненный значениями false периметр
getCenterMass -- расчитать центр масс значений
]]

--local QM = require('geoscan.geo.qmultitude')

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
Возвращает следующий сдвиг для [x,y] по частовой стрелке вокруг центра [cx,cy] в зависимости от разницы
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
Возвращает ближайшую к данной точку, где callback(qelement) == true.
Поиск начинается с левого нижнего угла, идет против часовой стрелки.
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

-- возвращает заполненный значениями false периметр
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
Возвращает qgraph, заполненный значениями true,
a непрерывная область из клеток, где пристутствует элемент
или где callback(qelement) == true, будет заполнена значениями false
startx, starty - клетка начала поиска
x,y,h,w - ограничивающая поиск область
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

return G