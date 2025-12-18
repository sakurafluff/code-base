--// Services \\--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

--//

local RainbowMachine = {}

local classMeta = {
	__index = RainbowMachine
}

local PlayersData = require(script.Parent.PlayersData)
local ClientTween = require(ReplicatedStorage.Library.ClientTween)
local DoorHandler = require(ReplicatedStorage.Library.DoorHandler)
local SoundPlayer = require(ReplicatedStorage.Library.SoundPlayer)

--// Instances \\--

local Events = ReplicatedStorage.Events
local NotificationEvent = Events.Notification
local InventoryEvent = Events.Inventory
local RemoveInventory = Events.RemoveInventory
local JumpscareEvent = Events.Jumpscare

--//

--// Objectives \\--
local Objecives = ReplicatedStorage.Objectives
--//


function RainbowMachine.new(folder: typeof(workspace["Rainbow Machine"]))

	local machine = folder:FindFirstChild("Machine")
	assert(machine, `No Machine inside {folder:GetFullName()}`)

	local itemPrompt = machine:FindFirstChildWhichIsA("ProximityPrompt", true)
	assert(itemPrompt, `No itemPrompt inside {machine:GetFullName()}`)

	local chicken = folder:FindFirstChild("Chicken")
	assert(chicken, `No Chicken inside {machine:GetFullName()}`)

	local eggBasket = folder:FindFirstChild("EggBasket")
	assert(eggBasket, `No EggBasket inside {machine:GetFullName()}`)

	local door = folder:FindFirstChild("Door")
	assert(door, `No Door inside {machine:GetFullName()}`)

	local sounds = folder:FindFirstChild("Sounds")
	assert(sounds, `No Sounds inside {machine:GetFullName()}`)

	local eggs = {}
	local colors = {}

	for _, egg in eggBasket:GetChildren() do
		if egg:HasTag("Egg") then

			egg.Material = Enum.Material.SmoothPlastic
			colors[egg:GetAttribute("Order")] = egg.Color

			egg.Color = Color3.new(1,1,1)
			table.insert(eggs, egg)

		end
	end

	-- constructing

	local rainbowMachine = setmetatable({

		ItemPrompt = itemPrompt,
		Folder = folder,
		Chicken = chicken,
		Machine = machine,

		Door = door,
		Sounds = sounds,

		DefaultData = {

			ChickenCFrame = chicken.RootPart.CFrame,
			EyeColor = chicken.Eyes.Color

		},

		Items = folder.Items:Clone(),

		Eggs = eggs,
		Colors = colors,

		TicketEntered = false,
		BatteryEntered = false,
		Activated = false,
		Ended = false,
		Debounce = false,

		InputCount = 0,
		MistakeCount = 0,

	}, classMeta)


	-- connections

	itemPrompt.Triggered:Connect(function(player)
		rainbowMachine:EnterItem(player)
	end)

	for _, egg in eggs do

		egg.ClickDetector.MouseClick:Connect(function(player)
			rainbowMachine:Input(player, egg.Name)
		end)

	end

	-- return

	return RainbowMachine

end


function RainbowMachine:Reset()

	self.TicketEntered = false
	self.BatteryEntered = false
	self.InputCount = 0
	self.MistakeCount = 0
	self.Activated = false
	self.Debounce = false
	self.Ended = false

	self.Chicken.RootPart.CFrame = self.DefaultData.ChickenCFrame
	self.Chicken.Eyes.Color = self.DefaultData.EyeColor
	self.ItemPrompt.Enabled = true

	self.Items:Clone().Parent = workspace

	for _, v in self.Machine.Battery:GetChildren() do
		v.Transparency = 1
	end

end


function RainbowMachine:Mistake(player)

	local mistakeCount = self.MistakeCount
	print(`Mistake #{mistakeCount}`)

	if mistakeCount == 1 then

		local tween = ClientTween.Create(self.Chicken.Eyes, TweenInfo.new(0.3), {Color = Color3.new(1)})
		tween:Play()

	elseif mistakeCount == 2 then

		local targetCFrame = self.DefaultData.ChickenCFrame * CFrame.new(0, 4.5, -1.16571045)

		local tween = ClientTween.Create(self.Chicken.RootPart, TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {CFrame = targetCFrame})
		tween:Play()

	elseif mistakeCount == 3 then

		JumpscareEvent:FireClient(player, self.Folder.Jumpscare)

		task.wait(3)

		if player.Character then
			player.Character.Humanoid.Health = 0
		end

		task.wait(1)

		self:Reset()
		return true

	end

end

function RainbowMachine:Done()

	RainbowMachine.Ended = true
	Objecives["Open Rainbow Grey Door"].Value = true
	
	DoorHandler.OpenDoor(self.Door)
	
end


