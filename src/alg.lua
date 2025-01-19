



local function simplN(n)
	local simpl = {}
	local num = {}
	for i = 1,n do
		num[i] = i
	end

	for i = 2,n do
		local c = num[i]
		if c then
			for k = c*c, n do
				if num[k] and num[k] % c == 0 then num[k] = nil end
			end
		end
	end

	local si = 0
	for i = 1,n do
		if num[i] then 
			si = si + 1
			simpl[si] = num[i]
			print(num[i])
		end
	end	
	return simpl
end


local floor = math.floor

local function gcd(a, b)
	if a >= b then a,b = b,a end
	local t
	while a ~= 0 do
		t = a
		a = b % t
		b = t
	end
	return b
end


print('Simpl 10:\n')
simplN(1000000)




--[[
local s2 = 2*i*i + 2*i + 1
local sa = n*n - 2*(n*(i + 1) + i*i) + 1 = i*i + i*2*n + (n*n + 2*n + 1)
]]--

local ev = 2*n + 1
local s = s + 2*ev + 1 = s + 2*n + 2

local function sqrSum(n)
	local s = 1
	local ev = 1
	for i = 2,n do
		s = s + ev + ev + 1
		ev = ev + 2
	end
	return s
end

n  s   ev
0  1   1
1  4   3
2  9   5
3  16  7
4  25  9
5  36  11
6  49  13
7  64  15
8  81  17
9  100 19
10 121 21









