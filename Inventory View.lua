local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local CoreGui = (gethui and gethui()) or game:GetService("CoreGui")

if CoreGui:FindFirstChild("PetViewerGui") then
    CoreGui.PetViewerGui:Destroy()
end

local LocalPlayer = Players.LocalPlayer
local selectedPlayer = LocalPlayer
local currentViewedItem = nil 
local currentViewMode = "petsFolder"
local isStackedView = true 
local autoUpdateConnectionAdded = nil
local autoUpdateConnectionRemoved = nil
local isUpdating = false
local rainbowStrokes = {}

local realDisplayName, realUserName, realUserId = "", "", ""

-- SISTEMA DE SONS DOS HUDS --
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

local function formatNumber(n)
    n = tonumber(n) or 0
    if n >= 1e12 then return string.format("%.1fT", n / 1e12):gsub("%.0T", "T")
    elseif n >= 1e9 then return string.format("%.1fB", n / 1e9):gsub("%.0B", "B")
    elseif n >= 1e6 then return string.format("%.1fM", n / 1e6):gsub("%.0M", "M")
    elseif n >= 1e3 then return string.format("%.1fK", n / 1e3):gsub("%.0K", "K")
    else return tostring(n) end
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

-- BOTÃO FLUTUANTE
local ToggleBtn = Instance.new("TextButton", ScreenGui)
ToggleBtn.Size = UDim2.new(0, 40, 0, 40)
ToggleBtn.Position = UDim2.new(0.5, -389, 0.5, -122) 
ToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
ToggleBtn.Text = "SL"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 22
ToggleBtn.ZIndex = 50 
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 8)
createStroke(ToggleBtn, Color3.fromRGB(60, 60, 60), 2)

-- MAIN FRAME
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 420, 0, 450)
MainFrame.Position = UDim2.new(0.5, -305, 0.5, -262)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
MainFrame.Active = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
createStroke(MainFrame, Color3.fromRGB(40, 40, 40), 2)

-- STATUS GUI
local StatusFrame = Instance.new("Frame", MainFrame)
StatusFrame.Size = UDim2.new(0, 245, 0, 300)
StatusFrame.Position = UDim2.new(1, 10, 0, 150) 
StatusFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
StatusFrame.Visible = false
StatusFrame.Active = true
Instance.new("UICorner", StatusFrame).CornerRadius = UDim.new(0, 8)
createStroke(StatusFrame, Color3.fromRGB(45, 45, 45), 2)

-- SETTINGS MENU
local SettingsFrame = Instance.new("Frame", MainFrame)
SettingsFrame.Size = UDim2.new(0, 245, 0, 140) 
SettingsFrame.Position = UDim2.new(1, 10, 0, 0) 
SettingsFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
SettingsFrame.Visible = false -- Inicia invisível
Instance.new("UICorner", SettingsFrame).CornerRadius = UDim.new(0, 10)
createStroke(SettingsFrame, Color3.fromRGB(40, 40, 40), 2)

local SettingsTitle = Instance.new("TextLabel", SettingsFrame)
SettingsTitle.Size = UDim2.new(1, -40, 0, 20)
SettingsTitle.Position = UDim2.new(0, 10, 0, 5)
SettingsTitle.BackgroundTransparency = 1
SettingsTitle.Text = "Settings View"
SettingsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
SettingsTitle.Font = Enum.Font.GothamBlack
SettingsTitle.TextSize = 16
SettingsTitle.TextXAlignment = Enum.TextXAlignment.Left

-- BOTÃO DE ABRIR/FECHAR SETTING
local SettingsToggleBtn = Instance.new("ImageButton", MainFrame)
SettingsToggleBtn.Size = UDim2.new(0, 22, 0, 22) 
SettingsToggleBtn.Position = UDim2.new(1, -30, 0, 8) 
SettingsToggleBtn.BackgroundTransparency = 1
SettingsToggleBtn.Image = "rbxassetid://100589335929927"
SettingsToggleBtn.ScaleType = Enum.ScaleType.Fit
SettingsToggleBtn.ZIndex = 60

SettingsToggleBtn.MouseButton1Click:Connect(function()
    playSound(SOUNDS.UI_CLICK)
    SettingsFrame.Visible = not SettingsFrame.Visible
    
    if SettingsFrame.Visible then
        -- Move para dentro da Gui do Settings
        SettingsToggleBtn.Parent = SettingsFrame
        SettingsToggleBtn.Position = UDim2.new(1, -30, 0, 5)
    else
        -- Volta para a borda da Gui Inventory
        SettingsToggleBtn.Parent = MainFrame
        SettingsToggleBtn.Position = UDim2.new(1, -30, 0, 8)
    end
end)

