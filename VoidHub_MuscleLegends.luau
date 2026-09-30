--[[
    Void Hub | Muscle Legends
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

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

LocalPlayer.Idled:Connect(function()
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new())
end)

local function formatNumber(n)
	if n >= 1e18 then return string.format("%.1fqi", n / 1e18)
	elseif n >= 1e15 then return string.format("%.1fqa", n / 1e15)
	elseif n >= 1e12 then return string.format("%.1ft", n / 1e12)
	elseif n >= 1e9 then return string.format("%.1fb", n / 1e9)
	elseif n >= 1e6 then return string.format("%.1fm", n / 1e6)
	elseif n >= 1e3 then return string.format("%.1fk", n / 1e3)
	else return tostring(n) end
end

local function getCharacter()
	return LocalPlayer.Character
end

local function getHumanoid()
	local char = getCharacter()
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
	local char = getCharacter()
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function getMuscleEvent()
	return LocalPlayer:FindFirstChild("muscleEvent")
end

local function fireRep()
	local ev = getMuscleEvent()
	if ev then pcall(function() ev:FireServer("rep") end) end
end

local function firePunch()
	local ev = getMuscleEvent()
	if not ev then return end
	pcall(function()
		ev:FireServer("punch", "leftHand")
		ev:FireServer("punch", "rightHand")
	end)
end

local function equipPunch()
	local char = getCharacter()
	local hum = getHumanoid()
	if not char or not hum then return end
	local tool = char:FindFirstChild("Punch") or LocalPlayer.Backpack:FindFirstChild("Punch")
	if tool and tool.Parent ~= char then
		pcall(function() hum:EquipTool(tool) end)
	end
end

local function isPlayerAlive(player)
	return player and player.Character
		and player.Character:FindFirstChild("HumanoidRootPart")
		and player.Character:FindFirstChild("Humanoid")
		and player.Character.Humanoid.Health > 0
end

local function isSpawnProtected(player)
	if not player or not player.Character then return false end
	if player.Character:FindFirstChildOfClass("ForceField")
		or player.Character:FindFirstChild("spawnProtectionHighlight") then
		return true
	end
	local untilT = player.Character:GetAttribute("SpawnProtectedUntil")
	return typeof(untilT) == "number" and Workspace:GetServerTimeNow() < untilT
end

local Suffixes = { K = 3, M = 6, B = 9, T = 12, Qa = 15, Qi = 18, Sx = 21, Sp = 24, Oc = 27, No = 30, Dc = 33 }

local function ParseValue(str)
	if not str then return 0 end
	str = string.gsub(tostring(str), ",", "")
	local numStr, suffix = string.match(str, "^([%d%.]+)(%a*)")
	local num = tonumber(numStr)
	if not num then return 0 end
	if suffix and Suffixes[suffix] then num = num * (10 ^ Suffixes[suffix]) end
	return num
end

local function getPlayerStrength(player)
	local stats = player:FindFirstChild("leaderstats")
	local strVal = stats and stats:FindFirstChild("Strength") and stats.Strength.Value or 0
	return ParseValue(strVal)
end

pcall(function()
	for _, portal in pairs(game:GetDescendants()) do
		if portal.Name == "RobloxForwardPortals" then portal:Destroy() end
	end
	game.DescendantAdded:Connect(function(descendant)
		if descendant.Name == "RobloxForwardPortals" then descendant:Destroy() end
	end)
end)

local State = {
	Size = 2, Speed = 120, FOV = 70,
	SetSize = false, SetSpeed = false, SetFOV = false,
	AntiFling = true, LockPosition = false, LockPos = nil,
	HidePets = true, HidePopups = true, InfiniteJump = false, SpinFortune = false,
	KillAll = false, FarmEvilKarma = false, FarmGoodKarma = false, KillList = false,
	DeathRing = false, DeathRingRange = 20, ShowRing = false,
	AutoRebirth = false, RebirthTarget = 0, AutoSize1 = false, AutoKing = false,
	SelectedExercise = "Weight", AutoExercise = false, AutoRep = false,
	AutoRock = false, SelectedRock = nil, AutoBoss = false,
	AutoBuyPet = false, AutoBuyAura = false, AutoEvolve = false,
	EatEggs = false, EatBoosts = false, AutoBrawl = false,
	Whitelist = {}, Killlist = {},
	SelectedPets = {}, SelectedAuras = {}, EvolvePets = {},
	PetBuyAmount = 1, AuraBuyAmount = 1, EvolveAmount = 1,
}

local RockData = {
	["Tiny Rock - 0 Dura"] = 0, ["Large Rock - 100 Dura"] = 100, ["Punching Rock - 10 Dura"] = 10,
	["Golden Rock - 5k Dura"] = 5000, ["Frost Rock - 150k Dura"] = 150000, ["Mythical Rock - 400k Dura"] = 400000,
	["Eternal Rock - 750k Dura"] = 750000, ["Legend Rock - 1m Dura"] = 1000000, ["Muscle King Rock - 5m Dura"] = 5000000,
	["Jungle Rock - 10m Dura"] = 10000000, ["Industrial Rock - 25m Dura"] = 25000000,
}

local TeleportLocations = {
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

local function positionNearTarget(target, heightOffset)
	if not isPlayerAlive(target) or isSpawnProtected(target) or isSpawnProtected(LocalPlayer) then return false end
	local localRoot = getRoot()
	local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	if not localRoot or not targetRoot then return false end
	localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, heightOffset or 3.5, 0)
	localRoot.AssemblyLinearVelocity = Vector3.zero
	localRoot.AssemblyAngularVelocity = Vector3.zero
	return true
end

local function touchAndPunch(target, heightOffset)
	if not positionNearTarget(target, heightOffset) then return false end
	RunService.Heartbeat:Wait()
	if not positionNearTarget(target, heightOffset) then return false end
	local char = getCharacter()
	local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	if not char or not targetRoot then return false end
	local hand = char:FindFirstChild("LeftHand") or char:FindFirstChild("RightHand")
	if not hand then return false end
	equipPunch()
	pcall(function()
		firetouchinterest(targetRoot, hand, 0)
		firetouchinterest(targetRoot, hand, 1)
		firePunch()
	end)
	return true
end

local function attackForDuration(target, duration, shouldContinue, heightOffset)
	local started = os.clock()
	while os.clock() - started < duration
		and (not shouldContinue or shouldContinue())
		and isPlayerAlive(target) and not isSpawnProtected(target) do
		if positionNearTarget(target, heightOffset or 3.5) then
			local char = getCharacter()
			local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
			local left = char and char:FindFirstChild("LeftHand")
			local right = char and char:FindFirstChild("RightHand")
			equipPunch()
			if targetRoot and left and right then
				pcall(function()
					firetouchinterest(targetRoot, left, 0)
					firetouchinterest(targetRoot, left, 1)
					firetouchinterest(targetRoot, right, 0)
					firetouchinterest(targetRoot, right, 1)
					firePunch()
				end)
			end
		end
		RunService.Heartbeat:Wait()
	end
end

local function isWhitelisted(player)
	for _, name in ipairs(State.Whitelist) do
		if name:lower() == player.Name:lower() then return true end
	end
	return false
end

local function isBlacklisted(player)
	for _, name in ipairs(State.Killlist) do
		if name:lower() == player.Name:lower() then return true end
	end
	return false
end

local function matchesKarma(player, farmEvil, farmGood)
	local good = player:FindFirstChild("goodKarma")
	local evil = player:FindFirstChild("evilKarma")
	if not good or not evil then return false end
	local gv, ev = good.Value or 0, evil.Value or 0
	if gv + ev < 5 then return false end
	return (farmEvil and gv > ev) or (farmGood and ev > gv)
end

local function enableAntiFling()
	local root = getRoot()
	if not root then return end
	local old = root:FindFirstChild("BodyVelocity")
	if old and old.MaxForce == Vector3.new(100000, 0, 100000) then old:Destroy() end
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(100000, 0, 100000)
	bv.Velocity = Vector3.zero
	bv.P = 1250
	bv.Parent = root
end

local function disableAntiFling()
	local root = getRoot()
	if not root then return end
	local bv = root:FindFirstChild("BodyVelocity")
	if bv and bv.MaxForce == Vector3.new(100000, 0, 100000) then bv:Destroy() end
end

LocalPlayer.CharacterAdded:Connect(function(char)
	char:WaitForChild("HumanoidRootPart", 5)
	if State.AntiFling then enableAntiFling() end
	if State.LockPosition and char:FindFirstChild("HumanoidRootPart") then
		State.LockPos = char.HumanoidRootPart.Position
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
		if State.LockPosition and State.LockPos then
			local root = getRoot()
			if root then
				local bp = root:FindFirstChild("PositionLocker")
				if bp then
					bp.Position = State.LockPos
				else
					disableAntiFling()
					bp = Instance.new("BodyPosition")
					bp.Name = "PositionLocker"
					bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
					bp.Position = State.LockPos
					bp.P = 100000
					bp.Parent = root
				end
			end
		end
		task.wait(0.05)
	end
end)

UserInputService.JumpRequest:Connect(function()
	if State.InfiniteJump then
		local hum = getHumanoid()
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

task.spawn(function()
	local parts = {}
	local partSize, totalDist = 2048, 50000
	local start = Vector3.new(-2, -9.5, -2)
	for x = 0, math.ceil(totalDist / partSize) - 1 do
		for z = 0, math.ceil(totalDist / partSize) - 1 do
			for _, offset in ipairs({
				{x * partSize, z * partSize}, {-x * partSize, z * partSize},
				{-x * partSize, -z * partSize}, {x * partSize, -z * partSize},
			}) do
				local p = Instance.new("Part")
				p.Size = Vector3.new(partSize, 1, partSize)
				p.Position = start + Vector3.new(offset[1], 0, offset[2])
				p.Anchored = true
				p.Transparency = 1
				p.CanCollide = true
				p.Name = "VoidWaterPart"
				p.Parent = Workspace
				table.insert(parts, p)
			end
		end
	end
	_G.VoidWaterParts = parts
end)

task.spawn(function()
	while true do
		if State.KillAll then
			for _, player in ipairs(Players:GetPlayers()) do
				if not State.KillAll then break end
				if player ~= LocalPlayer and not isWhitelisted(player)
					and isPlayerAlive(player) and not isSpawnProtected(player) then
					attackForDuration(player, 4, function()
						return State.KillAll and not isWhitelisted(player)
					end, 3.5)
				end
			end
			task.wait(0.05)
		else task.wait(0.2) end
	end
end)

task.spawn(function()
	while true do
		if State.FarmEvilKarma or State.FarmGoodKarma then
			for _, player in ipairs(Players:GetPlayers()) do
				if not (State.FarmEvilKarma or State.FarmGoodKarma) then break end
				if player ~= LocalPlayer and not isWhitelisted(player)
					and isPlayerAlive(player) and not isSpawnProtected(player)
					and matchesKarma(player, State.FarmEvilKarma, State.FarmGoodKarma) then
					local hits = 0
					while hits < 4 and isPlayerAlive(player) and not isSpawnProtected(player)
						and matchesKarma(player, State.FarmEvilKarma, State.FarmGoodKarma)
						and (State.FarmEvilKarma or State.FarmGoodKarma) do
						if touchAndPunch(player, 3.5) then hits = hits + 1 end
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
			local target = nil
			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= LocalPlayer and isBlacklisted(player)
					and isPlayerAlive(player) and not isSpawnProtected(player) then
					target = player
					break
				end
			end
			if target then
				while State.KillList and isBlacklisted(target)
					and isPlayerAlive(target) and not isSpawnProtected(target) do
					touchAndPunch(target, 10)
					task.wait(0.05)
				end
			else task.wait(0.1) end
		else task.wait(0.2) end
	end
end)

local RingPart = nil
task.spawn(function()
	while true do
		if State.DeathRing then
			local root = getRoot()
			if root then
				if State.ShowRing then
					if not RingPart or not RingPart.Parent then
						RingPart = Instance.new("Part")
						RingPart.Name = "VoidHubKillAuraRing"
						RingPart.Shape = Enum.PartType.Cylinder
						RingPart.Material = Enum.Material.Neon
						RingPart.Color = Color3.fromRGB(138, 0, 0)
						RingPart.Transparency = 0.6
						RingPart.Anchored = true
						RingPart.CanCollide = false
						RingPart.CanTouch = false
						RingPart.CanQuery = false
						RingPart.CastShadow = false
						RingPart.Size = Vector3.new(0.2, State.DeathRingRange * 2, State.DeathRingRange * 2)
						RingPart.Parent = Workspace
					end
					RingPart.CFrame = root.CFrame * CFrame.Angles(0, 0, math.rad(90))
					RingPart.Size = Vector3.new(0.2, State.DeathRingRange * 2, State.DeathRingRange * 2)
				elseif RingPart then
					RingPart:Destroy()
					RingPart = nil
				end
				local center = root.CFrame
				for _, player in ipairs(Players:GetPlayers()) do
					if not State.DeathRing then break end
					local tr = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
					if player ~= LocalPlayer and not isWhitelisted(player)
						and isPlayerAlive(player) and not isSpawnProtected(player)
						and tr and (center.Position - tr.Position).Magnitude <= State.DeathRingRange then
						local hits = 0
						while hits < 4 and State.DeathRing and isPlayerAlive(player) and not isSpawnProtected(player) do
							local ctr = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
							if not ctr or (center.Position - ctr.Position).Magnitude > State.DeathRingRange then break end
							if touchAndPunch(player, 3.5) then hits = hits + 1 end
							local lr = getRoot()
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

task.spawn(function()
	while true do
		if State.AutoRebirth and State.RebirthTarget > 0 then
			local rebirths = LocalPlayer.leaderstats and LocalPlayer.leaderstats:FindFirstChild("Rebirths")
			if rebirths and rebirths.Value < State.RebirthTarget then
				pcall(function() ReplicatedStorage.rEvents.rebirthRemote:InvokeServer("rebirthRequest") end)
			else
				State.AutoRebirth = false
			end
			task.wait(0.05)
		else task.wait(0.3) end
	end
end)

task.spawn(function()
	while true do
		if State.AutoSize1 then
			pcall(function() ReplicatedStorage.rEvents.changeSpeedSizeRemote:InvokeServer("changeSize", 1) end)
		end
		task.wait(0.05)
	end
end)

task.spawn(function()
	while true do
		if State.AutoKing then
			local root = getRoot()
			local hum = getHumanoid()
			if root and hum and hum.Health > 0 then
				if (root.Position - KingPos.Position).Magnitude > 5 then
					pcall(function() root.CFrame = KingPos end)
				end
			end
			task.wait(0.1)
		else task.wait(0.3) end
	end
end)

task.spawn(function()
	while true do
		if State.AutoExercise and State.SelectedExercise then
			local char = getCharacter()
			local hum = getHumanoid()
			if char and hum and hum.Health > 0 then
				if not char:FindFirstChild(State.SelectedExercise) then
					local tool = LocalPlayer.Backpack:FindFirstChild(State.SelectedExercise)
					if tool then pcall(function() hum:EquipTool(tool) end) task.wait(0.2) end
				end
				if char:FindFirstChild(State.SelectedExercise) then fireRep() end
			end
			task.wait()
		else task.wait(0.2) end
	end
end)

task.spawn(function()
	while true do
		if State.AutoRep then fireRep() task.wait(0.1)
		else task.wait(0.3) end
	end
end)

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
							local left = getCharacter() and getCharacter():FindFirstChild("LeftHand")
							local right = getCharacter() and getCharacter():FindFirstChild("RightHand")
							if left and right then
								pcall(function()
									firetouchinterest(v.Parent.Rock, right, 0)
									firetouchinterest(v.Parent.Rock, right, 1)
									firetouchinterest(v.Parent.Rock, left, 0)
									firetouchinterest(v.Parent.Rock, left, 1)
								end)
								equipPunch()
								firePunch()
							end
						end
					end
				end
			end
			task.wait(0.12)
		else task.wait(0.3) end
	end
end)

task.spawn(function()
	while true do
		if State.SpinFortune then
			pcall(function()
				local remote = ReplicatedStorage.rEvents:FindFirstChild("openFortuneWheelRemote")
				local chances = ReplicatedStorage:FindFirstChild("shared")
					and ReplicatedStorage.shared:FindFirstChild("catalogs")
					and ReplicatedStorage.shared.catalogs:FindFirstChild("fortuneWheelChances")
					and ReplicatedStorage.shared.catalogs.fortuneWheelChances:FindFirstChild("Fortune Wheel")
				if remote and chances then remote:InvokeServer("openFortuneWheel", chances) end
			end)
			task.wait(1)
		else task.wait(0.5) end
	end
end)

task.spawn(function()
	local function findBoss()
		for _, candidate in ipairs(CollectionService:GetTagged("BossEventBoss")) do
			if candidate:IsA("Model") and candidate:IsDescendantOf(Workspace) then
				local hitbox = candidate:FindFirstChild("BossDamageHitbox", true)
				if hitbox and hitbox:IsA("BasePart") then
					local stats = candidate:FindFirstChild("stats")
					local health = stats and stats:FindFirstChild("Health")
					local hp = health and health.Value or Workspace:GetAttribute("BossHealth") or 0
					if typeof(hp) == "number" and hp > 0 then return candidate, hitbox end
				end
			end
		end
	end
	while true do
		if State.AutoBoss then
			local model, hitbox = findBoss()
			if model and hitbox then
				local char = getCharacter()
				local root = getRoot()
				local hum = getHumanoid()
				if root and hum and hum.Health > 0 then
					local head = model:FindFirstChild("Head", true)
					local center = (head and head:IsA("BasePart") and head.Position)
						or (hitbox.Position + Vector3.new(0, hitbox.Size.Y * 0.35, 0))
					root.CFrame = CFrame.lookAt(center, center + hitbox.CFrame.LookVector)
					root.AssemblyLinearVelocity = Vector3.zero
					equipPunch()
					local left = char and char:FindFirstChild("LeftHand")
					local right = char and char:FindFirstChild("RightHand")
					pcall(function()
						if left then firetouchinterest(hitbox, left, 0) firetouchinterest(hitbox, left, 1) end
						if right then firetouchinterest(hitbox, right, 0) firetouchinterest(hitbox, right, 1) end
						firePunch()
					end)
				end
				task.wait(0.05)
			else task.wait(0.25) end
		else task.wait(0.3) end
	end
end)

task.spawn(function()
	while true do
		if State.AutoBuyPet and #State.SelectedPets > 0 then
			local folder = ReplicatedStorage:FindFirstChild("shared")
				and ReplicatedStorage.shared:FindFirstChild("runtime")
				and ReplicatedStorage.shared.runtime:FindFirstChild("cPetShopFolder")
			local remote = ReplicatedStorage.rEvents:FindFirstChild("cPetShopRemote")
			if folder and remote then
				for _, name in ipairs(State.SelectedPets) do
					local item = folder:FindFirstChild(name)
					if item then
						for _ = 1, State.PetBuyAmount do
							task.spawn(function() pcall(function() remote:InvokeServer(item) end) end)
						end
					end
				end
			end
			task.wait(0.15)
		else task.wait(0.4) end
	end
end)

task.spawn(function()
	while true do
		if State.AutoBuyAura and #State.SelectedAuras > 0 then
			local folder = ReplicatedStorage:FindFirstChild("shared")
				and ReplicatedStorage.shared:FindFirstChild("runtime")
				and ReplicatedStorage.shared.runtime:FindFirstChild("cPetShopFolder")
			local remote = ReplicatedStorage.rEvents:FindFirstChild("cPetShopRemote")
			if folder and remote then
				for _, name in ipairs(State.SelectedAuras) do
					local item = folder:FindFirstChild(name)
					if item then
						for _ = 1, State.AuraBuyAmount do
							task.spawn(function() pcall(function() remote:InvokeServer(item) end) end)
						end
					end
				end
			end
			task.wait(0.15)
		else task.wait(0.4) end
	end
end)

task.spawn(function()
	while true do
		if State.AutoEvolve and #State.EvolvePets > 0 then
			for _, name in ipairs(State.EvolvePets) do
				for _ = 1, State.EvolveAmount do
					pcall(function() ReplicatedStorage.rEvents.petEvolveEvent:FireServer("evolvePet", name) end)
				end
			end
			task.wait(0.5)
		else task.wait(0.5) end
	end
end)

task.spawn(function()
	while true do
		if State.EatEggs then
			local tool = (getCharacter() and getCharacter():FindFirstChild("Protein Egg"))
				or LocalPlayer.Backpack:FindFirstChild("Protein Egg")
			if tool then pcall(function() getMuscleEvent():FireServer("proteinEgg", tool) end) end
			task.wait(0.25)
		else task.wait(0.5) end
	end
end)

task.spawn(function()
	local items = {"Tropical Shake", "Energy Shake", "Protein Bar", "TOUGH Bar", "Protein Shake", "ULTRA Shake", "Energy Bar"}
	while true do
		if State.EatBoosts then
			for _, itemName in ipairs(items) do
				local tool = (getCharacter() and getCharacter():FindFirstChild(itemName))
					or LocalPlayer.Backpack:FindFirstChild(itemName)
				if tool then
					local parts = {}
					for word in itemName:gmatch("%S+") do table.insert(parts, word:lower()) end
					for i = 2, #parts do parts[i] = parts[i]:sub(1, 1):upper() .. parts[i]:sub(2) end
					for _ = 1, 10 do pcall(function() getMuscleEvent():FireServer(table.concat(parts), tool) end) end
				end
			end
			task.wait(0.15)
		else task.wait(0.5) end
	end
end)

-- BRAWL
local AreasDeBrawl = {
	{Pos = Vector3.new(4465, 177, -8851), Size = Vector3.new(552, 400, 548)},
	{Pos = Vector3.new(-1856.5, 175, -6315), Size = Vector3.new(499, 400, 496)},
	{Pos = Vector3.new(978, 177, -7433), Size = Vector3.new(502, 400, 504)},
}

local function isInBrawlArea(pos)
	for _, area in ipairs(AreasDeBrawl) do
		local offset = pos - area.Pos
		local half = area.Size / 2
		if math.abs(offset.X) <= half.X and math.abs(offset.Y) <= half.Y and math.abs(offset.Z) <= half.Z then
			return true
		end
	end
	return false
end

local ESPFolder = CoreGui:FindFirstChild("VoidHubBrawlESP")
if ESPFolder then ESPFolder:Destroy() end
ESPFolder = Instance.new("Folder")
ESPFolder.Name = "VoidHubBrawlESP"
ESPFolder.Parent = CoreGui

local function UpdateESP(player, isWeaker)
	local esp = ESPFolder:FindFirstChild(player.Name)
	if not esp then
		esp = Instance.new("Folder")
		esp.Name = player.Name
		esp.Parent = ESPFolder
		local hl = Instance.new("Highlight")
		hl.Name = "Highlight"
		hl.FillTransparency = 0.5
		hl.OutlineTransparency = 0
		hl.Parent = esp
		local bg = Instance.new("BillboardGui")
		bg.Name = "NameTag"
		bg.Size = UDim2.new(0, 100, 0, 25)
		bg.StudsOffset = Vector3.new(0, 2.5, 0)
		bg.AlwaysOnTop = true
		local txt = Instance.new("TextLabel")
		txt.Size = UDim2.new(1, 0, 1, 0)
		txt.BackgroundTransparency = 1
		txt.TextColor3 = Color3.fromRGB(255, 255, 255)
		txt.TextStrokeTransparency = 0
		txt.Font = Enum.Font.GothamBold
		txt.TextSize = 14
		txt.Parent = bg
		bg.Parent = esp
	end
	local hl = esp:FindFirstChild("Highlight")
	if hl then
		hl.Adornee = player.Character
		hl.FillColor = isWeaker and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
	end
	local bg = esp:FindFirstChild("NameTag")
	if bg then
		bg.Adornee = player.Character and player.Character:FindFirstChild("Head")
		local txt = bg:FindFirstChildOfClass("TextLabel")
		if txt then txt.Text = player.Name end
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
	local aggroList = {}
	while true do
		if State.AutoBrawl then
			local myChar = getCharacter()
			local root = getRoot()
			local hum = getHumanoid()
			if myChar and root and hum and hum.Health > 0 then
				local myPos = root.Position
				local myMap = LocalPlayer:FindFirstChild("currentMap") and LocalPlayer.currentMap.Value
				local myStr = getPlayerStrength(LocalPlayer)
				if isInBrawlArea(myPos) then
					local machineInUse = LocalPlayer:FindFirstChild("machineInUse")
					if machineInUse and machineInUse.Value ~= nil then hum.Jump = true end
					for _, player in ipairs(Players:GetPlayers()) do
						if player ~= LocalPlayer and isPlayerAlive(player)
							and isInBrawlArea(player.Character.HumanoidRootPart.Position) then
							aggroList[player] = true
						end
					end
					local alvoFraco, alvoForte = nil, nil
					local distFraco, distForte = math.huge, math.huge
					local currentESP = {}
					for player, _ in pairs(aggroList) do
						if player.Parent and isPlayerAlive(player) then
							local targetMap = player:FindFirstChild("currentMap") and player.currentMap.Value
							if targetMap == myMap then
								local weaker = getPlayerStrength(player) < myStr
								UpdateESP(player, weaker)
								currentESP[player.Name] = true
								local dist = (myPos - player.Character.HumanoidRootPart.Position).Magnitude
								if weaker then
									if dist < distFraco then distFraco = dist; alvoFraco = player.Character end
								else
									if dist < distForte then distForte = dist; alvoForte = player.Character end
								end
							else aggroList[player] = nil end
						else aggroList[player] = nil end
					end
					for _, esp in ipairs(ESPFolder:GetChildren()) do
						if not currentESP[esp.Name] then esp:Destroy() end
					end
					local alvo = alvoFraco or alvoForte
					if alvo and alvo:FindFirstChild("HumanoidRootPart") then
						pcall(function() myChar:SetPrimaryPartCFrame(alvo.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)) end)
						equipPunch()
						local punch = myChar:FindFirstChild("Punch")
						if punch then pcall(function() punch:Activate() end) end
						for _ = 1, 4 do firePunch() end
					end
				else
					aggroList = {}
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
				local gameGui = LocalPlayer.PlayerGui:FindFirstChild("gameGui")
				if gameGui then
					local survivorBonus = gameGui:FindFirstChild("survivorBonusLabel")
					local noBrawlers = gameGui:FindFirstChild("noBrawlersLabel")
					if (survivorBonus and survivorBonus.Visible) and not (noBrawlers and noBrawlers.Visible) then
						local hum = getHumanoid()
						if hum and hum.Health > 0 then hum.Health = 0 task.wait(5) end
					end
				end
			end)
			task.wait(0.5)
		else task.wait(0.5) end
	end
