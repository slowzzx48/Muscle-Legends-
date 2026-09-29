--[[
    VIEW INVENTORY @Slowzzx4
    - Status as main tab, real-time updates
    - Left buttons with gradient + icons (IconsV2 / lucide)
    - Section titles for all areas
    - Invite Trade locked with sound while Status is open
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = (gethui and gethui()) or game:GetService("CoreGui")

if CoreGui:FindFirstChild("PetViewerGui") then
    CoreGui.PetViewerGui:Destroy()
end

-- ============================================
-- ICONS SUPPORT (IconsV2 - lucide)
-- ============================================
local IconsV2 = loadstring(game:HttpGetAsync(
    "https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua"
))()
IconsV2.SetIconsType("lucide")

local function GetIcon(icon)
    if typeof(icon) == "string" and icon:find("rbxassetid://") then
        return icon
    end
    if typeof(icon) == "string" and icon:find(":") then
        local pack, name = icon:match("([^:]+):(.+)")
        if pack and name then
            IconsV2.SetIconsType(string.lower(pack))
            local data = IconsV2.GetIcon(name)
            if typeof(data) == "table" then return data.Image or data[1] or "" end
            return data or ""
        end
    end
    IconsV2.SetIconsType("lucide")
    local data = IconsV2.GetIcon(icon)
    if typeof(data) == "table" then return data.Image or data[1] or "" end
    return data or ""
end

local LocalPlayer = Players.LocalPlayer
local selectedPlayer = LocalPlayer
local currentViewedItem = nil 
local currentViewMode = "status"
local isStackedView = true 
local autoUpdateConnectionAdded = nil
local autoUpdateConnectionRemoved = nil
local isUpdating = false
local rainbowObjects = {} -- UIStroke (Color) ou GuiObject (BackgroundColor3)

local currentSearchQuery = ""

local realDisplayName, realUserName, realUserId = "", "", ""

-- SOUND SYSTEM
local function playSound(id)
    task.spawn(function()
        local sound = Instance.new("Sound")
        sound.SoundId = id
        sound.Volume = 1
        sound.Parent = SoundService
        sound:Play()
        sound.Ended:Connect(function()
            sound:Destroy()
        end)
    end)
end

local SOUNDS = {
    CARD_CLICK = "rbxassetid://3610999518",
    BRAWL_ERROR = "rbxassetid://3611171767",
    UI_CLICK = "rbxassetid://2818606146"
}

local RARITY_MAP = {
    ["unique"]    = { name = "Unique",   color = Color3.fromRGB(255, 120, 0), order = 2 },
    ["epic"]      = { name = "Epic",     color = Color3.fromRGB(170, 0, 255), order = 3 },
    ["rare"]      = { name = "Rare",     color = Color3.fromRGB(0, 150, 255), order = 4 },
    ["advance"]   = { name = "Advance",  color = Color3.fromRGB(0, 255, 0),   order = 5 },
    ["advanced"]  = { name = "Advance",  color = Color3.fromRGB(0, 255, 0),   order = 5 }, 
    ["incomum"]   = { name = "Advance",  color = Color3.fromRGB(0, 255, 0),   order = 5 }, 
    ["uncommon"]  = { name = "Advance",  color = Color3.fromRGB(0, 255, 0),   order = 5 }, 
    ["common"]    = { name = "Common",   color = Color3.fromRGB(200, 200, 200), order = 6 },
    ["comum"]     = { name = "Common",   color = Color3.fromRGB(200, 200, 200), order = 6 },
    ["basic"]     = { name = "Common",   color = Color3.fromRGB(200, 200, 200), order = 6 },
    ["básico"]    = { name = "Common",   color = Color3.fromRGB(200, 200, 200), order = 6 },
    ["basico"]    = { name = "Common",   color = Color3.fromRGB(200, 200, 200), order = 6 },
    ["admin"]     = { name = "Admin",    color = Color3.fromRGB(255, 255, 255), order = 0, isRainbow = true },
    ["legendary"] = { name = "Legendary",color = Color3.fromRGB(255, 215, 0), order = 1 }
}

local PERK_CONFIG = {
    ["strength"]   = { icon = "💪", name = "Strength", color = Color3.fromRGB(255, 230, 0) },   
    ["durability"] = { icon = "🛡️", name = "Durability", color = Color3.fromRGB(0, 150, 255) }, 
    ["agility"]    = { icon = "⚡", name = "Agility", color = Color3.fromRGB(0, 255, 80) },     
    ["damage"]     = { icon = "⚔️", name = "Damage", color = Color3.fromRGB(255, 50, 50) }      
}
local PERK_ORDER = {"strength", "durability", "agility", "damage"}

local SUFFIXES = {"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc", "Ud", "Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Ocd", "Nod", "Vg"}
local function formatNumber(n)
    n = tonumber(n) or 0
    if n < 1000 then return tostring(math.floor(n)) end
    local suffixIndex = math.floor(math.log10(n) / 3) + 1
    if suffixIndex > #SUFFIXES then suffixIndex = #SUFFIXES end
    local short = n / (10 ^ ((suffixIndex - 1) * 3))
    return string.format("%.1f%s", short, SUFFIXES[suffixIndex]):gsub("%.0", "")
end

local function colorToHex(color)
    return string.format("#%02X%02X%02X", math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255))
end

local function createStroke(parent, color, thickness, mode)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(0, 0, 0)
    stroke.Thickness = thickness or 1.5
    stroke.ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

local function extractItemImage(inst)
    if not inst then return "" end
    local function checkValueForImage(val)
        if not val then return nil end
        local sVal = tostring(val)
        if string.find(sVal, "rbxassetid://") or string.find(sVal, "http") then return sVal end
        local justId = string.match(sVal, "^%d+$")
        if justId and tonumber(justId) > 1000 then return "rbxassetid://" .. justId end
        return nil
    end

    local directValue = nil
    pcall(function() directValue = inst.Value end)
    if directValue then
        local img = checkValueForImage(directValue)
        if img then return img end
    end

    for _, obj in ipairs(inst:GetDescendants()) do
        if obj:IsA("StringValue") or obj:IsA("IntValue") or obj:IsA("NumberValue") then
            local img = checkValueForImage(obj.Value)
            if img then return img end
        end
        if obj:IsA("Decal") or obj:IsA("Texture") then return obj.Texture end
        if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then return obj.Image end
        if obj:IsA("MeshPart") then return obj.TextureID end
        if obj:IsA("SpecialMesh") then return obj.TextureId end
    end
    return "" 
end

local function getItemData(inst)
    local isEv = inst:FindFirstChild("evolved")
    local lvlVal = inst:FindFirstChild("level")
    local strength = 0
    local perks = inst:FindFirstChild("perksFolder")
    if perks then
        local strVal = perks:FindFirstChild("strength") or perks:FindFirstChild("Strength")
        if strVal then strength = tonumber(strVal.Value) or 0 end
    end
    return {
        isEvolved = isEv and (not isEv:IsA("ValueBase") or isEv.Value == true) or false,
        level = lvlVal and tostring(lvlVal.Value) or "1",
        strength = strength,
    }
end

-- GUI PRINCIPAL
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "PetViewerGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local ToggleBtn = Instance.new("TextButton", ScreenGui)
ToggleBtn.Size = UDim2.new(0, 40, 0, 40)
ToggleBtn.Position = UDim2.new(0.5, -450, 0.5, -225) 
ToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
ToggleBtn.Text = "SL"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 22
ToggleBtn.ZIndex = 50 
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 8)
createStroke(ToggleBtn, Color3.fromRGB(60, 60, 60), 2)

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 420, 0, 450)
MainFrame.Position = UDim2.new(0.5, -120, 0.5, -225) 
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
MainFrame.Active = true
MainFrame.Visible = false
MainFrame.ZIndex = 10
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
createStroke(MainFrame, Color3.fromRGB(40, 40, 40), 2)

