--[[
    Muscle Legends
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = workspace
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local function notify(title, text)
	pcall(function()
		StarterGui:SetCore("SendNotification", {Title = tostring(title), Text = tostring(text), Duration = 5})
	end)
end

LocalPlayer.Idled:Connect(function()
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new())
end)

-- ==========================================
-- VOID UI
-- ==========================================
local VoidUI
do
	local ok, err = pcall(function()
		VoidUI = loadstring(game:HttpGet(
			"https://raw.githubusercontent.com/slowzzx4-8/Ui-library/refs/heads/main/Void%20Ui%20Library.lua",
			true
		))()
	end)
	if not ok or not VoidUI or type(VoidUI) ~= "table" or not VoidUI.CreateWindow then
		notify("Muscle Legends", "UI failed: " .. tostring(err))
		warn("[Muscle Legends] UI failed:", err)
		return
	end
end

local Window = VoidUI:CreateWindow({
	Name = "Muscle Legends",
	Theme = "Dark",
	ToggleKey = Enum.KeyCode.RightControl,
})

pcall(function()
	Window:EditOpenButton({ Title = "Muscle Legends", Transparency = 0.2 })
end)
pcall(function() if Window.Open then Window:Open() end end)

notify("Muscle Legends", "Loaded")

-- ==========================================
-- HELPERS
-- ==========================================
local function formatNumber(n)
	if type(n) ~= "number" then return tostring(n) end
	if n >= 1e18 then return string.format("%.1fqi", n / 1e18)
	elseif n >= 1e15 then return string.format("%.1fqa", n / 1e15)
	elseif n >= 1e12 then return string.format("%.1ft", n / 1e12)
	elseif n >= 1e9 then return string.format("%.1fb", n / 1e9)
	elseif n >= 1e6 then return string.format("%.1fm", n / 1e6)
	elseif n >= 1e3 then return string.format("%.1fk", n / 1e3)
	else return tostring(math.floor(n)) end
end

local function formatWithCommas(n)
	local s = tostring(math.floor(tonumber(n) or 0))
	while true do
		local ns, c = s:gsub("^(-?%d+)(%d%d%d)", "%1.%2")
		s = ns
		if c == 0 then break end
	end
	return s
end

local function char() return LocalPlayer.Character end
local function hum() local c = char() return c and c:FindFirstChildOfClass("Humanoid") end
local function root() local c = char() return c and c:FindFirstChild("HumanoidRootPart") end
local function muscleEv() return LocalPlayer:FindFirstChild("muscleEvent") end

local function fireRep()
	local e = muscleEv()
	if e then pcall(function() e:FireServer("rep") end) end
end

local function firePunch()
	local e = muscleEv()
	if not e then return end
	pcall(function()
		e:FireServer("punch", "leftHand")
		e:FireServer("punch", "rightHand")
	end)
end

local function equipPunch()
	local c, h = char(), hum()
	if not c or not h then return end
	local t = c:FindFirstChild("Punch") or LocalPlayer.Backpack:FindFirstChild("Punch")
	if t and t.Parent ~= c then pcall(function() h:EquipTool(t) end) end
end

local function safeTouch(a, b, t)
	if firetouchinterest then pcall(function() firetouchinterest(a, b, t) end) end
end

local function isAlive(p)
	return p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0
end

local function isProtected(p)
	if not p or not p.Character then return false end
	if p.Character:FindFirstChildOfClass("ForceField") or p.Character:FindFirstChild("spawnProtectionHighlight") then return true end
	local u = p.Character:GetAttribute("SpawnProtectedUntil")
	return typeof(u) == "number" and Workspace:GetServerTimeNow() < u
end

local Suffixes = {K=3,M=6,B=9,T=12,Qa=15,Qi=18,Sx=21,Sp=24,Oc=27,No=30,Dc=33}
local function ParseValue(str)
	if not str then return 0 end
	str = string.gsub(tostring(str), ",", "")
	local numStr, suffix = string.match(str, "^([%d%.]+)(%a*)")
	local num = tonumber(numStr)
	if not num then return 0 end
	if suffix and Suffixes[suffix] then num = num * (10 ^ Suffixes[suffix]) end
	return num
end

local function getStrength(p)
	local s = p:FindFirstChild("leaderstats")
	return ParseValue(s and s:FindFirstChild("Strength") and s.Strength.Value or 0)
end

pcall(function()
	for _, o in pairs(game:GetDescendants()) do
		if o.Name == "RobloxForwardPortals" then o:Destroy() end
	end
	game.DescendantAdded:Connect(function(d)
		if d.Name == "RobloxForwardPortals" then d:Destroy() end
	end)
end)

local State = {
	Size = 2, Speed = 120, FOV = 70,
	SetSize = false, SetSpeed = false, SetFOV = false,
	AntiFling = true, LockPos = false, LockPosVec = nil,
	HidePets = true, HidePopups = true, WalkWater = true,
	InfJump = false, SpinFortune = false,
	KillAll = false, FarmEvil = false, FarmGood = false, KillList = false,
	WhitelistFriends = false, DeathRing = false, ShowRing = false, RingRange = 20,
	AutoRebirth = false, RebirthTarget = 0, AutoSize1 = false, AutoKing = false,
	Exercise = "Weight", AutoExercise = false, AutoSquat = false, AutoLift = false,
	SelectedSquat = nil, SelectedLift = nil, AutoRep = false,
	AutoRock = false, SelectedRock = nil,
	PushupIndustrial = false, PushupJungle = false, PushupKing = false, PushupLegends = false,
	AutoBoss = false, ContinueBoss = true,
	AutoBuyPet = false, AutoBuyAura = false, AutoEvolve = false, AutoTrade = false,
	EatEggs = false, EatBoosts = false, AutoBrawl = false,
	Spectate = false, SpectatePlayer = nil,
	Whitelist = {}, Killlist = {},
	SelectedPets = {}, SelectedAuras = {}, EvolvePets = {},
	TradePlayers = {}, TradePets = {},
	PetBuyAmt = 1, AuraBuyAmt = 1, EvolveAmt = 1,
	SelectedBosses = {},
}

local RockData = {
	["Tiny Rock - 0 Dura"] = 0, ["Large Rock - 100 Dura"] = 100, ["Punching Rock - 10 Dura"] = 10,
	["Golden Rock - 5k Dura"] = 5000, ["Frost Rock - 150k Dura"] = 150000, ["Mythical Rock - 400k Dura"] = 400000,
	["Eternal Rock - 750k Dura"] = 750000, ["Legend Rock - 1m Dura"] = 1000000, ["Muscle King Rock - 5m Dura"] = 5000000,
	["Jungle Rock - 10m Dura"] = 10000000, ["Industrial Rock - 25m Dura"] = 25000000,
}

local Teleports = {
	["Tiny Island"] = CFrame.new(-37.1, 9.2, 1919),
	["Main Island"] = CFrame.new(16.07, 9.08, 133.8),
	["Beach"] = CFrame.new(-8, 9, -169.2),
	["Overcharged Gym"] = CFrame.new(-2941.766, 151.797, 4994.552),
	["Industrial Gym"] = CFrame.new(-5254.681641, 58.342850, 4931.850586),
	["Jungle Gym"] = CFrame.new(-8543, 6.8, 2400),
	["Muscle King Gym"] = CFrame.new(-8665.4, 17.21, -5792.9),
	["Legends Gym"] = CFrame.new(4516, 991.5, -3856),
	["Infernal Gym"] = CFrame.new(-6759, 7.36, -1284),
	["Mythical Gym"] = CFrame.new(2250, 7.37, 1073.2),
	["Frost Gym"] = CFrame.new(-2623, 7.36, -409),
}

local KingPos = CFrame.new(-8665.4, 17.21, -5792.9)

local function inList(list, name)
	for _, n in ipairs(list) do if n:lower() == name:lower() then return true end end
	return false
end

local function addUnique(list, name)
	if not inList(list, name) then table.insert(list, name) end
end

local function removeName(list, name)
	for i = #list, 1, -1 do if list[i]:lower() == name:lower() then table.remove(list, i) end end
end

local function toggleList(list, value)
	if inList(list, value) then removeName(list, value) else table.insert(list, value) end
end

local function isWL(p) return inList(State.Whitelist, p.Name) end
local function isBL(p) return inList(State.Killlist, p.Name) end

local function matchKarma(p, evil, good)
	local g, e = p:FindFirstChild("goodKarma"), p:FindFirstChild("evilKarma")
	if not g or not e then return false end
	local gv, ev = g.Value or 0, e.Value or 0
	if gv + ev < 5 then return false end
	return (evil and gv > ev) or (good and ev > gv)
end

local function posNear(target, h)
	if not isAlive(target) or isProtected(target) or isProtected(LocalPlayer) then return false end
	local lr, tr = root(), target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	if not lr or not tr then return false end
	lr.CFrame = tr.CFrame * CFrame.new(0, h or 3.5, 0)
	lr.AssemblyLinearVelocity = Vector3.zero
	lr.AssemblyAngularVelocity = Vector3.zero
	return true
end

local function touchPunch(target, h)
	if not posNear(target, h) then return false end
	RunService.Heartbeat:Wait()
	if not posNear(target, h) then return false end
	local c = char()
	local tr = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	if not c or not tr then return false end
	local hand = c:FindFirstChild("LeftHand") or c:FindFirstChild("RightHand")
	if not hand then return false end
	equipPunch()
	safeTouch(tr, hand, 0) safeTouch(tr, hand, 1)
	firePunch()
	return true
end

local function attackDur(target, dur, cont, h)
	local t0 = os.clock()
	while os.clock() - t0 < dur and (not cont or cont()) and isAlive(target) and not isProtected(target) do
		if posNear(target, h or 3.5) then
			local c = char()
			local tr = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
			local L = c and c:FindFirstChild("LeftHand")
			local R = c and c:FindFirstChild("RightHand")
			equipPunch()
			if tr and L and R then
				safeTouch(tr, L, 0) safeTouch(tr, L, 1)
				safeTouch(tr, R, 0) safeTouch(tr, R, 1)
				firePunch()
			end
		end
		RunService.Heartbeat:Wait()
	end
end

-- Anti fling
local function enableAF()
	local r = root()
	if not r then return end
	local old = r:FindFirstChild("BodyVelocity")
	if old and old.MaxForce == Vector3.new(100000, 0, 100000) then old:Destroy() end
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(100000, 0, 100000)
	bv.Velocity = Vector3.zero
	bv.P = 1250
	bv.Parent = r
end

local function disableAF()
	local r = root()
	if not r then return end
	local bv = r:FindFirstChild("BodyVelocity")
	if bv and bv.MaxForce == Vector3.new(100000, 0, 100000) then bv:Destroy() end
end

LocalPlayer.CharacterAdded:Connect(function(c)
	c:WaitForChild("HumanoidRootPart", 5)
	if State.AntiFling then enableAF() end
	if State.LockPos and c:FindFirstChild("HumanoidRootPart") then
		State.LockPosVec = c.HumanoidRootPart.Position
	end
end)

task.spawn(function()
	while true do
		if State.SetSize then pcall(function() ReplicatedStorage.rEvents.changeSpeedSizeRemote:InvokeServer("changeSize", State.Size) end) end
		if State.SetSpeed then pcall(function() ReplicatedStorage.rEvents.changeSpeedSizeRemote:InvokeServer("changeSpeed", State.Speed) end) end
		if State.SetFOV and Camera then Camera.FieldOfView = State.FOV end
		if State.LockPos and State.LockPosVec then
			local r = root()
			if r then
				local bp = r:FindFirstChild("PositionLocker")
				if bp then bp.Position = State.LockPosVec
				else
					disableAF()
					bp = Instance.new("BodyPosition")
					bp.Name = "PositionLocker"
					bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
					bp.Position = State.LockPosVec
					bp.P = 100000
					bp.Parent = r
				end
			end
		end
		task.wait(0.05)
	end
end)

UserInputService.JumpRequest:Connect(function()
	if State.InfJump then
		local h = hum()
		if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

-- Water
task.spawn(function()
	local parts = {}
	local ps, td = 2048, 40000
	local st = Vector3.new(-2, -9.5, -2)
	for x = 0, math.ceil(td/ps)-1 do
		for z = 0, math.ceil(td/ps)-1 do
			for _, o in ipairs({{x*ps,z*ps},{-x*ps,z*ps},{-x*ps,-z*ps},{x*ps,-z*ps}}) do
				local p = Instance.new("Part")
				p.Size = Vector3.new(ps, 1, ps)
				p.Position = st + Vector3.new(o[1], 0, o[2])
				p.Anchored = true
				p.Transparency = 1
				p.CanCollide = true
				p.Name = "MLWater"
				p.Parent = Workspace
				table.insert(parts, p)
			end
		end
	end
	_G.MLWater = parts
end)

-- Kill loops
task.spawn(function()
	while true do
		if State.KillAll then
			for _, p in ipairs(Players:GetPlayers()) do
				if not State.KillAll then break end
				if p ~= LocalPlayer and not isWL(p) and isAlive(p) and not isProtected(p) then
					attackDur(p, 4, function() return State.KillAll and not isWL(p) end, 3.5)
				end
			end
			task.wait(0.05)
		else task.wait(0.2) end
	end
end)

task.spawn(function()
	while true do
		if State.FarmEvil or State.FarmGood then
			for _, p in ipairs(Players:GetPlayers()) do
				if not (State.FarmEvil or State.FarmGood) then break end
				if p ~= LocalPlayer and not isWL(p) and isAlive(p) and not isProtected(p)
					and matchKarma(p, State.FarmEvil, State.FarmGood) then
					local hits = 0
					while hits < 4 and isAlive(p) and not isProtected(p)
						and matchKarma(p, State.FarmEvil, State.FarmGood)
						and (State.FarmEvil or State.FarmGood) do
						if touchPunch(p, 3.5) then hits += 1 end
						task.wait(0.05)
					end
				end
			end
			task.wait(0.05)
		else task.wait(0.2) end
	end
end)

task.spawn(function()
	while true do
		if State.KillList then
			local target
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= LocalPlayer and isBL(p) and isAlive(p) and not isProtected(p) then target = p break end
			end
			if target then
				while State.KillList and isBL(target) and isAlive(target) and not isProtected(target) do
					touchPunch(target, 10)
					task.wait(0.05)
				end
			else task.wait(0.1) end
		else task.wait(0.2) end
	end
end)

-- Death ring
local RingPart
task.spawn(function()
	while true do
		if State.DeathRing then
			local r = root()
			if r then
				if State.ShowRing then
					if not RingPart or not RingPart.Parent then
						RingPart = Instance.new("Part")
						RingPart.Name = "MLRing"
						RingPart.Shape = Enum.PartType.Cylinder
						RingPart.Material = Enum.Material.Neon
						RingPart.Color = Color3.fromRGB(138, 0, 0)
						RingPart.Transparency = 0.6
						RingPart.Anchored = true
						RingPart.CanCollide = false
						RingPart.CanTouch = false
						RingPart.CanQuery = false
						RingPart.CastShadow = false
						RingPart.Parent = Workspace
					end
					RingPart.Size = Vector3.new(0.2, State.RingRange * 2, State.RingRange * 2)
					RingPart.CFrame = r.CFrame * CFrame.Angles(0, 0, math.rad(90))
				elseif RingPart then RingPart:Destroy() RingPart = nil end
				local center = r.CFrame
				for _, p in ipairs(Players:GetPlayers()) do
					if not State.DeathRing then break end
					local tr = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
					if p ~= LocalPlayer and not isWL(p) and isAlive(p) and not isProtected(p)
						and tr and (center.Position - tr.Position).Magnitude <= State.RingRange then
						local hits = 0
						while hits < 4 and State.DeathRing and isAlive(p) and not isProtected(p) do
							local ctr = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
							if not ctr or (center.Position - ctr.Position).Magnitude > State.RingRange then break end
							if touchPunch(p, 3.5) then hits += 1 end
							local lr = root()
							if lr then lr.CFrame = center; lr.AssemblyLinearVelocity = Vector3.zero end
							RunService.Heartbeat:Wait()
						end
					end
				end
			end
			task.wait(0.05)
		else
			if RingPart then RingPart:Destroy() RingPart = nil end
			task.wait(0.2)
		end
	end
end)

-- Farming loops
task.spawn(function()
	while true do
		if State.AutoRebirth and State.RebirthTarget > 0 then
			local rb = LocalPlayer.leaderstats and LocalPlayer.leaderstats:FindFirstChild("Rebirths")
			if rb and rb.Value < State.RebirthTarget then
				pcall(function() ReplicatedStorage.rEvents.rebirthRemote:InvokeServer("rebirthRequest") end)
			else State.AutoRebirth = false end
			task.wait(0.05)
		else task.wait(0.3) end
	end
end)

task.spawn(function()
	while true do
		if State.AutoSize1 then pcall(function() ReplicatedStorage.rEvents.changeSpeedSizeRemote:InvokeServer("changeSize", 1) end) end
		task.wait(0.05)
	end
end)

task.spawn(function()
	while true do
		if State.AutoKing then
			local r, h = root(), hum()
			if r and h and h.Health > 0 and (r.Position - KingPos.Position).Magnitude > 5 then
				pcall(function() r.CFrame = KingPos end)
			end
			task.wait(0.1)
		else task.wait(0.3) end
	end
end)

task.spawn(function()
	while true do
		if State.AutoExercise and State.Exercise then
			local c, h = char(), hum()
			if c and h and h.Health > 0 then
				if not c:FindFirstChild(State.Exercise) then
					local t = LocalPlayer.Backpack:FindFirstChild(State.Exercise)
					if t then pcall(function() h:EquipTool(t) end) task.wait(0.2) end
				end
				if c:FindFirstChild(State.Exercise) then fireRep() end
			end
			task.wait()
		else task.wait(0.2) end
	end
end)

task.spawn(function()
	while true do
		if State.AutoRep then fireRep() task.wait(0.1) else task.wait(0.3) end
	end
end)

-- Machine exercise (squat/lift)
local function getInteract(machine)
	for _, d in ipairs(machine:GetDescendants()) do
		if d:IsA("BasePart") and string.lower(d.Name) == "interactseat" then return d end
	end
end

local function enterMachine(machine)
	if not machine or not machine.Parent then return false end
	local r = root()
	local part = getInteract(machine)
	if not r or not part then return false end
	r.CFrame = part.CFrame * CFrame.new(0, 3, 0)
	r.AssemblyLinearVelocity = Vector3.zero
	task.wait(0.4)
	VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
	task.wait(0.1)
	VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
	task.wait(0.4)
	return true
end

local SquatChoices, LiftChoices = {}, {}
local SquatNames, LiftNames = {}, {}
pcall(function()
	local folder = Workspace:WaitForChild("machinesFolder", 5)
	if not folder then return end
	local squatsByName = {}
	for _, m in ipairs(folder:GetChildren()) do
		local ln = string.lower(m.Name)
		if string.find(ln, "squat", 1, true) and ln ~= "squat rack" then
			squatsByName[m.Name] = squatsByName[m.Name] or {}
			table.insert(squatsByName[m.Name], m)
		elseif string.find(ln, "lift", 1, true) and ln ~= "deadlift" then
			LiftChoices[m.Name] = m
			table.insert(LiftNames, m.Name)
		end
	end
	for n, list in pairs(squatsByName) do
		SquatChoices[n] = list[1]
		table.insert(SquatNames, n)
	end
	table.sort(SquatNames)
	table.sort(LiftNames)
end)

local machineState = {
	Squat = {Running = false, Active = nil, Seat = nil, Reenter = 0},
	Lift = {Running = false, Active = nil, Seat = nil, Reenter = 0},
}

local function runMachine(kind, choices)
	local ms = machineState[kind]
	task.spawn(function()
		local lastChar = char()
		while ms.Running do
			local c, h = char(), hum()
			if c ~= lastChar then
				lastChar = c
				ms.Active = nil
				ms.Seat = nil
				ms.Reenter = os.clock() + 3.5
			end
			if not c or not h or h.Health <= 0 then
				ms.Active = nil
				ms.Seat = nil
				ms.Reenter = math.max(ms.Reenter, os.clock() + 3.5)
				task.wait(0.1)
			else
				local st = h:GetState()
				if ms.Active and (st == Enum.HumanoidStateType.Jumping or st == Enum.HumanoidStateType.Freefall
					or (ms.Seat and h.SeatPart ~= ms.Seat)) then
					ms.Active = nil
					ms.Seat = nil
					ms.Reenter = os.clock() + 3.5
				end
				local selected = (kind == "Squat" and State.SelectedSquat and SquatChoices[State.SelectedSquat])
					or (kind == "Lift" and State.SelectedLift and LiftChoices[State.SelectedLift])
				if selected and not ms.Active and os.clock() >= ms.Reenter then
					if enterMachine(selected) then
						ms.Active = selected
						ms.Seat = h.SeatPart
					end
				end
				if ms.Active then fireRep() end
				task.wait(0.1)
			end
		end
	end)
end

task.spawn(function()
	while true do
		if State.AutoRock and State.SelectedRock and RockData[State.SelectedRock] then
			local dura = LocalPlayer:FindFirstChild("Durability")
			if dura and dura.Value >= RockData[State.SelectedRock] then
				local folder = Workspace:FindFirstChild("machinesFolder")
				if folder then
					for _, v in pairs(folder:GetDescendants()) do
						if v.Name == "neededDurability" and v.Value == RockData[State.SelectedRock]
							and v.Parent and v.Parent:FindFirstChild("Rock") then
							local L = char() and char():FindFirstChild("LeftHand")
							local R = char() and char():FindFirstChild("RightHand")
							if L and R then
								safeTouch(v.Parent.Rock, R, 0) safeTouch(v.Parent.Rock, R, 1)
								safeTouch(v.Parent.Rock, L, 0) safeTouch(v.Parent.Rock, L, 1)
								equipPunch() firePunch()
							end
						end
					end
				end
			end
			task.wait(0.12)
		else task.wait(0.3) end
	end
end)

-- Better strength configs
local StrengthConfigs = {
	{key = "PushupIndustrial", tool = "Pushups", rock = "Industrial Rock"},
	{key = "PushupJungle", tool = "Pushups", rock = "Ancient Jungle Rock"},
	{key = "PushupKing", tool = "Pushups", rock = "Muscle King Mountain"},
	{key = "PushupLegends", tool = "Pushups", rock = "Rock Of Legends"},
}

for _, cfg in ipairs(StrengthConfigs) do
	task.spawn(function()
		while true do
			if State[cfg.key] then
				local c, h = char(), hum()
				if c and h then
					if LocalPlayer.Backpack:FindFirstChild(cfg.tool) and not c:FindFirstChild(cfg.tool) then
						pcall(function() h:EquipTool(LocalPlayer.Backpack[cfg.tool]) end)
					end
					fireRep()
					local folder = Workspace:FindFirstChild("machinesFolder")
					if folder and folder:FindFirstChild(cfg.rock) and c:FindFirstChild("LeftHand") then
						safeTouch(folder[cfg.rock].Rock, c.LeftHand, 0)
						safeTouch(folder[cfg.rock].Rock, c.LeftHand, 1)
					end
					if LocalPlayer.Backpack:FindFirstChild("Punch") then
						pcall(function() h:EquipTool(LocalPlayer.Backpack.Punch) end)
						firePunch()
					end
					RunService.RenderStepped:Wait()
					if LocalPlayer.Backpack:FindFirstChild(cfg.tool) then
						pcall(function() h:EquipTool(LocalPlayer.Backpack[cfg.tool]) end)
					end
				else task.wait(0.1) end
			else task.wait(0.3) end
		end
	end)
end

task.spawn(function()
	while true do
		if State.SpinFortune then
			pcall(function()
				local remote = ReplicatedStorage.rEvents:FindFirstChild("openFortuneWheelRemote")
				local chances = ReplicatedStorage.shared.catalogs.fortuneWheelChances["Fortune Wheel"]
				if remote and chances then remote:InvokeServer("openFortuneWheel", chances) end
			end)
			task.wait(1)
		else task.wait(0.5) end
	end
end)

-- Boss
local function findBoss()
	for _, c in ipairs(CollectionService:GetTagged("BossEventBoss")) do
		if c:IsA("Model") and c:IsDescendantOf(Workspace) then
			local hitbox = c:FindFirstChild("BossDamageHitbox", true)
			if hitbox and hitbox:IsA("BasePart") then
				local stats = c:FindFirstChild("stats")
				local health = stats and stats:FindFirstChild("Health")
				local hp = health and health.Value or Workspace:GetAttribute("BossHealth") or 0
				if typeof(hp) == "number" and hp > 0 then return c, hitbox, health, stats end
			end
		end
	end
end

task.spawn(function()
	while true do
		if State.AutoBoss then
			local model, hitbox = findBoss()
			if model and hitbox then
				local allow = true
				if next(State.SelectedBosses) then
					allow = State.SelectedBosses[model.Name] == true
				end
				if allow then
					local c, r, h = char(), root(), hum()
					if r and h and h.Health > 0 then
						local head = model:FindFirstChild("Head", true)
						local center = (head and head:IsA("BasePart") and head.Position)
							or (hitbox.Position + Vector3.new(0, hitbox.Size.Y * 0.35, 0))
						r.CFrame = CFrame.lookAt(center, center + hitbox.CFrame.LookVector)
						r.AssemblyLinearVelocity = Vector3.zero
						equipPunch()
						local L = c and c:FindFirstChild("LeftHand")
						local R = c and c:FindFirstChild("RightHand")
						if L then safeTouch(hitbox, L, 0) safeTouch(hitbox, L, 1) end
						if R then safeTouch(hitbox, R, 0) safeTouch(hitbox, R, 1) end
						firePunch()
					end
					task.wait(0.03)
				else task.wait(0.25) end
			else task.wait(0.25) end
		else task.wait(0.3) end
	end
end)

-- Pets / boosts / trade
task.spawn(function()
	while true do
		if State.AutoBuyPet and #State.SelectedPets > 0 then
			pcall(function()
				local folder = ReplicatedStorage.shared.runtime.cPetShopFolder
				local remote = ReplicatedStorage.rEvents.cPetShopRemote
				for _, name in ipairs(State.SelectedPets) do
					local item = folder:FindFirstChild(name)
					if item then
						for _ = 1, State.PetBuyAmt do
							task.spawn(function() pcall(function() remote:InvokeServer(item) end) end)
						end
					end
				end
			end)
			task.wait(0.15)
		else task.wait(0.4) end
	end
end)

task.spawn(function()
	while true do
		if State.AutoBuyAura and #State.SelectedAuras > 0 then
			pcall(function()
				local folder = ReplicatedStorage.shared.runtime.cPetShopFolder
				local remote = ReplicatedStorage.rEvents.cPetShopRemote
				for _, name in ipairs(State.SelectedAuras) do
					local item = folder:FindFirstChild(name)
					if item then
						for _ = 1, State.AuraBuyAmt do
							task.spawn(function() pcall(function() remote:InvokeServer(item) end) end)
						end
					end
				end
			end)
			task.wait(0.15)
		else task.wait(0.4) end
	end
end)

task.spawn(function()
	while true do
		if State.AutoEvolve and #State.EvolvePets > 0 then
			for _, name in ipairs(State.EvolvePets) do
				for _ = 1, State.EvolveAmt do
					pcall(function() ReplicatedStorage.rEvents.petEvolveEvent:FireServer("evolvePet", name) end)
				end
			end
			task.wait(0.5)
		else task.wait(0.5) end
	end
end)

task.spawn(function()
	while true do
		if State.AutoTrade and #State.TradePlayers > 0 and #State.TradePets > 0 then
			for _, username in ipairs(State.TradePlayers) do
				if not State.AutoTrade then break end
				local tp = Players:FindFirstChild(username)
				if tp then
					pcall(function()
						local ev = ReplicatedStorage.rEvents.tradingEvent
						ev:FireServer("sendTradeRequest", tp)
						task.wait(0.5)
						local unique = LocalPlayer.petsFolder.Unique
						local offered, offeredPets = 0, {}
						repeat
							local added = false
							for _, sel in ipairs(State.TradePets) do
								for _, pet in ipairs(unique:GetChildren()) do
									if pet.Name == sel and not offeredPets[pet] then
										ev:FireServer("offerItem", pet)
										offeredPets[pet] = true
										offered += 1
										added = true
										task.wait(0.01)
										break
									end
								end
								if offered >= 6 then break end
							end
						until offered >= 6 or not added or not State.AutoTrade
						task.wait(0.05)
						if State.AutoTrade then ev:FireServer("acceptTrade") task.wait(2) end
					end)
				end
			end
			task.wait(2)
		else task.wait(1) end
	end
end)

task.spawn(function()
	while true do
		if State.EatEggs then
			local t = (char() and char():FindFirstChild("Protein Egg")) or LocalPlayer.Backpack:FindFirstChild("Protein Egg")
			if t then pcall(function() muscleEv():FireServer("proteinEgg", t) end) end
			task.wait(0.25)
		else task.wait(0.5) end
	end
end)

task.spawn(function()
	local items = {"Tropical Shake","Energy Shake","Protein Bar","TOUGH Bar","Protein Shake","ULTRA Shake","Energy Bar"}
	while true do
		if State.EatBoosts then
			for _, name in ipairs(items) do
				local t = (char() and char():FindFirstChild(name)) or LocalPlayer.Backpack:FindFirstChild(name)
				if t then
					local parts = {}
					for w in name:gmatch("%S+") do table.insert(parts, w:lower()) end
					for i = 2, #parts do parts[i] = parts[i]:sub(1,1):upper() .. parts[i]:sub(2) end
					for _ = 1, 10 do pcall(function() muscleEv():FireServer(table.concat(parts), t) end) end
				end
			end
			task.wait(0.15)
		else task.wait(0.5) end
	end
end)

-- Brawl
local BrawlAreas = {
	{Pos = Vector3.new(4465, 177, -8851), Size = Vector3.new(552, 400, 548)},
	{Pos = Vector3.new(-1856.5, 175, -6315), Size = Vector3.new(499, 400, 496)},
	{Pos = Vector3.new(978, 177, -7433), Size = Vector3.new(502, 400, 504)},
}
local function inBrawl(pos)
	for _, a in ipairs(BrawlAreas) do
		local o = pos - a.Pos
		local h = a.Size / 2
		if math.abs(o.X) <= h.X and math.abs(o.Y) <= h.Y and math.abs(o.Z) <= h.Z then return true end
	end
	return false
end

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "MLBrawlESP"
pcall(function()
	if gethui then ESPFolder.Parent = gethui() else ESPFolder.Parent = CoreGui end
end)
if not ESPFolder.Parent then ESPFolder.Parent = CoreGui end

local function updESP(p, weak)
	local e = ESPFolder:FindFirstChild(p.Name)
	if not e then
		e = Instance.new("Folder")
		e.Name = p.Name
		e.Parent = ESPFolder
		local hl = Instance.new("Highlight")
		hl.Name = "Highlight"
		hl.FillTransparency = 0.5
		hl.Parent = e
		local bg = Instance.new("BillboardGui")
		bg.Name = "NameTag"
		bg.Size = UDim2.new(0, 100, 0, 25)
		bg.StudsOffset = Vector3.new(0, 2.5, 0)
		bg.AlwaysOnTop = true
		local txt = Instance.new("TextLabel")
		txt.Size = UDim2.new(1, 0, 1, 0)
		txt.BackgroundTransparency = 1
		txt.TextColor3 = Color3.new(1, 1, 1)
		txt.TextStrokeTransparency = 0
		txt.Font = Enum.Font.GothamBold
		txt.TextSize = 14
		txt.Parent = bg
		bg.Parent = e
	end
	local hl = e:FindFirstChild("Highlight")
	if hl then hl.Adornee = p.Character; hl.FillColor = weak and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0) end
	local bg = e:FindFirstChild("NameTag")
	if bg then
		bg.Adornee = p.Character and p.Character:FindFirstChild("Head")
		local t = bg:FindFirstChildOfClass("TextLabel")
		if t then t.Text = p.Name end
	end
end

task.spawn(function()
	while true do
		if State.AutoBrawl then
			pcall(function() ReplicatedStorage.rEvents.brawlEvent:FireServer("joinBrawl") end)
			task.wait(2)
		else task.wait(0.5) end
	end
end)

task.spawn(function()
	local aggro = {}
	while true do
		if State.AutoBrawl then
			local c, r, h = char(), root(), hum()
			if c and r and h and h.Health > 0 then
				local myPos = r.Position
				local myMap = LocalPlayer:FindFirstChild("currentMap") and LocalPlayer.currentMap.Value
				local myStr = getStrength(LocalPlayer)
				if inBrawl(myPos) then
					local miu = LocalPlayer:FindFirstChild("machineInUse")
					if miu and miu.Value ~= nil then h.Jump = true end
					for _, p in ipairs(Players:GetPlayers()) do
						if p ~= LocalPlayer and isAlive(p) and inBrawl(p.Character.HumanoidRootPart.Position) then
							aggro[p] = true
						end
					end
					local weakT, strongT = nil, nil
					local dW, dS = math.huge, math.huge
					local cur = {}
					for p, _ in pairs(aggro) do
						if p.Parent and isAlive(p) then
							local tm = p:FindFirstChild("currentMap") and p.currentMap.Value
							if tm == myMap then
								local weak = getStrength(p) < myStr
								updESP(p, weak)
								cur[p.Name] = true
								local d = (myPos - p.Character.HumanoidRootPart.Position).Magnitude
								if weak then if d < dW then dW = d; weakT = p.Character end
								else if d < dS then dS = d; strongT = p.Character end end
							else aggro[p] = nil end
						else aggro[p] = nil end
					end
					for _, e in ipairs(ESPFolder:GetChildren()) do
						if not cur[e.Name] then e:Destroy() end
					end
					local alvo = weakT or strongT
					if alvo and alvo:FindFirstChild("HumanoidRootPart") then
						pcall(function() c:SetPrimaryPartCFrame(alvo.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)) end)
						equipPunch()
						local punch = c:FindFirstChild("Punch")
						if punch then pcall(function() punch:Activate() end) end
						for _ = 1, 4 do firePunch() end
					end
				else
					aggro = {}
					ESPFolder:ClearAllChildren()
				end
			end
			task.wait(0.05)
		else
			ESPFolder:ClearAllChildren()
			task.wait(0.3)
		end
	end
end)

