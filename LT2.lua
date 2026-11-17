
-- LT2 ULTIMATE UTILITY HUB
-- Client-side foundation for Roblox / Delta
-- RightShift: toggle menu | Q: toggle fly

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Settings = {
    MenuKey = Enum.KeyCode.RightShift,
    FlyKey = Enum.KeyCode.Q,
    FlySpeed = 65,
    TreeAmount = 1,
    Flying = false,
    RGB = true
}

local Connections = {}
local function track(connection)
    table.insert(Connections, connection)
    return connection
end

local function character()
    return Player.Character
end

local function root()
    local c = character()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function notify(message)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "LT2 Utility Hub",
            Text = tostring(message),
            Duration = 4
        })
    end)
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "LT2UltimateHub"
gui.ResetOnSpawn = false
gui.Parent = Player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(620, 420)
main.Position = UDim2.new(0.5, -310, 0.5, -210)
main.BackgroundColor3 = Color3.fromRGB(15, 17, 24)
main.BorderSizePixel = 0
main.Visible = true
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = main

local stroke = Instance.new("UIStroke")
stroke.Thickness = 1.5
stroke.Parent = main

local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 55)
top.BackgroundColor3 = Color3.fromRGB(23, 26, 36)
top.BorderSizePixel = 0
top.Parent = main

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 12)
topCorner.Parent = top

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -25, 1, 0)
title.Position = UDim2.fromOffset(15, 0)
title.BackgroundTransparency = 1
title.Text = "LT2  /  ULTIMATE HUB"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 19
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = top

local sidebar = Instance.new("Frame")
sidebar.Position = UDim2.fromOffset(10, 65)
sidebar.Size = UDim2.new(0, 145, 1, -75)
sidebar.BackgroundColor3 = Color3.fromRGB(20, 23, 32)
sidebar.BorderSizePixel = 0
sidebar.Parent = main

Instance.new("UICorner", sidebar).CornerRadius =
    UDim.new(0, 8)

local content = Instance.new("ScrollingFrame")
content.Position = UDim2.fromOffset(165, 68)
content.Size = UDim2.new(1, -175, 1, -80)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 3
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.Parent = main

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 9)
layout.Parent = content

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 5)
padding.PaddingLeft = UDim.new(0, 5)
padding.PaddingRight = UDim.new(0, 8)
padding.Parent = content

-- RGB
local hue = 0
track(RunService.RenderStepped:Connect(function(dt)
    if Settings.RGB then
        hue = (hue + dt * 0.16) % 1
        local colour = Color3.fromHSV(hue, 0.8, 1)
        stroke.Color = colour
    end
end))

local function clearContent()
    for _, v in ipairs(content:GetChildren()) do
        if v:IsA("GuiObject") and
            not v:IsA("UIListLayout") and
            not v:IsA("UIPadding") then
            v:Destroy()
        end
    end
end

local function section(text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -5, 0, 30)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(120, 170, 255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 15
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = content
end

local function button(text, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -5, 0, 38)
    b.BackgroundColor3 = Color3.fromRGB(32, 37, 50)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Text = text
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 13
    b.AutoButtonColor = true
    b.Parent = content
    Instance.new("UICorner", b).CornerRadius =
        UDim.new(0, 7)
    track(b.Activated:Connect(callback))
    return b
end

local function slider(label, minimum, maximum, initial, callback)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, -5, 0, 65)
    holder.BackgroundColor3 = Color3.fromRGB(26, 30, 41)
    holder.Parent = content
    Instance.new("UICorner", holder).CornerRadius =
        UDim.new(0, 7)

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -15, 0, 27)
    text.Position = UDim2.fromOffset(10, 3)
    text.BackgroundTransparency = 1
    text.TextColor3 = Color3.new(1, 1, 1)
    text.Font = Enum.Font.Gotham
    text.TextSize = 12
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Parent = holder

    local bar = Instance.new("TextButton")
    bar.Size = UDim2.new(1, -20, 0, 8)
    bar.Position = UDim2.fromOffset(10, 42)
    bar.BackgroundColor3 = Color3.fromRGB(55, 62, 80)
    bar.Text = ""
    bar.Parent = holder
    Instance.new("UICorner", bar).CornerRadius =
        UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    fill.BorderSizePixel = 0
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius =
        UDim.new(1, 0)

    local value = initial
    local function update(v)
        value = math.clamp(math.floor(v), minimum, maximum)
        local alpha = (value - minimum) / (maximum - minimum)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        text.Text = label .. ": " .. value
        callback(value)
    end

    local dragging = false
    track(bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end))
    track(UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType ==
            Enum.UserInputType.MouseMovement then
            local alpha = math.clamp(
                (input.Position.X - bar.AbsolutePosition.X) /
                bar.AbsoluteSize.X, 0, 1)
            update(minimum + alpha * (maximum - minimum))
        end
    end))
    track(UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))
    update(initial)
