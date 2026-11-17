
--========================================================
-- NEXUS HUB - IMPROVED LT2 WAYPOINTS
--========================================================

local locations = {
    ["Spawn"] = CFrame.new(155, 5, 74),
    ["Wood R Us"] = CFrame.new(265, 5, 57),
    ["Land Store"] = CFrame.new(258, 5, -99),
    ["Link's Logic"] = CFrame.new(4607, 9, -798),
    ["Cave"] = CFrame.new(3581, -177, 430),
    ["Volcano"] = CFrame.new(-1585, 625, 1140),
    ["Swamp"] = CFrame.new(-1209, 138, -801),
    ["Palm Island"] = CFrame.new(2549, 5, -42),
    ["Fancy Furnishings"] = CFrame.new(491, 13, -1720),
    ["Boxed Cars"] = CFrame.new(509, 5, -1463),
    ["Fine Arts Shop"] = CFrame.new(5207, -156, 719),
    ["Bob's Shack"] = CFrame.new(260, 10, -2542),
    ["Dock"] = CFrame.new(1114, 3, -197),
    ["Bridge"] = CFrame.new(113, 15, -977),
    ["End Times"] = CFrame.new(113, -204, -951),
    ["Shrine of Sight"] = CFrame.new(-1600, 205, 919),
    ["The Den"] = CFrame.new(323, 49, 1930),
    ["Volcano Win"] = CFrame.new(-1675, 358, 1476),
    ["Ski Lodge"] = CFrame.new(1244, 66, 2306),
    ["Strange Man"] = CFrame.new(1061, 20, 1131),
    ["Frost Tree"] = CFrame.new(1448, 413, 3185),
    ["SnowGlow Tree"] = CFrame.new(-1105, -6, -894)
}

local function teleportToLocation(name)
    local destination = locations[name]

    if not destination then
        notify("Teleport error", "No waypoint exists for " .. tostring(name))
        return
    end

    local character = Player.Character
    if not character then
        notify("Teleport error", "Character is not loaded.")
        return
    end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then
        notify("Teleport error", "HumanoidRootPart is missing.")
        return
    end

    savedPosition = root.CFrame

    local success, err = pcall(function()
        character:PivotTo(destination + Vector3.new(0, 5, 0))
    end)

    if not success then
        notify("Teleport error", tostring(err))
        return
    end

    task.wait(0.35)

    notify(
        "Waypoint",
        "Teleport attempted: " .. name ..
        ". The server may correct the position."
    )
end