task.spawn(function()
	while true do
		if State.AutoBrawl then
			pcall(function()
				local gui = LocalPlayer.PlayerGui:FindFirstChild("gameGui")
				if gui then
					local sb = gui:FindFirstChild("survivorBonusLabel")
					local nb = gui:FindFirstChild("noBrawlersLabel")
					if (sb and sb.Visible) and not (nb and nb.Visible) then
						local h = hum()
						if h and h.Health > 0 then h.Health = 0 task.wait(5) end
					end
				end
			end)
			task.wait(0.5)
		else task.wait(0.5) end
	end
end)

-- Whitelist friends loop
task.spawn(function()
	while true do
		if State.WhitelistFriends then
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= LocalPlayer then
					pcall(function()
						if p:IsFriendsWith(LocalPlayer.UserId) then addUnique(State.Whitelist, p.Name) end
					end)
				end
			end
			task.wait(3)
		else task.wait(1) end
	end
end)

-- Spectate
task.spawn(function()
	while true do
		if State.Spectate and State.SpectatePlayer then
			local p = Players:FindFirstChild(State.SpectatePlayer)
			if p and p.Character then
				local h = p.Character:FindFirstChildOfClass("Humanoid")
				if h and Camera then Camera.CameraSubject = h end
			end
			task.wait(0.2)
		else task.wait(0.5) end
	end
end)