function RainbowMachine:ShuffleEggs()

	print("shuffling")

	local eggs = self.Eggs
	
	Random.new():Shuffle(eggs)

	local array = table.create(#eggs)
	for i = 1, #eggs do array[i] = i end

	Random.new():Shuffle(array)
	--self.Sounds.Chromatic:Play()

	for _, i in array do
		local egg = eggs[i]
		egg.Color = self.Colors[i]
		egg.Material = Enum.Material.Neon
		egg.SurfaceGui.TextLabel.Text = i
		
		SoundPlayer.Play3D(SoundService.SFX.EggBeep, egg)
		task.wait(0.2)
	end

	task.wait(0.3)

	for i = 1, 2 do

		for _, i in array do
			local egg = eggs[i]
			egg.Color = Color3.new(1, 1, 1)
			egg.Material = Enum.Material.SmoothPlastic
		end

		task.wait(0.5)

		for _, i in array do
			local egg = eggs[i]
			egg.Color = self.Colors[i]
			egg.Material = Enum.Material.Neon
		end

		--self.Sounds.Ping2:Play()
		SoundPlayer.Play3D(SoundService.SFX.EggBeep, self.Machine:GetPivot().Position)
		task.wait(0.5)

	end

	for _, i in array do
		local egg = eggs[i]
		egg.Color = Color3.new(1, 1, 1)
		egg.Material = Enum.Material.SmoothPlastic
	end

end


function RainbowMachine:Input(player: Player, egg: string)

	if self.Ended then return end
	if not self.Activated then NotificationEvent:FireClient(player, "The machine is off") return end

	if self.Debounce then return end
	self.Debounce = true
	
	local nextInput = self.InputCount + 1
	--self.InputCount += 1
	SoundPlayer.Play(SoundService.SFX.EggBeep)
	--self.Sounds.Ping:Play()

	local currentEgg = self.Eggs[nextInput]
	local isCorrect = currentEgg.name == egg
	
	if isCorrect then
		self.InputCount = nextInput
	end

	local color = isCorrect and Color3.fromRGB(39, 165, 0) or Color3.fromRGB(165, 0, 0)

	for _, egg in self.Eggs do
		egg.Color = color
		egg.Material = Enum.Material.Neon
	end

	task.wait(1)

	for _, egg in self.Eggs do
		egg.Color = Color3.new(1, 1, 1)
		egg.Material = Enum.Material.SmoothPlastic
	end

	task.wait(1)

	if not isCorrect then

		self.MistakeCount += 1
		local reset = self:Mistake(player)
		if reset then return end

	end

	if self.InputCount == 7 then -- fix this back to 7
		print("Completed")
		self:Done()
	else
		self:ShuffleEggs()
		warn("done shuffling")
	end

	self.Debounce = false

end


function RainbowMachine:Activate()

	if self.Ended then return end

	if not self.TicketEntered then
		warn("Ticket not entered")
		return
	elseif not self.BatteryEntered then
		warn("Battery not entered")
		return
	end

	print("Machine starting")	

	self.Activated = true
	self.Debounce = true
	self:ShuffleEggs()
	self.Debounce = false

end


function RainbowMachine:EnterItem(player: Player)

	local inventory = PlayersData[player].Inventory

	if not self.BatteryEntered then

		local itemName = "Battery"

		local index = table.find(inventory, itemName)
		if not index then NotificationEvent:FireClient(player, "The machine is off, charge it to make it working.") return end

		local tool = player.Backpack:FindFirstChild(itemName) 
		if not tool then
			local character = player.Character

			if character then
				tool = character:FindFirstChild(itemName)
			end
		end

		if tool then
			RemoveInventory:FireClient(player, tool.Name)
			tool:Destroy() 
		end

		table.remove(inventory, index)
		
		
		
		print("battery inserted")
		Objecives["Power the Rainbow Machine"].Value = true

		self.BatteryEntered = true

		for _, v in self.Machine.Battery:GetChildren() do
			v.Transparency = 0
		end

	elseif not self.TicketEntered then

		local itemName = "Ticket"
		
		local index = table.find(inventory, itemName)
		if not index then NotificationEvent:FireClient(player, "Insert a ticket to start the machine") return end
		local tool = player.Backpack:FindFirstChild(itemName) 
		if not tool then
			local character = player.Character

			if character then
				tool = character:FindFirstChild(itemName)
			end
		end
		
		if tool then
			RemoveInventory:FireClient(player, tool.Name)
			tool:Destroy() 
		end

		table.remove(inventory, index)
		print("ticket entered")
		Objecives["Pay something to the Machine"].Value = true
		self.TicketEntered = true

		local ticketEntrance = self.Machine.TicketEntrance.CFrame

		local ticket = self.Items.Ticket:Clone()
		ticket.CFrame = ticketEntrance * CFrame.new(0.8, 0, 0) 
		ticket.Parent = workspace

		local tween = ClientTween.Create(ticket, TweenInfo.new(), {CFrame = ticketEntrance * CFrame.new(-0.8,0,0)})

		task.delay(0.4, function()

			SoundPlayer.Play(SoundService.SFX.TicketInsert)

			tween:Play()
			tween.Completed:Connect(function()
				ticket:Destroy()
				self:Activate()
			end)

		end)

		self.ItemPrompt.Enabled = false

	end

end


return RainbowMachine