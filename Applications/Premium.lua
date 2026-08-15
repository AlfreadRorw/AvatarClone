-- ================================================
-- PREMIUM APP - Mega Upgrade (Dark Mode, 20+ Features, Toggles, Cooldown)
-- ================================================

local Services       = _G.Services
local LocalPlayer    = _G.LocalPlayer
local Firebase       = _G.Firebase
local Config         = _G.Config or {}
local Helpers        = _G.Helpers or {}
local appContent     = _G.appContent

local UIS            = Services.UserInputService
local Workspace      = Services.Workspace

-- ==================== STATE MANAGEMENT ====================
local selectedTargetId = nil
local selectedTargetName = "Pilih Player"
local tpOnTapActive = false
local tapConnectionBegan = nil
local tapConnectionEnded = nil
local inputStartPos = nil

local lastCommandTime = 0
local COMMAND_COOLDOWN = 1.5 -- Anti spam 1.5 detik

-- Menyimpan status toggle fitur troll per-player
local trollStates = {}

-- ==================== ACCESS VALIDATION ====================
local function hasAccess()
    if LocalPlayer.UserId == (Config.DEVELOPER_USER_ID or 10164114772) then return true end
    if Firebase and Firebase.IsPermanentUser then
        return Firebase.IsPermanentUser(LocalPlayer.UserId)
    end
    return false
end
_G.hasPremiumAccess = hasAccess

-- ==================== FIREBASE SENDER HELPER ====================
local function sendCommand(cmdType, extraData)
    if not selectedTargetId then
        _G.showDynamicNotification("⚠️ Pilih target di Tab Target!", Color3.fromRGB(255, 70, 70))
        return false
    end
    
    if os.clock() - lastCommandTime < COMMAND_COOLDOWN then
        _G.showDynamicNotification("⏳ Cooldown! Jangan spam.", Color3.fromRGB(243, 156, 18))
        return false
    end
    lastCommandTime = os.clock()

    local data = { type = cmdType, timestamp = os.time() }
    if extraData then
        for k, v in pairs(extraData) do data[k] = v end
    end
    pcall(function() Firebase.PushCommand(selectedTargetId, data) end)
    _G.showDynamicNotification("✅ Perintah " .. cmdType .. " terkirim!", Color3.fromRGB(46, 204, 113))
    return true
end

-- ==================== TP-ON-TAP LOGIC (FIXED CAMERA DRAG) ====================
local function setupTapListener(state)
    tpOnTapActive = state
    if tapConnectionBegan then tapConnectionBegan:Disconnect() end
    if tapConnectionEnded then tapConnectionEnded:Disconnect() end

    if tpOnTapActive then
        _G.showDynamicNotification("TP On-Tap: AKTIF! Ketuk (jangan geser) layar.", Color3.fromRGB(168, 100, 255))
        
        tapConnectionBegan = UIS.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                inputStartPos = input.Position
            end
        end)
        
        tapConnectionEnded = UIS.InputEnded:Connect(function(input, gp)
            if gp or not inputStartPos or not selectedTargetId then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                local dist = (input.Position - inputStartPos).Magnitude
                -- Jika jarak antara tekan dan lepas < 15 pixel, artinya TAP, bukan geser layar
                if dist < 15 then
                    local cam = Workspace.CurrentCamera
                    local ray = cam:ScreenPointToRay(input.Position.X, input.Position.Y)
                    local params = RaycastParams.new()
                    params.FilterDescendantsInstances = {LocalPlayer.Character}
                    params.FilterType = Enum.RaycastFilterType.Exclude

                    local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
                    if result then
                        local cmdData = {
                            type = "teleport_to_point",
                            x = result.Position.X, y = result.Position.Y + 3.5, z = result.Position.Z,
                            fromPlaceId = game.PlaceId, fromJobId = game.JobId, timestamp = os.time()
                        }
                        pcall(function() Firebase.PushCommand(selectedTargetId, cmdData) end)
                        
                        -- Visual mark
                        local part = Instance.new("Part", Workspace)
                        part.Size = Vector3.new(2, 0.2, 2)
                        part.Position = result.Position
                        part.Anchored = true
                        part.CanCollide = false
                        part.Material = Enum.Material.Neon
                        part.Color = Color3.fromRGB(168, 100, 255)
                        part.Shape = Enum.PartType.Cylinder
                        task.delay(1.5, function() part:Destroy() end)
                    end
                end
            end
        end)
    else
        _G.showDynamicNotification("TP On-Tap: NONAKTIF", Color3.fromRGB(200, 200, 200))
    end