end)

-- ==========================================
-- VOID UI LIBRARY
-- ==========================================
local VoidUI = loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/slowzzx4-8/Ui-library/refs/heads/main/Void%20Ui%20Library.lua"
))()

local Window = VoidUI:CreateWindow({
	Name = "Void Hub | Muscle Legends",
	Theme = "Dark"
})

pcall(function()
	Window:EditOpenButton({
		Title = "Void Hub",
		Transparency = 0.2,
	})
end)

local function playerOptions()
	local opts = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			table.insert(opts, p.DisplayName .. " | " .. p.Name)
		end
	end
	if #opts == 0 then table.insert(opts, "No players") end
	return opts
end

local function petShopList(powerUp)
	local list = {}
	pcall(function()
		local folder = ReplicatedStorage.shared.runtime.cPetShopFolder
		for _, item in ipairs(folder:GetChildren()) do
			if (item:GetAttribute("IsPowerUp") == true) == powerUp then
				table.insert(list, item.Name)
			end
		end
	end)
	table.sort(list)
	if #list == 0 then table.insert(list, "None") end
	return list
end

local function rockOptions()
	local opts = {}
	for name in pairs(RockData) do table.insert(opts, name) end
	table.sort(opts)
	return opts
end

local function teleportOptions()
	local opts = {}
	for name in pairs(TeleportLocations) do table.insert(opts, name) end
	table.sort(opts)
	return opts
