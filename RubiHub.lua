--[[
    Rubi Hub UI Library
    Chilli Hub style recreation
    Transparent panels · pill toggles · curved sliders · multi/single dropdowns · quick bars · chili toggle button

    Usage:
        local Rubi = loadstring(game:HttpGet("https://raw.githubusercontent.com/slowzzx48/Muscle-Legends-/refs/heads/main/RubiHub.lua"))()
        local Window = Rubi:CreateWindow({ Title = "Rubi Hub" })
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = (gethui and gethui()) or game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local Rubi = {}
Rubi.__index = Rubi
Rubi.Version = "3.0"

local Theme = {
	Header = Color3.fromRGB(175, 15, 20),
	HeaderDark = Color3.fromRGB(110, 0, 5),
	Accent = Color3.fromRGB(190, 20, 25),
	AccentHover = Color3.fromRGB(220, 40, 45),
	Background = Color3.fromRGB(12, 18, 14),
	Panel = Color3.fromRGB(18, 26, 20),
	PanelAlt = Color3.fromRGB(14, 20, 16),
	Row = Color3.fromRGB(8, 12, 10),
	Stroke = Color3.fromRGB(0, 0, 0),
	Text = Color3.fromRGB(255, 255, 255),
	TextDim = Color3.fromRGB(190, 195, 190),
	TextMuted = Color3.fromRGB(130, 135, 130),
	ToggleOn = Color3.fromRGB(45, 200, 75),
	ToggleOff = Color3.fromRGB(55, 60, 55),
	SliderFill = Color3.fromRGB(45, 200, 75),
	SliderBg = Color3.fromRGB(35, 42, 38),
	Tab = Color3.fromRGB(175, 20, 25),
	TabActive = Color3.fromRGB(210, 35, 40),
	SearchBg = Color3.fromRGB(20, 28, 22),
	White = Color3.fromRGB(255, 255, 255),
	Success = Color3.fromRGB(45, 200, 75),
	Warning = Color3.fromRGB(255, 170, 40),
	Error = Color3.fromRGB(220, 50, 50),
	QuickBar = Color3.fromRGB(0, 0, 0),
}

local function tween(obj, props, t, style)
	local ti = TweenInfo.new(t or 0.15, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
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

pcall(function()
	for _, n in ipairs({"RubiHubGui", "RubiQuickBar", "RubiFPS", "RubiNotify", "RubiChiliBtn", "RubiDialog"}) do
		local o = CoreGui:FindFirstChild(n)
		if o then o:Destroy() end
	end
end)

function Rubi:CreateWindow(opts)
	opts = opts or {}
	local title = opts.Title or "Rubi Hub"
	local size = opts.Size or UDim2.new(0, 560, 0, 420)
	local transparency = opts.Transparency or 0.18

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
	Main.BackgroundTransparency = transparency
	Main.BorderSizePixel = 0
	Main.Active = true
	Main.ClipsDescendants = true
	Main.Parent = Screen
	corner(Main, 8)
	stroke(Main, Theme.Stroke, 1.5)

	local Header = Instance.new("Frame")
	Header.Name = "Header"
	Header.Size = UDim2.new(1, 0, 0, 36)
	Header.BackgroundColor3 = Theme.Header
	Header.BackgroundTransparency = 0
	Header.BorderSizePixel = 0
	Header.Parent = Main
	stroke(Header, Theme.HeaderDark, 1)

	local HeaderLabel = Instance.new("TextLabel")
	HeaderLabel.Name = "Title"
	HeaderLabel.Size = UDim2.new(1, -50, 1, 0)
	HeaderLabel.Position = UDim2.new(0, 14, 0, 0)
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
	CloseBtn.BackgroundColor3 = Theme.HeaderDark
	CloseBtn.Text = "X"
	CloseBtn.TextColor3 = Theme.Text
	CloseBtn.Font = Enum.Font.GothamBold
	CloseBtn.TextSize = 14
	CloseBtn.AutoButtonColor = false
	CloseBtn.Parent = Header
	corner(CloseBtn, 4)
	CloseBtn.MouseEnter:Connect(function() tween(CloseBtn, {BackgroundColor3 = Theme.Error}, 0.1) end)
	CloseBtn.MouseLeave:Connect(function() tween(CloseBtn, {BackgroundColor3 = Theme.HeaderDark}, 0.1) end)

	makeDraggable(Header, Main)

	local LeftBar = Instance.new("Frame")
	LeftBar.Name = "LeftBar"
	LeftBar.Size = UDim2.new(0, 100, 1, -36)
	LeftBar.Position = UDim2.new(0, 0, 0, 36)
	LeftBar.BackgroundColor3 = Theme.PanelAlt
	LeftBar.BackgroundTransparency = transparency * 0.6
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
	list(LeftScroll, Enum.FillDirection.Vertical, 5)
	pad(LeftScroll, 8, 8, 6, 6)

	local RightBar = Instance.new("Frame")
	RightBar.Name = "RightBar"
	RightBar.Size = UDim2.new(0, 100, 1, -36)
	RightBar.Position = UDim2.new(1, -100, 0, 36)
	RightBar.BackgroundColor3 = Theme.PanelAlt
	RightBar.BackgroundTransparency = transparency * 0.6
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
	list(RightScroll, Enum.FillDirection.Vertical, 5)
	pad(RightScroll, 8, 8, 6, 6)

	local Content = Instance.new("Frame")
	Content.Name = "Content"
	Content.Size = UDim2.new(1, -200, 1, -70)
	Content.Position = UDim2.new(0, 100, 0, 36)
	Content.BackgroundColor3 = Theme.Panel
	Content.BackgroundTransparency = transparency
	Content.BorderSizePixel = 0
	Content.ClipsDescendants = true
	Content.Parent = Main

	local SearchBar = Instance.new("Frame")
	SearchBar.Name = "SearchBar"
	SearchBar.Size = UDim2.new(1, -200, 0, 34)
	SearchBar.Position = UDim2.new(0, 100, 1, -34)
	SearchBar.BackgroundColor3 = Theme.SearchBg
	SearchBar.BackgroundTransparency = transparency * 0.5
	SearchBar.BorderSizePixel = 0
	SearchBar.Parent = Main

	local SearchBox = Instance.new("TextBox")
	SearchBox.Name = "Search"
	SearchBox.Size = UDim2.new(1, -16, 0, 24)
	SearchBox.Position = UDim2.new(0, 8, 0.5, -12)
	SearchBox.BackgroundColor3 = Color3.fromRGB(28, 36, 30)
	SearchBox.BackgroundTransparency = 0.2
	SearchBox.PlaceholderText = "Search  Filter features..."
	SearchBox.PlaceholderColor3 = Theme.TextMuted
	SearchBox.Text = ""
	SearchBox.TextColor3 = Theme.Text
	SearchBox.Font = Enum.Font.Gotham
	SearchBox.TextSize = 12
	SearchBox.ClearTextOnFocus = false
	SearchBox.Parent = SearchBar
	corner(SearchBox, 6)
	stroke(SearchBox, Color3.fromRGB(40, 45, 42), 1)
	pad(SearchBox, 0, 0, 10, 10)

	local FPSGui = Instance.new("ScreenGui")
	FPSGui.Name = "RubiFPS"
	FPSGui.ResetOnSpawn = false
	FPSGui.DisplayOrder = 250
	FPSGui.Parent = CoreGui

	local FPSLabel = Instance.new("TextLabel")
	FPSLabel.Size = UDim2.new(0, 120, 0, 18)
	FPSLabel.Position = UDim2.new(1, -130, 0, 6)
	FPSLabel.BackgroundTransparency = 1
	FPSLabel.Text = "0 FPS  0 ms"
	FPSLabel.TextColor3 = Theme.Text
	FPSLabel.Font = Enum.Font.GothamBold
	FPSLabel.TextSize = 11
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

	local ChiliGui = Instance.new("ScreenGui")
	ChiliGui.Name = "RubiChiliBtn"
	ChiliGui.ResetOnSpawn = false
	ChiliGui.DisplayOrder = 190
	ChiliGui.Parent = CoreGui

	local ChiliBtn = Instance.new("TextButton")
	ChiliBtn.Name = "Chili"
	ChiliBtn.Size = UDim2.new(0, 44, 0, 44)
	ChiliBtn.Position = UDim2.new(0, 16, 0.5, -22)
	ChiliBtn.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	ChiliBtn.BackgroundTransparency = 0.15
	ChiliBtn.Text = "\u{1F336}"
	ChiliBtn.TextSize = 22
	ChiliBtn.Font = Enum.Font.GothamBold
	ChiliBtn.TextColor3 = Color3.fromRGB(220, 40, 40)
	ChiliBtn.AutoButtonColor = false
	ChiliBtn.Visible = false
	ChiliBtn.Parent = ChiliGui
	corner(ChiliBtn, 22)
	stroke(ChiliBtn, Color3.fromRGB(40, 40, 40), 1.5)
	makeDraggable(ChiliBtn, ChiliBtn)

	local Window = {
		Screen = Screen,
		Main = Main,
		Tabs = {},
		CurrentTab = nil,
		SearchBox = SearchBox,
		Flags = {},
		Theme = Theme,
		_visible = true,
	}

	local function setMainVisible(v)
		Window._visible = v
		Main.Visible = v
		ChiliBtn.Visible = not v
	end

	CloseBtn.MouseButton1Click:Connect(function()
		setMainVisible(false)
	end)
	ChiliBtn.MouseButton1Click:Connect(function()
		setMainVisible(true)
	end)

	local function makeSideButton(parent, text, order)
		local btn = Instance.new("TextButton")
		btn.Name = text
		btn.Size = UDim2.new(1, 0, 0, 32)
		btn.BackgroundColor3 = Theme.Tab
		btn.BackgroundTransparency = 0
		btn.Text = text
		btn.TextColor3 = Theme.Text
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 12
		btn.LayoutOrder = order or 0
		btn.AutoButtonColor = false
		btn.Parent = parent
		corner(btn, 6)
		stroke(btn, Theme.HeaderDark, 1)
		btn.MouseEnter:Connect(function()
			if Window.CurrentTab ~= text then
				tween(btn, {BackgroundColor3 = Theme.TabActive}, 0.1)
			end
		end)
		btn.MouseLeave:Connect(function()
			if Window.CurrentTab ~= text then
				tween(btn, {BackgroundColor3 = Theme.Tab}, 0.1)
			end
		end)
		return btn
	end

	function Window:CreateTab(name)
		local order = #self.Tabs + 1
		local page = Instance.new("ScrollingFrame")
		page.Name = name
		page.Size = UDim2.new(1, 0, 1, 0)
		page.BackgroundTransparency = 1
		page.BorderSizePixel = 0
		page.ScrollBarThickness = 3
		page.ScrollBarImageColor3 = Theme.Accent
		page.CanvasSize = UDim2.new(0, 0, 0, 0)
		page.AutomaticCanvasSize = Enum.AutomaticSize.Y
		page.Visible = false
		page.Parent = Content
		list(page, Enum.FillDirection.Vertical, 5)
		pad(page, 8, 8, 8, 8)

		local btn = makeSideButton(LeftScroll, name, order)
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
			sectionFrame.Size = UDim2.new(1, 0, 0, 0)
			sectionFrame.BackgroundTransparency = 1
			sectionFrame.AutomaticSize = Enum.AutomaticSize.Y
			sectionFrame.LayoutOrder = secOrder
			sectionFrame.Parent = page
			list(sectionFrame, Enum.FillDirection.Vertical, 3)

			local headerBtn = Instance.new("TextButton")
			headerBtn.Name = "Header"
			headerBtn.Size = UDim2.new(1, 0, 0, 22)
			headerBtn.BackgroundTransparency = 1
			headerBtn.Text = ""
			headerBtn.AutoButtonColor = false
			headerBtn.LayoutOrder = 1
			headerBtn.Parent = sectionFrame

			local arrow = Instance.new("TextLabel")
			arrow.Size = UDim2.new(0, 16, 1, 0)
			arrow.Position = UDim2.new(0, 2, 0, 0)
			arrow.BackgroundTransparency = 1
			arrow.Text = "\u{25BC}"
			arrow.TextColor3 = Theme.TextDim
			arrow.Font = Enum.Font.GothamBold
			arrow.TextSize = 10
			arrow.Parent = headerBtn

			local headerLbl = Instance.new("TextLabel")
			headerLbl.Size = UDim2.new(1, -24, 1, 0)
			headerLbl.Position = UDim2.new(0, 18, 0, 0)
			headerLbl.BackgroundTransparency = 1
			headerLbl.Text = sectionName
			headerLbl.TextColor3 = Theme.Text
			headerLbl.Font = Enum.Font.GothamBold
			headerLbl.TextSize = 13
			headerLbl.TextXAlignment = Enum.TextXAlignment.Left
			headerLbl.Parent = headerBtn

			local body = Instance.new("Frame")
			body.Name = "Body"
			body.Size = UDim2.new(1, 0, 0, 0)
			body.BackgroundTransparency = 1
			body.AutomaticSize = Enum.AutomaticSize.Y
			body.LayoutOrder = 2
			body.Visible = true
			body.Parent = sectionFrame
			list(body, Enum.FillDirection.Vertical, 3)

			local open = true
			headerBtn.MouseButton1Click:Connect(function()
				open = not open
				body.Visible = open
				arrow.Text = open and "\u{25BC}" or "\u{25B6}"
			end)

			local section = { Name = sectionName, Body = body, _order = 0 }
			local function nextOrder()
				section._order = section._order + 1
				return section._order
			end

			local function makeRow(height)
				local row = Instance.new("Frame")
				row.Size = UDim2.new(1, 0, 0, height or 30)
				row.BackgroundColor3 = Theme.Row
				row.BackgroundTransparency = 0.55
				row.LayoutOrder = nextOrder()
				row.Parent = body
				corner(row, 5)
				stroke(row, Color3.fromRGB(0, 0, 0), 1)
				return row
			end

			function section:AddToggle(opts)
				opts = type(opts) == "table" and opts or { Name = tostring(opts) }
				local name = opts.Name or "Toggle"
				local desc = opts.Description or opts.Desc
				local default = opts.Default or false
				local flag = opts.Flag
				local callback = opts.Callback

				local h = desc and 42 or 30
				local row = makeRow(h)

				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(1, -54, 0, desc and 16 or 30)
				lbl.Position = UDim2.new(0, 10, 0, desc and 3 or 0)
				lbl.BackgroundTransparency = 1
				lbl.Text = name
				lbl.TextColor3 = Theme.Text
				lbl.Font = Enum.Font.Gotham
				lbl.TextSize = 12
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.Parent = row

				if desc then
					local d = Instance.new("TextLabel")
					d.Size = UDim2.new(1, -54, 0, 14)
					d.Position = UDim2.new(0, 10, 0, 20)
					d.BackgroundTransparency = 1
					d.Text = desc
					d.TextColor3 = Theme.TextMuted
					d.Font = Enum.Font.Gotham
					d.TextSize = 10
					d.TextXAlignment = Enum.TextXAlignment.Left
					d.TextTruncate = Enum.TextTruncate.AtEnd
					d.Parent = row
				end

				local track = Instance.new("Frame")
				track.Size = UDim2.new(0, 38, 0, 18)
				track.Position = UDim2.new(1, -46, 0.5, -9)
				track.BackgroundColor3 = default and Theme.ToggleOn or Theme.ToggleOff
				track.Parent = row
				corner(track, 9)
				stroke(track, Theme.Stroke, 1)

				local knob = Instance.new("Frame")
				knob.Size = UDim2.new(0, 14, 0, 14)
				knob.Position = default and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
				knob.BackgroundColor3 = Theme.White
				knob.Parent = track
				corner(knob, 7)

				local state = default
				if flag then Window.Flags[flag] = state end

				local function set(v, fire)
					state = not not v
					tween(track, {BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff}, 0.12)
					tween(knob, {Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}, 0.14)
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
				function api:SetValue(v) set(v) end
				return api
			end

			function section:AddSlider(opts)
				opts = opts or {}
				local name = opts.Name or "Slider"
				local min, max = opts.Min or 0, opts.Max or 100
				local default = opts.Default or min
				local flag, callback = opts.Flag, opts.Callback
				local suffix = opts.Suffix or ""
				local decimals = opts.Decimals or 0

				local row = makeRow(46)
				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(0.55, 0, 0, 16)
				lbl.Position = UDim2.new(0, 10, 0, 3)
				lbl.BackgroundTransparency = 1
				lbl.Text = name
				lbl.TextColor3 = Theme.Text
				lbl.Font = Enum.Font.Gotham
				lbl.TextSize = 12
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.Parent = row

				local valLbl = Instance.new("TextLabel")
				valLbl.Size = UDim2.new(0, 70, 0, 16)
				valLbl.Position = UDim2.new(1, -78, 0, 3)
				valLbl.BackgroundTransparency = 1
				valLbl.Text = tostring(default) .. suffix
				valLbl.TextColor3 = Theme.Text
				valLbl.Font = Enum.Font.GothamBold
				valLbl.TextSize = 12
				valLbl.TextXAlignment = Enum.TextXAlignment.Right
				valLbl.Parent = row

				local bar = Instance.new("Frame")
				bar.Size = UDim2.new(1, -20, 0, 8)
				bar.Position = UDim2.new(0, 10, 1, -16)
				bar.BackgroundColor3 = Theme.SliderBg
				bar.Parent = row
				corner(bar, 4)

				local fill = Instance.new("Frame")
				fill.Size = UDim2.new(math.clamp((default - min) / math.max(max - min, 1), 0, 1), 0, 1, 0)
				fill.BackgroundColor3 = Theme.SliderFill
				fill.Parent = bar
				corner(fill, 4)

				local value = default
				if flag then Window.Flags[flag] = value end
				local sliding = false

				local function fmt(v)
					if decimals > 0 then
						return string.format("%." .. decimals .. "f", v) .. suffix
					end
					return tostring(math.floor(v + 0.5)) .. suffix
				end

				local function update(x)
					local rel = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
					value = min + (max - min) * rel
					if decimals == 0 then value = math.floor(value + 0.5) end
					fill.Size = UDim2.new(rel, 0, 1, 0)
					valLbl.Text = fmt(value)
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
					valLbl.Text = fmt(value)
					if flag then Window.Flags[flag] = value end
					if callback then task.spawn(callback, value) end
				end
				function api:Get() return value end
				function api:SetValue(v) api:Set(v) end
				return api
			end

			function section:AddDropdown(opts)
				opts = opts or {}
				local name = opts.Name or "Dropdown"
				local options = opts.Options or {}
				local default = opts.Default
				local multi = opts.Multi or false
				local flag, callback = opts.Flag, opts.Callback
				local searchable = opts.Searchable ~= false

				local row = makeRow(30)
				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(0.36, 0, 1, 0)
				lbl.Position = UDim2.new(0, 10, 0, 0)
				lbl.BackgroundTransparency = 1
				lbl.Text = name
				lbl.TextColor3 = Theme.Text
				lbl.Font = Enum.Font.Gotham
				lbl.TextSize = 12
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.Parent = row

				local dropBtn = Instance.new("TextButton")
				dropBtn.Size = UDim2.new(0.60, -10, 0, 22)
				dropBtn.Position = UDim2.new(0.40, 0, 0.5, -11)
				dropBtn.BackgroundColor3 = Color3.fromRGB(30, 38, 32)
				dropBtn.BackgroundTransparency = 0.15
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
				caret.Text = "\u{25BC}"
				caret.TextColor3 = Theme.Text
				caret.Font = Enum.Font.Gotham
				caret.TextSize = 9
				caret.Parent = dropBtn

				local listFrame = Instance.new("Frame")
				listFrame.Name = "DropList"
				listFrame.Size = UDim2.new(0, 0, 0, 0)
				listFrame.BackgroundColor3 = Color3.fromRGB(22, 28, 24)
				listFrame.BackgroundTransparency = 0.05
				listFrame.BorderSizePixel = 0
				listFrame.Visible = false
				listFrame.ZIndex = 60
				listFrame.ClipsDescendants = true
				listFrame.Parent = Content
				corner(listFrame, 6)
				stroke(listFrame, Theme.Stroke, 1)

				local searchBox
				if searchable then
					searchBox = Instance.new("TextBox")
					searchBox.Size = UDim2.new(1, -8, 0, 22)
					searchBox.Position = UDim2.new(0, 4, 0, 4)
					searchBox.BackgroundColor3 = Color3.fromRGB(32, 40, 34)
					searchBox.PlaceholderText = "Search..."
					searchBox.PlaceholderColor3 = Theme.TextMuted
					searchBox.Text = ""
					searchBox.TextColor3 = Theme.Text
					searchBox.Font = Enum.Font.Gotham
					searchBox.TextSize = 11
					searchBox.ClearTextOnFocus = false
					searchBox.ZIndex = 61
					searchBox.Parent = listFrame
					corner(searchBox, 4)
					pad(searchBox, 0, 0, 6, 6)
				end

				local optScroll = Instance.new("ScrollingFrame")
				optScroll.Size = UDim2.new(1, -4, 1, searchable and -30 or -4)
				optScroll.Position = UDim2.new(0, 2, 0, searchable and 28 or 2)
				optScroll.BackgroundTransparency = 1
				optScroll.BorderSizePixel = 0
				optScroll.ScrollBarThickness = 3
				optScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
				optScroll.ZIndex = 61
				optScroll.Parent = listFrame

				local grid = Instance.new("UIGridLayout")
				grid.CellSize = multi and UDim2.new(0.48, -2, 0, 22) or UDim2.new(1, -4, 0, 22)
				grid.CellPadding = UDim2.new(0, 3, 0, 2)
				grid.SortOrder = Enum.SortOrder.LayoutOrder
				grid.Parent = optScroll
				pad(optScroll, 2, 2, 2, 2)

				local selected = {}
				if multi then
					if type(default) == "table" then
						for _, v in ipairs(default) do selected[v] = true end
					end
				else
					if default then selected[default] = true end
				end
				if flag then Window.Flags[flag] = multi and selected or default end

				local isOpen = false
				local filtered = options

				local function countSelected()
					local n = 0
					for _ in pairs(selected) do n = n + 1 end
					return n
				end

				local function refreshLabel()
					if multi then
						local n = countSelected()
						dropBtn.Text = "  " .. (n > 0 and (n .. " selected") or "0 selected")
					else
						local v = next(selected)
						dropBtn.Text = "  " .. (v and tostring(v) or "Select...")
					end
				end

				local function rebuild()
					for _, c in ipairs(optScroll:GetChildren()) do
						if c:IsA("TextButton") then c:Destroy() end
					end
					for i, opt in ipairs(filtered) do
						local ob = Instance.new("TextButton")
						ob.Size = UDim2.new(1, 0, 0, 22)
						ob.BackgroundColor3 = selected[opt] and Color3.fromRGB(40, 90, 50) or Color3.fromRGB(32, 40, 34)
						ob.Text = (multi and (selected[opt] and " \u{2611} " or " \u{2610} ") or "  ") .. tostring(opt)
						ob.TextColor3 = Theme.Text
						ob.Font = Enum.Font.Gotham
						ob.TextSize = 11
						ob.TextXAlignment = Enum.TextXAlignment.Left
						ob.LayoutOrder = i
						ob.ZIndex = 62
						ob.AutoButtonColor = false
						ob.Parent = optScroll
						corner(ob, 4)

						ob.MouseButton1Click:Connect(function()
							if multi then
								selected[opt] = not selected[opt] or nil
								ob.BackgroundColor3 = selected[opt] and Color3.fromRGB(40, 90, 50) or Color3.fromRGB(32, 40, 34)
								ob.Text = (selected[opt] and " \u{2611} " or " \u{2610} ") .. tostring(opt)
								refreshLabel()
								if flag then Window.Flags[flag] = selected end
								if callback then task.spawn(callback, selected) end
							else
								table.clear(selected)
								selected[opt] = true
								dropBtn.Text = "  " .. tostring(opt)
								isOpen = false
								listFrame.Visible = false
								caret.Text = "\u{25BC}"
								if flag then Window.Flags[flag] = opt end
								if callback then task.spawn(callback, opt) end
							end
						end)
					end
					local rows = multi and math.ceil(#filtered / 2) or #filtered
					optScroll.CanvasSize = UDim2.new(0, 0, 0, rows * 24 + 4)
				end
				rebuild()
				refreshLabel()

				local function openList()
					local abs = dropBtn.AbsolutePosition
					local absSize = dropBtn.AbsoluteSize
					local contentAbs = Content.AbsolutePosition
					listFrame.Position = UDim2.new(0, abs.X - contentAbs.X, 0, abs.Y - contentAbs.Y + absSize.Y + 2)
					listFrame.Size = UDim2.new(0, math.max(absSize.X, multi and 280 or 180), 0, math.min((multi and math.ceil(#filtered / 2) or #filtered) * 24 + (searchable and 36 or 8), 180))
					listFrame.Visible = true
					caret.Text = "\u{25B2}"
					isOpen = true
					if searchBox then searchBox.Text = "" end
					filtered = options
					rebuild()
				end

				local function closeList()
					isOpen = false
					listFrame.Visible = false
					caret.Text = "\u{25BC}"
				end

				dropBtn.MouseButton1Click:Connect(function()
					if isOpen then closeList() else openList() end
				end)

				if searchBox then
					searchBox:GetPropertyChangedSignal("Text"):Connect(function()
						local q = string.lower(searchBox.Text)
						filtered = {}
						for _, o in ipairs(options) do
							if q == "" or string.find(string.lower(tostring(o)), q, 1, true) then
								table.insert(filtered, o)
							end
						end
						rebuild()
					end)
				end

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
					filtered = options
					rebuild()
				end
				function api:SetValue(v) api:Set(v) end
				return api
			end

			function section:AddButton(opts)
				opts = type(opts) == "table" and opts or { Name = tostring(opts) }
				local name = opts.Name or "Button"
				local callback = opts.Callback
				local style = opts.Style

				local row = makeRow(32)
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, -16, 0, 24)
				btn.Position = UDim2.new(0, 8, 0.5, -12)
				btn.BackgroundColor3 = style == "danger" and Theme.Error or Theme.Accent
				btn.Text = name
				btn.TextColor3 = Theme.Text
				btn.Font = Enum.Font.GothamBold
				btn.TextSize = 12
				btn.AutoButtonColor = false
				btn.Parent = row
				corner(btn, 5)
				stroke(btn, Theme.HeaderDark, 1)

				btn.MouseButton1Click:Connect(function()
					if callback then task.spawn(callback) end
				end)
				btn.MouseEnter:Connect(function()
					tween(btn, {BackgroundColor3 = style == "danger" and Color3.fromRGB(255, 70, 70) or Theme.AccentHover}, 0.1)
				end)
				btn.MouseLeave:Connect(function()
					tween(btn, {BackgroundColor3 = style == "danger" and Theme.Error or Theme.Accent}, 0.1)
				end)
				return btn
			end

			function section:AddLabel(text)
				local row = makeRow(26)
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
					__index = function(_, k) if k == "Text" then return lbl.Text end; if k == "SetTitle" then return function(_, t) lbl.Text = tostring(t) end end end,
				})
				return proxy
			end

			function section:AddParagraph(title, content)
				local row = makeRow(50)
				local t = Instance.new("TextLabel")
				t.Size = UDim2.new(1, -16, 0, 15)
				t.Position = UDim2.new(0, 10, 0, 3)
				t.BackgroundTransparency = 1
				t.Text = tostring(title or "")
				t.TextColor3 = Theme.Text
				t.Font = Enum.Font.GothamBold
				t.TextSize = 12
				t.TextXAlignment = Enum.TextXAlignment.Left
				t.Parent = row
				local c = Instance.new("TextLabel")
				c.Size = UDim2.new(1, -16, 0, 28)
				c.Position = UDim2.new(0, 10, 0, 18)
				c.BackgroundTransparency = 1
				c.Text = tostring(content or "")
				c.TextColor3 = Theme.TextMuted
				c.Font = Enum.Font.Gotham
				c.TextSize = 10
				c.TextXAlignment = Enum.TextXAlignment.Left
				c.TextWrapped = true
				c.Parent = row
				return { Title = t, Content = c }
			end

			function section:AddTextbox(opts)
				opts = opts or {}
				local name = opts.Name or "Input"
				local placeholder = opts.Placeholder or "..."
				local default = opts.Default or ""
				local flag, callback = opts.Flag, opts.Callback

				local row = makeRow(30)
				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(0.36, 0, 1, 0)
				lbl.Position = UDim2.new(0, 10, 0, 0)
				lbl.BackgroundTransparency = 1
				lbl.Text = name
				lbl.TextColor3 = Theme.Text
				lbl.Font = Enum.Font.Gotham
				lbl.TextSize = 12
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.Parent = row

				local box = Instance.new("TextBox")
				box.Size = UDim2.new(0.60, -10, 0, 20)
				box.Position = UDim2.new(0.40, 0, 0.5, -10)
				box.BackgroundColor3 = Color3.fromRGB(30, 38, 32)
				box.BackgroundTransparency = 0.15
				box.Text = tostring(default)
				box.PlaceholderText = placeholder
				box.PlaceholderColor3 = Theme.TextMuted
				box.TextColor3 = Theme.Text
				box.Font = Enum.Font.Gotham
				box.TextSize = 11
				box.ClearTextOnFocus = false
				box.Parent = row
				corner(box, 5)
				stroke(box, Theme.Stroke, 1)
				pad(box, 0, 0, 6, 6)
				if flag then Window.Flags[flag] = default end
				box.FocusLost:Connect(function()
					if flag then Window.Flags[flag] = box.Text end
					if callback then callback(box.Text) end
				end)
				return box
			end

			function section:AddKeybind(opts)
				opts = opts or {}
				local name = opts.Name or "Keybind"
				local default = opts.Default or Enum.KeyCode.Unknown
				local flag, callback = opts.Flag, opts.Callback

				local row = makeRow(30)
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
				btn.Size = UDim2.new(0, 72, 0, 20)
				btn.Position = UDim2.new(1, -82, 0.5, -10)
				btn.BackgroundColor3 = Color3.fromRGB(30, 38, 32)
				btn.Text = (key and key.Name) or "None"
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

			function section:AddSeparator()
				local row = Instance.new("Frame")
				row.Size = UDim2.new(1, 0, 0, 6)
				row.BackgroundTransparency = 1
				row.LayoutOrder = nextOrder()
				row.Parent = body
				local line = Instance.new("Frame")
				line.Size = UDim2.new(1, -20, 0, 1)
				line.Position = UDim2.new(0, 10, 0.5, 0)
				line.BackgroundColor3 = Color3.fromRGB(50, 55, 50)
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

	function Window:AddRightButton(name, callback)
		local btn = makeSideButton(RightScroll, name, #RightScroll:GetChildren())
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
		n.Size = UDim2.new(0, 250, 0, 60)
		n.Position = UDim2.new(1, -270, 1, -80)
		n.BackgroundColor3 = Theme.Panel
		n.BackgroundTransparency = 0.1
		n.Parent = nGui
		corner(n, 8)
		stroke(n, col, 1.5)

		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(0, 4, 1, 0)
		bar.BackgroundColor3 = col
		bar.BorderSizePixel = 0
		bar.Parent = n

		local t = Instance.new("TextLabel")
		t.Size = UDim2.new(1, -16, 0, 20)
		t.Position = UDim2.new(0, 12, 0, 6)
		t.BackgroundTransparency = 1
		t.Text = title or "Rubi Hub"
		t.TextColor3 = Theme.Text
		t.Font = Enum.Font.GothamBold
		t.TextSize = 13
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.Parent = n

		local d = Instance.new("TextLabel")
		d.Size = UDim2.new(1, -16, 0, 26)
		d.Position = UDim2.new(0, 12, 0, 26)
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

	function Window:Dialog(opts)
		opts = opts or {}
		local title = opts.Title or "Confirm"
		local desc = opts.Desc or opts.Description or ""
		local buttons = opts.Buttons or {
			{ Text = "Cancel", Callback = function() end },
			{ Text = "Confirm", Callback = function() end },
		}

		local dGui = CoreGui:FindFirstChild("RubiDialog")
		if dGui then dGui:Destroy() end
		dGui = Instance.new("ScreenGui")
		dGui.Name = "RubiDialog"
		dGui.ResetOnSpawn = false
		dGui.DisplayOrder = 400
		dGui.Parent = CoreGui

		local overlay = Instance.new("Frame")
		overlay.Size = UDim2.new(1, 0, 1, 0)
		overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		overlay.BackgroundTransparency = 0.5
		overlay.Parent = dGui

		local box = Instance.new("Frame")
		box.Size = UDim2.new(0, 300, 0, 140)
		box.Position = UDim2.new(0.5, -150, 0.5, -70)
		box.BackgroundColor3 = Color3.fromRGB(22, 26, 24)
		box.Parent = overlay
		corner(box, 10)
		stroke(box, Theme.Accent, 1.5)

		local titleLbl = Instance.new("TextLabel")
		titleLbl.Size = UDim2.new(1, -20, 0, 24)
		titleLbl.Position = UDim2.new(0, 12, 0, 10)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Text = "\u{26A0}  " .. title
		titleLbl.TextColor3 = Theme.Text
		titleLbl.Font = Enum.Font.GothamBold
		titleLbl.TextSize = 14
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left
		titleLbl.Parent = box

		local descLbl = Instance.new("TextLabel")
		descLbl.Size = UDim2.new(1, -24, 0, 50)
		descLbl.Position = UDim2.new(0, 12, 0, 38)
		descLbl.BackgroundTransparency = 1
		descLbl.Text = desc
		descLbl.TextColor3 = Theme.TextDim
		descLbl.Font = Enum.Font.Gotham
		descLbl.TextSize = 11
		descLbl.TextXAlignment = Enum.TextXAlignment.Left
		descLbl.TextYAlignment = Enum.TextYAlignment.Top
		descLbl.TextWrapped = true
		descLbl.Parent = box

		local btnCount = #buttons
		for i, b in ipairs(buttons) do
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1 / btnCount, -10, 0, 30)
			btn.Position = UDim2.new((i - 1) / btnCount, 6, 1, -40)
			btn.BackgroundColor3 = (i == btnCount) and Theme.Accent or Color3.fromRGB(45, 50, 48)
			btn.Text = b.Text or "OK"
			btn.TextColor3 = Theme.Text
			btn.Font = Enum.Font.GothamBold
			btn.TextSize = 12
			btn.AutoButtonColor = false
			btn.Parent = box
			corner(btn, 6)
			btn.MouseButton1Click:Connect(function()
				dGui:Destroy()
				if b.Callback then task.spawn(b.Callback) end
			end)
		end
	end

	function Window:SetVisible(v) setMainVisible(v) end
	function Window:Destroy()
		Screen:Destroy()
		FPSGui:Destroy()
		ChiliGui:Destroy()
		for _, n in ipairs({"RubiNotify", "RubiQuickBar", "RubiDialog"}) do
			local o = CoreGui:FindFirstChild(n)
			if o then o:Destroy() end
		end
	end

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

	function Window:CreateQuickBar(barName)
		local QGui = CoreGui:FindFirstChild("RubiQuickBar")
		if not QGui then
			QGui = Instance.new("ScreenGui")
			QGui.Name = "RubiQuickBar"
			QGui.ResetOnSpawn = false
			QGui.DisplayOrder = 180
			QGui.Parent = CoreGui
		end

		local count = 0
		for _, c in ipairs(QGui:GetChildren()) do
			if c:IsA("Frame") then count = count + 1 end
		end

		local bar = Instance.new("Frame")
		bar.Name = barName or ("QuickBar" .. (count + 1))
		bar.Size = UDim2.new(0, 160, 0, 26)
		bar.Position = UDim2.new(0.55 + count * 0.12, 0, 0.02, 0)
		bar.BackgroundTransparency = 1
		bar.Parent = QGui

		local handle = Instance.new("TextButton")
		handle.Size = UDim2.new(1, 0, 0, 24)
		handle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		handle.BackgroundTransparency = 0.4
		handle.Text = ""
		handle.AutoButtonColor = false
		handle.Parent = bar
		corner(handle, 4)
		stroke(handle, Color3.fromRGB(40, 40, 40), 1)

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
		collapse.Size = UDim2.new(0, 20, 0, 20)
		collapse.Position = UDim2.new(1, -22, 0.5, -10)
		collapse.BackgroundTransparency = 1
		collapse.Text = "\u{25BC}"
		collapse.TextColor3 = Theme.Text
		collapse.Font = Enum.Font.GothamBold
		collapse.TextSize = 10
		collapse.Parent = handle

		local body = Instance.new("Frame")
		body.Size = UDim2.new(1, 10, 0, 0)
		body.Position = UDim2.new(0.5, 0, 0, 26)
		body.AnchorPoint = Vector2.new(0.5, 0)
		body.BackgroundTransparency = 1
		body.AutomaticSize = Enum.AutomaticSize.Y
		body.Parent = bar
		list(body, Enum.FillDirection.Vertical, 3)

		makeDraggable(handle, bar)
		local expanded = true
		collapse.MouseButton1Click:Connect(function()
			expanded = not expanded
			body.Visible = expanded
			collapse.Text = expanded and "\u{25BC}" or "\u{25B2}"
		end)

		local qb = { Bar = bar, Body = body }

		function qb:AddToggle(name, callback, default)
			local item = Instance.new("TextButton")
			item.Size = UDim2.new(1, 0, 0, 26)
			item.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			item.BackgroundTransparency = 0.45
			item.Text = ""
			item.AutoButtonColor = false
			item.Parent = body
			corner(item, 4)
			stroke(item, Color3.fromRGB(40, 40, 40), 1)

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

		function qb:AddSlider(name, min, max, default, callback)
			min, max, default = min or 0, max or 100, default or min
			local item = Instance.new("Frame")
			item.Size = UDim2.new(1, 0, 0, 40)
			item.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			item.BackgroundTransparency = 0.45
			item.Parent = body
			corner(item, 4)
			stroke(item, Color3.fromRGB(40, 40, 40), 1)

			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(0.6, 0, 0, 14)
			lbl.Position = UDim2.new(0, 6, 0, 2)
			lbl.BackgroundTransparency = 1
			lbl.Text = name
			lbl.TextColor3 = Theme.Text
			lbl.Font = Enum.Font.Gotham
			lbl.TextSize = 10
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Parent = item

			local valLbl = Instance.new("TextLabel")
			valLbl.Size = UDim2.new(0.35, 0, 0, 14)
			valLbl.Position = UDim2.new(0.62, 0, 0, 2)
			valLbl.BackgroundTransparency = 1
			valLbl.Text = tostring(default)
			valLbl.TextColor3 = Theme.Text
			valLbl.Font = Enum.Font.GothamBold
			valLbl.TextSize = 10
			valLbl.TextXAlignment = Enum.TextXAlignment.Right
			valLbl.Parent = item

			local barTrack = Instance.new("Frame")
			barTrack.Size = UDim2.new(1, -12, 0, 6)
			barTrack.Position = UDim2.new(0, 6, 1, -12)
			barTrack.BackgroundColor3 = Theme.SliderBg
			barTrack.Parent = item
			corner(barTrack, 3)

			local fill = Instance.new("Frame")
			fill.Size = UDim2.new(math.clamp((default - min) / math.max(max - min, 1), 0, 1), 0, 1, 0)
			fill.BackgroundColor3 = Theme.SliderFill
			fill.Parent = barTrack
			corner(fill, 3)

			local value = default
			local sliding = false
			local function update(x)
				local rel = math.clamp((x - barTrack.AbsolutePosition.X) / math.max(barTrack.AbsoluteSize.X, 1), 0, 1)
				value = math.floor(min + (max - min) * rel + 0.5)
				fill.Size = UDim2.new(rel, 0, 1, 0)
				valLbl.Text = tostring(value)
				if callback then callback(value) end
			end
			barTrack.InputBegan:Connect(function(inp)
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
			return item
		end

		return qb
	end

	return Window
end

function Rubi:GetTheme() return Theme end
function Rubi:SetTheme(key, color)
	if Theme[key] then Theme[key] = color end
end

return Rubi
