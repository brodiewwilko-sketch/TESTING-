if game.PlaceId ~= 13822889 then
    warn("LT2 Utility Hub: this script is for Lumber Tycoon 2 only.")
    return
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local function getGuiParent()
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        or LocalPlayer:WaitForChild("PlayerGui", 10)
    if playerGui then return playerGui end
    if typeof(gethui) == "function" then
        local ok, result = pcall(gethui)
        if ok and result then return result end
    end
    error("LT2 Hub: PlayerGui and executor UI parent are unavailable.")
end

local GuiParent = getGuiParent()
local Existing = GuiParent:FindFirstChild("LT2UtilityHub")
if Existing then Existing:Destroy() end

local ScreenGui
local restoreCamera
local flyToggleSetter
local unloadHub

local State = {
    runningTree = false,
    stopTree = false,
    runningBlueprints = false,
    stopBlueprints = false,
    fly = false,
    noclip = false,
    infiniteJump = false,
    walkSpeed = 16,
    jumpPower = 50,
    flySpeed = 75,
    treeClass = "Generic",
    treeAmount = 1,
    guiKey = Enum.KeyCode.RightShift,
    flyKey = Enum.KeyCode.Q,
    savedCFrame = nil,
    cameraSaved = nil,
    oldCollisions = {},
    oldFog = nil,
    alwaysNight = false,
    noShadows = false,
    fullBright = false,
    rgbEnabled = true,
    rgbSpeed = 55,
    closed = false,
}

local function notify(title, message, duration)
    if State.closed then return end
    duration = duration or 4
    local toast = Instance.new("Frame")
    toast.Name = "Toast"
    toast.AnchorPoint = Vector2.new(1, 1)
    toast.Position = UDim2.new(1, -18, 1, 90)
    toast.Size = UDim2.new(0, 310, 0, 70)
    toast.BackgroundColor3 = Color3.fromRGB(20, 23, 31)
    toast.BorderSizePixel = 0
    toast.Parent = ScreenGui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = toast
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(90, 120, 255)
    stroke.Thickness = 1.2
    stroke.Parent = toast
    local heading = Instance.new("TextLabel")
    heading.BackgroundTransparency = 1
    heading.Position = UDim2.new(0, 12, 0, 7)
    heading.Size = UDim2.new(1, -24, 0, 22)
    heading.Font = Enum.Font.GothamBold
    heading.Text = title
    heading.TextColor3 = Color3.fromRGB(245, 247, 255)
    heading.TextSize = 14
    heading.TextXAlignment = Enum.TextXAlignment.Left
    heading.Parent = toast
    local body = Instance.new("TextLabel")
    body.BackgroundTransparency = 1
    body.Position = UDim2.new(0, 12, 0, 30)
    body.Size = UDim2.new(1, -24, 0, 32)
    body.Font = Enum.Font.Gotham
    body.Text = message
    body.TextColor3 = Color3.fromRGB(185, 192, 208)
    body.TextSize = 12
    body.TextWrapped = true
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.Parent = toast
    TweenService:Create(toast, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -18, 1, -18)
    }):Play()
    task.delay(duration, function()
        if toast and toast.Parent then
            TweenService:Create(toast, TweenInfo.new(0.2), {
                Position = UDim2.new(1, -18, 1, 90), BackgroundTransparency = 1
            }):Play()
            task.wait(0.22)
            if toast then toast:Destroy() end
        end
    end)
end

local function safeCall(label, callback)
    local ok, result = xpcall(callback, function(err)
        return debug.traceback(tostring(err), 2)
    end)
    if not ok then
        warn("[LT2 Utility] " .. label .. ": " .. tostring(result))
        notify(label .. " failed", tostring(result):sub(1, 180), 6)
        return false, result
    end
    return true, result
end

local function getCharacter()
    local character = LocalPlayer.Character
    if not character then return nil, nil, nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then return nil, nil, nil end
    return character, humanoid, root
end

local function setCharacterCFrame(cf)
    local character, humanoid, root = getCharacter()
    if not root then
        notify("Teleport failed", "Your character has not loaded yet.")
        return false
    end
    if State.cameraSaved then restoreCamera() end
    pcall(function() LocalPlayer:RequestStreamAroundAsync(cf.Position) end)
    character:PivotTo(cf)
    return true
end

--// UI ------------------------------------------------------------------------
ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LT2UtilityHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999999
ScreenGui.Enabled = true
ScreenGui.Parent = GuiParent

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
Main.Size = UDim2.new(0, 760, 0, 500)
Main.BackgroundColor3 = Color3.fromRGB(14, 16, 23)
Main.BorderSizePixel = 0
Main.Active = true
Main.ZIndex = 1
Main.Parent = ScreenGui
local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 13)
MainCorner.Parent = Main
local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1.7
MainStroke.Color = Color3.fromRGB(130, 130, 255)
MainStroke.Parent = Main
local MainStrokeGradient = Instance.new("UIGradient")
MainStrokeGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 55, 135)),
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 185, 65)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(70, 235, 190)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(75, 130, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(195, 75, 255)),
})
MainStrokeGradient.Rotation = 25
MainStrokeGradient.Parent = MainStroke

local Top = Instance.new("Frame")
Top.Name = "TopBar"
Top.Size = UDim2.new(1, 0, 0, 54)
Top.BackgroundColor3 = Color3.fromRGB(19, 22, 32)
Top.BorderSizePixel = 0
Top.Active = true
Top.ZIndex = 10
Top.Parent = Main
local TopGradient = Instance.new("UIGradient")
TopGradient.Color = ColorSequence.new(Color3.fromRGB(25, 29, 45), Color3.fromRGB(17, 19, 30))
TopGradient.Rotation = 90
TopGradient.Parent = Top
local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 13)
TopCorner.Parent = Top
local TopCover = Instance.new("Frame")
TopCover.Position = UDim2.new(0, 0, 1, -13)
TopCover.Size = UDim2.new(1, 0, 0, 13)
TopCover.BackgroundColor3 = Top.BackgroundColor3
TopCover.BorderSizePixel = 0
TopCover.Parent = Top

local Accent = Instance.new("Frame")
Accent.Position = UDim2.new(0, 0, 1, -3)
Accent.Size = UDim2.new(1, 0, 0, 3)
Accent.BorderSizePixel = 0
Accent.Parent = Top
local AccentGradient = Instance.new("UIGradient")
AccentGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 120)),
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 190, 60)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 235, 180)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(70, 120, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 70, 255)),
})
AccentGradient.Parent = Accent

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 20, 0, 7)
Title.Size = UDim2.new(0, 250, 0, 24)
Title.Font = Enum.Font.GothamBold
Title.Text = "LT2  /  UTILITY HUB"
Title.TextColor3 = Color3.fromRGB(245, 247, 255)
Title.TextSize = 17
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Top
local Subtitle = Instance.new("TextLabel")
Subtitle.BackgroundTransparency = 1
Subtitle.Position = UDim2.new(0, 21, 0, 30)
Subtitle.Size = UDim2.new(0, 300, 0, 16)
Subtitle.Font = Enum.Font.Gotham
Subtitle.Text = "WOOD • MOVEMENT • LOCATIONS • TOOLS"
Subtitle.TextColor3 = Color3.fromRGB(126, 137, 161)
Subtitle.TextSize = 9
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Top

local Minimize = Instance.new("TextButton")
Minimize.AnchorPoint = Vector2.new(1, 0.5)
Minimize.Position = UDim2.new(1, -16, 0.5, 0)
Minimize.Size = UDim2.new(0, 30, 0, 28)
Minimize.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
Minimize.BorderSizePixel = 0
Minimize.Text = "—"
Minimize.Font = Enum.Font.GothamBold
Minimize.TextSize = 16
Minimize.TextColor3 = Color3.fromRGB(230, 233, 243)
Minimize.Parent = Top
Minimize.ZIndex = 30
Minimize.Active = true
Minimize.Selectable = true
Instance.new("UICorner", Minimize).CornerRadius = UDim.new(0, 7)

local Close = Instance.new("TextButton")
Close.AnchorPoint = Vector2.new(1, 0.5)
Close.Position = UDim2.new(1, -54, 0.5, 0)
Close.Size = UDim2.new(0, 30, 0, 28)
Close.BackgroundColor3 = Color3.fromRGB(75, 35, 48)
Close.BorderSizePixel = 0
Close.Text = "×"
Close.Font = Enum.Font.GothamBold
Close.TextSize = 19
Close.TextColor3 = Color3.fromRGB(255, 220, 227)
Close.Parent = Top
Close.ZIndex = 30
Close.Active = true
Close.Selectable = true
Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 7)

local Sidebar = Instance.new("Frame")
Sidebar.Position = UDim2.new(0, 0, 0, 54)
Sidebar.Size = UDim2.new(0, 155, 1, -54)
Sidebar.BackgroundColor3 = Color3.fromRGB(17, 20, 29)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main
Sidebar.ZIndex = 5
Sidebar.ClipsDescendants = true
local SideLayout = Instance.new("UIListLayout")
SideLayout.Padding = UDim.new(0, 5)
SideLayout.SortOrder = Enum.SortOrder.LayoutOrder
SideLayout.Parent = Sidebar
local SidePadding = Instance.new("UIPadding")
SidePadding.PaddingTop = UDim.new(0, 12)
SidePadding.PaddingLeft = UDim.new(0, 9)
SidePadding.PaddingRight = UDim.new(0, 9)
SidePadding.Parent = Sidebar

local Content = Instance.new("Frame")
Content.Position = UDim2.new(0, 155, 0, 54)
Content.Size = UDim2.new(1, -155, 1, -54)
Content.BackgroundTransparency = 1
Content.Parent = Main
Content.ZIndex = 2

local Pages, TabButtons = {}, {}
local ActiveTab = nil
local TabCount = 0

local function createPage(name)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = name .. "Page"
    scroll.Position = UDim2.new(0, 0, 0, 0)
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Color3.fromRGB(85, 105, 155)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Active = true
    scroll.ZIndex = 3
    scroll.Visible = false
    scroll.Parent = Content
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 9)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 17)
    padding.PaddingLeft = UDim.new(0, 18)
    padding.PaddingRight = UDim.new(0, 18)
    padding.PaddingBottom = UDim.new(0, 18)
    padding.Parent = scroll
    Pages[name] = scroll
    local tab = Instance.new("TextButton")
    tab.Name = name .. "Tab"
    tab.Size = UDim2.new(1, 0, 0, 34)
    tab.BackgroundColor3 = Color3.fromRGB(24, 28, 39)
    tab.BorderSizePixel = 0
    tab.AutoButtonColor = false
    tab.Text = name
    tab.Font = Enum.Font.GothamSemibold
    tab.TextSize = 12
    tab.TextColor3 = Color3.fromRGB(160, 169, 188)
    tab.Parent = Sidebar
    tab.Visible = true
    tab.Active = true
    tab.Selectable = true
    tab.ZIndex = 12
    TabCount = TabCount + 1
    tab.LayoutOrder = TabCount
    Instance.new("UICorner", tab).CornerRadius = UDim.new(0, 8)
    local tabStroke = Instance.new("UIStroke")
    tabStroke.Color = Color3.fromRGB(56, 64, 91)
    tabStroke.Transparency = 0.55
    tabStroke.Thickness = 1
    tabStroke.Parent = tab
    TabButtons[name] = tab

    local function selectThisPage()
        for pageName, page in pairs(Pages) do
            page.Visible = (pageName == name)
            local button = TabButtons[pageName]
            if button then
                button.BackgroundColor3 = (pageName == name) and Color3.fromRGB(46, 56, 83) or Color3.fromRGB(24, 28, 39)
                button.TextColor3 = (pageName == name) and Color3.fromRGB(245, 247, 255) or Color3.fromRGB(160, 169, 188)
            end
        end
        ActiveTab = name
    end

    tab.Activated:Connect(selectThisPage)
    if not ActiveTab then selectThisPage() end
    return scroll