end

local function toggleInList(list, value)
	for i = #list, 1, -1 do
		if list[i] == value then table.remove(list, i) return false end
	end
	table.insert(list, value)
	return true
end

-- MAIN
local Main = Window:Tab({ Title = "Main" })
Main:Section({ Title = "User Settings" })

Main:Input({
	Title = "Size Value", Placeholder = "2",
	Callback = function(Value)
		local n = tonumber(Value)
		if n and n > 0 then State.Size = n end
	end
})
Main:Toggle({ Title = "Set Size", Default = false, Callback = function(V) State.SetSize = V end })

Main:Input({
	Title = "Speed Value", Placeholder = "120",
	Callback = function(Value)
		local n = tonumber(Value)
		if n and n > 0 then State.Speed = n end
	end
})
Main:Toggle({ Title = "Set Speed", Default = false, Callback = function(V) State.SetSpeed = V end })

Main:Input({
	Title = "FOV Value", Placeholder = "70",
	Callback = function(Value)
		local n = tonumber(Value)
		if n and n >= 1 and n <= 120 then State.FOV = n end
	end
})
Main:Toggle({
	Title = "Set FOV", Default = false,
	Callback = function(V)
		State.SetFOV = V
		if Camera then Camera.FieldOfView = V and State.FOV or 70 end
	end
})