local ItemStatusFrame = Instance.new("Frame", MainFrame)
ItemStatusFrame.Size = UDim2.new(0, 245, 0, 300)
ItemStatusFrame.Position = UDim2.new(1, 12, 0, 0)
ItemStatusFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ItemStatusFrame.Visible = false
ItemStatusFrame.Active = true
ItemStatusFrame.ZIndex = 5
Instance.new("UICorner", ItemStatusFrame).CornerRadius = UDim.new(0, 8)
createStroke(ItemStatusFrame, Color3.fromRGB(45, 45, 45), 2)

local LeftButtonsContainer = Instance.new("Frame", MainFrame)
LeftButtonsContainer.Size = UDim2.new(0, 40, 0, 340) 
LeftButtonsContainer.Position = UDim2.new(0, -48, 0, 0)
LeftButtonsContainer.BackgroundTransparency = 1
LeftButtonsContainer.ZIndex = 20

local LeftLayout = Instance.new("UIListLayout", LeftButtonsContainer)
LeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
LeftLayout.Padding = UDim.new(0, 24) 

-- SECTION TITLE (original position)
local SectionTitleLabel = Instance.new("TextLabel", MainFrame)
SectionTitleLabel.Size = UDim2.new(0.92, 0, 0, 20)
SectionTitleLabel.Position = UDim2.new(0.04, 0, 0, 124)
SectionTitleLabel.BackgroundTransparency = 1
SectionTitleLabel.Text = "STATUS"
SectionTitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SectionTitleLabel.Font = Enum.Font.GothamBlack
SectionTitleLabel.TextSize = 14
SectionTitleLabel.ZIndex = 12
SectionTitleLabel.TextXAlignment = Enum.TextXAlignment.Center
createStroke(SectionTitleLabel, Color3.fromRGB(0, 0, 0), 2).ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

local loadPlayerItems, setupAutoUpdate, updatePlayerStatusDisplay, rebuildStatusUI
local PetScroll, StatusMainFrame, EmptyLabel, StatusLeftScroll
local cachedStatLabels = {}

local function updateSectionTitle(title)
    SectionTitleLabel.Text = string.upper(title)
end

-- SEARCH: filters open content (stats or cards) of the selected player
local SearchBox -- definido depois no topo
local function applySearch()
    if not SearchBox then return end
    local q = string.lower(SearchBox.Text or ""):gsub("%s+", "")
    currentSearchQuery = q

    if currentViewMode == "status" then
        for _, child in ipairs(StatusLeftScroll:GetChildren()) do
            if child:IsA("Frame") and child.Name:find("Stat_") then
                local name = string.lower(child.Name:gsub("Stat_", ""))
                child.Visible = (q == "" or string.find(name, q, 1, true) ~= nil)
            end
        end
    else
        for _, child in pairs(PetScroll:GetChildren()) do
            if child:IsA("TextButton") then
                local itemName = string.lower(child.Name or "")
                child.Visible = (q == "" or string.find(itemName, q, 1, true) ~= nil)
            end
        end
    end
end

-- LEFT BUTTONS WITH ICONS
local function createLeftButton(textName, iconName, order, onClick)
    local btn = Instance.new("TextButton", LeftButtonsContainer)
    btn.Size = UDim2.new(0, 40, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = ""
    btn.LayoutOrder = order
    btn.ZIndex = 21
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    createStroke(btn, Color3.fromRGB(0, 0, 0), 2)

    -- Black gradient background
    local grad = Instance.new("UIGradient", btn)
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 10))
    }
    grad.Rotation = 90
    
    -- Ícone central
    local iconImg = Instance.new("ImageLabel", btn)
    iconImg.Size = UDim2.new(0, 22, 0, 22)
    iconImg.Position = UDim2.new(0.5, 0, 0.5, -2)
    iconImg.AnchorPoint = Vector2.new(0.5, 0.5)
    iconImg.BackgroundTransparency = 1
    iconImg.Image = GetIcon(iconName)
    iconImg.ImageColor3 = Color3.fromRGB(255, 255, 255)
    iconImg.ScaleType = Enum.ScaleType.Fit
    iconImg.ZIndex = 22

    -- Texto abaixo
    local btnText = Instance.new("TextLabel", btn)
    btnText.Size = UDim2.new(2, 0, 0, 16)
    btnText.Position = UDim2.new(0.5, 0, 1, 0)
    btnText.AnchorPoint = Vector2.new(0.5, 0.5)
    btnText.BackgroundTransparency = 1
    btnText.Text = textName
    btnText.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnText.Font = Enum.Font.GothamBlack
    btnText.TextSize = 10
    btnText.ZIndex = 22
    createStroke(btnText, Color3.fromRGB(0, 0, 0), 2).ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

    btn.MouseButton1Click:Connect(function()
        playSound(SOUNDS.UI_CLICK)
        onClick()
    end)
    return btn
end

createLeftButton("Status", "user", 1, function()
    currentViewMode = "status"
    updateSectionTitle("Player Status")
    PetScroll.Visible = false
    EmptyLabel.Visible = false
    StatusMainFrame.Visible = true
    ItemStatusFrame.Visible = false
    rebuildStatusUI()
end)

createLeftButton("Pets", "paw-print", 2, function()
    currentViewMode = "petsFolder"
    updateSectionTitle("Pets")
    StatusMainFrame.Visible = false
    PetScroll.Visible = true
    ItemStatusFrame.Visible = false
    currentViewedItem = nil
    loadPlayerItems()
    setupAutoUpdate()
end)

createLeftButton("Auras", "sparkles", 3, function()
    currentViewMode = "powerUpsFolder"
    updateSectionTitle("Auras")
    StatusMainFrame.Visible = false
    PetScroll.Visible = true
    ItemStatusFrame.Visible = false
    currentViewedItem = nil
    loadPlayerItems()
    setupAutoUpdate()
end)

createLeftButton("Skins", "shirt", 4, function()
    currentViewMode = "machineSkinsFolder"
    updateSectionTitle("Skins")
    StatusMainFrame.Visible = false
    PetScroll.Visible = true
    ItemStatusFrame.Visible = false
    currentViewedItem = nil
    loadPlayerItems()
    setupAutoUpdate()
end)

createLeftButton("Boost", "rocket", 5, function()
    currentViewMode = "consumablesFolder"
    updateSectionTitle("Boosts")
    StatusMainFrame.Visible = false
    PetScroll.Visible = true
    ItemStatusFrame.Visible = false
    currentViewedItem = nil
    loadPlayerItems()
    setupAutoUpdate()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    playSound(SOUNDS.UI_CLICK)
    MainFrame.Visible = not MainFrame.Visible
    if not MainFrame.Visible then
        ItemStatusFrame.Visible = false
    end
end)

local function addSubtleGradient(frame)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(26, 26, 26)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 12, 12))
    }
    gradient.Rotation = 90
    gradient.Parent = frame
end
addSubtleGradient(MainFrame)
addSubtleGradient(ItemStatusFrame)

local TitleLabel = Instance.new("TextLabel", MainFrame)
TitleLabel.Size = UDim2.new(0, 180, 0, 36)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.RichText = true
TitleLabel.Text = "VIEW INVENTORY By <font color='#FF0000'>@Slowzzx4</font>"
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 13
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 11
createStroke(TitleLabel, Color3.fromRGB(0, 0, 0), 2).ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

