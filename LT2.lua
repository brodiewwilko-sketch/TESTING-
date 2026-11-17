
--========================================================
-- LT2 NEXUS HUB | DELTA EXECUTOR
-- Complete replacement
--========================================================

if _G.LT2NexusCleanup then
    pcall(_G.LT2NexusCleanup)
end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local MENU_KEY = Enum.KeyCode.RightShift
local FLY_KEY = Enum.KeyCode.Q

local flySpeed = 65
local treeAmount = 1
local selectedTreeClass = nil
local savedPosition = nil

local flying = false
local freecam = false
local capturingKey = nil
local rgbEnabled = true

local flyConnection
local freecamConnection
local rgbConnection
local selectedHighlight

local connections = {}

local function track(connection)
    table.insert(connections, connection)
    return connection
end

local function notify(title, message)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = tostring(message),
            Duration = 4
        })
    end)
end

local function getCharacter()
    return Player.Character or Player.CharacterAdded:Wait()
end

local function getRoot()
    return getCharacter():WaitForChild("HumanoidRootPart")
end

local function savePosition()
    savedPosition = getRoot().CFrame
    notify("Position saved", "Your position has been saved.")
end

local function returnPosition()
    if not savedPosition then
        notify("Error", "Save a position first.")
        return
    end

    getRoot().CFrame = savedPosition
    notify("Position", "Returned to saved position.")
end

--========================================================
-- GUI
--========================================================

local parent = (gethui and gethui()) or game:GetService("CoreGui")

local old = parent:FindFirstChild("LT2NexusHub")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "LT2NexusHub"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = parent

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(700, 490)
main.Position = UDim2.new(0.5, -350, 0.5, -245)
main.BackgroundColor3 = Color3.fromRGB(16, 18, 25)
main.BorderSizePixel = 0
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 13)

local stroke = Instance.new("UIStroke")
stroke.Thickness = 1.5
stroke.Color = Color3.fromRGB(120, 80, 255)
stroke.Parent = main

local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 58)
top.BackgroundColor3 = Color3.fromRGB(23, 25, 36)
top.BorderSizePixel = 0
top.Parent = main

Instance.new("UICorner", top).CornerRadius = UDim.new(0, 13)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -100, 0, 28)
title.Position = UDim2.fromOffset(18, 7)
title.BackgroundTransparency = 1
title.Text = "N E X U S   |   L U M B E R   T Y C O O N   2"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = top

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -100, 0, 17)
subtitle.Position = UDim2.fromOffset(19, 34)
subtitle.BackgroundTransparency = 1
subtitle.Text = "UTILITY HUB  •  DELTA EDITION"
subtitle.TextColor3 = Color3.fromRGB(145, 150, 170)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 10
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = top

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(34, 32)
close.Position = UDim2.new(1, -45, 0, 12)
close.BackgroundColor3 = Color3.fromRGB(190, 55, 75)
close.Text = "×"
close.TextColor3 = Color3.new(1, 1, 1)
close.Font = Enum.Font.GothamBold
close.TextSize = 22
close.Parent = top
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 8)

local sidebar = Instance.new("Frame")
sidebar.Position = UDim2.fromOffset(0, 58)
sidebar.Size = UDim2.new(0, 160, 1, -58)
sidebar.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
sidebar.BorderSizePixel = 0
sidebar.Parent = main

local content = Instance.new("ScrollingFrame")
content.Position = UDim2.fromOffset(174, 72)
content.Size = UDim2.new(1, -188, 1, -86)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 3
content.ScrollBarImageColor3 = Color3.fromRGB(130, 100, 255)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.CanvasSize = UDim2.new()
content.Parent = main

local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 9)
contentLayout.Parent = content

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 5)
padding.Parent = content

local accent = Color3.fromRGB(135, 95, 255)
local currentTab = "Wood"

