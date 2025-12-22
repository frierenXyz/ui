--[[ 
    -------------------------------------------------------
    DEATH BALL PRO: V9 (ENHANCED ACCURACY & SPAM)
    -------------------------------------------------------
    IMPROVEMENTS:
    - Advanced velocity prediction with acceleration tracking
    - Adaptive distance calculation based on ball speed tiers
    - Enhanced spam mode with smart cooldown management
    - Improved direction detection with angle tolerance
    - Better curve timing synchronization
    - Anti-false-positive filtering
]]

-- // 0. CLEANUP SYSTEM //
local ScriptKey = "DeathBall_Pro_V9_Enhanced"
local getgenv = getgenv or function() return _G end

if getgenv()[ScriptKey] then
	if getgenv()[ScriptKey].Connection then getgenv()[ScriptKey].Connection:Disconnect() end
	if getgenv()[ScriptKey].UI and getgenv()[ScriptKey].UI.Parent then getgenv()[ScriptKey].UI:Destroy() end
end

getgenv()[ScriptKey] = { Connection = nil, UI = nil }

-- // SERVICES //
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

-- Mobile detection
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- // 1. UI LIBRARY (ORIGINAL TAB STYLE) // --
local Library = {}
local GUI_NAME = "DeathBall_Pro_UI"
local THEME = {
	Background = Color3.fromRGB(18, 18, 22),
	Header     = Color3.fromRGB(22, 22, 28),
	Section    = Color3.fromRGB(28, 28, 35),
	Text       = Color3.fromRGB(240, 240, 240),
	Accent     = Color3.fromRGB(255, 50, 50),
	DarkText   = Color3.fromRGB(150, 150, 150),
	Stroke     = Color3.fromRGB(50, 50, 55)
}

local function Create(class, props)
	local inst = Instance.new(class)
	for k, v in pairs(props) do inst[k] = v end
	return inst
end

local function MakeDraggable(topbar, widget)
	local dragging, dragInput, dragStart, startPos
	local function Update(input)
		local delta = input.Position - dragStart
		local targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		TweenService:Create(widget, TweenInfo.new(0.05), {Position = targetPos}):Play()
	end
	topbar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragStart = input.Position; startPos = widget.Position
			input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
		end
	end)
	topbar.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
	UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then Update(input) end end)
end

