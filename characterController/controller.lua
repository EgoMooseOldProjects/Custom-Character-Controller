local terrain = game.Workspace.Terrain;
local camera = game.Workspace.CurrentCamera;

local TRANSPARENCY = 1;

local core = script.Parent;
local animSound = require(core.classes:WaitForChild("animSoundCopy"));
local createForces = require(core.functions:WaitForChild("createForces"));
local castCylinder = require(core.functions:WaitForChild("castCylinder"));

local input = require(core.utility:WaitForChild("input"));
local debugger = require(core.utility:WaitForChild("debugger"));

local controller = {};
local controller_mt = {__index = controller};
local controller_ref = setmetatable({}, {__mode = "k"});

-- private functions

local function castBox(cf, size, world)
	local region = Region3.new(cf.p - size/2, cf.p + size/2);
	local parts = game.Workspace:FindPartsInRegion3WithWhiteList(region, {world}, math.huge);	
	return parts;
end

local function isComplexGeometry(part)
	if (not part) then
		return false;
	end
	local notBlock = (part.ClassName == "Part" and part.Shape ~= Enum.PartType.Block);
	local isMeshUnion = (part.ClassName == "UnionOperation" or part.ClassName == "MeshPart");
	return notBlock or isMeshUnion;
end

local function setModelTransparency(model, transparency)
	for k, v in next, model:GetChildren() do
		if (v:IsA("BasePart")) then
			v.Transparency = transparency;
		end
		setModelTransparency(v, transparency);
	end
end

-- public constructor

function controller.new(character)
	local self = {};
	local private = {};
	
	--
	local lastArchivable = character.Archivable;
	character.Archivable = true;
	local physCharacter = character:Clone();
	physCharacter.Parent = nil;
	character.Archivable = lastArchivable;
	setModelTransparency(physCharacter, TRANSPARENCY);
	
	--
	self.character = character;
	self.humanoid = character:WaitForChild("Humanoid");
	self.hrp = character:WaitForChild("HumanoidRootPart");
	
	self.physCharacter = physCharacter;
	self.physHumanoid = physCharacter:WaitForChild("Humanoid");
	self.physHrp = physCharacter:WaitForChild("HumanoidRootPart");
	
	self.forces = createForces();
	self.forces.attach0.Parent = self.hrp;
	self.forces.attach1.Parent = terrain;
	self.forces.alignPosition.Parent = self.hrp;
	self.forces.alignOrientation.Parent = self.hrp;
	
	self.animSound = animSound.new(self.humanoid, self.physHumanoid);
	
	--
	self.isEnabled = false;
	self.isR15 = (self.humanoid.RigType == Enum.HumanoidRigType.R15);
	self.height = (self.isR15 and self.humanoid.HipHeight + self.hrp.Size.y/2 or 3);
	
	--
	self.world = game.Workspace.World;
	self.worldCenter = CFrame.new(5000, 0, 0);
	
	--
	private.fakeWorld = Instance.new("Model", camera);
	private.attendance = {};
	private.lastHit = nil;
	private.lastNormal = Vector3.new(0, 0, 0);
	private.lastAxis = Vector3.new(-1, 0, 0);
	private.surfaceCF = CFrame.new();
	
	-- TODO: clean this up?
	local function jumpBind(actionName, inputState, inputObject)
		if (inputState == Enum.UserInputState.Begin) then
			self.physHumanoid.Jump = true;
		end
		return Enum.ContextActionResult.Pass;
	end
	
	game:GetService("ContextActionService"):BindAction("jump", jumpBind, false, Enum.PlayerActions.CharacterJump);
	
	self.humanoid.Died:Connect(function()
		camera:ClearAllChildren();
	end)
	
	self.physHumanoid.Died:Connect(function()
		self.humanoid.Health = 0;
	end)
	
	--
	controller_ref[self] = private;
	return setmetatable(self, controller_mt);
end

function controller:setEnabled(bool)
	self.forces.attach1.CFrame = self.hrp.CFrame;
	self.forces.alignPosition.Enabled = bool;
	self.forces.alignOrientation.Enabled = bool;
	--self.physHrp.Anchored = true;
	self.physHrp.CFrame = self.worldCenter * self.hrp.CFrame;
	self.physCharacter.Parent = bool and camera or nil;
	self.humanoid.AutoRotate = not bool;
	self.humanoid.PlatformStand = bool;
	self.physHumanoid.PlatformStand = not bool;
	self.isEnabled = bool;
	if (not bool) then
		controller_ref[self].fakeWorld:ClearAllChildren();
	end
	self.animSound:setEnabled(bool);
