local Players = game:GetService("Players")
local Replicatedtorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TeleportService = game:GetService("TeleportService")

local Remotes = Replicatedtorage:WaitForChild("RemoteEvents")

local JoinGameEvent = Remotes.JoinGame
local JoinPartyEvent = Remotes.JoinParty
local LeaveParty = Remotes.LeaveParty
local Parties = Replicatedtorage.Parties
local StartMatch = Remotes.StartMatch
local CreateParty = Remotes.CreateParty
local Kick = Remotes.Kick

local ChapterIDs = {
	--Chapter1 = 87844619814085
	Chapter1 = 73718447453920
} 

local Parties = Replicatedtorage.Parties
local PartySerial = 0
local CurrentParty_Num = 0
local Party = {}

Players.PlayerAdded:Connect(function(Player)
	
	Player.CharacterAdded:Connect(function()
		local Character = Player.Character
		local Humanoid = Character:WaitForChild("Humanoid")
		Humanoid.WalkSpeed = 0
		Humanoid.JumpPower = 0
		Humanoid.JumpHeight = 0
	end)	
end)

local function PartyTeleport(Players)

	local TeleportOptions = Instance.new("TeleportOptions")
	TeleportOptions.ShouldReserveServer = true

	local success, result = pcall(function()
		return TeleportService:TeleportAsync(ChapterIDs["Chapter1"], Players, TeleportOptions)
	end)
	warn(result)
	print(Players)
end

JoinGameEvent.OnServerEvent:Connect(function(Player, Chapter)
	local TeleportOptions = Instance.new("TeleportOptions")
	TeleportOptions.ShouldReserveServer = true
	local success, result = pcall(function()
		return TeleportService:TeleportAsync(ChapterIDs["Chapter1"], {Player}, TeleportOptions)
	end)
	warn(result)
end)

local function Enrty(Player, Party)

	local PartyFolder = Parties:FindFirstChild(tostring(Party))
	print(Party)
	if not PartyFolder then return end
	
	local PartyPlayers = PartyFolder:GetChildren()
	
	if #PartyPlayers < 5 then
		Player:SetAttribute("Party", Party)

		local StringValue = Instance.new("StringValue")
		StringValue.Name = Player.Name
		StringValue.Parent = PartyFolder
		StringValue.Value = Player.Name
		return Party
	else
		return false
	end

end

CreateParty.OnServerInvoke = function(Player, Chapter)
	PartySerial += 1
	
	local PartyFolder = Instance.new("Folder")
	PartyFolder.Name = PartySerial
	PartyFolder.Parent = Parties
	
	Player:SetAttribute("Party", PartySerial)
	PartyFolder:SetAttribute("Party", PartySerial)
	Player:SetAttribute("Leader","Host")
	
	local StringValue = Instance.new("StringValue")
	StringValue.Name = Player.Name
	StringValue.Parent = PartyFolder
	StringValue.Value = Player.Name
	StringValue:SetAttribute("Leader","Host")

	table.insert(Party, PartyFolder)
	
	return true
end

JoinPartyEvent.OnServerInvoke = function(Player, Party)
	return Enrty(Player, Party)

end




StartMatch.OnServerEvent:Connect(function(Player)
	local PartySerial = Player:GetAttribute("Party")

	local PartyFolder = game.ReplicatedStorage.Parties:WaitForChild(PartySerial)
	local isHost = PartyFolder[Player.Name]:GetAttribute("Leader")
	
	if isHost == "Host" then
		
		local Party = Player:GetAttribute("Party")
		local PartyFolder = Parties:FindFirstChild(tostring(Party))
		
		local PartyPlayers = {}

		for i, Name in PartyFolder:GetChildren() do
			local player = Players:FindFirstChild(Name.Value)
			table.insert(PartyPlayers, player)
		end
		
		PartyFolder:Destroy()
		print(PartyPlayers)
		PartyTeleport(PartyPlayers)
		task.wait(5)
		
	end
end)


LeaveParty.OnServerEvent:Connect(function(Player)
	local Party = Player:GetAttribute("Party")
	local PartyFolder = Parties:FindFirstChild(tostring(Party))
	if not PartyFolder[Player.Name] then return end
	PartyFolder[Player.Name]:Destroy()
	if #PartyFolder:GetChildren() == 0 then
		PartyFolder:Destroy()
	end
	Player:SetAttribute("Party", nil)
	CurrentParty_Num -= 1
end)

Players.PlayerRemoving:Connect(function(Player)
	local Party = Player:GetAttribute("Party")
	local PartyFolder = Parties:FindFirstChild(tostring(Party))
	if not PartyFolder then return end
	if not PartyFolder[Player.Name] then return end
	PartyFolder[Player.Name]:Destroy()
	if #PartyFolder:GetChildren() == 0 then
		PartyFolder:Destroy()
	end
	Player:SetAttribute("Party", nil)
	CurrentParty_Num -= 1
end)

Kick.OnServerEvent:Connect(function(Leader, Target)
	
	local Player = Players:FindFirstChild(Target)
	if not Player then return end
	local Party = Player:GetAttribute("Party")
	if not Party then return end
	local PartyFolder = Parties:FindFirstChild(tostring(Party))
	if not PartyFolder[Player.Name] then return end
	PartyFolder[Player.Name]:Destroy()
	
	if #PartyFolder:GetChildren() == 0 then
		PartyFolder:Destroy()
	end
	
	Player:SetAttribute("Party", nil)
	CurrentParty_Num -= 1
	Kick:FireClient(Player)
	
end)