Main:Section({ Title = "Protection" })
Main:Toggle({
	Title = "Anti Fling", Default = true,
	Callback = function(V)
		State.AntiFling = V
		if V then enableAntiFling() else disableAntiFling() end
	end
})
Main:Toggle({
	Title = "Lock Position", Default = false,
	Callback = function(V)
		State.LockPosition = V
		if V then
			local root = getRoot()
			if root then State.LockPos = root.Position end
		else
			local root = getRoot()
			if root then
				local bp = root:FindFirstChild("PositionLocker")
				if bp then bp:Destroy() end
			end
			State.LockPos = nil
		end
	end
})

Main:Section({ Title = "Visuals" })
Main:Toggle({
	Title = "Hide Pets", Default = true,
	Callback = function(V)
		State.HidePets = V
		pcall(function() ReplicatedStorage.rEvents.showPetsEvent:FireServer(V and "hidePets" or "showPets") end)
	end
})
Main:Toggle({
	Title = "Hide Popups", Default = true,
	Callback = function(V)
		State.HidePopups = V
		pcall(function() ReplicatedStorage.rEvents.savePlayerSizeEvent:FireServer("showPopupsOption") end)
	end
})
Main:Toggle({
	Title = "Walk on Water", Default = true,
	Callback = function(V)
		if _G.VoidWaterParts then
			for _, p in ipairs(_G.VoidWaterParts) do
				if p and p.Parent then p.CanCollide = V end
			end
		end
	end
})
Main:Toggle({ Title = "Infinite Jump", Default = false, Callback = function(V) State.InfiniteJump = V end })
Main:Toggle({ Title = "Spin Fortune Wheel", Default = false, Callback = function(V) State.SpinFortune = V end })
Main:Dropdown({
	Title = "Change Time",
	Option = { "Day", "Night" },
	Callback = function(V) Lighting.ClockTime = V == "Night" and 0 or 9 end
})