-- GRID DE BOTÕES (PET, AURA, SKIN, PROTEIN)
local CategFrame = Instance.new("Frame", SettingsFrame)
CategFrame.Size = UDim2.new(1, -10, 0, 55)
CategFrame.Position = UDim2.new(0, 5, 0, 35)
CategFrame.BackgroundTransparency = 1

local CategGrid = Instance.new("UIGridLayout", CategFrame)
CategGrid.CellSize = UDim2.new(0, 110, 0, 22)
CategGrid.CellPadding = UDim2.new(0, 10, 0, 6)
CategGrid.SortOrder = Enum.SortOrder.LayoutOrder
CategGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center

local loadPlayerItems, setupAutoUpdate

local function createTopButton(text, folderName, color1, color2, order)
    local btn = Instance.new("TextButton", CategFrame)
    btn.Text = text
    btn.Font = Enum.Font.GothamBlack
    btn.TextSize = 10
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.LayoutOrder = order
    createStroke(btn, Color3.fromRGB(0, 0, 0), 1.5).ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(0, 0, 0)
    stroke.Thickness = 1.5

    local grad = Instance.new("UIGradient", btn)
    grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, color1), ColorSequenceKeypoint.new(1, color2)}
    grad.Rotation = 90

    btn.MouseButton1Click:Connect(function()
        playSound(SOUNDS.UI_CLICK)
        if currentViewMode ~= folderName then
            currentViewMode = folderName
            if StatusFrame then StatusFrame.Visible = false end
            currentViewedItem = nil
            loadPlayerItems()
            setupAutoUpdate()
        end
    end)
    return btn
end

createTopButton("Pets", "petsFolder", Color3.fromRGB(100, 200, 255), Color3.fromRGB(0, 100, 255), 1)
createTopButton("Aura", "powerUpsFolder", Color3.fromRGB(100, 255, 100), Color3.fromRGB(0, 180, 0), 2)
createTopButton("Skins", "machineSkinsFolder", Color3.fromRGB(255, 100, 100), Color3.fromRGB(180, 0, 0), 3)
createTopButton("Protein", "consumablesFolder", Color3.fromRGB(255, 200, 100), Color3.fromRGB(200, 120, 0), 4)

-- BOTÃO VIEW MODE 
local ViewModeBtn = Instance.new("TextButton", SettingsFrame)
ViewModeBtn.Size = UDim2.new(1, -20, 0, 36)
ViewModeBtn.Position = UDim2.new(0, 10, 0, 95)
ViewModeBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255) 
ViewModeBtn.Text = "Mode: View 1"
ViewModeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ViewModeBtn.Font = Enum.Font.GothamBold
ViewModeBtn.TextSize = 12
Instance.new("UICorner", ViewModeBtn).CornerRadius = UDim.new(0, 6) 
createStroke(ViewModeBtn, Color3.fromRGB(0, 0, 0), 1.5)

local ViewModeTextStroke = Instance.new("UIStroke", ViewModeBtn)
ViewModeTextStroke.Color = Color3.fromRGB(0, 0, 0)
ViewModeTextStroke.Thickness = 1.5
ViewModeTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

local ViewModeGrad = Instance.new("UIGradient", ViewModeBtn)
ViewModeGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 60, 60)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 30))
}
ViewModeGrad.Rotation = 90

