-- ================================================
-- APPLICATIONS/TELEPORT.LUA — Purple Glass Teleport App
-- Features: Player List, Tap to Teleport, Spectator Mode
-- Fix: nil Services crash, blocking thumbnail fetch, history ordering
-- ================================================

local Services = _G.Services or {}
local T = _G.T or {}
local Helpers = _G.Helpers or {}
local LocalPlayer = _G.LocalPlayer
local Storage = _G.Storage
local Firebase = _G.Firebase

-- ==================== CONSTANTS (PURPLE GLASS) ====================
local WHITE       = Color3.fromRGB(255, 255, 255)
local BLACK       = Color3.fromRGB(15, 12, 20)
local LIGHT_GRAY  = Color3.fromRGB(247, 244, 253)   -- background lavender-putih
local MID_GRAY    = Color3.fromRGB(225, 218, 240)
local DARK_GRAY   = Color3.fromRGB(140, 130, 155)
local ACCENT      = Color3.fromRGB(20, 12, 32)      -- hitam-ungu untuk pill/badge gelap
local PURPLE      = Color3.fromRGB(124, 58, 237)
local PURPLE_LIGHT= Color3.fromRGB(167, 120, 244)
local PURPLE_DEEP = Color3.fromRGB(70, 30, 150)
local GREEN       = Color3.fromRGB(30, 180, 100)
local RED         = Color3.fromRGB(255, 80, 80)

