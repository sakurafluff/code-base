local Players = game:GetService("Players")
local Replicatedtorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")


local Remotes = Replicatedtorage:WaitForChild("RemoteEvents")


local JoinGameEvent = Remotes.JoinGame
local JoinPartyEvent = Remotes.JoinParty
local LeaveParty = Remotes.LeaveParty
local Parties = Replicatedtorage.Parties
local StartMatch = Remotes.StartMatch
local CreateParty = Remotes.CreateParty

local Player = Players.LocalPlayer

local GuI = script.Parent
local MainFrame = GuI.MainMenuScreen
local Credits = GuI.Credits
local Settings =  GuI.Settings
local Chapter1 = GuI.Chapter1
local ChapterSelection = GuI.ChapterSelection
local Updates = GuI.Updates
local MapSelection = GuI.MapSelection
local PlayersJoinScreen = GuI.JoinPlayerScreen
local ServerFrame = GuI.ServerFrame
local HostView = GuI.ServerHostView


local FrameHandleFunctions = {}
local Gui_Conections = {}
local Camera = workspace.CurrentCamera
Camera.CameraType = Enum.CameraType.Scriptable
Camera.CFrame = workspace:WaitForChild("CameraPart").CFrame

Player.CharacterAdded:Connect(function()
	
	local Camera = workspace.CurrentCamera
	Camera.CameraType = Enum.CameraType.Scriptable
	Camera.CFrame = workspace:WaitForChild("CameraPart").CFrame
	
	task.spawn(function()
		while task.wait(1) do
			Camera.CameraType = Enum.CameraType.Scriptable
			Camera.CFrame = workspace:WaitForChild("CameraPart").CFrame
		end
	end)
end)

--- utility functions ---

local function ConnectionsResolver()
	for _,Connection in Gui_Conections do
		Connection:Disconnect()
	end
	return
end

local function TweenFrameToMiddle(frame, duration, Finalposition)

	local screenSize = frame.Parent.AbsoluteSize
	local frameSize = frame.AbsoluteSize
	local startPosition = UDim2.new(1, frameSize.X, frame.Position.Y.Scale, frame.Position.Y.Offset) 
	local middlePosition = UDim2.new(0.5, -frameSize.X / 2, frame.Position.Y.Scale, frame.Position.Y.Offset)

	frame.Position = startPosition 

	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local goal = {Position = Finalposition}

	local tween = TweenService:Create(frame, tweenInfo, goal)
	tween:Play()
	return
		
end

---

function FrameHandleFunctions:MainMenu()
	ConnectionsResolver()
	MainFrame.Visible = true
	local Panel = MainFrame.LeftPanel
	local PlayButton = Panel.PlayButton
	local ExitButton = Panel.ExitButton
	local SettingButton = Panel.SettingsButton
	local CreditsButton = Panel.CreditsButton
	local UpdatesButton = Panel.UpdatesButton

	TweenFrameToMiddle(MainFrame, 0.5, MainFrame.Position)

	Gui_Conections["PlayButton"] = PlayButton.TextButton.MouseButton1Down:Connect(function()
		MainFrame.Visible = false
		self:MapSelection()
		return
	end)

	Gui_Conections["SettingButton"] = SettingButton.TextButton.MouseButton1Down:Connect(function()
		MainFrame.Visible = false
		Settings.Visible = true
		self:Settings()
		return
	end)

	Gui_Conections["CreditsButton"] = CreditsButton.TextButton.MouseButton1Down:Connect(function()
		MainFrame.Visible = false
		Credits.Visible = true
		self:Credits()
		return
	end)
	
	Gui_Conections["UpdatesButton"] = UpdatesButton.TextButton.MouseButton1Down:Connect(function()
		MainFrame.Visible = false
		Updates.Visible = true
		print("calling update")
		self:Updates()
		return
	end)
	
	Gui_Conections["Exit"] = ExitButton.ExitButton.MouseButton1Down:Connect(function()
		Remotes.Leave:FireServer()
	end)

	return
end

