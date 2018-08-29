local function createForces(self)
	local attach0 = Instance.new("Attachment");
	local attach1 = Instance.new("Attachment");
	
	local alignPosition = Instance.new("AlignPosition");
	alignPosition.Enabled = false;
	alignPosition.MaxForce = 10^6;
	alignPosition.Responsiveness = 200;
	alignPosition.Attachment0 = attach0;
	alignPosition.Attachment1 = attach1;
	
	local alignOrientation = Instance.new("AlignOrientation");
	alignOrientation.Enabled = false;
	alignOrientation.MaxTorque = 10^6;
	alignOrientation.Responsiveness = 200;
	alignOrientation.Attachment0 = attach0;
	alignOrientation.Attachment1 = attach1;

	return {
		attach0 = attach0;
		attach1 = attach1;
		alignPosition = alignPosition;
		alignOrientation = alignOrientation;
	};
end

return createForces;
