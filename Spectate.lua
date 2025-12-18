local Spectate = {}

local Players = game:GetService("Players")
local Rep_Storage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Events = Rep_Storage:WaitForChild("Remotes")
local Spectate_Event = Events:WaitForChild("Spectate")
local UpdateAlivePlayers = Events:WaitForChild("UpdateAlive")

local Player = Players.LocalPlayer

local Gui = script.Parent.Parent
local Frame = Gui:WaitForChild("Frame")
local PlayerName = Frame.PlayerName
local RightButton = Frame.Right
local LeftButton = Frame.Left

local Scare_Model = workspace.JumpScare
local Scare_Cam = Scare_Model:WaitForChild("Camera")
local Scare_Cam2 = Scare_Model.Camera2

local Camera = workspace.CurrentCamera

Spectate.Connections = {}
Spectate.CurrentFocus = nil

local function Cam_Tween(Player)

	local Info = TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local Cframe = CFrame.lookAt(Player.Character.Head.Position + Player.Character.Head.CFrame.LookVector * 10, Player.Character.Head.Position)
	local Tween = TweenService:Create(Camera, Info, {CFrame = Cframe})	
	Camera.CameraType = Enum.CameraType.Scriptable
	Tween:Play()
	Tween.Completed:Wait()
	Tween:Destroy()
	Camera.CameraType = Enum.CameraType.Custom
	Camera.CameraSubject = Player.Character

	return
end

Spectate.ChangeFocus = function(FocusPlayer)
	Cam_Tween(FocusPlayer)
	PlayerName.Text = FocusPlayer.Name
end

Spectate.JumpScare = function()
	game.SoundService["HORROR SCREAM 11"]:Play()

	Camera.CameraType = Enum.CameraType.Scriptable

	Camera.CFrame = Scare_Model.Camera.CFrame
	local Tween = TweenService:Create(Camera, TweenInfo.new(0.4), {CFrame = Scare_Cam2.CFrame})
	Tween:Play()
	task.wait(2)
	Camera.CameraType = Enum.CameraType.Custom
end


function Spectate:Setup(Players)
	
	if #Players < 1 then return end
	Frame.Visible = true
	Camera = workspace.CurrentCamera
	self.CurrentFocus = self.CurrentFocus or Players[1]
	if self.CurrentFocus == nil then return end
	self.ChangeFocus(Spectate.CurrentFocus)
	Camera.FieldOfView = 70

	self.Connections["Right"] = RightButton.MouseButton1Click:Connect(function()
		local NewFocus = Players[1]
		for i,v in pairs(Players) do
			if v == Spectate.CurrentFocus then
				if Players[i+1] then
					NewFocus = Players[i+1]
				else
					NewFocus = Players[1]
				end
			end
		end
		self.CurrentFocus = NewFocus
		self.ChangeFocus(self.CurrentFocus)
		--PlayerName.Text = self.CurrentFocus.Text
	end)

	self.Connections["Left"] = LeftButton.MouseButton1Click:Connect(function()
		local NewFocus = Players[1]
		for i,v in pairs(Players) do
			if v == nil then
				continue
			end
			if v == self.CurrentFocus then
				if Players[i-1] then
					NewFocus = Players[i-1]
				else
					NewFocus = Players[#Players]
				end
			end
		end
		self.CurrentFocus = NewFocus
		self.ChangeFocus(self.CurrentFocus)
	end)

	self.Connections["UpdatePlayer"] = UpdateAlivePlayers.OnClientEvent:Connect(function()
		self.Connections.Left:Disconnect()
		self.Connections.Right:Disconnect()

		self:Setup(Players)
	end)
	
	
end

Frame:GetPropertyChangedSignal("Visible"):Connect(function()
	if Frame.Visible then
		require(Rep_Storage.Library.MouseUnlock).Unlock()
	else
		require(Rep_Storage.Library.MouseUnlock).Lock()
	end
end)


return Spectate
