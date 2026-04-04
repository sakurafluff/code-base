--//Services//--
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

--//Variables//--
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Root = Character:WaitForChild("shark_mesh")

--//Config//--
local MaxSpeed = 40
local BoostSpeed = 70
local Acceleration = 8
local TurnSpeed = 5
local VerticalSpeed = 25
local Drag = 3
local WaterSurfaceY = 141.28
local SeaBottomY = 5
local BuoyancySmooth = 0.5

-- Extra configs
local Sprinting = false
local Boosting = false
local BoostDuration = 2
local BoostCooldown = 5
local BoostTimer = 0
local BoostCooldownTimer = 0

local IdleSwayStrength = 0.5
local IdleSwaySpeed = 2

local CurrentVelocity = Vector3.zero
local VerticalInput = 0

local Humanoid = Character:WaitForChild("Humanoid")
Humanoid.WalkSpeed = 0
Humanoid.JumpPower = 0
Humanoid.AutoRotate = false

--//Input Handling//--
UserInputService.InputBegan:Connect(function(Input, Gp)
	if Gp then return end

	if Input.KeyCode == Enum.KeyCode.Space then
		VerticalInput = 1
	elseif Input.KeyCode == Enum.KeyCode.LeftControl then
		VerticalInput = -1
	elseif Input.KeyCode == Enum.KeyCode.LeftShift then
		Sprinting = true
	elseif Input.KeyCode == Enum.KeyCode.E then
		if BoostCooldownTimer <= 0 then
			Boosting = true
			BoostTimer = BoostDuration
			BoostCooldownTimer = BoostCooldown
		end
	end
end)

UserInputService.InputEnded:Connect(function(Input)
	if Input.KeyCode == Enum.KeyCode.Space or Input.KeyCode == Enum.KeyCode.LeftControl then
		VerticalInput = 0
	elseif Input.KeyCode == Enum.KeyCode.LeftShift then
		Sprinting = false
	end
end)

--//Utility Functions//--
local function ApplyIdleSway(Time)
	local OffsetY = math.sin(Time * IdleSwaySpeed) * IdleSwayStrength
	return Vector3.new(0, OffsetY, 0)
end

local function ClampWaterBounds(Position, Velocity, Dt)
	local NextY = Position.Y + Velocity.Y * Dt

	if NextY > WaterSurfaceY then
		local Excess = NextY - WaterSurfaceY
		return Vector3.new(
			Velocity.X,
			-Excess * BuoyancySmooth / Dt,
			Velocity.Z
		)
	elseif NextY < SeaBottomY then
		local Excess = SeaBottomY - NextY
		return Vector3.new(
			Velocity.X,
			Excess * BuoyancySmooth / Dt,
			Velocity.Z
		)
	end

	return Velocity
end

local function GetSpeed()
	if Boosting then
		return BoostSpeed
	elseif Sprinting then
		return MaxSpeed * 1.5
	else
		return MaxSpeed
	end
end

--//Main Loop//--
RunService.RenderStepped:Connect(function(Dt)

	local Camera = workspace.CurrentCamera
	local InputDir = Humanoid.MoveDirection
	local MoveDirection = Vector3.zero

	-- State handling
	if InputDir.Magnitude > 0 then
		Character:SetAttribute("State", "Running")
	else
		Character:SetAttribute("State", "Idle")
	end

	-- Movement direction
	if InputDir.Magnitude > 0 then
		local CamLook = Camera.CFrame.LookVector
		MoveDirection = CamLook.Unit * InputDir.Magnitude

		local TargetCFrame = CFrame.new(Root.Position, Root.Position + MoveDirection)
		Root.CFrame = Root.CFrame:Lerp(TargetCFrame, TurnSpeed * Dt)
	end

	-- Speed calculation
	local Speed = GetSpeed()

	-- Target velocity
	local TargetVelocity = MoveDirection * Speed
	TargetVelocity += Vector3.new(0, VerticalInput * VerticalSpeed, 0)

	-- Acceleration smoothing
	CurrentVelocity = CurrentVelocity:Lerp(TargetVelocity, Acceleration * Dt)

	-- Drag when idle
	if InputDir.Magnitude == 0 and VerticalInput == 0 then
		CurrentVelocity = CurrentVelocity:Lerp(Vector3.zero, Drag * Dt)

		-- Idle sway
		CurrentVelocity += ApplyIdleSway(tick())
	end

	-- Water bounds clamp
	CurrentVelocity = ClampWaterBounds(Root.Position, CurrentVelocity, Dt)

	-- Boost handling
	if Boosting then
		BoostTimer -= Dt
		if BoostTimer <= 0 then
			Boosting = false
		end
	end

	if BoostCooldownTimer > 0 then
		BoostCooldownTimer -= Dt
	end

	-- Apply velocity
	Root.AssemblyLinearVelocity = CurrentVelocity
end)


local function PrintDebug()
	while true do
		task.wait(1)
		print("Speed:", CurrentVelocity.Magnitude)
		print("Boosting:", Boosting)
		print("Cooldown:", math.max(0, BoostCooldownTimer))
	end
end

task.spawn(PrintDebug)

--//Extra Enhancements//--

-- Smooth rotation stabilizer
RunService.Heartbeat:Connect(function()
	if CurrentVelocity.Magnitude > 1 then
		local Look = CurrentVelocity.Unit
		local Target = CFrame.new(Root.Position, Root.Position + Look)
		Root.CFrame = Root.CFrame:Lerp(Target, 0.1)
	end
end)

-- Anti-stuck system
RunService.Stepped:Connect(function()
	if CurrentVelocity.Magnitude < 0.1 then
		CurrentVelocity += Vector3.new(0, 0.01, 0)
	end
end)

-- Auto depth stabilizer
RunService.Heartbeat:Connect(function()
	if VerticalInput == 0 then
		local DepthCenter = (WaterSurfaceY + SeaBottomY) / 2
		local Offset = DepthCenter - Root.Position.Y
		CurrentVelocity += Vector3.new(0, Offset * 0.01, 0)
	end
end)

-- Safety reset if out of bounds
RunService.Heartbeat:Connect(function()
	if Root.Position.Y > WaterSurfaceY + 50 then
		Root.Position = Vector3.new(Root.Position.X, WaterSurfaceY - 5, Root.Position.Z)
	elseif Root.Position.Y < SeaBottomY - 50 then
		Root.Position = Vector3.new(Root.Position.X, SeaBottomY + 5, Root.Position.Z)
	end
end)

