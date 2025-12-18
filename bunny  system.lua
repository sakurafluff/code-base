local Rep_Storage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PathFindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")


local ServerStorage = game:GetService("ServerStorage")
local Events = ServerStorage:WaitForChild("BindableEvents")
local RemoteEvents = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")

local BunnySpawn_Event = Events:WaitForChild("BunnySpawn")
local BunnyEventValue = Events:WaitForChild("BunnyEventValue")
local Reset = Events:WaitForChild("Reset")

local BunnySpawn_Client = RemoteEvents:WaitForChild("BunnySpawn")

local Bunny = workspace.Rabbit
local BunnyHumanoid = Bunny.Humanoid
local Walk_Anim = Rep_Storage:WaitForChild("RabbitWalk")
local Walk_Track = BunnyHumanoid:LoadAnimation(Walk_Anim)
local Shake_Signal = Rep_Storage:WaitForChild("CamShake")

local Right_Crack = Bunny.Body.FootRight.Crack
local Right_Smoke = Bunny.Body.FootRight.Smoke
local Left_Crack = Bunny.Body.FootLeft.Crack
local Left_Smoke = Bunny.Body.FootLeft.Smoke

local Crack = Rep_Storage.Crack
local LeftAtt = Bunny.Body.FootLeft
local RightAtt = Bunny.Body.FootRight

--Walk_Track.Looped = true
--Walk_Track:Play()

local MATERIALS = Enum.Material:GetEnumItems()
local Dict = {}

for _, material in MATERIALS do
	Dict[material.Name] = 2000
end

Dict.BunnyPath = 1

local Path = PathFindingService:CreatePath({
	AgentRadius = 5,
	AgentHeight = 9,
	AgentCanJump = true,
	WaypointSpacing = 3,

	Costs = Dict
})

local Distance = 2000
local start

local Deads = {}

local SoundPlayer = require(Rep_Storage:WaitForChild("SoundPlayer"))
local Chase_Track
local PATH_ = Instance.new("Folder", workspace)

local function CreateMarker(position: Vector3, parent: Instance, i)
	local Part = Instance.new("Part")
	Part.Name = i
	Part.Shape = "Ball"
	Part.Size = Vector3.one * 0.5
	Part.CanQuery = false
	Part.CanTouch = true
	Part.CastShadow = false
	Part.Material = Enum.Material.Neon
	Part.Color = Color3.fromRGB(186, 97, 34)
	Part.Anchored = true
	Part.Position = position
	Part.CanCollide = false
	Part.Parent = parent
end

local function GetSurvivors(): {Player}
	local players = Players:GetPlayers()
	local survivors = {}

	for _, player in players do
		if player.Character and player.Character.Parent then
			table.insert(survivors, player)
		end
	end

	return survivors
end

BunnySpawn_Event.Event:Connect(function(_, Bunny)

	BunnySpawn_Client:FireAllClients()
	Chase_Track = SoundPlayer.Play(SoundService["Horror Drones (B)"])
	
	--Chase_Track.
	
	BunnyEventValue.Value = true

	BunnyEventValue.Value = true
	local Character_Root
	local Character


	local TargetCharacterRoot
	local TargetCharacter

	--BunnyHumanoid:MoveTo(workspace.Stairs_END.Position)
	--BunnyHumanoid.MoveToFinished:Wait()

	task.spawn(function()
		while task.wait(0.8) do -- why waiting this long? ermmm what the smelly doin

			if BunnyEventValue.Value == false then break end

			for _, player in GetSurvivors() do
				local character = player.Character
				if  character.Humanoid.Health < 1 then continue end

				local In_Lift = player:FindFirstChild("InLift")
				if In_Lift then continue end

				local New_Distance = (character.PrimaryPart.Position - Bunny.PrimaryPart.Position).Magnitude

				if New_Distance < Distance then
					Distance = New_Distance
					TargetCharacter = character
					TargetCharacterRoot = character:WaitForChild("HumanoidRootPart")
					start = true

				end

			end

			Distance = 1000
		end
	end)

	local RayParams = RaycastParams.new()
	RayParams.FilterDescendantsInstances = {workspace.Rabbit}
	RayParams.FilterType = Enum.RaycastFilterType.Exclude

	repeat task.wait() until start
	if BunnyEventValue.Value == false then return end

	local function Path_Compute()

		local Direction = (TargetCharacterRoot.Position - Bunny.PrimaryPart.Position).Unit
		local Raycast = workspace:Blockcast(CFrame.lookAt(Bunny.HumanoidRootPart.Position, TargetCharacterRoot.Position), Vector3.new(4,4,4),Direction*1000, RayParams)
		if not Raycast then return end 

		--[[if Raycast.Instance.Parent ~= Character or Raycast.Instance.Parent.Parent ~= Character then
			for i = 0,4,1 do
				Raycast = workspace:Blockcast(CFrame.lookAt(Bunny.HumanoidRootPart.Position, Character_Root.Position), Vector3.new(4,4,4),Direction*1000, RayParams)
				if Raycast.Instance.Parent ~= Character or Raycast.Instance.Parent.Parent ~= Character then
					continue
				else
					break
				end
			end 
		end]]
       
		if Raycast.Instance then
			if Raycast.Instance.Parent == TargetCharacter or Raycast.Instance.Parent.Parent == TargetCharacter then
				BunnyHumanoid.WalkSpeed = 16
				BunnyHumanoid:MoveTo(TargetCharacterRoot.Position)
			else
				Path:ComputeAsync(Bunny.PrimaryPart.Position, TargetCharacter.HumanoidRootPart.Position)
				local Player_pos = TargetCharacter.HumanoidRootPart.Position
				local Waypoints
				if Path.Status == Enum.PathStatus.Success then
					Waypoints = Path:GetWaypoints()--[[
					PATH_:ClearAllChildren()
					--for i,v in Waypoints do
					--	CreateMarker(v.Position, PATH_, i)
					--end]]
				else return

				end

				for i,v in Waypoints do
					Path:ComputeAsync(Bunny.PrimaryPart.Position, TargetCharacter.HumanoidRootPart.Position)
					BunnyHumanoid.WalkSpeed = 16
					if v.Action == Enum.PathWaypointAction.Jump then
						BunnyHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
					end
					BunnyHumanoid:MoveTo(v.Position)
					--BunnyHumanoid.MoveToFinished:Wait()

					local Objects = workspace:GetPartBoundsInRadius(Bunny.PrimaryPart.Position, 6)
					local Check = false

					for i,v in Objects do
						if v.Parent == TargetCharacter then
							Check = true
						end

					end

					if Check == true then
						break
					end

				end

			end

		end

	end

	while task.wait(1) do
		if BunnyEventValue.Value == false then
			break
		end
		Path_Compute()

	end



end)




--local Player = game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait()
--local Character = Player.Character or Player.CharacterAdded:Wait()

local function Reset_Func()

	if Chase_Track then
		Chase_Track:Stop()
	end
	--Chase_Track:Stop()
	for i,v in Players:GetPlayers() do
		Deads[v] = nil
	end
end

Reset.Event:Connect(Reset_Func)