local function corner(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = object
end

local function clearContent()
    for _, item in ipairs(content:GetChildren()) do
        if item:IsA("GuiObject") and item ~= contentLayout and item ~= padding then
            item:Destroy()
        end
    end
end

local function addLabel(text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -8, 0, 28)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = accent
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = content
    return label
end

local function addButton(text, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -8, 0, 38)
    button.BackgroundColor3 = Color3.fromRGB(32, 35, 47)
    button.Text = text
    button.TextColor3 = Color3.fromRGB(235, 237, 245)
    button.Font = Enum.Font.GothamSemibold
    button.TextSize = 12
    button.AutoButtonColor = true
    button.Parent = content
    corner(button, 8)

    local line = Instance.new("UIStroke")
    line.Color = Color3.fromRGB(55, 58, 75)
    line.Thickness = 1
    line.Parent = button

    button.MouseButton1Click:Connect(function()
        local ok, err = pcall(callback)
        if not ok then
            notify("Feature error", err)
        end
    end)

    return button
end

local function addSlider(labelText, minValue, maxValue, initialValue, callback)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, -8, 0, 65)
    holder.BackgroundColor3 = Color3.fromRGB(27, 30, 41)
    holder.Parent = content
    corner(holder, 8)

    local label = Instance.new("TextLabel")
    label.Position = UDim2.fromOffset(10, 5)
    label.Size = UDim2.new(1, -20, 0, 23)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = holder

    local bar = Instance.new("Frame")
    bar.Position = UDim2.fromOffset(10, 39)
    bar.Size = UDim2.new(1, -20, 0, 7)
    bar.BackgroundColor3 = Color3.fromRGB(55, 58, 72)
    bar.Parent = holder
    corner(bar, 5)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((initialValue-minValue)/(maxValue-minValue), 0, 1, 0)
    fill.BackgroundColor3 = accent
    fill.Parent = bar
    corner(fill, 5)

    local dragging = false

    local function update(x)
        local percent = math.clamp(
            (x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X,
            0, 1
        )

        local value = math.floor(minValue + percent * (maxValue-minValue) + 0.5)
        fill.Size = UDim2.new(percent, 0, 1, 0)
        label.Text = labelText .. "  |  " .. value
        callback(value)
    end

    label.Text = labelText .. "  |  " .. initialValue

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(input.Position.X)
        end
    end)

    track(UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input.Position.X)
        end
    end))

    track(UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))
end

--========================================================
-- RGB ANIMATION
--========================================================

rgbConnection = RunService.RenderStepped:Connect(function()
    if not rgbEnabled then return end

    local hue = (tick() * 0.12) % 1
    accent = Color3.fromHSV(hue, 0.75, 1)

    stroke.Color = accent
    title.TextColor3 = accent
end)

--========================================================
-- TREE DETECTION
--========================================================

local function getTreeRegions()
    local regions = {}

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "TreeRegion" then
            table.insert(regions, obj)
        end
    end

    return regions
end

local function getTreeClasses()
    local classes = {}
    local seen = {}

    for _, region in ipairs(getTreeRegions()) do
        for _, tree in ipairs(region:GetChildren()) do
            local class = tree:FindFirstChild("TreeClass")

            if class and not seen[class.Value] then
                seen[class.Value] = true
                table.insert(classes, class.Value)
            end
        end
    end

    table.sort(classes)
    return classes
end

local function findTrees(className)
    local trees = {}

    for _, region in ipairs(getTreeRegions()) do
        for _, tree in ipairs(region:GetChildren()) do
            local class = tree:FindFirstChild("TreeClass")

            if class and class.Value == className then
                table.insert(trees, tree)
            end
        end
    end

    return trees
end

local function clearHighlight()
    if selectedHighlight then
        selectedHighlight:Destroy()
        selectedHighlight = nil
    end
end

local function highlightTree(tree)
    clearHighlight()
    if not tree then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "NexusTreeHighlight"
    highlight.FillColor = accent
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.75
    highlight.Adornee = tree
    highlight.Parent = gui

    selectedHighlight = highlight
end