ViewModeBtn.MouseButton1Click:Connect(function()
    playSound(SOUNDS.UI_CLICK)
    isStackedView = not isStackedView
    if isStackedView then
        ViewModeBtn.Text = "Mode: View 1"
    else
        ViewModeBtn.Text = "Mode: View 2"
    end
    loadPlayerItems()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    playSound(SOUNDS.UI_CLICK)
    MainFrame.Visible = not MainFrame.Visible
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
addSubtleGradient(StatusFrame)
addSubtleGradient(SettingsFrame)

-- TÍTULO COM RICH TEXT
local TitleLabel = Instance.new("TextLabel", MainFrame)
TitleLabel.Size = UDim2.new(1, -20, 0, 36)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.RichText = true
TitleLabel.Text = "VIEW INVENTORY By <font color='#FF0000'>@Slowzzx4</font>"
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 13
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
createStroke(TitleLabel, Color3.fromRGB(0, 0, 0), 2).ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

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

local AvatarBg = Instance.new("Frame", ProfileFrame)
AvatarBg.Size = UDim2.new(0, 46, 0, 46)
AvatarBg.Position = UDim2.new(0, 0, 0.5, -23)
AvatarBg.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
Instance.new("UICorner", AvatarBg).CornerRadius = UDim.new(0, 10)
local AvatarStroke = Instance.new("UIStroke", AvatarBg)
AvatarStroke.Thickness = 2
AvatarStroke.Color = Color3.fromRGB(255, 255, 255)
local AvatarImage = Instance.new("ImageLabel", AvatarBg)
AvatarImage.Size = UDim2.new(1, 0, 1, 0)
AvatarImage.BackgroundTransparency = 1
Instance.new("UICorner", AvatarImage).CornerRadius = UDim.new(0, 10)

local UserInfoFrame = Instance.new("Frame", ProfileFrame)
UserInfoFrame.Size = UDim2.new(1, -56, 1, 0)
UserInfoFrame.Position = UDim2.new(0, 54, 0, 0)
UserInfoFrame.BackgroundTransparency = 1

local UserNameLabel = Instance.new("TextLabel", UserInfoFrame)
UserNameLabel.Size = UDim2.new(1, 0, 0, 22)
UserNameLabel.Position = UDim2.new(0, 0, 0, 4)
UserNameLabel.BackgroundTransparency = 1
UserNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
UserNameLabel.Font = Enum.Font.GothamBold
UserNameLabel.TextSize = 13
UserNameLabel.TextXAlignment = Enum.TextXAlignment.Left

local UserIdLabel = Instance.new("TextLabel", UserInfoFrame)
UserIdLabel.Size = UDim2.new(1, 0, 0, 18)
UserIdLabel.Position = UDim2.new(0, 0, 0, 24)
UserIdLabel.BackgroundTransparency = 1
UserIdLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
UserIdLabel.Font = Enum.Font.GothamBold
UserIdLabel.TextSize = 11
UserIdLabel.TextXAlignment = Enum.TextXAlignment.Left

local updateDropdown
local resetToLocalPlayer

local function updateProfileDisplay(plr)
    if not plr then return end
    realDisplayName = plr.DisplayName
    if plr == LocalPlayer then
        UserNameLabel.Text = realDisplayName .. " (Callback error)"
        UserIdLabel.Text = "Callback error"
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

-- DROPDOWN DE SELEÇÃO
local DropdownBtn = Instance.new("TextButton", MainFrame)
DropdownBtn.Size = UDim2.new(0.92, 0, 0, 26)
DropdownBtn.Position = UDim2.new(0.04, 0, 0, 92)
DropdownBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35) 
DropdownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DropdownBtn.Font = Enum.Font.GothamBold
DropdownBtn.TextSize = 12
DropdownBtn.TextXAlignment = Enum.TextXAlignment.Left
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

-- ÁREA DE SCROLL DE PETS/AURAS
local PetScroll = Instance.new("ScrollingFrame", MainFrame)
PetScroll.Size = UDim2.new(0.92, 0, 0, 268)
PetScroll.Position = UDim2.new(0.04, 0, 0, 126)
PetScroll.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
PetScroll.BorderSizePixel = 0
PetScroll.ScrollBarThickness = 2
Instance.new("UICorner", PetScroll).CornerRadius = UDim.new(0, 8)

local EmptyLabel = Instance.new("TextLabel", MainFrame)
EmptyLabel.Size = PetScroll.Size
EmptyLabel.Position = PetScroll.Position
EmptyLabel.BackgroundTransparency = 1
EmptyLabel.Text = "Not Found"
EmptyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
EmptyLabel.Font = Enum.Font.GothamBlack
EmptyLabel.TextSize = 20
EmptyLabel.Visible = false
EmptyLabel.TextXAlignment = Enum.TextXAlignment.Center
EmptyLabel.TextYAlignment = Enum.TextYAlignment.Center
createStroke(EmptyLabel, Color3.fromRGB(0, 0, 0), 2).ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

