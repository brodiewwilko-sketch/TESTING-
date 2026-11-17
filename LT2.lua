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
-- KEY INPUT
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
            notify("Keybind changed", input.KeyCode.Name)
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
-- CLEANUP
--========================================================

local function cleanup()
    if destroyed then return end
    destroyed = true

    if flying then stopFly(true) end
    if freecam then stopFreecam(true) end

    if rgbConnection then
        rgbConnection:Disconnect()
        rgbConnection = nil
    end

    for _, connection in ipairs(connections) do
        pcall(function() connection:Disconnect() end)
    end

    clearHighlight()
    UIS.MouseBehavior = Enum.MouseBehavior.Default

    if gui then gui:Destroy() end
    _G.LT2NexusCleanup = nil
end

_G.LT2NexusCleanup = cleanup
closeButton.MouseButton1Click:Connect(cleanup)

--========================================================
-- START
--========================================================

savedPosition = getRoot().CFrame
showTab("Wood")
notify("NEXUS HUB", "Loaded. Menu: Right Shift | Fly: Q")
print("[LT2 Nexus Hub] Loaded successfully.")