-- ========== TOPO: Search | Minimize | Fullscreen | Destroy ==========
local TopControls = Instance.new("Frame", MainFrame)
TopControls.Name = "TopControls"
TopControls.Size = UDim2.new(0, 210, 0, 28)
TopControls.Position = UDim2.new(1, -218, 0, 4)
TopControls.BackgroundTransparency = 1
TopControls.ZIndex = 25

local topList = Instance.new("UIListLayout", TopControls)
topList.FillDirection = Enum.FillDirection.Horizontal
topList.HorizontalAlignment = Enum.HorizontalAlignment.Right
topList.VerticalAlignment = Enum.VerticalAlignment.Center
topList.Padding = UDim.new(0, 6)
topList.SortOrder = Enum.SortOrder.LayoutOrder

-- Search (metade, compacto)
local SearchF = Instance.new("Frame", TopControls)
SearchF.Name = "Search"
SearchF.Size = UDim2.new(0, 100, 0, 24)
SearchF.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
SearchF.BorderSizePixel = 0
SearchF.LayoutOrder = 1
SearchF.ZIndex = 26
Instance.new("UICorner", SearchF).CornerRadius = UDim.new(0, 8)
createStroke(SearchF, Color3.fromRGB(60, 60, 60), 1)

local SearchIcon = Instance.new("ImageLabel", SearchF)
SearchIcon.Size = UDim2.new(0, 13, 0, 13)
SearchIcon.Position = UDim2.new(0, 5, 0.5, 0)
SearchIcon.AnchorPoint = Vector2.new(0, 0.5)
SearchIcon.BackgroundTransparency = 1
SearchIcon.Image = GetIcon("search")
SearchIcon.ImageColor3 = Color3.fromRGB(180, 180, 190)
SearchIcon.ZIndex = 27

SearchBox = Instance.new("TextBox", SearchF)
SearchBox.Size = UDim2.new(1, -24, 1, 0)
SearchBox.Position = UDim2.new(0, 20, 0, 0)
SearchBox.BackgroundTransparency = 1
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 11
SearchBox.Text = ""
SearchBox.PlaceholderText = "Search..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(140, 140, 140)
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.ClearTextOnFocus = false
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ZIndex = 27

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    applySearch()
end)

local function makeIconBtn(name, iconName, size, order)
    local b = Instance.new("ImageButton", TopControls)
    b.Name = name
    b.Size = UDim2.new(0, size, 0, size)
    b.BackgroundTransparency = 1
    b.Image = GetIcon(iconName)
    b.ImageColor3 = Color3.fromRGB(200, 200, 210)
    b.LayoutOrder = order
    b.ZIndex = 26
    return b
end

local MinimizeBtn = makeIconBtn("Minimize", "minus", 18, 2)
local FullscreenBtn = makeIconBtn("Fullscreen", "maximize", 16, 3)
local DestroyBtn = makeIconBtn("Cross", "x", 18, 4)

MinimizeBtn.MouseButton1Click:Connect(function()
    playSound(SOUNDS.UI_CLICK)
    MainFrame.Visible = false
    ItemStatusFrame.Visible = false
end)

FullscreenBtn.MouseButton1Click:Connect(function()
    -- visual only, no function
end)

DestroyBtn.MouseButton1Click:Connect(function()
    playSound(SOUNDS.UI_CLICK)
    if ScreenGui and ScreenGui.Parent then
        ScreenGui:Destroy()
    end
end)

local function makeDraggable(guiElement, dragArea)
    local dragging, dragInput, dragStart, startPos
    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = guiElement.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    dragArea.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            guiElement.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

makeDraggable(MainFrame, TitleLabel)
makeDraggable(ToggleBtn, ToggleBtn)

-- PAINEL DO PERFIL DO JOGADOR
local ProfileFrame = Instance.new("Frame", MainFrame)
ProfileFrame.Size = UDim2.new(0.92, 0, 0, 50)
ProfileFrame.Position = UDim2.new(0.04, 0, 0, 36)
ProfileFrame.BackgroundTransparency = 1
ProfileFrame.ZIndex = 11

local AvatarBg = Instance.new("Frame", ProfileFrame)
AvatarBg.Size = UDim2.new(0, 46, 0, 46)
AvatarBg.Position = UDim2.new(0, 0, 0.5, -23)
AvatarBg.BackgroundColor3 = Color3.fromRGB(255, 255, 255) 
AvatarBg.ZIndex = 12
Instance.new("UICorner", AvatarBg).CornerRadius = UDim.new(0, 10)
local AvatarStroke = Instance.new("UIStroke", AvatarBg)
AvatarStroke.Thickness = 2
AvatarStroke.Color = Color3.fromRGB(0, 0, 0)
local AvatarGrad = Instance.new("UIGradient", AvatarBg)
AvatarGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 40)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 5, 5))
}
AvatarGrad.Rotation = 90

local AvatarImage = Instance.new("ImageLabel", AvatarBg)
AvatarImage.Size = UDim2.new(1, 0, 1, 0)
AvatarImage.BackgroundTransparency = 1
AvatarImage.ZIndex = 13
Instance.new("UICorner", AvatarImage).CornerRadius = UDim.new(0, 10)

local UserInfoFrame = Instance.new("Frame", ProfileFrame)
UserInfoFrame.Size = UDim2.new(1, -56, 1, 0)
UserInfoFrame.Position = UDim2.new(0, 54, 0, 0)
UserInfoFrame.BackgroundTransparency = 1
UserInfoFrame.ZIndex = 12

local UserNameLabel = Instance.new("TextLabel", UserInfoFrame)
UserNameLabel.Size = UDim2.new(1, 0, 0, 22)
UserNameLabel.Position = UDim2.new(0, 0, 0, 4)
UserNameLabel.BackgroundTransparency = 1
UserNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
UserNameLabel.Font = Enum.Font.GothamBold
UserNameLabel.TextSize = 13
UserNameLabel.ZIndex = 12
UserNameLabel.TextXAlignment = Enum.TextXAlignment.Left

local UserIdLabel = Instance.new("TextLabel", UserInfoFrame)
UserIdLabel.Size = UDim2.new(1, 0, 0, 18)
UserIdLabel.Position = UDim2.new(0, 0, 0, 24)
UserIdLabel.BackgroundTransparency = 1
UserIdLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
UserIdLabel.Font = Enum.Font.GothamBold
UserIdLabel.TextSize = 11
UserIdLabel.ZIndex = 12
UserIdLabel.TextXAlignment = Enum.TextXAlignment.Left

local updateDropdown
local resetToLocalPlayer

local function updateProfileDisplay(plr)
    if not plr then return end
    realDisplayName = plr.DisplayName
    if plr == LocalPlayer then
        UserNameLabel.Text = realDisplayName .. " (You)"
        UserIdLabel.Text = "You"
    else
        realUserName = plr.Name
        realUserId = tostring(plr.UserId)
        UserNameLabel.Text = realDisplayName .. " (@" .. realUserName .. ")"
        UserIdLabel.Text = "ID: " .. realUserId
    end
    task.spawn(function()
        local content, _ = Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        AvatarImage.Image = content or ""
    end)
end

-- PLAYER SELECTION DROPDOWN
local DropdownBtn = Instance.new("TextButton", MainFrame)
DropdownBtn.Size = UDim2.new(0.92, 0, 0, 26)
DropdownBtn.Position = UDim2.new(0.04, 0, 0, 92)
DropdownBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35) 
DropdownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DropdownBtn.Font = Enum.Font.GothamBold
DropdownBtn.TextSize = 12
DropdownBtn.TextXAlignment = Enum.TextXAlignment.Left
DropdownBtn.ZIndex = 12
Instance.new("UICorner", DropdownBtn).CornerRadius = UDim.new(0, 6)
createStroke(DropdownBtn, Color3.fromRGB(60, 60, 60), 1)