-- CONTAINER DOS BOTÕES NA PARTE INFERIOR
local ButtonsFrame = Instance.new("Frame", MainFrame)
ButtonsFrame.Size = UDim2.new(0.92, 0, 0, 32)
ButtonsFrame.Position = UDim2.new(0.04, 0, 0, 404)
ButtonsFrame.BackgroundTransparency = 1

local BtnLayout = Instance.new("UIListLayout", ButtonsFrame)
BtnLayout.FillDirection = Enum.FillDirection.Horizontal
BtnLayout.SortOrder = Enum.SortOrder.LayoutOrder
BtnLayout.Padding = UDim.new(0, 8)

local function createGradientButton(text, color1, color2, layoutOrder)
    local bgFrame = Instance.new("Frame", ButtonsFrame)
    bgFrame.Size = UDim2.new(0.5, -4, 1, 0)
    bgFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    bgFrame.LayoutOrder = layoutOrder
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

task.spawn(function()
    while true do
        task.wait(0.5)
        if MainFrame.Visible then updateInviteUI() end
    end
end)

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

-- STATUS GUI COMPONENTES
local StatusTitleBg = Instance.new("Frame", StatusFrame)
StatusTitleBg.Size = UDim2.new(1, -20, 0, 24)
StatusTitleBg.Position = UDim2.new(0, 10, 0, 10)
StatusTitleBg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", StatusTitleBg).CornerRadius = UDim.new(0, 6)
createStroke(StatusTitleBg, Color3.fromRGB(0, 0, 0), 1.5)

local StatusTitle = Instance.new("TextLabel", StatusTitleBg)
StatusTitle.Size = UDim2.new(1, 0, 1, 0)
StatusTitle.BackgroundTransparency = 1
StatusTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusTitle.Font = Enum.Font.GothamBlack
StatusTitle.TextSize = 12
StatusTitle.TextXAlignment = Enum.TextXAlignment.Center
createStroke(StatusTitle, Color3.fromRGB(0, 0, 0), 1.5).ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

local StatusImageBg = Instance.new("Frame", StatusFrame)
StatusImageBg.Size = UDim2.new(0, 64, 0, 64)
StatusImageBg.Position = UDim2.new(0, 12, 0, 42)
StatusImageBg.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
Instance.new("UICorner", StatusImageBg).CornerRadius = UDim.new(0, 5)
local StatusImageStroke = createStroke(StatusImageBg, Color3.fromRGB(30, 30, 30), 2)
local StatusPetImage = Instance.new("ImageLabel", StatusImageBg)
StatusPetImage.Size = UDim2.new(1, 0, 1, 0)
StatusPetImage.BackgroundTransparency = 1
StatusPetImage.ScaleType = Enum.ScaleType.Fit

local StatusEvLabel = Instance.new("TextLabel", StatusImageBg)
StatusEvLabel.Size = UDim2.new(1, 0, 0, 14)
StatusEvLabel.Position = UDim2.new(0, 0, 0, 2)
StatusEvLabel.BackgroundTransparency = 1
StatusEvLabel.Font = Enum.Font.GothamBlack
StatusEvLabel.TextSize = 10
StatusEvLabel.ZIndex = 5
createStroke(StatusEvLabel, Color3.fromRGB(0, 0, 0), 2).ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

local StatusQuantityBg = Instance.new("Frame", StatusImageBg)
StatusQuantityBg.Size = UDim2.new(0, 18, 0, 14)
StatusQuantityBg.Position = UDim2.new(1, -2, 1, -2)
StatusQuantityBg.AnchorPoint = Vector2.new(1, 1)
StatusQuantityBg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
StatusQuantityBg.ZIndex = 6
Instance.new("UICorner", StatusQuantityBg).CornerRadius = UDim.new(0, 3)
createStroke(StatusQuantityBg, Color3.fromRGB(0, 0, 0), 1)

local StatusQuantityTxt = Instance.new("TextLabel", StatusQuantityBg)
StatusQuantityTxt.Size = UDim2.new(1, 0, 1, 0)
StatusQuantityTxt.BackgroundTransparency = 1
StatusQuantityTxt.Text = "x1"
StatusQuantityTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusQuantityTxt.Font = Enum.Font.GothamBlack
StatusQuantityTxt.TextSize = 9
StatusQuantityTxt.ZIndex = 7
createStroke(StatusQuantityTxt, Color3.fromRGB(0, 0, 0), 1).ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

