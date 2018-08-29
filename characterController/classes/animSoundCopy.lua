local localSound = script:WaitForChild("LocalSound");

local animSound = {};
local animSound_mt = {__index = animSound};

function animSound.new(realHum, fakeHum)
	local self = {};
	
	self.fakeHum = fakeHum;
	self.realHum = realHum;
	self.animate = realHum.Parent:WaitForChild("Animate");
	
	self.realSound = realHum.Parent:WaitForChild("Sound"):WaitForChild("LocalSound");
	self.lsound = localSound:Clone();
	self.lsound.physHuman.Value = fakeHum;
	self.lsound.Parent = realHum.Parent:WaitForChild("Sound");
	
	return setmetatable(self, animSound_mt);
end

function animSound:setEnabled(bool)
	self.realSound.Disabled = bool;
	self.lsound.Disabled = not bool;
	self.animate.Human.Value = bool and self.fakeHum or self.realHum;
end

return animSound;