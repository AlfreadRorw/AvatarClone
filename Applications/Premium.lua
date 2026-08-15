-- ================================================
-- PREMIUM APP - Advanced Tabbed Control Panel
-- Fitur: Tabs, Force Chat, Jail, Troll, TP, Filter Online
-- ================================================

local Services       = _G.Services
local LocalPlayer    = _G.LocalPlayer
local Firebase       = _G.Firebase
local Config         = _G.Config or {}
local Helpers        = _G.Helpers or {}
local T              = _G.T or {}
local appContent     = _G.appContent

local UIS            = Services.UserInputService
local Workspace      = Services.Workspace

-- ==================== STATE MANAGEMENT ====================
local selectedTargetId = nil
local selectedTargetName = "Pilih Player"
local tpOnTapActive = false
local tapConnection = nil
local currentTab = "Target" -- Default tab

-- ==================== ACCESS VALIDATION ====================
local function hasAccess()
    if LocalPlayer.UserId == (Config.DEVELOPER_USER_ID or 10164114772) then return true end
    if Firebase and Firebase.IsPermanentUser then
        return Firebase.IsPermanentUser(LocalPlayer.UserId)
    end
    return false
end
_G.hasPremiumAccess = hasAccess

-- ==================== TP-ON-TAP LOGIC ====================
local function setupTapListener(state)
    tpOnTapActive = state
    if tapConnection then
        tapConnection:Disconnect()
        tapConnection = nil
    end

    if tpOnTapActive then
        _G.showDynamicNotification("TP On-Tap: AKTIF! Sentuh layar.", Color3.fromRGB(168, 100, 255))
        tapConnection = UIS.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed or not selectedTargetId then return end
            
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                local pos = input.Position
                local cam = Workspace.CurrentCamera
                local ray = cam:ScreenPointToRay(pos.X, pos.Y)
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
        end)
    end
end

-- ==================== FIREBASE SENDER HELPER ====================
local function sendCommand(cmdType, extraData)
    if not selectedTargetId then
        _G.showDynamicNotification("⚠️ Pilih target terlebih dahulu di Tab Target!", Color3.fromRGB(255, 70, 70))
        return false
    end
    local data = { type = cmdType, timestamp = os.time() }
    if extraData then
        for k, v in pairs(extraData) do data[k] = v end
    end
    pcall(function() Firebase.PushCommand(selectedTargetId, data) end)
    _G.showDynamicNotification("✅ Perintah " .. cmdType .. " terkirim!", Color3.fromRGB(46, 204, 113))
    return true
end