local corner  = Helpers.corner or function(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 10); c.Parent = o; return c end
local stroke  = Helpers.stroke or function(o, c, t, tr) local s = Instance.new("UIStroke"); s.Color = c or BLACK; s.Thickness = t or 1; s.Transparency = tr or 0; s.Parent = o; return s end
local tween   = Helpers.tween or function(o, props, dur)
    local ts = game:GetService("TweenService")
    local tw = ts:Create(o, TweenInfo.new(dur or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end
local pressFX = Helpers.pressFX or function(btn)
    btn.MouseButton1Down:Connect(function() tween(btn, {Size = btn.Size - UDim2.new(0,2,0,2)}, 0.08) end)
    btn.MouseButton1Up:Connect(function() tween(btn, {Size = btn.Size + UDim2.new(0,2,0,2)}, 0.08) end)
end
local gradient = function(o, seq, rotation)
    local g = Instance.new("UIGradient")
    g.Color = seq
    g.Rotation = rotation or 0
    g.Parent = o
    return g
end

-- ==================== STATE ====================
local currentFilter = "all" -- all, friends, history
local searchQuery = ""
local selectedPlayer = nil
local isSpectating = false
local spectateConnection = nil
local teleportHistory = {} -- {userId, displayName, name, placeId, jobId, timestamp}
local maxHistory = 20

-- ==================== HELPER FUNCTIONS ====================
local function getPlayerList()
    if not Services.Players then return {} end
    local players = {}
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(players, player)
        end
    end
    return players
end

local function isFriend(userId)
    if Firebase and Firebase.IsFriend then
        local ok, result = pcall(function()
            return Firebase.IsFriend(LocalPlayer.UserId, userId)
        end)
        return ok and result or false
    end
    return false
end

local function formatDistance(seconds)
    seconds = math.max(0, seconds or 0) -- FIX: clamp biar nggak muncul angka negatif kalau clock desync
    if seconds < 60 then
        return string.format("%ds", seconds)
    elseif seconds < 3600 then
        return string.format("%dm", math.floor(seconds / 60))
    elseif seconds < 86400 then
        return string.format("%dh", math.floor(seconds / 3600))
    else
        return string.format("%dd", math.floor(seconds / 86400))
    end
end

-- Cache thumbnail supaya tidak blocking berulang tiap refresh (FIX bug #2)
local thumbnailCache = {}
local function getPlayerThumbnail(player, imageLabel)
    local cached = thumbnailCache[player.UserId]
    if cached then
        imageLabel.Image = cached
        return
    end
    task.spawn(function()
        local ok, content = pcall(function()
            return Services.Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        end)
        if ok and content and imageLabel.Parent then
            thumbnailCache[player.UserId] = content
            imageLabel.Image = content
        end
    end)
end

-- ==================== SPECTATOR SYSTEM ====================
local function stopSpectating()
    if isSpectating then
        isSpectating = false
        if spectateConnection then
            spectateConnection:Disconnect()
            spectateConnection = nil
        end

        local camera = Services.Workspace and Services.Workspace.CurrentCamera
        if camera then
            camera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") or LocalPlayer.Character
        end

        if _G.showDynamicNotification then
            _G.showDynamicNotification("Spectator Off", RED)
        end
    end
end

local function startSpectating(targetPlayer)
    stopSpectating()

    if not targetPlayer or targetPlayer == LocalPlayer then return end

    isSpectating = true
    selectedPlayer = targetPlayer

    local camera = Services.Workspace and Services.Workspace.CurrentCamera
    if camera then
        local targetHumanoid = targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid")
        if targetHumanoid then
            camera.CameraSubject = targetHumanoid
        end
    end

    spectateConnection = targetPlayer.CharacterAdded:Connect(function(character)
        if isSpectating and selectedPlayer == targetPlayer then
            local cam = Services.Workspace and Services.Workspace.CurrentCamera
            if cam then
                local humanoid = character:WaitForChild("Humanoid", 5)
                if humanoid then
                    cam.CameraSubject = humanoid
                end
            end
        end
    end)

    if Services.Players then
        Services.Players.PlayerRemoving:Connect(function(player)
            if player == targetPlayer and isSpectating then
                stopSpectating()
            end
        end)
    end

    if _G.showDynamicNotification then
        _G.showDynamicNotification("Spectating: " .. targetPlayer.DisplayName, GREEN)
    end
end

-- ==================== TELEPORT SYSTEM ====================
local function teleportToPlayer(targetPlayer)
    if not targetPlayer or targetPlayer == LocalPlayer then return end

    table.insert(teleportHistory, {
        userId = targetPlayer.UserId,
        displayName = targetPlayer.DisplayName,
        name = targetPlayer.Name,
        placeId = game.PlaceId,
        jobId = game.JobId,
        timestamp = os.time()
    })

    while #teleportHistory > maxHistory do
        table.remove(teleportHistory, 1)
    end

    if Storage and Storage.appSettings then
        Storage.appSettings.teleportHistory = teleportHistory
        pcall(function()
            if Storage.persistSettings then Storage.persistSettings() end
        end)
    end

    local targetCharacter = targetPlayer.Character
    if not targetCharacter then
        if _G.showDynamicNotification then
            _G.showDynamicNotification("Player not in game!", RED)
        end
        return
    end

    local targetHRP = targetCharacter:FindFirstChild("HumanoidRootPart")
    if not targetHRP then
        if _G.showDynamicNotification then
            _G.showDynamicNotification("Cannot find player position!", RED)
        end
        return
    end

    local localCharacter = LocalPlayer.Character
    local localHRP = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")

    if localHRP then
        localHRP.CFrame = targetHRP.CFrame + Vector3.new(0, 3, 0)
        if _G.showDynamicNotification then
            _G.showDynamicNotification("Teleported to " .. targetPlayer.DisplayName, GREEN)
        end
    else
        if _G.showDynamicNotification then
            _G.showDynamicNotification("Your character not ready!", RED)
        end
    end
end

-- ==================== UI COMPONENTS ====================
local function createSpectatorToggle(parent)
    local wrap = Instance.new("Frame", parent)
    wrap.Size = UDim2.new(1, 0, 0, 44)
    wrap.BackgroundTransparency = 1
    wrap.LayoutOrder = 0

    local pill = Instance.new("TextButton", wrap)
    pill.Size = UDim2.new(0, 190, 0, 40)
    pill.Position = UDim2.new(0.5, 0, 0, 0)
    pill.AnchorPoint = Vector2.new(0.5, 0)
    pill.BackgroundColor3 = ACCENT
    pill.AutoButtonColor = false
    pill.Text = ""
    corner(pill, 20)

    local icon = Instance.new("TextLabel", pill)
    icon.Size = UDim2.new(0, 24, 1, 0)
    icon.Position = UDim2.new(0, 14, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Text = "👁"
    icon.TextColor3 = WHITE
    icon.TextSize = 15
    icon.Font = Enum.Font.GothamBold

    local label = Instance.new("TextLabel", pill)
    label.Name = "Label"
    label.Size = UDim2.new(1, -46, 1, 0)
    label.Position = UDim2.new(0, 40, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = "Spectator Off"
    label.TextColor3 = WHITE
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left

    pill.MouseButton1Click:Connect(function()
        if isSpectating then
            stopSpectating()
        end
        label.Text = isSpectating and ("Spectating") or "Spectator Off"
    end)

    return wrap, label
end

local function createSearchBar(parent)
    local searchFrame = Instance.new("Frame", parent)
    searchFrame.Size = UDim2.new(1, 0, 0, 44)
    searchFrame.BackgroundColor3 = WHITE
    searchFrame.BorderSizePixel = 0
    searchFrame.LayoutOrder = 2
    corner(searchFrame, 16)
    stroke(searchFrame, PURPLE_LIGHT, 1, 0.4)

    local searchIcon = Instance.new("TextLabel", searchFrame)
    searchIcon.Size = UDim2.new(0, 34, 1, 0)
    searchIcon.Position = UDim2.new(0, 8, 0, 0)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Text = "🔍"
    searchIcon.TextColor3 = DARK_GRAY
    searchIcon.Font = Enum.Font.GothamBold
    searchIcon.TextSize = 15
    searchIcon.TextXAlignment = Enum.TextXAlignment.Center
    searchIcon.TextYAlignment = Enum.TextYAlignment.Center

    local searchBox = Instance.new("TextBox", searchFrame)
    searchBox.Size = UDim2.new(1, -76, 1, 0)
    searchBox.Position = UDim2.new(0, 40, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.PlaceholderText = "Search players..."
    searchBox.PlaceholderColor3 = DARK_GRAY
    searchBox.Text = searchQuery
    searchBox.TextColor3 = BLACK
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 14
    searchBox.ClearTextOnFocus = false
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.TextYAlignment = Enum.TextYAlignment.Center

    local clearBtn = Instance.new("TextButton", searchFrame)
    clearBtn.Size = UDim2.new(0, 20, 0, 20)
    clearBtn.Position = UDim2.new(1, -26, 0.5, 0)
    clearBtn.AnchorPoint = Vector2.new(0, 0.5)
    clearBtn.BackgroundTransparency = 1
    clearBtn.Text = "×"
    clearBtn.TextColor3 = DARK_GRAY
    clearBtn.Font = Enum.Font.GothamBold
    clearBtn.TextSize = 18
    clearBtn.AutoButtonColor = false
    clearBtn.Visible = false
    clearBtn.MouseButton1Click:Connect(function()
        searchBox.Text = ""
    end)

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        searchQuery = searchBox.Text
        clearBtn.Visible = searchQuery ~= ""
        if _G.refreshCurr then
            _G.refreshCurr()
        end
    end)

    return searchFrame
end

local function createFilterTabs(parent)
    local tabFrame = Instance.new("Frame", parent)
    tabFrame.Size = UDim2.new(1, 0, 0, 44)
    tabFrame.BackgroundTransparency = 1
    tabFrame.LayoutOrder = 3

    local tabLayout = Instance.new("UIListLayout", tabFrame)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 8)

    local tabs = {
        {name = "All",      filter = "all",      icon = nil},
        {name = "Friends",  filter = "friends",  icon = nil},
        {name = "History",  filter = "history",  icon = "🕐"},
    }

    local tabButtons = {}

    for i, tab in ipairs(tabs) do
        local btn = Instance.new("TextButton", tabFrame)
        btn.Size = UDim2.new(1/#tabs, -6, 1, 0)
        btn.BackgroundColor3 = currentFilter == tab.filter and ACCENT or WHITE
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.LayoutOrder = i
        corner(btn, 14)
        stroke(btn, PURPLE_LIGHT, 1, currentFilter == tab.filter and 1 or 0.5)

        if currentFilter == tab.filter then
            gradient(btn, ColorSequence.new{
                ColorSequenceKeypoint.new(0, ACCENT),
                ColorSequenceKeypoint.new(1, PURPLE_DEEP)
            }, 0)
        end

        local lbl = Instance.new("TextLabel", btn)
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = (tab.icon and (tab.icon .. " ") or "") .. tab.name
        lbl.TextColor3 = currentFilter == tab.filter and WHITE or BLACK
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 13

        btn.MouseButton1Click:Connect(function()
            currentFilter = tab.filter
            if _G.refreshCurr then
                _G.refreshCurr()
            end
        end)

        table.insert(tabButtons, btn)
    end

    return tabFrame
end

local function createPlayerCard(parent, player, order)
    local card = Instance.new("Frame", parent)
    card.Size = UDim2.new(1, 0, 0, 76)
    card.BackgroundColor3 = WHITE
    card.BorderSizePixel = 0
    card.LayoutOrder = order
    card.ClipsDescendants = true
    corner(card, 16)
    stroke(card, MID_GRAY, 1, 0.4)

    -- Avatar thumbnail
    local avatarWrap = Instance.new("Frame", card)
    avatarWrap.Size = UDim2.new(0, 52, 0, 52)
    avatarWrap.Position = UDim2.new(0, 12, 0.5, -26)
    avatarWrap.AnchorPoint = Vector2.new(0, 0.5)
    avatarWrap.BackgroundColor3 = LIGHT_GRAY
    avatarWrap.BorderSizePixel = 0
    corner(avatarWrap, 26)
    stroke(avatarWrap, PURPLE_LIGHT, 2, 0.2)

    local avatar = Instance.new("ImageLabel", avatarWrap)
    avatar.Size = UDim2.new(1, 0, 1, 0)
    avatar.BackgroundTransparency = 1
    avatar.ScaleType = Enum.ScaleType.Crop
    corner(avatar, 26)
    getPlayerThumbnail(player, avatar) -- FIX: async, tidak lagi blocking render loop

    -- Online dot indicator
    local onlineDot = Instance.new("Frame", avatarWrap)
    onlineDot.Size = UDim2.new(0, 12, 0, 12)
    onlineDot.Position = UDim2.new(1, -12, 1, -12)
    onlineDot.BackgroundColor3 = GREEN
    onlineDot.BorderSizePixel = 0
    corner(onlineDot, 6)
    stroke(onlineDot, WHITE, 2, 0)

    -- Player info
    local infoFrame = Instance.new("Frame", card)
    infoFrame.Size = UDim2.new(1, -155, 1, -16)
    infoFrame.Position = UDim2.new(0, 74, 0, 8)
    infoFrame.BackgroundTransparency = 1

    local nameLabel = Instance.new("TextLabel", infoFrame)
    nameLabel.Size = UDim2.new(1, 0, 0, 22)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.DisplayName
    nameLabel.TextColor3 = BLACK
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 15
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left

    local usernameLabel = Instance.new("TextLabel", infoFrame)
    usernameLabel.Size = UDim2.new(1, 0, 0, 18)
    usernameLabel.Position = UDim2.new(0, 0, 0, 21)
    usernameLabel.BackgroundTransparency = 1
    usernameLabel.Text = "@" .. player.Name
    usernameLabel.TextColor3 = DARK_GRAY
    usernameLabel.Font = Enum.Font.Gotham
    usernameLabel.TextSize = 12
    usernameLabel.TextXAlignment = Enum.TextXAlignment.Left

    local statusLabel = Instance.new("TextLabel", infoFrame)
    statusLabel.Size = UDim2.new(1, 0, 0, 16)
    statusLabel.Position = UDim2.new(0, 0, 0, 42)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "•Online"
    statusLabel.TextColor3 = GREEN
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextSize = 11
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Action buttons (dark rounded square utk teleport, white circle utk spectate)
    local teleportBtn = Instance.new("TextButton", card)
    teleportBtn.Size = UDim2.new(0, 44, 0, 44)
    teleportBtn.Position = UDim2.new(1, -100, 0.5, -22)
    teleportBtn.AnchorPoint = Vector2.new(0, 0.5)
    teleportBtn.BackgroundColor3 = ACCENT
    teleportBtn.Text = "📱"
    teleportBtn.TextColor3 = WHITE
    teleportBtn.Font = Enum.Font.GothamBold
    teleportBtn.TextSize = 17
    teleportBtn.AutoButtonColor = false
    corner(teleportBtn, 14)
    pressFX(teleportBtn)

    local spectateBtn = Instance.new("TextButton", card)
    spectateBtn.Size = UDim2.new(0, 44, 0, 44)
    spectateBtn.Position = UDim2.new(1, -48, 0.5, -22)
    spectateBtn.AnchorPoint = Vector2.new(0, 0.5)
    spectateBtn.BackgroundColor3 = WHITE
    spectateBtn.Text = "👁"
    spectateBtn.TextColor3 = PURPLE
    spectateBtn.Font = Enum.Font.GothamBold
    spectateBtn.TextSize = 17
    spectateBtn.AutoButtonColor = false
    corner(spectateBtn, 22)
    stroke(spectateBtn, PURPLE_LIGHT, 1, 0.3)
    pressFX(spectateBtn)

    teleportBtn.MouseButton1Click:Connect(function()
        teleportToPlayer(player)
    end)

    spectateBtn.MouseButton1Click:Connect(function()
        if isSpectating and selectedPlayer == player then
            stopSpectating()
            spectateBtn.BackgroundColor3 = WHITE
            spectateBtn.TextColor3 = PURPLE
        else
            startSpectating(player)
            spectateBtn.BackgroundColor3 = PURPLE
            spectateBtn.TextColor3 = WHITE
        end
        if _G.refreshCurr then _G.refreshCurr() end
    end)

    return card
end

-- ==================== MAIN APP FUNCTION ====================
function _G.openTeleportApp()
    local appContent = _G.appContent
    if not appContent then return end

    for _, child in ipairs(appContent:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end

    local existingLayout = appContent:FindFirstChildOfClass("UIListLayout")
    if not existingLayout then
        local appLayout = Instance.new("UIListLayout", appContent)
        appLayout.Padding = UDim.new(0, 12)
        appLayout.SortOrder = Enum.SortOrder.LayoutOrder
    end

    -- Spectator toggle pill (top)
    createSpectatorToggle(appContent)

    -- Title
    local titleFrame = Instance.new("Frame", appContent)
    titleFrame.Size = UDim2.new(1, 0, 0, 34)
    titleFrame.BackgroundTransparency = 1
    titleFrame.LayoutOrder = 1

    local titleLbl = Instance.new("TextLabel", titleFrame)
    titleLbl.Size = UDim2.new(1, -30, 1, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "Save & Teleport"
    titleLbl.TextColor3 = BLACK
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 22
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left

    local titleSpark = Instance.new("TextLabel", titleFrame)
    titleSpark.Size = UDim2.new(0, 26, 1, 0)
    titleSpark.Position = UDim2.new(0, 200, 0, 0)
    titleSpark.BackgroundTransparency = 1
    titleSpark.Text = "✦"
    titleSpark.TextColor3 = PURPLE
    titleSpark.TextSize = 18
    titleSpark.Font = Enum.Font.GothamBold

    -- Search bar
    createSearchBar(appContent)

    -- Filter tabs
    createFilterTabs(appContent)

    -- Spectator status bar
    local specStatus = Instance.new("Frame", appContent)
    specStatus.Size = UDim2.new(1, 0, 0, 36)
    specStatus.BackgroundColor3 = LIGHT_GRAY
    specStatus.BorderSizePixel = 0
    specStatus.LayoutOrder = 4
    corner(specStatus, 10)

    local specLabel = Instance.new("TextLabel", specStatus)
    specLabel.Size = UDim2.new(1, -16, 1, 0)
    specLabel.Position = UDim2.new(0, 8, 0, 0)
    specLabel.BackgroundTransparency = 1
    specLabel.Text = isSpectating and ("👁 Spectating: " .. (selectedPlayer and selectedPlayer.DisplayName or "None")) or "👁 Tap 👁 to spectate a player"
    specLabel.TextColor3 = isSpectating and GREEN or DARK_GRAY
    specLabel.Font = Enum.Font.GothamBold
    specLabel.TextSize = 12
    specLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Player list container
    local playerContainer = Instance.new("ScrollingFrame", appContent)
    playerContainer.Size = UDim2.new(1, 0, 1, -230)
    playerContainer.BackgroundTransparency = 1
    playerContainer.BorderSizePixel = 0
    playerContainer.ScrollBarThickness = 2
    playerContainer.ScrollBarImageColor3 = PURPLE
    playerContainer.LayoutOrder = 5
    playerContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    playerContainer.CanvasSize = UDim2.new(0, 0, 0, 0)

    local playerLayout = Instance.new("UIListLayout", playerContainer)
    playerLayout.Padding = UDim.new(0, 8)
    playerLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- Get and filter players
    local players = getPlayerList()
    local filteredPlayers = {}

    if currentFilter == "friends" then
        for _, player in ipairs(players) do
            if isFriend(player.UserId) then
                table.insert(filteredPlayers, player)
            end
        end
    elseif currentFilter == "history" then
        -- FIX: history sekarang dikasih LayoutOrder eksplisit (terbaru di atas)
        -- supaya urutannya konsisten, tidak acak sesuai insertion order Instance.
        local reversedHistory = {}
        for i = #teleportHistory, 1, -1 do
            table.insert(reversedHistory, teleportHistory[i])
        end
        for i, historyItem in ipairs(reversedHistory) do
            local historyCard = Instance.new("Frame", playerContainer)
            historyCard.Size = UDim2.new(1, 0, 0, 56)
            historyCard.BackgroundColor3 = WHITE
            historyCard.BorderSizePixel = 0
            historyCard.LayoutOrder = i
            corner(historyCard, 14)
            stroke(historyCard, MID_GRAY, 1, 0.4)

            local historyName = Instance.new("TextLabel", historyCard)
            historyName.Size = UDim2.new(1, -16, 0, 28)
            historyName.Position = UDim2.new(0, 10, 0, 4)
            historyName.BackgroundTransparency = 1
            historyName.Text = historyItem.displayName
            historyName.TextColor3 = BLACK
            historyName.Font = Enum.Font.GothamBold
            historyName.TextSize = 14

            local historyTime = Instance.new("TextLabel", historyCard)
            historyTime.Size = UDim2.new(1, -16, 0, 16)
            historyTime.Position = UDim2.new(0, 10, 0, 32)
            historyTime.BackgroundTransparency = 1
            historyTime.Text = formatDistance(os.time() - historyItem.timestamp) .. " ago"
            historyTime.TextColor3 = DARK_GRAY
            historyTime.Font = Enum.Font.Gotham
            historyTime.TextSize = 11
        end
    else
        for _, player in ipairs(players) do
            if searchQuery == "" or
               player.DisplayName:lower():find(searchQuery:lower(), 1, true) or
               player.Name:lower():find(searchQuery:lower(), 1, true) then
                table.insert(filteredPlayers, player)
            end
        end
    end

    table.sort(filteredPlayers, function(a, b)
        local aFriend = isFriend(a.UserId)
        local bFriend = isFriend(b.UserId)
        if aFriend ~= bFriend then
            return aFriend
        end
        return a.DisplayName:lower() < b.DisplayName:lower()
    end)

    for i, player in ipairs(filteredPlayers) do
        createPlayerCard(playerContainer, player, i)
    end

    if #filteredPlayers == 0 and currentFilter ~= "history" then
        local emptyState = Instance.new("Frame", playerContainer)
        emptyState.Size = UDim2.new(1, 0, 0, 100)
        emptyState.BackgroundTransparency = 1
        emptyState.LayoutOrder = 999

        local emptyText = Instance.new("TextLabel", emptyState)
        emptyText.Size = UDim2.new(1, 0, 0, 30)
        emptyText.Position = UDim2.new(0, 0, 0.5, -15)
        emptyText.AnchorPoint = Vector2.new(0, 0.5)
        emptyText.BackgroundTransparency = 1
        emptyText.Text = "No players found"
        emptyText.TextColor3 = DARK_GRAY
        emptyText.Font = Enum.Font.GothamBold
        emptyText.TextSize = 14
    elseif #teleportHistory == 0 and currentFilter == "history" then
        local emptyState = Instance.new("Frame", playerContainer)
        emptyState.Size = UDim2.new(1, 0, 0, 100)
        emptyState.BackgroundTransparency = 1
        emptyState.LayoutOrder = 999

        local emptyText = Instance.new("TextLabel", emptyState)
        emptyText.Size = UDim2.new(1, 0, 0, 30)
        emptyText.Position = UDim2.new(0, 0, 0.5, -15)
        emptyText.AnchorPoint = Vector2.new(0, 0.5)
        emptyText.BackgroundTransparency = 1
        emptyText.Text = "No teleport history yet"
        emptyText.TextColor3 = DARK_GRAY
        emptyText.Font = Enum.Font.GothamBold
        emptyText.TextSize = 14
    end

    -- Footer: Players online count + Refresh button
    local footer = Instance.new("Frame", appContent)
    footer.Size = UDim2.new(1, 0, 0, 40)
    footer.BackgroundTransparency = 1
    footer.LayoutOrder = 6

    local onlineWrap = Instance.new("Frame", footer)
    onlineWrap.Size = UDim2.new(0.5, 0, 1, 0)
    onlineWrap.BackgroundTransparency = 1

    local onlineDotIcon = Instance.new("Frame", onlineWrap)
    onlineDotIcon.Size = UDim2.new(0, 8, 0, 8)
    onlineDotIcon.Position = UDim2.new(0, 2, 0.5, -4)
    onlineDotIcon.BackgroundColor3 = GREEN
    onlineDotIcon.BorderSizePixel = 0
    corner(onlineDotIcon, 4)

    local onlineLbl = Instance.new("TextLabel", onlineWrap)
    onlineLbl.Size = UDim2.new(1, -16, 1, 0)
    onlineLbl.Position = UDim2.new(0, 16, 0, 0)
    onlineLbl.BackgroundTransparency = 1
    onlineLbl.Text = "Players online: " .. #players
    onlineLbl.TextColor3 = DARK_GRAY
    onlineLbl.Font = Enum.Font.GothamBold
    onlineLbl.TextSize = 13
    onlineLbl.TextXAlignment = Enum.TextXAlignment.Left

    local refreshBtn = Instance.new("TextButton", footer)
    refreshBtn.Size = UDim2.new(0, 110, 0, 36)
    refreshBtn.Position = UDim2.new(1, 0, 0.5, -18)
    refreshBtn.AnchorPoint = Vector2.new(1, 0)
    refreshBtn.BackgroundColor3 = WHITE
    refreshBtn.Text = "↻ Refresh"
    refreshBtn.TextColor3 = PURPLE
    refreshBtn.Font = Enum.Font.GothamBold
    refreshBtn.TextSize = 13
    refreshBtn.AutoButtonColor = false
    corner(refreshBtn, 18)
    stroke(refreshBtn, PURPLE_LIGHT, 1, 0.3)
    pressFX(refreshBtn)

    refreshBtn.MouseButton1Click:Connect(function()
        if _G.refreshCurr then _G.refreshCurr() end
    end)
end

-- ==================== INITIALIZATION ====================
if Storage and Storage.appSettings and Storage.appSettings.teleportHistory then
    teleportHistory = Storage.appSettings.teleportHistory
end

-- Auto-refresh player list periodically
task.spawn(function()
    while true do
        task.wait(30)
        if _G.refreshCurr and _G.appTitle and _G.appTitle.Text == "Save & Teleport" then
            _G.refreshCurr()
        end
    end
end)

print("[Teleport] Purple Glass Teleport App Loaded!")