-- ==========================================
-- UI BUILD
-- ==========================================
local function playerOpts()
	local o = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then table.insert(o, p.DisplayName .. " | " .. p.Name) end
	end
	if #o == 0 then table.insert(o, "No players") end
	return o
end

local function petList(isAura)
	local list = {}
	pcall(function()
		for _, item in ipairs(ReplicatedStorage.shared.runtime.cPetShopFolder:GetChildren()) do
			if (item:GetAttribute("IsPowerUp") == true) == isAura then table.insert(list, item.Name) end
		end
	end)
	table.sort(list)
	if #list == 0 then table.insert(list, "None") end
	return list
end

local function optsFrom(t)
	local o = {}
	for k in pairs(t) do table.insert(o, k) end
	table.sort(o)
	return o
end

local function parsePlayer(v)
	local n = v:match("| (.+)$") or v
	return n:gsub("^%s*(.-)%s*$", "%1")
end

local Main = Window:Tab({ Title = "Main" })
Main:Section({ Title = "User Settings" })
Main:Input({ Title = "Size", Placeholder = "2", Callback = function(v) local n=tonumber(v); if n and n>0 then State.Size=n end end })
Main:Toggle({ Title = "Set Size", Default = false, Callback = function(v) State.SetSize = v end })
Main:Input({ Title = "Speed", Placeholder = "120", Callback = function(v) local n=tonumber(v); if n and n>0 then State.Speed=n end end })
Main:Toggle({ Title = "Set Speed", Default = false, Callback = function(v) State.SetSpeed = v end })
Main:Input({ Title = "FOV", Placeholder = "70", Callback = function(v) local n=tonumber(v); if n and n>=1 and n<=120 then State.FOV=n end end })
Main:Toggle({ Title = "Set FOV", Default = false, Callback = function(v) State.SetFOV=v; if Camera then Camera.FieldOfView = v and State.FOV or 70 end end })
Main:Section({ Title = "Protection" })
Main:Toggle({ Title = "Anti Fling", Default = true, Callback = function(v) State.AntiFling=v; if v then enableAF() else disableAF() end end })
Main:Toggle({ Title = "Lock Position", Default = false, Callback = function(v)
	State.LockPos = v
	if v then local r=root(); if r then State.LockPosVec=r.Position end
	else local r=root(); if r then local bp=r:FindFirstChild("PositionLocker"); if bp then bp:Destroy() end end; State.LockPosVec=nil end
end })
Main:Section({ Title = "Visuals" })
Main:Toggle({ Title = "Hide Pets", Default = true, Callback = function(v)
	State.HidePets=v
	pcall(function() ReplicatedStorage.rEvents.showPetsEvent:FireServer(v and "hidePets" or "showPets") end)
end })
Main:Toggle({ Title = "Hide Popups", Default = true, Callback = function(v)
	State.HidePopups=v
	pcall(function() ReplicatedStorage.rEvents.savePlayerSizeEvent:FireServer("showPopupsOption") end)
end })
Main:Toggle({ Title = "Walk on Water", Default = true, Callback = function(v)
	State.WalkWater=v
	if _G.MLWater then for _,p in ipairs(_G.MLWater) do if p and p.Parent then p.CanCollide=v end end end
end })
Main:Toggle({ Title = "Infinite Jump", Default = false, Callback = function(v) State.InfJump=v end })
Main:Toggle({ Title = "Spin Fortune Wheel", Default = false, Callback = function(v) State.SpinFortune=v end })
Main:Dropdown({ Title = "Change Time", Option = {"Day","Night"}, Callback = function(v) Lighting.ClockTime = v=="Night" and 0 or 9 end })

