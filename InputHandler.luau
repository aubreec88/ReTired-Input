--!strict
--!optimize 2
--!native

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

export type CreateInputContextData = {
	inputContextName:string?,
	sink:boolean?,
	priority:number?,
	enabled:boolean?,
	parent:Instance?,
}

export type CreateInputActionData = {
	inputContext:InputContext,
	actionName:string?,
	actionType:Enum.InputActionType?,
	enabled:boolean?,
	parent:Instance?,

	onPress:(...any?)->(...any?)?,
	onRelease:(...any?)->(...any?)?,
}

export type CreateInputBindingData = {
	inputAction:InputAction,
	inputInstanceName:string?,
	keycode:Enum.KeyCode?,
	uiButton:GuiButton?,
	primaryModifier:Enum.KeyCode?,
	secondaryModifier:Enum.KeyCode?,
	parent:Instance?,
}

local selfPlayer:Player = (Players.LocalPlayer :: Player)

local Main = {}

-- Returns the inputs folder that is created inside of the players character. [[december]]
function Main.GetInputsFolder()
	local inputsFolder:Folder

	local selfCharacter:Model = (selfPlayer.Character :: Model)

	-- This is in a pcall because "FindFirstChild" likes to error out sometimes. [[december]]
	pcall(function()
		inputsFolder = (selfCharacter:FindFirstChild("Inputs") :: Folder)
	end)

	if not inputsFolder then
		inputsFolder = (Instance.new("Folder") :: Folder)
		inputsFolder.Parent = selfCharacter
		inputsFolder.Name = "Inputs"
	end

	return inputsFolder
end

--[[
	(SCROLL FOR VALUES!!)
	
	Info on what sink is: https://create.roblox.com/docs/reference/engine/classes/InputContext#Sink.
	And for priority, the priority of base roblox bindings are 2000. 
	Creates an input context inside of a folder named "Inputs" thats parented under your own character.
	
	Values = {
		inputContextName:string?
		sink:boolean?
		priority:number?
		enabled:boolean?
		parent:Instance?
	}
	
	(december)
]]
function Main.CreateInputContext(creationData:CreateInputContextData):InputContext
	local enabled = creationData.enabled
	local inputContextName = (creationData.inputContextName or HttpService:GenerateGUID(true))
	local parent = creationData.parent
	local priority = (creationData.priority or 2000)
	local sink = creationData.sink

	-- I don't know if these are actually necessary but I'd much rather play it safe. [[december]]
	if enabled == nil then
		enabled = true
	end

	if sink == nil then
		sink = false
	end

	local inputsFolder:Folder

	local InputContext = (Instance.new("InputContext") :: InputContext)
	InputContext.Name = inputContextName
	InputContext.Enabled = enabled
	InputContext.Sink = sink

	if parent then
		InputContext.Parent = parent

		return InputContext
	end

	-- Automatically handles the input folder creation/indexing [[december]]
	InputContext.Parent = Main.GetInputsFolder()

	return InputContext
end