end

function controller:setLastAxis(axis)
	controller_ref[self].lastAxis = axis;
end

function controller:getNormal()
	return controller_ref[self].lastNormal;
end

function controller:getFilter()
	return castBox(self.hrp.CFrame, Vector3.new(10, 10, 10), self.world);
end

function controller:castFeet(filter)
	if not (self.isEnabled) then
		return;
	end
	local isComplex = isComplexGeometry(controller_ref[self].lastHit);
	local hit, pos, normal, oneHit = castCylinder(self.hrp.CFrame, -self.hrp.CFrame.upVector, self.height+1, 2, filter or {self.world}, isComplex);
	return hit, pos, normal, oneHit, isComplex;
end

function controller:updateFakeWorld(filter)
	if not (self.isEnabled) then
		return;
	end
	
	local private = controller_ref[self];
	local attendance = private.attendance;
	
	for real, fake in next, attendance do
		fake.CanCollide = false;
		fake.Transparency = 1;
	end
	
	for i = 1, #filter do
		local real = filter[i];
		local fake = attendance[real];
		
		if (not fake) then
			fake = real:Clone();
			fake:ClearAllChildren();
			fake.Anchored = true;
			fake.Transparency = 1;
			fake.RotVelocity = Vector3.new(0, 0, 0);
			fake.Velocity = Vector3.new(0, 0, 0);
			fake.Parent = private.fakeWorld;
			attendance[real] = fake;
		end
		
		if (fake and private.lastHit) then
			local hitRot = (private.lastHitCF - private.lastHitCF.p);
			fake.CFrame = self.worldCenter * private.surfaceCF * hitRot * (private.lastHit.CFrame:inverse() * real.CFrame);
			
			fake.CanCollide = true;
			fake.Transparency = TRANSPARENCY;
		end
	end
	
	private.attendance = attendance;
end

function controller:updateCharacter(move)
	if not (self.isEnabled) then
		return;
	end
	
	if (self.physHrp.Position.y <= game.Workspace.FallenPartsDestroyHeight) then
		self.humanoid.Health = 0;
	end
	
	local private = controller_ref[self];
	
	if (private.lastHit) then
		local hitRot = (private.lastHitCF - private.lastHitCF.p);
		local offset = self.worldCenter * private.surfaceCF * hitRot;
		self.forces.attach1.CFrame = private.lastHit.CFrame * (offset:inverse() * self.physHrp.CFrame)
	end

	self.physHumanoid:Move(move, false);
end

function controller:setPart(hit, normal, extraRotation)
	if not (self.isEnabled) then
		return;
	end
	
	local private = controller_ref[self];
	
	private.attendance = {};

	local surfaceCF = CFrame.new();
	local hitRot = hit.CFrame - hit.CFrame.p;
	local dot = Vector3.new(0, 1, 0):Dot(normal);
	local cross = Vector3.new(0, 1, 0):Cross(normal);
	
	if (cross:Dot(cross) > 0) then
		surfaceCF = CFrame.fromAxisAngle(-cross, math.acos(dot));
		private.lastAxis = cross;
	elseif (dot < 0) then
		surfaceCF = CFrame.fromAxisAngle(-private.lastAxis, math.acos(dot));--hitRot * private.lastNotUpsideDown * CFrame.Angles(math.pi, 0, 0)
	end
	
	private.lastHit = hit;
	private.lastHitCF = hit.CFrame;
	private.lastNormal = normal;
	private.surfaceCF = surfaceCF;
	
	private.fakeWorld:ClearAllChildren();

	self.physHrp.CFrame = self.worldCenter * surfaceCF * hitRot * (hit.CFrame:inverse() * self.hrp.CFrame) * extraRotation;
end

function controller:setNormal(normal, extraRotation)
	self:setPart(terrain, normal, extraRotation);
end	
	
function controller:autoRotate(dt)
	debugger.step();
	if not (self.isEnabled) then
		return;
	end
	
	local private = controller_ref[self];
	
	local filter = self:getFilter();
	local hit, pos, normal, oneHit, isComplex = self:castFeet(filter);
	
	if (hit and (hit ~= private.lastHit or (normal:Dot(private.lastNormal) < 0.99 and hit.Name ~= "rPart") or (oneHit and not isComplex and private.lastNormal:Dot(normal) < 0.9999 and hit.Name ~= "rPart"))) then
		self:setPart(hit, normal, CFrame.new());
	end
		
	self:updateFakeWorld(filter);
	self:updateCharacter(self.humanoid.MoveDirection);
end

--

return controller;