end

local function addHeader(page, text)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -4, 0, 24)
    label.Font = Enum.Font.GothamBold
    label.Text = text:upper()
    label.TextColor3 = Color3.fromRGB(116, 150, 255)
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = page
    return label
end

local function addInfo(page, text, height)
    local label = Instance.new("TextLabel")
    label.BackgroundColor3 = Color3.fromRGB(22, 26, 37)
    label.BorderSizePixel = 0
    label.Size = UDim2.new(1, -4, 0, height or 48)
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = Color3.fromRGB(172, 181, 201)
    label.TextSize = 11
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = page
    Instance.new("UICorner", label).CornerRadius = UDim.new(0, 8)
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 12)
    pad.PaddingRight = UDim.new(0, 12)
    pad.PaddingTop = UDim.new(0, 7)
    pad.PaddingBottom = UDim.new(0, 7)
    pad.Parent = label
    return label
end

local function addButton(page, text, description, callback, accentColor)
    local button = Instance.new("TextButton")
    button.AutoButtonColor = false
    button.BackgroundColor3 = Color3.fromRGB(24, 28, 39)
    button.BorderSizePixel = 0
    button.Size = UDim2.new(1, -4, 0, description and 58 or 42)
    button.Text = ""
    button.Parent = page
    button.Active = true
    button.Selectable = true
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
    local buttonStroke = Instance.new("UIStroke")
    buttonStroke.Color = accentColor or Color3.fromRGB(84, 110, 210)
    buttonStroke.Transparency = 0.72
    buttonStroke.Thickness = 1
    buttonStroke.Parent = button
    local line = Instance.new("Frame")
    line.Size = UDim2.new(0, 3, 1, -14)
    line.Position = UDim2.new(0, 0, 0, 7)
    line.BackgroundColor3 = accentColor or Color3.fromRGB(90, 122, 245)
    line.BorderSizePixel = 0
    line.Parent = button
    local lineGradient = Instance.new("UIGradient")
    lineGradient.Color = AccentGradient.Color
    lineGradient.Rotation = 90
    lineGradient.Parent = line
    Instance.new("UICorner", line).CornerRadius = UDim.new(1, 0)
    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 13, 0, description and 8 or 0)
    title.Size = UDim2.new(1, -25, 0, description and 20 or 42)
    title.Font = Enum.Font.GothamSemibold
    title.Text = text
    title.TextColor3 = Color3.fromRGB(235, 239, 250)
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextYAlignment = description and Enum.TextYAlignment.Center or Enum.TextYAlignment.Center
    title.Parent = button
    if description then
        local desc = Instance.new("TextLabel")
        desc.BackgroundTransparency = 1
        desc.Position = UDim2.new(0, 13, 0, 29)
        desc.Size = UDim2.new(1, -25, 0, 19)
        desc.Font = Enum.Font.Gotham
        desc.Text = description
        desc.TextColor3 = Color3.fromRGB(137, 147, 169)
        desc.TextSize = 10
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.Parent = button
    end
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(34, 40, 56)}):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.16), {BackgroundColor3 = Color3.fromRGB(24, 28, 39)}):Play()
    end)
    button.Activated:Connect(function()
        if callback then
            task.spawn(function()
                safeCall(text, callback)
            end)
        end
    end)
    return button
end

local function addStepper(page, titleText, initial, minimum, maximum, onChange)
    local value = initial
    local row = Instance.new("Frame")
    row.BackgroundColor3 = Color3.fromRGB(22, 26, 37)
    row.BorderSizePixel = 0
    row.Size = UDim2.new(1, -4, 0, 52)
    row.Parent = page
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 12, 0, 0)
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Font = Enum.Font.GothamSemibold
    label.Text = titleText
    label.TextColor3 = Color3.fromRGB(224, 230, 245)
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    local valueLabel = Instance.new("TextLabel")
    valueLabel.BackgroundTransparency = 1
    valueLabel.Position = UDim2.new(0.57, 0, 0, 0)
    valueLabel.Size = UDim2.new(0, 54, 1, 0)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Text = tostring(value)
    valueLabel.TextColor3 = Color3.fromRGB(124, 158, 255)
    valueLabel.TextSize = 12
    valueLabel.Parent = row
    local function makeStep(symbol, x, delta)
        local b = Instance.new("TextButton")
        b.Position = UDim2.new(1, x, 0.5, -13)
        b.Size = UDim2.new(0, 27, 0, 26)
        b.BackgroundColor3 = Color3.fromRGB(48, 58, 88)
        b.BorderSizePixel = 0
        b.Font = Enum.Font.GothamBold
        b.Text = symbol
        b.TextSize = 15
        b.TextColor3 = Color3.fromRGB(240, 243, 255)
        b.Parent = row
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        b.Activated:Connect(function()
            value = math.clamp(value + delta, minimum, maximum)
            valueLabel.Text = tostring(value)
            if onChange then onChange(value) end
        end)
    end
    makeStep("−", -62, -1)
    makeStep("+", -31, 1)
    if onChange then onChange(value) end
    return function() return value end
end

