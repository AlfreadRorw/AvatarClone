-- ================================================
-- PERMANENT/TARGET.LUA - Pilih Player Target (Fixed)
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
        accentSoft = Color3.fromRGB(120, 80, 200),
        accentGlow = Color3.fromRGB(198, 150, 255),
        green = Color3.fromRGB(80, 220, 150),
        textMain = Color3.fromRGB(240, 240, 245),
        textSub = Color3.fromRGB(150, 150, 165),
        textFaint = Color3.fromRGB(95, 95, 110),
        border = Color3.fromRGB(45, 45, 58),
    }

    -- ==================== REFRESH BUTTON ====================
    local refreshBtn = Instance.new("TextButton", contentArea)
    refreshBtn.Size = UDim2.new(0.95, 0, 0, 38)
    refreshBtn.BackgroundColor3 = P.accent
    refreshBtn.Text = "Refresh Player Online"
    refreshBtn.TextColor3 = Color3.new(1, 1, 1)
    refreshBtn.Font = Enum.Font.GothamBold
    refreshBtn.TextSize = 11
    refreshBtn.AutoButtonColor = false
    Helpers.corner(refreshBtn, 10)
    if Helpers.pressFX then Helpers.pressFX(refreshBtn) end

    -- ==================== PLAYER LIST CONTAINER ====================
    local listContainer = Instance.new("Frame", contentArea)
    listContainer.Size = UDim2.new(0.95, 0, 0, 0)
    listContainer.AutomaticSize = Enum.AutomaticSize.Y
    listContainer.BackgroundTransparency = 1

    local listLayout = Instance.new("UIListLayout", listContainer)
    listLayout.Padding = UDim.new(0, 8)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- ==================== LOADING INDICATOR ====================
    local loadingLbl = Instance.new("TextLabel", listContainer)
    loadingLbl.Size = UDim2.new(1, 0, 0, 40)
    loadingLbl.BackgroundTransparency = 1
    loadingLbl.Text = "Loading players..."
    loadingLbl.TextColor3 = P.textFaint
    loadingLbl.Font = Enum.Font.Gotham
    loadingLbl.TextSize = 11
    loadingLbl.TextXAlignment = Enum.TextXAlignment.Center

    -- ==================== LOAD PLAYERS ====================
    local function loadPlayers()
        -- Clear list (kecuali UIListLayout)
        for _, child in ipairs(listContainer:GetChildren()) do
            if not child:IsA("UIListLayout") then
                child:Destroy()
            end
        end

        -- Loading indicator
        local loading = Instance.new("TextLabel", listContainer)
        loading.Size = UDim2.new(1, 0, 0, 40)
        loading.BackgroundTransparency = 1
        loading.Text = "Fetching online players..."
        loading.TextColor3 = P.textFaint
        loading.Font = Enum.Font.Gotham
        loading.TextSize = 11
        loading.TextXAlignment = Enum.TextXAlignment.Center

        task.spawn(function()
            -- Ambil data dari Firebase
            local ok, players = pcall(function()
                return Firebase.GetOnlinePlayers()
            end)

            -- Hapus loading
            pcall(function() loading:Destroy() end)

            if not ok or not players or type(players) ~= "table" then
                local empty = Instance.new("TextLabel", listContainer)
                empty.Size = UDim2.new(1, 0, 0, 60)
                empty.BackgroundTransparency = 1
                empty.Text = "Tidak ada player online.\n\nMinta mereka untuk menjalankan script ini juga."
                empty.TextColor3 = P.textFaint
                empty.Font = Enum.Font.Gotham
                empty.TextSize = 11
                empty.TextWrapped = true
                empty.TextXAlignment = Enum.TextXAlignment.Center
                return
            end

            local renderedCount = 0

            for uidStr, pData in pairs(players) do
                if type(pData) == "table" then
                    local uid = tonumber(uidStr)
                    if uid and uid ~= LocalPlayer.UserId then
                        -- Cek online status
                        local isOnline = pData.isOnline ~= false
                        if pData.lastSeen and (os.time() - tonumber(pData.lastSeen or 0)) > 120 then
                            isOnline = false
                        end

                        if isOnline then
                            renderedCount = renderedCount + 1
                            local isSelected = (State.selectedTargetId == uid)

                            -- ==================== PLAYER ROW ====================
                            local pRow = Instance.new("TextButton", listContainer)
                            pRow.Size = UDim2.new(1, 0, 0, 56)
                            pRow.BackgroundColor3 = isSelected and P.accentSoft or P.bgCard2
                            pRow.AutoButtonColor = false
                            pRow.LayoutOrder = renderedCount
                            Helpers.corner(pRow, 12)
                            Helpers.stroke(pRow, isSelected and P.accentGlow or P.border, isSelected and 2 or 1, isSelected and 0 or 0.4)

                            -- Avatar
                            local avatar = Instance.new("ImageLabel", pRow)
                            avatar.Size = UDim2.new(0, 40, 0, 40)
                            avatar.Position = UDim2.new(0, 8, 0.5, -20)
                            avatar.BackgroundColor3 = P.bgElevated
                            avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. uidStr .. "&width=100&height=100&format=png"
                            Helpers.corner(avatar, 100)

                            -- Online dot
                            local onlineDot = Instance.new("Frame", avatar)
                            onlineDot.Size = UDim2.new(0, 10, 0, 10)
                            onlineDot.Position = UDim2.new(1, -8, 1, -8)
                            onlineDot.BackgroundColor3 = P.green
                            Helpers.corner(onlineDot, 100)
                            Helpers.stroke(onlineDot, P.bgCard2, 2, 0)

                            -- Display Name
                            local nameLbl = Instance.new("TextLabel", pRow)
                            nameLbl.Size = UDim2.new(1, -70, 0, 20)
                            nameLbl.Position = UDim2.new(0, 56, 0, 8)
                            nameLbl.BackgroundTransparency = 1
                            nameLbl.Text = pData.displayName or pData.username or "User"
                            nameLbl.TextColor3 = P.textMain
                            nameLbl.Font = Enum.Font.GothamBold
                            nameLbl.TextSize = 12
                            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

                            -- Map name
                            local mapLbl = Instance.new("TextLabel", pRow)
                            mapLbl.Size = UDim2.new(1, -70, 0, 14)
                            mapLbl.Position = UDim2.new(0, 56, 0, 30)
                            mapLbl.BackgroundTransparency = 1
                            mapLbl.Text = pData.mapName or "Unknown Map"
                            mapLbl.TextColor3 = P.textSub
                            mapLbl.Font = Enum.Font.Gotham
                            mapLbl.TextSize = 9
                            mapLbl.TextXAlignment = Enum.TextXAlignment.Left
                            mapLbl.TextTruncate = Enum.TextTruncate.AtEnd

                            -- Selected checkmark
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

                            -- Click to select
                            pRow.MouseButton1Click:Connect(function()
                                State.selectedTargetId = uid
                                State.selectedTargetName = pData.displayName or pData.username or tostring(uid)
                                _G.showDynamicNotification("Target: " .. State.selectedTargetName, P.accentGlow)
                                loadPlayers() -- Refresh untuk update highlight
                            end)
                        end
                    end
                end
            end

            -- Empty state
            if renderedCount == 0 then
                local empty = Instance.new("TextLabel", listContainer)
                empty.Size = UDim2.new(1, 0, 0, 60)
                empty.BackgroundTransparency = 1
                empty.Text = "Tidak ada player online.\n\nMinta mereka untuk menjalankan script ini juga."
                empty.TextColor3 = P.textFaint
                empty.Font = Enum.Font.Gotham
                empty.TextSize = 11
                empty.TextWrapped = true
                empty.TextXAlignment = Enum.TextXAlignment.Center
            end
        end)
    end

    -- Refresh button click
    refreshBtn.MouseButton1Click:Connect(loadPlayers)

    -- Initial load
    loadPlayers()
end

-- Register sub-app
_G.PremiumSubApps = _G.PremiumSubApps or {}
_G.PremiumSubApps["Target"] = {
    name = "Target",
    iconName = "Target",
    loadFunc = openTargetApp,
}

print("[Permanent/Target] Loaded!")