function FrameHandleFunctions:ChapterSelection(Mode)
	print("called")
	ConnectionsResolver()
	ChapterSelection.Visible = true
	TweenFrameToMiddle(ChapterSelection, 0.5, ChapterSelection.Position)

	local SelectionFrame = ChapterSelection.Frame
	local Chapters =  SelectionFrame.Chapters
	local Chapter1 = Chapters.Chapter1
	--local Chapter2 = Chapters.Chapter2
	--local Chapter3 = Chapters.Chapter3
	--local Chapter4 = Chapters.Chapter4

	local BackButton = SelectionFrame.BackButton

	Gui_Conections["Back"] = BackButton.TextButton.MouseButton1Down:Connect(function()
		ChapterSelection.Visible = false
		self:MapSelection()
		return
	end)

	Gui_Conections["Chapter1"] = Chapter1.ImageButton.MouseButton1Down:Connect(function()
		ChapterSelection.Visible = false
		if Mode == "Single" then
			print("heyyyy")
			Chapter1.Visible = true
			script.Parent.Title.Visible = false
			self:Chapter1()
		elseif Mode == "Multi" then
			local Party = CreateParty:InvokeServer()
			ChapterSelection.Visible = false
			self:HostView()
		end
		
		return
	end)

	return
end

function FrameHandleFunctions:Chapter1()
	ConnectionsResolver()
	Chapter1.Visible = true
	TweenFrameToMiddle(Chapter1, 0.5, Chapter1.Position)
	
	local PlayButton = Chapter1.PlayButton
	local BackButton = Chapter1.MenuButton
	
	Gui_Conections["PlayButton"] = PlayButton.MouseButton1Down:Connect(function()
		JoinGameEvent:FireServer("Chapter1")
		--self:MapSelection()
		return
	end)
	
	Gui_Conections["Back"] = BackButton.MouseButton1Down:Connect(function()
		Chapter1.Visible = false
		self:MapSelection()
		return
	end)
	
	return
end

function FrameHandleFunctions:MapSelection()
	script.Parent.Title.Visible = true
	ConnectionsResolver()
	MapSelection.Visible = true
	TweenFrameToMiddle(MapSelection, 0.5, MapSelection.Position)
	
	local MapOne = MapSelection.MainContent.PaddingFrame.MapOne
	local MapTwo = MapSelection.MainContent.PaddingFrame.MapTwo
	local BackButton = MapSelection.ButtonFrame.Button
	BackButton.Visible = true
	BackButton.CONTINUE.Text = "EXIT"
	
	Gui_Conections["MapOne"] = MapOne.Button.MouseButton1Down:Connect(function()
		MapSelection.Visible = false
		--Chapter1.Visible = true
		self:ChapterSelection("Single")
		return
	end)
	
	Gui_Conections["MapTwo"] = MapTwo.Button.MouseButton1Down:Connect(function()
		MapSelection.Visible = false
		--JoinPartyEvent:FireServer()
		self:ServerSelection()
		return
	end)
	
	Gui_Conections["Back"] = BackButton.MouseButton1Down:Connect(function()
		MapSelection.Visible = false
		self:MainMenu()
		return
	end)
	
	return
end