-- ==================== MAIN APP UI ====================
function _G.openPremiumApp()
    if not hasAccess() then
        _G.showDynamicNotification("Akses Ditolak! Membutuhkan Key Permanen.", Color3.fromRGB(255, 70, 70))
        if _G.goHome then _G.goHome() end
        return
    end

    -- Clear previous content
    for _, child in ipairs(appContent:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end

    -- 1. HEADER & STATUS (Sticky di Atas)
    local headerFrame = Instance.new("Frame", appContent)
    headerFrame.Size = UDim2.new(1, 0, 0, 35)
    headerFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    Helpers.corner(headerFrame, 8)
    
    local statusLbl = Instance.new("TextLabel", headerFrame)
    statusLbl.Size = UDim2.new(1, 0, 1, 0)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text = "TARGET: " .. string.upper(selectedTargetName)
    statusLbl.TextColor3 = Color3.fromRGB(168, 100, 255)
    statusLbl.Font = Enum.Font.GothamBlack
    statusLbl.TextSize = 12

    -- 2. TAB BUTTONS CONTAINER
    local tabContainer = Instance.new("Frame", appContent)
    tabContainer.Size = UDim2.new(1, 0, 0, 40)
    tabContainer.Position = UDim2.new(0, 0, 0, 42)
    tabContainer.BackgroundTransparency = 1

    local tabLayout = Instance.new("UIListLayout", tabContainer)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- 3. CONTENT CONTAINERS (Isi dari setiap tab)
    local contentArea = Instance.new("Frame", appContent)
    contentArea.Size = UDim2.new(1, 0, 1, -90)
    contentArea.Position = UDim2.new(0, 0, 0, 90)
    contentArea.BackgroundTransparency = 1

    local tabs = {}
    local tabFrames = {}

    local function switchTab(tabName)
        for name, frame in pairs(tabFrames) do
            frame.Visible = (name == tabName)
        end
        for name, btn in pairs(tabs) do
            if name == tabName then
                btn.BackgroundColor3 = Color3.fromRGB(168, 100, 255)
                btn.TextColor3 = Color3.new(1, 1, 1)
            else
                btn.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
                btn.TextColor3 = Color3.fromRGB(100, 100, 115)
            end
        end
    end

    local function createTab(name, order)
        -- Create Button
        local btn = Instance.new("TextButton", tabContainer)
        btn.Size = UDim2.new(0.25, -4, 1, 0)
        btn.Text = name
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.LayoutOrder = order
        Helpers.corner(btn, 6)
        tabs[name] = btn

        -- Create Frame
        local frame = Instance.new("ScrollingFrame", contentArea)
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundTransparency = 1
        frame.ScrollBarThickness = 0
        frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        frame.Visible = false
        tabFrames[name] = frame

        local listLay = Instance.new("UIListLayout", frame)
        listLay.Padding = UDim.new(0, 8)
        listLay.SortOrder = Enum.SortOrder.LayoutOrder

        btn.MouseButton1Click:Connect(function() switchTab(name) end)
        return frame
    end

    -- ==================== TAB 1: TARGET ====================
    local targetFrame = createTab("Target", 1)
    
    local refBtn = Instance.new("TextButton", targetFrame)
    refBtn.Size = UDim2.new(1, 0, 0, 30)
    refBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    refBtn.Text = "🔄 Refresh Player Online"
    refBtn.TextColor3 = Color3.new(1,1,1)
    refBtn.Font = Enum.Font.GothamBold
    refBtn.TextSize = 11
    Helpers.corner(refBtn, 8)

    local playerListContainer = Instance.new("Frame", targetFrame)
    playerListContainer.Size = UDim2.new(1, 0, 0, 0)
    playerListContainer.AutomaticSize = Enum.AutomaticSize.Y
    playerListContainer.BackgroundTransparency = 1
    local pLayout = Instance.new("UIListLayout", playerListContainer)
    pLayout.Padding = UDim.new(0, 5)

    local function loadPlayers()
        for _, c in ipairs(playerListContainer:GetChildren()) do if c:IsA("GuiButton") then c:Destroy() end end
        task.spawn(function()
            local ok, players = pcall(function() return Firebase.GetOnlinePlayers() end)
            if not ok or not players then return end

            for uidStr, pData in pairs(players) do
                local uid = tonumber(uidStr)
                if uid == LocalPlayer.UserId then continue end
                
                -- LOGIKA FILTER ONLINE (Hanya Tampil yang aktif < 2 Menit terakhir)
                local isOnline = pData.isOnline
                if pData.lastSeen then
                    if (os.time() - pData.lastSeen) > 120 then isOnline = false end
                end

                if not isOnline then continue end -- SKIP JIKA OFFLINE

                local pRow = Instance.new("TextButton", playerListContainer)
                pRow.Size = UDim2.new(1, 0, 0, 40)
                pRow.BackgroundColor3 = Color3.new(1, 1, 1)
                Helpers.corner(pRow, 8)
                
                local nameLbl = Instance.new("TextLabel", pRow)
                nameLbl.Size = UDim2.new(1, -10, 1, 0)
                nameLbl.Position = UDim2.new(0, 10, 0, 0)
                nameLbl.BackgroundTransparency = 1
                nameLbl.Text = pData.username or ("User_" .. uidStr)
                nameLbl.TextColor3 = Color3.fromRGB(20, 20, 28)
                nameLbl.Font = Enum.Font.GothamBold
                nameLbl.TextSize = 12
                nameLbl.TextXAlignment = Enum.TextXAlignment.Left

                pRow.MouseButton1Click:Connect(function()
                    selectedTargetId = uid
                    selectedTargetName = pData.username or tostring(uid)
                    statusLbl.Text = "TARGET: " .. string.upper(selectedTargetName)
                    _G.showDynamicNotification("Target diset: " .. selectedTargetName, Color3.fromRGB(168, 100, 255))
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
        card.Size = UDim2.new(1, 0, 0, 70)
        card.BackgroundColor3 = Color3.new(1,1,1)
        Helpers.corner(card, 8)
        
        local tLbl = Instance.new("TextLabel", card)
        tLbl.Size = UDim2.new(1, -80, 0, 20); tLbl.Position = UDim2.new(0, 10, 0, 10)
        tLbl.BackgroundTransparency = 1; tLbl.Text = title; tLbl.Font = Enum.Font.GothamBold
        tLbl.TextSize = 12; tLbl.TextXAlignment = Enum.TextXAlignment.Left
        
        local dLbl = Instance.new("TextLabel", card)
        dLbl.Size = UDim2.new(1, -80, 0, 30); dLbl.Position = UDim2.new(0, 10, 0, 30)
        dLbl.BackgroundTransparency = 1; dLbl.Text = desc; dLbl.Font = Enum.Font.Gotham
        dLbl.TextSize = 9; dLbl.TextXAlignment = Enum.TextXAlignment.Left; dLbl.TextWrapped = true
        dLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
        
        local btn = Instance.new("TextButton", card)
        btn.Size = UDim2.new(0, 65, 0, 30); btn.Position = UDim2.new(1, -75, 0.5, -15)
        btn.BackgroundColor3 = Color3.fromRGB(168, 100, 255); btn.TextColor3 = Color3.new(1,1,1)
        btn.Text = btnText; btn.Font = Enum.Font.GothamBold; btn.TextSize = 10
        Helpers.corner(btn, 6); Helpers.pressFX(btn)
        btn.MouseButton1Click:Connect(callback)
    end

    addCard(tpFrame, "Tarik ke Saya", "Menarik target melintasi server langsung ke samping Anda.", "Tarik", function()
        sendCommand("teleport_to_dev", { devUserId = LocalPlayer.UserId, devPlaceId = game.PlaceId, devJobId = game.JobId })
    end)
    
    addCard(tpFrame, "TP On-Tap", "Klik pada dunia 3D untuk memindahkan target ke titik tersebut.", "Toggle", function()
        setupTapListener(not tpOnTapActive)
    end)


    -- ==================== TAB 3: CHAT (FORCE CHAT) ====================
    local chatFrame = createTab("Chat", 3)
    
    local chatInput = Instance.new("TextBox", chatFrame)
    chatInput.Size = UDim2.new(1, 0, 0, 40)
    chatInput.BackgroundColor3 = Color3.new(1,1,1)
    chatInput.PlaceholderText = "Ketik pesan untuk diucapkan target..."
    chatInput.Text = ""
    chatInput.Font = Enum.Font.Gotham
    chatInput.TextSize = 12
    chatInput.TextColor3 = Color3.fromRGB(20, 20, 28)
    Helpers.corner(chatInput, 8)
    
    local sendChatBtn = Instance.new("TextButton", chatFrame)
    sendChatBtn.Size = UDim2.new(1, 0, 0, 35)
    sendChatBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    sendChatBtn.Text = "Kirim Pesan (Force Chat)"
    sendChatBtn.TextColor3 = Color3.new(1,1,1)
    sendChatBtn.Font = Enum.Font.GothamBold
    sendChatBtn.TextSize = 11
    Helpers.corner(sendChatBtn, 8)
    
    sendChatBtn.MouseButton1Click:Connect(function()
        local text = chatInput.Text
        if text == "" then return end
        if sendCommand("force_chat", { message = text }) then
            chatInput.Text = "" -- Clear sesudah kirim
        end
    end)


    -- ==================== TAB 4: TROLL / JAIL ====================
    local trollFrame = createTab("Troll", 4)
    
    local trollGrid = Instance.new("Frame", trollFrame)
    trollGrid.Size = UDim2.new(1, 0, 0, 200)
    trollGrid.BackgroundTransparency = 1
    
    local gridLayout = Instance.new("UIGridLayout", trollGrid)
    gridLayout.CellSize = UDim2.new(0.5, -5, 0, 45)
    gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)

    local function tBtn(name, color, cmd)
        local b = Instance.new("TextButton", trollGrid)
        b.BackgroundColor3 = color
        b.Text = name
        b.TextColor3 = Color3.new(1,1,1)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 11
        Helpers.corner(b, 8)
        Helpers.pressFX(b)
        b.MouseButton1Click:Connect(function() sendCommand("troll_action", { action = cmd }) end)
    end

    tBtn("Jail", Color3.fromRGB(230, 126, 34), "jail")
    tBtn("Unjail", Color3.fromRGB(46, 204, 113), "unjail")
    tBtn("Freeze", Color3.fromRGB(52, 152, 219), "freeze")
    tBtn("Unfreeze", Color3.fromRGB(46, 204, 113), "unfreeze")
    tBtn("Fling (Terbang)", Color3.fromRGB(155, 89, 182), "fling")
    tBtn("Kill", Color3.fromRGB(231, 76, 60), "kill")

    -- Set Default Tab
    switchTab("Target")
end

print("[Premium] Mod Menu Premium (Tabbed) Dimuat!")