-- KILLING
local Killing = Window:Tab({ Title = "Killing" })
Killing:Section({ Title = "Pets" })
Killing:Button({
	Title = "Equip Best Damage",
	Callback = function()
		local priority = {"Wild Wizard", "Chaos Sorcerer", "Mighty Monster", "Small Fry"}
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
					count = count + 1
					task.wait(0.1)
				end
			end
		end)
	end
})
Killing:Button({
	Title = "Equip Best Health",
	Callback = function()
		local priority = {"Mighty Monster", "Small Fry", "Wild Wizard", "Chaos Sorcerer"}
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
					count = count + 1
					task.wait(0.1)
				end
			end
		end)
	end
})

Killing:Section({ Title = "Auto Kill" })
Killing:Toggle({ Title = "Kill Everyone", Default = false, Callback = function(V) State.KillAll = V end })
Killing:Toggle({ Title = "Farm Evil Karma", Default = false, Callback = function(V) State.FarmEvilKarma = V end })
Killing:Toggle({ Title = "Farm Good Karma", Default = false, Callback = function(V) State.FarmGoodKarma = V end })
Killing:Toggle({ Title = "Kill List", Default = false, Callback = function(V) State.KillList = V end })

Killing:Section({ Title = "Kill Aura" })
Killing:Input({
	Title = "Ring Range (1-140)", Placeholder = "20",
	Callback = function(V)
		local n = tonumber(V)
		if n then State.DeathRingRange = math.clamp(n, 1, 140) end
	end
})
Killing:Toggle({ Title = "Toggle Ring", Default = false, Callback = function(V) State.DeathRing = V end })
Killing:Toggle({ Title = "Show Ring", Default = false, Callback = function(V) State.ShowRing = V end })