function FrameHandleFunctions:ServerSelection()
	ConnectionsResolver()
	ServerFrame.Visible = true
	TweenFrameToMiddle(ServerFrame, 0.5, ServerFrame.Position)

	local PartyFrame = ServerFrame.UI.ScrollSection.PaddingFrame.ScrollingFrame
	local CreateButton = ServerFrame.UI.Infosection.PaddingFrame.Button.ButtonFrame.Button
	local BackButton = ServerFrame.ExitButton.ExitButton
	local Parties = game.ReplicatedStorage.Parties
	print(Parties:GetChildren())
	for i,Frame in PartyFrame:GetChildren() do
		if Frame:IsA("Frame") then
			Frame.Visible = false
			print(Frame.Name)
			
		end
	end
	
	local function ServerSetup()
		for i,Frame in PartyFrame:GetChildren() do
			if Frame:IsA("Frame") then
				Frame.Visible = false
				print(Frame.Name)

			end
		end
		local Lobbies = Parties:GetChildren()
		for i, Lobby in Lobbies do
			local Frame = PartyFrame[tostring(i)]
			local JoinButton = Frame.buttonframe.ImageButton
			local HostImage = Frame.HostImage

			Frame.Visible = true
			
			for i,v in Lobby:GetChildren() do
				print(v, v:GetAttribute("Leader"))
				if v:GetAttribute("Leader") == "Host" then
					local Host = Players:FindFirstChild(v.Name)
					local HeadImage = Players:GetUserThumbnailAsync(Host.UserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size420x420)
					HostImage.Image = HeadImage
				end
			end

			Gui_Conections["JoinParty"..i] = JoinButton.MouseButton1Down:Once(function()
				ServerFrame.Visible = false
				local PartySerial = JoinPartyEvent:InvokeServer(Lobby.Name)
				if PartySerial then
					self:PlayerJoinScreen(PartySerial)
				end
				return
			end)
		end
	end
	
	ServerSetup()
	
	Gui_Conections["ChildAdded"] = Parties.ChildAdded:Connect(ServerSetup)
	Gui_Conections["ChildRemoved"] = Parties.ChildRemoved:Connect(ServerSetup)
	
	Gui_Conections["Create Lobby"] = CreateButton.MouseButton1Down:Connect(function()
		ServerFrame.Visible = false
		self:ChapterSelection("Multi")
		return
	end) 
	
	Gui_Conections["Back"] = BackButton.MouseButton1Down:Connect(function()
		ServerFrame.Visible = false
		self:MapSelection()
		return
		
	end)
	
end

function FrameHandleFunctions:PlayerJoinScreen()
	ConnectionsResolver()
	
	local PlayerFrame = PlayersJoinScreen.Players.Scroll.ScrollingFrame
	local PlayersCount = PlayersJoinScreen.PlayersCount
	local StartButton = PlayersJoinScreen.Info.Content.Actions.ButtonFrame.Start
	local BackButton = PlayersJoinScreen.ExitButton.ExitButton
	local Host = PlayersJoinScreen.Info.Content.Host
	
	
	PlayersJoinScreen.Visible = true
	TweenFrameToMiddle(PlayersJoinScreen, 0.5, PlayersJoinScreen.Position)
	local PartySerial = Player:GetAttribute("Party")
	
	local PartyFolder = game.ReplicatedStorage.Parties:WaitForChild(PartySerial)
	
	for i,v in PlayerFrame:GetChildren() do
		if v:IsA("Frame") then
			v.Visible = false 
			
		end
	end
	
	local function SetPlayers()
		for i,v in PlayerFrame:GetChildren() do
			if v:IsA("Frame") then
				v.Visible = false 
			end
		end
		local PartyPlayers = PartyFolder:GetChildren()

		for i, player in PartyPlayers do
			local Player = Players:FindFirstChild(player.Name)
			
			if not Player then return end
			local HeadImage = Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
			
			if player:GetAttribute("Leader") == "Host" then
				Host["@username"].Text = player.Name
			end
			
			PlayerFrame[tostring(i)]["@username"].Text = player.Name
			PlayerFrame[tostring(i)].Visible = true
			PlayerFrame[tostring(i)].PlayerImage.ImageLabel.Image = HeadImage
		end
		PlayersCount.Text = #PartyPlayers.."/5"
		return
	end
	
	SetPlayers()
	
	if PartyFolder[Player.Name]:GetAttribute("Leader") == "Host" then
		StartButton.Visible = true
		StartButton.Text = "START"
		Gui_Conections["StartMatch"] = StartButton.MouseButton1Down:Connect(function()
			StartButton.Text = "Teleporting"
			StartMatch:FireServer()
		end)
	else
		StartButton.Visible = true
		StartButton.Text = "Waiting..."
	end
	
	Gui_Conections["ChildAdded"] = PartyFolder.ChildAdded:Connect(SetPlayers)
	Gui_Conections["ChildRemoved"] = PartyFolder.ChildRemoved:Connect(SetPlayers)
	
	Gui_Conections["Kicked"] = Remotes.Kick.OnClientEvent:Once(function()
		PlayersJoinScreen.Visible = false
		self:ServerSelection()
	end)
	
	Gui_Conections["Back"] = BackButton.MouseButton1Down:Once(function()
		LeaveParty:FireServer()
		task.wait(.8)
		PlayersJoinScreen.Visible = false
		self:ServerSelection()
	end)
