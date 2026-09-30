--[[
    Rubi Hub UI Library v2
    Chilli Hub style — icons, sections, toggles, sliders, dropdowns, keybinds, etc.
    local Rubi = loadstring(game:HttpGet("URL"))()
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = (gethui and gethui()) or game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local Rubi = {}
Rubi.__index = Rubi
Rubi.Version = "2.0"

-- Theme
local Theme = {
	Header = Color3.fromRGB(111, 0, 2),
	HeaderDark = Color3.fromRGB(58, 0, 0),
	Accent = Color3.fromRGB(175, 0, 0),
	AccentDark = Color3.fromRGB(126, 0, 0),
	AccentBright = Color3.fromRGB(220, 20, 20),
	Background = Color3.fromRGB(18, 22, 20),
	Panel = Color3.fromRGB(26, 30, 28),
	PanelAlt = Color3.fromRGB(22, 26, 24),
	Row = Color3.fromRGB(0, 0, 0),
	Stroke = Color3.fromRGB(0, 0, 0),
	Text = Color3.fromRGB(255, 255, 255),
	TextDim = Color3.fromRGB(185, 185, 185),
	TextMuted = Color3.fromRGB(120, 120, 120),
	ToggleOn = Color3.fromRGB(50, 200, 80),
	ToggleOff = Color3.fromRGB(70, 70, 70),
	SliderFill = Color3.fromRGB(50, 200, 80),
	SliderBg = Color3.fromRGB(40, 45, 42),
	Tab = Color3.fromRGB(175, 0, 0),
	TabActive = Color3.fromRGB(220, 30, 30),
	SearchBg = Color3.fromRGB(28, 32, 30),
	White = Color3.fromRGB(255, 255, 255),
	Success = Color3.fromRGB(50, 200, 80),
	Warning = Color3.fromRGB(255, 180, 40),
	Error = Color3.fromRGB(220, 50, 50),
}

-- Built-in Lucide-style icon map (rbxassetid fallbacks + unicode)
local Icons = {
	home = "rbxassetid://7733960981",
	farm = "rbxassetid://7734053495",
	shop = "rbxassetid://7734053495",
	pets = "rbxassetid://7733913011",
	player = "rbxassetid://7733960981",
	server = "rbxassetid://7734053495",
	misc = "rbxassetid://7734053495",
	settings = "rbxassetid://7734053495",
	config = "rbxassetid://7734053495",
	discord = "rbxassetid://7734053495",
	search = "rbxassetid://7734053495",
	close = "rbxassetid://7733920644",
	check = "rbxassetid://7733715400",
	chevron = "rbxassetid://7733717447",
	star = "rbxassetid://7733960981",
	zap = "rbxassetid://7734053495",
	shield = "rbxassetid://7734053495",
	eye = "rbxassetid://7734053495",
	key = "rbxassetid://7734053495",
	box = "rbxassetid://7734053495",
	-- unicode fallbacks used when Image fails
	_unicode = {
		home = "⌂", farm = "⚙", shop = "🛒", pets = "🐾", player = "👤",
		server = "🖥", misc = "•••", settings = "⚙", config = "📁",
		discord = "💬", search = "🔍", close = "✕", check = "✓",
		star = "★", zap = "⚡", shield = "🛡", eye = "👁", key = "🔑", box = "📦",
	},
}

-- Optional external icon pack (Wind/Lucide style)
local ExternalIcons = nil
pcall(function()
	ExternalIcons = loadstring(game:HttpGetAsync(
		"https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua"
	))()
	if ExternalIcons and ExternalIcons.SetIconsType then
		ExternalIcons.SetIconsType("lucide")
	end
end)

local function GetIcon(name)
	if not name or name == "" then return nil, nil end
	name = string.lower(tostring(name))
	if ExternalIcons then
		local ok, data = pcall(function() return ExternalIcons.GetIcon(name) end)
		if ok and data then
			if typeof(data) == "table" then
				return data.Image or data[1], nil
			elseif type(data) == "string" and data ~= "" then
				return data, nil
			end
		end
	end
	if Icons[name] then
		return Icons[name], Icons._unicode[name]
	end
	-- try as raw asset id
	if string.find(name, "rbxassetid://") or tonumber(name) then
		return (string.find(name, "rbxassetid") and name) or ("rbxassetid://" .. name), nil
	end
	return nil, Icons._unicode[name] or "•"
end

local function tween(obj, props, t, style)
	local ti = TweenInfo.new(t or 0.16, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tw = TweenService:Create(obj, ti, props)
	tw:Play()
	return tw
end

local function corner(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 6)
	c.Parent = p
	return c
end

local function stroke(p, col, th)
	local s = Instance.new("UIStroke")
	s.Color = col or Theme.Stroke
	s.Thickness = th or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = p
	return s
end

local function pad(p, t, b, l, r)
	local u = Instance.new("UIPadding")
	u.PaddingTop = UDim.new(0, t or 0)
	u.PaddingBottom = UDim.new(0, b or 0)
	u.PaddingLeft = UDim.new(0, l or 0)
	u.PaddingRight = UDim.new(0, r or 0)
	u.Parent = p
	return u
end

local function list(p, dir, spacing)
	local l = Instance.new("UIListLayout")
	l.FillDirection = dir or Enum.FillDirection.Vertical
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Padding = UDim.new(0, spacing or 4)
	l.Parent = p
	return l
end

local function makeDraggable(handle, target)
	target = target or handle
	local dragging, start, startPos, input
	handle.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			start = inp.Position
			startPos = target.Position
			inp.Changed:Connect(function()
				if inp.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	handle.InputChanged:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
			input = inp
		end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if inp == input and dragging then
			local d = inp.Position - start
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end

local function applyIcon(parent, iconName, size, pos)
	local imgId, unicode = GetIcon(iconName)
	if imgId then
		local img = Instance.new("ImageLabel")
		img.Name = "Icon"
		img.Size = size or UDim2.new(0, 16, 0, 16)
		img.Position = pos or UDim2.new(0, 8, 0.5, 0)
		img.AnchorPoint = Vector2.new(0, 0.5)
		img.BackgroundTransparency = 1
		img.Image = imgId
		img.ImageColor3 = Theme.White
		img.ScaleType = Enum.ScaleType.Fit
		img.Parent = parent
		return img
	elseif unicode then
		local lbl = Instance.new("TextLabel")
		lbl.Name = "Icon"
		lbl.Size = size or UDim2.new(0, 16, 0, 16)
		lbl.Position = pos or UDim2.new(0, 8, 0.5, 0)
		lbl.AnchorPoint = Vector2.new(0, 0.5)
		lbl.BackgroundTransparency = 1
		lbl.Text = unicode
		lbl.TextColor3 = Theme.White
		lbl.Font = Enum.Font.Gotham
		lbl.TextSize = 12
		lbl.Parent = parent
		return lbl
	end
	return nil
end

-- Cleanup old
pcall(function()
	for _, n in ipairs({"RubiHubGui", "RubiQuickBar", "RubiFPS", "RubiNotify"}) do
		local o = CoreGui:FindFirstChild(n)
		if o then o:Destroy() end
	end
end)

----------------------------------------------------------------
-- CREATE WINDOW
----------------------------------------------------------------
function Rubi:CreateWindow(opts)
	opts = opts or {}
	local title = opts.Title or "Rubi Hub"
	local size = opts.Size or UDim2.new(0, 540, 0, 440)
	local iconName = opts.Icon

	local Screen = Instance.new("ScreenGui")
	Screen.Name = "RubiHubGui"
	Screen.ResetOnSpawn = false
	Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	Screen.DisplayOrder = 200
	Screen.Parent = CoreGui

	local Main = Instance.new("Frame")
	Main.Name = "Main"
	Main.Size = size
	Main.Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2)
	Main.BackgroundColor3 = Theme.Background
	Main.BackgroundTransparency = 0.12
	Main.BorderSizePixel = 0
	Main.Active = true
	Main.ClipsDescendants = true
	Main.Parent = Screen
	corner(Main, 8)
	stroke(Main, Theme.Stroke, 1.5)

	-- Header
	local Header = Instance.new("Frame")
	Header.Name = "Header"
	Header.Size = UDim2.new(1, 0, 0, 38)
	Header.BackgroundColor3 = Theme.Header
	Header.BorderSizePixel = 0
	Header.Parent = Main
	stroke(Header, Theme.HeaderDark, 1)

	if iconName then
		applyIcon(Header, iconName, UDim2.new(0, 22, 0, 22), UDim2.new(0, 10, 0.5, 0))
	end

	local HeaderLabel = Instance.new("TextLabel")
	HeaderLabel.Name = "Title"
	HeaderLabel.Size = UDim2.new(1, -60, 1, 0)
	HeaderLabel.Position = UDim2.new(0, iconName and 36 or 14, 0, 0)
	HeaderLabel.BackgroundTransparency = 1
	HeaderLabel.Text = title
	HeaderLabel.TextColor3 = Theme.Text
	HeaderLabel.Font = Enum.Font.GothamBold
	HeaderLabel.TextSize = 16
	HeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
	HeaderLabel.Parent = Header

	local CloseBtn = Instance.new("TextButton")
	CloseBtn.Name = "Close"
	CloseBtn.Size = UDim2.new(0, 28, 0, 24)
	CloseBtn.Position = UDim2.new(1, -34, 0.5, -12)
	CloseBtn.BackgroundColor3 = Theme.AccentDark
	CloseBtn.Text = "X"
	CloseBtn.TextColor3 = Theme.Text
	CloseBtn.Font = Enum.Font.GothamBold
	CloseBtn.TextSize = 14
	CloseBtn.AutoButtonColor = false
	CloseBtn.Parent = Header
	corner(CloseBtn, 4)
	stroke(CloseBtn, Theme.HeaderDark, 1)
	CloseBtn.MouseEnter:Connect(function() tween(CloseBtn, {BackgroundColor3 = Theme.Error}, 0.1) end)
	CloseBtn.MouseLeave:Connect(function() tween(CloseBtn, {BackgroundColor3 = Theme.AccentDark}, 0.1) end)

	makeDraggable(Header, Main)
	CloseBtn.MouseButton1Click:Connect(function() Screen.Enabled = false end)

	-- Left tabs
	local LeftBar = Instance.new("Frame")
	LeftBar.Name = "LeftBar"
	LeftBar.Size = UDim2.new(0, 108, 1, -38)
	LeftBar.Position = UDim2.new(0, 0, 0, 38)
	LeftBar.BackgroundColor3 = Theme.PanelAlt
	LeftBar.BorderSizePixel = 0
	LeftBar.Parent = Main

	local LeftScroll = Instance.new("ScrollingFrame")
	LeftScroll.Size = UDim2.new(1, 0, 1, 0)
	LeftScroll.BackgroundTransparency = 1
	LeftScroll.BorderSizePixel = 0
	LeftScroll.ScrollBarThickness = 2
	LeftScroll.ScrollBarImageColor3 = Theme.Accent
	LeftScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	LeftScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	LeftScroll.Parent = LeftBar
	list(LeftScroll, Enum.FillDirection.Vertical, 6)
	pad(LeftScroll, 8, 8, 6, 6)

	-- Right buttons
	local RightBar = Instance.new("Frame")
	RightBar.Name = "RightBar"
	RightBar.Size = UDim2.new(0, 108, 1, -38)
	RightBar.Position = UDim2.new(1, -108, 0, 38)
	RightBar.BackgroundColor3 = Theme.PanelAlt
	RightBar.BorderSizePixel = 0
	RightBar.Parent = Main

	local RightScroll = Instance.new("ScrollingFrame")
	RightScroll.Size = UDim2.new(1, 0, 1, 0)
	RightScroll.BackgroundTransparency = 1
	RightScroll.BorderSizePixel = 0
	RightScroll.ScrollBarThickness = 2
	RightScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	RightScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	RightScroll.Parent = RightBar
	list(RightScroll, Enum.FillDirection.Vertical, 6)
	pad(RightScroll, 8, 8, 6, 6)

	-- Center
	local Content = Instance.new("Frame")
	Content.Name = "Content"
	Content.Size = UDim2.new(1, -216, 1, -72)
	Content.Position = UDim2.new(0, 108, 0, 38)
	Content.BackgroundColor3 = Theme.Panel
	Content.BorderSizePixel = 0
	Content.ClipsDescendants = true
	Content.Parent = Main

	-- Search
	local SearchBar = Instance.new("Frame")
	SearchBar.Name = "SearchBar"
	SearchBar.Size = UDim2.new(1, -216, 0, 34)
	SearchBar.Position = UDim2.new(0, 108, 1, -34)
	SearchBar.BackgroundColor3 = Theme.SearchBg
	SearchBar.BorderSizePixel = 0
	SearchBar.Parent = Main

	local SearchIcon = applyIcon(SearchBar, "search", UDim2.new(0, 14, 0, 14), UDim2.new(0, 10, 0.5, 0))
	local SearchBox = Instance.new("TextBox")
	SearchBox.Name = "Search"
	SearchBox.Size = UDim2.new(1, -36, 0, 26)
	SearchBox.Position = UDim2.new(0, 28, 0.5, -13)
	SearchBox.BackgroundColor3 = Color3.fromRGB(35, 40, 38)
	SearchBox.PlaceholderText = "Search / Filter features..."
	SearchBox.PlaceholderColor3 = Theme.TextMuted
	SearchBox.Text = ""
	SearchBox.TextColor3 = Theme.Text
	SearchBox.Font = Enum.Font.Gotham
	SearchBox.TextSize = 12
	SearchBox.ClearTextOnFocus = false
	SearchBox.Parent = SearchBar
	corner(SearchBox, 6)
	stroke(SearchBox, Color3.fromRGB(50, 50, 50), 1)
	pad(SearchBox, 0, 0, 8, 8)

	-- FPS
	local FPSGui = Instance.new("ScreenGui")
	FPSGui.Name = "RubiFPS"
	FPSGui.ResetOnSpawn = false
	FPSGui.DisplayOrder = 250
	FPSGui.Parent = CoreGui

	local FPSLabel = Instance.new("TextLabel")
	FPSLabel.Size = UDim2.new(0, 130, 0, 20)
	FPSLabel.Position = UDim2.new(1, -140, 0, 8)
	FPSLabel.BackgroundTransparency = 1
	FPSLabel.Text = "0 FPS  0 ms"
	FPSLabel.TextColor3 = Theme.Text
	FPSLabel.Font = Enum.Font.GothamBold
	FPSLabel.TextSize = 12
	FPSLabel.TextXAlignment = Enum.TextXAlignment.Right
	FPSLabel.Parent = FPSGui

	local fpsFrames, fpsLast, fpsVal = 0, tick(), 60
	RunService.RenderStepped:Connect(function()
		fpsFrames = fpsFrames + 1
		local now = tick()
		if now - fpsLast >= 1 then
			fpsVal = math.floor(fpsFrames / (now - fpsLast) + 0.5)
			fpsFrames = 0
			fpsLast = now
		end
		local ping = 0
		pcall(function() ping = math.floor(LocalPlayer:GetNetworkPing() * 1000) end)
		FPSLabel.Text = string.format("%d FPS  %d ms", fpsVal, ping)
	end)

	----------------------------------------------------------------
	local Window = {
		Screen = Screen,
		Main = Main,
		Tabs = {},
		CurrentTab = nil,
		SearchBox = SearchBox,
		Flags = {},
		Theme = Theme,
	}

	local function makeSideButton(parent, text, order, iconName)
		local btn = Instance.new("TextButton")
		btn.Name = text
		btn.Size = UDim2.new(1, 0, 0, 34)
		btn.BackgroundColor3 = Theme.Tab
		btn.Text = ""
		btn.LayoutOrder = order or 0
		btn.AutoButtonColor = false
		btn.Parent = parent
		corner(btn, 6)
		stroke(btn, Theme.HeaderDark, 1)

		local hasIcon = iconName and true or false
		if hasIcon then
			applyIcon(btn, iconName, UDim2.new(0, 16, 0, 16), UDim2.new(0, 8, 0.5, 0))
		end

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, hasIcon and -28 or -8, 1, 0)
		lbl.Position = UDim2.new(0, hasIcon and 26 or 4, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = text
		lbl.TextColor3 = Theme.Text
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 11
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextTruncate = Enum.TextTruncate.AtEnd
		lbl.Parent = btn

		btn.MouseEnter:Connect(function()
			if Window.CurrentTab ~= text then
				tween(btn, {BackgroundColor3 = Theme.TabActive}, 0.12)
			end
		end)
		btn.MouseLeave:Connect(function()
			if Window.CurrentTab ~= text then
				tween(btn, {BackgroundColor3 = Theme.Tab}, 0.12)
			end
		end)
		return btn
	end

	function Window:CreateTab(name, icon)
		local order = #self.Tabs + 1
		local page = Instance.new("ScrollingFrame")
		page.Name = name
		page.Size = UDim2.new(1, 0, 1, 0)
		page.BackgroundTransparency = 1
		page.BorderSizePixel = 0
		page.ScrollBarThickness = 4
		page.ScrollBarImageColor3 = Theme.Accent
		page.CanvasSize = UDim2.new(0, 0, 0, 0)
		page.AutomaticCanvasSize = Enum.AutomaticSize.Y
		page.Visible = false
		page.Parent = Content
		list(page, Enum.FillDirection.Vertical, 6)
		pad(page, 8, 8, 8, 8)

		local btn = makeSideButton(LeftScroll, name, order, icon)
		local tab = { Name = name, Page = page, Button = btn, Sections = {}, _order = 0 }

		btn.MouseButton1Click:Connect(function()
			for _, t in pairs(self.Tabs) do
				t.Page.Visible = false
				t.Button.BackgroundColor3 = Theme.Tab
			end
			page.Visible = true
			btn.BackgroundColor3 = Theme.TabActive
			self.CurrentTab = name
		end)

		function tab:CreateSection(sectionName)
			local secOrder = self._order + 1
			self._order = secOrder

			local sectionFrame = Instance.new("Frame")
			sectionFrame.Name = sectionName .. "Section"
			sectionFrame.Size = UDim2.new(1, 0, 0, 28)
			sectionFrame.BackgroundTransparency = 1
			sectionFrame.AutomaticSize = Enum.AutomaticSize.Y
			sectionFrame.LayoutOrder = secOrder
			sectionFrame.Parent = page
			list(sectionFrame, Enum.FillDirection.Vertical, 4)

			local headerBtn = Instance.new("TextButton")
			headerBtn.Name = "Header"
			headerBtn.Size = UDim2.new(1, 0, 0, 24)
			headerBtn.BackgroundTransparency = 1
			headerBtn.Text = ""
			headerBtn.AutoButtonColor = false
			headerBtn.LayoutOrder = 1
			headerBtn.Parent = sectionFrame

			local headerLbl = Instance.new("TextLabel")
			headerLbl.Size = UDim2.new(1, -28, 1, 0)
			headerLbl.Position = UDim2.new(0, 4, 0, 0)
			headerLbl.BackgroundTransparency = 1
			headerLbl.Text = sectionName
			headerLbl.TextColor3 = Theme.Text
			headerLbl.Font = Enum.Font.GothamBold
			headerLbl.TextSize = 13
			headerLbl.TextXAlignment = Enum.TextXAlignment.Left
			headerLbl.Parent = headerBtn

			local arrow = Instance.new("TextLabel")
			arrow.Size = UDim2.new(0, 20, 1, 0)
			arrow.Position = UDim2.new(1, -24, 0, 0)
			arrow.BackgroundTransparency = 1
			arrow.Text = "▼"
			arrow.TextColor3 = Theme.Text
			arrow.Font = Enum.Font.GothamBold
			arrow.TextSize = 10
			arrow.Parent = headerBtn

			local body = Instance.new("Frame")
			body.Name = "Body"
			body.Size = UDim2.new(1, 0, 0, 0)
			body.BackgroundTransparency = 1
			body.AutomaticSize = Enum.AutomaticSize.Y
			body.LayoutOrder = 2
			body.Visible = true
			body.Parent = sectionFrame
			list(body, Enum.FillDirection.Vertical, 4)

			local open = true
			headerBtn.MouseButton1Click:Connect(function()
				open = not open
				body.Visible = open
				arrow.Text = open and "▼" or "▶"
			end)

			local section = { Name = sectionName, Body = body, _order = 0 }
			local function nextOrder()
				section._order = section._order + 1
				return section._order
			end
			local function makeRow(height)
				local row = Instance.new("Frame")
				row.Size = UDim2.new(1, 0, 0, height or 32)
				row.BackgroundColor3 = Theme.Row
				row.BackgroundTransparency = 0.5
				row.LayoutOrder = nextOrder()
				row.Parent = body
				corner(row, 6)
				stroke(row, Theme.Stroke, 1)
				return row
			end

			-- Toggle
			function section:AddToggle(opts)
				opts = type(opts) == "table" and opts or { Name = tostring(opts) }
				local name = opts.Name or "Toggle"
				local desc = opts.Description or opts.Desc
				local default = opts.Default or false
				local flag = opts.Flag
				local callback = opts.Callback
				local icon = opts.Icon

				local h = desc and 44 or 32
				local row = makeRow(h)

				if icon then
					applyIcon(row, icon, UDim2.new(0, 14, 0, 14), UDim2.new(0, 8, 0, desc and 10 or 9))
				end
				local xOff = icon and 26 or 10

				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(1, -56 - (icon and 16 or 0), 0, desc and 16 or 32)
				lbl.Position = UDim2.new(0, xOff, 0, desc and 4 or 0)
				lbl.BackgroundTransparency = 1
				lbl.Text = name
				lbl.TextColor3 = Theme.Text
				lbl.Font = Enum.Font.Gotham
				lbl.TextSize = 12
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.Parent = row

				if desc then
					local d = Instance.new("TextLabel")
					d.Size = UDim2.new(1, -56, 0, 14)
					d.Position = UDim2.new(0, xOff, 0, 22)
					d.BackgroundTransparency = 1
					d.Text = desc
					d.TextColor3 = Theme.TextMuted
					d.Font = Enum.Font.Gotham
					d.TextSize = 10
					d.TextXAlignment = Enum.TextXAlignment.Left
					d.Parent = row
				end

				local track = Instance.new("Frame")
				track.Size = UDim2.new(0, 40, 0, 20)
				track.Position = UDim2.new(1, -48, 0.5, -10)
				track.BackgroundColor3 = default and Theme.ToggleOn or Theme.ToggleOff
				track.Parent = row
				corner(track, 10)
				stroke(track, Theme.Stroke, 1)

				local knob = Instance.new("Frame")
				knob.Size = UDim2.new(0, 16, 0, 16)
				knob.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
				knob.BackgroundColor3 = Theme.White
				knob.Parent = track
				corner(knob, 8)

				local state = default
				if flag then Window.Flags[flag] = state end

				local function set(v, fire)
					state = not not v
					tween(track, {BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff}, 0.12)
					tween(knob, {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}, 0.15)
					if flag then Window.Flags[flag] = state end
					if fire ~= false and callback then task.spawn(callback, state) end
				end

				local hit = Instance.new("TextButton")
				hit.Size = UDim2.new(1, 0, 1, 0)
				hit.BackgroundTransparency = 1
				hit.Text = ""
				hit.Parent = track
				hit.MouseButton1Click:Connect(function() set(not state) end)

				local api = {}
				function api:Set(v) set(v) end
				function api:Get() return state end
				return api
			end

			-- Slider
			function section:AddSlider(opts)
				opts = opts or {}
				local name = opts.Name or "Slider"
				local min, max = opts.Min or 0, opts.Max or 100
				local default = opts.Default or min
				local flag, callback = opts.Flag, opts.Callback
				local suffix = opts.Suffix or ""

				local row = makeRow(48)
				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(0.55, 0, 0, 16)
				lbl.Position = UDim2.new(0, 10, 0, 4)
				lbl.BackgroundTransparency = 1
				lbl.Text = name
				lbl.TextColor3 = Theme.Text
				lbl.Font = Enum.Font.Gotham
				lbl.TextSize = 12
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.Parent = row

				local valLbl = Instance.new("TextLabel")
				valLbl.Size = UDim2.new(0, 60, 0, 16)
				valLbl.Position = UDim2.new(1, -68, 0, 4)
				valLbl.BackgroundTransparency = 1
				valLbl.Text = tostring(default) .. suffix
				valLbl.TextColor3 = Theme.Text
				valLbl.Font = Enum.Font.GothamBold
				valLbl.TextSize = 12
				valLbl.TextXAlignment = Enum.TextXAlignment.Right
				valLbl.Parent = row

				local bar = Instance.new("Frame")
				bar.Size = UDim2.new(1, -20, 0, 10)
				bar.Position = UDim2.new(0, 10, 1, -18)
				bar.BackgroundColor3 = Theme.SliderBg
				bar.Parent = row
				corner(bar, 5)

				local fill = Instance.new("Frame")
				fill.Size = UDim2.new(math.clamp((default - min) / math.max(max - min, 1), 0, 1), 0, 1, 0)
				fill.BackgroundColor3 = Theme.SliderFill
				fill.Parent = bar
				corner(fill, 5)

				local value = default
				if flag then Window.Flags[flag] = value end
				local sliding = false

				local function update(x)
					local rel = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
					value = math.floor(min + (max - min) * rel + 0.5)
					fill.Size = UDim2.new(rel, 0, 1, 0)
					valLbl.Text = tostring(value) .. suffix
					if flag then Window.Flags[flag] = value end
					if callback then task.spawn(callback, value) end
				end

				bar.InputBegan:Connect(function(inp)
					if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
						sliding = true
						update(inp.Position.X)
					end
				end)
				UserInputService.InputChanged:Connect(function(inp)
					if sliding and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
						update(inp.Position.X)
					end
				end)
				UserInputService.InputEnded:Connect(function(inp)
					if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
						sliding = false
					end
				end)

				local api = {}
				function api:Set(v)
					value = math.clamp(tonumber(v) or min, min, max)
					local rel = (value - min) / math.max(max - min, 1)
					fill.Size = UDim2.new(rel, 0, 1, 0)
					valLbl.Text = tostring(value) .. suffix
					if flag then Window.Flags[flag] = value end
					if callback then task.spawn(callback, value) end
				end
				function api:Get() return value end
				return api
			end

			-- Dropdown
			function section:AddDropdown(opts)
				opts = opts or {}
				local name = opts.Name or "Dropdown"
				local options = opts.Options or {}
				local default = opts.Default
				local multi = opts.Multi or false
				local flag, callback = opts.Flag, opts.Callback

				local row = makeRow(32)
				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(0.38, 0, 1, 0)
				lbl.Position = UDim2.new(0, 10, 0, 0)
				lbl.BackgroundTransparency = 1
				lbl.Text = name
				lbl.TextColor3 = Theme.Text
				lbl.Font = Enum.Font.Gotham
				lbl.TextSize = 12
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.Parent = row

				local dropBtn = Instance.new("TextButton")
				dropBtn.Size = UDim2.new(0.58, -10, 0, 24)
				dropBtn.Position = UDim2.new(0.42, 0, 0.5, -12)
				dropBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 38)
				dropBtn.Text = "  " .. (default and tostring(default) or (multi and "0 selected" or "Select..."))
				dropBtn.TextColor3 = Theme.TextDim
				dropBtn.Font = Enum.Font.Gotham
				dropBtn.TextSize = 11
				dropBtn.TextXAlignment = Enum.TextXAlignment.Left
				dropBtn.AutoButtonColor = false
				dropBtn.Parent = row
				corner(dropBtn, 5)
				stroke(dropBtn, Theme.Stroke, 1)

				local caret = Instance.new("TextLabel")
				caret.Size = UDim2.new(0, 16, 1, 0)
				caret.Position = UDim2.new(1, -18, 0, 0)
				caret.BackgroundTransparency = 1
				caret.Text = "▼"
				caret.TextColor3 = Theme.Text
				caret.Font = Enum.Font.Gotham
				caret.TextSize = 10
				caret.Parent = dropBtn

				local listFrame = Instance.new("ScrollingFrame")
				listFrame.Size = UDim2.new(0.58, -10, 0, 0)
				listFrame.Position = UDim2.new(0.42, 0, 1, 2)
				listFrame.BackgroundColor3 = Color3.fromRGB(30, 34, 32)
				listFrame.BorderSizePixel = 0
				listFrame.Visible = false
				listFrame.ZIndex = 50
				listFrame.ScrollBarThickness = 3
				listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
				listFrame.Parent = row
				corner(listFrame, 6)
				stroke(listFrame, Theme.Stroke, 1)
				list(listFrame, Enum.FillDirection.Vertical, 2)
				pad(listFrame, 4, 4, 4, 4)

				local selected = {}
				if multi then
					if type(default) == "table" then for _, v in ipairs(default) do selected[v] = true end end
				else
					if default then selected[default] = true end
				end
				if flag then Window.Flags[flag] = multi and selected or default end

				local isOpen = false
				local function refreshLabel()
					if multi then
						local n = 0
						for _ in pairs(selected) do n = n + 1 end
						dropBtn.Text = "  " .. (n > 0 and (n .. " selected") or "0 selected")
					else
						dropBtn.Text = "  " .. (next(selected) and tostring(next(selected)) or "Select...")
					end
				end

				local function rebuild()
					for _, c in ipairs(listFrame:GetChildren()) do
						if c:IsA("TextButton") then c:Destroy() end
					end
					for i, opt in ipairs(options) do
						local ob = Instance.new("TextButton")
						ob.Size = UDim2.new(1, 0, 0, 22)
						ob.BackgroundColor3 = selected[opt] and Color3.fromRGB(50, 80, 50) or Color3.fromRGB(40, 44, 42)
						ob.Text = "  " .. tostring(opt)
						ob.TextColor3 = Theme.Text
						ob.Font = Enum.Font.Gotham
						ob.TextSize = 11
						ob.TextXAlignment = Enum.TextXAlignment.Left
						ob.LayoutOrder = i
						ob.ZIndex = 51
						ob.AutoButtonColor = false
						ob.Parent = listFrame
						corner(ob, 4)
						ob.MouseButton1Click:Connect(function()
							if multi then
								selected[opt] = not selected[opt] or nil
								ob.BackgroundColor3 = selected[opt] and Color3.fromRGB(50, 80, 50) or Color3.fromRGB(40, 44, 42)
								refreshLabel()
								if flag then Window.Flags[flag] = selected end
								if callback then task.spawn(callback, selected) end
							else
								table.clear(selected)
								selected[opt] = true
								dropBtn.Text = "  " .. tostring(opt)
								isOpen = false
								listFrame.Visible = false
								listFrame.Size = UDim2.new(0.58, -10, 0, 0)
								if flag then Window.Flags[flag] = opt end
								if callback then task.spawn(callback, opt) end
							end
						end)
					end
					listFrame.CanvasSize = UDim2.new(0, 0, 0, #options * 24)
				end
				rebuild()
				refreshLabel()

				dropBtn.MouseButton1Click:Connect(function()
					isOpen = not isOpen
					listFrame.Visible = isOpen
					listFrame.Size = isOpen and UDim2.new(0.58, -10, 0, math.min(#options * 24 + 8, 150)) or UDim2.new(0.58, -10, 0, 0)
					caret.Text = isOpen and "▲" or "▼"
				end)

				local api = {}
				function api:Set(v)
					if multi then
						selected = {}
						if type(v) == "table" then for _, x in pairs(v) do selected[x] = true end end
					else
						selected = {[v] = true}
					end
					rebuild()
					refreshLabel()
				end
				function api:Get()
					if multi then return selected end
					return next(selected)
				end
				function api:Refresh(newOpts)
					options = newOpts or options
					rebuild()
				end
				return api
			end

			-- Button
			function section:AddButton(opts)
				opts = type(opts) == "table" and opts or { Name = tostring(opts) }
				local name = opts.Name or "Button"
				local callback = opts.Callback
				local icon = opts.Icon

				local row = makeRow(34)
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, -16, 0, 26)
				btn.Position = UDim2.new(0, 8, 0.5, -13)
				btn.BackgroundColor3 = Theme.Accent
				btn.Text = ""
				btn.AutoButtonColor = false
				btn.Parent = row
				corner(btn, 5)
				stroke(btn, Theme.HeaderDark, 1)

				if icon then
					applyIcon(btn, icon, UDim2.new(0, 14, 0, 14), UDim2.new(0, 8, 0.5, 0))
				end
				local bl = Instance.new("TextLabel")
				bl.Size = UDim2.new(1, 0, 1, 0)
				bl.BackgroundTransparency = 1
				bl.Text = name
				bl.TextColor3 = Theme.Text
				bl.Font = Enum.Font.GothamBold
				bl.TextSize = 12
				bl.Parent = btn

				btn.MouseButton1Click:Connect(function()
					if callback then task.spawn(callback) end
				end)
				btn.MouseEnter:Connect(function() tween(btn, {BackgroundColor3 = Theme.TabActive}, 0.1) end)
				btn.MouseLeave:Connect(function() tween(btn, {BackgroundColor3 = Theme.Accent}, 0.1) end)
				return btn
			end

			-- Label
			function section:AddLabel(text)
				local row = makeRow(28)
				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(1, -16, 1, 0)
				lbl.Position = UDim2.new(0, 10, 0, 0)
				lbl.BackgroundTransparency = 1
				lbl.Text = tostring(text or "")
				lbl.TextColor3 = Theme.TextDim
				lbl.Font = Enum.Font.Gotham
				lbl.TextSize = 12
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.Parent = row
				local proxy = {}
				setmetatable(proxy, {
					__newindex = function(_, k, v) if k == "Text" then lbl.Text = tostring(v) end end,
					__index = function(_, k) if k == "Text" then return lbl.Text end end,
				})
				return proxy
			end

			-- Paragraph
			function section:AddParagraph(title, content)
				local row = makeRow(52)
				local t = Instance.new("TextLabel")
				t.Size = UDim2.new(1, -16, 0, 16)
				t.Position = UDim2.new(0, 10, 0, 4)
				t.BackgroundTransparency = 1
				t.Text = tostring(title or "")
				t.TextColor3 = Theme.Text
				t.Font = Enum.Font.GothamBold
				t.TextSize = 12
				t.TextXAlignment = Enum.TextXAlignment.Left
				t.Parent = row
				local c = Instance.new("TextLabel")
				c.Size = UDim2.new(1, -16, 0, 28)
				c.Position = UDim2.new(0, 10, 0, 20)
				c.BackgroundTransparency = 1
				c.Text = tostring(content or "")
				c.TextColor3 = Theme.TextMuted
				c.Font = Enum.Font.Gotham
				c.TextSize = 11
				c.TextXAlignment = Enum.TextXAlignment.Left
				c.TextWrapped = true
				c.Parent = row
				return { Title = t, Content = c }
			end

			-- Textbox
			function section:AddTextbox(opts)
				opts = opts or {}
				local name = opts.Name or "Input"
				local placeholder = opts.Placeholder or "..."
				local default = opts.Default or ""
				local flag, callback = opts.Flag, opts.Callback

				local row = makeRow(32)
				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(0.38, 0, 1, 0)
				lbl.Position = UDim2.new(0, 10, 0, 0)
				lbl.BackgroundTransparency = 1
				lbl.Text = name
				lbl.TextColor3 = Theme.Text
				lbl.Font = Enum.Font.Gotham
				lbl.TextSize = 12
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.Parent = row

				local box = Instance.new("TextBox")
				box.Size = UDim2.new(0.58, -10, 0, 22)
				box.Position = UDim2.new(0.42, 0, 0.5, -11)
				box.BackgroundColor3 = Color3.fromRGB(35, 40, 38)
				box.Text = tostring(default)
				box.PlaceholderText = placeholder
				box.TextColor3 = Theme.Text
				box.Font = Enum.Font.Gotham
				box.TextSize = 11
				box.ClearTextOnFocus = false
				box.Parent = row
				corner(box, 5)
				stroke(box, Theme.Stroke, 1)
				if flag then Window.Flags[flag] = default end
				box.FocusLost:Connect(function()
					if flag then Window.Flags[flag] = box.Text end
					if callback then callback(box.Text) end
				end)
				return box
			end

			-- Keybind
			function section:AddKeybind(opts)
				opts = opts or {}
				local name = opts.Name or "Keybind"
				local default = opts.Default or Enum.KeyCode.Unknown
				local flag, callback = opts.Flag, opts.Callback

				local row = makeRow(32)
				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(0.5, 0, 1, 0)
				lbl.Position = UDim2.new(0, 10, 0, 0)
				lbl.BackgroundTransparency = 1
				lbl.Text = name
				lbl.TextColor3 = Theme.Text
				lbl.Font = Enum.Font.Gotham
				lbl.TextSize = 12
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.Parent = row

				local key = default
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(0, 80, 0, 22)
				btn.Position = UDim2.new(1, -90, 0.5, -11)
				btn.BackgroundColor3 = Color3.fromRGB(35, 40, 38)
				btn.Text = key.Name or "None"
				btn.TextColor3 = Theme.Text
				btn.Font = Enum.Font.GothamBold
				btn.TextSize = 11
				btn.AutoButtonColor = false
				btn.Parent = row
				corner(btn, 5)
				stroke(btn, Theme.Stroke, 1)
				if flag then Window.Flags[flag] = key end

				local listening = false
				btn.MouseButton1Click:Connect(function()
					listening = true
					btn.Text = "..."
				end)
				UserInputService.InputBegan:Connect(function(inp, gp)
					if not listening then
						if not gp and inp.KeyCode == key and callback then
							task.spawn(callback)
						end
						return
					end
					if inp.UserInputType == Enum.UserInputType.Keyboard then
						key = inp.KeyCode
						btn.Text = key.Name
						listening = false
						if flag then Window.Flags[flag] = key end
						if opts.OnChanged then opts.OnChanged(key) end
					end
				end)

				local api = {}
				function api:Set(k) key = k; btn.Text = k.Name; if flag then Window.Flags[flag] = k end end
				function api:Get() return key end
				return api
			end

			-- Separator
			function section:AddSeparator()
				local row = Instance.new("Frame")
				row.Size = UDim2.new(1, 0, 0, 8)
				row.BackgroundTransparency = 1
				row.LayoutOrder = nextOrder()
				row.Parent = body
				local line = Instance.new("Frame")
				line.Size = UDim2.new(1, -20, 0, 1)
				line.Position = UDim2.new(0, 10, 0.5, 0)
				line.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
				line.BorderSizePixel = 0
				line.Parent = row
				return row
			end

			table.insert(self.Sections, section)
			return section
		end

		table.insert(self.Tabs, tab)
		if order == 1 then
			page.Visible = true
			btn.BackgroundColor3 = Theme.TabActive
			self.CurrentTab = name
		end
		return tab
	end

	function Window:AddRightButton(name, callback, icon)
		local btn = makeSideButton(RightScroll, name, #RightScroll:GetChildren(), icon)
		btn.MouseButton1Click:Connect(function()
			if callback then task.spawn(callback) end
		end)
		return btn
	end

	function Window:Notify(title, text, duration, notifType)
		duration = duration or 3
		local col = Theme.Accent
		if notifType == "success" then col = Theme.Success
		elseif notifType == "warning" then col = Theme.Warning
		elseif notifType == "error" then col = Theme.Error end

		local nGui = CoreGui:FindFirstChild("RubiNotify")
		if not nGui then
			nGui = Instance.new("ScreenGui")
			nGui.Name = "RubiNotify"
			nGui.ResetOnSpawn = false
			nGui.DisplayOrder = 300
			nGui.Parent = CoreGui
		end

		local n = Instance.new("Frame")
		n.Size = UDim2.new(0, 240, 0, 64)
		n.Position = UDim2.new(1, -260, 1, -90)
		n.BackgroundColor3 = Theme.Panel
		n.Parent = nGui
		corner(n, 8)
		stroke(n, col, 1.5)

		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(0, 4, 1, 0)
		bar.BackgroundColor3 = col
		bar.BorderSizePixel = 0
		bar.Parent = n

		local t = Instance.new("TextLabel")
		t.Size = UDim2.new(1, -16, 0, 22)
		t.Position = UDim2.new(0, 12, 0, 6)
		t.BackgroundTransparency = 1
		t.Text = title or "Rubi Hub"
		t.TextColor3 = Theme.Text
		t.Font = Enum.Font.GothamBold
		t.TextSize = 13
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.Parent = n

		local d = Instance.new("TextLabel")
		d.Size = UDim2.new(1, -16, 0, 28)
		d.Position = UDim2.new(0, 12, 0, 28)
		d.BackgroundTransparency = 1
		d.Text = text or ""
		d.TextColor3 = Theme.TextDim
		d.Font = Enum.Font.Gotham
		d.TextSize = 11
		d.TextXAlignment = Enum.TextXAlignment.Left
		d.TextWrapped = true
		d.Parent = n

		task.delay(duration, function()
			tween(n, {BackgroundTransparency = 1}, 0.25)
			task.wait(0.25)
			n:Destroy()
		end)
	end

	function Window:SetVisible(v) Main.Visible = v end
	function Window:Destroy()
		Screen:Destroy()
		FPSGui:Destroy()
		local n = CoreGui:FindFirstChild("RubiNotify")
		if n then n:Destroy() end
		local q = CoreGui:FindFirstChild("RubiQuickBar")
		if q then q:Destroy() end
	end

	-- Search
	SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local q = string.lower(SearchBox.Text)
		local tab
		for _, t in pairs(Window.Tabs) do
			if t.Name == Window.CurrentTab then tab = t break end
		end
		if not tab then return end
		for _, sec in pairs(tab.Sections) do
			for _, child in ipairs(sec.Body:GetChildren()) do
				if child:IsA("Frame") then
					if q == "" then
						child.Visible = true
					else
						local found = false
						for _, d in ipairs(child:GetDescendants()) do
							if (d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox")) and d.Text and string.find(string.lower(d.Text), q, 1, true) then
								found = true
								break
							end
						end
						child.Visible = found
					end
				end
			end
		end
	end)

	-- Quick Bar
	function Window:CreateQuickBar(barName)
		local QGui = CoreGui:FindFirstChild("RubiQuickBar")
		if not QGui then
			QGui = Instance.new("ScreenGui")
			QGui.Name = "RubiQuickBar"
			QGui.ResetOnSpawn = false
			QGui.DisplayOrder = 180
			QGui.Parent = CoreGui
		end

		local bar = Instance.new("Frame")
		bar.Name = barName or "QuickBar1"
		bar.Size = UDim2.new(0, 170, 0, 28)
		bar.Position = UDim2.new(0.7, 0, 0.05, 0)
		bar.BackgroundTransparency = 1
		bar.Parent = QGui

		local handle = Instance.new("TextButton")
		handle.Size = UDim2.new(1, 0, 0, 26)
		handle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		handle.BackgroundTransparency = 0.35
		handle.Text = ""
		handle.AutoButtonColor = false
		handle.Parent = bar
		corner(handle, 4)
		stroke(handle, Theme.Stroke, 1)

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -28, 1, 0)
		title.Position = UDim2.new(0, 8, 0, 0)
		title.BackgroundTransparency = 1
		title.Text = barName or "Quick Bar"
		title.TextColor3 = Theme.Text
		title.Font = Enum.Font.GothamBold
		title.TextSize = 11
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Parent = handle

		local collapse = Instance.new("TextButton")
		collapse.Size = UDim2.new(0, 22, 0, 22)
		collapse.Position = UDim2.new(1, -24, 0.5, -11)
		collapse.BackgroundTransparency = 1
		collapse.Text = "▼"
		collapse.TextColor3 = Theme.Text
		collapse.Font = Enum.Font.GothamBold
		collapse.TextSize = 10
		collapse.Parent = handle

		local body = Instance.new("Frame")
		body.Size = UDim2.new(1, 20, 0, 0)
		body.Position = UDim2.new(0.5, 0, 0, 28)
		body.AnchorPoint = Vector2.new(0.5, 0)
		body.BackgroundTransparency = 1
		body.AutomaticSize = Enum.AutomaticSize.Y
		body.Parent = bar
		list(body, Enum.FillDirection.Vertical, 4)

		makeDraggable(handle, bar)
		local expanded = true
		collapse.MouseButton1Click:Connect(function()
			expanded = not expanded
			body.Visible = expanded
			collapse.Text = expanded and "▼" or "▶"
		end)

		local qb = { Bar = bar, Body = body }
		function qb:AddToggle(name, callback, default)
			local item = Instance.new("TextButton")
			item.Size = UDim2.new(1, 0, 0, 28)
			item.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			item.BackgroundTransparency = 0.4
			item.Text = ""
			item.AutoButtonColor = false
			item.Parent = body
			corner(item, 4)
			stroke(item, Theme.Stroke, 1)

			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, -40, 1, 0)
			lbl.Position = UDim2.new(0, 6, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = name
			lbl.TextColor3 = Theme.Text
			lbl.Font = Enum.Font.Gotham
			lbl.TextSize = 11
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Parent = item

			local track = Instance.new("Frame")
			track.Size = UDim2.new(0, 28, 0, 14)
			track.Position = UDim2.new(1, -34, 0.5, -7)
			track.BackgroundColor3 = default and Theme.ToggleOn or Theme.ToggleOff
			track.Parent = item
			corner(track, 7)

			local knob = Instance.new("Frame")
			knob.Size = UDim2.new(0, 12, 0, 12)
			knob.Position = default and UDim2.new(1, -13, 0.5, -6) or UDim2.new(0, 1, 0.5, -6)
			knob.BackgroundColor3 = Theme.White
			knob.Parent = track
			corner(knob, 6)

			local state = default or false
			item.MouseButton1Click:Connect(function()
				state = not state
				track.BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff
				knob.Position = state and UDim2.new(1, -13, 0.5, -6) or UDim2.new(0, 1, 0.5, -6)
				if callback then callback(state) end
			end)
			return item
		end
		return qb
	end

	return Window
end

-- Theme access
function Rubi:GetTheme() return Theme end
function Rubi:SetTheme(key, color)
	if Theme[key] then Theme[key] = color end
end

return Rubi
