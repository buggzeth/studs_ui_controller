local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

local TWEEN_WINDOW_OPEN = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TWEEN_WINDOW_CLOSE = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local TWEEN_BTN_DOWN = TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_BTN_UP   = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local TWEEN_SLIDER   = TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local SOUND_CLICK = "rbxassetid://72826565018765"
local SOUND_OPEN  = "rbxassetid://139731037802687"
local SOUND_CLOSE = "rbxassetid://72826565018765"

local function playSound(soundId: string)
	if soundId == "" then return end
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = 0.4
	sound.Parent = PlayerGui
	sound.PlayOnRemove = true
	sound:Destroy()
end




type WindowData = {
	ScaleObj: UIScale,
	BaseWidth: number,
	BaseHeight: number,
	BaseTrans: number,
	Open: boolean,
	IsOpening: boolean,
}

local managedWindows: { [CanvasGroup]: WindowData } = {}

local function getResponsiveFactor(baseWidth: number, baseHeight: number): number
	local viewport = Camera.ViewportSize
	local scaleX = (viewport.X * 0.94) / baseWidth
	local scaleY = (viewport.Y * 0.88) / baseHeight
	return math.clamp(math.min(scaleX, scaleY, 1.0), 0.35, 1.0)
end




local function openWindow(window: CanvasGroup)
	local data = managedWindows[window]
	if not data or data.IsOpening or data.Open then return end
	data.IsOpening = true


	local parentGui = window:FindFirstAncestorWhichIsA("ScreenGui")
	if parentGui then
		parentGui.Enabled = true
	end

	local targetScale = getResponsiveFactor(data.BaseWidth, data.BaseHeight)
	data.ScaleObj.Scale = targetScale * 0.75
	window.GroupTransparency = 1
	window.Visible = true

	playSound(SOUND_OPEN)

	local t1 = TweenService:Create(data.ScaleObj, TWEEN_WINDOW_OPEN, { Scale = targetScale })
	local t2 = TweenService:Create(window, TWEEN_WINDOW_OPEN, { GroupTransparency = data.BaseTrans })
	t1:Play()
	t2:Play()

	data.Open = true
	window:SetAttribute("Open", true)
	data.IsOpening = false
end

local function closeWindow(window: CanvasGroup)
	local data = managedWindows[window]
	if not data or not data.Open then return end

	playSound(SOUND_CLOSE)

	local t1 = TweenService:Create(data.ScaleObj, TWEEN_WINDOW_CLOSE, { Scale = data.ScaleObj.Scale * 0.8 })
	local t2 = TweenService:Create(window, TWEEN_WINDOW_CLOSE, { GroupTransparency = 1 })
	t1:Play()
	t2:Play()

	t2.Completed:Once(function()
		window.Visible = false
		data.Open = false
		window:SetAttribute("Open", false)
	end)
end

local function toggleWindow(window: CanvasGroup)
	local data = managedWindows[window]
	if not data then return end

	if data.Open then
		closeWindow(window)
	else

		for otherWin, otherData in pairs(managedWindows) do
			if otherWin ~= window and otherData.Open then
				closeWindow(otherWin)
			end
		end
		openWindow(window)
	end
end




local function initWindow(window: CanvasGroup)
	if managedWindows[window] then return end

	local windowScale = window:WaitForChild("WindowScale", 3) :: UIScale?
	if not windowScale then
		warn("[UIAnimationManager] Missing WindowScale inside window:", window.Name)
		return
	end

	local parentGui = window:FindFirstAncestorWhichIsA("ScreenGui")
	if parentGui then
		parentGui.Enabled = true
	end

	local baseWidth = window.Size.X.Offset > 0 and window.Size.X.Offset or 500
	local baseHeight = window.Size.Y.Offset > 0 and window.Size.Y.Offset or 360
	local baseTrans = window.GroupTransparency


	window.Visible = false
	window.GroupTransparency = 1

	managedWindows[window] = {
		ScaleObj = windowScale,
		BaseWidth = baseWidth,
		BaseHeight = baseHeight,
		BaseTrans = baseTrans,
		Open = false,
		IsOpening = false,
	}

	window:SetAttribute("Open", false)


	local closeBtn = window:FindFirstChild("CloseButton", true)
	if closeBtn and closeBtn:IsA("GuiButton") then
		closeBtn.Activated:Connect(function()
			closeWindow(window)
		end)
	end
end