local Killing = Window:Tab({ Title = "Killing" })
Killing:Section({ Title = "Pets" })
Killing:Button({ Title = "Equip Best Damage", Callback = function()
	local priority = {"Wild Wizard","Chaos Sorcerer","Mighty Monster","Small Fry"}
	pcall(function()
		for _, folder in pairs(LocalPlayer.petsFolder:GetChildren()) do
			if folder:IsA("Folder") then
				for _, pet in pairs(folder:GetChildren()) do
					ReplicatedStorage.rEvents.equipPetEvent:FireServer("unequipPet", pet)
				end
			end
		end
		task.wait(0.2)
		local byName = {}
		for _, n in ipairs(priority) do byName[n] = {} end
		for _, pet in pairs(LocalPlayer.petsFolder.Unique:GetChildren()) do
			if byName[pet.Name] then table.insert(byName[pet.Name], pet) end
		end
		local count = 0
		for _, n in ipairs(priority) do
			for _, pet in ipairs(byName[n]) do
				if count >= 9 then return end
				ReplicatedStorage.rEvents.equipPetEvent:FireServer("equipPet", pet)
				count += 1
				task.wait(0.1)
			end
		end
	end)
end })
Killing:Button({ Title = "Equip Best Health", Callback = function()
	local priority = {"Mighty Monster","Small Fry","Wild Wizard","Chaos Sorcerer"}
	pcall(function()
		for _, folder in pairs(LocalPlayer.petsFolder:GetChildren()) do
			if folder:IsA("Folder") then
				for _, pet in pairs(folder:GetChildren()) do
					ReplicatedStorage.rEvents.equipPetEvent:FireServer("unequipPet", pet)
				end
			end
		end
		task.wait(0.2)
		local byName = {}
		for _, n in ipairs(priority) do byName[n] = {} end
		for _, pet in pairs(LocalPlayer.petsFolder.Unique:GetChildren()) do
			if byName[pet.Name] then table.insert(byName[pet.Name], pet) end
		end
		local count = 0
		for _, n in ipairs(priority) do
			for _, pet in ipairs(byName[n]) do
				if count >= 9 then return end
				ReplicatedStorage.rEvents.equipPetEvent:FireServer("equipPet", pet)
				count += 1
				task.wait(0.1)
			end
		end
	end)
end })
Killing:Section({ Title = "Auto Kill" })
Killing:Toggle({ Title = "Kill Everyone", Default = false, Callback = function(v) State.KillAll=v end })
Killing:Toggle({ Title = "Whitelist Friends", Default = false, Callback = function(v) State.WhitelistFriends=v end })
Killing:Toggle({ Title = "Farm Evil Karma", Default = false, Callback = function(v) State.FarmEvil=v end })
Killing:Toggle({ Title = "Farm Good Karma", Default = false, Callback = function(v) State.FarmGood=v end })
Killing:Toggle({ Title = "Kill List", Default = false, Callback = function(v) State.KillList=v end })
Killing:Section({ Title = "Kill Aura" })
Killing:Input({ Title = "Ring Range", Placeholder = "20", Callback = function(v) local n=tonumber(v); if n then State.RingRange=math.clamp(n,1,140) end end })
Killing:Toggle({ Title = "Toggle Ring", Default = false, Callback = function(v) State.DeathRing=v end })
Killing:Toggle({ Title = "Show Ring", Default = false, Callback = function(v) State.ShowRing=v end })
Killing:Section({ Title = "Lists" })
Killing:Dropdown({ Title = "Add to Whitelist", Option = playerOpts(), Callback = function(v)
	local n = parsePlayer(v); if n ~= "No players" then addUnique(State.Whitelist, n) end
end })
Killing:Button({ Title = "Clear Whitelist", Callback = function() State.Whitelist = {} end })
Killing:Dropdown({ Title = "Add to Killlist", Option = playerOpts(), Callback = function(v)
	local n = parsePlayer(v); if n ~= "No players" then addUnique(State.Killlist, n) end
end })
Killing:Button({ Title = "Clear Killlist", Callback = function() State.Killlist = {} end })
Killing:Section({ Title = "Spectate" })
Killing:Dropdown({ Title = "Choose Player", Option = playerOpts(), Callback = function(v)
	local n = parsePlayer(v); if n ~= "No players" then State.SpectatePlayer = n end
end })
Killing:Toggle({ Title = "Spectate", Default = false, Callback = function(v)
	State.Spectate = v
	if not v then
		local h = hum()
		if h and Camera then Camera.CameraSubject = h end
	end
end })