--[[
	(SCROLL FOR VALUES!!)
	
	Info on action types: https://create.roblox.com/docs/reference/engine/enums/InputActionType.
	Should be parented under a "InputContext" instance.
	The name of action property only changes the name of the action.
	
	Values = {
		inputContext:InputContext
		actionName:string?
		actionType:Enum.InputActionType?
		enabled:boolean?
		parent:Instance?
		
		(BOOL ACTION TYPE ONLY!!)
		onPress:(...any?)->(...any?)?
		onRelease:(...any?)->(...any?)?	
	}
	
	(december)
]]
function Main.CreateInputAction(creationData:CreateInputActionData):InputAction
    repeat task.wait() until selfPlayer.Character

	local selfCharacter:Model = (selfPlayer.Character :: Model)
	
	-- Using "WaitForChild" to play it safe. [[december]]
	local selfHumanoid:Humanoid = (selfCharacter:WaitForChild("Humanoid") :: Humanoid)
	
	local actionName:string = (creationData.actionName or HttpService:GenerateGUID(true))
	local actionType:Enum.InputActionType = (creationData.actionType or Enum.InputActionType.Bool)
	local enabled:boolean? = creationData.enabled
	local inputContext:InputContext = creationData.inputContext
	local parent:Instance? = creationData.parent

	local onPress:(...any)->(...any)? = creationData.onPress
	local onRelease:(...any)->(...any)? = creationData.onRelease

	if not inputContext then
		warn("No 'InputContext' instance was given!")

		return
	end

	if enabled == nil then
		enabled = true
	end

	local InputAction:InputAction = (Instance.new("InputAction") :: InputAction)
	InputAction.Name = actionName
	InputAction.Enabled = enabled
	InputAction.Type = actionType

	if onPress then
		print("onPress is true", onPress)
		local onPressConnection:RBXScriptConnection

		onPressConnection = InputAction.Pressed:Connect(function()
			task.spawn(function()
				onPress()
			end)
		end)
		
		-- Memory leak protection. [[december]]
		selfHumanoid.Died:Once(function()
			if onPressConnection then
				onPressConnection:Disconnect()
			end
		end)
	end

	if onRelease then
		local onReleaseConnection:RBXScriptConnection

		onReleaseConnection = InputAction.Released:Connect(function()
			task.spawn(function()
				onRelease()
			end)
		end)
		
		-- Memory leak protection. [[december]]
	    selfHumanoid.Died:Once(function()
			if onReleaseConnection then
				onReleaseConnection:Disconnect()
			end
		end)
	end

	-- As stated above in the other function, I don't know if this is actually necessary but I'd much rather play it safe. [[december]]
	if parent then
		InputAction.Parent = parent

		return InputAction
	end

	InputAction.Parent = inputContext

	return InputAction
end

--[[
	(SCROLL FOR VALUES!!)
	
	Info on "InputBinding" instances: https://create.roblox.com/docs/reference/engine/classes/InputBinding.
	Should be parented under a "InputAction" instance.
	Can't have a keycode and ui button set at the same time, not my fault. It's a limitation with the instance itself.
	As always, the string you input to be set as the name of the instance only affects the name of said instance.
	
	Values = {
		inputAction:InputAction
		inputInstanceName:string?
		keycode:Enum.KeyCode?
		uiButton:GuiButton?
		primaryModifier:Enum.KeyCode?
		secondaryModifier:Enum.KeyCode?
		parent:Instance?
	}
	
	(december)
]]
function Main.CreateInputBinding(creationData:CreateInputBindingData):InputBinding
	local inputAction:InputAction = creationData.inputAction
	local inputInstanceName:string = (creationData.inputInstanceName or HttpService:GenerateGUID(true))
	local keycode:Enum.KeyCode = (creationData.keycode or Enum.KeyCode.Unknown)
	local parent:Instance? = creationData.parent
	local primaryModifier:Enum.KeyCode = (creationData.primaryModifier or Enum.KeyCode.Unknown)
	local uiButton:GuiButton? = creationData.uiButton
	local secondaryModifier:Enum.KeyCode = (creationData.secondaryModifier or Enum.KeyCode.Unknown)

	if not inputAction then
		warn("No 'InputAction' instance was given!")

		return
	end

	if not keycode then
		warn("Keycode for the 'InputBinding' instance was nil, set it to 'Enum.Keycode.Unknown' so it wouldn't error out!")
	end

	if keycode and uiButton then
		warn("You can't set both a keycode and a UI button on an 'InputBinding' instance!")
	end

	local InputBinding:InputBinding = (Instance.new("InputBinding") :: InputBinding)
	InputBinding.Name = inputInstanceName

	if parent then
		InputBinding.Parent = parent
	else
		InputBinding.Parent = inputAction
	end

	InputBinding.PrimaryModifier = primaryModifier
	InputBinding.SecondaryModifier = secondaryModifier

	if uiButton then
		InputBinding.UIButton = uiButton

		return InputBinding
	end

	InputBinding.KeyCode = keycode

	return InputBinding
end

return Main