local KEYWORD_MAPPINGS = {
	{ key = "shop",     gui = "ShopGui",         win = "ShopWindow" },
	{ key = "daily",    gui = "DailyRewardsGui", win = "DailyRewardsWindow" },
	{ key = "time",     gui = "TimeRewardsGui",  win = "TimeRewardsWindow" },
	{ key = "codes",    gui = "CodesGui",        win = "CodesWindow" },
	{ key = "reward",   gui = "RewardsGui",      win = "RewardsWindow" },
	{ key = "spin",     gui = "LuckyWheelGui",   win = "LuckyWheelWindow" },
	{ key = "wheel",    gui = "LuckyWheelGui",   win = "LuckyWheelWindow" },
	{ key = "setting",  gui = "SettingsGui",     win = "SettingsWindow" },
}

local function resolveTargetWindow(button: GuiButton): CanvasGroup?

	local targetAttr = button:GetAttribute("TargetGui")
	if targetAttr and typeof(targetAttr) == "string" then
		local gui = PlayerGui:FindFirstChild(targetAttr) or PlayerGui:WaitForChild(targetAttr, 2)
		if gui and gui:IsA("ScreenGui") then
			gui.Enabled = true
			local win = gui:FindFirstChildWhichIsA("CanvasGroup", true)
			if win then return win end
		end
	end


	local lowerName = button.Name:lower()
	for _, map in ipairs(KEYWORD_MAPPINGS) do
		if lowerName:find(map.key) then
			local gui = PlayerGui:FindFirstChild(map.gui) or PlayerGui:WaitForChild(map.gui, 2)
			if gui and gui:IsA("ScreenGui") then
				gui.Enabled = true
				local win = gui:FindFirstChild(map.win, true) :: CanvasGroup?
				if not win then
					win = gui:FindFirstChildWhichIsA("CanvasGroup", true)
				end
				if win then return win end
			end
		end
	end

	return nil
end




local isSpinning = false

local function hookWheelSpin(spinBtn: GuiButton)
	spinBtn.Activated:Connect(function()
		if isSpinning then return end

		local window = spinBtn:FindFirstAncestor("LuckyWheelWindow")
		if not window then return end

		local spinner = window:FindFirstChild("WheelSpinner", true) :: CanvasGroup?
		if not spinner then return end

		isSpinning = true


		local winningSlice = math.random(1, 5)
		local sliceCenter = (winningSlice - 1) * 72 + 36
		local fullRotations = 360 * math.random(4, 6)
		local targetAngle = fullRotations + (360 - sliceCenter)

		local spinTweenInfo = TweenInfo.new(3.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
		local spinTween = TweenService:Create(spinner, spinTweenInfo, { Rotation = targetAngle })

		playSound(SOUND_OPEN)
		spinTween:Play()

		spinTween.Completed:Once(function()
			spinner.Rotation = (360 - sliceCenter) % 360
			isSpinning = false
			playSound(SOUND_CLICK)
		end)
	end)
end




local hookedButtons = {}

local function hookButton(button: GuiButton)
	if hookedButtons[button] then return end
	hookedButtons[button] = true

	button.Active = true


	local buttonScale = button:FindFirstChild("ButtonScale") :: UIScale?
	if not buttonScale then
		buttonScale = Instance.new("UIScale")
		buttonScale.Name = "ButtonScale"
		buttonScale.Scale = 1
		buttonScale.Parent = button
	end


	button.MouseButton1Down:Connect(function()
		playSound(SOUND_CLICK)
		TweenService:Create(buttonScale, TWEEN_BTN_DOWN, { Scale = 0.92 }):Play()
	end)

	button.MouseButton1Up:Connect(function()
		TweenService:Create(buttonScale, TWEEN_BTN_UP, { Scale = 1.0 }):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(buttonScale, TWEEN_BTN_UP, { Scale = 1.0 }):Play()
	end)


	if button.Name == "SpinButton" or string.find(button.Name, "Mult") then
		hookWheelSpin(button)
		return
	end


	button.Activated:Connect(function()
		local win = resolveTargetWindow(button)
		if win then
			if not managedWindows[win] then
				initWindow(win)
			end
			toggleWindow(win)
		end
	end)
end


local function hookClaimButton(claimBtn: GuiButton)
	claimBtn.Activated:Connect(function()
		claimBtn:SetAttribute("Claimed", true)
		local label = claimBtn:FindFirstChildWhichIsA("TextLabel", true)
		if label then
			label.Text = "CLAIMED!"
		end
	end)
end




local activeSlider: { Track: Frame, Anchor: Frame, Row: Instance }? = nil

local function hookSlider(row: Instance)
	local track = row:FindFirstChild("SliderTrack") :: Frame?
	if not track then return end
	local anchor = track:FindFirstChild("SliderAnchor") :: Frame?
	if not anchor then return end

	local function updateSlider(mouseX: number)
		local absX = track.AbsolutePosition.X
		local absW = track.AbsoluteSize.X
		if absW <= 0 then return end

		local percent = math.clamp((mouseX - absX) / absW, 0, 1)
		TweenService:Create(anchor, TWEEN_SLIDER, {
			Position = UDim2.new(percent, 0, 0.5, 0)
		}):Play()

		row:SetAttribute("Value", percent)
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			activeSlider = { Track = track, Anchor = anchor, Row = row }
			updateSlider(input.Position.X)
		end
	end)

	anchor.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			activeSlider = { Track = track, Anchor = anchor, Row = row }
		end
	end)
