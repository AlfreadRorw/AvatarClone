-- ================================================
-- SETTINGS APP - Fixed Lifecycle, Performance, Validation
-- ================================================

local Services = _G.Services
local LocalPlayer = _G.LocalPlayer
local Players = Services.Players
local TeleportService = Services.TeleportService
local MarketplaceService = Services.MarketplaceService
local T = _G.T
local Helpers = _G.Helpers
local Storage = _G.Storage
local Firebase = _G.Firebase
local Config = _G.Config or {}
local Assets = _G.Assets

local appContent = _G.appContent
local appSettings = Storage and Storage.appSettings or {}

local corner = Helpers.corner
local stroke = Helpers.stroke
local tween = Helpers.tween
local pressFX = Helpers.pressFX

-- ==================== DARK THEME COLORS ====================
local colors = {
    card = Color3.fromRGB(25, 25, 32),
    card2 = Color3.fromRGB(30, 30, 38),
    cardHover = Color3.fromRGB(35, 35, 45),
    accent = Color3.fromRGB(255, 255, 255),
    accent2 = Color3.fromRGB(0, 200, 255),
    gold = Color3.fromRGB(255, 180, 50),
    green = Color3.fromRGB(0, 230, 118),
    red = Color3.fromRGB(255, 82, 82),
    text = Color3.fromRGB(255, 255, 255),
    text2 = Color3.fromRGB(170, 170, 180),
    text3 = Color3.fromRGB(100, 100, 115),
    border = Color3.fromRGB(45, 45, 55),
}

-- ==================== LIFECYCLE MANAGER ====================
local SettingsLifecycle = {
    active = false,
    tasks = {},
    connections = {},
}

local function addTask(fn)
    local taskId = #SettingsLifecycle.tasks + 1
    SettingsLifecycle.tasks[taskId] = task(fn)
    return taskId
end

local function addConnection(conn)
    table.insert(SettingsLifecycle.connections, conn)
    return conn
end

local function cleanupSettings()
    SettingsLifecycle.active = false
    
    -- Cancel all tasks
    for _, taskId in ipairs(SettingsLifecycle.tasks) do
        pcall(function() task.cancel(taskId) end)
    end
    SettingsLifecycle.tasks = {}
    
    -- Disconnect all connections
    for _, conn in ipairs(SettingsLifecycle.connections) do
        pcall(function() conn:Disconnect() end)
    end
    SettingsLifecycle.connections = {}
end

-- Register cleanup to global
table.insert(_G.AvatarCloneCleanupTasks or {}, cleanupSettings)

-- ==================== SAFE DEPENDENCY CHECK ====================
local function getConfigValue(key, default)
    if Config and Config[key] ~= nil then
        return Config[key]
    end
    return default
end

local function getAssetIcon(name)
    if Assets and Assets.GetIcon then
        local icon = Assets.GetIcon(name)
        if icon and icon ~= "" then
            return icon
        end
    end
    return "" -- Safe fallback
end

