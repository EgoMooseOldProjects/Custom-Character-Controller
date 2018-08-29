local terrain = game:GetService("Workspace").Terrain;

local deb = {enabled = false};

local usedPoints = {};
local usedVectors = {};
local unusedPoints = {};
local unusedVectors = {};

function deb.print(...)
	if (deb.enabled) then
		print(...);
	end
end

function deb.warn(...)
	if (deb.enabled) then
		warn(...);
	end
end

function deb.error(...)
	if (deb.enabled) then
		error(...);
	end
end

function deb.point(position, colour)
	if not (deb.enabled) then
		return
	end
	
	local instance = table.remove(unusedPoints);
	
	if not instance then
		instance = Instance.new("SphereHandleAdornment");
		instance.ZIndex = 1;
		instance.Name = "Debug Handle";
		instance.AlwaysOnTop = true;
		instance.Radius = 0.12;
		instance.Adornee = terrain;
		instance.Parent = terrain;
	end

	instance.CFrame = CFrame.new(position);
	instance.Color3 = colour;

	table.insert(usedPoints, instance);
end

function deb.vector(position, direction, color)
	if not (deb.enabled) then
		return;
	end

	local instance = table.remove(unusedVectors);

	if not instance then
		instance = Instance.new("BoxHandleAdornment");
		instance.Color3 = Color3.new(1, 1, 1);
		instance.AlwaysOnTop = true;
		instance.ZIndex = 2;
		instance.Transparency = 0.25;
		instance.Parent = terrain;
		instance.Adornee = terrain;
	end

	instance.Size = Vector3.new(0.1, 0.1, direction.magnitude);
	instance.CFrame = CFrame.new(position + direction/2, position + direction);
	instance.Color3 = color;

	table.insert(usedVectors, instance);
end

function deb.step()
	while #unusedPoints > 0 do
		table.remove(unusedPoints):Destroy();
	end

	while #unusedVectors > 0 do
		table.remove(unusedVectors):Destroy();
	end

	usedPoints, unusedPoints = unusedPoints, usedPoints;
	usedVectors, unusedVectors = unusedVectors, usedVectors;
end

return deb;