local function addToggle(page, titleText, initial, callback, description)
    local row = Instance.new("Frame")
    row.BackgroundColor3 = Color3.fromRGB(22, 26, 37)
    row.BorderSizePixel = 0
    row.Size = UDim2.new(1, -4, 0, description and 58 or 46)
    row.Parent = page
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 12, 0, description and 7 or 0)
    title.Size = UDim2.new(1, -80, 0, description and 20 or 46)
    title.Font = Enum.Font.GothamSemibold
    title.Text = titleText
    title.TextColor3 = Color3.fromRGB(224, 230, 245)
    title.TextSize = 11
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = row
    if description then
        local desc = Instance.new("TextLabel")
        desc.BackgroundTransparency = 1
        desc.Position = UDim2.new(0, 12, 0, 29)
        desc.Size = UDim2.new(1, -80, 0, 18)
        desc.Font = Enum.Font.Gotham
        desc.Text = description
        desc.TextColor3 = Color3.fromRGB(137, 147, 169)
        desc.TextSize = 10
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.Parent = row
    end
    local toggle = Instance.new("TextButton")
    toggle.AnchorPoint = Vector2.new(1, 0.5)
    toggle.Position = UDim2.new(1, -12, 0.5, 0)
    toggle.Size = UDim2.new(0, 42, 0, 23)
    toggle.BorderSizePixel = 0
    toggle.Parent = row
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 17, 0, 17)
    knob.Position = UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(245, 247, 255)
    knob.BorderSizePixel = 0
    knob.Parent = toggle
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local enabled = initial and true or false
    local function render()
        toggle.BackgroundColor3 = enabled and Color3.fromRGB(76, 112, 242) or Color3.fromRGB(59, 65, 80)
        knob.Position = enabled and UDim2.new(1, -20, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    end
    local function setEnabled(value, fireCallback)
        enabled = value and true or false
        render()
        if fireCallback and callback then callback(enabled) end
    end
    render()
    toggle.Activated:Connect(function()
        setEnabled(not enabled, true)
    end)
    return function() return enabled end, function(value, fireCallback) setEnabled(value, fireCallback ~= false) end
end

local function addSelector(page, titleText, options, defaultValue, onChange)
    local index = 1
    for i, value in ipairs(options) do
        if value == defaultValue then index = i break end
    end
    local row = Instance.new("Frame")
    row.BackgroundColor3 = Color3.fromRGB(22, 26, 37)
    row.BorderSizePixel = 0
    row.Size = UDim2.new(1, -4, 0, 58)
    row.Parent = page
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 12, 0, 5)
    label.Size = UDim2.new(1, -24, 0, 17)
    label.Font = Enum.Font.GothamSemibold
    label.Text = titleText
    label.TextColor3 = Color3.fromRGB(224, 230, 245)
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    local valueLabel = Instance.new("TextLabel")
    valueLabel.BackgroundTransparency = 1
    valueLabel.Position = UDim2.new(0, 12, 0, 27)
    valueLabel.Size = UDim2.new(1, -80, 0, 20)
    valueLabel.Font = Enum.Font.Gotham
    valueLabel.Text = options[index]
    valueLabel.TextColor3 = Color3.fromRGB(128, 159, 255)
    valueLabel.TextSize = 11
    valueLabel.TextXAlignment = Enum.TextXAlignment.Left
    valueLabel.Parent = row
    local function change(delta)
        index = ((index - 1 + delta) % #options) + 1
        valueLabel.Text = options[index]
        if onChange then onChange(options[index]) end
    end
    for i, text in ipairs({"‹", "›"}) do
        local b = Instance.new("TextButton")
        b.AnchorPoint = Vector2.new(1, 0.5)
        b.Position = UDim2.new(1, -(i == 1 and 44 or 12), 0.5, 4)
        b.Size = UDim2.new(0, 26, 0, 25)
        b.BackgroundColor3 = Color3.fromRGB(48, 58, 88)
        b.BorderSizePixel = 0
        b.Font = Enum.Font.GothamBold
        b.Text = text
        b.TextSize = 17
        b.TextColor3 = Color3.fromRGB(240, 243, 255)
        b.Parent = row
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        b.Activated:Connect(function() change(i == 1 and -1 or 1) end)
    end
    if onChange then onChange(options[index]) end
    return function() return options[index] end, function(newOptions)
        options = newOptions
        index = math.clamp(index, 1, #options)
        valueLabel.Text = options[index] or "No options"
        if onChange and options[index] then onChange(options[index]) end
    end
end

local HomePage = createPage("Home")
local BringPage = createPage("Bring")
local TeleportPage = createPage("Teleports")
local ViewerPage = createPage("Viewers")
local PlayerPage = createPage("Player")
local BuyPage = createPage("Blueprints")
local ItemsPage = createPage("Items")
local WorldPage = createPage("World")
local SettingsPage = createPage("Settings")

-- Draggable window
local dragging, dragStart, startPos, dragInput = false, nil, nil, nil
Top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
Top.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

Minimize.Activated:Connect(function()
    if State.closed then return end
    Sidebar.Visible = not Sidebar.Visible
    Content.Visible = Sidebar.Visible
    Main.Size = Sidebar.Visible and UDim2.new(0, 760, 0, 500) or UDim2.new(0, 400, 0, 54)
end)

--// Locations -----------------------------------------------------------------
local Locations = {
    ["Spawn"] = Vector3.new(172, 2, 74),
    ["Wood R Us"] = Vector3.new(265, 5, 57),
    ["Land Store"] = Vector3.new(258, 5, -99),
    ["Wood Dropoff"] = Vector3.new(323.4, -2.8, 134.7),
    ["Docks"] = Vector3.new(1114, 3.2, -197),
    ["Safari"] = Vector3.new(111.85, 11, -998.8),
    ["Bridge"] = Vector3.new(112.3, 11, -782.4),
    ["End Times / Lone Cave"] = Vector3.new(113, -214, -951),
    ["Cavecrawler Maze Entrance"] = Vector3.new(3590, -177, 415),
    ["Strange Man"] = Vector3.new(1061, 20, 1131),
    ["The Swamp"] = Vector3.new(-1209, 132, -801),
    ["Snow Biome"] = Vector3.new(890, 59.8, 1196),
    ["SnowGlow Biome"] = Vector3.new(-1086.9, -5.9, -945.3),
    ["The Den"] = Vector3.new(323, 49, 1930),
    ["Taiga Peak"] = Vector3.new(1560, 410, 3274),
    ["Volcano"] = Vector3.new(-1585, 625, 1140),
    ["Shrine of Sight"] = Vector3.new(-1600, 195, 919),
    ["Cherry Meadow"] = Vector3.new(220.9, 59.8, 1305.8),
    ["Palm Island"] = Vector3.new(2549, -5, -42),
    ["Palm Island 2"] = Vector3.new(1960, -5.9, -1501),
    ["Palm Island 3"] = Vector3.new(4344, -5.9, -1813),
    ["Fancy Furnishings"] = Vector3.new(491, 13, -1720),
    ["Fine Art Shop"] = Vector3.new(5207, -166, 719),
    ["Link's Logic"] = Vector3.new(4605, 3, -727),
    ["Bob's Shack"] = Vector3.new(260, 8, -2542),
    ["Lighthouse"] = Vector3.new(1464.8, 356.3, 3257.2),
    ["Green Box"] = Vector3.new(-1668.05, 351.17, 1475.39),
    ["Bird Cave"] = Vector3.new(4813.1, 33.5, -978.8),
}

local function teleportToBase()
    local properties = Workspace:FindFirstChild("Properties")
    if not properties then return notify("Base teleport failed", "Workspace.Properties was not found.") end
    for _, property in ipairs(properties:GetChildren()) do
        local owner = property:FindFirstChild("Owner")
        local origin = property:FindFirstChild("OriginSquare")
        if owner and owner.Value == LocalPlayer and origin and origin:IsA("BasePart") then
            setCharacterCFrame(origin.CFrame + Vector3.new(0, 7, 0))
            return notify("Teleport", "Returned to your land.")
        end
    end
    notify("Base teleport failed", "No owned plot was found. Load your save first.")
end

addHeader(HomePage, "Welcome back")
addInfo(HomePage, "LT2 Utility Hub is loaded. Explore one-click Bring Tree, cave viewers, player/item teleports, blueprint buying, movement and local world controls.", 56)
addButton(HomePage, "Save current position", "Stores the exact position for Bring Tree and manual return.", function()
    local _, _, root = getCharacter()
    if not root then return notify("Save position failed", "Character is not loaded.") end
    State.savedCFrame = root.CFrame
    notify("Position saved", "Your current position has been saved.")
end)
addButton(HomePage, "Return to saved position", "Teleport back to the last saved position.", function()
    if not State.savedCFrame then return notify("No saved position", "Press Save current position first.") end
    setCharacterCFrame(State.savedCFrame)
end)
addButton(HomePage, "Teleport to your base", "Finds your plot using its Owner value.", teleportToBase)
addInfo(HomePage, "Menu: RightShift    •    Fly: Q    •    Fly movement: WASD + Space / Ctrl", 42)
addInfo(HomePage, "Bring Tree automatically finds a compatible axe in your Character/Backpack. Tree types shown in the list may not be spawned in this server. Blueprint buying spends your in-game cash.", 62)

--// Teleports UI --------------------------------------------------------------
addHeader(TeleportPage, "Main and hidden locations")
addInfo(TeleportPage, "Coordinates are community-referenced landmarks. Some locations may be blocked by terrain, server changes or streaming.", 46)
local sortedLocations = {}
for name in pairs(Locations) do table.insert(sortedLocations, name) end
table.sort(sortedLocations)
for _, name in ipairs(sortedLocations) do
    local locationName = name
    addButton(TeleportPage, locationName, "Teleport to " .. locationName, function()
        local point = Locations[locationName]
        if not point then return notify("Teleport failed", "The destination is missing.") end
        setCharacterCFrame(CFrame.new(point + Vector3.new(0, 3, 0)))
        notify("Teleport", "Moved to " .. locationName .. ".")
    end)
end
addButton(TeleportPage, "Teleport to Cavecrawler tree", "Only works when a blue Cavecrawler tree is loaded in this server.", function()
    local function locateBlueTree()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") then
                local classValue = obj:FindFirstChild("TreeClass")
                if classValue and tostring(classValue.Value) == "CaveCrawler" then
                    local wood = obj:FindFirstChild("WoodSection", true)
                    if wood and wood:IsA("BasePart") then return wood end
                end
            end
        end
    end
    local wood = locateBlueTree()
    if not wood then return notify("Cavecrawler teleport failed", "No Cavecrawler tree is loaded in this server. Follow the current maze route.") end
    setCharacterCFrame(wood.CFrame * CFrame.new(-7, 3, 0))
end, Color3.fromRGB(65, 175, 225))

addHeader(TeleportPage, "Player shortcuts")
addInfo(TeleportPage, "Teleport near an online player. This only moves your character; it does not affect their character or plot.", 48)
local function addPlayerTeleport(player)
    if not player or player == LocalPlayer then return end
    addButton(TeleportPage, "Go to " .. player.Name, "Teleport near this player if their character is loaded.", function()
        local targetCharacter = player.Character
        local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
        if not targetRoot then return notify("Player teleport failed", player.Name .. " does not have a loaded character.") end
        setCharacterCFrame(targetRoot.CFrame * CFrame.new(0, 0, 7))
    end, Color3.fromRGB(83, 135, 220))
end
for _, player in ipairs(Players:GetPlayers()) do addPlayerTeleport(player) end
Players.PlayerAdded:Connect(addPlayerTeleport)

--// Camera viewers ------------------------------------------------------------
restoreCamera = function()
    local saved = State.cameraSaved
    if not saved then return end
    State.cameraSaved = nil
    local camera = Workspace.CurrentCamera
    if camera then
        camera.CameraType = saved.CameraType
        camera.CameraSubject = saved.CameraSubject
        camera.CFrame = saved.CFrame
        camera.FieldOfView = saved.FieldOfView
    end
    notify("Viewer closed", "Camera restored to your character.")
end

local function startCameraView(position, target, label)
    if State.cameraSaved then restoreCamera() end
    local camera = Workspace.CurrentCamera
    if not camera then return notify("Viewer failed", "CurrentCamera is unavailable.") end
    State.cameraSaved = {
        CameraType = camera.CameraType,
        CameraSubject = camera.CameraSubject,
        CFrame = camera.CFrame,
        FieldOfView = camera.FieldOfView,
    }
    pcall(function() LocalPlayer:RequestStreamAroundAsync(position) end)
    camera.CameraType = Enum.CameraType.Scriptable
    camera.FieldOfView = 70
    camera.CFrame = CFrame.lookAt(position, target)
    notify(label, "Camera moved. Press Restore Camera to return.", 5)
end

local function findTreeWood(treeClass)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local classValue = obj:FindFirstChild("TreeClass")
            if classValue and tostring(classValue.Value) == treeClass then
                local wood = obj:FindFirstChild("WoodSection", true)
                if wood and wood:IsA("BasePart") then return obj, wood end
            end
        end
    end
    return nil, nil
end

addHeader(ViewerPage, "Camera-only viewers")
addInfo(ViewerPage, "These buttons move your camera, not your character. Cavecrawler Cavern is deep inside the Tropics Maze; its route changes every four days, so the viewer locks onto a live blue tree when one is loaded.", 64)
addButton(ViewerPage, "View Lone Cave / End Times Cave", "Lone Cave is below the bridge; camera view uses its landmark position.", function()
    local _, wood = findTreeWood("LoneCave")
    local target = wood and wood.Position or Vector3.new(113, -214, -951)
    startCameraView(target + Vector3.new(0, 38, 72), target, "Lone Cave viewer")
end, Color3.fromRGB(164, 105, 235))
addButton(ViewerPage, "View End Times Tree", "Focuses on the Lone Cave / Phantom tree when it is loaded.", function()
    local _, wood = findTreeWood("LoneCave")
    if not wood then return notify("End Times Tree not found", "The Phantom tree is not loaded in this server.") end
    startCameraView(wood.Position + Vector3.new(0, 18, 38), wood.Position, "End Times Tree viewer")
end, Color3.fromRGB(164, 105, 235))
addButton(ViewerPage, "View Cavecrawler Cavern (Blue Wood)", "Locks the camera onto a live blue Cavecrawler tree; falls back to a rough cave landmark only if no tree is streamed.", function()
    local _, wood = findTreeWood("CaveCrawler")
    if not wood then
        notify("Cavecrawler viewer", "No blue tree is streamed in this server. Using an approximate cave landmark; this may not be the cavern.", 6)
        local fallback = Vector3.new(3590, -177, 415)
        startCameraView(fallback + Vector3.new(0, 45, 80), fallback, "Cavecrawler landmark viewer")
        return
    end
    local target = wood.Position
    startCameraView(target + Vector3.new(0, 52, 92), target, "Cavecrawler Cavern viewer")
end, Color3.fromRGB(65, 175, 225))
addButton(ViewerPage, "Restore Camera", "Return to normal character camera.", restoreCamera)

--// Tree detection and chopping ------------------------------------------------
local KnownTreeClasses = {
    "Generic", "Oak", "Elm", "Birch", "Cherry", "Fir", "Pine", "Walnut", "Koa", "Palm",
    "Lava", "Volcano", "SnowGlow", "Frost", "Gold", "GoldSwampy", "GreenSwampy", "Zombie",
    "CaveCrawler", "LoneCave", "Phantom", "Spooky", "SpookyNeon", "Spook", "Sinister",
    "BlueSpruce", "Kappala", "CherryBlossom", "Sign",
}

local function getTreeRegions()
    local regions = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "TreeRegion" then table.insert(regions, obj) end
    end
    return regions
end

local function getTreeClasses()
    local seen, classes = {}, {}
    for _, className in ipairs(KnownTreeClasses) do
        if not seen[className] then seen[className] = true; table.insert(classes, className) end
    end
    for _, region in ipairs(getTreeRegions()) do
        for _, model in ipairs(region:GetChildren()) do
            local classValue = model:FindFirstChild("TreeClass")
            if model:IsA("Model") and classValue and not seen[tostring(classValue.Value)] then
                seen[tostring(classValue.Value)] = true
                table.insert(classes, tostring(classValue.Value))
            end
        end
    end
    table.sort(classes)
    return classes
end

local function getTreeRootSection(tree)
    local fallback = nil
    for _, part in ipairs(tree:GetDescendants()) do
        if part:IsA("BasePart") and part.Name == "WoodSection" then
            local id = part:FindFirstChild("ID")
            if id and tonumber(id.Value) == 1 then return part end
            fallback = fallback or part
        end
    end
    return fallback
end

local function findAvailableTree(treeClass)
    local candidates = {}
    local regions = getTreeRegions()
    if #regions == 0 then
        return nil, "No TreeRegion folders are loaded in Workspace. The map may still be streaming; try Refresh or rejoin."
    end

    local matching, claimed, cut, malformed = 0, 0, 0, 0
    for _, region in ipairs(regions) do
        for _, model in ipairs(region:GetChildren()) do
            if model:IsA("Model") then
                local classValue = model:FindFirstChild("TreeClass")
                if classValue and tostring(classValue.Value) == treeClass then
                    matching += 1
                    local owner = model:FindFirstChild("Owner")
                    if model:FindFirstChild("RootCut") then
                        cut += 1
                    elseif not model:FindFirstChild("CutEvent") or not owner then
                        malformed += 1
                    elseif owner.Value ~= nil then
                        claimed += 1
                    else
                        local rootWood, sectionCount, totalMass = getTreeRootSection(model), 0, 0
                        for _, part in ipairs(model:GetDescendants()) do
                            if part:IsA("BasePart") and part.Name == "WoodSection" then
                                sectionCount += 1
                                totalMass += part.AssemblyMass
                            end
                        end
                        if rootWood and sectionCount > 1 then
                            table.insert(candidates, {Model = model, Mass = totalMass})
                        else
                            malformed += 1
                        end
                    end
                end
            end
        end
    end

    table.sort(candidates, function(a, b) return a.Mass > b.Mass end)
    if candidates[1] then return candidates[1].Model end
    if matching == 0 then
        return nil, "No " .. treeClass .. " tree is spawned in this server. The list includes game tree types, not only trees currently spawned here."
    elseif claimed == matching then
        return nil, "Found " .. matching .. " " .. treeClass .. " tree(s), but all are owned/claimed. Try another server."
    elseif cut == matching then
        return nil, "Found " .. matching .. " " .. treeClass .. " tree(s), but they have already been cut."
    elseif malformed > 0 then
        return nil, "Found " .. matching .. " matching tree(s), but none had the required standing WoodSection/CutEvent structure."
    end
    return nil, "Found " .. matching .. " matching tree(s), but none is currently available to chop."
end

local function getBestAxeForTree(treeClass)
    local character = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not character then return nil, nil, "Your character is not loaded." end

    local candidates, seen = {}, {}
    local function inspect(container, equipped)
        if not container then return end
        for _, tool in ipairs(container:GetChildren()) do
            if tool:IsA("Tool") and not seen[tool] and tool:FindFirstChild("ToolName") then
                seen[tool] = true
                local toolName = tostring(tool.ToolName.Value)
                local moduleFolder = ReplicatedStorage:FindFirstChild("AxeClasses")
                local module = moduleFolder and moduleFolder:FindFirstChild("AxeClass_" .. toolName)
                if module then
                    local ok, stats = pcall(function() return require(module).new() end)
                    if ok and type(stats) == "table" then
                        if stats.SpecialTrees and stats.SpecialTrees[treeClass] then
                            for key, value in pairs(stats.SpecialTrees[treeClass]) do stats[key] = value end
                        end
                        local supportsTree = stats.Damage ~= nil and stats.SwingCooldown ~= nil
                        if treeClass == "LoneCave" then supportsTree = supportsTree and toolName == "EndTimesAxe" end
                        if supportsTree then
                            table.insert(candidates, {Tool = tool, Stats = stats, Damage = tonumber(stats.Damage) or 0, Equipped = equipped})
                        end
                    end
                end
            end
        end
    end
    inspect(character, true)
    inspect(backpack, false)
    table.sort(candidates, function(a, b)
        if a.Equipped ~= b.Equipped then return a.Equipped end
        return a.Damage > b.Damage
    end)
    local best = candidates[1]
    if not best then
        if treeClass == "LoneCave" then
            return nil, nil, "No suitable End Times Axe was found. Put it in your inventory first."
        end
        return nil, nil, "No usable LT2 axe was found in your character or Backpack."
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if best.Tool.Parent ~= character then
        if not humanoid then return nil, nil, "Your Humanoid is missing, so the axe cannot be equipped." end
        humanoid:EquipTool(best.Tool)
        task.wait(0.25)
    end
    if best.Tool.Parent ~= character then return nil, nil, "The game did not equip the selected axe." end
    return best.Tool, best.Stats
end

local function getAxeStats(axe, treeClass)
    local axeClasses = ReplicatedStorage:FindFirstChild("AxeClasses")
    if not axeClasses then return nil, "ReplicatedStorage.AxeClasses was not found." end
    local toolName = axe:FindFirstChild("ToolName")
    if not toolName then return nil, "Selected tool has no ToolName value." end
    local module = axeClasses:FindFirstChild("AxeClass_" .. tostring(toolName.Value))
    if not module then return nil, "No axe stats module exists for " .. tostring(toolName.Value) .. "." end
    local ok, stats = pcall(function() return require(module).new() end)
    if not ok or type(stats) ~= "table" then return nil, "Could not read axe stats: " .. tostring(stats) end
    if stats.SpecialTrees and stats.SpecialTrees[treeClass] then
        for key, value in pairs(stats.SpecialTrees[treeClass]) do stats[key] = value end
    end
    if not stats.Damage or not stats.SwingCooldown then return nil, "Axe stats are missing Damage or SwingCooldown." end
    return stats
end

local function findOwnedLooseLog(treeClass, startTime, baselineLogs)
    local logFolder = Workspace:FindFirstChild("LogModels")
    if not logFolder then return nil end
    for _, log in ipairs(logFolder:GetChildren()) do
        local owner = log:FindFirstChild("Owner")
        local isNew = not (baselineLogs and baselineLogs[log])
        if isNew and owner and owner.Value == LocalPlayer then
            local wood = log:FindFirstChild("WoodSection", true)
            if (wood and wood:IsA("BasePart")) or log.PrimaryPart then return log end
        end
    end
    return nil
end

local function moveLooseLogTo(cutLog, destination)
    local interaction = ReplicatedStorage:FindFirstChild("Interaction")
    local dragRemote = interaction and interaction:FindFirstChild("ClientIsDragging")
    if not dragRemote then return false, "Interaction.ClientIsDragging was not found." end
    if not cutLog or not cutLog.Parent then return false, "The cut tree log disappeared before it could be moved." end

    local wood = cutLog:FindFirstChild("WoodSection", true)
    if wood and wood:IsA("BasePart") then
        pcall(function() cutLog.PrimaryPart = wood end)
    end
    if not cutLog.PrimaryPart and not wood then
        return false, "The new log has no WoodSection or PrimaryPart to move."
    end
    if not dragRemote:IsA("RemoteEvent") then
        return false, "Interaction.ClientIsDragging is present but is not a RemoteEvent."
    end

    local ok, err = pcall(function()
        local destinationCFrame = destination * CFrame.new(0, 4, 0)
        -- Request drag ownership while the model is still present, then move it
        -- repeatedly with its physics velocity cleared so it does not roll away.
        task.spawn(function()
            for _ = 1, 60 do
                if not cutLog.Parent then break end
                dragRemote:FireServer(cutLog)
                task.wait()
            end
        end)
        task.wait(0.1)
        for _ = 1, 60 do
            if not cutLog.Parent then break end
            local primary = cutLog.PrimaryPart or wood
            if primary and primary.Parent then
                primary.AssemblyLinearVelocity = Vector3.zero
                primary.AssemblyAngularVelocity = Vector3.zero
            end
            cutLog:PivotTo(destinationCFrame)
            task.wait()
        end
        if cutLog.Parent then
            dragRemote:FireServer(cutLog)
            cutLog:PivotTo(destinationCFrame)
        end
        task.wait(0.25)
    end)
    if not ok then return false, "The drag/move operation raised an error: " .. tostring(err) end
    if not cutLog.Parent then return false, "The server removed the loose log while it was being moved." end
    local targetPosition = (destination * CFrame.new(0, 4, 0)).Position
    local finalPosition = cutLog:GetPivot().Position
    if (finalPosition - targetPosition).Magnitude > 35 then
        return false, "The drag request ran, but the log stayed " .. math.floor((finalPosition - targetPosition).Magnitude) .. " studs from the saved position. The server did not accept the drag/move; you may not have drag ownership."
    end
    return true
end

local function bringOneTree(treeClass, originalCFrame)
    local character, humanoid, root = getCharacter()
    if not root then return false, "Character is not loaded." end

    local tree, treeError = findAvailableTree(treeClass)
    if not tree then return false, treeError or ("Could not find an available " .. treeClass .. " tree.") end
    local wood = getTreeRootSection(tree)
    local cutEvent = tree:FindFirstChild("CutEvent")
    local interaction = ReplicatedStorage:FindFirstChild("Interaction")
    local proxy = interaction and interaction:FindFirstChild("RemoteProxy")
    if not wood then return false, "The selected tree has no usable root WoodSection." end
    if not cutEvent then return false, "The selected tree has no CutEvent instance; the game's tree structure may have changed." end
    if not proxy then return false, "ReplicatedStorage.Interaction.RemoteProxy is missing; the game's chop remote may have changed." end
    if not proxy:IsA("RemoteEvent") then return false, "RemoteProxy exists but is not a RemoteEvent, so FireServer cannot be called." end

    local axe, stats, axeError = getBestAxeForTree(treeClass)
    if not axe then return false, axeError end

    local logFolder = Workspace:FindFirstChild("LogModels")
    if not logFolder then return false, "Workspace.LogModels was not found." end
    local baselineLogs = {}
    for _, existingLog in ipairs(logFolder:GetChildren()) do baselineLogs[existingLog] = true end

    local newLog = nil
    local addedConnection = logFolder.ChildAdded:Connect(function(log)
        task.spawn(function()
            for _ = 1, 20 do
                if not log or not log.Parent then return end
                local owner = log:FindFirstChild("Owner")
                if owner and owner.Value == LocalPlayer and not baselineLogs[log] then
                    newLog = log
                    return
                end
                task.wait(0.1)
            end
        end)
    end)

    local function findNewOwnedLog()
        for _, log in ipairs(logFolder:GetChildren()) do
            if not baselineLogs[log] then
                local owner = log:FindFirstChild("Owner")
                if owner and owner.Value == LocalPlayer then return log end
            end
        end
        return nil
    end

    local tetherConnection
    local chopOk, chopError = pcall(function()
        local approach = wood.Position + Vector3.new(5, 3, 0)
        root.CFrame = CFrame.lookAt(approach, wood.Position)
        task.wait(0.25)

        -- Keep the character in valid chopping range while the server processes
        -- each swing. This connection is always disconnected after the pcall.
        tetherConnection = RunService.Heartbeat:Connect(function()
            if State.stopTree or not tree.Parent or not wood.Parent or not root.Parent then return end
            if (root.Position - approach).Magnitude > 3 then
                root.CFrame = CFrame.lookAt(approach, wood.Position)
            end
        end)

        local sectionId = 1
        local idValue = wood:FindFirstChild("ID")
        if idValue and tonumber(idValue.Value) then sectionId = tonumber(idValue.Value) end
        local swingCooldown = math.max(tonumber(stats.SwingCooldown) or 0.25, 0.12)
        local args = {
            tool = axe,
            height = 0.3,
            faceVector = (wood.Position - root.Position).Magnitude > 0 and (wood.Position - root.Position).Unit or Vector3.new(1, 0, 0),
            sectionId = sectionId,
            hitPoints = tonumber(stats.Damage) or 0.2,
            cooldown = tonumber(stats.SwingCooldown) or 0,
            cuttingClass = "Axe",
        }

        local deadline = os.clock() + 35
        repeat
            if State.stopTree then break end
            if not tree.Parent then break end
            if tree:FindFirstChild("RootCut") then break end
            if not root.Parent then error("Your character root disappeared during the chop.") end
            if not wood.Parent then break end
            proxy:FireServer(cutEvent, args)
            task.wait(swingCooldown)
            newLog = newLog or findNewOwnedLog()
        until tree:FindFirstChild("RootCut") or newLog or os.clock() >= deadline
    end)
    if tetherConnection then tetherConnection:Disconnect() end
    addedConnection:Disconnect()

    if not chopOk then return false, "Chop request failed: " .. tostring(chopError) end
    if State.stopTree then return false, "Stopped by user." end

    local logDeadline = os.clock() + 10
    while not newLog and os.clock() < logDeadline do
        newLog = findNewOwnedLog()
        task.wait(0.12)
    end
    if not newLog then
        if tree.Parent and not tree:FindFirstChild("RootCut") then
            return false, "No cut was confirmed after 35 seconds. The server rejected the chop or the axe/tree stats do not match. Check that you have the right axe, the tree is unclaimed, and your character is close enough."
        end
        return false, "The tree was cut, but no new log owned by you appeared in Workspace.LogModels within 10 seconds. The server may not have replicated the log yet."
    end

    local moved, moveError = moveLooseLogTo(newLog, originalCFrame)
    if not moved then return false, "The tree was cut, but moving its log failed: " .. tostring(moveError) end
    if root.Parent then root.CFrame = originalCFrame end
    return true, "Brought " .. treeClass .. " back to your saved position."
end

local treeClassOptions = getTreeClasses()
local treeListRefresh
local bringStatusLabel

local function setBringStatus(message, isError)
    if bringStatusLabel and bringStatusLabel.Parent then
        bringStatusLabel.Text = "STATUS  /  " .. tostring(message)
        bringStatusLabel.TextColor3 = isError and Color3.fromRGB(255, 132, 150) or Color3.fromRGB(120, 236, 190)
    end
end

local function beginBringTree(treeClass)
    if State.runningTree then
        local message = "A Bring Tree job is already running. Press Stop before starting another."
        setBringStatus(message, true)
        return notify("Bring Tree busy", message, 5)
    end
    local _, _, root = getCharacter()
    if not root then
        local message = "Your character or HumanoidRootPart is not loaded. Reset or rejoin, then try again."
        setBringStatus(message, true)
        return notify("Bring Tree failed", message, 6)
    end

    State.savedCFrame = root.CFrame
    local original = State.savedCFrame
    local requestedAmount = math.clamp(tonumber(State.treeAmount) or 1, 1, 67)
    State.runningTree = true
    State.stopTree = false
    setBringStatus("Starting " .. treeClass .. " • " .. requestedAmount .. " requested", false)
    notify("Bring Tree", "Starting " .. treeClass .. ". Your starting position has been saved.", 3)

    task.spawn(function()
        local completed = 0
        local failure = nil
        for index = 1, requestedAmount do
            if State.stopTree then
                failure = "Stopped by you before the next tree."
                break
            end
            setBringStatus("Processing " .. index .. "/" .. requestedAmount .. " • " .. treeClass, false)
            local ok, message = bringOneTree(treeClass, original)
            if not ok then
                failure = tostring(message or "The tree process failed without returning an error message.")
                break
            end
            completed += 1
            setBringStatus("Brought " .. completed .. "/" .. requestedAmount .. " • " .. treeClass, false)
            task.wait(0.45)
        end

        local _, _, currentRoot = getCharacter()
        if currentRoot and original then currentRoot.CFrame = original end
        State.runningTree = false
        State.stopTree = false

        if failure then
            setBringStatus("FAILED after " .. completed .. " tree(s): " .. failure, true)
            notify("Bring Tree failed", failure, 8)
            warn("[LT2 Bring Tree] " .. failure)
        else
            local summary = "Finished: " .. completed .. "/" .. requestedAmount .. " " .. treeClass .. " tree(s) brought to your starting position."
            setBringStatus(summary, false)
            notify("Bring Tree finished", summary, 6)
        end
    end)
end

local function createTreeClassList(options)
    local panel = Instance.new("Frame")
    panel.Name = "BringTreePanel"
    panel.Size = UDim2.new(1, -4, 0, 326)
    panel.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
    panel.BorderSizePixel = 0
    panel.Parent = BringPage
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 11)
    local panelStroke = Instance.new("UIStroke")
    panelStroke.Color = Color3.fromRGB(113, 83, 255)
    panelStroke.Transparency = 0.48
    panelStroke.Thickness = 1.15
    panelStroke.Parent = panel
    local panelGradient = Instance.new("UIGradient")
    panelGradient.Color = ColorSequence.new(Color3.fromRGB(26, 31, 49), Color3.fromRGB(17, 20, 31))
    panelGradient.Rotation = 90
    panelGradient.Parent = panel

    local heading = Instance.new("TextLabel")
    heading.BackgroundTransparency = 1
    heading.Position = UDim2.new(0, 13, 0, 8)
    heading.Size = UDim2.new(1, -26, 0, 22)
    heading.Font = Enum.Font.GothamBold
    heading.Text = "BRING TREE"
    heading.TextColor3 = Color3.fromRGB(243, 245, 255)
    heading.TextSize = 13
    heading.TextXAlignment = Enum.TextXAlignment.Left
    heading.Parent = panel

    local subheading = Instance.new("TextLabel")
    subheading.BackgroundTransparency = 1
    subheading.Position = UDim2.new(0, 13, 0, 29)
    subheading.Size = UDim2.new(1, -26, 0, 17)
    subheading.Font = Enum.Font.Gotham
    subheading.Text = "Click a tree type below to start chopping and bringing it back."
    subheading.TextColor3 = Color3.fromRGB(151, 163, 190)
    subheading.TextSize = 10
    subheading.TextXAlignment = Enum.TextXAlignment.Left
    subheading.Parent = panel

    local search = Instance.new("TextBox")
    search.Position = UDim2.new(0, 11, 0, 52)
    search.Size = UDim2.new(1, -22, 0, 30)
    search.BackgroundColor3 = Color3.fromRGB(11, 14, 23)
    search.BorderSizePixel = 0
    search.PlaceholderText = "Search tree types..."
    search.PlaceholderColor3 = Color3.fromRGB(116, 128, 154)
    search.Text = ""
    search.ClearTextOnFocus = false
    search.Font = Enum.Font.Gotham
    search.TextSize = 11
    search.TextColor3 = Color3.fromRGB(238, 242, 255)
    search.Parent = panel
    Instance.new("UICorner", search).CornerRadius = UDim.new(0, 7)
    local searchStroke = Instance.new("UIStroke")
    searchStroke.Color = Color3.fromRGB(75, 83, 122)
    searchStroke.Transparency = 0.55
    searchStroke.Parent = search

    local list = Instance.new("ScrollingFrame")
    list.Name = "TreeTypeList"
    list.Position = UDim2.new(0, 11, 0, 91)
    list.Size = UDim2.new(1, -22, 1, -102)
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 4
    list.ScrollBarImageColor3 = Color3.fromRGB(155, 91, 255)
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.CanvasSize = UDim2.new(0, 0, 0, 0)
    list.Active = true
    list.Parent = panel
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = list

    local function render()
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
        end
        local filter = string.lower(search.Text or "")
        local order = 0
        for _, className in ipairs(options) do
            if filter == "" or string.find(string.lower(className), filter, 1, true) then
                order += 1
                local button = Instance.new("TextButton")
                button.Name = "BringTree_" .. className
                button.LayoutOrder = order
                button.Size = UDim2.new(1, -2, 0, 34)
                button.BackgroundColor3 = Color3.fromRGB(27, 32, 48)
                button.BorderSizePixel = 0
                button.AutoButtonColor = false
                button.Text = ""
                button.Active = true
                button.Selectable = true
                button.Parent = list
                Instance.new("UICorner", button).CornerRadius = UDim.new(0, 7)
                local edge = Instance.new("UIStroke")
                edge.Color = Color3.fromRGB(86, 91, 145)
                edge.Transparency = 0.62
                edge.Parent = button

                local name = Instance.new("TextLabel")
                name.BackgroundTransparency = 1
                name.Position = UDim2.new(0, 11, 0, 0)
                name.Size = UDim2.new(1, -118, 1, 0)
                name.Font = Enum.Font.GothamSemibold
                name.Text = className
                name.TextColor3 = Color3.fromRGB(232, 237, 252)
                name.TextSize = 11
                name.TextXAlignment = Enum.TextXAlignment.Left
                name.Parent = button

                local action = Instance.new("TextLabel")
                action.AnchorPoint = Vector2.new(1, 0.5)
                action.Position = UDim2.new(1, -9, 0.5, 0)
                action.Size = UDim2.new(0, 92, 0, 23)
                action.BackgroundColor3 = Color3.fromRGB(89, 57, 178)
                action.BorderSizePixel = 0
                action.Font = Enum.Font.GothamBold
                action.Text = "BRING TREE"
                action.TextColor3 = Color3.fromRGB(255, 255, 255)
                action.TextSize = 9
                action.Parent = button
                Instance.new("UICorner", action).CornerRadius = UDim.new(0, 6)

                button.MouseEnter:Connect(function()
                    TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(39, 43, 67)}):Play()
                end)
                button.MouseLeave:Connect(function()
                    TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(27, 32, 48)}):Play()
                end)
                button.Activated:Connect(function()
                    beginBringTree(className)
                end)
            end
        end
        if order == 0 then
            local empty = Instance.new("TextLabel")
            empty.BackgroundTransparency = 1
            empty.Size = UDim2.new(1, 0, 0, 28)
            empty.Text = "No matching tree types"
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 11
            empty.TextColor3 = Color3.fromRGB(150, 160, 180)
            empty.Parent = list
        end
    end
    search:GetPropertyChangedSignal("Text"):Connect(render)
    render()
    treeListRefresh = function(newOptions)
        options = newOptions
        render()
    end