local function selectTree(className)
    local trees = findTrees(className)

    if #trees == 0 then
        notify("Tree search", "No " .. className .. " trees are currently spawned.")
        return
    end

    selectedTreeClass = className
    highlightTree(trees[1])

    notify("Tree selected", className .. " | " .. #trees .. " found.")
end

--========================================================
-- END TIMES TREE + LONE CAVE FREECAM
--========================================================

local function findPhantomTree()
    for _, region in ipairs(getTreeRegions()) do
        for _, tree in ipairs(region:GetChildren()) do
            local class = tree:FindFirstChild("TreeClass")
            local section = tree:FindFirstChild("WoodSection")

            if class and class.Value == "LoneCave" and section then
                return tree, section
            end
        end
    end

    return nil, nil
end

local function stopFreecam()
    freecam = false

    if freecamConnection then
        freecamConnection:Disconnect()
        freecamConnection = nil
    end

    UIS.MouseBehavior = Enum.MouseBehavior.Default
    Camera.CameraType = Enum.CameraType.Custom

    local humanoid = getCharacter():FindFirstChildOfClass("Humanoid")
    if humanoid then
        Camera.CameraSubject = humanoid
    end

    notify("Freecam", "Camera returned to your character.")
end

local function startFreecam(position, target)
    if freecam then
        stopFreecam()
    end

    freecam = true
    Camera.CameraType = Enum.CameraType.Scriptable
    UIS.MouseBehavior = Enum.MouseBehavior.LockCenter

    local cameraPosition = position
    local lookAt = target

    local initial = CFrame.lookAt(cameraPosition, lookAt)
    local pitch, yaw = initial:ToOrientation()

    local sensitivity = 0.0025
    local speed = 55

    Camera.CFrame = initial

    freecamConnection = RunService.RenderStepped:Connect(function(dt)
        if not freecam then return end

        local delta = UIS:GetMouseDelta()
        yaw = yaw - delta.X * sensitivity
        pitch = math.clamp(pitch - delta.Y * sensitivity, -1.5, 1.5)

        local rotation = CFrame.fromOrientation(pitch, yaw, 0)
        local movement = Vector3.zero

        if UIS:IsKeyDown(Enum.KeyCode.W) then
            movement += rotation.LookVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.S) then
            movement -= rotation.LookVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.A) then
            movement -= rotation.RightVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.D) then
            movement += rotation.RightVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.E) then
            movement += Vector3.yAxis
        end
        if UIS:IsKeyDown(Enum.KeyCode.Q) then
            movement -= Vector3.yAxis
        end

        if movement.Magnitude > 0 then
            cameraPosition += movement.Unit * speed * dt
        end

        Camera.CFrame = CFrame.new(cameraPosition) * rotation
    end)

    notify("Freecam", "WASD move | E up | Q down | Mouse look")
end

local function viewEndTimesTree()
    local tree, section = findPhantomTree()

    if not tree then
        notify("End Times Tree", "The Phantom tree is not spawned in this server.")
        return
    end

    highlightTree(tree)

    startFreecam(
        section.Position + Vector3.new(13, 8, 18),
        section.Position
    )
end

local function viewLoneCave()
    local tree, section = findPhantomTree()

    if not tree then
        notify("Lone Cave", "The LoneCave tree is not spawned, so its exact location cannot be found.")
        return
    end

    highlightTree(tree)

    startFreecam(
        section.Position + Vector3.new(55, 30, 55),
        section.Position
    )
end

--========================================================
-- AXES
--========================================================

local function getAxeTools()
    local result = {}

    local backpack = Player:FindFirstChildOfClass("Backpack")
    local character = getCharacter()

    for _, container in ipairs({backpack, character}) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") and tool:FindFirstChild("ToolName") then
                    table.insert(result, tool)
                end
            end
        end
    end

    return result
end

local function equipAxe(tool)
    local humanoid = getCharacter():FindFirstChildOfClass("Humanoid")

    if not humanoid then
        notify("Axe", "Character humanoid not found.")
        return
    end

    humanoid:EquipTool(tool)
    notify("Axe equipped", tool.Name)
end

--========================================================
-- FLY
--========================================================

local function stopFly()
    flying = false

    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end

    local root = getCharacter():FindFirstChild("HumanoidRootPart")

    if root then
        for _, name in ipairs({"NexusFlyVelocity", "NexusFlyGyro"}) do
            local obj = root:FindFirstChild(name)
            if obj then obj:Destroy() end
        end
    end

    notify("Fly", "Fly disabled.")
end

local function startFly()
    if flying then return end

    if freecam then
        stopFreecam()
    end

    flying = true

    local root = getRoot()

    local velocity = Instance.new("BodyVelocity")
    velocity.Name = "NexusFlyVelocity"
    velocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    velocity.Velocity = Vector3.zero
    velocity.Parent = root

    local gyro = Instance.new("BodyGyro")
    gyro.Name = "NexusFlyGyro"
    gyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    gyro.P = 9000
    gyro.Parent = root

    flyConnection = RunService.RenderStepped:Connect(function()
        if not flying or not root.Parent then return end

        local cam = workspace.CurrentCamera
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

        velocity.Velocity =
            direction.Magnitude > 0 and direction.Unit * flySpeed
            or Vector3.zero

        gyro.CFrame = cam.CFrame
    end)

    notify("Fly enabled", "WASD move | Space up | Ctrl down")
end

local function toggleFly()
    if flying then
        stopFly()
    else
        startFly()
    end
end

--========================================================
-- TELEPORTS
--========================================================