Killing:Section({ Title = "Lists" })
Killing:Dropdown({
	Title = "Add to Whitelist",
	Option = playerOptions(),
	Callback = function(Value)
		local name = Value:match("| (.+)$") or Value
		name = name:gsub("^%s*(.-)%s*$", "%1")
		if name == "No players" then return end
		for _, n in ipairs(State.Whitelist) do
			if n:lower() == name:lower() then return end
		end
		table.insert(State.Whitelist, name)
	end
})
Killing:Button({ Title = "Clear Whitelist", Callback = function() State.Whitelist = {} end })
Killing:Dropdown({
	Title = "Add to Killlist",
	Option = playerOptions(),
	Callback = function(Value)
		local name = Value:match("| (.+)$") or Value
		name = name:gsub("^%s*(.-)%s*$", "%1")
		if name == "No players" then return end
		for _, n in ipairs(State.Killlist) do
			if n:lower() == name:lower() then return end
		end
		table.insert(State.Killlist, name)
	end
})
Killing:Button({ Title = "Clear Killlist", Callback = function() State.Killlist = {} end })

-- BRAWL
local Brawl = Window:Tab({ Title = "Brawl" })
Brawl:Section({ Title = "Auto Brawl" })
Brawl:Toggle({
	Title = "Auto Brawl",
	Desc = "Join, kill weaker first, ESP, anti-seat, auto reset on win",
	Default = false,
	Callback = function(V)
		State.AutoBrawl = V
		if not V then ESPFolder:ClearAllChildren() end
	end
})
Brawl:Label({
	Title = "Info",
	Desc = "Green ESP = weaker | Red ESP = stronger"
})

