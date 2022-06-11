math.dist1d = function(a, b)
	local x,y = (type(a) == 'table' and unpack(a) or a), (type(b) == 'table' and unpack(b) or b)
	local d = y-x; return math.sqrt(d * d)
end
math.dist2d = function(a, b)
	local x,y = (is_actor(a) and {a:GetX(), a:GetY()} or a), (is_actor(b) and {b:GetX(), b:GetY()} or b)
	local dx,dy = (y[1]-x[1]), (y[2]-x[2]); return math.sqrt(dx * dx + dy * dy)
end
math.dist = math.dist2d -- shortcut
math.dist3d = function(a, b)
	local x,y = (is_actor(a) and {a:GetX(), a:GetY(), a:GetZ()} or a), (is_actor(b) and {b:GetX(), b:GetY(), a:GetZ()} or b) 
	local dx,dy,dz = (y[1]-x[1]), (y[2]-x[2]), (y[3]-x[3]); return math.sqrt(dx * dx + dy * dy + dz * dz)
end
math.random_float = function(mn, mx) if mn==mx then return mn end if mn > mx then mn,mx=mx,mn end return math.random() * (mx - mn) + mn end