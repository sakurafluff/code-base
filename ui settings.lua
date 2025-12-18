local Players  = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DatastoreService = game:GetService("DataStoreService")
local SettingsData = DatastoreService:GetDataStore("SoundSettings")
local BadgeService = game:GetService("BadgeService")

local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local PlayerVolumeData = {}

local WELCOME_BADGE_ID = 2860118779471817
local MeetItzFoxy_BADGE_ID = 3467036028616487
local ItzFoxy_USER_ID = 5158398537

Remotes.SetVolume.OnServerEvent:Connect(function(Player, Volumes)
	
	local PlayerVolume = Player.Volumes

	for i,v in Volumes do
		PlayerVolume[i].Value = v
		PlayerVolumeData[Player.Name][i] = v
	end
	
end)

Players.PlayerAdded:Connect(function(Player)
	
	local success, hasBadge = pcall(BadgeService.UserHasBadgeAsync, BadgeService, Player.UserId, WELCOME_BADGE_ID)
	--task.wait(5)
	--Remotes.BagdeAward:FireClient(Player,"Welcome")
	if success then	
		if not hasBadge then
			BadgeService:AwardBadge(Player.UserId, WELCOME_BADGE_ID)
			Remotes.BagdeAward:FireClient(Player,"Welcome")
		end
	end		

	if Player.UserId == ItzFoxy_USER_ID then
		for _, v in Players:GetPlayers() do
			local success, hasBadge = pcall(BadgeService.UserHasBadgeAsync, BadgeService, v.UserId, MeetItzFoxy_BADGE_ID)	
			if success then
				if not hasBadge then
					BadgeService:AwardBadge(v.UserId, MeetItzFoxy_BADGE_ID)
					Remotes.BagdeAward:FireClient(Player,"Meet the dev!")
				end
			end 
		end		
	end
	
	for i,v in Players:GetPlayers() do
		if v.UserId == ItzFoxy_USER_ID then
			local success, hasBadge = pcall(BadgeService.UserHasBadgeAsync, BadgeService, Player.UserId, MeetItzFoxy_BADGE_ID)

			if success then	
				if not hasBadge then
					BadgeService:AwardBadge(Player.UserId, MeetItzFoxy_BADGE_ID)	
				end
			end	
		end
	end
	
	local Status, Data = pcall(function()	
		return SettingsData:GetAsync(Player.UserId.." Volume")
	end)
	
	local Volumes = Instance.new("Folder")
	Volumes.Name = "Volumes"
	
	PlayerVolumeData[Player.Name] = {}
	local MasterVolume = Instance.new("NumberValue")
	MasterVolume.Name = "MasterVolume"
	MasterVolume.Value = 1
	PlayerVolumeData[Player.Name]["MasterVolume"] = 1
	MasterVolume.Parent = Volumes
	Volumes.Parent = Player

	local MusicVolume = Instance.new("NumberValue")
	MusicVolume.Name = "MusicVolume"
	PlayerVolumeData[Player.Name]["MusicVolume"] = 1
	MusicVolume.Value = 1
	MusicVolume.Parent = Volumes

	local SFXVolume = Instance.new("NumberValue")
	SFXVolume.Name = "SFXVolume"
	SFXVolume.Value = 1
	PlayerVolumeData[Player.Name]["SFXVolume"] = 1
	SFXVolume.Parent = Volumes

	local VoiceVolume = Instance.new("NumberValue")
	VoiceVolume.Name = "VoiceVolume"
	VoiceVolume.Value = 1
	PlayerVolumeData[Player.Name]["VoiceVolume"] = 1
	VoiceVolume.Parent = Volumes
	
	local Subtitles = Instance.new("BoolValue")
	Subtitles.Name = "Enable Subtitles"
	Subtitles.Value = true
	PlayerVolumeData[Player.Name]["Enable Subtitles"] = true
	Subtitles.Parent = Volumes
	
	if Data then
		PlayerVolumeData[Player.Name]["MasterVolume"] =  Data["MasterVolume"]
		MasterVolume.Value = Data["MasterVolume"]
		PlayerVolumeData[Player.Name]["VoiceVolume"] = Data["VoiceVolume"]
		VoiceVolume.Value = Data["VoiceVolume"]
		SFXVolume.Value = Data["SFXVolume"]
		PlayerVolumeData[Player.Name]["SFXVolume"] =  Data["SFXVolume"]
		MusicVolume.Value = Data["MusicVolume"]
		PlayerVolumeData[Player.Name]["MusicVolume"] =  Data["MusicVolume"]
		Subtitles.Value = Data["Enable Subtitles"]
		PlayerVolumeData[Player.Name]["Enable Subtitles"] =  Data["Enable Subtitles"]
	end
end)

Players.PlayerRemoving:Connect(function(Player)
	SettingsData:SetAsync(Player.UserId.." Volume", PlayerVolumeData[Player.Name])
	PlayerVolumeData[Player.Name] = nil
end)

Remotes.Leave.OnServerEvent:Connect(function(Player)
	SettingsData:SetAsync(Player.UserId.." Volume", PlayerVolumeData[Player.Name])
	--PlayerVolumeData[Player.Name] = nil
	Player:Kick("Bye!")
end)