local locations = {
    "Wood R Us",
    "Land Store",
    "Volcano",
    "Cave",
    "Palm Island",
    "Spawn",
    "Fancy Furnishings",
    "Boxed Cars",
    "Furniture Store"
}

local function findLocation(name)
    local wanted = string.lower(name)

    for _, obj in ipairs(workspace:GetDescendants()) do
        if string.find(string.lower(obj.Name), wanted, 1, true) then
            if obj:IsA("BasePart") then
                return obj
            elseif obj:IsA("Model") then
                return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
            end
        end
    end
end

local function teleportToLocation(name)
    local target = findLocation(name)

    if not target then
        notify("Teleport failed", "Couldn't find " .. name)
        return
    end

    savedPosition = getRoot().CFrame
    getRoot().CFrame = target.CFrame + Vector3.new(0, 5, 0)

    notify("Teleport", "Moved to " .. name)
end

--========================================================
-- SECRET
--========================================================

local function showSecret()
    local popup = Instance.new("TextLabel")
    popup.Size = UDim2.fromOffset(380, 65)
    popup.Position = UDim2.new(0.5, -190, 0.12, 0)
    popup.BackgroundColor3 = Color3.fromRGB(25, 22, 38)
    popup.TextColor3 = accent
    popup.Text = "oliver vaughn 187 kingsway"
    popup.Font = Enum.Font.GothamBold
    popup.TextSize = 19
    popup.Parent = gui
    corner(popup, 10)

    task.delay(5, function()
        if popup and popup.Parent then
            popup:Destroy()
        end
    end)
end

--========================================================
-- TABS
--========================================================

local tabs = {
    "Wood",
    "Movement",
    "Teleports",
    "Visuals",
    "Axes",
    "Settings",
    "Misc"
}

local tabButtons = {}