end

local function tab(name, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -12, 0, 35)
    b.Position = UDim2.fromOffset(6, 0)
    b.BackgroundColor3 = Color3.fromRGB(30, 35, 47)
    b.Text = name
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 12
    b.Parent = sidebar
    Instance.new("UICorner", b).CornerRadius =
        UDim.new(0, 6)
    track(b.Activated:Connect(callback))
end

-- Fly
local flyVelocity
local flyConnection

local function stopFly()
    Settings.Flying = false
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    if flyVelocity then
        flyVelocity:Destroy()
        flyVelocity = nil
    end
    local r = root()
    if r then
        r.AssemblyLinearVelocity = Vector3.zero
    end
    notify("Fly disabled")
end

local function startFly()
    local r = root()
    if not r then
        notify("Cannot fly: character not loaded")
        return
    end

    stopFly()
    Settings.Flying = true

    flyVelocity = Instance.new("BodyVelocity")
    flyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    flyVelocity.Velocity = Vector3.zero
    flyVelocity.Parent = r

    flyConnection = RunService.RenderStepped:Connect(function()
        if not Settings.Flying or not root() then
            stopFly()
            return
        end

        local cam = Workspace.CurrentCamera
        local direction = Vector3.zero

        if UIS:IsKeyDown(Enum.KeyCode.W) then
            direction += cam.CFrame.LookVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.S) then
            direction -= cam.CFrame.LookVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.A) then
            direction -= cam.CFrame.RightVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.D) then
            direction += cam.CFrame.RightVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then
            direction += Vector3.yAxis
        end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
            direction -= Vector3.yAxis
        end

        flyVelocity.Velocity =
            direction.Magnitude > 0
            and direction.Unit * Settings.FlySpeed
            or Vector3.zero
    end)
    notify("Fly enabled")
end

local function toggleFly()
    if Settings.Flying then
        stopFly()
    else
        startFly()
    end
end

-- Tree scanner
local function getTrees()
    local trees = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and
            obj:FindFirstChild("WoodSection") then
            table.insert(trees, obj)
        end
    end
    return trees
end