local Brawl = Window:Tab({ Title = "Brawl" })
Brawl:Section({ Title = "Auto Brawl" })
Brawl:Toggle({ Title = "Auto Brawl", Default = false, Callback = function(v)
	State.AutoBrawl = v
	if not v then ESPFolder:ClearAllChildren() end
end })

local Farming = Window:Tab({ Title = "Farming" })
Farming:Section({ Title = "Rebirths" })
Farming:Input({ Title = "Rebirth Target", Placeholder = "0", Callback = function(v) local n=tonumber(v); if n and n>=0 then State.RebirthTarget=n end end })
Farming:Toggle({ Title = "Auto Rebirth", Default = false, Callback = function(v) State.AutoRebirth=v end })
Farming:Toggle({ Title = "Auto Size 1", Default = false, Callback = function(v) State.AutoSize1=v end })
Farming:Toggle({ Title = "Auto King", Default = false, Callback = function(v) State.AutoKing=v end })
Farming:Section({ Title = "Exercises" })
Farming:Dropdown({ Title = "Select Exercise", Option = {"Weight","Pushups","Situps","Handstands"}, Callback = function(v) State.Exercise=v end })
Farming:Toggle({ Title = "Start Exercising", Default = false, Callback = function(v)
	State.AutoExercise = v
	if v then
		machineState.Squat.Running = false
		machineState.Lift.Running = false
		State.AutoSquat = false
		State.AutoLift = false
	end
end })
if #SquatNames > 0 then
	Farming:Dropdown({ Title = "Select Squat", Option = SquatNames, Callback = function(v) State.SelectedSquat=v end })
