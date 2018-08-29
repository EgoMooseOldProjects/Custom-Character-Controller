local debugger = require(script.Parent.Parent.utility:WaitForChild("debugger"));
local matrix = require(script.Parent.Parent.utility:WaitForChild("matrix"));

local CAST_COUNT = 32;

local function planeLeastSquares(points, direction)
	if (#points < 3) then
		return Vector3.new(0, 1, 0);
	end
	
	local tempA = {};
	local tempB = {};
	
	for i = 1, #points do
		local p = points[i];
		table.insert(tempA, {p.x, p.z, 1});
		table.insert(tempB, {p.y});
	end

	local A = matrix(tempA);
	local b = matrix(tempB);
	
	local done, rank = (A:transpose()*A):invert()
	if (done) then
		local fit = done * A:transpose() * b;
		local a, b, c = fit[1][1], fit[2][1], fit[3][1];
		
		local m = Vector3.new(0, c, 0);
		local v1 = Vector3.new(1, a + c, 0) - m;
		local v2 = Vector3.new(0, b + c, 1) - m;
		
		local normal = v1:Cross(v2);
		if (normal:Dot(direction) < 0) then
			normal = -normal;
		end

		return normal.unit;
	end
	
	-- coplanar (very lazy solution only works b/c sunflower)
	local a, b, c = points[1], points[2], points[3];
	local normal = (a - c):Cross(b - c);
	if (normal:Dot(direction) < 0) then
		normal = -normal;
	end
	return normal.unit;
end

local function sunflower(n, alpha)
	local i, phi = 1, (math.sqrt(5) + 1) / 2;
	local b = math.ceil(alpha*math.sqrt(n));
	return function()
		if (i <= n) then
			i = i + 1;
			local r = i > (n - b) and 1 or math.sqrt(i - 0.5)/math.sqrt(n - (b + 1)/2);
			local t = 2*math.pi*i/(phi*phi);
			return r*math.cos(t), r*math.sin(t);
		end
		return;
	end
end

local function castCylinder(origin, direction, height, radius, whiteList, isComplex)	
	local ray = Ray.new(origin.p, direction*height);
	local fhit, fpos, fnormal = game.Workspace:FindPartOnRayWithWhitelist(ray, whiteList, false, true);
	local normal = fnormal;
	
	if (isComplex) then
		return fhit, fpos, fnormal;
	end
	
	local points = {};
	local hits = {};
	
	for x, z in sunflower(CAST_COUNT, 2) do
		local offset = Vector3.new(x*radius, 0, z*radius);
		local start = origin.p + origin:vectorToWorldSpace(offset);
		
		local ray = Ray.new(start, direction*height) -- + origin:vectorToWorldSpace(offset));
		local hit, pos, normal = game.Workspace:FindPartOnRayWithWhitelist(ray, whiteList, false, true);
		local dist = (pos - origin.p).magnitude;

		if (hit) then
			hits[hit] = true;
			points[#points+1] = pos;
		end

		debugger.point(pos, hit and Color3.new(0, 1, 0) or Color3.new(1, 0, 0));
	end
	
	local hitCount = 0;
	for hit, _ in next, hits do
		hitCount = hitCount + 1;
	end

	if (#points >= 3 and hitCount > 1) then
		fnormal = planeLeastSquares(points, -direction);
	end

	debugger.vector(fpos, fnormal, Color3.new(1, 1, 1));
	
	return fhit, fpos, fnormal, hitCount == 1;
end

return castCylinder;