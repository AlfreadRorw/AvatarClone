-- ================================================
-- PERMANENT/TARGET.LUA - Pilih Player Target
-- ================================================

local Services = _G.Services
local LocalPlayer = _G.LocalPlayer
local Firebase = _G.Firebase
local Helpers = _G.Helpers or {}

local function openTargetApp(contentArea)
    local State = _G.PremiumState
    
    local P = {
        bgCard2 = Color3.fromRGB(26, 26, 34),
        bgElevated = Color3.fromRGB(32, 32, 42),
        accent = Color3.fromRGB(168, 110, 255),
        accentGlow = Color3.fromRGB(198, 150, 255),
        green = Color3.fromRGB(80, 220, 150),
        textMain = Color3.fromRGB(240, 240, 245),
        textSub = Color3.fromRGB(150, 150, 165),
        border = Color3.fromRGB(45, 45, 58),
    }

    -- Refresh button
    local refreshBtn = Instance.new("TextButton", contentArea)
    refreshBtn.Size = UDim2.new(0.95, 0, 0, 36)
    refreshBtn.BackgroundColor3 = P.accent
    refreshBtn.Text = "Refresh Player Online"
    refreshBtn.TextColor3 = Color3.new(1, 1, 1)
    refreshBtn.Font = Enum.Font.GothamBold
    refreshBtn.TextSize = 11
    refreshBtn.AutoButtonColor = false
    Helpers.corner(refreshBtn, 10)

    local listContainer = Instance.new("Frame", contentArea)
    listContainer.Size = UDim2.new(0.95, 0, 0, 0)
    listContainer.AutomaticSize = Enum.AutomaticSize.Y
    listContainer.BackgroundTransparency = 1

    local listLayout = Instance.new("UIListLayout", listContainer)
    listLayout.Padding = UDim.new(0, 6)

    local function loadPlayers()
        for _, c in ipairs(listContainer:GetChildren()) do
            if not c:IsA("UIListLayout") then c:Destroy() end
        end

        task.spawn(function()
            local ok, players = pcall(function() return Firebase.GetOnlinePlayers() end)
            if not ok or not players then return end

            for uidStr, pData in pairs(players) do
                local uid = tonumber(uidStr)
                if uid == LocalPlayer.UserId then continue end

                local isOnline = pData.isOnline
                if pData.lastSeen and (os.time() - pData.lastSeen) > 120 then isOnline = false end
                if not isOnline then continue end

                local isSelected = (State.selectedTargetId == uid)

                local pRow = Instance.new("TextButton", listContainer)
                pRow.Size = UDim2.new(1, 0, 0, 54)
                pRow.BackgroundColor3 = isSelected and P.accent or P.bgCard2
                pRow.AutoButtonColor = false
                Helpers.corner(pRow, 12)
                Helpers.stroke(pRow, isSelected and P.accentGlow or P.border, isSelected and 2 or 1, isSelected and 0 or 0.4)

                local av = Instance.new("ImageLabel", pRow)
                av.Size = UDim2.new(0, 38, 0, 38)
                av.Position = UDim2.new(0, 8, 0.5, -19)
                av.BackgroundColor3 = P.bgElevated
                av.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. uidStr .. "&width=100&height=100&format=png"
                Helpers.corner(av, 100)

                local nameLbl = Instance.new("TextLabel", pRow)
                nameLbl.Size = UDim2.new(1, -60, 0, 20)
                nameLbl.Position = UDim2.new(0, 54, 0, 8)
                nameLbl.BackgroundTransparency = 1
                nameLbl.Text = pData.displayName or pData.username or "User"
                nameLbl.TextColor3 = P.textMain
                nameLbl.Font = Enum.Font.GothamBold
                nameLbl.TextSize = 12
                nameLbl.TextXAlignment = Enum.TextXAlignment.Left

                local mapLbl = Instance.new("TextLabel", pRow)
                mapLbl.Size = UDim2.new(1, -60, 0, 14)
                mapLbl.Position = UDim2.new(0, 54, 0, 30)
                mapLbl.BackgroundTransparency = 1
                mapLbl.Text = pData.mapName or "Unknown Map"
                mapLbl.TextColor3 = P.textSub
                mapLbl.Font = Enum.Font.Gotham
                mapLbl.TextSize = 9
                mapLbl.TextXAlignment = Enum.TextXAlignment.Left

                if isSelected then
                    local check = Instance.new("TextLabel", pRow)
                    check.Size = UDim2.new(0, 20, 0, 20)
                    check.Position = UDim2.new(1, -26, 0.5, -10)
                    check.BackgroundTransparency = 1
                    check.Text = "v"
                    check.TextColor3 = P.accentGlow
                    check.Font = Enum.Font.GothamBlack
                    check.TextSize = 14
                end

                pRow.MouseButton1Click:Connect(function()
                    State.selectedTargetId = uid
                    State.selectedTargetName = pData.displayName or pData.username or tostring(uid)
                    _G.showDynamicNotification("Target: " .. State.selectedTargetName, P.accent)
                    loadPlayers()
                end)
            end
        end)
    end

    refreshBtn.MouseButton1Click:Connect(loadPlayers)
    loadPlayers()
end

_G.PremiumSubApps = _G.PremiumSubApps or {}
_G.PremiumSubApps["Target"] = {
    name = "Target",
    iconName = "Target",
    loadFunc = openTargetApp,
}

print("[Permanent/Target] Loaded!")