end
Farming:Toggle({ Title = "Auto Squat", Default = false, Callback = function(v)
	State.AutoSquat = v
	machineState.Squat.Running = v
	machineState.Squat.Active = nil
	if v then
		State.AutoExercise = false
		machineState.Lift.Running = false
		State.AutoLift = false
		runMachine("Squat", SquatChoices)
	end
end })
if #LiftNames > 0 then
	Farming:Dropdown({ Title = "Select Lift", Option = LiftNames, Callback = function(v) State.SelectedLift=v end })
end
Farming:Toggle({ Title = "Auto Lift", Default = false, Callback = function(v)
	State.AutoLift = v
	machineState.Lift.Running = v
	machineState.Lift.Active = nil
	if v then
		State.AutoExercise = false
		machineState.Squat.Running = false
		State.AutoSquat = false
		runMachine("Lift", LiftChoices)
	end
end })
Farming:Toggle({ Title = "Auto Rep", Default = false, Callback = function(v) State.AutoRep=v end })
Farming:Section({ Title = "Rocks" })
Farming:Dropdown({ Title = "Select Rock", Option = optsFrom(RockData), Callback = function(v) State.SelectedRock=v end })
Farming:Toggle({ Title = "Auto Rock", Default = false, Callback = function(v) State.AutoRock=v end })
Farming:Section({ Title = "Better Strength" })
Farming:Toggle({ Title = "Pushup + Industrial Rock", Default = false, Callback = function(v) State.PushupIndustrial=v end })
Farming:Toggle({ Title = "Pushup + Jungle Rock", Default = false, Callback = function(v) State.PushupJungle=v end })
Farming:Toggle({ Title = "Pushup + Muscle King Rock", Default = false, Callback = function(v) State.PushupKing=v end })
Farming:Toggle({ Title = "Pushup + Legends Rock", Default = false, Callback = function(v) State.PushupLegends=v end })

