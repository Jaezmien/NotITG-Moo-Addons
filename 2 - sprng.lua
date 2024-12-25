sprng = {}

local function random(t)
	if t == 0 then return 0.5 end
	return math.mod(math.sin(t * 3229.3) * 43758.5453, 1)
end

function sprng:Create(seed)
	local instance = {}

	local index = 0
	local instance_seed = seed or math.random()

	function instance:Next(min, max)
		local value = random(instance_seed + index)
		index = index + 1

		if not min and not max then
			return value
		end

		local mi = math.ceil(min)
		local ma = math.floor(max)
		return math.floor(value * (ma - mi + 1) + mi)
	end

	return instance
end

local global = sprng:Create()

sprng.__call = function(_,min,max)
	return global:Next(min,max)
end