end

function FrameHandleFunctions:HostView()
	ConnectionsResolver()

	local PlayerFrame = HostView.Players.Scroll.ScrollingFrame
	local PlayersCount = HostView.PlayersCount
	local StartButton = HostView.Info.Content.Actions.ButtonFrame.Start
	local BackButton = HostView.ExitButton.ExitButton
	local Host = HostView.Info.Content.Host
	
	HostView.Visible = true
	TweenFrameToMiddle(HostView, 0.5, HostView.Position)
	local PartySerial = Player:GetAttribute("Party")

	local PartyFolder = game.ReplicatedStorage.Parties:WaitForChild(PartySerial)

	for i,v in PlayerFrame:GetChildren() do
		if v:IsA("Frame") then
			v.Visible = false 
		end
	end

	local function SetPlayers()
		local Labels = {}
		for i,v in PlayerFrame:GetChildren() do
			if v:IsA("Frame") then
				v.Visible = false 
			end
		end
		local PartyPlayers = PartyFolder:GetChildren()

		for i, player in PartyPlayers do
			local Player = Players:FindFirstChild(player.Name)
			
			if not Player then return end
			local HeadImage = Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)

			if player:GetAttribute("Leader") == "Host" then
				Host["@username"].Text = player.Name
				PlayerFrame[tostring(i)].ButtonFrame.RemoveButton.Visible = false
				for i,v in PlayerFrame:GetChildren() do
					if v:IsA("Frame") then
						v.Visible = false 
					end
				end
				
				PlayerFrame[tostring(i)].Visible = true
				
				for i,v in Labels do
						v.Visible = true 
				end
			end
			
			table.insert(Labels,PlayerFrame[tostring(i)])
			
			Gui_Conections["Kicked"] = PlayerFrame[tostring(i)].ButtonFrame.RemoveButton.MouseButton1Down:Once(function()
				
				Remotes.Kick:FireServer(player.Name)
				
			end)
			
			
			PlayerFrame[tostring(i)]["@username"].Text = player.Name
			PlayerFrame[tostring(i)].Visible = true
			PlayerFrame[tostring(i)].PlayerImage.ImageLabel.Image = HeadImage
		end
		PlayersCount.Text = #PartyPlayers.."/5"
		return
	end

	SetPlayers()
	
	Gui_Conections["StartMatch"] = StartButton.MouseButton1Down:Connect(function()
		StartButton.TextLabel.Text = "Teleporting"
		StartMatch:FireServer()
	end)

	Gui_Conections["ChildAdded"] = PartyFolder.ChildAdded:Connect(SetPlayers)
	Gui_Conections["ChildRemoved"] = PartyFolder.ChildRemoved:Connect(SetPlayers)
	
	Gui_Conections["Back"] = BackButton.MouseButton1Down:Once(function()
		
		LeaveParty:FireServer()
		task.wait(1)
		HostView.Visible = false
		self:ServerSelection()
	end)
	
end

function FrameHandleFunctions:Exit()
	ConnectionsResolver()
	Remotes.Leave:FireServer()
	return
end

function FrameHandleFunctions:Credits()
	ConnectionsResolver()
	local ExitButton = Credits.ExitButton

	Credits.Visible = true
	TweenFrameToMiddle(Credits, 0.5, Credits.Position)

	Gui_Conections["Back"] = ExitButton.ExitButton.MouseButton1Down:Connect(function()
		Credits.Visible = false
		self:MainMenu()
		return
	end)
	
	return
end

function FrameHandleFunctions:Updates()
	ConnectionsResolver()

	Updates.Visible = true
	TweenFrameToMiddle(Updates, 0.5, Updates.Position)
	
	local ExitButton = Updates.ExitButton
	Gui_Conections["Back"] = ExitButton.ExitButton.MouseButton1Down:Connect(function()
		Updates.Visible = false
		self:MainMenu()
	end)
	
	return
end

