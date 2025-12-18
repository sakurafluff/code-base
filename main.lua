--// Services \\--

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")
local SoundService = game:GetService("SoundService")

--// Constants \\--

--local RESPAWN_PRODUCT_ID = 2992334315 -- smelly
local RESPAWN_PRODUCT_ID = 3239733416
local HINT_PRODUCT_ID = 3239733150


local STARTING_CHECKPOINT = tostring(3)
local STARTING_LIVES = tostring(3)

--// Modules \\--

local Library = ReplicatedStorage.Library
local RainbowMachineHandler = require(script.RainbowMachine) -- READ (after reading this script's marked stuffs)
local SoundPlayer = require(Library.SoundPlayer)

local ButtonHandler = require(script.ButtonHandler)
local PlayersData = require(script.PlayersData)
local CubeHandler = require(script.CubeHandler)

local ClientTween = require(ReplicatedStorage.Library.ClientTween)
local DoorHandler = require(ReplicatedStorage.Library.DoorHandler)

--// Instances \\--

local Bindables = ServerStorage.BindableEvents
local Events = ReplicatedStorage.Events
local Remotes = ReplicatedStorage.Remotes
local Objectives = ReplicatedStorage.Objectives
local InventoryEvent = Events.Inventory
local PickUpCubeEvent = Events.PickUpCube
local NotificationEvent = Events.Notification
local HackedComputerEvent = Events.HackedComputer
local ResetSystems = Bindables.Reset
local RespawnPurchase = Remotes.RespawnPrompt
local DeadScreen = Remotes.DeadScreen

--//

local ButtonList = CollectionService:GetTagged("Button")
local CubeList = CollectionService:GetTagged("Cube")

local ComputerHacked = false
local ButtonTypes = {}

--// Functions \\--


local function setCollisionGroup(part: Instance)

	if part:IsA("BasePart") then
		part.CollisionGroup = "Player"
	end

end


local function setUpButton(button: BasePart)

	local buttonType = button:GetAttribute("Type")
	ButtonTypes[buttonType] = button

	if buttonType == "Red" then

		local elevator = workspace["Cube Puzzle System"].Elevator

		local startPosition = elevator.CFrame
		local endPosition = elevator.CFrame + Vector3.yAxis * 21.5

		local speed = 2
		local tween

		ButtonHandler.new(button):Connect(function(isDown)

			local target = isDown and endPosition or startPosition
			local duration = (target.Position - elevator.Position).Magnitude / speed

			if tween then tween:Cancel() end

			local currentTween = game.TweenService:Create(elevator, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = target})
			tween = currentTween

			currentTween:Play()
			currentTween.Completed:Wait()

			if currentTween == tween then tween = nil end

		end)

	elseif buttonType == "Green" then

		local door = workspace["Cube Puzzle System"].DoorA

		local startCFrame = door.CFrame
		local startSize = Vector3.new(18.079, 17.824, 0.1)

		local endSize = Vector3.new(18.079, 1, 0.1)
		local endCFrame = startCFrame * CFrame.new((startSize - endSize))

		local buttonDown, debounce
		local state = {
			[true] = ClientTween.Create(door, TweenInfo.new(4, Enum.EasingStyle.Linear), {CFrame = endCFrame}),
			[false] = ClientTween.Create(door, TweenInfo.new(4, Enum.EasingStyle.Linear), {CFrame = startCFrame})
		}

		ButtonHandler.new(button):Connect(function(isDown)

			buttonDown = isDown
			if debounce then return end

			debounce = true

			repeat

				isDown = buttonDown
				local tween = state[isDown]
				tween:Play()
				tween.Completed:Wait()

			until buttonDown == isDown


			debounce = false

		end)

	elseif buttonType == "Blue" then

		local door = workspace["Cube Puzzle System"].DoorB

		local buttonDown, debounce
		local state = {
			[true] = "OpenDoor",
			[false] = "CloseDoor"
		}

		ButtonHandler.new(button):Connect(function(isDown)

			buttonDown = isDown
			if debounce then return end

			debounce = true

			repeat

				isDown = buttonDown
				local funcName = state[isDown]
				Objectives["Open the second grey Door"].Value = true
				DoorHandler[funcName](door)
				task.wait(2.3)

			until buttonDown == isDown


			debounce = false

		end)

	else
		error(`Invalid button type: {buttonType}`)
	end