-- FARMING
local Farming = Window:Tab({ Title = "Farming" })
Farming:Section({ Title = "Rebirths" })
Farming:Input({
	Title = "Rebirth Target", Placeholder = "0",
	Callback = function(V)
		local n = tonumber(V)
		if n and n >= 0 then State.RebirthTarget = n end
	end
})
Farming:Toggle({ Title = "Auto Rebirth", Default = false, Callback = function(V) State.AutoRebirth = V end })
Farming:Toggle({ Title = "Auto Size 1", Default = false, Callback = function(V) State.AutoSize1 = V end })
Farming:Toggle({ Title = "Auto King", Default = false, Callback = function(V) State.AutoKing = V end })

Farming:Section({ Title = "Exercises" })
Farming:Dropdown({
	Title = "Select Exercise",
	Option = { "Weight", "Pushups", "Situps", "Handstands" },
	Callback = function(V) State.SelectedExercise = V end
})
Farming:Toggle({ Title = "Start Exercising", Default = false, Callback = function(V) State.AutoExercise = V end })
Farming:Toggle({ Title = "Auto Rep", Default = false, Callback = function(V) State.AutoRep = V end })

Farming:Section({ Title = "Rocks" })
Farming:Dropdown({
	Title = "Select Rock",
	Option = rockOptions(),
	Callback = function(V) State.SelectedRock = V end
})
Farming:Toggle({ Title = "Auto Rock", Default = false, Callback = function(V) State.AutoRock = V end })