end

-- ==================== MAIN APP UI ====================
function _G.openPremiumApp()
    if not hasAccess() then
        _G.showDynamicNotification("Akses Ditolak! Membutuhkan Key Permanen.", Color3.fromRGB(255, 70, 70))
        if _G.goHome then _G.goHome() end
        return
    end

    for _, child in ipairs(appContent:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end
    
    appContent.BackgroundColor3 = Color3.fromRGB(15, 15, 20) -- Dark Theme Base

    -- 1. HEADER & STATUS
    local headerFrame = Instance.new("Frame", appContent)
    headerFrame.Size = UDim2.new(1, 0, 0, 35)
    headerFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    headerFrame.BorderSizePixel = 0
    
    local statusLbl = Instance.new("TextLabel", headerFrame)
    statusLbl.Size = UDim2.new(1, 0, 1, 0)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text = "TARGET: " .. string.upper(selectedTargetName)
    statusLbl.TextColor3 = Color3.fromRGB(180, 120, 255)
    statusLbl.Font = Enum.Font.GothamBlack
    statusLbl.TextSize = 13

    -- 2. TABS
    local tabContainer = Instance.new("ScrollingFrame", appContent)
    tabContainer.Size = UDim2.new(1, 0, 0, 40)
    tabContainer.Position = UDim2.new(0, 0, 0, 40)
    tabContainer.BackgroundTransparency = 1
    tabContainer.CanvasSize = UDim2.new(1.2, 0, 0, 0)
    tabContainer.ScrollBarThickness = 0

    local tabLayout = Instance.new("UIListLayout", tabContainer)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 5)

    local contentArea = Instance.new("Frame", appContent)
    contentArea.Size = UDim2.new(1, 0, 1, -85)
    contentArea.Position = UDim2.new(0, 0, 0, 85)
    contentArea.BackgroundTransparency = 1

    local tabs = {}
    local tabFrames = {}

    local function switchTab(tabName)
        for name, frame in pairs(tabFrames) do frame.Visible = (name == tabName) end
        for name, btn in pairs(tabs) do
            if name == tabName then
                btn.BackgroundColor3 = Color3.fromRGB(168, 100, 255)
                btn.TextColor3 = Color3.new(1, 1, 1)
            else
                btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
                btn.TextColor3 = Color3.fromRGB(150, 150, 150)
            end
        end
    end

    local function createTab(name, order)
        local btn = Instance.new("TextButton", tabContainer)
        btn.Size = UDim2.new(0, 80, 1, 0)
        btn.Text = name
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        Helpers.corner(btn, 6)
        tabs[name] = btn

        local frame = Instance.new("ScrollingFrame", contentArea)
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundTransparency = 1
        frame.ScrollBarThickness = 2
        frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        frame.Visible = false
        tabFrames[name] = frame

        local listLay = Instance.new("UIListLayout", frame)
        listLay.Padding = UDim.new(0, 8)
        listLay.HorizontalAlignment = Enum.HorizontalAlignment.Center

        btn.MouseButton1Click:Connect(function() switchTab(name) end)
        return frame
    end

    -- ==================== TAB 1: TARGET (DARK/PREMIUM UI) ====================
    local targetFrame = createTab("Target", 1)
    
    local refBtn = Instance.new("TextButton", targetFrame)
    refBtn.Size = UDim2.new(0.95, 0, 0, 35)
    refBtn.BackgroundColor3 = Color3.fromRGB(168, 100, 255)
    refBtn.Text = "🔄 Refresh Player Online"
    refBtn.TextColor3 = Color3.new(1,1,1)
    refBtn.Font = Enum.Font.GothamBold
    refBtn.TextSize = 12
    Helpers.corner(refBtn, 8)

    local playerListContainer = Instance.new("Frame", targetFrame)
    playerListContainer.Size = UDim2.new(0.95, 0, 0, 0)
    playerListContainer.AutomaticSize = Enum.AutomaticSize.Y
    playerListContainer.BackgroundTransparency = 1
    local pLayout = Instance.new("UIListLayout", playerListContainer)
    pLayout.Padding = UDim.new(0, 8)

    local function loadPlayers()
        for _, c in ipairs(playerListContainer:GetChildren()) do if c:IsA("GuiButton") then c:Destroy() end end
        task.spawn(function()
            local ok, players = pcall(function() return Firebase.GetOnlinePlayers() end)
            if not ok or not players then return end

            for uidStr, pData in pairs(players) do
                local uid = tonumber(uidStr)
                if uid == LocalPlayer.UserId then continue end
                
                local isOnline = pData.isOnline
                if pData.lastSeen and (os.time() - pData.lastSeen) > 120 then isOnline = false end
                if not isOnline then continue end 

                local pRow = Instance.new("TextButton", playerListContainer)
                pRow.Size = UDim2.new(1, 0, 0, 55)
                pRow.BackgroundColor3 = Color3.fromRGB(30, 30, 35) -- Dark row
                Helpers.corner(pRow, 10)
                
                local av = Instance.new("ImageLabel", pRow)
                av.Size = UDim2.new(0, 40, 0, 40)
                av.Position = UDim2.new(0, 10, 0.5, -20)
                av.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
                av.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. uidStr .. "&width=150&height=150&format=png"
                Helpers.corner(av, 100)
                
                local nameLbl = Instance.new("TextLabel", pRow)
                nameLbl.Size = UDim2.new(1, -65, 0, 18)
                nameLbl.Position = UDim2.new(0, 60, 0, 10)
                nameLbl.BackgroundTransparency = 1
                nameLbl.Text = pData.username or "User"
                nameLbl.TextColor3 = Color3.new(1,1,1)
                nameLbl.Font = Enum.Font.GothamBold
                nameLbl.TextSize = 13
                nameLbl.TextXAlignment = Enum.TextXAlignment.Left

                local mapLbl = Instance.new("TextLabel", pRow)
                mapLbl.Size = UDim2.new(1, -65, 0, 14)
                mapLbl.Position = UDim2.new(0, 60, 0, 30)
                mapLbl.BackgroundTransparency = 1
                mapLbl.Text = pData.mapName or "Unknown Map"
                mapLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
                mapLbl.Font = Enum.Font.Gotham
                mapLbl.TextSize = 10
                mapLbl.TextXAlignment = Enum.TextXAlignment.Left

                pRow.MouseButton1Click:Connect(function()
                    selectedTargetId = uid
                    selectedTargetName = pData.username or tostring(uid)
                    statusLbl.Text = "TARGET: " .. string.upper(selectedTargetName)
                    
                    for _, c in ipairs(playerListContainer:GetChildren()) do
                        if c:IsA("GuiButton") then
                            c.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
                        end
                    end
                    pRow.BackgroundColor3 = Color3.fromRGB(70, 40, 110) -- Highlight
                    _G.showDynamicNotification("Target: " .. selectedTargetName, Color3.fromRGB(168, 100, 255))
                end)
            end
        end)
    end
    refBtn.MouseButton1Click:Connect(loadPlayers)
    loadPlayers()

    -- ==================== TAB 2: TELEPORT ====================
    local tpFrame = createTab("Teleport", 2)
    
    local function addCard(parent, title, desc, btnText, callback)
        local card = Instance.new("Frame", parent)
        card.Size = UDim2.new(0.95, 0, 0, 80)
        card.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        Helpers.corner(card, 8)
        
        local tLbl = Instance.new("TextLabel", card)
        tLbl.Size = UDim2.new(1, -80, 0, 20); tLbl.Position = UDim2.new(0, 10, 0, 10)
        tLbl.BackgroundTransparency = 1; tLbl.Text = title; tLbl.Font = Enum.Font.GothamBold
        tLbl.TextSize = 13; tLbl.TextXAlignment = Enum.TextXAlignment.Left
        tLbl.TextColor3 = Color3.new(1,1,1)
        
        local dLbl = Instance.new("TextLabel", card)
        dLbl.Size = UDim2.new(1, -80, 0, 40); dLbl.Position = UDim2.new(0, 10, 0, 30)
        dLbl.BackgroundTransparency = 1; dLbl.Text = desc; dLbl.Font = Enum.Font.Gotham
        dLbl.TextSize = 10; dLbl.TextXAlignment = Enum.TextXAlignment.Left; dLbl.TextWrapped = true
        dLbl.TextColor3 = Color3.fromRGB(180, 180, 180)
        
        local btn = Instance.new("TextButton", card)
        btn.Size = UDim2.new(0, 65, 0, 35); btn.Position = UDim2.new(1, -75, 0.5, -17.5)
        btn.BackgroundColor3 = Color3.fromRGB(168, 100, 255); btn.TextColor3 = Color3.new(1,1,1)
        btn.Text = btnText; btn.Font = Enum.Font.GothamBold; btn.TextSize = 11
        Helpers.corner(btn, 6); Helpers.pressFX(btn)
        btn.MouseButton1Click:Connect(callback)
    end

    addCard(tpFrame, "Tarik ke Saya", "Menarik target lintas server langsung ke Anda.", "Tarik", function()
        sendCommand("teleport_to_dev", { devUserId = LocalPlayer.UserId, devPlaceId = game.PlaceId, devJobId = game.JobId })
    end)
    addCard(tpFrame, "TP On-Tap", "Ketuk layar untuk memindahkan target ke titik tersebut.", "Toggle", function()
        setupTapListener(not tpOnTapActive)
    end)


    -- ==================== TAB 3: ADMIN & CHAT ====================
    local chatFrame = createTab("Admin", 3)
    
    local chatInput = Instance.new("TextBox", chatFrame)
    chatInput.Size = UDim2.new(0.95, 0, 0, 45)
    chatInput.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    chatInput.PlaceholderText = "Ketik pesan publik..."
    chatInput.Text = ""
    chatInput.Font = Enum.Font.Gotham
    chatInput.TextSize = 12
    chatInput.TextColor3 = Color3.new(1,1,1)
    Helpers.corner(chatInput, 8)
    
    local sendChatBtn = Instance.new("TextButton", chatFrame)
    sendChatBtn.Size = UDim2.new(0.95, 0, 0, 35)
    sendChatBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    sendChatBtn.Text = "Paksa Target Bicara (Global)"
    sendChatBtn.TextColor3 = Color3.new(1,1,1)
    sendChatBtn.Font = Enum.Font.GothamBold
    sendChatBtn.TextSize = 12
    Helpers.corner(sendChatBtn, 8)
    
    sendChatBtn.MouseButton1Click:Connect(function()
        if sendCommand("force_chat", { message = chatInput.Text }) then chatInput.Text = "" end
    end)

    local reBtn = Instance.new("TextButton", chatFrame)
    reBtn.Size = UDim2.new(0.95, 0, 0, 35)
    reBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    reBtn.Text = "Ubah/Refresh Avatar (via Remote 're')"
    reBtn.TextColor3 = Color3.new(1,1,1)
    reBtn.Font = Enum.Font.GothamBold
    reBtn.TextSize = 12
    Helpers.corner(reBtn, 8)
    
    reBtn.MouseButton1Click:Connect(function()
        sendCommand("force_remote", { remotePath = Config.REMOTE_PATH or "Remotes.Command.CommandEvent", cmd = "re" })
    end)

    -- ==================== TAB 4: MEGA TROLL ====================
    local trollFrame = createTab("Troll", 4)
    
    local function addTrollToggle(title, desc, actionOn, actionOff, color)
        local card = Instance.new("Frame", trollFrame)
        card.Size = UDim2.new(0.95, 0, 0, 70)
        card.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        Helpers.corner(card, 8)

        local tLbl = Instance.new("TextLabel", card)
        tLbl.Size = UDim2.new(1, -90, 0, 20); tLbl.Position = UDim2.new(0, 10, 0, 8)
        tLbl.BackgroundTransparency = 1; tLbl.Text = title; tLbl.Font = Enum.Font.GothamBold
        tLbl.TextSize = 13; tLbl.TextXAlignment = Enum.TextXAlignment.Left; tLbl.TextColor3 = Color3.new(1,1,1)
        
        local dLbl = Instance.new("TextLabel", card)
        dLbl.Size = UDim2.new(1, -90, 0, 35); dLbl.Position = UDim2.new(0, 10, 0, 28)
        dLbl.BackgroundTransparency = 1; dLbl.Text = desc; dLbl.Font = Enum.Font.Gotham
        dLbl.TextSize = 10; dLbl.TextXAlignment = Enum.TextXAlignment.Left; dLbl.TextWrapped = true
        dLbl.TextColor3 = Color3.fromRGB(160, 160, 160)

        local btn = Instance.new("TextButton", card)
        btn.Size = UDim2.new(0, 70, 0, 35); btn.Position = UDim2.new(1, -80, 0.5, -17.5)
        btn.BackgroundColor3 = color
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Text = "OFF"
        btn.Font = Enum.Font.GothamBold; btn.TextSize = 12
        Helpers.corner(btn, 6)

        btn.MouseButton1Click:Connect(function()
            if not selectedTargetId then return end
            trollStates[selectedTargetId] = trollStates[selectedTargetId] or {}
            
            local isOn = not trollStates[selectedTargetId][actionOn]
            trollStates[selectedTargetId][actionOn] = isOn

            if isOn then
                btn.Text = "ON"
                btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113) -- Hijau
                sendCommand("troll_action", { action = actionOn })
            else
                btn.Text = "OFF"
                btn.BackgroundColor3 = color
                sendCommand("troll_action", { action = actionOff })
            end
        end)
    end

    -- Fitur-fitur Troll Toggle (20 Features Grouped)
    addTrollToggle("Jail", "Mengurung target di dalam kotak transparan.", "jail", "unjail", Color3.fromRGB(230, 126, 34))
    addTrollToggle("Freeze", "Membekukan karakter target agar tidak bisa bergerak.", "freeze", "unfreeze", Color3.fromRGB(52, 152, 219))
    addTrollToggle("Blind", "Membuat layar target menjadi gelap gulita.", "blind", "unblind", Color3.fromRGB(44, 62, 80))
    addTrollToggle("Blur Vision", "Membuat pandangan target menjadi kabur dan pusing.", "blur", "unblur", Color3.fromRGB(142, 68, 173))
    addTrollToggle("Fire Aura", "Membakar target dengan api visual.", "fire", "unfire", Color3.fromRGB(192, 57, 43))
    addTrollToggle("Smoke Aura", "Menutupi target dengan asap tebal.", "smoke", "unsmoke", Color3.fromRGB(127, 140, 141))
    addTrollToggle("Force Sit", "Memaksa target terus duduk (tidak bisa berdiri).", "forcesit", "unforcesit", Color3.fromRGB(243, 156, 18))
    addTrollToggle("Spin", "Memutar badan target seperti gasing.", "spin", "unspin", Color3.fromRGB(211, 84, 0))
    addTrollToggle("Slow Walk", "Membuat kecepatan jalan target sangat lambat.", "slow", "unslow", Color3.fromRGB(52, 73, 94))
    addTrollToggle("High Jump", "Memberikan efek lompatan super tinggi.", "highjump", "unhighjump", Color3.fromRGB(26, 188, 156))
    
    -- Eksekusi instan (bukan toggle) ditaruh terpisah di bawah
    local instantLbl = Instance.new("TextLabel", trollFrame)
    instantLbl.Size = UDim2.new(0.95, 0, 0, 30)
    instantLbl.BackgroundTransparency = 1
    instantLbl.Text = "INSTANT TROLL ACTION:"
    instantLbl.TextColor3 = Color3.fromRGB(180, 120, 255)
    instantLbl.Font = Enum.Font.GothamBold
    instantLbl.TextXAlignment = Enum.TextXAlignment.Left

    local gridLayout = Instance.new("UIGridLayout", trollFrame) -- Untuk tombol instan
    gridLayout.CellSize = UDim2.new(0.46, 0, 0, 40)
    gridLayout.CellPadding = UDim2.new(0.04, 0, 0, 10)
    
    local function addInstantBtn(name, cmd, color)
        local btn = Instance.new("TextButton", trollFrame)
        btn.BackgroundColor3 = color; btn.Text = name; btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.GothamBold; btn.TextSize = 11; Helpers.corner(btn, 8)
        btn.MouseButton1Click:Connect(function() sendCommand("troll_action", { action = cmd }) end)
    end

    addInstantBtn("Kill", "kill", Color3.fromRGB(231, 76, 60))
    addInstantBtn("Fling", "fling", Color3.fromRGB(155, 89, 182))
    addInstantBtn("Noclip", "noclip", Color3.fromRGB(149, 165, 166))
    addInstantBtn("Remove Limbs", "nolimbs", Color3.fromRGB(192, 57, 43))
    
    switchTab("Target")
end
