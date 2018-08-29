local input = {};
input.moveVector = Vector3.new(0, 0, 0);

local movement = {forward = 0, backward = 0, right = 0, left = 0};

local function movementBind(actionName, inputState, inputObject)
	if (inputState == Enum.UserInputState.Begin) then
		movement[actionName] = 1;
	elseif (inputState == Enum.UserInputState.End) then
		movement[actionName] = 0;
	end
	input.moveVector = Vector3.new(movement.right - movement.left, 0, movement.backward - movement.forward);
	return Enum.ContextActionResult.Pass;
end
	
game:GetService("ContextActionService"):BindAction("forward", movementBind, false, Enum.PlayerActions.CharacterForward);
game:GetService("ContextActionService"):BindAction("backward", movementBind, false, Enum.PlayerActions.CharacterBackward);
game:GetService("ContextActionService"):BindAction("left", movementBind, false, Enum.PlayerActions.CharacterLeft);
game:GetService("ContextActionService"):BindAction("right", movementBind, false, Enum.PlayerActions.CharacterRight);

return input;