--// Services \\--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

--// Modules \\--

local ClientTween = require(ReplicatedStorage.Library.ClientTween)
local SoundPlayer = require(ReplicatedStorage.Library.SoundPlayer)
local DoorHandler = require(ReplicatedStorage.Library.DoorHandler)

--// Instances \\--

local Events = ReplicatedStorage.Events
local Objectives = ReplicatedStorage.Objectives
local InventoryEvent = Events.Inventory
local Notification = Events.Notification
local PickUpCube = Events.PickUpCube

--// Module \\--

local Module = {}


local Colors = {
	StandBy = Color3.fromRGB(48, 88, 176),
	Granted = Color3.fromRGB(44, 168, 44),
	Denied = Color3.fromRGB(165, 43, 45)
}

local InteractableDrawers = {}

local DISTANCE_THRESHOLD = 12

local AlignPosition = script:WaitForChild("AlignPosition")
local AngularVelocity = script:WaitForChild("AngularVelocity")

local Camera = workspace.Camera

local isHoldingTouch, touchPosition

local function SetupKey(Folder, Key, InteractableDrawers)

	local randomDrawer = InteractableDrawers[math.random(1, #InteractableDrawers)]
	randomDrawer:SetAttribute("HasKey", true)

	local ray = workspace:Raycast(randomDrawer.Position, Vector3.yAxis * -2)
	if ray then
		Key.Position = ray.Position
	else
		Key.Position = randomDrawer.Position - (Vector3.yAxis * 2)
	end

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = Key
	weld.Part1 = randomDrawer
	weld.Parent = Key

	local conn = randomDrawer:GetAttributeChangedSignal("Open"):Connect(function()
		Key.ProximityPrompt.Enabled = randomDrawer:GetAttribute("Open")
	end)

	Key.ProximityPrompt.Triggered:Once(function(player)

		weld:Destroy()

		local Id = Key:GetAttribute("Id")
		Key.Name = `Key{Id}`
		Key.Parent = game:GetService("ServerStorage")

		InventoryEvent:FireClient(player, Key.Name, 1)
		Objectives["Find Orange Key"].Value = true
		player:SetAttribute(`Key{Id}`, true)

		conn:Disconnect()

	end)

	Key.ProximityPrompt.Enabled = false
	Key.ProximityPrompt.RequiresLineOfSight = false
end

local function SetupKeypad(KeyPad, Door, Sounds)

	local Id = KeyPad:GetAttribute("Id")

	local detector = Instance.new("ClickDetector")
	detector.MaxActivationDistance = 6
	detector.Parent = KeyPad.KeyPad

	detector.MouseClick:Connect(function(player)

		if player:GetAttribute(`Key{Id}`) then

			SoundPlayer.Play3D(Sounds.KeyAccept, KeyPad.KeyPad)

			local tween = ClientTween.Create(KeyPad.Light, TweenInfo.new(0.1), {Color = Colors.Granted})
			tween:Play()

			DoorHandler.OpenDoor(Door)

		else

			SoundPlayer.Play3D(Sounds.KeyDenied, KeyPad.KeyPad)

			local keyName = KeyPad:GetAttribute("KeyName")
			Notification:FireClient(player, `You need a {keyName} to open this door`)

			local tween = ClientTween.Create(KeyPad.Light, TweenInfo.new(0.1), {Color = Colors.Denied})
			tween:Play()

			task.wait(1.5)

			local tween2 = ClientTween.Create(KeyPad.Light, TweenInfo.new(0.1), {Color = Colors.StandBy})
			tween2:Play()

		end

	end)

end

local function SetupDrawers(Drawers, Sounds)

	for _, drawer in Drawers:GetDescendants() do

		if not drawer:HasTag("Drawer") then continue end

		local detector = Instance.new("ClickDetector")
		detector.MaxActivationDistance = 6
		detector.Parent = drawer

		local depth = drawer.Size.X/2

		local openTween = ClientTween.Create(drawer, TweenInfo.new(0.3), {CFrame = drawer.CFrame * CFrame.new(-depth, 0, 0)})
		local closeTween = ClientTween.Create(drawer, TweenInfo.new(0.3), {CFrame = drawer.CFrame})

		local cooldown = false
		drawer:SetAttribute("Open", false)

		detector.MouseClick:Connect(function()

			if cooldown then return end
			cooldown = true

			SoundPlayer.Play3D(Sounds.DrawerOpen, drawer.Position)
			drawer:SetAttribute("Open", not drawer:GetAttribute("Open"))

			if drawer:GetAttribute("Open") then
				openTween:Play()
			else
				closeTween:Play()
			end

			task.wait(0.4)
			cooldown = false

		end)

		table.insert(InteractableDrawers, drawer)

	end

end


function Module.SetUpCube(cube: BasePart)

	local pickUpPrompt = cube:FindFirstChildWhichIsA("ProximityPrompt", true)

	while not pickUpPrompt or not pickUpPrompt:IsA("ProximityPrompt") do
		cube.DescendantAdded:Wait()
		pickUpPrompt = cube:FindFirstChildWhichIsA("ProximityPrompt", true)
	end

	pickUpPrompt.Triggered:Connect(function(playerWhoTriggered: Player)

		if playerWhoTriggered ~= Players.LocalPlayer then return end

		local character = playerWhoTriggered.Character
		if not character then return end

		local humanoidRootPart = character.HumanoidRootPart
		local offset = Camera.CFrame:Inverse() * cube.CFrame

		pickUpPrompt.Enabled = false
		local canPickUp = PickUpCube:InvokeServer(cube, true)
		if not canPickUp then pickUpPrompt.Enabled = true return end

		local attachment = Instance.new("Attachment")

		AlignPosition.Attachment0 = attachment
		AngularVelocity.Attachment0 = attachment

		AlignPosition.Parent = cube
		AngularVelocity.Parent = cube

		attachment.Parent = cube

		if UserInputService:IsKeyDown(Enum.KeyCode.E) or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then

			while UserInputService:IsKeyDown(Enum.KeyCode.E) or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do

				if (cube.Position - humanoidRootPart.Position).Magnitude > DISTANCE_THRESHOLD then break end

				local screenPoint = UserInputService:GetMouseLocation()
				local x, y = screenPoint.X, screenPoint.Y

				local currentDirection = Camera:ScreenPointToRay(x, y).Direction
				local currentCFrame = CFrame.lookAlong(Camera.CFrame.Position, currentDirection)

				local targetPosition = (currentCFrame * offset).Position
				AlignPosition.Position = targetPosition
				RunService.RenderStepped:Wait()

			end

		elseif isHoldingTouch then

			repeat

				local x, y = touchPosition.X, touchPosition.Y

				local currentDirection = Camera:ScreenPointToRay(x, y).Direction
				local currentCFrame = CFrame.lookAlong(Camera.CFrame.Position, currentDirection)

				local targetPosition = (currentCFrame * offset).Position
				AlignPosition.Position = targetPosition
				RunService.RenderStepped:Wait()

			until not isHoldingTouch

		end

		attachment:Destroy()

		cube.AssemblyLinearVelocity = Vector3.zero
		PickUpCube:InvokeServer(cube, false, cube.CFrame)

		pickUpPrompt.Enabled = true

	end)

end

UserInputService.TouchLongPress:Connect(function(touchPositions, state)
	isHoldingTouch = state ~= Enum.UserInputState.End 
	touchPosition = touchPositions[1]
end)



function Module.Setup(Folder)

	local Key = Folder:FindFirstChild("Key")
	local KeyPad = Folder:FindFirstChild("KeyPad")
	local Door = Folder:FindFirstChild("Door")
	local Drawers = Folder:FindFirstChild("Drawers")
	local Sounds = Folder:FindFirstChild("Sounds")

	assert(Key, "No Key found")
	assert(KeyPad, "No KeyPad found")
	assert(Door, "No Door found")
	assert(Drawers, "No Drawers found")

	SetupDrawers(Drawers, Sounds)
	SetupKey(Folder, Key, InteractableDrawers)
	SetupKeypad(KeyPad, Door, Sounds)

	KeyPad.Light.Color = Colors.StandBy
end

return Module