local StatusExtraFrame = Instance.new("Frame", StatusFrame)
StatusExtraFrame.Size = UDim2.new(0, 150, 0, 64)
StatusExtraFrame.Position = UDim2.new(0, 84, 0, 42)
StatusExtraFrame.BackgroundTransparency = 1
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
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    createStroke(lbl, Color3.fromRGB(0, 0, 0), 1.5).ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    return lbl
end

local lblRebirths = createExtraLabel()
local lblUntradeable = createExtraLabel()
local lblRobux = createExtraLabel()

local StatusLevelTxt = Instance.new("TextLabel", StatusFrame)
StatusLevelTxt.Size = UDim2.new(1, -20, 0, 16)
StatusLevelTxt.Position = UDim2.new(0, 10, 0, 112)
StatusLevelTxt.BackgroundTransparency = 1
StatusLevelTxt.Font = Enum.Font.GothamBold
StatusLevelTxt.TextSize = 13 
StatusLevelTxt.RichText = true 
StatusLevelTxt.TextXAlignment = Enum.TextXAlignment.Left
createStroke(StatusLevelTxt, Color3.fromRGB(0, 0, 0), 1.5).ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

local StatusNameTxt = Instance.new("TextLabel", StatusFrame)
StatusNameTxt.Size = UDim2.new(1, -20, 0, 16)
StatusNameTxt.Position = UDim2.new(0, 10, 0, 130)
StatusNameTxt.BackgroundTransparency = 1
StatusNameTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusNameTxt.Font = Enum.Font.GothamBlack
StatusNameTxt.TextSize = 12
StatusNameTxt.TextXAlignment = Enum.TextXAlignment.Left
createStroke(StatusNameTxt, Color3.fromRGB(0, 0, 0), 1.5).ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