end

UserInputService.InputChanged:Connect(function(input)
	if not activeSlider then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		local absX = activeSlider.Track.AbsolutePosition.X
		local absW = activeSlider.Track.AbsoluteSize.X
		if absW > 0 then
			local percent = math.clamp((input.Position.X - absX) / absW, 0, 1)
			TweenService:Create(activeSlider.Anchor, TWEEN_SLIDER, {
				Position = UDim2.new(percent, 0, 0.5, 0)
			}):Play()
			activeSlider.Row:SetAttribute("Value", percent)
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		activeSlider = nil
	end
end)

local function updateHudScale()
	local hudGui = PlayerGui:FindFirstChild("HudGui")
	if not hudGui then return end

	local viewport = Camera.ViewportSize
	local leftHud = hudGui:FindFirstChild("LeftHud")
	local rightHud = hudGui:FindFirstChild("RightHud")
	local cashDisplay = hudGui:FindFirstChild("CashDisplay")

	-- RightHud design height is 390px; ensure it fits within 90% of screen height
	if rightHud then
		local rightScale = rightHud:FindFirstChild("HudScale") :: UIScale?
		if rightScale then
			rightScale.Scale = math.clamp((viewport.Y * 0.90) / 390, 0.45, 1.0)
		end
	end

	-- LeftHud design height is 318px
	if leftHud then
		local leftScale = leftHud:FindFirstChild("HudScale") :: UIScale?
		if leftScale then
			leftScale.Scale = math.clamp((viewport.Y * 0.90) / 318, 0.45, 1.0)
		end
	end

	-- CashDisplay matches LeftHud scale so icon and text match
	if cashDisplay then
		local cashScale = cashDisplay:FindFirstChild("HudScale") :: UIScale?
		if cashScale then
			cashScale.Scale = math.clamp((viewport.Y * 0.90) / 318, 0.55, 1.0)
		end
	end
end

local activeSpotlights = {}

local function startAmbientSpotlight(spotlight: ImageLabel)
	if activeSpotlights[spotlight] then return end
	activeSpotlights[spotlight] = true

	local isCore = string.find(spotlight.Name, "Core") ~= nil
	local duration = isCore and 14 or 26
	local targetRotation = isCore and -360 or 360

	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false)
	local tween = TweenService:Create(spotlight, tweenInfo, { Rotation = targetRotation })
	tween:Play()
end


local function processInstance(inst: Instance)
	if inst:IsA("CanvasGroup") and string.find(inst.Name, "Window") then
		initWindow(inst)
	end

	if inst:IsA("GuiButton") then
		hookButton(inst)
		if inst.Name == "ClaimButton" or inst.Name == "ClaimButtonPill" then
			hookClaimButton(inst)
		end
	end

	if inst:IsA("CanvasGroup") and (inst.Name == "Music_Row" or inst.Name == "SFX_Row") then
		hookSlider(inst)
	end

	if inst:IsA("ImageLabel") and string.find(inst.Name, "RadialSpotlight") then
		startAmbientSpotlight(inst)
	end
end

local function scanAndHook(root: Instance)
	processInstance(root)
	for _, descendant in ipairs(root:GetDescendants()) do
		processInstance(descendant)
	end
end


scanAndHook(PlayerGui)


PlayerGui.DescendantAdded:Connect(function(descendant)
	task.defer(function()
		scanAndHook(descendant)
	end)
end)

task.defer(updateHudScale)
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateHudScale)

Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	for _, data in pairs(managedWindows) do
		if data.Open then
			local targetScale = getResponsiveFactor(data.BaseWidth, data.BaseHeight)
			TweenService:Create(data.ScaleObj, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Scale = targetScale
			}):Play()
		end
	end
end)