local DropdownList = Instance.new("ScrollingFrame", MainFrame)
DropdownList.Size = UDim2.new(0.92, 0, 0, 130)
DropdownList.Position = UDim2.new(0.04, 0, 0, 120)
DropdownList.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
DropdownList.BorderSizePixel = 0
DropdownList.ScrollBarThickness = 2
DropdownList.Visible = false
DropdownList.ZIndex = 30
Instance.new("UICorner", DropdownList).CornerRadius = UDim.new(0, 6)
createStroke(DropdownList, Color3.fromRGB(45, 45, 45), 1)
local DropLayout = Instance.new("UIListLayout", DropdownList)
DropLayout.Padding = UDim.new(0, 2)

DropdownBtn.MouseButton1Click:Connect(function() 
    playSound(SOUNDS.UI_CLICK)
    DropdownList.Visible = not DropdownList.Visible 
end)

-- CONTENT AREAS
PetScroll = Instance.new("ScrollingFrame", MainFrame)
PetScroll.Size = UDim2.new(0.92, 0, 0, 248)
PetScroll.Position = UDim2.new(0.04, 0, 0, 148)
PetScroll.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
PetScroll.BorderSizePixel = 0
PetScroll.ScrollBarThickness = 2
PetScroll.ZIndex = 11
PetScroll.Visible = false
Instance.new("UICorner", PetScroll).CornerRadius = UDim.new(0, 8)

local GridLayout = Instance.new("UIGridLayout", PetScroll)
GridLayout.CellSize = UDim2.new(0, 86, 0, 118)
GridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
GridLayout.SortOrder = Enum.SortOrder.LayoutOrder
local GridPadding = Instance.new("UIPadding", PetScroll)
GridPadding.PaddingLeft = UDim.new(0, 6); GridPadding.PaddingTop = UDim.new(0, 6)

-- STATUS UI (full width)
StatusMainFrame = Instance.new("Frame", MainFrame)
StatusMainFrame.Size = UDim2.new(0.92, 0, 0, 248)
StatusMainFrame.Position = UDim2.new(0.04, 0, 0, 148)
StatusMainFrame.BackgroundTransparency = 1
StatusMainFrame.Visible = true
StatusMainFrame.ZIndex = 11

StatusLeftScroll = Instance.new("ScrollingFrame", StatusMainFrame)
StatusLeftScroll.Size = UDim2.new(1, 0, 1, 0)
StatusLeftScroll.Position = UDim2.new(0, 0, 0, 0)
StatusLeftScroll.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
StatusLeftScroll.BorderSizePixel = 0
StatusLeftScroll.ScrollBarThickness = 2
StatusLeftScroll.ZIndex = 12
Instance.new("UICorner", StatusLeftScroll).CornerRadius = UDim.new(0, 8)
local StatusLeftLayout = Instance.new("UIListLayout", StatusLeftScroll)
StatusLeftLayout.Padding = UDim.new(0, 6)
StatusLeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
local StatusLeftPadding = Instance.new("UIPadding", StatusLeftScroll)
StatusLeftPadding.PaddingTop = UDim.new(0, 8)
StatusLeftPadding.PaddingBottom = UDim.new(0, 8)
StatusLeftPadding.PaddingLeft = UDim.new(0, 8)
StatusLeftPadding.PaddingRight = UDim.new(0, 8)

EmptyLabel = Instance.new("TextLabel", MainFrame)
EmptyLabel.Size = PetScroll.Size
EmptyLabel.Position = PetScroll.Position
EmptyLabel.BackgroundTransparency = 1
EmptyLabel.Text = "Not Found"
EmptyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
EmptyLabel.Font = Enum.Font.GothamBlack
EmptyLabel.TextSize = 20
EmptyLabel.Visible = false
EmptyLabel.ZIndex = 12
EmptyLabel.TextXAlignment = Enum.TextXAlignment.Center
EmptyLabel.TextYAlignment = Enum.TextYAlignment.Center
createStroke(EmptyLabel, Color3.fromRGB(0, 0, 0), 2).ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

-- BOTTOM BUTTONS
local ButtonsFrame = Instance.new("Frame", MainFrame)
ButtonsFrame.Size = UDim2.new(0.92, 0, 0, 32)
ButtonsFrame.Position = UDim2.new(0.04, 0, 0, 404)
ButtonsFrame.BackgroundTransparency = 1
ButtonsFrame.ZIndex = 11

local BtnLayout = Instance.new("UIListLayout", ButtonsFrame)
BtnLayout.FillDirection = Enum.FillDirection.Horizontal
BtnLayout.SortOrder = Enum.SortOrder.LayoutOrder
BtnLayout.Padding = UDim.new(0, 8)

local function createGradientButton(text, color1, color2, layoutOrder)
    local bgFrame = Instance.new("Frame", ButtonsFrame)
    bgFrame.Size = UDim2.new(0.5, -4, 1, 0)
    bgFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    bgFrame.LayoutOrder = layoutOrder
    bgFrame.ZIndex = 12
    Instance.new("UICorner", bgFrame).CornerRadius = UDim.new(0, 6)
    createStroke(bgFrame, Color3.fromRGB(0, 0, 0), 1.5)

    local gradient = Instance.new("UIGradient", bgFrame)
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, color1),
        ColorSequenceKeypoint.new(1, color2)
    }
    gradient.Rotation = 90

    local btn = Instance.new("TextButton", bgFrame)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Text = text
    btn.ZIndex = 13
    return bgFrame, btn, gradient
end

local InviteBg, BtnInvite, InviteGrad = createGradientButton("Invite Trade", Color3.fromRGB(160, 60, 230), Color3.fromRGB(100, 30, 160), 1)
local ResetBg, BtnReset, ResetGrad = createGradientButton("Reset", Color3.fromRGB(240, 70, 70), Color3.fromRGB(160, 30, 30), 2)

local InviteTextStroke = Instance.new("UIStroke", BtnInvite)
InviteTextStroke.Thickness = 2
InviteTextStroke.Color = Color3.fromRGB(0, 0, 0)
InviteTextStroke.Enabled = false

local currentTradeState = "Available"

local function checkTradeState()
    if not selectedPlayer then return "Available" end
    if selectedPlayer == LocalPlayer then return "Blocked" end

    -- Quando a aba Status estiver aberta → sempre bloqueado
    if currentViewMode == "status" then
        return "Blocked"
    end

    local currentMap = selectedPlayer:FindFirstChild("currentMap")
    local mapName = currentMap and (currentMap:IsA("StringValue") and currentMap.Value or tostring(currentMap)) or ""
    if mapName == "Magma Ring" or mapName == "Desert Ring" or mapName == "Boxing Ring" then
        return "In Brawl"
    end
    return "Available"
end

local function updateInviteUI()
    currentTradeState = checkTradeState()
    if currentTradeState == "Blocked" then
        BtnInvite.Text = "BLOCKED"
        BtnInvite.TextColor3 = Color3.fromRGB(255, 50, 50)
        InviteTextStroke.Enabled = true
        InviteGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 50)), ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20))}
    elseif currentTradeState == "In Brawl" then
        BtnInvite.Text = "IN BRAWL"
        BtnInvite.TextColor3 = Color3.fromRGB(255, 50, 50)
        InviteTextStroke.Enabled = true
        InviteGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 50)), ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20))}
    else
        BtnInvite.Text = "Invite Trade"
        BtnInvite.TextColor3 = Color3.fromRGB(255, 255, 255)
        InviteTextStroke.Enabled = false
        InviteGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 60, 230)), ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 30, 160))}
    end