local function scanTrees()
    local trees = getTrees()
    notify("Found " .. #trees .. " tree models")
    return trees
end

local function bringTreeNotice()
    local trees = scanTrees()
    if #trees == 0 then
        notify("No supported trees found")
        return
    end
    notify("Tree scanner ready. Automated server chopping requires verified LT2 server interactions.")
end

-- Teleport helper
local function teleportTo(position)
    local r = root()
    if not r then
        notify("Teleport failed: character unavailable")
        return
    end
    r.CFrame = CFrame.new(position + Vector3.new(0, 4, 0))
end

-- Tabs
local function home()
    clearContent()
    section("OVERVIEW")
    button("Toggle Fly (Q)", toggleFly)
    button("Scan all loaded trees", scanTrees)
    button("Show current position", function()
        local r = root()
        if r then
            notify(tostring(r.Position))
        else
            notify("Character unavailable")
        end
    end)
    section("STATUS")
    button("Refresh diagnostics", function()
        notify("Character: " .. (character() and "Loaded" or "Missing") ..
            " | Trees: " .. #getTrees())
    end)
end

local function bring()
    clearContent()
    section("TREE COLLECTION")
    slider("Trees to collect", 1, 67, Settings.TreeAmount,
        function(v)
            Settings.TreeAmount = v
        end)
    button("Scan available trees", scanTrees)
    button("Bring selected trees", bringTreeNotice)
    section("INFORMATION")
    button("Why isn't chopping working?", function()
        notify("Tree cutting requires valid server-authorized axe interactions.")
    end)
end

local function locations()
    clearContent()
    section("LOCATION TOOLS")
    button("Save current position", function()
        local r = root()
        if r then
            Settings.SavedPosition = r.Position
            notify("Position saved")
        end
    end)
    button("Return to saved position", function()
        if Settings.SavedPosition then
            teleportTo(Settings.SavedPosition)
        else
            notify("No saved position")
        end
    end)
    section("CAVE VIEWERS")
    button("Scan End Times cave", function()
        notify("Cave scan: searching loaded workspace objects")
        local found = 0
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if string.find(string.lower(obj.Name), "end times") or
                string.find(string.lower(obj.Name), "cave") then
                found += 1
            end
        end
        notify("Matching objects: " .. found)
    end)
    button("Scan Lone Cave", function()
        local found = 0
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if string.find(string.lower(obj.Name), "lone") and
                string.find(string.lower(obj.Name), "cave") then
                found += 1
            end
        end
        notify("Lone Cave matches: " .. found)
    end)
end

local function settings()
    clearContent()
    section("CUSTOMISATION")
    button("Toggle RGB", function()
        Settings.RGB = not Settings.RGB
        notify("RGB: " .. tostring(Settings.RGB))
    end)
    slider("Fly speed", 10, 150, Settings.FlySpeed,
        function(v)
            Settings.FlySpeed = v
        end)
    button("Change menu key", function()
        notify("Press a new key")
        Settings.WaitingForMenuKey = true
    end)
    button("Change fly key", function()
        notify("Press a new key")
        Settings.WaitingForFlyKey = true
    end)
    section("DEFAULT CONTROLS")
    button("Menu: Right Shift", function()
        Settings.MenuKey = Enum.KeyCode.RightShift
        notify("Menu key reset")
    end)
    button("Fly: Q", function()
        Settings.FlyKey = Enum.KeyCode.Q
        notify("Fly key reset")
    end)
end

local function misc()
    clearContent()
    section("MISCELLANEOUS")
    button("Secret", function()
        notify("Oliver Vaughn 187 Kingsway")
    end)
    button("Refresh character", function()
        notify("Character: " .. (character() and "Loaded" or "Missing"))
    end)
    button("Stop fly", stopFly)
end

local sideLayout = Instance.new("UIListLayout")
sideLayout.Padding = UDim.new(0, 7)
sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sideLayout.Parent = sidebar

tab("Home", home)
tab("Bring", bring)
tab("Locations", locations)
tab("Settings", settings)
tab("Misc", misc)

home()

-- Keyboard controls
track(UIS.InputBegan:Connect(function(input, processed)
    if processed then return end

    if Settings.WaitingForMenuKey then
        Settings.MenuKey = input.KeyCode
        Settings.WaitingForMenuKey = false
        notify("Menu key updated")
        return
    end

    if Settings.WaitingForFlyKey then
        Settings.FlyKey = input.KeyCode
        Settings.WaitingForFlyKey = false
        notify("Fly key updated")
        return
    end

    if input.KeyCode == Settings.MenuKey then
        main.Visible = not main.Visible
    elseif input.KeyCode == Settings.FlyKey then
        toggleFly()
    end
end))

-- Drag GUI
local dragging, dragStart, startPosition

track(top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPosition = main.Position
    end
end))

track(UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType ==
        Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end))

track(UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end))

track(Player.CharacterAdded:Connect(function()
    if Settings.Flying then
        stopFly()
    end
end))

notify("LT2 Ultimate Hub loaded")