end

local function GetSurviors()
	
	local survs = {}
	
	for _, player in Players:GetPlayers() do
		local Character = player.Character
		local Humanoid = Character.Humanoid
		local Humanoid_Health = Humanoid.Health
		local Player_CheckPoint = tonumber(player:GetAttribute("Checkpoint"))
		local Player_Lives = tonumber(player:GetAttribute("Lives"))
		
		if Humanoid_Health > 0 then
			return false
		end
	
		if Player_CheckPoint == 3 and Player_Lives > 0 then
			table.insert(survs, player)
		end
	end
	
	return true, survs
end


--//Music//--
local GameMusic = SoundService:WaitForChild("MainGameMusic")
GameMusic.Looped = true
GameMusic:Play()



local function spawnPlayer(player: Player)

	player:LoadCharacter()

	local character = player.Character
	character:PivotTo(workspace.Checkpoints:FindFirstChild(player:GetAttribute("Checkpoint")):GetPivot())

end

local function spawnAll(survivors)
	
	for i,player in survivors do
		spawnPlayer(player)
	end
end

local function ShowDeathScreen(player: Player)
	local Player_CheckPoint = tonumber(player:GetAttribute("Checkpoint"))
	local Player_Lives = tonumber(player:GetAttribute("Lives"))
	
	if Player_CheckPoint ~= 3 then
		DeadScreen:FireClient(player, Player_Lives, Player_CheckPoint)

		player:SetAttribute("RespawnTime", workspace:GetServerTimeNow() + Players.RespawnTime)
		player:SetAttribute("PurchaseTime", workspace:GetServerTimeNow() + 20)
		
		if Player_Lives > 0 then
			print("respawn...")
			task.delay(Players.RespawnTime, spawnPlayer, player)
		end
	end
end

local function OnPlayerAdded(player: Player) -- READ
	--repeat task.wait() until (CutsceneEnded.Value == true)
	print("game started")
	player:SetAttribute("Checkpoint", STARTING_CHECKPOINT)
	player:SetAttribute("Lives", STARTING_LIVES)
	
	
	PlayersData[player] = {
		Inventory = {}
	}
	
	player.CharacterAdded:Connect(function(character)

		character.DescendantAdded:Connect(setCollisionGroup)
		for _, v in character:GetDescendants() do setCollisionGroup(v) end

		character.Humanoid.Died:Once(function()
			
			local Player_CheckPoint = tonumber(player:GetAttribute("Checkpoint"))
			local Player_Lives = tonumber(player:GetAttribute("Lives"))
			Player_Lives = Player_Lives - 1

			player:SetAttribute("Lives", tostring(Player_Lives))
			
			if Player_CheckPoint ~= 3 then
				ShowDeathScreen(player)
			else
				local Alldead, survs = GetSurviors()
				print("All dead:", Alldead)
				
				if Alldead then
					--if  #survs < 1 then return end
					ResetSystems:Fire()
					
					local players = Players:GetPlayers()
					for i, player in players do
						
						local Player_CheckPoint = tonumber(player:GetAttribute("Checkpoint"))
						local Player_Lives = tonumber(player:GetAttribute("Lives"))
												
						print("showing death screens")

						local character = player.Character
						print(player, "last died to bunny", character:GetAttribute("LastToDieToBunny"))
						
						local delayTime = if character:GetAttribute("LastToDieToBunny") then 2 else 0
						
						task.delay(delayTime, function()
							player:SetAttribute("RespawnTime", workspace:GetServerTimeNow() + Players.RespawnTime + 2 - delayTime)
							player:SetAttribute("PurchaseTime", workspace:GetServerTimeNow() + 20 + 2 - delayTime)
							DeadScreen:FireClient(player, Player_Lives, Player_CheckPoint)
						end)
						
					end

					task.wait(Players.RespawnTime + 2)
					spawnAll(survs)
					
				end
			end
			
		end)

	end)

	task.delay(2, spawnPlayer, player)
	--spawnPlayer()

	print("you smell")

	