end

BtnInvite.MouseButton1Click:Connect(function()
    if currentTradeState ~= "Available" then
        playSound(SOUNDS.BRAWL_ERROR)
    else
        playSound(SOUNDS.UI_CLICK)
        if selectedPlayer and selectedPlayer ~= LocalPlayer then
            local event = ReplicatedStorage:FindFirstChild("rEvents")
            if event and event:FindFirstChild("tradingEvent") then
                event.tradingEvent:FireServer("sendTradeRequest", selectedPlayer)
            end
        end
    end
end)

-- ITEM STATUS COMPONENTES DA UI LATERAL
local StatusTitleBg = Instance.new("Frame", ItemStatusFrame)
StatusTitleBg.Size = UDim2.new(1, -20, 0, 24)
StatusTitleBg.Position = UDim2.new(0, 10, 0, 10)
StatusTitleBg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
StatusTitleBg.ZIndex = 6
Instance.new("UICorner", StatusTitleBg).CornerRadius = UDim.new(0, 6)
createStroke(StatusTitleBg, Color3.fromRGB(0, 0, 0), 1.5)

local StatusTitle = Instance.new("TextLabel", StatusTitleBg)
StatusTitle.Size = UDim2.new(1, 0, 1, 0)
StatusTitle.BackgroundTransparency = 1
StatusTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusTitle.Font = Enum.Font.GothamBlack
StatusTitle.TextSize = 12
StatusTitle.ZIndex = 7
StatusTitle.TextXAlignment = Enum.TextXAlignment.Center
createStroke(StatusTitle, Color3.fromRGB(0, 0, 0), 1.5).ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

local StatusImageBg = Instance.new("Frame", ItemStatusFrame)
StatusImageBg.Size = UDim2.new(0, 64, 0, 64)
StatusImageBg.Position = UDim2.new(0, 12, 0, 42)
StatusImageBg.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
StatusImageBg.ZIndex = 6
Instance.new("UICorner", StatusImageBg).CornerRadius = UDim.new(0, 5)
local StatusImageStroke = createStroke(StatusImageBg, Color3.fromRGB(30, 30, 30), 2)

local StatusPetImage = Instance.new("ImageLabel", StatusImageBg)
StatusPetImage.Size = UDim2.new(1, 0, 1, 0)
StatusPetImage.BackgroundTransparency = 1
StatusPetImage.ScaleType = Enum.ScaleType.Fit
StatusPetImage.ZIndex = 7

local StatusEvLabel = Instance.new("TextLabel", StatusImageBg)
StatusEvLabel.Size = UDim2.new(1, 0, 0, 14)
StatusEvLabel.Position = UDim2.new(0, 0, 0, 2)
StatusEvLabel.BackgroundTransparency = 1
StatusEvLabel.Font = Enum.Font.GothamBlack
StatusEvLabel.TextSize = 10
StatusEvLabel.ZIndex = 8
createStroke(StatusEvLabel, Color3.fromRGB(0, 0, 0), 2).ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

local StatusQuantityBg = Instance.new("Frame", StatusImageBg)
StatusQuantityBg.Size = UDim2.new(0, 18, 0, 14)
StatusQuantityBg.Position = UDim2.new(1, -2, 1, -2)
StatusQuantityBg.AnchorPoint = Vector2.new(1, 1)
StatusQuantityBg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
StatusQuantityBg.ZIndex = 8
Instance.new("UICorner", StatusQuantityBg).CornerRadius = UDim.new(0, 3)
createStroke(StatusQuantityBg, Color3.fromRGB(0, 0, 0), 1)

local StatusQuantityTxt = Instance.new("TextLabel", StatusQuantityBg)
StatusQuantityTxt.Size = UDim2.new(1, 0, 1, 0)
StatusQuantityTxt.BackgroundTransparency = 1
StatusQuantityTxt.Text = "x1"
StatusQuantityTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusQuantityTxt.Font = Enum.Font.GothamBlack
StatusQuantityTxt.TextSize = 9
StatusQuantityTxt.ZIndex = 9
createStroke(StatusQuantityTxt, Color3.fromRGB(0, 0, 0), 1).ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

local StatusExtraFrame = Instance.new("Frame", ItemStatusFrame)
StatusExtraFrame.Size = UDim2.new(0, 150, 0, 64)
StatusExtraFrame.Position = UDim2.new(0, 84, 0, 42)
StatusExtraFrame.BackgroundTransparency = 1
StatusExtraFrame.ZIndex = 6
local StatusExtraLayout = Instance.new("UIListLayout", StatusExtraFrame)
StatusExtraLayout.Padding = UDim.new(0, 2)
StatusExtraLayout.SortOrder = Enum.SortOrder.LayoutOrder
StatusExtraLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local function createExtraLabel()
    local lbl = Instance.new("TextLabel", StatusExtraFrame)
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.RichText = true
    lbl.ZIndex = 7
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    createStroke(lbl, Color3.fromRGB(0, 0, 0), 1.5).ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    return lbl
end

local lblRebirths = createExtraLabel()
local lblUntradeable = createExtraLabel()
local lblRobux = createExtraLabel()

local StatusLevelTxt = Instance.new("TextLabel", ItemStatusFrame)
StatusLevelTxt.Size = UDim2.new(1, -20, 0, 16)
StatusLevelTxt.Position = UDim2.new(0, 10, 0, 112)
StatusLevelTxt.BackgroundTransparency = 1
StatusLevelTxt.Font = Enum.Font.GothamBold
StatusLevelTxt.TextSize = 13 
StatusLevelTxt.RichText = true 
StatusLevelTxt.ZIndex = 7
StatusLevelTxt.TextXAlignment = Enum.TextXAlignment.Left
createStroke(StatusLevelTxt, Color3.fromRGB(0, 0, 0), 1.5).ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

local StatusNameTxt = Instance.new("TextLabel", ItemStatusFrame)
StatusNameTxt.Size = UDim2.new(1, -20, 0, 16)
StatusNameTxt.Position = UDim2.new(0, 10, 0, 130)
StatusNameTxt.BackgroundTransparency = 1
StatusNameTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusNameTxt.Font = Enum.Font.GothamBlack
StatusNameTxt.TextSize = 12
StatusNameTxt.ZIndex = 7
StatusNameTxt.TextXAlignment = Enum.TextXAlignment.Left
createStroke(StatusNameTxt, Color3.fromRGB(0, 0, 0), 1.5).ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

local StatusScrollInner = Instance.new("ScrollingFrame", ItemStatusFrame)
StatusScrollInner.Size = UDim2.new(1, -20, 1, -155)
StatusScrollInner.Position = UDim2.new(0, 10, 0, 152)
StatusScrollInner.BackgroundColor3 = Color3.fromRGB(15,15,15)
StatusScrollInner.BackgroundTransparency = 1
StatusScrollInner.BorderSizePixel = 0
StatusScrollInner.ScrollBarThickness = 2
StatusScrollInner.ZIndex = 6
local StatusLayoutInner = Instance.new("UIListLayout", StatusScrollInner)
StatusLayoutInner.Padding = UDim.new(0, 6)

local function getStatValue(plr, statName)
    if not plr then return "0" end
    local ls = plr:FindFirstChild("leaderstats")
    if ls then
        local st = ls:FindFirstChild(statName)
        if st then return st.Value end
        for _, child in ipairs(ls:GetChildren()) do
            if child.Name:lower() == statName:lower() then return child.Value end
        end
    end
    local direct = plr:FindFirstChild(statName)
    if direct then return direct.Value end
    for _, child in ipairs(plr:GetChildren()) do
        if child.Name:lower() == statName:lower() then return child.Value end
    end
    return "0"