function FrameHandleFunctions:Settings()
	ConnectionsResolver()

	Settings.Visible = true
	local ExitButton = Settings.ExitButton
	local SoundVolumes = Settings.Volumes
	local ResetButton = Settings.DefaultSetButton.DefaultSetButton
	
	TweenFrameToMiddle(Settings, 0.5, Settings.Position)

	Gui_Conections["Back"] = ExitButton.ExitButton.MouseButton1Down:Connect(function()
		Settings.Visible = false
		local Volumes = {}
		for i,v in SoundVolumes:GetChildren() do
			Volumes[v.Name] = v.Value
		end
		
		Remotes.SetVolume:FireServer(Volumes)
		print(Volumes)
		self:MainMenu()
	end)
	
	local Mouse = Player:GetMouse()
	local Volumes = Player:WaitForChild("Volumes")
	
	for i,v in SoundVolumes:GetChildren() do
		print(SoundVolumes:GetChildren())
		v.Value = Volumes[v.Name].Value
	end
	
	for i,v in Settings.AudioFrame:GetChildren() do
		
		if string.match(v.Name, "Volume") then
			
			local Volume = v
			local Slider = Volume.VolumeSLIDER
			local Fill = Slider.Fill
			local Trigger = Slider.Trigger
			local ValueUi = Volume.MinVol
			local IsActive = false
			
			Fill.Size = UDim2.fromScale(Volumes[v.Name].Value,1)
			ValueUi.Text = tostring(math.floor(Volumes[v.Name].Value*100))
			local function UpdateSlider()
				local Output = math.clamp((Mouse.X-Slider.AbsolutePosition.X)/(Slider.AbsoluteSize.X),0,1)
				Fill.Size = UDim2.fromScale(Output,1)
				SoundVolumes[v.Name].Value = Output
				ValueUi.Text = tostring(math.floor(Output*100))
				return
			end
			
			local function ActiveSlider()
				IsActive = true
				while IsActive do
					UpdateSlider()
					task.wait()
				end
			end
			
			
			Gui_Conections["Trigger"..i] = Trigger.MouseButton1Down:Connect(function()
				ActiveSlider()
			end)

			Gui_Conections["InputEnded"..i] = UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
					IsActive = false
				end

			end)
			
		end
	end
	
	local Subtitles = Settings.AudioFrame["Enable Subtitles"]
	local Option = Subtitles.Option
	--SoundVolumes["Enable Subtitles"] = Volumes[Option.Name].Value
	
	if Volumes["Enable Subtitles"].Value == true then
		Option.Text = "ON"
	else
		Option.Text = "OFF"
	end
	
	Gui_Conections["RightArrow"] = Subtitles.RightArrow.MouseButton1Down:Connect(function()
		if Option.Text == "ON" then
			Option.Text = "OFF"
			SoundVolumes["Enable Subtitles"].Value = false
		elseif Option.Text == "OFF" then
			Option.Text = "ON"
			SoundVolumes["Enable Subtitles"].Value = true
		end
	end)
	Gui_Conections["LeftArrow"] = Subtitles.LeftArrow.MouseButton1Down:Connect(function()
		if Option.Text == "ON" then
			Option.Text = "OFF"
			SoundVolumes["Enable Subtitles"].Value = false
		elseif Option.Text == "OFF" then
			Option.Text = "ON"
			SoundVolumes["Enable Subtitles"].Value = true
		end
	end)
	
	Gui_Conections["Reset"] = ResetButton.MouseButton1Down:Connect(function()
		
		for i,v in Settings.AudioFrame:GetChildren() do
			if string.match(v.Name, "Volume") then
				local Volume = v
				local Slider = Volume.VolumeSLIDER
				local Fill = Slider.Fill
				local ValueUi = Volume.MinVol
				local Output = 1
				Fill.Size = UDim2.fromScale(Output,1)
				SoundVolumes[v.Name].Value = Output
				ValueUi.Text = tostring(math.floor(Output*100))	
			end
		end
		
		Option.Text = "ON"
		SoundVolumes["Enable Subtitles"].Value = true
		return
	end)
	
	return
end



FrameHandleFunctions:MainMenu()