local Boss = Window:Tab({ Title = "Boss" })
Boss:Section({ Title = "Boss Farm" })
Boss:Toggle({ Title = "Auto Farm Boss", Default = false, Callback = function(v) State.AutoBoss=v end })
Boss:Toggle({ Title = "Continue Farming after Boss Kill", Default = true, Callback = function(v) State.ContinueBoss=v end })
pcall(function()
	local ok, cfg = pcall(function()
		return require(ReplicatedStorage.shared.config.BossEventConfig)
	end)
	if ok and cfg and cfg.RARITIES then
		local names = {}
		for _, rarity in ipairs(cfg.RARITIES) do
			local model = tostring(rarity.BossModel or "")
			local display = tostring(rarity.DisplayName or rarity.Name or model)
			if model ~= "" then
				State.SelectedBosses[model] = true
				table.insert(names, display)
			end
		end
		if #names > 0 then
			Boss:Dropdown({ Title = "Target Bosses", Option = names, Callback = function(display)
				-- toggle selection by display -> model
				pcall(function()
					for _, rarity in ipairs(cfg.RARITIES) do
						local model = tostring(rarity.BossModel or "")
						local d = tostring(rarity.DisplayName or rarity.Name or model)
						if d == display and model ~= "" then
							State.SelectedBosses[model] = not State.SelectedBosses[model]
						end
					end
				end)
			end })
		end
	end
end)