local StatusScroll = Instance.new("ScrollingFrame", StatusFrame)
StatusScroll.Size = UDim2.new(1, -20, 1, -155)
StatusScroll.Position = UDim2.new(0, 10, 0, 152)
StatusScroll.BackgroundColor3 = Color3.fromRGB(15,15,15)
StatusScroll.BackgroundTransparency = 1
StatusScroll.BorderSizePixel = 0
StatusScroll.ScrollBarThickness = 2
local StatusLayout = Instance.new("UIListLayout", StatusScroll)
StatusLayout.Padding = UDim.new(0, 6)

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
            btn.Text = "  " .. displayName .. " (Callback error)"
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
                DropdownBtn.Text = "  " .. displayName .. " (Callback error)"
            else
                DropdownBtn.Text = "  " .. displayName .. " (@" .. plr.Name .. ")"
            end
            DropdownList.Visible = false
            StatusFrame.Visible = false
            currentViewedItem = nil
            
            updateProfileDisplay(plr)
            loadPlayerItems()
            setupAutoUpdate()
        end)
    end
    DropdownList.CanvasSize = UDim2.new(0, 0, 0, #Players:GetPlayers() * 28)
end

updateDropdown()
Players.PlayerAdded:Connect(updateDropdown)

local GridLayout = Instance.new("UIGridLayout", PetScroll)
GridLayout.CellSize = UDim2.new(0, 86, 0, 118)
GridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
GridLayout.SortOrder = Enum.SortOrder.LayoutOrder
local GridPadding = Instance.new("UIPadding", PetScroll)
GridPadding.PaddingLeft = UDim.new(0, 6); GridPadding.PaddingTop = UDim.new(0, 6)

RunService.RenderStepped:Connect(function()
    local t = tick() % 2 / 2
    local hue = Color3.fromHSV(t, 1, 1)
    for stroke, _ in pairs(rainbowStrokes) do
        if stroke.Parent then stroke.Color = hue else rainbowStrokes[stroke] = nil end
    end
end)

loadPlayerItems = function()
    if isUpdating then return end
    isUpdating = true
    DropdownList.Visible = false
    table.clear(rainbowStrokes)
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
        Card.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
        Card.Text = ""
        Card.LayoutOrder = order
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 6)
        
        local mainStroke = createStroke(Card, data.color, 2)
        if data.isRainbow then rainbowStrokes[mainStroke] = true end

        local ImageFrame = Instance.new("Frame", Card)
        ImageFrame.Size = UDim2.new(1, -8, 0, 58)
        ImageFrame.Position = UDim2.new(0, 4, 0, 4)
        ImageFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
        Instance.new("UICorner", ImageFrame).CornerRadius = UDim.new(0, 5)
        
        local imgId = extractItemImage(data.inst)
        local Img = Instance.new("ImageLabel", ImageFrame)
        Img.Size = UDim2.new(1, 0, 1, 0)
        Img.BackgroundTransparency = 1
        Img.ScaleType = Enum.ScaleType.Fit
        Img.Image = imgId

        local EvLabel = Instance.new("TextLabel", ImageFrame)
        EvLabel.Size = UDim2.new(1, 0, 0, 14)
        EvLabel.Position = UDim2.new(0, 0, 0, 2)
        EvLabel.BackgroundTransparency = 1
        EvLabel.Font = Enum.Font.GothamBlack
        EvLabel.TextSize = 9
        EvLabel.ZIndex = 5
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
            StackQuantityBg.ZIndex = 6
            Instance.new("UICorner", StackQuantityBg).CornerRadius = UDim.new(0, 3)
            local sStroke = createStroke(StackQuantityBg, Color3.fromRGB(0, 0, 0), 1)
            if data.isRainbow then rainbowStrokes[sStroke] = true end

            local StackQuantityTxt = Instance.new("TextLabel", StackQuantityBg)
            StackQuantityTxt.Size = UDim2.new(1, 0, 1, 0)
            StackQuantityTxt.BackgroundTransparency = 1
            StackQuantityTxt.Text = "x" .. tostring(data.count)
            StackQuantityTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
            StackQuantityTxt.Font = Enum.Font.GothamBlack
            StackQuantityTxt.TextSize = 9
            StackQuantityTxt.ZIndex = 7
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

        local RarityLabel = Instance.new("TextLabel", Card)
        RarityLabel.Size = UDim2.new(1, -4, 0, 14)
        RarityLabel.Position = UDim2.new(0, 2, 0, 98)
        if currentViewMode == "machineSkinsFolder" then RarityLabel.Position = UDim2.new(0, 2, 0, 88) end
        RarityLabel.BackgroundTransparency = 1
        RarityLabel.Text = string.upper(data.rarity)
        RarityLabel.TextColor3 = data.color
        RarityLabel.Font = Enum.Font.GothamBlack
        RarityLabel.TextSize = 9
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

            if StatusFrame.Visible and currentViewedItem == data.inst then
                StatusFrame.Visible = false
                currentViewedItem = nil
                return
            end
            
            currentViewedItem = data.inst
            for _, c in pairs(StatusScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
            
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
            lblUntradeable.Text = string.format("<font color='#CCCCCC'>UnTradeAble </font> %s", isUntradeable and "<font color='#00FF00'>On</font>" or "<font color='#FF3232'>Off</font>")
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
                
                local bannerFrame = Instance.new("Frame", StatusScroll)
                bannerFrame.Size = UDim2.new(1, -6, 0, 26)
                bannerFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                
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
            for _, c in pairs(StatusScroll:GetChildren()) do
                if c:IsA("Frame") then childCount = childCount + 1 end
            end
            StatusScroll.CanvasSize = UDim2.new(0, 0, 0, childCount * 32)
            
            StatusFrame.Visible = true
        end)
    end
    PetScroll.CanvasSize = UDim2.new(0, 0, 0, (math.ceil(#itemList / 4) * 124) + 10)
    isUpdating = false
end

setupAutoUpdate = function()
    if autoUpdateConnectionAdded then autoUpdateConnectionAdded:Disconnect() end
    if autoUpdateConnectionRemoved then autoUpdateConnectionRemoved:Disconnect() end
    
    if selectedPlayer then
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
    currentViewMode = "petsFolder"
    DropdownBtn.Text = "  " .. LocalPlayer.DisplayName .. " (Callback error)"
    updateProfileDisplay(LocalPlayer)
    StatusFrame.Visible = false
    currentViewedItem = nil
    loadPlayerItems()
    setupAutoUpdate()
end

BtnReset.MouseButton1Click:Connect(function()
    playSound(SOUNDS.UI_CLICK)
    resetToLocalPlayer()
end)

Players.PlayerRemoving:Connect(function(plr)
    updateDropdown()
    if plr == selectedPlayer then resetToLocalPlayer() end
end)

selectedPlayer = LocalPlayer
DropdownBtn.Text = "  " .. LocalPlayer.DisplayName .. " (Callback error)"
updateProfileDisplay(LocalPlayer)
loadPlayerItems()
setupAutoUpdate()