end

-- Stats SEM emojis
local function getStatsList()
    return {
        { name = "STRENGTH", value = getStatValue(selectedPlayer, "Strength"), color = Color3.fromRGB(255, 230, 0) },
        { name = "DURABILITY", value = getStatValue(selectedPlayer, "Durability"), color = Color3.fromRGB(0, 150, 255) },
        { name = "AGILITY", value = getStatValue(selectedPlayer, "Agility"), color = Color3.fromRGB(0, 255, 80) },
        { name = "REBIRTH", value = getStatValue(selectedPlayer, "Rebirths"), color = Color3.fromRGB(255, 140, 0) },
        { name = "KILLS", value = getStatValue(selectedPlayer, "Kills"), color = Color3.fromRGB(255, 50, 50) },
        { name = "BRAWL", value = getStatValue(selectedPlayer, "Brawls"), color = Color3.fromRGB(170, 0, 255) },
    }
end

-- Rebuild Status UI when switching player or opening for the first time
rebuildStatusUI = function()
    for _, child in ipairs(StatusLeftScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    table.clear(cachedStatLabels)

    if not selectedPlayer then return end

    local statsList = getStatsList()
    for order, item in ipairs(statsList) do
        local card = Instance.new("Frame", StatusLeftScroll)
        card.Size = UDim2.new(1, 0, 0, 32)
        card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        card.ZIndex = 13
        card.LayoutOrder = order
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
        createStroke(card, Color3.fromRGB(0, 0, 0), 1.5)

        -- Dark gradient style
        local grad = Instance.new("UIGradient", card)
        grad.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 70, 70)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 25))
        }
        grad.Rotation = 90

        local nameLabel = Instance.new("TextLabel", card)
        nameLabel.Size = UDim2.new(0.5, -4, 1, 0)
        nameLabel.Position = UDim2.new(0, 8, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = item.name
        nameLabel.TextColor3 = item.color or Color3.fromRGB(255, 255, 255)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 10
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.ZIndex = 14
        createStroke(nameLabel, Color3.fromRGB(0, 0, 0), 1.5).ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

        local valLabel = Instance.new("TextLabel", card)
        valLabel.Size = UDim2.new(0.5, -4, 1, 0)
        valLabel.Position = UDim2.new(0.5, 0, 0, 0)
        valLabel.BackgroundTransparency = 1
        valLabel.Text = formatNumber(item.value) -- real value with K M B ... Vg suffixes
        valLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        valLabel.Font = Enum.Font.GothamBlack
        valLabel.TextSize = 12
        valLabel.TextXAlignment = Enum.TextXAlignment.Right
        valLabel.ZIndex = 14
        createStroke(valLabel, Color3.fromRGB(0, 0, 0), 1.5).ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

        cachedStatLabels[item.name] = valLabel
        card.Name = "Stat_" .. item.name -- para search
    end

    StatusLeftScroll.CanvasSize = UDim2.new(0, 0, 0, #statsList * 38)
    applySearch()
end

-- Lightweight real-time update
updatePlayerStatusDisplay = function()
    if not selectedPlayer or currentViewMode ~= "status" then return end
    local statsList = getStatsList()
    for _, item in ipairs(statsList) do
        if cachedStatLabels[item.name] then
            cachedStatLabels[item.name].Text = formatNumber(item.value)
        end
    end
end

-- Real-time update loop
task.spawn(function()
    while task.wait(0.5) do
        if MainFrame.Visible and currentViewMode == "status" then
            updatePlayerStatusDisplay()
            updateInviteUI()
        end
    end
end)

updateDropdown = function()
    for _, child in pairs(DropdownList:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    for _, plr in pairs(Players:GetPlayers()) do
        local btn = Instance.new("TextButton", DropdownList)
        btn.Size = UDim2.new(1, -4, 0, 26)
        btn.Position = UDim2.new(0, 2, 0, 0)
        btn.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255) 
        
        local displayName = plr.DisplayName
        if plr == LocalPlayer then
            btn.Text = "  " .. displayName .. " (You)"
        else
            btn.Text = "  " .. displayName .. " (@" .. plr.Name .. ")"
        end
        
        btn.Font = Enum.Font.GothamBold 
        btn.TextSize = 11
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.ZIndex = 31
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        btn.MouseButton1Click:Connect(function()
            playSound(SOUNDS.UI_CLICK)

            selectedPlayer = plr
            if plr == LocalPlayer then
                DropdownBtn.Text = "  " .. displayName .. " (You)"
            else
                DropdownBtn.Text = "  " .. displayName .. " (@" .. plr.Name .. ")"
            end
            DropdownList.Visible = false
            
            ItemStatusFrame.Visible = false
            currentViewedItem = nil
            
            updateProfileDisplay(plr)
            
            if currentViewMode == "status" then
                rebuildStatusUI()
            else
                loadPlayerItems()
                setupAutoUpdate()
            end
        end)
    end
    DropdownList.CanvasSize = UDim2.new(0, 0, 0, #Players:GetPlayers() * 28)
end

updateDropdown()
Players.PlayerAdded:Connect(updateDropdown)

RunService.RenderStepped:Connect(function()
    local t = tick() % 2 / 2
    local hue = Color3.fromHSV(t, 1, 1)
    for obj, kind in pairs(rainbowObjects) do
        if obj and obj.Parent then
            if kind == "stroke" then
                obj.Color = hue
            elseif kind == "bg" then
                obj.BackgroundColor3 = hue
            end
        else
            rainbowObjects[obj] = nil
        end
    end
end)

loadPlayerItems = function()
    if isUpdating or currentViewMode == "status" then return end
    isUpdating = true
    DropdownList.Visible = false
    table.clear(rainbowObjects)
    for _, child in pairs(PetScroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end

    local targetFolder = selectedPlayer and selectedPlayer:FindFirstChild(currentViewMode)
    if not targetFolder then
        EmptyLabel.Visible = true; isUpdating = false; return
    end

    local itemList = {}
    local groupedItems = {}

    local function processInstance(inst, customRarity)
        local pData = getItemData(inst)
        pData.inst = inst
        
        if customRarity then
            pData.rarity = customRarity.name
            pData.order = customRarity.order
            pData.color = customRarity.color
            pData.hexColor = colorToHex(customRarity.color)
            pData.isRainbow = customRarity.isRainbow
        elseif currentViewMode == "consumablesFolder" then
            pData.rarity = ""
            pData.order = 1
            pData.color = Color3.fromRGB(150, 150, 150)
            pData.hexColor = "#969696"
            pData.isRainbow = false
        end

        if isStackedView then
            local groupKey = inst.Name .. "_" .. tostring(pData.isEvolved)
            if groupedItems[groupKey] then
                groupedItems[groupKey].count = groupedItems[groupKey].count + 1
            else
                pData.count = 1
                groupedItems[groupKey] = pData
                table.insert(itemList, pData)
            end
        else
            pData.count = 1
            table.insert(itemList, pData)
        end
    end

    if currentViewMode == "consumablesFolder" then
        for _, obj in pairs(targetFolder:GetChildren()) do
            if obj:IsA("Folder") then
                for _, inst in pairs(obj:GetChildren()) do processInstance(inst, nil) end
            else
                processInstance(obj, nil)
            end
        end
    else
        for _, folder in pairs(targetFolder:GetChildren()) do
            local folderKey = folder.Name:lower()
            local rInfo = RARITY_MAP[folderKey]
            if not rInfo and currentViewMode == "machineSkinsFolder" then rInfo = RARITY_MAP["common"] end
            if rInfo then
                for _, inst in pairs(folder:GetChildren()) do processInstance(inst, rInfo) end
            end
        end
    end

    if #itemList == 0 then EmptyLabel.Visible = true; isUpdating = false; return else EmptyLabel.Visible = false end

    table.sort(itemList, function(a, b)
        if a.order ~= b.order then return a.order < b.order end
        if a.strength ~= b.strength then return a.strength > b.strength end
        return a.inst.Name < b.inst.Name
    end)

    for order, data in ipairs(itemList) do
        local Card = Instance.new("TextButton", PetScroll)
        Card.Name = data.inst.Name
        Card.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
        Card.Text = ""
        Card.LayoutOrder = order
        Card.ZIndex = 12
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 6)
        
        local mainStroke = createStroke(Card, data.color, 2)
        if data.isRainbow then rainbowObjects[mainStroke] = "stroke" end

        local ImageFrame = Instance.new("Frame", Card)
        ImageFrame.Size = UDim2.new(1, -8, 0, 58)
        ImageFrame.Position = UDim2.new(0, 4, 0, 4)
        ImageFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
        ImageFrame.ZIndex = 13
        Instance.new("UICorner", ImageFrame).CornerRadius = UDim.new(0, 5)
        
        local imgId = extractItemImage(data.inst)
        local Img = Instance.new("ImageLabel", ImageFrame)
        Img.Size = UDim2.new(1, 0, 1, 0)
        Img.BackgroundTransparency = 1
        Img.ScaleType = Enum.ScaleType.Fit
        Img.Image = imgId
        Img.ZIndex = 14

        local EvLabel = Instance.new("TextLabel", ImageFrame)
        EvLabel.Size = UDim2.new(1, 0, 0, 14)
        EvLabel.Position = UDim2.new(0, 0, 0, 2)
        EvLabel.BackgroundTransparency = 1
        EvLabel.Font = Enum.Font.GothamBlack
        EvLabel.TextSize = 9
        EvLabel.ZIndex = 15
        createStroke(EvLabel, Color3.fromRGB(0, 0, 0), 2).ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

        if data.isEvolved and currentViewMode ~= "consumablesFolder" and currentViewMode ~= "machineSkinsFolder" then
            EvLabel.Text = "EVOLVED"
            EvLabel.TextColor3 = Color3.fromRGB(170, 0, 255)
        elseif currentViewMode == "petsFolder" or currentViewMode == "powerUpsFolder" then
            EvLabel.Text = "NORMAL"
            EvLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
        else
            EvLabel.Visible = false
        end
        
        if isStackedView and data.count > 1 then
            local StackQuantityBg = Instance.new("Frame", ImageFrame)
            StackQuantityBg.Size = UDim2.new(0, 18, 0, 14)
            StackQuantityBg.Position = UDim2.new(1, -2, 1, -2)
            StackQuantityBg.AnchorPoint = Vector2.new(1, 1)
            StackQuantityBg.BackgroundColor3 = data.color
            StackQuantityBg.ZIndex = 16
            Instance.new("UICorner", StackQuantityBg).CornerRadius = UDim.new(0, 3)
            local sStroke = createStroke(StackQuantityBg, Color3.fromRGB(0, 0, 0), 1)
            if data.isRainbow then
                rainbowObjects[sStroke] = "stroke"
                rainbowObjects[StackQuantityBg] = "bg"
            end

            local StackQuantityTxt = Instance.new("TextLabel", StackQuantityBg)
            StackQuantityTxt.Size = UDim2.new(1, 0, 1, 0)
            StackQuantityTxt.BackgroundTransparency = 1
            StackQuantityTxt.Text = "x" .. tostring(data.count)
            StackQuantityTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
            StackQuantityTxt.Font = Enum.Font.GothamBlack
            StackQuantityTxt.TextSize = 9
            StackQuantityTxt.ZIndex = 17
            createStroke(StackQuantityTxt, Color3.fromRGB(0, 0, 0), 1).ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
        end

        local LevelLabel = Instance.new("TextLabel", Card)
        LevelLabel.Size = UDim2.new(1, -4, 0, 12)
        LevelLabel.Position = UDim2.new(0, 2, 0, 66)
        LevelLabel.BackgroundTransparency = 1
        LevelLabel.RichText = true
        LevelLabel.Text = "<font color='"..data.hexColor.."'>Level</font> <font color='#FFFFFF'>" .. data.level .. "</font>"
        if currentViewMode == "consumablesFolder" or currentViewMode == "machineSkinsFolder" then LevelLabel.Visible = false end
        LevelLabel.Font = Enum.Font.GothamBold
        LevelLabel.TextSize = 11 
        LevelLabel.ZIndex = 13
        createStroke(LevelLabel, Color3.fromRGB(0, 0, 0), 1.5).ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

        local ItemName = Instance.new("TextLabel", Card)
        ItemName.Size = UDim2.new(1, -4, 0, 14)
        ItemName.Position = UDim2.new(0, 2, 0, 81)
        if currentViewMode == "consumablesFolder" or currentViewMode == "machineSkinsFolder" then ItemName.Position = UDim2.new(0, 2, 0, 70) end
        ItemName.BackgroundTransparency = 1
        ItemName.Text = data.inst.Name
        ItemName.TextColor3 = Color3.fromRGB(240, 240, 240)
        ItemName.Font = Enum.Font.GothamBold
        ItemName.TextSize = 9
        ItemName.TextScaled = true
        ItemName.ZIndex = 13

        local RarityLabel = Instance.new("TextLabel", Card)
        RarityLabel.Size = UDim2.new(1, -4, 0, 14)
        RarityLabel.Position = UDim2.new(0, 2, 0, 98)
        if currentViewMode == "machineSkinsFolder" then RarityLabel.Position = UDim2.new(0, 2, 0, 88) end
        RarityLabel.BackgroundTransparency = 1
        RarityLabel.Text = string.upper(data.rarity)
        RarityLabel.TextColor3 = data.color
        RarityLabel.Font = Enum.Font.GothamBlack
        RarityLabel.TextSize = 9
        RarityLabel.ZIndex = 13
        if data.isRainbow then
            RunService.RenderStepped:Connect(function()
                local t = tick() % 2 / 2
                if RarityLabel.Parent then RarityLabel.TextColor3 = Color3.fromHSV(t, 1, 1) end
            end)
        end
        if currentViewMode == "consumablesFolder" then RarityLabel.Visible = false end
        createStroke(RarityLabel, Color3.fromRGB(0, 0, 0), 1.5).ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

        Card.MouseButton1Click:Connect(function()
            playSound(SOUNDS.CARD_CLICK)
            
            if currentViewMode == "consumablesFolder" or currentViewMode == "machineSkinsFolder" then
                return
            end

            if ItemStatusFrame.Visible and currentViewedItem == data.inst then
                ItemStatusFrame.Visible = false
                currentViewedItem = nil
                return
            end
            
            currentViewedItem = data.inst
            for _, c in pairs(StatusScrollInner:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
            
            StatusTitleBg.BackgroundColor3 = data.color
            StatusTitle.Text = string.upper(data.rarity)
            StatusImageStroke.Color = data.color
            StatusPetImage.Image = imgId
            
            local itemCount = 0
            for _, folder in pairs(targetFolder:GetChildren()) do
                if RARITY_MAP[folder.Name:lower()] then
                    for _, p in pairs(folder:GetChildren()) do
                        if p.Name == data.inst.Name then itemCount = itemCount + 1 end
                    end
                end
            end
            
            StatusQuantityBg.BackgroundColor3 = data.color
            StatusQuantityTxt.Text = "x" .. tostring(itemCount)
            -- rainbow quantity badge (admin)
            for obj, kind in pairs(rainbowObjects) do
                if obj == StatusQuantityBg or (kind == "stroke" and obj.Parent == StatusQuantityBg) then
                    rainbowObjects[obj] = nil
                end
            end
            if data.isRainbow then
                rainbowObjects[StatusQuantityBg] = "bg"
                local qStroke = StatusQuantityBg:FindFirstChildOfClass("UIStroke")
                if qStroke then rainbowObjects[qStroke] = "stroke" end
            end

            if data.isEvolved then
                StatusEvLabel.Text = "EVOLVED"
                StatusEvLabel.TextColor3 = Color3.fromRGB(170, 0, 255)
            else
                StatusEvLabel.Text = "NORMAL"
                StatusEvLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
            end

            StatusLevelTxt.Text = "<font color='"..data.hexColor.."'>Level</font> <font color='#FFFFFF'>" .. data.level .. "</font>"
            StatusNameTxt.Text = data.inst.Name

            local reqRebirthsObj = data.inst:FindFirstChild("requiredRebirths") or data.inst:FindFirstChild("RequiredRebirths")
            local untradeableObj = data.inst:FindFirstChild("untradeable") or data.inst:FindFirstChild("Untradeable")
            local robuxPetObj = data.inst:FindFirstChild("robuxPet") or data.inst:FindFirstChild("RobuxPet")

            local rRebirthsVal = reqRebirthsObj and reqRebirthsObj.Value or 0
            local isUntradeable = untradeableObj and ((untradeableObj:IsA("BoolValue") and untradeableObj.Value == true) or (tonumber(untradeableObj.Value) or 0) > 0)
            local isRobux = robuxPetObj and ((robuxPetObj:IsA("BoolValue") and robuxPetObj.Value == true) or (tonumber(robuxPetObj.Value) or 0) > 0)

            lblRebirths.Text = string.format("<font color='#CCCCCC'>Required Rebirths </font> <font color='#FFFFFF'>%s</font>", formatNumber(rRebirthsVal))
            lblUntradeable.Text = string.format("<font color='#CCCCCC'>Untradeable </font> %s", isUntradeable and "<font color='#00FF00'>On</font>" or "<font color='#FF3232'>Off</font>")
            lblRobux.Text = string.format("<font color='#CCCCCC'>Robux Pet </font> %s", isRobux and "<font color='#00FF00'>Yes</font>" or "<font color='#FF3232'>No</font>")

            local perks = data.inst:FindFirstChild("perksFolder")
            local perksData = {}
            if perks then
                for _, perk in pairs(perks:GetChildren()) do
                    if perk:IsA("ValueBase") then perksData[perk.Name:lower()] = perk end
                end
            end

            local function createPerkBanner(pKey, perkObj)
                local pCfg = PERK_CONFIG[pKey] or { icon = "✨", name = perkObj.Name, color = Color3.fromRGB(220, 220, 220) }
                local perkHex = colorToHex(pCfg.color)
                
                local bannerFrame = Instance.new("Frame", StatusScrollInner)
                bannerFrame.Size = UDim2.new(1, -6, 0, 26)
                bannerFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                bannerFrame.ZIndex = 7
                
                local gradient = Instance.new("UIGradient", bannerFrame)
                gradient.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 70, 70)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 25))
                }
                gradient.Rotation = 90
                
                Instance.new("UICorner", bannerFrame).CornerRadius = UDim.new(0, 6)
                createStroke(bannerFrame, Color3.fromRGB(0, 0, 0), 1.5)

                local nameLbl = Instance.new("TextLabel", bannerFrame)
                nameLbl.Size = UDim2.new(0.5, -8, 1, 0)
                nameLbl.Position = UDim2.new(0, 8, 0, 0)
                nameLbl.BackgroundTransparency = 1
                nameLbl.RichText = true
                nameLbl.Text = "<font color='"..perkHex.."'>"..pCfg.icon .. " " .. pCfg.name .. "</font>"
                nameLbl.Font = Enum.Font.GothamBold
                nameLbl.TextSize = 12
                nameLbl.ZIndex = 8
                nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                createStroke(nameLbl, Color3.fromRGB(0, 0, 0), 1).ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

                local valLbl = Instance.new("TextLabel", bannerFrame)
                valLbl.Size = UDim2.new(0.5, -8, 1, 0)
                valLbl.Position = UDim2.new(0.5, 0, 0, 0)
                valLbl.BackgroundTransparency = 1
                valLbl.Text = formatNumber(perkObj.Value)
                valLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                valLbl.Font = Enum.Font.GothamBlack
                valLbl.TextSize = 13
                valLbl.ZIndex = 8
                valLbl.TextXAlignment = Enum.TextXAlignment.Right
                createStroke(valLbl, Color3.fromRGB(0, 0, 0), 1.5).ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
            end

            for _, key in ipairs(PERK_ORDER) do
                if perksData[key] then
                    createPerkBanner(key, perksData[key])
                    perksData[key] = nil 
                end
            end
            for key, perkObj in pairs(perksData) do createPerkBanner(key, perkObj) end
            
            local childCount = 0
            for _, c in pairs(StatusScrollInner:GetChildren()) do
                if c:IsA("Frame") then childCount = childCount + 1 end
            end
            StatusScrollInner.CanvasSize = UDim2.new(0, 0, 0, childCount * 32)
            
            ItemStatusFrame.Visible = true
        end)
    end
    PetScroll.CanvasSize = UDim2.new(0, 0, 0, (math.ceil(#itemList / 4) * 124) + 10)
    isUpdating = false
    applySearch()
end

setupAutoUpdate = function()
    if autoUpdateConnectionAdded then autoUpdateConnectionAdded:Disconnect() end
    if autoUpdateConnectionRemoved then autoUpdateConnectionRemoved:Disconnect() end
    
    if selectedPlayer and currentViewMode ~= "status" then
        updateInviteUI()
        local activeFolder = selectedPlayer:FindFirstChild(currentViewMode)
        if activeFolder then
            local function triggerUpdate()
                task.wait(0.2) 
                if ScreenGui.Parent then loadPlayerItems() end
            end
            autoUpdateConnectionAdded = activeFolder.DescendantAdded:Connect(triggerUpdate)
            autoUpdateConnectionRemoved = activeFolder.DescendantRemoving:Connect(triggerUpdate)
        end
    end
end

resetToLocalPlayer = function()
    selectedPlayer = LocalPlayer
    currentViewMode = "status"
    updateSectionTitle("Player Status")
    DropdownBtn.Text = "  " .. LocalPlayer.DisplayName .. " (You)"
    updateProfileDisplay(LocalPlayer)
    
    ItemStatusFrame.Visible = false
    PetScroll.Visible = false
    EmptyLabel.Visible = false
    StatusMainFrame.Visible = true
    currentViewedItem = nil
    
    rebuildStatusUI()
    updateInviteUI()
end

BtnReset.MouseButton1Click:Connect(function()
    playSound(SOUNDS.UI_CLICK)
    resetToLocalPlayer()
end)

Players.PlayerRemoving:Connect(function(plr)
    updateDropdown()
    if plr == selectedPlayer then resetToLocalPlayer() end
end)

-- INITIAL SETUP → STATUS TAB
selectedPlayer = LocalPlayer
DropdownBtn.Text = "  " .. LocalPlayer.DisplayName .. " (You)"
updateProfileDisplay(LocalPlayer)
updateSectionTitle("Player Status")
rebuildStatusUI()
updateInviteUI()