local Pets = Window:Tab({ Title = "Pets" })
local pets = petList(false)
local auras = petList(true)
Pets:Section({ Title = "Pet Shop" })
Pets:Dropdown({ Title = "Choose Pet", Option = pets, Callback = function(v) if v~="None" then toggleList(State.SelectedPets, v) end end })
Pets:Input({ Title = "Buy Amount", Placeholder = "1", Callback = function(v) State.PetBuyAmt=math.max(1,math.floor(tonumber(v) or 1)) end })
Pets:Toggle({ Title = "Buy Pet", Default = false, Callback = function(v) State.AutoBuyPet=v end })
Pets:Section({ Title = "Auras" })
Pets:Dropdown({ Title = "Choose Aura", Option = auras, Callback = function(v) if v~="None" then toggleList(State.SelectedAuras, v) end end })
Pets:Input({ Title = "Aura Buy Amount", Placeholder = "1", Callback = function(v) State.AuraBuyAmt=math.max(1,math.floor(tonumber(v) or 1)) end })
Pets:Toggle({ Title = "Buy Aura", Default = false, Callback = function(v) State.AutoBuyAura=v end })
Pets:Section({ Title = "Evolve" })
Pets:Dropdown({ Title = "Evolve Pet", Option = pets, Callback = function(v) if v~="None" then toggleList(State.EvolvePets, v) end end })
Pets:Input({ Title = "Evolve Amount", Placeholder = "1", Callback = function(v) State.EvolveAmt=math.max(1,math.floor(tonumber(v) or 1)) end })
Pets:Toggle({ Title = "Auto Evolve", Default = false, Callback = function(v) State.AutoEvolve=v end })
Pets:Section({ Title = "Trading" })
Pets:Dropdown({ Title = "Trade Player", Option = playerOpts(), Callback = function(v)
	local n = parsePlayer(v); if n ~= "No players" then toggleList(State.TradePlayers, n) end
end })
Pets:Button({ Title = "Add All Players", Callback = function()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then addUnique(State.TradePlayers, p.Name) end
	end
end })
Pets:Dropdown({ Title = "Trade Pet", Option = pets, Callback = function(v) if v~="None" then toggleList(State.TradePets, v) end end })
Pets:Toggle({ Title = "Auto Trade", Default = false, Callback = function(v) State.AutoTrade=v end })

local Boosts = Window:Tab({ Title = "Boosts" })
Boosts:Section({ Title = "Consumables" })
Boosts:Toggle({ Title = "Eat All Eggs", Default = false, Callback = function(v) State.EatEggs=v end })
Boosts:Toggle({ Title = "Eat All Boosts", Default = false, Callback = function(v) State.EatBoosts=v end })
Boosts:Section({ Title = "Egg Gifter" })
local giftEggPlayer, giftEggAmt = nil, 0
Boosts:Dropdown({ Title = "Choose Player", Option = playerOpts(), Callback = function(v)
	local n = parsePlayer(v)
	if n ~= "No players" then giftEggPlayer = Players:FindFirstChild(n) end
end })
Boosts:Input({ Title = "Amount", Placeholder = "0", Callback = function(v) giftEggAmt = math.max(0, math.floor(tonumber(v) or 0)) end })
Boosts:Button({ Title = "Start Gifting Eggs", Callback = function()
	if not giftEggPlayer or giftEggAmt == 0 then return end
	task.spawn(function()
		for _ = 1, giftEggAmt do
			local egg = LocalPlayer.consumablesFolder and LocalPlayer.consumablesFolder:FindFirstChild("Protein Egg")
			if not egg then break end
			pcall(function() ReplicatedStorage.rEvents.giftRemote:InvokeServer("giftRequest", giftEggPlayer, egg) end)
			task.wait(0.1)
		end
	end)
end })
Boosts:Section({ Title = "Shake Gifter" })
local giftShakePlayer, giftShakeAmt = nil, 0
Boosts:Dropdown({ Title = "Choose Player", Option = playerOpts(), Callback = function(v)
	local n = parsePlayer(v)
	if n ~= "No players" then giftShakePlayer = Players:FindFirstChild(n) end
end })
Boosts:Input({ Title = "Amount", Placeholder = "0", Callback = function(v) giftShakeAmt = math.max(0, math.floor(tonumber(v) or 0)) end })
Boosts:Button({ Title = "Start Gifting Shakes", Callback = function()
	if not giftShakePlayer or giftShakeAmt == 0 then return end
	task.spawn(function()
		for _ = 1, giftShakeAmt do
			local shake = LocalPlayer.consumablesFolder and LocalPlayer.consumablesFolder:FindFirstChild("Tropical Shake")
			if not shake then break end
			pcall(function() ReplicatedStorage.rEvents.giftRemote:InvokeServer("giftRequest", giftShakePlayer, shake) end)
			task.wait(0.1)
		end
	end)
end })

local Specs = Window:Tab({ Title = "Specs" })
local inspectPlayer = nil
Specs:Section({ Title = "Player Stats" })
Specs:Dropdown({ Title = "Choose Player", Option = playerOpts(), Callback = function(v)
	local n = parsePlayer(v)
	if n ~= "No players" then inspectPlayer = Players:FindFirstChild(n) end
end })
Specs:Button({ Title = "Print Stats", Callback = function()
	local p = inspectPlayer
	if not p then print("No player selected") return end
	print("Name:", p.DisplayName, "User:", p.Name)
	local ls = p:FindFirstChild("leaderstats")
	if ls then
		for _, n in ipairs({"Strength","Rebirths","Kills","Brawls"}) do
			local s = ls:FindFirstChild(n)
			if s then print(n, formatNumber(s.Value), formatWithCommas(s.Value)) end
		end
	end
	for _, n in ipairs({"Durability","Agility","evilKarma","goodKarma"}) do
		local s = p:FindFirstChild(n)
		if s then print(n, formatNumber(s.Value), formatWithCommas(s.Value)) end
	end
end })

local Teleport = Window:Tab({ Title = "Teleports" })
Teleport:Section({ Title = "Locations" })
local selectedTp = nil
Teleport:Dropdown({ Title = "Destination", Option = optsFrom(Teleports), Callback = function(v) selectedTp=v end })
Teleport:Button({ Title = "Teleport", Callback = function()
	if selectedTp and Teleports[selectedTp] then
		local r = root(); if r then r.CFrame = Teleports[selectedTp] end
	end
end })
for name, cf in pairs(Teleports) do
	Teleport:Button({ Title = name, Callback = function()
		local r = root(); if r then r.CFrame = cf end
	end })
end

local StatsTab = Window:Tab({ Title = "Stats" })
local startTime = tick()
local initial = {}
pcall(function()
	local ls = LocalPlayer:WaitForChild("leaderstats", 5)
	if ls then
		for _, n in ipairs({"Strength","Rebirths","Kills","Brawls"}) do
			local s = ls:FindFirstChild(n)
			if s then initial[n] = s.Value end
		end
	end
end)
StatsTab:Section({ Title = "Session" })
StatsTab:Button({ Title = "Print Session Stats", Callback = function()
	print(string.format("[Muscle Legends] Session %.0fs", tick()-startTime))
	local ls = LocalPlayer:FindFirstChild("leaderstats")
	if ls then
		for _, n in ipairs({"Strength","Rebirths","Kills","Brawls"}) do
			local s = ls:FindFirstChild(n)
			if s then
				local gained = s.Value - (initial[n] or s.Value)
				print(n, formatNumber(s.Value), "Gained", formatNumber(gained))
			end
		end
	end
end })

local Info = Window:Tab({ Title = "Info" })
Info:Section({ Title = "Muscle Legends" })
Info:Label({ Title = "Controls", Desc = "RightControl open/close" })
Info:Button({ Title = "Destroy UI", Callback = function() pcall(function() Window:Destroy() end) end })

task.defer(function()
	pcall(function()
		if Window.Open then Window:Open() end
		if Window.SelectFirstTab then Window:SelectFirstTab() end
	end)
end)

print("[Muscle Legends] Loaded")