end

local ProductFunctions = {}

ProductFunctions[RESPAWN_PRODUCT_ID] = function(_, player)
	
	local Player_Lives = tonumber(player:GetAttribute("Lives"))
	Player_Lives += 1
	player:SetAttribute("Lives", tostring(Player_Lives))
	
	spawnPlayer(player)

	return true
	
end

ProductFunctions[HINT_PRODUCT_ID] = function(_, player)
	
	local HintCredits = player:FindFirstChild("HintCredits")
	HintCredits.Value += 3
	
	return true
end

local function processReceipt(receiptInfo)
	local userId = receiptInfo.PlayerId
	local productId = receiptInfo.ProductId

	local player = Players:GetPlayerByUserId(userId)
	if player then
		
		local handler = ProductFunctions[productId]
		local success, result = pcall(handler, receiptInfo, player)
		if success then
			
			return Enum.ProductPurchaseDecision.PurchaseGranted
		else
			warn("Failed to process receipt:", receiptInfo, result)
		end
	end

	
	return Enum.ProductPurchaseDecision.NotProcessedYet
end


--// Connections \\--

Players.PlayerAdded:Connect(OnPlayerAdded)

for _, player in Players:GetPlayers() do
	OnPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player: Player) 
	PlayersData[player] = nil
end)

MarketplaceService.ProcessReceipt = processReceipt

RespawnPurchase.OnServerEvent:Connect(function(player)

	local Player_CheckPoint = tonumber(player:GetAttribute("Checkpoint"))
	local Player_Lives = tonumber(player:GetAttribute("Lives"))
	
	if Player_Lives <= 0 then
	
		local Id = RESPAWN_PRODUCT_ID
		MarketplaceService:PromptProductPurchase(player, Id)
		
	end

end)

InventoryEvent.OnServerEvent:Connect(function(player: Player, item: Instance) -- READ (WILL BE DOING INVENTORY UI)

	local playerData = PlayersData[player]
	local inventory = playerData.Inventory

	local itemName = item:GetAttribute("ItemName")
	table.insert(inventory, itemName)

	local tool = game.ServerStorage:FindFirstChild(itemName)

	if not tool then
		tool = Instance.new("Tool")
		tool.Name = itemName
	end
	tool.Parent = player.Backpack

	item:Destroy()
	InventoryEvent:FireClient(player, itemName, 1)

end)


HackedComputerEvent.OnServerEvent:Connect(function(player: Player)

	if ComputerHacked then return end
	ComputerHacked = true

	script.LocketKey:Clone().Parent = workspace
	Objectives["Find the Key of Locker"].Value = true
	

end)

local ClickDetetcor = workspace["Hacking System"].LocketKey.ClickDetector
ClickDetetcor.MouseClick:Once(function(Player)
	local character = Player.Character
	if not character then return end
	Objectives["Find the Key of Locker"].Value = true
end)


PickUpCubeEvent.OnServerInvoke = function(player, cube: BasePart, pickUp: boolean, ...)

	if not cube then return end

	local character = player.Character
	if not character then return end

	local owner = cube:GetAttribute("Owner")
	if owner and owner ~= player.UserId then return end

	if pickUp then

		local humanoid = character.Humanoid
		if humanoid.Health == 0 then return end

		local cubeObject = CubeHandler.GetCubeFromPart(cube)
		if not cubeObject then return end

		cubeObject:SetOwnership(player)

	else

		local cubeObject = CubeHandler.GetCubeFromPart(cube)
		if not cubeObject then return end

		cubeObject:RemoveOwnership(player)

	end

	return true

end