end

addHeader(BringPage, "Tree collection")
addInfo(BringPage, "Each tree type is a one-click action. Clicking a row saves your current position, equips a compatible axe, attempts the chop, then returns the resulting owned log. The server can still reject game remotes or drag ownership; the exact reason will appear below.", 68)
addStepper(BringPage, "Trees to bring per click (max 67)", 1, 1, 67, function(value) State.treeAmount = value end)
createTreeClassList(treeClassOptions)

bringStatusLabel = addInfo(BringPage, "STATUS  /  Ready — click a tree type to bring it.", 62)
bringStatusLabel.TextColor3 = Color3.fromRGB(120, 236, 190)
addButton(BringPage, "Refresh tree types", "Refreshes the game-wide tree class list and types currently streamed in this server.", function()
    treeClassOptions = getTreeClasses()
    if treeListRefresh then treeListRefresh(treeClassOptions) end
    local msg = tostring(#treeClassOptions) .. " tree types listed. A type may not be spawned in this server."
    setBringStatus(msg, false)
    notify("Tree list refreshed", msg, 5)
end)
addButton(BringPage, "Stop Bring Tree", "Stops after the current chop/move check and returns you to your saved position.", function()
    if not State.runningTree then return notify("Bring Tree", "There is no active Bring Tree job.") end
    State.stopTree = true
    setBringStatus("Stop requested — waiting for the current step to finish.", false)
    notify("Stopping Bring Tree", "The job will stop at its next safe check.")
end, Color3.fromRGB(185, 83, 92))

--// Blueprint purchase --------------------------------------------------------
local STORE_IDS = {
    WoodRUs = 7,
    FurnitureStore = 8,
    CarStore = 9,
    ShackShop = 10,
    FineArt = 11,
    LogicStore = 12,
}

local function getStoreFolder()
    return Workspace:FindFirstChild("Stores")
end

local function getShopItemsFolder()
    local stores = getStoreFolder()
    return stores and stores:FindFirstChild("ShopItems")
end

local function findNearestCounter(itemModel)
    local stores = getStoreFolder()
    local mainPart = itemModel and itemModel:FindFirstChild("Main")
    if mainPart and not mainPart:IsA("BasePart") then mainPart = nil end
    mainPart = mainPart or (itemModel and itemModel.PrimaryPart) or (itemModel and itemModel:FindFirstChildWhichIsA("BasePart", true))
    if not stores or not mainPart then return nil, nil end

    local nearest, nearestStore, nearestDistance = nil, nil, math.huge
    for _, store in ipairs(stores:GetChildren()) do
        if store.Name ~= "ShopItems" and store.Name ~= "LandStore" then
            local counter = store:FindFirstChild("Counter")
            if counter and counter:IsA("BasePart") then
                local distance = (counter.Position - mainPart.Position).Magnitude
                if distance < nearestDistance then
                    nearest, nearestStore, nearestDistance = counter, store, distance
                end
            end
        end
    end
    if nearestDistance > 500 then return nil, nil end
    return nearest, nearestStore
end

local function listBlueprintModels()
    local shopItems = getShopItemsFolder()
    if not shopItems then return {}, "Workspace.Stores.ShopItems was not found." end
    local list, seen = {}, {}
    for _, model in ipairs(shopItems:GetChildren()) do
        if model:IsA("Model") then
            local typeValue = model:FindFirstChild("Type")
            local nameValue = model:FindFirstChild("BoxItemName")
            local owner = model:FindFirstChild("Owner")
            if typeValue and tostring(typeValue.Value) == "Blueprint" and nameValue and owner and owner.Value == nil then
                local counter, store = findNearestCounter(model)
                if counter and store and STORE_IDS[store.Name] then
                    local name = tostring(nameValue.Value)
                    local key = store.Name .. "::" .. name
                    if not seen[key] then
                        seen[key] = true
                        table.insert(list, {Name = name, StoreName = store.Name, Model = model})
                    end
                end
            end
        end
    end
    table.sort(list, function(a, b)
        if a.StoreName == b.StoreName then return a.Name < b.Name end
        return a.StoreName < b.StoreName
    end)
    return list
end

--// Item finder and local player teleporter ------------------------------------
local function getModelTarget(model)
    if not model or not model.Parent then return nil end
    if model:IsA("BasePart") then return model end
    local named = model:FindFirstChild("Main") or model:FindFirstChild("WoodSection", true)
    if named and named:IsA("BasePart") then return named end
    if model.PrimaryPart then return model.PrimaryPart end
    return model:FindFirstChildWhichIsA("BasePart", true)
end

local function scanTeleportItems()
    local results, seen = {}, {}
    local folders = {
        Workspace:FindFirstChild("LogModels"),
        Workspace:FindFirstChild("PlayerModels"),
        getShopItemsFolder(),
    }
    for _, folder in ipairs(folders) do
        if folder then
            for _, object in ipairs(folder:GetChildren()) do
                if (object:IsA("Model") or object:IsA("BasePart")) and not seen[object] then
                    local target = getModelTarget(object)
                    if target then
                        seen[object] = true
                        local itemName = object.Name
                        local boxName = object:FindFirstChild("BoxItemName") or object:FindFirstChild("ItemName")
                        if boxName and boxName:IsA("ValueBase") then itemName = tostring(boxName.Value) end
                        local owner = object:FindFirstChild("Owner")
                        local ownerValue = owner and owner.Value
                        local ownerName = "Unclaimed / unknown"
                        if typeof(ownerValue) == "Instance" then ownerName = ownerValue.Name
                        elseif ownerValue ~= nil and tostring(ownerValue) ~= "" then ownerName = tostring(ownerValue) end
                        table.insert(results, {Object = object, Target = target, Name = itemName, Owner = ownerName})
                    end
                end
            end
        end
    end
    table.sort(results, function(a, b) return string.lower(a.Name) < string.lower(b.Name) end)
    return results
end

addHeader(ItemsPage, "Item finder & teleporter")
addInfo(ItemsPage, "Scans loose logs, player models and stocked shop items. Click a result to teleport your character near it; this does not move or steal the item.", 56)
local itemSearch = Instance.new("TextBox")
itemSearch.Size = UDim2.new(1, -4, 0, 34)
itemSearch.BackgroundColor3 = Color3.fromRGB(17, 21, 33)
itemSearch.BorderSizePixel = 0
itemSearch.PlaceholderText = "Search logs, boxes and items..."
itemSearch.PlaceholderColor3 = Color3.fromRGB(122, 133, 158)
itemSearch.Text = ""
itemSearch.ClearTextOnFocus = false
itemSearch.Font = Enum.Font.Gotham
itemSearch.TextSize = 11
itemSearch.TextColor3 = Color3.fromRGB(236, 240, 255)
itemSearch.Parent = ItemsPage
Instance.new("UICorner", itemSearch).CornerRadius = UDim.new(0, 8)
local itemSearchPadding = Instance.new("UIPadding")
itemSearchPadding.PaddingLeft = UDim.new(0, 10)
itemSearchPadding.Parent = itemSearch
local itemList = Instance.new("ScrollingFrame")
itemList.Name = "ItemResults"
itemList.Size = UDim2.new(1, -4, 0, 300)
itemList.BackgroundColor3 = Color3.fromRGB(17, 21, 33)
itemList.BorderSizePixel = 0
itemList.ScrollBarThickness = 4
itemList.ScrollBarImageColor3 = Color3.fromRGB(155, 91, 255)
itemList.AutomaticCanvasSize = Enum.AutomaticSize.Y
itemList.CanvasSize = UDim2.new(0, 0, 0, 0)
itemList.Active = true
itemList.Parent = ItemsPage
Instance.new("UICorner", itemList).CornerRadius = UDim.new(0, 9)
local itemLayout = Instance.new("UIListLayout")
itemLayout.Padding = UDim.new(0, 5)
itemLayout.SortOrder = Enum.SortOrder.LayoutOrder
itemLayout.Parent = itemList
local itemPadding = Instance.new("UIPadding")
itemPadding.PaddingTop = UDim.new(0, 7)
itemPadding.PaddingLeft = UDim.new(0, 7)
itemPadding.PaddingRight = UDim.new(0, 7)
itemPadding.PaddingBottom = UDim.new(0, 7)
itemPadding.Parent = itemList
local itemStatus = addInfo(ItemsPage, "ITEMS  /  Press Refresh to scan the current server.", 42)
local function renderItemResults()
    for _, child in ipairs(itemList:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
    end
    local query = string.lower(itemSearch.Text or "")
    local results = scanTeleportItems()
    local order = 0
    for _, entry in ipairs(results) do
        if query == "" or string.find(string.lower(entry.Name), query, 1, true) then
            order += 1
            if order <= 100 then
                local row = Instance.new("TextButton")
                row.Size = UDim2.new(1, -2, 0, 38)
                row.LayoutOrder = order
                row.BackgroundColor3 = Color3.fromRGB(27, 32, 48)
                row.BorderSizePixel = 0
                row.AutoButtonColor = false
                row.Text = ""
                row.Active = true
                row.Parent = itemList
                Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)
                local name = Instance.new("TextLabel")
                name.BackgroundTransparency = 1
                name.Position = UDim2.new(0, 10, 0, 3)
                name.Size = UDim2.new(1, -18, 0, 17)
                name.Font = Enum.Font.GothamSemibold
                name.Text = entry.Name
                name.TextColor3 = Color3.fromRGB(232, 237, 252)
                name.TextSize = 11
                name.TextXAlignment = Enum.TextXAlignment.Left
                name.Parent = row
                local sub = Instance.new("TextLabel")
                sub.BackgroundTransparency = 1
                sub.Position = UDim2.new(0, 10, 0, 20)
                sub.Size = UDim2.new(1, -18, 0, 14)
                sub.Font = Enum.Font.Gotham
                sub.Text = "Owner: " .. entry.Owner .. "  •  Click to teleport nearby"
                sub.TextColor3 = Color3.fromRGB(137, 148, 171)
                sub.TextSize = 9
                sub.TextXAlignment = Enum.TextXAlignment.Left
                sub.Parent = row
                row.Activated:Connect(function()
                    if not entry.Object.Parent or not entry.Target.Parent then
                        return notify("Item teleport failed", "That item disappeared; refresh the item list and try again.")
                    end
                    local _, _, root = getCharacter()
                    if not root then return notify("Item teleport failed", "Your character is not loaded.") end
                    local targetPosition = entry.Target.Position + Vector3.new(0, 6, 0)
                    setCharacterCFrame(CFrame.lookAt(targetPosition, entry.Target.Position))
                    notify("Item teleport", "Moved near " .. entry.Name .. ". The item itself was not moved.")
                end)
            end
        end
    end
    itemStatus.Text = "ITEMS  /  " .. tostring(math.min(order, 100)) .. " matching result(s) shown."
end
itemSearch:GetPropertyChangedSignal("Text"):Connect(renderItemResults)
addButton(ItemsPage, "Refresh item list", "Rescans logs, player models and store stock currently loaded in the server.", renderItemResults)
renderItemResults()

--// World / visual controls ----------------------------------------------------
addHeader(WorldPage, "Client-side environment")
addInfo(WorldPage, "These lighting and visual options only change what you see locally. They do not alter the server or other players.", 52)
local originalClockTime = Lighting.ClockTime
local originalGlobalShadows = Lighting.GlobalShadows
local originalBrightness = Lighting.Brightness
local originalAmbient = Lighting.Ambient
local originalOutdoorAmbient = Lighting.OutdoorAmbient
local originalFogEnd = Lighting.FogEnd
local alwaysDaySetter, alwaysNightSetter
local _, setAlwaysDay = addToggle(WorldPage, "Always day", false, function(value)
    State.alwaysDay = value
    if value then
        State.alwaysNight = false
        if alwaysNightSetter then alwaysNightSetter(false, false) end
        Lighting.ClockTime = 13
    end
end, "Locks your local lighting to daytime.")
alwaysDaySetter = setAlwaysDay
local _, setAlwaysNight = addToggle(WorldPage, "Always night", false, function(value)
    State.alwaysNight = value
    if value then
        State.alwaysDay = false
        if alwaysDaySetter then alwaysDaySetter(false, false) end
        Lighting.ClockTime = 0
    end
end, "Locks your local lighting to night-time.")
alwaysNightSetter = setAlwaysNight
local _, setNoShadows = addToggle(WorldPage, "Disable global shadows", false, function(value)
    State.noShadows = value
    Lighting.GlobalShadows = not value
end, "Local performance / visibility option.")
local _, setFullBright = addToggle(WorldPage, "Full bright", false, function(value)
    State.fullBright = value
    if value then
        Lighting.Brightness = 3
        Lighting.Ambient = Color3.fromRGB(190, 190, 205)
        Lighting.OutdoorAmbient = Color3.fromRGB(210, 210, 225)
    else
        Lighting.Brightness = originalBrightness
        Lighting.Ambient = originalAmbient
        Lighting.OutdoorAmbient = originalOutdoorAmbient
    end
end, "Raises local brightness; does not change server time.")
local _, setFogDistance = addToggle(WorldPage, "Remove fog distance", false, function(value)
    if value then Lighting.FogEnd = 100000 else Lighting.FogEnd = originalFogEnd end
end, "Extends your local fog distance. Atmosphere effects may still be present.")
addButton(WorldPage, "Restore original lighting", "Restores the lighting values captured when the hub started.", function()
    State.alwaysDay = false
    State.alwaysNight = false
    State.noShadows = false
    State.fullBright = false
    Lighting.ClockTime = originalClockTime
    Lighting.GlobalShadows = originalGlobalShadows
    Lighting.Brightness = originalBrightness
    Lighting.Ambient = originalAmbient
    Lighting.OutdoorAmbient = originalOutdoorAmbient
    Lighting.FogEnd = originalFogEnd
    if alwaysDaySetter then alwaysDaySetter(false, false) end
    if alwaysNightSetter then alwaysNightSetter(false, false) end
    if setNoShadows then setNoShadows(false, false) end
    if setFullBright then setFullBright(false, false) end
    if setFogDistance then setFogDistance(false, false) end
    notify("Lighting restored", "Your original local lighting values have been restored.")
end)

local function tryPing()
    local ping = ReplicatedStorage:FindFirstChild("TestPing")
    if ping and ping:IsA("RemoteFunction") then pcall(function() ping:InvokeServer() end) end
end

local function triggerStorePurchase(storeName)
    local storeId = STORE_IDS[storeName]
    if not storeId then return false, "No purchase ID mapping is known for store " .. tostring(storeName) .. "." end
    local npcFolder = ReplicatedStorage:FindFirstChild("NPCDialog")
    local playerChatted = npcFolder and npcFolder:FindFirstChild("PlayerChatted")
    if not playerChatted or not playerChatted:IsA("RemoteFunction") then
        return false, "ReplicatedStorage.NPCDialog.PlayerChatted was not found."
    end
    local ok, result = pcall(function()
        return playerChatted:InvokeServer({ID = storeId}, "ConfirmPurchase")
    end)
    if not ok then return false, "Store purchase interaction failed: " .. tostring(result) end
    return true
end

local function buyOneBlueprint(entry, originalCFrame)
    local stores = getStoreFolder()
    local shopItems = getShopItemsFolder()
    if not stores or not shopItems then return false, "Workspace.Stores.ShopItems is missing." end

    local model = entry.Model
    if not model or not model.Parent or not model:IsDescendantOf(shopItems) then
        model = nil
        for _, candidate in ipairs(shopItems:GetChildren()) do
            if candidate:IsA("Model") then
                local nameValue = candidate:FindFirstChild("BoxItemName")
                local typeValue = candidate:FindFirstChild("Type")
                local owner = candidate:FindFirstChild("Owner")
                if nameValue and tostring(nameValue.Value) == entry.Name and typeValue and tostring(typeValue.Value) == "Blueprint" and owner and owner.Value == nil then
                    model = candidate
                    break
                end
            end
        end
    end
    if not model then return false, "Blueprint stock for " .. entry.Name .. " is no longer available." end

    local counter, store = findNearestCounter(model)
    if not counter or not store then return false, "Could not find the correct store counter for " .. entry.Name .. "." end
    if store.Name ~= entry.StoreName then return false, "The closest counter changed; skipping to avoid purchasing from the wrong store." end

    local primary = model:FindFirstChild("Main")
    if primary and not primary:IsA("BasePart") then primary = nil end
    primary = primary or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
    if not primary then return false, "Blueprint box " .. entry.Name .. " has no Main/BasePart." end
    if not model.PrimaryPart then pcall(function() model.PrimaryPart = primary end) end
    local originalItemCFrame = model:GetPivot()

    local _, _, root = getCharacter()
    if not root then return false, "Character is not loaded." end
    local interaction = ReplicatedStorage:FindFirstChild("Interaction")
    local drag = interaction and interaction:FindFirstChild("ClientIsDragging")
    local interact = interaction and interaction:FindFirstChild("ClientInteracted")
    if not drag then return false, "Interaction.ClientIsDragging was not found." end

    -- Move to the actual counter for this ShopItems box, repeating the drag
    -- ownership request while the client updates the model's pivot.
    root.CFrame = CFrame.new(primary.Position + Vector3.new(5, 2, 5))
    tryPing()
    task.wait(0.15)
    local counterTop = counter.CFrame * CFrame.new(0, counter.Size.Y / 2 + primary.Size.Y / 2, 0)
    local dragOk, dragErr = pcall(function()
        for _ = 1, 24 do
            if State.stopBlueprints then return end
            drag:FireServer(model)
            model:PivotTo(counterTop)
            task.wait()
        end
        drag:FireServer(model)
    end)
    if not dragOk then return false, "Could not move blueprint box to its counter: " .. tostring(dragErr) end
    if State.stopBlueprints then return false, "Stopped by user." end

    root.CFrame = counter.CFrame * CFrame.new(0, 3, 5)
    tryPing()
    task.wait(0.2)

    -- One server confirmation is sent per item. We deliberately do not spam
    -- this call because a delayed response could otherwise double-charge.
    local purchaseOk, purchaseError = triggerStorePurchase(store.Name)
    if not purchaseOk then
        pcall(function()
            if model.Parent then drag:FireServer(model); model:PivotTo(originalItemCFrame); drag:FireServer(model) end
        end)
        return false, purchaseError
    end

    local confirmed = false
    local deadline = os.clock() + 5
    while os.clock() < deadline do
        if State.stopBlueprints then break end
        if not model.Parent or not model:IsDescendantOf(shopItems) then
            confirmed = true
            break
        end
        local owner = model:FindFirstChild("Owner")
        if owner and owner.Value == LocalPlayer then confirmed = true; break end
        task.wait(0.15)
    end
    if not confirmed then
        if model and model.Parent then
            pcall(function()
                drag:FireServer(model)
                model:PivotTo(originalItemCFrame)
                drag:FireServer(model)
            end)
        end
        if root.Parent then root.CFrame = originalCFrame end
        return false, "The server did not confirm purchase of " .. entry.Name .. ". Check your cash and the counter."
    end

    -- Some builds re-parent the bought box; others create a separate player box.
    local purchasedBox = nil
    local modelOwner = model and model:FindFirstChild("Owner")
    if model and model.Parent and (not model:IsDescendantOf(shopItems) or (modelOwner and modelOwner.Value == LocalPlayer)) then
        purchasedBox = model
    else
        local playerModels = Workspace:FindFirstChild("PlayerModels")
        if playerModels then
            for _, candidate in ipairs(playerModels:GetDescendants()) do
                if candidate:IsA("Model") then
                    local owner = candidate:FindFirstChild("Owner")
                    local purchasedName = candidate:FindFirstChild("PurchasedBoxItemName") or candidate:FindFirstChild("BoxItemName")
                    if owner and owner.Value == LocalPlayer and purchasedName and tostring(purchasedName.Value) == entry.Name then
                        purchasedBox = candidate
                        break
                    end
                end
            end
        end
    end

    -- Bring the purchased box back and open it where the user started.
    if purchasedBox and purchasedBox.Parent then
        pcall(function()
            drag:FireServer(purchasedBox)
            purchasedBox:PivotTo(originalCFrame * CFrame.new(0, 3, 0))
            drag:FireServer(purchasedBox)
        end)
        task.wait(0.15)
        if interact and purchasedBox.Parent then
            pcall(function() interact:FireServer(purchasedBox, "Open box") end)
            task.wait(0.25)
            local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
            local character, humanoid = getCharacter()
            if backpack and humanoid then
                local blueprintTool = backpack:FindFirstChild("BlueprintTool") or (character and character:FindFirstChild("BlueprintTool"))
                if blueprintTool and blueprintTool:IsA("Tool") then pcall(function() humanoid:EquipTool(blueprintTool) end) end
            end
        end
    end
    if root.Parent then root.CFrame = originalCFrame end
    return true, "Purchased " .. entry.Name .. "."
end

addHeader(BuyPage, "Blueprint store automation")
addInfo(BuyPage, "Scans Workspace.Stores.ShopItems for stocked blueprint boxes, finds the nearest shop counter, buys one at a time and tries to open each purchased box. You need enough in-game cash.", 70)
addButton(BuyPage, "Scan available blueprints", "Lists the blueprint boxes currently spawned in the server.", function()
    local list, err = listBlueprintModels()
    if err then return notify("Blueprint scan failed", err) end
    if #list == 0 then return notify("No blueprints found", "No unowned blueprint boxes are currently visible in the stores.") end
    notify("Blueprint scan", tostring(#list) .. " stocked blueprint box(es) found.", 5)
    for i = 1, math.min(#list, 12) do print(string.format("[LT2 Blueprints] %s (%s)", list[i].Name, list[i].StoreName)) end
end)
addButton(BuyPage, "Buy All Available Blueprints", "Buys the stocked blueprints one at a time. Requires enough in-game cash.", function()
    if State.runningBlueprints then return notify("Blueprint buyer", "A purchase session is already running.") end
    local list, err = listBlueprintModels()
    if err then return notify("Blueprint buyer failed", err) end
    if #list == 0 then return notify("No blueprints found", "No available blueprint boxes are loaded in the stores.") end
    local _, _, root = getCharacter()
    if not root then return notify("Blueprint buyer failed", "Your character is not loaded.") end
    local original = root.CFrame
    State.runningBlueprints = true
    State.stopBlueprints = false
    task.spawn(function()
        local successes, failures = 0, 0
        for index, entry in ipairs(list) do
            if State.stopBlueprints then break end
            notify("Buying blueprint " .. index .. "/" .. #list, entry.Name .. " • " .. entry.StoreName, 2)
            local ok, result = buyOneBlueprint(entry, original)
            if ok then
                successes += 1
            else
                failures += 1
                notify("Blueprint skipped", result, 5)
                task.wait(0.3)
            end
            local _, _, currentRoot = getCharacter()
            if currentRoot then currentRoot.CFrame = original end
            task.wait(0.35)
        end
        local _, _, currentRoot = getCharacter()
        if currentRoot then currentRoot.CFrame = original end
        State.runningBlueprints = false
        State.stopBlueprints = false
        notify("Blueprint session finished", successes .. " purchased • " .. failures .. " failed or unavailable.", 6)
    end)
end, Color3.fromRGB(190, 145, 65))
addButton(BuyPage, "Stop blueprint buying", "Stops after the current server interaction check.", function()
    State.stopBlueprints = true
    notify("Stopping buyer", "The blueprint buyer will stop at its next check.")
end, Color3.fromRGB(185, 83, 92))

--// Player controls ------------------------------------------------------------
addHeader(PlayerPage, "Movement")
local flyToggleGetter
flyToggleGetter, flyToggleSetter = addToggle(PlayerPage, "Fly (Q to toggle)", false, function(value)
    State.fly = value
    if value then
        task.spawn(function()
            local character, humanoid, root = getCharacter()
            if not root then State.fly = false; return notify("Fly failed", "Character is not loaded.") end
            local oldPlatform = humanoid.PlatformStand
            local gyro = Instance.new("BodyGyro")
            gyro.Name = "LT2HubFlyGyro"
            gyro.P = 90000
            gyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            gyro.CFrame = root.CFrame
            gyro.Parent = root
            local velocity = Instance.new("BodyVelocity")
            velocity.Name = "LT2HubFlyVelocity"
            velocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            velocity.Velocity = Vector3.zero
            velocity.Parent = root
            humanoid.PlatformStand = true
            while State.fly and character.Parent and humanoid.Health > 0 and root.Parent do
                local camera = Workspace.CurrentCamera
                local vertical = 0
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vertical += 1 end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.C) then vertical -= 1 end
                local move = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= camera.CFrame.RightVector end
                move += Vector3.new(0, vertical, 0)
                velocity.Velocity = move.Magnitude > 0 and move.Unit * State.flySpeed or Vector3.zero
                gyro.CFrame = camera.CFrame
                task.wait()
            end
            if gyro then gyro:Destroy() end
            if velocity then velocity:Destroy() end
            if humanoid and humanoid.Parent then
                humanoid.PlatformStand = oldPlatform
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end)
        notify("Fly enabled", "WASD to move, Space to rise, Ctrl/C to descend.")
    else
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root then
            local gyro = root:FindFirstChild("LT2HubFlyGyro")
            local velocity = root:FindFirstChild("LT2HubFlyVelocity")
            if gyro then gyro:Destroy() end
            if velocity then velocity:Destroy() end
        end
        notify("Fly disabled", "Normal movement restored.")
    end
end, "Fly key: Q • WASD + Space / Ctrl")
addStepper(PlayerPage, "Fly speed", 75, 10, 300, function(value) State.flySpeed = value end)
addToggle(PlayerPage, "Noclip", false, function(value)
    State.noclip = value
    if not value then
        for part, canCollide in pairs(State.oldCollisions) do
            if part and part.Parent then pcall(function() part.CanCollide = canCollide end) end
        end
        State.oldCollisions = {}
    end
    notify("Noclip", value and "Noclip enabled." or "Collision settings restored.")
end)
addToggle(PlayerPage, "Infinite jump", false, function(value)
    State.infiniteJump = value
    notify("Infinite jump", value and "Enabled." or "Disabled.")
end)
addStepper(PlayerPage, "Walk speed", 16, 16, 100, function(value)
    State.walkSpeed = value
    local _, humanoid = getCharacter()
    if humanoid then humanoid.WalkSpeed = value end
end)
addStepper(PlayerPage, "Jump power", 50, 50, 200, function(value)
    State.jumpPower = value
    local _, humanoid = getCharacter()
    if humanoid then humanoid.UseJumpPower = true; humanoid.JumpPower = value end
end)

--// Settings ------------------------------------------------------------------
addHeader(SettingsPage, "Hub settings")
addInfo(SettingsPage, "RightShift toggles the menu. Q toggles fly. You can close the hub with the × button or unload it below.", 50)
addButton(SettingsPage, "Restore camera", "Exit any cave viewer and restore the normal camera.", restoreCamera)
addButton(SettingsPage, "Refresh tree selector", "Rescan currently visible server tree types.", function()
    treeClassOptions = getTreeClasses()
    if treeListRefresh then treeListRefresh(treeClassOptions) end
    notify("Tree selector", #treeClassOptions .. " tree classes are listed; only some may be spawned in this server.")
end)
local savedEffectStates = {}
local function restoreSavedVisualEffects()
    local restored = 0
    for effect, saved in pairs(savedEffectStates) do
        if effect and effect.Parent then
            pcall(function()
                if type(saved) == "table" then
                    effect.Density = saved.Density
                    effect.Haze = saved.Haze
                    effect.Glare = saved.Glare
                else
                    effect.Enabled = saved
                end
            end)
            restored += 1
        end
    end
    savedEffectStates = {}
    return restored
end
addButton(SettingsPage, "Disable visual effects", "Turns off local Atmosphere/Bloom/ColorCorrection/SunRays effects without deleting them.", function()
    local changed = 0
    for _, child in ipairs(Lighting:GetChildren()) do
        if child:IsA("Atmosphere") then
            if savedEffectStates[child] == nil then
                savedEffectStates[child] = {Density = child.Density, Haze = child.Haze, Glare = child.Glare}
            end
            child.Density = 0
            child.Haze = 0
            child.Glare = 0
            changed += 1
        elseif child:IsA("BloomEffect") or child:IsA("ColorCorrectionEffect") or child:IsA("SunRaysEffect") then
            if savedEffectStates[child] == nil then savedEffectStates[child] = child.Enabled end
            child.Enabled = false
            changed += 1
        end
    end
    notify("Visual effects", "Disabled " .. changed .. " local lighting effect(s). You can restore them before unloading.")
end)
addButton(SettingsPage, "Restore visual effects", "Re-enables lighting effects that were switched off by this hub.", function()
    local restored = restoreSavedVisualEffects()
    notify("Visual effects", "Restored " .. restored .. " lighting effect(s).")
end)
addToggle(SettingsPage, "RGB animation", true, function(value)
    State.rgbEnabled = value
    notify("RGB animation", value and "Animated rainbow accents enabled." or "Rainbow animation paused.")
end)
addStepper(SettingsPage, "RGB animation speed", 55, 5, 150, function(value) State.rgbSpeed = value end)
addButton(SettingsPage, "Open World controls", "Use the World tab for day/night, shadows, full bright and fog settings.", function()
    local targetPage = Pages.World
    if targetPage then
        for pageName, page in pairs(Pages) do
            page.Visible = (pageName == "World")
            local tab = TabButtons[pageName]
            if tab then
                tab.BackgroundColor3 = (pageName == "World") and Color3.fromRGB(46, 56, 83) or Color3.fromRGB(24, 28, 39)
                tab.TextColor3 = (pageName == "World") and Color3.fromRGB(245, 247, 255) or Color3.fromRGB(160, 169, 188)
            end
        end
        ActiveTab = "World"
    end
end)
addButton(SettingsPage, "Unload hub", "Stops loops, restores camera/collisions and local lighting, then removes the UI.", function()
    if unloadHub then unloadHub() end
end, Color3.fromRGB(185, 83, 92))

--// Runtime listeners ---------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, processed)
    if processed or UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == State.guiKey then
        Main.Visible = not Main.Visible
    elseif input.KeyCode == State.flyKey then
        if flyToggleSetter then flyToggleSetter(not State.fly) end
    elseif input.KeyCode == Enum.KeyCode.End then
        unloadHub()
    end
end)

UserInputService.JumpRequest:Connect(function()
    if State.infiniteJump then
        local _, humanoid = getCharacter()
        if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

RunService.Stepped:Connect(function()
    if State.closed then return end
    if State.noclip then
        local character = LocalPlayer.Character
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    if State.oldCollisions[part] == nil then State.oldCollisions[part] = part.CanCollide end
                    part.CanCollide = false
                end
            end
        end
    end
    local _, humanoid = getCharacter()
    if humanoid then
        if State.walkSpeed and humanoid.WalkSpeed ~= State.walkSpeed then humanoid.WalkSpeed = State.walkSpeed end
        if State.jumpPower and humanoid.UseJumpPower and humanoid.JumpPower ~= State.jumpPower then humanoid.JumpPower = State.jumpPower end
    end
    if State.alwaysDay then Lighting.ClockTime = 13 end
    if State.alwaysNight then Lighting.ClockTime = 0 end
end)

unloadHub = function()
    if State.closed then return end
    State.closed = true
    State.fly = false
    State.stopTree = true
    State.stopBlueprints = true
    State.noclip = false
    if State.cameraSaved then
        local saved = State.cameraSaved
        local camera = Workspace.CurrentCamera
        if camera then
            camera.CameraType = saved.CameraType
            camera.CameraSubject = saved.CameraSubject
            camera.CFrame = saved.CFrame
            camera.FieldOfView = saved.FieldOfView
        end
        State.cameraSaved = nil
    end
    for part, canCollide in pairs(State.oldCollisions) do
        if part and part.Parent then pcall(function() part.CanCollide = canCollide end) end
    end
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        local gyro = root:FindFirstChild("LT2HubFlyGyro")
        local velocity = root:FindFirstChild("LT2HubFlyVelocity")
        if gyro then gyro:Destroy() end
        if velocity then velocity:Destroy() end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.PlatformStand = false end
    end
    Lighting.ClockTime = originalClockTime
    Lighting.GlobalShadows = originalGlobalShadows
    Lighting.Brightness = originalBrightness
    Lighting.Ambient = originalAmbient
    Lighting.OutdoorAmbient = originalOutdoorAmbient
    Lighting.FogEnd = originalFogEnd
    restoreSavedVisualEffects()
    if ScreenGui then ScreenGui:Destroy() end
end
Close.Activated:Connect(unloadHub)

-- Animate the multicolour accent without a separate forever coroutine.
local rainbowConnection
rainbowConnection = RunService.RenderStepped:Connect(function(dt)
    if State.closed or not AccentGradient.Parent then
        if rainbowConnection then rainbowConnection:Disconnect() end
        return
    end
    if State.rgbEnabled then
        AccentGradient.Rotation = (AccentGradient.Rotation + dt * State.rgbSpeed) % 360
        MainStrokeGradient.Rotation = (MainStrokeGradient.Rotation + dt * State.rgbSpeed * 0.65) % 360
    end
end)

-- Ensure Home is visible on first load.
if Pages.Home then
    ScreenGui.Enabled = true
    Main.Visible = true
    Content.Visible = true
    Sidebar.Visible = true
    Pages.Home.Visible = true
    ActiveTab = "Home"
    if TabButtons.Home then
        TabButtons.Home.BackgroundColor3 = Color3.fromRGB(46, 56, 83)
        TabButtons.Home.TextColor3 = Color3.fromRGB(245, 247, 255)
    end
end
notify("LT2 Utility Hub loaded", "RightShift opens/closes the menu. Q toggles fly.", 5)
print("[LT2 Utility Hub] Loaded successfully. Build: Neon UI / One-Click Bring Tree.")