-- ==================== BUILDER FUNCTIONS ====================
local function createSection(title, order)
    local section = Instance.new("Frame", appContent)
    section.Size = UDim2.new(1, 0, 0, 0)
    section.AutomaticSize = Enum.AutomaticSize.Y
    section.BackgroundTransparency = 1
    section.LayoutOrder = order

    local layout = Instance.new("UIListLayout", section)
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local titleFrame = Instance.new("Frame", section)
    titleFrame.Size = UDim2.new(1, 0, 0, 25)
    titleFrame.BackgroundTransparency = 1
    titleFrame.LayoutOrder = 0

    local accentLine = Instance.new("Frame", titleFrame)
    accentLine.Size = UDim2.new(0, 3, 0, 16)
    accentLine.Position = UDim2.new(0, 0, 0.5, -8)
    accentLine.BackgroundColor3 = colors.accent2
    accentLine.BorderSizePixel = 0
    corner(accentLine, 2)

    local titleLbl = Instance.new("TextLabel", titleFrame)
    titleLbl.Size = UDim2.new(1, -20, 0, 20)
    titleLbl.Position = UDim2.new(0, 10, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = colors.text2
    titleLbl.Font = Enum.Font.GothamBlack
    titleLbl.TextSize = 10
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left

    return section
end

local function createCard(parent, order)
    local card = Instance.new("Frame", parent)
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = colors.card
    card.LayoutOrder = order
    card.BorderSizePixel = 0
    corner(card, 14)
    stroke(card, colors.border, 1, 0.3)

    local cardLayout = Instance.new("UIListLayout", card)
    cardLayout.Padding = UDim.new(0, 6)
    cardLayout.SortOrder = Enum.SortOrder.LayoutOrder

    return card
end

-- ==================== OPEN SETTINGS APP ====================
function _G.openSettingsApp()
    -- Cleanup previous instance
    cleanupSettings()
    SettingsLifecycle.active = true
    
    -- ==================== KEY TIMER (OPTIMIZED) ====================
    local timerSection = createSection("KEY STATUS", 1)
    local timerCard = createCard(timerSection, 1)

    local timerLabel = Instance.new("TextLabel", timerCard)
    timerLabel.Size = UDim2.new(1, 0, 0, 16)
    timerLabel.BackgroundTransparency = 1
    timerLabel.Text = "WAKTU TERSISA"
    timerLabel.TextColor3 = colors.text3
    timerLabel.Font = Enum.Font.GothamBold
    timerLabel.TextSize = 8
    timerLabel.TextXAlignment = Enum.TextXAlignment.Center
    timerLabel.LayoutOrder = 0

    local timerDisplay = Instance.new("TextLabel", timerCard)
    timerDisplay.Size = UDim2.new(1, 0, 0, 40)
    timerDisplay.BackgroundTransparency = 1
    timerDisplay.Text = "00:00:00"
    timerDisplay.TextColor3 = colors.text
    timerDisplay.Font = Enum.Font.GothamBlack
    timerDisplay.TextSize = 28
    timerDisplay.LayoutOrder = 1

    local statusBadge = Instance.new("TextLabel", timerCard)
    statusBadge.Size = UDim2.new(0, 90, 0, 20)
    statusBadge.Position = UDim2.new(0.5, -45, 0, 58)
    statusBadge.BackgroundColor3 = colors.green
    statusBadge.BackgroundTransparency = 0.85
    statusBadge.Text = "ACTIVE"
    statusBadge.TextColor3 = colors.green
    statusBadge.Font = Enum.Font.GothamBlack
    statusBadge.TextSize = 8
    statusBadge.LayoutOrder = 2
    corner(statusBadge, 10)

    -- Optimized timer: fetch expiry once, countdown locally
    local keyExpiryTimestamp = nil
    local lastFirebaseCheck = 0
    
    local function fetchKeyExpiry()
        local savedKey = nil
        if Storage and Storage.appSettings then
            savedKey = Storage.appSettings.savedKey
        end
        
        if not savedKey or savedKey == "" then
            keyExpiryTimestamp = nil
            return nil
        end
        
        if Firebase and Firebase.GetData then
            local ok, keyData = pcall(function()
                return Firebase.GetData("keys/" .. savedKey)
            end)
            
            if ok and keyData and keyData.expires then
                keyExpiryTimestamp = tonumber(keyData.expires)
                return keyExpiryTimestamp
            end
        end
        
        keyExpiryTimestamp = nil
        return nil
    end
    
    local function updateTimerDisplay()
        local now = os.time()
        
        -- Refresh from Firebase every 30 seconds
        if (now - lastFirebaseCheck) >= 30 then
            fetchKeyExpiry()
            lastFirebaseCheck = now
        end
        
        if keyExpiryTimestamp and keyExpiryTimestamp > now then
            local remaining = keyExpiryTimestamp - now
            local hours = math.floor(remaining / 3600)
            local minutes = math.floor((remaining % 3600) / 60)
            local seconds = remaining % 60
            
            timerDisplay.Text = string.format("%02d:%02d:%02d", hours, minutes, seconds)
            
            if remaining > 3600 then
                timerDisplay.TextColor3 = colors.green
                statusBadge.Text = "ACTIVE"
                statusBadge.TextColor3 = colors.green
                statusBadge.BackgroundColor3 = colors.green
            elseif remaining > 600 then
                timerDisplay.TextColor3 = colors.gold
                statusBadge.Text = "WARNING"
                statusBadge.TextColor3 = colors.gold
                statusBadge.BackgroundColor3 = colors.gold
            else
                timerDisplay.TextColor3 = colors.red
                statusBadge.Text = "CRITICAL"
                statusBadge.TextColor3 = colors.red
                statusBadge.BackgroundColor3 = colors.red
            end
        else
            timerDisplay.Text = "NO KEY"
            timerDisplay.TextColor3 = colors.text3
            statusBadge.Text = "INACTIVE"
            statusBadge.TextColor3 = colors.text3
            statusBadge.BackgroundColor3 = colors.text3
        end
    end
    
    -- Initial fetch
    fetchKeyExpiry()
    lastFirebaseCheck = os.time()
    
    -- Local countdown loop (no HTTP every second)
    local timerTask = task.spawn(function()
        while SettingsLifecycle.active and timerDisplay.Parent do
            updateTimerDisplay()
            task.wait(1)
        end
    end)
    table.insert(SettingsLifecycle.tasks, timerTask)

    -- ==================== DEVELOPER PROFILE ====================
    local devSection = createSection("DEVELOPER", 2)
    local devCard = createCard(devSection, 1)

    local devHeader = Instance.new("Frame", devCard)
    devHeader.Size = UDim2.new(1, 0, 0, 65)
    devHeader.BackgroundTransparency = 1
    devHeader.LayoutOrder = 0

    local avatarFrame = Instance.new("Frame", devHeader)
    avatarFrame.Size = UDim2.new(0, 48, 0, 48)
    avatarFrame.Position = UDim2.new(0, 10, 0.5, -24)
    avatarFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    avatarFrame.BackgroundTransparency = 0.5
    avatarFrame.ZIndex = 2
    corner(avatarFrame, 100)
    stroke(avatarFrame, colors.gold, 2, 0)

    local avatarImage = Instance.new("ImageLabel", avatarFrame)
    avatarImage.Size = UDim2.new(1, -6, 1, -6)
    avatarImage.Position = UDim2.new(0, 3, 0, 3)
    avatarImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    
    -- Safe developer ID
    local devUserId = getConfigValue("DEVELOPER_USER_ID", nil) or LocalPlayer.UserId
    avatarImage.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. devUserId .. "&width=100&height=100&format=png"
    avatarImage.ZIndex = 3
    corner(avatarImage, 100)

    local devName = Instance.new("TextLabel", devHeader)
    devName.Size = UDim2.new(1, -65, 0, 22)
    devName.Position = UDim2.new(0, 65, 0, 12)
    devName.BackgroundTransparency = 1
    devName.Text = getConfigValue("DEVELOPER_USERNAME", "AlfreadR0rw")
    devName.TextColor3 = colors.text
    devName.Font = Enum.Font.GothamBlack
    devName.TextSize = 14
    devName.TextXAlignment = Enum.TextXAlignment.Left
    devName.ZIndex = 2

    local devRole = Instance.new("TextLabel", devHeader)
    devRole.Size = UDim2.new(0, 50, 0, 18)
    devRole.Position = UDim2.new(0, 65, 0, 36)
    devRole.BackgroundColor3 = colors.gold
    devRole.Text = "OWNER"
    devRole.TextColor3 = Color3.fromRGB(255, 255, 255)
    devRole.Font = Enum.Font.GothamBlack
    devRole.TextSize = 8
    devRole.ZIndex = 2
    corner(devRole, 9)

    -- ==================== SOCIAL MEDIA ====================
    local socialSection = createSection("SOCIAL MEDIA", 3)
    local socialCard = createCard(socialSection, 1)

    local function isPlaceholderLink(url)
        if not url or url == "" then
            return true
        end
        if url:find("yourdiscord") or url:find("yourusername") or url:find("6281234567890") then
            return true
        end
        return false
    end

    local function createSocialButton(parent, order, name, iconName, linkKey)
        local link = getConfigValue(linkKey, "")
        local isConfigured = not isPlaceholderLink(link)
        
        local btn = Instance.new("TextButton", parent)
        btn.Size = UDim2.new(1, 0, 0, 50)
        btn.BackgroundColor3 = colors.card2
        btn.LayoutOrder = order
        btn.AutoButtonColor = false
        btn.BorderSizePixel = 0
        corner(btn, 12)
        stroke(btn, colors.border, 1, 0.3)
        pressFX(btn)

        -- Icon
        local iconFrame = Instance.new("Frame", btn)
        iconFrame.Size = UDim2.new(0, 34, 0, 34)
        iconFrame.Position = UDim2.new(0, 8, 0.5, -17)
        iconFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        iconFrame.BackgroundTransparency = 0.9
        iconFrame.ZIndex = 2
        corner(iconFrame, 10)

        local iconImage = Instance.new("ImageLabel", iconFrame)
        iconImage.Size = UDim2.new(1, -8, 1, -8)
        iconImage.Position = UDim2.new(0, 4, 0, 4)
        iconImage.BackgroundTransparency = 1
        iconImage.Image = getAssetIcon(iconName)
        iconImage.ScaleType = Enum.ScaleType.Fit
        iconImage.ZIndex = 3

        local nameLbl = Instance.new("TextLabel", btn)
        nameLbl.Size = UDim2.new(1, -55, 0, 22)
        nameLbl.Position = UDim2.new(0, 50, 0, 8)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = name
        nameLbl.TextColor3 = colors.text
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 12
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.ZIndex = 2

        local subLbl = Instance.new("TextLabel", btn)
        subLbl.Size = UDim2.new(1, -55, 0, 16)
        subLbl.Position = UDim2.new(0, 50, 0, 28)
        subLbl.BackgroundTransparency = 1
        subLbl.Text = isConfigured and "Klik untuk copy link" or "Link belum dikonfigurasi"
        subLbl.TextColor3 = isConfigured and colors.text3 or colors.red
        subLbl.Font = Enum.Font.Gotham
        subLbl.TextSize = 8
        subLbl.TextXAlignment = Enum.TextXAlignment.Left
        subLbl.ZIndex = 2

        btn.MouseButton1Click:Connect(function()
            if not isConfigured then
                _G.showDynamicNotification(name .. " link belum dikonfigurasi", colors.red)
                return
            end
            
            local copyOk = Helpers.copyToClipboard(link)
            if copyOk then
                _G.showDynamicNotification(name .. " link copied!", colors.accent2)
            else
                _G.showDynamicNotification("Clipboard unavailable", colors.red)
            end
        end)

        return btn
    end

    createSocialButton(socialCard, 0, "Discord", "discord", "DiscordURL")
    createSocialButton(socialCard, 1, "WhatsApp", "whatsapp", "WhatsAppURL")
    createSocialButton(socialCard, 2, "Telegram", "telegram", "TelegramURL")

    -- ==================== QUICK ACTIONS ====================
    local actionSection = createSection("AKSI CEPAT", 4)
    local actionCard = createCard(actionSection, 1)

    local function createActionButton(parent, order, title, iconName, onClick)
        local btn = Instance.new("TextButton", parent)
        btn.Size = UDim2.new(1, 0, 0, 42)
        btn.BackgroundColor3 = colors.card2
        btn.LayoutOrder = order
        btn.AutoButtonColor = false
        btn.BorderSizePixel = 0
        corner(btn, 10)
        stroke(btn, colors.border, 1, 0.3)
        pressFX(btn)

        local iconImage = Instance.new("ImageLabel", btn)
        iconImage.Size = UDim2.new(0, 22, 0, 22)
        iconImage.Position = UDim2.new(0, 10, 0.5, -11)
        iconImage.BackgroundTransparency = 1
        iconImage.Image = getAssetIcon(iconName)
        iconImage.ScaleType = Enum.ScaleType.Fit
        iconImage.ZIndex = 2

        local titleLbl = Instance.new("TextLabel", btn)
        titleLbl.Size = UDim2.new(1, -40, 1, 0)
        titleLbl.Position = UDim2.new(0, 38, 0, 0)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = title
        titleLbl.TextColor3 = colors.text
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.TextSize = 11
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left

        if type(onClick) == "function" then
            btn.MouseButton1Click:Connect(onClick)
        end

        return btn
    end

    createActionButton(actionCard, 0, "Rejoin Server", "wifi", function()
        local ok, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId)
        end)
        if not ok then
            _G.showDynamicNotification("Rejoin gagal: " .. tostring(err), colors.red)
        end
    end)

    createActionButton(actionCard, 1, "Copy User ID", "clipboard", function()
        local copyOk = Helpers.copyToClipboard(tostring(LocalPlayer.UserId))
        if copyOk then
            _G.showDynamicNotification("User ID copied!", colors.green)
        else
            _G.showDynamicNotification("Clipboard unavailable", colors.red)
        end
    end)

    createActionButton(actionCard, 2, "Copy Key", "keys", function()
        local savedKey = appSettings.savedKey
        if savedKey and savedKey ~= "" then
            local copyOk = Helpers.copyToClipboard(savedKey)
            if copyOk then
                _G.showDynamicNotification("Key copied!", colors.green)
            else
                _G.showDynamicNotification("Clipboard unavailable", colors.red)
            end
        else
            _G.showDynamicNotification("No key saved", colors.red)
        end
    end)

    createActionButton(actionCard, 3, "Buy Key", "link", function()
        local url = getConfigValue("BUY_KEY_URL", "")
        
        if isPlaceholderLink(url) then
            _G.showDynamicNotification("Link belum dikonfigurasi", colors.red)
            return
        end
        
        local copyOk = Helpers.copyToClipboard(url)
        if copyOk then
            _G.showDynamicNotification("Link copied!", colors.gold)
        else
            _G.showDynamicNotification("Clipboard unavailable", colors.red)
        end
    end)

    -- ==================== MAP INFO ====================
    local mapSection = createSection("MAP INFO", 5)
    local mapCard = createCard(mapSection, 1)

    local mapRow = Instance.new("Frame", mapCard)
    mapRow.Size = UDim2.new(1, 0, 0, 30)
    mapRow.BackgroundTransparency = 1
    mapRow.LayoutOrder = 0

    local mapIcon = Instance.new("ImageLabel", mapRow)
    mapIcon.Size = UDim2.new(0, 20, 0, 20)
    mapIcon.Position = UDim2.new(0, 10, 0.5, -10)
    mapIcon.BackgroundTransparency = 1
    mapIcon.Image = getAssetIcon("website")
    mapIcon.ScaleType = Enum.ScaleType.Fit
    mapIcon.ZIndex = 2

    local mapNameLbl = Instance.new("TextLabel", mapRow)
    mapNameLbl.Size = UDim2.new(1, -40, 0, 20)
    mapNameLbl.Position = UDim2.new(0, 35, 0.5, -10)
    mapNameLbl.BackgroundTransparency = 1
    mapNameLbl.Text = "Loading..."
    mapNameLbl.TextColor3 = colors.text
    mapNameLbl.Font = Enum.Font.GothamBold
    mapNameLbl.TextSize = 11
    mapNameLbl.TextXAlignment = Enum.TextXAlignment.Left
    mapNameLbl.ZIndex = 2

    -- Map name with lifecycle-aware task
    local mapTask = task.spawn(function()
        local ok, result = pcall(function()
            return MarketplaceService:GetProductInfo(game.PlaceId)
        end)
        if ok and result and result.Name then
            if mapNameLbl.Parent then
                mapNameLbl.Text = result.Name
            end
        else
            if mapNameLbl.Parent then
                mapNameLbl.Text = "Unknown Map"
            end
        end
    end)
    table.insert(SettingsLifecycle.tasks, mapTask)

    -- ==================== INFO ====================
    local infoSection = createSection("INFO", 6)
    local infoCard = createCard(infoSection, 1)

    local infoLbl = Instance.new("TextLabel", infoCard)
    infoLbl.Size = UDim2.new(1, 0, 0, 20)
    infoLbl.BackgroundTransparency = 1
    infoLbl.Text = "Version 2.3.0"
    infoLbl.TextColor3 = colors.text3
    infoLbl.Font = Enum.Font.Gotham
    infoLbl.TextSize = 9
    infoLbl.TextXAlignment = Enum.TextXAlignment.Center
    infoLbl.LayoutOrder = 0

    local copyrightLbl = Instance.new("TextLabel", infoCard)
    copyrightLbl.Size = UDim2.new(1, 0, 0, 16)
    copyrightLbl.BackgroundTransparency = 1
    copyrightLbl.Text = "Copyright 2024 " .. getConfigValue("DEVELOPER_USERNAME", "AlfreadR0rw")
    copyrightLbl.TextColor3 = colors.text3
    copyrightLbl.Font = Enum.Font.Gotham
    copyrightLbl.TextSize = 8
    copyrightLbl.TextXAlignment = Enum.TextXAlignment.Center
    copyrightLbl.LayoutOrder = 1
end

print("[Settings] App loaded!")