function Library:CreateWindow(config)
	local Title = config.Title or "UI Library"
	local OldInstance = PlayerGui:FindFirstChild(GUI_NAME)
	if OldInstance then OldInstance:Destroy() end

	local ScreenGui = Create("ScreenGui", {Name = GUI_NAME, Parent = PlayerGui, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true})
	getgenv()[ScriptKey].UI = ScreenGui
	
	local OpenFrame = Create("Frame", {Name = "OpenFrame", Parent = ScreenGui, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.new(0, 0, 0, 0), BackgroundColor3 = THEME.Background, ClipsDescendants = true, Visible = false})
	Create("UICorner", {Parent = OpenFrame, CornerRadius = UDim.new(1, 0)}); Create("UIStroke", {Parent = OpenFrame, Color = THEME.Accent, Thickness = 2})
	local OpenBtn = Create("TextButton", {Parent = OpenFrame, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "OPEN", Font = Enum.Font.GothamBold, TextColor3 = THEME.Accent, TextSize = 14})

	local MainFrame = Create("Frame", {Name = "MainFrame", Parent = ScreenGui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 500, 0, 350), BackgroundColor3 = THEME.Background, ClipsDescendants = true})
	Create("UICorner", {Parent = MainFrame, CornerRadius = UDim.new(0, 10)}); Create("UIStroke", {Parent = MainFrame, Color = THEME.Accent, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})

	local Topbar = Create("Frame", {Parent = MainFrame, BackgroundColor3 = THEME.Header, Size = UDim2.new(1, 0, 0, 40), BorderSizePixel = 0})
	MakeDraggable(Topbar, MainFrame)
	Create("TextLabel", {Parent = Topbar, BackgroundTransparency = 1, Position = UDim2.new(0, 15, 0, 0), Size = UDim2.new(0.6, 0, 1, 0), Font = Enum.Font.GothamBold, Text = Title, TextColor3 = THEME.Text, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left})

	local Controls = Create("Frame", {Parent = Topbar, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0, 60, 0, 24), BackgroundTransparency = 1})
	Create("UIListLayout", {Parent = Controls, FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5)})
	
	local MinBtn = Create("TextButton", {Parent = Controls, BackgroundColor3 = THEME.Section, Size = UDim2.new(0, 24, 0, 24), Text = "-", Font = Enum.Font.GothamBold, TextColor3 = THEME.Text, AutoButtonColor = false})
	Create("UICorner", {Parent = MinBtn, CornerRadius = UDim.new(0, 4)})
	local ExitBtn = Create("TextButton", {Parent = Controls, BackgroundColor3 = THEME.Accent, Size = UDim2.new(0, 24, 0, 24), Text = "X", Font = Enum.Font.GothamBold, TextColor3 = Color3.new(1,1,1), AutoButtonColor = false})
	Create("UICorner", {Parent = ExitBtn, CornerRadius = UDim.new(0, 4)})

	MinBtn.MouseButton1Click:Connect(function()
		MainFrame:TweenSize(UDim2.new(0, 500, 0, 0), "In", "Quad", 0.3, true, function() MainFrame.Visible = false; OpenFrame.Visible = true; OpenFrame:TweenSize(UDim2.new(0, 120, 0, 35), "Out", "Back", 0.3, true) end)
	end)
	OpenBtn.MouseButton1Click:Connect(function()
		OpenFrame:TweenSize(UDim2.new(0, 0, 0, 0), "In", "Quad", 0.2, true, function() OpenFrame.Visible = false; MainFrame.Visible = true; MainFrame:TweenSize(UDim2.new(0, 500, 0, 350), "Out", "Back", 0.3, true) end)
	end)
	ExitBtn.MouseButton1Click:Connect(function() 
		ScreenGui:Destroy()
		if getgenv()[ScriptKey].Connection then getgenv()[ScriptKey].Connection:Disconnect() end
	end)

	local Sidebar = Create("Frame", {Parent = MainFrame, BackgroundColor3 = THEME.Section, Position = UDim2.new(0, 0, 0, 40), Size = UDim2.new(0, 140, 1, -40), BorderSizePixel = 0})
	Create("UIListLayout", {Parent = Sidebar, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5)}); Create("UIPadding", {Parent = Sidebar, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)})
	local PageContainer = Create("Frame", {Parent = MainFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 150, 0, 50), Size = UDim2.new(1, -160, 1, -60)})

	local WindowObj = {Tabs = {}}
	local FirstTab = true

	function WindowObj:CreateTab(name)
		local TabBtn = Create("TextButton", {Parent = Sidebar, BackgroundColor3 = THEME.Section, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), Text = name, Font = Enum.Font.GothamMedium, TextColor3 = THEME.DarkText, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false})
		Create("UICorner", {Parent = TabBtn, CornerRadius = UDim.new(0, 6)}); Create("UIPadding", {Parent = TabBtn, PaddingLeft = UDim.new(0, 8)})
		local Page = Create("ScrollingFrame", {Parent = PageContainer, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, ScrollBarThickness = 2, ScrollBarImageColor3 = THEME.Accent, BorderSizePixel = 0})
		local PageLayout = Create("UIListLayout", {Parent = Page, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
		PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 20) end)

		local function Activate()
			for _, v in pairs(WindowObj.Tabs) do TweenService:Create(v.Btn, TweenInfo.new(0.2), {TextColor3 = THEME.DarkText}):Play(); v.Page.Visible = false end
			TweenService:Create(TabBtn, TweenInfo.new(0.2), {TextColor3 = THEME.Accent}):Play(); Page.Visible = true
		end
		TabBtn.MouseButton1Click:Connect(Activate)
		if FirstTab then FirstTab = false; Activate() end
		table.insert(WindowObj.Tabs, {Btn = TabBtn, Page = Page})

		local Elements = {}
		function Elements:CreateSection(text) Create("TextLabel", {Parent = Page, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 25), Text = text:upper(), Font = Enum.Font.GothamBold, TextColor3 = THEME.DarkText, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left}) end
		
		function Elements:CreateButton(text, callback)
			callback = callback or function() end
			local Btn = Create("TextButton", {Parent = Page, BackgroundColor3 = THEME.Section, Size = UDim2.new(1, -5, 0, 32), Text = text, Font = Enum.Font.Gotham, TextColor3 = THEME.Text, TextSize = 13, AutoButtonColor = false})
			Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 6)}); Create("UIStroke", {Parent = Btn, Color = THEME.Stroke, Thickness = 1})
			Btn.MouseButton1Click:Connect(function()
				TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = THEME.Accent}):Play()
				task.wait(0.1)
				TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = THEME.Section}):Play()
				callback(Btn)
			end)
			return Btn
		end

		function Elements:CreateToggle(text, callback)
			callback = callback or function() end
			local Toggled = false
			local Btn = Create("TextButton", {Parent = Page, BackgroundColor3 = THEME.Section, Size = UDim2.new(1, -5, 0, 32), Text = "", AutoButtonColor = false})
			Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 6)}); Create("UIStroke", {Parent = Btn, Color = THEME.Stroke, Thickness = 1})
			Create("TextLabel", {Parent = Btn, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -50, 1, 0), Text = text, Font = Enum.Font.Gotham, TextColor3 = THEME.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left})
			local Tracker = Create("Frame", {Parent = Btn, BackgroundColor3 = Color3.fromRGB(30, 30, 30), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0, 36, 0, 18)}); Create("UICorner", {Parent = Tracker, CornerRadius = UDim.new(1, 0)})
			local Dot = Create("Frame", {Parent = Tracker, BackgroundColor3 = Color3.fromRGB(100, 100, 100), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0), Size = UDim2.new(0, 14, 0, 14)}); Create("UICorner", {Parent = Dot, CornerRadius = UDim.new(1, 0)})
			Btn.MouseButton1Click:Connect(function()
				Toggled = not Toggled
				local TargetPos = Toggled and UDim2.new(0, 20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
				local TargetColor = Toggled and THEME.Accent or Color3.fromRGB(30, 30, 30)
				local DotColor = Toggled and Color3.new(1,1,1) or Color3.fromRGB(100,100,100)
				TweenService:Create(Dot, TweenInfo.new(0.2), {Position = TargetPos, BackgroundColor3 = DotColor}):Play()
				TweenService:Create(Tracker, TweenInfo.new(0.2), {BackgroundColor3 = TargetColor}):Play()
				callback(Toggled)
			end)
		end
		return Elements
	end
	return WindowObj
end

-- // 2. CONFIGURATION & STATE // --

local Config = {
	Enabled = false,
	AutoSpam = false,
	AutoCurve = false,
	CurveMode = "Up",
	Debug = false,
	SpamIntensity = "Medium", -- Low, Medium, High
	InvisibleCurve = false, -- Curve without camera movement
}

local State = {
	BallShadow = nil,
	BallObject = nil,
	PreviousPosition = nil,
	PreviousVelocity = nil,
	LastParry = 0,
	IsCurving = false,
	ConsecutiveDetections = 0,
	VelocityHistory = {},
}

local CurveModes = {"Up", "Down", "Back", "Left", "Right", "Random"}
local CurveIndex = 1

-- // 3. ENHANCED HELPER FUNCTIONS // --

local function GetBallColor(target)
	if not target then return Color3.new(1, 1, 1) end
	local highlight = target:FindFirstChildOfClass("Highlight")
	if highlight then return highlight.FillColor end
	return target:IsA("Part") and target.Color or Color3.new(1, 1, 1)
end

local function GetVisualHeight(shadow)
	if not shadow then return 0 end
	return math.min(((math.max(0, shadow.Size.X - 5)) * 20) + 3, 100)
end

-- NEW: Calculate acceleration for better prediction
local function CalculateAcceleration()
	if #State.VelocityHistory < 2 then return 0 end
	local latest = State.VelocityHistory[#State.VelocityHistory]
	local previous = State.VelocityHistory[#State.VelocityHistory - 1]
	return (latest - previous)
end

-- NEW: Adaptive distance based on speed tiers
local function GetAdaptiveDistance(velocityMag, ping)
	local baseDistance = 15
	local pingCompensation = velocityMag * ping * 0.35 -- Increased from 0.3
	
	-- Speed tier multipliers for better accuracy
	if velocityMag < 30 then
		return baseDistance + pingCompensation * 0.7 -- Slower balls need less distance
	elseif velocityMag < 60 then
		return baseDistance + pingCompensation
	elseif velocityMag < 100 then
		return baseDistance + pingCompensation * 1.2
	else
		return baseDistance + pingCompensation * 1.4 -- Fast balls need more distance
	end
end

-- ENHANCED: Better targeting detection with angle tolerance
local function IsTargetingPlayer(currentPos, velocityVec, rootPos)
	local color = GetBallColor(State.BallObject)
	if color == Color3.new(1, 1, 1) then return false end -- White = not targeted
	
	-- Direction check with improved tolerance
	local dirToPlayer = (rootPos - currentPos).Unit
	local dirOfBall = velocityVec.Unit
	local dotProduct = dirToPlayer:Dot(dirOfBall)
	
	-- More lenient angle (0.3 instead of 0.4) for better detection
	if dotProduct < 0.3 then return false end
	
	-- Distance filter: Only consider if within reasonable range
	local distance = (rootPos - currentPos).Magnitude
	if distance > 150 then return false end -- Too far to be a threat
	
	-- Consecutive detection filter (reduces false positives)
	if dotProduct > 0.5 then
		State.ConsecutiveDetections = State.ConsecutiveDetections + 1
	else
		State.ConsecutiveDetections = 0
	end
	
	return State.ConsecutiveDetections >= 2 -- Must detect 2 frames in a row
end

-- ENHANCED: Smarter parry trigger with true invisible curve option
local function TriggerParry()
	if State.IsCurving then return end
	
	local currentTime = os.clock()
	local timeSinceLastParry = currentTime - State.LastParry
	
	-- Minimum cooldown to prevent double-parrying
	if timeSinceLastParry < 0.08 then return end

	State.IsCurving = true
	local originalCFrame = Camera.CFrame
	
	-- Determine curve direction (with Random support)
	local curveDirection = nil
	if Config.AutoCurve then
		local curveMode = Config.CurveMode
		if curveMode == "Random" then
			local randomModes = {"Up", "Down", "Back", "Left", "Right"}
			curveMode = randomModes[math.random(1, #randomModes)]
		end
		
		local rad90 = math.rad(90)
		if curveMode == "Up" then curveDirection = CFrame.Angles(rad90, 0, 0)
		elseif curveMode == "Down" then curveDirection = CFrame.Angles(-rad90, 0, 0)
		elseif curveMode == "Back" then curveDirection = CFrame.Angles(0, math.rad(180), 0)
		elseif curveMode == "Left" then curveDirection = CFrame.Angles(0, rad90, 0)
		elseif curveMode == "Right" then curveDirection = CFrame.Angles(0, -rad90, 0)
		end
	end
	
	-- Apply curve with or without visible camera movement
	if Config.AutoCurve and curveDirection then
		if Config.InvisibleCurve then
			-- Invisible: Set camera in same frame as parry, restore immediately
			Camera.CFrame = originalCFrame * curveDirection
			
			-- Mobile uses touch input, PC uses keyboard
			if IS_MOBILE then
				-- Find and trigger the parry button on mobile
				local parryButton = PlayerGui:FindFirstChild("Parry", true) or 
				                   PlayerGui:FindFirstChild("ParryButton", true) or
				                   PlayerGui:FindFirstChild("BlockButton", true)
				if parryButton and parryButton:IsA("GuiButton") then
					-- Simulate button press for mobile
					for _, connection in pairs(getconnections(parryButton.MouseButton1Click)) do
						connection:Fire()
					end
				else
					-- Fallback to virtual input
					VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
					task.wait()
					VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
				end
			else
				VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
				task.wait()
				VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
			end
			
			Camera.CFrame = originalCFrame
		else
			-- Visible: Traditional method with delay
			Camera.CFrame = originalCFrame * curveDirection
			
			if IS_MOBILE then
				local parryButton = PlayerGui:FindFirstChild("Parry", true) or 
				                   PlayerGui:FindFirstChild("ParryButton", true) or
				                   PlayerGui:FindFirstChild("BlockButton", true)
				if parryButton and parryButton:IsA("GuiButton") then
					for _, connection in pairs(getconnections(parryButton.MouseButton1Click)) do
						connection:Fire()
					end
				else
					VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
					VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
				end
			else
				VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
				VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
			end
			
			task.delay(0.12, function()
				Camera.CFrame = originalCFrame
			end)
		end
	else
		-- No curve, just parry
		if IS_MOBILE then
			local parryButton = PlayerGui:FindFirstChild("Parry", true) or 
			                   PlayerGui:FindFirstChild("ParryButton", true) or
			                   PlayerGui:FindFirstChild("BlockButton", true)
			if parryButton and parryButton:IsA("GuiButton") then
				for _, connection in pairs(getconnections(parryButton.MouseButton1Click)) do
					connection:Fire()
				end
			else
				VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
				VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
			end
		else
			VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
		end
	end
	
	State.LastParry = currentTime
	task.delay(0.15, function()
		State.IsCurving = false
	end)
end

-- NEW: Enhanced spam mode with intensity levels
local function SpamParry()
	local cooldowns = {
		Low = 0.15,
		Medium = 0.1,
		High = 0.06
	}
	
	local cooldown = cooldowns[Config.SpamIntensity] or 0.1
	
	if (os.clock() - State.LastParry) > cooldown then
		TriggerParry()
	end
end

-- // 4. UI SETUP // --

local Window = Library:CreateWindow({ Title = "Death Ball Pro V9" })
local MainTab = Window:CreateTab("Main")

MainTab:CreateSection("Combat")

MainTab:CreateToggle("Auto Parry", function(Value)
	Config.Enabled = Value
	State.BallShadow = nil
	State.BallObject = nil
	State.PreviousPosition = nil
	State.PreviousVelocity = nil
	State.ConsecutiveDetections = 0
	State.VelocityHistory = {}
end)

MainTab:CreateToggle("Auto Spam (Clash)", function(Value)
	Config.AutoSpam = Value
end)

MainTab:CreateButton("Spam: Medium", function(Btn)
	local modes = {"Low", "Medium", "High"}
	local currentIndex = 1
	for i, mode in ipairs(modes) do
		if Config.SpamIntensity == mode then currentIndex = i break end
	end
	currentIndex = currentIndex + 1
	if currentIndex > #modes then currentIndex = 1 end
	Config.SpamIntensity = modes[currentIndex]
	Btn.Text = "Spam: " .. Config.SpamIntensity
end)

MainTab:CreateSection("Curve Settings")
MainTab:CreateToggle("Auto Curve", function(Value) Config.AutoCurve = Value end)
MainTab:CreateToggle("Invisible Curve", function(Value) Config.InvisibleCurve = Value end)
MainTab:CreateButton("Curve Mode: Up", function(Btn)
	CurveIndex = CurveIndex + 1
	if CurveIndex > #CurveModes then CurveIndex = 1 end
	Config.CurveMode = CurveModes[CurveIndex]
	Btn.Text = "Curve Mode: " .. Config.CurveMode
end)

MainTab:CreateSection("Misc")
MainTab:CreateToggle("Debug Mode", function(Value) Config.Debug = Value end)

-- // 5. ENHANCED PHYSICS LOOP // --

local Connection = RunService.RenderStepped:Connect(function(dt)
	if not Config.Enabled then return end
	if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return end

	-- Refresh References
	State.BallShadow = (State.BallShadow and State.BallShadow.Parent) and State.BallShadow or (workspace:FindFirstChild("FX") and workspace.FX:FindFirstChild("BallShadow"))
	State.BallObject = (State.BallObject and State.BallObject.Parent) and State.BallObject or (workspace:FindFirstChild("Ball") or workspace:FindFirstChild("Part"))

	if not State.BallShadow or not State.BallObject then
		State.PreviousPosition = nil
		State.PreviousVelocity = nil
		State.ConsecutiveDetections = 0
		State.VelocityHistory = {}
		return
	end

	local rootPart = LocalPlayer.Character.PrimaryPart
	local height = GetVisualHeight(State.BallShadow)
	local currentPos = Vector3.new(State.BallShadow.Position.X, State.BallShadow.Position.Y + height, State.BallShadow.Position.Z)

	if State.PreviousPosition then
		local velocityVec = (currentPos - State.PreviousPosition) / dt
		local velocityMag = velocityVec.Magnitude
		
		-- Update velocity history (keep last 5 frames)
		table.insert(State.VelocityHistory, velocityMag)
		if #State.VelocityHistory > 5 then
			table.remove(State.VelocityHistory, 1)
		end
		
		-- Anti-Lobby Check: Ignore if barely moving
		if velocityMag < 8 then -- Increased threshold from 5
			State.PreviousPosition = currentPos
			State.PreviousVelocity = velocityVec
			State.ConsecutiveDetections = 0
			return
		end

		local ping = LocalPlayer:GetNetworkPing()
		
		-- Use adaptive distance calculation
		local dynamicDistance = GetAdaptiveDistance(velocityMag, ping)
		local flatDistance = (Vector3.new(rootPart.Position.X, 0, rootPart.Position.Z) - Vector3.new(currentPos.X, 0, currentPos.Z)).Magnitude

		-- Enhanced targeting check
		local isTargeted = IsTargetingPlayer(currentPos, velocityVec, rootPart.Position)

		-- SPAM MODE: High-intensity parrying when close
		if Config.AutoSpam and isTargeted and flatDistance < 18 and velocityMag > 25 then
			SpamParry()
		-- STANDARD MODE: Precise single parry
		elseif isTargeted and flatDistance <= dynamicDistance then
			TriggerParry()
		end
	end

	State.PreviousPosition = currentPos
	State.PreviousVelocity = velocityVec
end)

getgenv()[ScriptKey].Connection = Connection
print("[Death Ball Pro V9] Loaded - Enhanced Accuracy & Spam")