do
	--repeat wait() until CutsceneEnded.Value == true
	task.wait(4)
	local folder = workspace["Hacking System"]
	local locker = folder.Locker
	folder.LocketKey.Parent = script

	local toTween = {
		[locker.LDoor.Hinge] = {
			[false] = locker.LDoor.Hinge.CFrame,
			[true] = locker.LDoor.Hinge.CFrame * locker.LDoor.Hinge:GetAttribute("Angles")
		},
		[locker.RDoor.Hinge] = {
			[false] = locker.RDoor.Hinge.CFrame,
			[true] = locker.RDoor.Hinge.CFrame * locker.RDoor.Hinge:GetAttribute("Angles")
		}
	}

	local sounds = locker.Sounds

	local openSound = sounds.LockerOpen
	local closeSound = sounds.LockerClose

	local isOpen = false
	local isLocked = true
	local canJumpscare = true

	local previousTween = {}

	locker.Prompt.OpenLocker.Triggered:Connect(function(playerWhoTriggered: Player) 

		local playerData = PlayersData[playerWhoTriggered]
		local inventory = playerData.Inventory

		if isLocked and not table.find(inventory, "Locker Key") then
			NotificationEvent:FireClient(playerWhoTriggered, "The locker is locked.") 
		else

			if isLocked then
				isLocked = false

				local itemName = "Locker Key"
				local index = table.find(inventory, itemName)
				if index then
					table.remove(inventory, index)

					local tool = playerWhoTriggered.Backpack:FindFirstChild(itemName) 
					if not tool then
						local character = playerWhoTriggered.Character

						if character then
							tool = character:FindFirstChild(itemName)
						end
					end

					if tool then
						tool:Destroy()
						Events.RemoveInventory:FireClient(playerWhoTriggered, tool.Name)
					end
				end

			end

			for _, v in previousTween do v:Cancel() end
			table.clear(previousTween)

			isOpen = not isOpen

			local tween

			for instance, tweenData in toTween do
				tween = ClientTween.Create(instance, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {CFrame = tweenData[isOpen]})
				tween:Play()
				table.insert(previousTween, tween)
			end

			if isOpen then
				openSound:Play()
			else
				closeSound:Play()
			end

			tween.Completed:Wait()
			Objectives["Open the locker with key"].Value = true

			if previousTween[2]._id == tween._id and isOpen and canJumpscare then
				Events.SpiderJumpscare:FireClient(playerWhoTriggered, playerWhoTriggered, locker.Spider)
				canJumpscare = false
				
				local character = playerWhoTriggered.Character
				local humanoid = character.Humanoid
				humanoid:TakeDamage(30)
			end

		end

	end)

end



RainbowMachineHandler.new(workspace["Rainbow Machine"]) -- READ

for _, v in CollectionService:GetTagged("Button") do task.spawn(setUpButton, v) end
for _, v in CollectionService:GetTagged("Cube") do task.spawn(CubeHandler.new, v, ButtonTypes[v:GetAttribute("Type")]) end

for _, checkPoint: BasePart in workspace.Checkpoints:GetChildren() do

	task.spawn(function()

		local cframe = checkPoint.CFrame
		local size = checkPoint.Size

		local players = {}

		while true do

			local parts = workspace:GetPartBoundsInBox(cframe, size)
			for _, part in parts do
				local character = part.Parent
				if not character:IsA("Model") then continue end
				
				local player = Players:GetPlayerFromCharacter(character)
				if not player or players[player] then continue end
				
				players[player] = true

				local currentCheckpoint = player:GetAttribute("Checkpoint")
				if currentCheckpoint >= checkPoint.Name then continue end
				
				player:SetAttribute("Checkpoint", checkPoint.Name)
				
				if checkPoint.Name == "3" then
					for _, player in Players:GetPlayers() do
						player:SetAttribute("Checkpoint", "3")
						
						if tonumber(player:GetAttribute("Lives")) > 0 then
							Remotes.BlackTransition:FireClient(player)
							task.delay(1, spawnPlayer, player)
							--spawnPlayer(player)
						end
					end
				end
			end
			
			task.wait(0.1)

		end

	end)

end