local function showTab(tab)
    currentTab = tab
    clearContent()

    for name, button in pairs(tabButtons) do
        button.BackgroundColor3 =
            name == tab and Color3.fromRGB(75, 58, 125)
            or Color3.fromRGB(30, 33, 45)
    end

    if tab == "Wood" then
        addLabel("TREE MANAGEMENT")

        addButton("REFRESH TREE TYPES", function()
            showTab("Wood")
            notify("Trees", "Tree list refreshed.")
        end)

        addLabel("BRING")

        addSlider("NUMBER OF TREES", 1, 67, treeAmount, function(value)
            treeAmount = value
        end)

        addButton("BRING SELECTED TREES", function()
            if not selectedTreeClass then
                notify("Bring", "Select a tree type first.")
                return
            end

            local trees = findTrees(selectedTreeClass)

            if #trees == 0 then
                notify("Bring", "No trees of this type are spawned.")
                return
            end

            notify(
                "Bring unavailable",
                "Automated server-side chopping and moving is not implemented."
            )
        end)

        addLabel("SELECT TREE TYPE")

        local classes = getTreeClasses()

        if #classes == 0 then
            addLabel("No tree types detected in this server.")
        end

        for _, className in ipairs(classes) do
            local label = className

            addButton(
                (selectedTreeClass == label and "✓  " or "") .. label,
                function()
                    selectTree(label)
                    showTab("Wood")
                end
            )
        end

        addButton("CLEAR TREE HIGHLIGHT", function()
            clearHighlight()
            selectedTreeClass = nil
            notify("Trees", "Highlight cleared.")
        end)

    elseif tab == "Movement" then
        addLabel("MOVEMENT CONTROLS")

        addButton("TOGGLE FLY  [" .. FLY_KEY.Name .. "]", toggleFly)

        addSlider("FLY SPEED", 10, 200, flySpeed, function(value)
            flySpeed = value
        end)

        addButton("SAVE CURRENT POSITION", savePosition)
        addButton("RETURN TO SAVED POSITION", returnPosition)

    elseif tab == "Teleports" then
        addLabel("MAIN LOCATIONS")

        addButton("SAVE POSITION", savePosition)
        addButton("RETURN TO SAVED POSITION", returnPosition)

        for _, name in ipairs(locations) do
            local locationName = name

            addButton(locationName, function()
                teleportToLocation(locationName)
            end)
        end

    elseif tab == "Visuals" then
        addLabel("END TIMES VIEWERS")

        addButton("VIEW END TIMES TREE", viewEndTimesTree)
        addButton("VIEW LONE CAVE", viewLoneCave)
        addButton("RETURN CAMERA TO PLAYER", stopFreecam)

        addLabel("TREE HIGHLIGHT")

        addButton("CLEAR HIGHLIGHT", clearHighlight)

        addButton("REFRESH TREE TYPES", function()
            local classes = getTreeClasses()
            notify("Tree types", #classes .. " types detected.")
        end)

    elseif tab == "Axes" then
        addLabel("YOUR AXE INVENTORY")

        local axes = getAxeTools()

        if #axes == 0 then
            addLabel("No axes detected.")
        end

        for _, tool in ipairs(axes) do
            local selectedTool = tool
            local toolName = tool:FindFirstChild("ToolName")
            local name = toolName and toolName.Value or tool.Name

            addButton("EQUIP  " .. name, function()
                equipAxe(selectedTool)
            end)
        end

        addButton("REFRESH AXE LIST", function()
            showTab("Axes")
        end)

    elseif tab == "Settings" then
        addLabel("KEYBIND SETTINGS")

        addButton("CHANGE MENU KEY  [" .. MENU_KEY.Name .. "]", function()
            capturingKey = "Menu"
            notify("Keybind", "Press a key for the menu.")
        end)

        addButton("CHANGE FLY KEY  [" .. FLY_KEY.Name .. "]", function()
            capturingKey = "Fly"
            notify("Keybind", "Press a key for fly.")
        end)

        addLabel("APPEARANCE")

        addButton("TOGGLE RGB: " .. (rgbEnabled and "ON" or "OFF"), function()
            rgbEnabled = not rgbEnabled
            showTab("Settings")
        end)

        addButton("RESET KEYBINDS", function()
            MENU_KEY = Enum.KeyCode.RightShift
            FLY_KEY = Enum.KeyCode.Q
            showTab("Settings")
            notify("Settings", "Default keybinds restored.")
        end)

    elseif tab == "Misc" then
        addLabel("MISCELLANEOUS")

        addButton("SECRET", showSecret)

        addButton("REJOIN SERVER", function()
            TeleportService:Teleport(game.PlaceId, Player)
        end)

        addButton("RESET CHARACTER", function()
            getCharacter():BreakJoints()
        end)

        addButton("HIDE GUI", function()
            main.Visible = false
        end)

        addButton("SHOW GUI", function()
            main.Visible = true
        end)

        addLabel("PLAYER EFFECTS")

        addButton("LOCAL SPIN VISUAL", function()
            notify("Local effect", "No server-side player or base fling is included.")
        end)
    end
end

--========================================================
-- SIDEBAR
--========================================================

for i, tab in ipairs(tabs) do
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -18, 0, 39)
    button.Position = UDim2.fromOffset(9, 13 + (i-1)*47)
    button.BackgroundColor3 = Color3.fromRGB(30, 33, 45)
    button.Text = "   " .. string.upper(tab)
    button.TextColor3 = Color3.fromRGB(225, 228, 240)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 12
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.Parent = sidebar
    corner(button, 8)

    tabButtons[tab] = button

    button.MouseButton1Click:Connect(function()
        showTab(tab)
    end)
end

--========================================================
-- DRAG WINDOW
--========================================================

local dragging = false
local dragStart
local startPosition

top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPosition = main.Position
    end
end)

track(UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
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

--========================================================
-- KEYBINDS
--========================================================

track(UIS.InputBegan:Connect(function(input, processed)
    if capturingKey then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if capturingKey == "Menu" then
                MENU_KEY = input.KeyCode
            elseif capturingKey == "Fly" then
                FLY_KEY = input.KeyCode
            end

            capturingKey = nil
            notify("Keybind updated", input.KeyCode.Name)
            showTab("Settings")
        end
        return
    end

    if processed then return end

    if input.KeyCode == MENU_KEY then
        main.Visible = not main.Visible
    elseif input.KeyCode == FLY_KEY then
        toggleFly()
    end
end))

--========================================================
-- CLOSE / CLEANUP
--========================================================

local function cleanup()
    if flying then
        stopFly()
    end

    if freecam then
        stopFreecam()
    end

    if rgbConnection then
        rgbConnection:Disconnect()
    end

    for _, connection in ipairs(connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    clearHighlight()
    gui:Destroy()
    _G.LT2NexusCleanup = nil
end

_G.LT2NexusCleanup = cleanup

close.MouseButton1Click:Connect(cleanup)

--========================================================
-- STARTUP
--========================================================

savedPosition = getRoot().CFrame
showTab("Wood")

notify("NEXUS HUB", "Successfully loaded!")
print("LT2 Nexus Hub loaded successfully.")
