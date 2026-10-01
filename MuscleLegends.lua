--[[
    Supreme Hub | Muscle Legends
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
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local CONFIG_PATH = "SupremeHub/MuscleLegends.json"

local function notify(title, text)
	pcall(function()
		StarterGui:SetCore("SendNotification", {Title = tostring(title), Text = tostring(text), Duration = 4})
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
		notify("Supreme Hub", "UI failed: " .. tostring(err))
		warn("[Supreme Hub] UI failed:", err)
		return
	end
end

local Window = VoidUI:CreateWindow({
	Name = "Supreme Hub",
	Theme = "Dark",
	ToggleKey = Enum.KeyCode.RightControl,
})

pcall(function()
	Window:EditOpenButton({
		Title = "Supreme Hub",
		Icon = "menu",
		Transparency = 0.15,
		Color = ColorSequence.new(Color3.fromRGB(90, 90, 90), Color3.fromRGB(60, 60, 60)),
		StrokeThickness = 1,
	})
end)
pcall(function() if Window.Open then Window:Open() end end)

-- ==========================================
-- HELPERS
-- ==========================================
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

-- ==========================================
-- STATE
-- ==========================================
local State = {
	Size = 2, Speed = 120, FOV = 70,
	SetSize = false, SetSpeed = false, SetFOV = false,
	AntiFling = true, LockPos = false, LockPosVec = nil,
	InfJump = false, SpinFortune = false,

	-- Master farm priority
	FarmMaster = false,

	KillAll = false, FarmEvil = false, FarmGood = false, KillList = false,
	WhitelistFriends = false, DeathRing = false, ShowRing = false, RingRange = 20,
	Spectate = false, SpectatePlayer = nil,

	AutoRebirth = false, RebirthTarget = 0, AutoSize1 = false, AutoKing = false,
	Exercise = "Weight", AutoExercise = false, AutoSquat = false, AutoLift = false,
	SelectedSquat = nil, SelectedLift = nil, AutoRep = false,
	AutoRock = false, SelectedRock = nil,
	PushupIndustrial = false, PushupJungle = false, PushupKing = false, PushupLegends = false,

	AutoBoss = false, ContinueBoss = true, SelectedBosses = {},

	AutoBuyPet = false, AutoBuyAura = false, AutoEvolve = false, AutoTrade = false,
	EatEggs = false, EatBoosts = false, AutoBrawl = false,
	Whitelist = {}, Killlist = {},
	SelectedPets = {}, SelectedAuras = {}, EvolvePets = {},
	TradePlayers = {}, TradePets = {},
	PetBuyAmt = 1, AuraBuyAmt = 1, EvolveAmt = 1,

	-- Misc / Hides
	TimeMode = "Day",
	Render3D = false,
	HidePets = true,
	HidePopups = true,
	HidePlayers = false,
	HideSound = false,
	Optimizer = false,
	WalkWater = true,
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

-- ==========================================
-- CONFIG SAVE / LOAD
-- ==========================================
local function ensureFolder()
	if type(makefolder) == "function" then
		pcall(makefolder, "SupremeHub")
	end
end

local function serializeState()
	return {
		Size = State.Size, Speed = State.Speed, FOV = State.FOV,
		SetSize = State.SetSize, SetSpeed = State.SetSpeed, SetFOV = State.SetFOV,
		AntiFling = State.AntiFling, InfJump = State.InfJump, SpinFortune = State.SpinFortune,
		FarmMaster = State.FarmMaster,
		AutoRep = State.AutoRep,
		AutoBoss = State.AutoBoss, ContinueBoss = State.ContinueBoss,
		AutoBrawl = State.AutoBrawl,
		AutoRebirth = State.AutoRebirth, RebirthTarget = State.RebirthTarget,
		AutoSize1 = State.AutoSize1, AutoKing = State.AutoKing,
		Exercise = State.Exercise, AutoExercise = State.AutoExercise,
		AutoRock = State.AutoRock, SelectedRock = State.SelectedRock,
		PushupIndustrial = State.PushupIndustrial, PushupJungle = State.PushupJungle,
		PushupKing = State.PushupKing, PushupLegends = State.PushupLegends,
		SelectedPets = State.SelectedPets, SelectedAuras = State.SelectedAuras,
		EvolvePets = State.EvolvePets,
		PetBuyAmt = State.PetBuyAmt, AuraBuyAmt = State.AuraBuyAmt, EvolveAmt = State.EvolveAmt,
		AutoBuyPet = State.AutoBuyPet, AutoBuyAura = State.AutoBuyAura, AutoEvolve = State.AutoEvolve,
		RingRange = State.RingRange, DeathRing = State.DeathRing, ShowRing = State.ShowRing,
		KillAll = State.KillAll, FarmEvil = State.FarmEvil, FarmGood = State.FarmGood,
		KillList = State.KillList, WhitelistFriends = State.WhitelistFriends,
		-- Hides / Misc
		TimeMode = State.TimeMode,
		Render3D = State.Render3D,
		HidePets = State.HidePets,
		HidePopups = State.HidePopups,
		HidePlayers = State.HidePlayers,
		HideSound = State.HideSound,
		Optimizer = State.Optimizer,
		WalkWater = State.WalkWater,
	}
end

local function applyConfig(cfg)
	if type(cfg) ~= "table" then return end
	for k, v in pairs(cfg) do
		if State[k] ~= nil then
			State[k] = v
		end
	end
end

local function saveConfig()
	if type(writefile) ~= "function" then return end
	ensureFolder()
	pcall(function()
		writefile(CONFIG_PATH, HttpService:JSONEncode(serializeState()))
	end)
end

local function loadConfig()
	if type(isfile) ~= "function" or type(readfile) ~= "function" then return end
	pcall(function()
		if not isfile(CONFIG_PATH) then return end
		local data = HttpService:JSONDecode(readfile(CONFIG_PATH))
		applyConfig(data)
	end)
end

loadConfig()

local function markDirty()
	task.defer(saveConfig)
end

-- ==========================================
-- FARM PRIORITY
-- Priority: Boss > Brawl > Rebirth (only when FarmMaster on)
-- ==========================================
local function farmPriority()
	if not State.FarmMaster then
		return { boss = false, brawl = false, rebirth = false, other = true }
	end
	if State.AutoBoss then
		return { boss = true, brawl = false, rebirth = false, other = false }
	end
	if State.AutoBrawl then
		return { boss = false, brawl = true, rebirth = false, other = false }
	end
	if State.AutoRebirth then
		return { boss = false, brawl = false, rebirth = true, other = false }
	end
	return { boss = false, brawl = false, rebirth = false, other = true }
end

local function canRunBoss()
	local p = farmPriority()
	return State.AutoBoss and (not State.FarmMaster or p.boss)
end

local function canRunBrawl()
	local p = farmPriority()
	return State.AutoBrawl and (not State.FarmMaster or p.brawl)
end

local function canRunRebirth()
	local p = farmPriority()
	return State.AutoRebirth and (not State.FarmMaster or p.rebirth)
end

local function canRunOtherFarm()
	local p = farmPriority()
	return not State.FarmMaster or p.other
end

-- Unseat if sitting while farming
task.spawn(function()
	while true do
		if State.FarmMaster or State.AutoBoss or State.AutoBrawl or State.AutoRebirth
			or State.AutoExercise or State.AutoRock or State.AutoRep then
			local h = hum()
			if h and h.SeatPart then
				h.Jump = true
				pcall(function() h.Sit = false end)
			end
		end
		task.wait(0.25)
	end
end)

-- ==========================================
-- COMBAT HELPERS
-- ==========================================
local function inList(list, name)
	for _, n in ipairs(list) do if n:lower() == name:lower() then return true end end
	return false
end

local function addUnique(list, name)
	if not inList(list, name) then table.insert(list, name) end
end

local function toggleList(list, value)
	for i = #list, 1, -1 do
		if list[i] == value then table.remove(list, i) return false end
	end
	table.insert(list, value)
	return true
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
		if State.SetSize then
			pcall(function() ReplicatedStorage.rEvents.changeSpeedSizeRemote:InvokeServer("changeSize", State.Size) end)
		end
		if State.SetSpeed then
			pcall(function() ReplicatedStorage.rEvents.changeSpeedSizeRemote:InvokeServer("changeSpeed", State.Speed) end)
		end
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
				p.CanCollide = State.WalkWater
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

-- Rebirth (priority aware)
task.spawn(function()
	while true do
		if canRunRebirth() and State.RebirthTarget > 0 then
			local rb = LocalPlayer.leaderstats and LocalPlayer.leaderstats:FindFirstChild("Rebirths")
			if rb and rb.Value < State.RebirthTarget then
				pcall(function() ReplicatedStorage.rEvents.rebirthRemote:InvokeServer("rebirthRequest") end)
			end
			task.wait(0.05)
		else task.wait(0.3) end
	end
end)

task.spawn(function()
	while true do
		if canRunOtherFarm() and State.AutoSize1 then
			pcall(function() ReplicatedStorage.rEvents.changeSpeedSizeRemote:InvokeServer("changeSize", 1) end)
		end
		task.wait(0.05)
	end
end)

task.spawn(function()
	while true do
		if canRunOtherFarm() and State.AutoKing then
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
		if canRunOtherFarm() and State.AutoExercise and State.Exercise then
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
		if canRunOtherFarm() and State.AutoRep then
			fireRep()
			task.wait(0.1)
		else task.wait(0.3) end
	end
end)

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
	local folder = Workspace:FindFirstChild("machinesFolder") or Workspace:WaitForChild("machinesFolder", 3)
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

local function runMachine(kind)
	local ms = machineState[kind]
	task.spawn(function()
		local lastChar = char()
		while ms.Running do
			if canRunOtherFarm() then
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
			else
				task.wait(0.2)
			end
		end
	end)
end

task.spawn(function()
	while true do
		if canRunOtherFarm() and State.AutoRock and State.SelectedRock and RockData[State.SelectedRock] then
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

local StrengthConfigs = {
	{key = "PushupIndustrial", tool = "Pushups", rock = "Industrial Rock"},
	{key = "PushupJungle", tool = "Pushups", rock = "Ancient Jungle Rock"},
	{key = "PushupKing", tool = "Pushups", rock = "Muscle King Mountain"},
	{key = "PushupLegends", tool = "Pushups", rock = "Rock Of Legends"},
}

for _, cfg in ipairs(StrengthConfigs) do
	task.spawn(function()
		while true do
			if canRunOtherFarm() and State[cfg.key] then
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

-- Boss (priority)
local function findBoss()
	for _, c in ipairs(CollectionService:GetTagged("BossEventBoss")) do
		if c:IsA("Model") and c:IsDescendantOf(Workspace) then
			local hitbox = c:FindFirstChild("BossDamageHitbox", true)
			if hitbox and hitbox:IsA("BasePart") then
				local stats = c:FindFirstChild("stats")
				local health = stats and stats:FindFirstChild("Health")
				local hp = health and health.Value or Workspace:GetAttribute("BossHealth") or 0
				if typeof(hp) == "number" and hp > 0 then return c, hitbox end
			end
		end
	end
end

task.spawn(function()
	while true do
		if canRunBoss() then
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

-- Pets
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

-- Brawl (priority)
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
		if canRunBrawl() then
			pcall(function() ReplicatedStorage.rEvents.brawlEvent:FireServer("joinBrawl") end)
			task.wait(2)
		else task.wait(0.5) end
	end
end)

task.spawn(function()
	local aggro = {}
	while true do
		if canRunBrawl() then
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
		if canRunBrawl() then
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
-- MISC: Render3D black overlay / Hides / Optimizer
-- ==========================================
local BlackOverlay
local Render3DConn

local function isOurUI(gui)
	if not gui or not gui:IsA("ScreenGui") then return false end
	local n = string.lower(gui.Name or "")
	if gui.Name == "SupremeHubBlackOverlay" then return true end
	if string.find(n, "supreme", 1, true) or string.find(n, "void", 1, true) then return true end
	-- Void UI ScreenGui often has no custom name; detect by content
	local ok, found = pcall(function()
		for _, d in ipairs(gui:GetDescendants()) do
			if d:IsA("TextLabel") or d:IsA("TextButton") then
				local t = tostring(d.Text or "")
				if string.find(t, "Supreme Hub", 1, true) then return true end
			end
			if d.Name == "Drag" or d.Name == "WindowDragBar" or d.Name == "NotificationHolder" then
				return true
			end
		end
		return false
	end)
	return ok and found == true
end

local function getGuiParents()
	local list = {CoreGui}
	pcall(function()
		if gethui then table.insert(list, 1, gethui()) end
	end)
	local pg = LocalPlayer:FindFirstChild("PlayerGui")
	if pg then table.insert(list, pg) end
	return list
end

local function ensureBlackOverlay()
	if BlackOverlay and BlackOverlay.Parent then return BlackOverlay end
	local parent = CoreGui
	pcall(function() if gethui then parent = gethui() end end)
	local sg = Instance.new("ScreenGui")
	sg.Name = "SupremeHubBlackOverlay"
	sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = true
	-- Below Void Hub (we force Void DisplayOrder higher)
	sg.DisplayOrder = 100
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = parent
	local f = Instance.new("Frame")
	f.Name = "Black"
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundColor3 = Color3.new(0, 0, 0)
	f.BorderSizePixel = 0
	f.ZIndex = 1
	f.Active = false
	f.Parent = sg
	BlackOverlay = sg
	return sg
end

local function promoteOurUI()
	for _, parent in ipairs(getGuiParents()) do
		for _, gui in ipairs(parent:GetChildren()) do
			if gui:IsA("ScreenGui") and isOurUI(gui) and gui.Name ~= "SupremeHubBlackOverlay" then
				pcall(function()
					gui.Enabled = true
					gui.DisplayOrder = 200000
					gui:SetAttribute("SH_OurUI", true)
				end)
			end
		end
	end
end

local function hideOtherGuis()
	local sg = BlackOverlay
	for _, parent in ipairs(getGuiParents()) do
		for _, gui in ipairs(parent:GetChildren()) do
			if gui:IsA("ScreenGui") and gui ~= sg then
				if isOurUI(gui) or gui:GetAttribute("SH_OurUI") then
					pcall(function()
						gui.Enabled = true
						gui.DisplayOrder = 200000
					end)
				else
					if gui.Enabled then
						gui:SetAttribute("SH_HiddenBy3D", true)
						gui.Enabled = false
					end
				end
			end
		end
	end
end

local function restoreOtherGuis()
	for _, parent in ipairs(getGuiParents()) do
		for _, gui in ipairs(parent:GetChildren()) do
			if gui:IsA("ScreenGui") and gui:GetAttribute("SH_HiddenBy3D") then
				gui.Enabled = true
				gui:SetAttribute("SH_HiddenBy3D", nil)
			end
		end
	end
end

local function setRender3D(on)
	State.Render3D = on
	if Render3DConn then
		pcall(function() Render3DConn:Disconnect() end)
		Render3DConn = nil
	end
	if on then
		local sg = ensureBlackOverlay()
		sg.Enabled = true
		sg.DisplayOrder = 100
		promoteOurUI()
		hideOtherGuis()
		-- Keep Void Hub on top and re-hide game GUIs that respawn
		Render3DConn = RunService.Heartbeat:Connect(function()
			if not State.Render3D then return end
			promoteOurUI()
			hideOtherGuis()
			if BlackOverlay and BlackOverlay.Parent then
				BlackOverlay.Enabled = true
				BlackOverlay.DisplayOrder = 100
			end
		end)
	else
		if BlackOverlay then BlackOverlay.Enabled = false end
		restoreOtherGuis()
	end
	markDirty()
end

local function applyHidePets()
	pcall(function()
		ReplicatedStorage.rEvents.showPetsEvent:FireServer(State.HidePets and "hidePets" or "showPets")
	end)
end

local function applyHidePopups()
	pcall(function()
		ReplicatedStorage.rEvents.savePlayerSizeEvent:FireServer("showPopupsOption")
	end)
end

local hiddenPlayerParts = {}
local function applyHidePlayers()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			for _, part in ipairs(p.Character:GetDescendants()) do
				if part:IsA("BasePart") or part:IsA("Decal") then
					if State.HidePlayers then
						if hiddenPlayerParts[part] == nil then
							if part:IsA("BasePart") then
								hiddenPlayerParts[part] = part.LocalTransparencyModifier
								part.LocalTransparencyModifier = 1
							elseif part:IsA("Decal") then
								hiddenPlayerParts[part] = part.Transparency
								part.Transparency = 1
							end
						end
					else
						local old = hiddenPlayerParts[part]
						if old ~= nil then
							if part:IsA("BasePart") then part.LocalTransparencyModifier = old
							elseif part:IsA("Decal") then part.Transparency = old end
							hiddenPlayerParts[part] = nil
						end
					end
				end
			end
		end
	end
end

local mutedSounds = {}
local function applyHideSound()
	for _, s in ipairs(Workspace:GetDescendants()) do
		if s:IsA("Sound") then
			local isMine = s:IsDescendantOf(char() or LocalPlayer)
			if State.HideSound and not isMine then
				if mutedSounds[s] == nil then
					mutedSounds[s] = s.Volume
					s.Volume = 0
				end
			elseif mutedSounds[s] ~= nil then
				s.Volume = mutedSounds[s]
				mutedSounds[s] = nil
			end
		end
	end
	-- also SoundService children not mine
	for _, s in ipairs(SoundService:GetDescendants()) do
		if s:IsA("Sound") then
			if State.HideSound then
				if mutedSounds[s] == nil then
					mutedSounds[s] = s.Volume
					s.Volume = 0
				end
			elseif mutedSounds[s] ~= nil then
				s.Volume = mutedSounds[s]
				mutedSounds[s] = nil
			end
		end
	end
end

local function applyOptimizer()
	if State.Optimizer then
		pcall(function()
			settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
		end)
		pcall(function()
			Lighting.GlobalShadows = false
			Lighting.FogEnd = 9e9
		end)
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
				or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
				obj.Enabled = false
				obj:SetAttribute("SH_Opt", true)
			end
		end
	else
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj:GetAttribute("SH_Opt") then
				if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
					or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
					obj.Enabled = true
				end
				obj:SetAttribute("SH_Opt", nil)
			end
		end
	end
end

task.spawn(function()
	while true do
		if State.HidePlayers then applyHidePlayers() end
		if State.HideSound then applyHideSound() end
		task.wait(1)
	end
end)

-- Apply saved hides on load
task.defer(function()
	applyHidePets()
	if State.Render3D then setRender3D(true) end
	if State.Optimizer then applyOptimizer() end
	if State.TimeMode then
		local map = {Day = 9, Noon = 12, Afternoon = 16, Night = 0, Midnight = 2}
		Lighting.ClockTime = map[State.TimeMode] or 9
	end
end)

-- ==========================================
-- UI TABS (order: Main, Rebirth, Killing, ...)
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

-- 1 MAIN
local Main = Window:Tab({ Title = "Main", Icon = "user" })
Main:Section({ Title = "Farm" })
Main:Toggle({ Title = "Farm Master", Default = State.FarmMaster, Callback = function(v)
	State.FarmMaster = v
	markDirty()
end })
Main:Section({ Title = "Size" })
Main:Slider({
	Title = "Size",
	Value = { Min = 1, Max = 100, Default = State.Size },
	Step = 1,
	Callback = function(v) State.Size = v markDirty() end
})
Main:Toggle({ Title = "Set Size", Default = State.SetSize, Callback = function(v) State.SetSize = v markDirty() end })
Main:Section({ Title = "Speed" })
Main:Slider({
	Title = "Speed",
	Value = { Min = 16, Max = 500, Default = State.Speed },
	Step = 1,
	Callback = function(v) State.Speed = v markDirty() end
})
Main:Toggle({ Title = "Set Speed", Default = State.SetSpeed, Callback = function(v) State.SetSpeed = v markDirty() end })
Main:Section({ Title = "FOV" })
Main:Slider({
	Title = "FOV",
	Value = { Min = 1, Max = 250, Default = State.FOV },
	Step = 1,
	Callback = function(v) State.FOV = v markDirty() end
})
Main:Toggle({ Title = "Set FOV", Default = State.SetFOV, Callback = function(v)
	State.SetFOV = v
	if Camera then Camera.FieldOfView = v and State.FOV or 70 end
	markDirty()
end })
Main:Section({ Title = "Protection" })
Main:Toggle({ Title = "Anti Fling", Default = State.AntiFling, Callback = function(v)
	State.AntiFling = v
	if v then enableAF() else disableAF() end
	markDirty()
end })
Main:Toggle({ Title = "Lock Position", Default = false, Callback = function(v)
	State.LockPos = v
	if v then local r=root(); if r then State.LockPosVec=r.Position end
	else local r=root(); if r then local bp=r:FindFirstChild("PositionLocker"); if bp then bp:Destroy() end end; State.LockPosVec=nil end
end })
Main:Toggle({ Title = "Infinite Jump", Default = State.InfJump, Callback = function(v) State.InfJump=v markDirty() end })
Main:Toggle({ Title = "Spin Fortune Wheel", Default = State.SpinFortune, Callback = function(v) State.SpinFortune=v markDirty() end })

-- 2 REBIRTH (was Farming)
local Rebirth = Window:Tab({ Title = "Rebirth", Icon = "refresh-cw" })
Rebirth:Section({ Title = "Rebirths" })
Rebirth:Input({ Title = "Rebirth Target", Placeholder = tostring(State.RebirthTarget or 0), Callback = function(v)
	local n = tonumber(v); if n and n >= 0 then State.RebirthTarget = n markDirty() end
end })
Rebirth:Toggle({ Title = "Auto Rebirth", Default = State.AutoRebirth, Callback = function(v) State.AutoRebirth=v markDirty() end })
Rebirth:Toggle({ Title = "Auto Size 1", Default = State.AutoSize1, Callback = function(v) State.AutoSize1=v markDirty() end })
Rebirth:Toggle({ Title = "Auto King", Default = State.AutoKing, Callback = function(v) State.AutoKing=v markDirty() end })
Rebirth:Section({ Title = "Exercises" })
Rebirth:Dropdown({ Title = "Select Exercise", Option = {"Weight","Pushups","Situps","Handstands"}, Callback = function(v)
	State.Exercise = v markDirty()
end })
Rebirth:Toggle({ Title = "Start Exercising", Default = State.AutoExercise, Callback = function(v)
	State.AutoExercise = v
	if v then
		machineState.Squat.Running = false
		machineState.Lift.Running = false
		State.AutoSquat = false
		State.AutoLift = false
	end
	markDirty()
end })
if #SquatNames > 0 then
	Rebirth:Dropdown({ Title = "Select Squat", Option = SquatNames, Callback = function(v) State.SelectedSquat=v end })
end
Rebirth:Toggle({ Title = "Auto Squat", Default = false, Callback = function(v)
	State.AutoSquat = v
	machineState.Squat.Running = v
	machineState.Squat.Active = nil
	if v then
		State.AutoExercise = false
		machineState.Lift.Running = false
		State.AutoLift = false
		runMachine("Squat")
	end
end })
if #LiftNames > 0 then
	Rebirth:Dropdown({ Title = "Select Lift", Option = LiftNames, Callback = function(v) State.SelectedLift=v end })
end
Rebirth:Toggle({ Title = "Auto Lift", Default = false, Callback = function(v)
	State.AutoLift = v
	machineState.Lift.Running = v
	machineState.Lift.Active = nil
	if v then
		State.AutoExercise = false
		machineState.Squat.Running = false
		State.AutoSquat = false
		runMachine("Lift")
	end
end })
Rebirth:Toggle({ Title = "Auto Rep", Default = State.AutoRep, Callback = function(v) State.AutoRep=v markDirty() end })
Rebirth:Section({ Title = "Rocks" })
Rebirth:Dropdown({ Title = "Select Rock", Option = optsFrom(RockData), Callback = function(v) State.SelectedRock=v markDirty() end })
Rebirth:Toggle({ Title = "Auto Rock", Default = State.AutoRock, Callback = function(v) State.AutoRock=v markDirty() end })
Rebirth:Section({ Title = "Better Strength" })
Rebirth:Toggle({ Title = "Pushup + Industrial Rock", Default = State.PushupIndustrial, Callback = function(v) State.PushupIndustrial=v markDirty() end })
Rebirth:Toggle({ Title = "Pushup + Jungle Rock", Default = State.PushupJungle, Callback = function(v) State.PushupJungle=v markDirty() end })
Rebirth:Toggle({ Title = "Pushup + Muscle King Rock", Default = State.PushupKing, Callback = function(v) State.PushupKing=v markDirty() end })
Rebirth:Toggle({ Title = "Pushup + Legends Rock", Default = State.PushupLegends, Callback = function(v) State.PushupLegends=v markDirty() end })

-- 3 KILLING
local Killing = Window:Tab({ Title = "Killing", Icon = "swords" })
Killing:Section({ Title = "Auto Kill" })
Killing:Toggle({ Title = "Kill Everyone", Default = State.KillAll, Callback = function(v) State.KillAll=v markDirty() end })
Killing:Toggle({ Title = "Whitelist Friends", Default = State.WhitelistFriends, Callback = function(v) State.WhitelistFriends=v markDirty() end })
Killing:Toggle({ Title = "Farm Evil Karma", Default = State.FarmEvil, Callback = function(v) State.FarmEvil=v markDirty() end })
Killing:Toggle({ Title = "Farm Good Karma", Default = State.FarmGood, Callback = function(v) State.FarmGood=v markDirty() end })
Killing:Toggle({ Title = "Kill List", Default = State.KillList, Callback = function(v) State.KillList=v markDirty() end })
Killing:Section({ Title = "Kill Aura" })
Killing:Slider({
	Title = "Ring Range",
	Value = { Min = 1, Max = 140, Default = State.RingRange },
	Step = 1,
	Callback = function(v) State.RingRange = v markDirty() end
})
Killing:Toggle({ Title = "Toggle Ring", Default = State.DeathRing, Callback = function(v) State.DeathRing=v markDirty() end })
Killing:Toggle({ Title = "Show Ring", Default = State.ShowRing, Callback = function(v) State.ShowRing=v markDirty() end })
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
	if not v then local h = hum(); if h and Camera then Camera.CameraSubject = h end end
end })

-- Brawl
local Brawl = Window:Tab({ Title = "Brawl", Icon = "shield" })
Brawl:Section({ Title = "Auto Brawl" })
Brawl:Toggle({ Title = "Auto Brawl", Default = State.AutoBrawl, Callback = function(v)
	State.AutoBrawl = v
	if not v then ESPFolder:ClearAllChildren() end
	markDirty()
end })

-- Boss (order: dropdown, kill toggle, continue)
local Boss = Window:Tab({ Title = "Boss", Icon = "skull" })
Boss:Section({ Title = "Boss Farm" })
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
				if State.SelectedBosses[model] == nil then State.SelectedBosses[model] = true end
				table.insert(names, display)
			end
		end
		if #names > 0 then
			Boss:Dropdown({ Title = "Target Bosses", Option = names, Callback = function(display)
				pcall(function()
					for _, rarity in ipairs(cfg.RARITIES) do
						local model = tostring(rarity.BossModel or "")
						local d = tostring(rarity.DisplayName or rarity.Name or model)
						if d == display and model ~= "" then
							State.SelectedBosses[model] = not State.SelectedBosses[model]
							markDirty()
						end
					end
				end)
			end })
		end
	end
end)
Boss:Toggle({ Title = "Auto Farm Boss", Default = State.AutoBoss, Callback = function(v) State.AutoBoss=v markDirty() end })
Boss:Toggle({ Title = "Continue Farming after Boss Kill", Default = State.ContinueBoss, Callback = function(v) State.ContinueBoss=v markDirty() end })

-- Pets
local Pets = Window:Tab({ Title = "Pets", Icon = "heart" })
local pets = petList(false)
local auras = petList(true)
Pets:Section({ Title = "Pet Shop" })
Pets:Dropdown({ Title = "Choose Pet", Option = pets, Callback = function(v)
	if v ~= "None" then toggleList(State.SelectedPets, v) markDirty() end
end })
Pets:Input({ Title = "Buy Amount", Placeholder = tostring(State.PetBuyAmt), Callback = function(v)
	State.PetBuyAmt = math.max(1, math.floor(tonumber(v) or 1)) markDirty()
end })
Pets:Toggle({ Title = "Buy Pet", Default = State.AutoBuyPet, Callback = function(v) State.AutoBuyPet=v markDirty() end })
Pets:Section({ Title = "Auras" })
Pets:Dropdown({ Title = "Choose Aura", Option = auras, Callback = function(v)
	if v ~= "None" then toggleList(State.SelectedAuras, v) markDirty() end
end })
Pets:Input({ Title = "Aura Buy Amount", Placeholder = tostring(State.AuraBuyAmt), Callback = function(v)
	State.AuraBuyAmt = math.max(1, math.floor(tonumber(v) or 1)) markDirty()
end })
Pets:Toggle({ Title = "Buy Aura", Default = State.AutoBuyAura, Callback = function(v) State.AutoBuyAura=v markDirty() end })
Pets:Section({ Title = "Evolve" })
Pets:Dropdown({ Title = "Evolve Pet", Option = pets, Callback = function(v)
	if v ~= "None" then toggleList(State.EvolvePets, v) markDirty() end
end })
Pets:Input({ Title = "Evolve Amount", Placeholder = tostring(State.EvolveAmt), Callback = function(v)
	State.EvolveAmt = math.max(1, math.floor(tonumber(v) or 1)) markDirty()
end })
Pets:Toggle({ Title = "Auto Evolve", Default = State.AutoEvolve, Callback = function(v) State.AutoEvolve=v markDirty() end })
Pets:Section({ Title = "Trading" })
Pets:Dropdown({ Title = "Trade Player", Option = playerOpts(), Callback = function(v)
	local n = parsePlayer(v); if n ~= "No players" then toggleList(State.TradePlayers, n) end
end })
Pets:Button({ Title = "Add All Players", Callback = function()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then addUnique(State.TradePlayers, p.Name) end
	end
end })
Pets:Dropdown({ Title = "Trade Pet", Option = pets, Callback = function(v)
	if v ~= "None" then toggleList(State.TradePets, v) end
end })
Pets:Toggle({ Title = "Auto Trade", Default = false, Callback = function(v) State.AutoTrade=v end })

-- Boosts
local Boosts = Window:Tab({ Title = "Boosts", Icon = "zap" })
Boosts:Section({ Title = "Consumables" })
Boosts:Toggle({ Title = "Eat All Eggs", Default = State.EatEggs, Callback = function(v) State.EatEggs=v end })
Boosts:Toggle({ Title = "Eat All Boosts", Default = State.EatBoosts, Callback = function(v) State.EatBoosts=v end })
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

-- Teleports (no dropdown)
local Teleport = Window:Tab({ Title = "Teleports", Icon = "map-pin" })
Teleport:Section({ Title = "Islands" })
for _, name in ipairs({"Tiny Island", "Main Island", "Beach"}) do
	local cf = Teleports[name]
	Teleport:Button({ Title = name, Callback = function()
		local r = root(); if r and cf then r.CFrame = cf end
	end })
end
Teleport:Section({ Title = "Gyms" })
for _, name in ipairs({
	"Overcharged Gym", "Industrial Gym", "Jungle Gym", "Muscle King Gym",
	"Legends Gym", "Infernal Gym", "Mythical Gym", "Frost Gym"
}) do
	local cf = Teleports[name]
	Teleport:Button({ Title = name, Callback = function()
		local r = root(); if r and cf then r.CFrame = cf end
	end })
end

-- Misc (Diversos)
local Misc = Window:Tab({ Title = "Misc", Icon = "settings" })
Misc:Section({ Title = "Time" })
Misc:Dropdown({
	Title = "Change Time",
	Option = {"Day", "Noon", "Afternoon", "Night", "Midnight"},
	Callback = function(v)
		State.TimeMode = v
		local map = {Day = 9, Noon = 12, Afternoon = 16, Night = 0, Midnight = 2}
		Lighting.ClockTime = map[v] or 9
		markDirty()
	end
})
Misc:Section({ Title = "Render" })
Misc:Toggle({ Title = "Render 3D", Default = State.Render3D, Callback = function(v)
	setRender3D(v)
end })
Misc:Section({ Title = "Hides" })
Misc:Toggle({ Title = "Hide Pets", Default = State.HidePets, Callback = function(v)
	State.HidePets = v
	applyHidePets()
	markDirty()
end })
Misc:Toggle({ Title = "Hide Popups", Default = State.HidePopups, Callback = function(v)
	State.HidePopups = v
	applyHidePopups()
	markDirty()
end })
Misc:Toggle({ Title = "Hide Players", Default = State.HidePlayers, Callback = function(v)
	State.HidePlayers = v
	applyHidePlayers()
	markDirty()
end })
Misc:Toggle({ Title = "Hide Sound", Default = State.HideSound, Callback = function(v)
	State.HideSound = v
	applyHideSound()
	markDirty()
end })
Misc:Toggle({ Title = "Walk on Water", Default = State.WalkWater, Callback = function(v)
	State.WalkWater = v
	if _G.MLWater then
		for _, p in ipairs(_G.MLWater) do
			if p and p.Parent then p.CanCollide = v end
		end
	end
	markDirty()
end })
Misc:Section({ Title = "Performance" })
Misc:Toggle({ Title = "Optimizer", Default = State.Optimizer, Callback = function(v)
	State.Optimizer = v
	applyOptimizer()
	markDirty()
end })
Misc:Button({ Title = "Save Config", Callback = function()
	saveConfig()
	notify("Supreme Hub", "Config saved")
end })
Misc:Button({ Title = "Destroy UI", Callback = function()
	saveConfig()
	pcall(function() Window:Destroy() end)
end })

task.defer(function()
	pcall(function()
		if Window.Open then Window:Open() end
		if Window.SelectFirstTab then Window:SelectFirstTab() end
	end)
end)

notify("Supreme Hub", "Loaded")
print("[Supreme Hub] Loaded")