-- BOSS
local Boss = Window:Tab({ Title = "Boss" })
Boss:Section({ Title = "Boss Farm" })
Boss:Toggle({ Title = "Auto Farm Boss", Default = false, Callback = function(V) State.AutoBoss = V end })

-- PETS
local Pets = Window:Tab({ Title = "Pets" })
local petList = petShopList(false)
local auraList = petShopList(true)

Pets:Section({ Title = "Pet Shop" })
Pets:Dropdown({
	Title = "Choose Pet (toggle select)",
	Option = petList,
	Callback = function(V)
		if V == "None" then return end
		toggleInList(State.SelectedPets, V)
	end
})
Pets:Input({
	Title = "Buy Amount", Placeholder = "1",
	Callback = function(V) State.PetBuyAmount = math.max(1, math.floor(tonumber(V) or 1)) end
})
Pets:Toggle({ Title = "Buy Pet", Default = false, Callback = function(V) State.AutoBuyPet = V end })

Pets:Section({ Title = "Auras" })
Pets:Dropdown({
	Title = "Choose Aura (toggle select)",
	Option = auraList,
	Callback = function(V)
		if V == "None" then return end
		toggleInList(State.SelectedAuras, V)
	end
})
Pets:Input({
	Title = "Aura Buy Amount", Placeholder = "1",
	Callback = function(V) State.AuraBuyAmount = math.max(1, math.floor(tonumber(V) or 1)) end
})
Pets:Toggle({ Title = "Buy Aura", Default = false, Callback = function(V) State.AutoBuyAura = V end })

Pets:Section({ Title = "Evolve" })
Pets:Dropdown({
	Title = "Evolve Pet (toggle select)",
	Option = petList,
	Callback = function(V)
		if V == "None" then return end
		toggleInList(State.EvolvePets, V)
	end
})
Pets:Input({
	Title = "Evolve Amount", Placeholder = "1",
	Callback = function(V) State.EvolveAmount = math.max(1, math.floor(tonumber(V) or 1)) end
})
Pets:Toggle({ Title = "Auto Evolve", Default = false, Callback = function(V) State.AutoEvolve = V end })

-- BOOSTS
local Boosts = Window:Tab({ Title = "Boosts" })
Boosts:Section({ Title = "Consumables" })
Boosts:Toggle({ Title = "Eat All Eggs", Default = false, Callback = function(V) State.EatEggs = V end })
Boosts:Toggle({
	Title = "Eat All Boosts",
	Desc = "May cause lag",
	Default = false,
	Callback = function(V) State.EatBoosts = V end
})

-- TELEPORTS
local Teleport = Window:Tab({ Title = "Teleports" })
Teleport:Section({ Title = "Locations" })
local selectedTp = nil
Teleport:Dropdown({
	Title = "Destination",
	Option = teleportOptions(),
	Callback = function(V) selectedTp = V end
})
Teleport:Button({
	Title = "Teleport",
	Callback = function()
		if selectedTp and TeleportLocations[selectedTp] then
			local root = getRoot()
			if root then root.CFrame = TeleportLocations[selectedTp] end
		end
	end
})
for name, cf in pairs(TeleportLocations) do
	Teleport:Button({
		Title = name,
		Callback = function()
			local root = getRoot()
			if root then root.CFrame = cf end
		end
	})
end

-- STATS
local StatsTab = Window:Tab({ Title = "Stats" })
StatsTab:Section({ Title = "Session" })
local startTime = tick()
local initialStats = {}
pcall(function()
	local ls = LocalPlayer:WaitForChild("leaderstats", 5)
	if ls then
		for _, name in ipairs({ "Strength", "Rebirths", "Kills", "Brawls" }) do
			local s = ls:FindFirstChild(name)
			if s then initialStats[name] = s.Value end
		end
	end
end)
StatsTab:Button({
	Title = "Print Stats to Console",
	Callback = function()
		print(string.format("[Void Hub] Session: %.0fs", tick() - startTime))
		local ls = LocalPlayer:FindFirstChild("leaderstats")
		if ls then
			for _, name in ipairs({ "Strength", "Rebirths", "Kills", "Brawls" }) do
				local s = ls:FindFirstChild(name)
				if s then
					local gained = s.Value - (initialStats[name] or s.Value)
					print(name, formatNumber(s.Value), "Gained:", formatNumber(gained))
				end
			end
		end
	end
})

-- INFO
local Info = Window:Tab({ Title = "Info" })
Info:Section({ Title = "Void Hub" })
Info:Label({
	Title = "Muscle Legends",
	Desc = "Use the floating open button to show or hide the UI."
})
Info:Button({
	Title = "Destroy UI",
	Callback = function()
		pcall(function() Window:Destroy() end)
	end
})

print("[Void Hub] Loaded successfully")
