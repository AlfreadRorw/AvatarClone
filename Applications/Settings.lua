-- ================================================
-- SETTINGS APP - Final Version with All Features
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
local Config = _G.Config
local Assets = _G.Assets

local appContent = _G.appContent
local appSettings = Storage and Storage.appSettings or {}

local corner = Helpers.corner
local stroke = Helpers.stroke
local tween = Helpers.tween
local pressFX = Helpers.pressFX

-- ==================== COLORS ====================
local colors = {
    card = Color3.fromRGB(255, 255, 255),
    cardHover = Color3.fromRGB(248, 248, 252),
    accent = Color3.fromRGB(30, 30, 35),
    accent2 = Color3.fromRGB(0, 150, 255),
    gold = Color3.fromRGB(255, 180, 50),
    green = Color3.fromRGB(0, 200, 100),
    red = Color3.fromRGB(255, 80, 80),
    text = Color3.fromRGB(30, 30, 35),
    text2 = Color3.fromRGB(100, 100, 110),
    text3 = Color3.fromRGB(150, 150, 160),
    border = Color3.fromRGB(220, 220, 225),
}

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

    -- Title with accent line
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
    -- ==================== KEY TIMER SECTION ====================
    local timerSection = createSection("KEY STATUS", 1)
    local timerCard = createCard(timerSection, 1)

    -- Timer label
    local timerLabel = Instance.new("TextLabel", timerCard)
    timerLabel.Size = UDim2.new(1, 0, 0, 16)
    timerLabel.BackgroundTransparency = 1
    timerLabel.Text = "WAKTU TERSISA"
    timerLabel.TextColor3 = colors.text3
    timerLabel.Font = Enum.Font.GothamBold
    timerLabel.TextSize = 8
    timerLabel.TextXAlignment = Enum.TextXAlignment.Center
    timerLabel.LayoutOrder = 0

    -- Timer display
    local timerDisplay = Instance.new("TextLabel", timerCard)
    timerDisplay.Size = UDim2.new(1, 0, 0, 40)
    timerDisplay.BackgroundTransparency = 1
    timerDisplay.Text = "00:00:00"
    timerDisplay.TextColor3 = colors.text
    timerDisplay.Font = Enum.Font.GothamBlack
    timerDisplay.TextSize = 28
    timerDisplay.LayoutOrder = 1

    -- Status badge
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

    -- Timer update function
    local function updateTimer()
        local savedKey = nil
        if Storage and Storage.appSettings then
            savedKey = Storage.appSettings.savedKey
        end

        if savedKey and savedKey ~= "" and Firebase and Firebase.GetKeyTimeRemaining then
            local ok, remaining = pcall(function()
                return Firebase.GetKeyTimeRemaining(LocalPlayer.UserId, savedKey)
            end)

            if ok and remaining and remaining > 0 then
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
        else
            timerDisplay.Text = "NO KEY"
            timerDisplay.TextColor3 = colors.text3
            statusBadge.Text = "INACTIVE"
            statusBadge.TextColor3 = colors.text3
            statusBadge.BackgroundColor3 = colors.text3
        end
    end

    -- Jalankan timer loop
    task.spawn(function()
        while timerDisplay.Parent do
            updateTimer()
            task.wait(1)
        end
    end)

    -- ==================== DEVELOPER PROFILE ====================
    local devSection = createSection("DEVELOPER", 2)
    local devCard = createCard(devSection, 1)

    local devHeader = Instance.new("Frame", devCard)
    devHeader.Size = UDim2.new(1, 0, 0, 65)
    devHeader.BackgroundTransparency = 1
    devHeader.LayoutOrder = 0

    -- Avatar with gold border
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
    avatarImage.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. (Config.DEVELOPER_USER_ID or LocalPlayer.UserId) .. "&width=100&height=100&format=png"
    avatarImage.ZIndex = 3
    corner(avatarImage, 100)

    -- Developer name
    local devName = Instance.new("TextLabel", devHeader)
    devName.Size = UDim2.new(1, -65, 0, 22)
    devName.Position = UDim2.new(0, 65, 0, 12)
    devName.BackgroundTransparency = 1
    devName.Text = Config.DEVELOPER_USERNAME or "AlfreadR0rw"
    devName.TextColor3 = colors.text
    devName.Font = Enum.Font.GothamBlack
    devName.TextSize = 14
    devName.TextXAlignment = Enum.TextXAlignment.Left
    devName.ZIndex = 2

    -- Role badge
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

    -- User ID
    local devUserId = Instance.new("TextLabel", devHeader)
    devUserId.Size = UDim2.new(1, -65, 0, 14)
    devUserId.Position = UDim2.new(0, 120, 0, 38)
    devUserId.BackgroundTransparency = 1
    devUserId.Text = "ID: " .. (Config.DEVELOPER_USER_ID or LocalPlayer.UserId)
    devUserId.TextColor3 = colors.text3
    devUserId.Font = Enum.Font.Code
    devUserId.TextSize = 9
    devUserId.TextXAlignment = Enum.TextXAlignment.Left
    devUserId.ZIndex = 2

    -- ==================== SOCIAL MEDIA ====================
    local socialSection = createSection("SOCIAL MEDIA", 3)
    local socialCard = createCard(socialSection, 1)

    local function createSocialButton(parent, order, name, iconName, link)
        local btn = Instance.new("TextButton", parent)
        btn.Size = UDim2.new(1, 0, 0, 50)
        btn.BackgroundColor3 = colors.cardHover
        btn.LayoutOrder = order
        btn.AutoButtonColor = false
        btn.BorderSizePixel = 0
        corner(btn, 12)
        stroke(btn, colors.border, 1, 0.3)
        pressFX(btn)

        -- Icon dari Assets
        local iconFrame = Instance.new("Frame", btn)
        iconFrame.Size = UDim2.new(0, 34, 0, 34)
        iconFrame.Position = UDim2.new(0, 8, 0.5, -17)
        iconFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        iconFrame.ZIndex = 2
        corner(iconFrame, 10)

        local iconImage = Instance.new("ImageLabel", iconFrame)
        iconImage.Size = UDim2.new(1, -8, 1, -8)
        iconImage.Position = UDim2.new(0, 4, 0, 4)
        iconImage.BackgroundTransparency = 1
        iconImage.Image = Assets.GetIcon(iconName)
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
        subLbl.Text = "Klik untuk copy link"
        subLbl.TextColor3 = colors.text3
        subLbl.Font = Enum.Font.Gotham
        subLbl.TextSize = 8
        subLbl.TextXAlignment = Enum.TextXAlignment.Left
        subLbl.ZIndex = 2

        btn.MouseButton1Click:Connect(function()
            Helpers.copyToClipboard(link)
            _G.showDynamicNotification(name .. " link copied!", colors.accent2)
        end)

        return btn
    end

    createSocialButton(socialCard, 0, "Discord", "discord", Config.DiscordURL or "")
    createSocialButton(socialCard, 1, "WhatsApp", "whatsapp", Config.WhatsAppURL or "")
    createSocialButton(socialCard, 2, "Telegram", "telegram", Config.TelegramURL or "")

    -- ==================== TOGGLES ====================
    local toggleSection = createSection("PENGATURAN", 4)
    local toggleCard = createCard(toggleSection, 1)

    local function createToggleRow(parent, order, title, description, initialState, onChange)
        local row = Instance.new("Frame", parent)
        row.Size = UDim2.new(1, 0, 0, 42)
        row.BackgroundTransparency = 1
        row.LayoutOrder = order

        local textFrame = Instance.new("Frame", row)
        textFrame.Size = UDim2.new(1, -60, 1, 0)
        textFrame.BackgroundTransparency = 1

        local titleLbl = Instance.new("TextLabel", textFrame)
        titleLbl.Size = UDim2.new(1, 0, 0, 20)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = title
        titleLbl.TextColor3 = colors.text
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.TextSize = 11
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left

        local descLbl = Instance.new("TextLabel", textFrame)
        descLbl.Size = UDim2.new(1, 0, 0, 16)
        descLbl.Position = UDim2.new(0, 0, 0, 20)
        descLbl.BackgroundTransparency = 1
        descLbl.Text = description
        descLbl.TextColor3 = colors.text3
        descLbl.Font = Enum.Font.Gotham
        descLbl.TextSize = 8
        descLbl.TextXAlignment = Enum.TextXAlignment.Left

        local toggle = Helpers.buildToggle(row, initialState, onChange)
        toggle.Position = UDim2.new(1, -50, 0.5, -13)

        return row
    end

    createToggleRow(toggleCard, 0, "Dynamic Island", "Notifikasi di atas layar", appSettings.toastEnabled ~= false, function(state)
        appSettings.toastEnabled = state
        Storage.persistSettings()
        _G.showDynamicNotification("Toast " .. (state and "ON" or "OFF"), colors.accent2)
    end)

    createToggleRow(toggleCard, 1, "Glow Effect", "Efek cahaya di pinggir phone", appSettings.glowEnabled ~= false, function(state)
        appSettings.glowEnabled = state
        Storage.persistSettings()
    end)

    -- ==================== QUICK ACTIONS ====================
    local actionSection = createSection("AKSI CEPAT", 5)
    local actionCard = createCard(actionSection, 1)

    local function createActionButton(parent, order, title, iconName, onClick)
        local btn = Instance.new("TextButton", parent)
        btn.Size = UDim2.new(1, 0, 0, 42)
        btn.BackgroundColor3 = colors.cardHover
        btn.LayoutOrder = order
        btn.AutoButtonColor = false
        btn.BorderSizePixel = 0
        corner(btn, 10)
        stroke(btn, colors.border, 1, 0.3)
        pressFX(btn)

        -- Icon
        local iconImage = Instance.new("ImageLabel", btn)
        iconImage.Size = UDim2.new(0, 22, 0, 22)
        iconImage.Position = UDim2.new(0, 10, 0.5, -11)
        iconImage.BackgroundTransparency = 1
        iconImage.Image = Assets.GetIcon(iconName)
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

        btn.MouseButton1Click:Connect(onClick)
        return btn
    end

    createActionButton(actionCard, 0, "Rejoin Server", "wifi", function()
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId)
        end)
    end)

    createActionButton(actionCard, 1, "Copy User ID", "clipboard", function()
        Helpers.copyToClipboard(tostring(LocalPlayer.UserId))
        _G.showDynamicNotification("User ID copied!", colors.green)
    end)

    createActionButton(actionCard, 2, "Copy Key", "keys", function()
        local savedKey = appSettings.savedKey
        if savedKey and savedKey ~= "" then
            Helpers.copyToClipboard(savedKey)
            _G.showDynamicNotification("Key copied!", colors.green)
        else
            _G.showDynamicNotification("No key saved", colors.red)
        end
    end)

    createActionButton(actionCard, 3, "Buy Key", "link", function()
        local url = Config.BUY_KEY_URL or "https://discord.gg/"
        Helpers.copyToClipboard(url)
        _G.showDynamicNotification("Link copied!", colors.gold)
    end)

    -- ==================== MAP INFO ====================
    local mapSection = createSection("MAP INFO", 6)
    local mapCard = createCard(mapSection, 1)

    local mapRow = Instance.new("Frame", mapCard)
    mapRow.Size = UDim2.new(1, 0, 0, 30)
    mapRow.BackgroundTransparency = 1
    mapRow.LayoutOrder = 0

    local mapIcon = Instance.new("ImageLabel", mapRow)
    mapIcon.Size = UDim2.new(0, 20, 0, 20)
    mapIcon.Position = UDim2.new(0, 10, 0.5, -10)
    mapIcon.BackgroundTransparency = 1
    mapIcon.Image = Assets.GetIcon("website")
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

    -- Load map name
    task.spawn(function()
        local success, result = pcall(function()
            return MarketplaceService:GetProductInfo(game.PlaceId)
        end)
        if success and result and result.Name then
            mapNameLbl.Text = result.Name
        else
            mapNameLbl.Text = "Unknown Map"
        end
    end)

    -- Job ID
    local jobRow = Instance.new("Frame", mapCard)
    jobRow.Size = UDim2.new(1, 0, 0, 25)
    jobRow.BackgroundTransparency = 1
    jobRow.LayoutOrder = 1

    local jobLbl = Instance.new("TextLabel", jobRow)
    jobLbl.Size = UDim2.new(1, 0, 1, 0)
    jobLbl.BackgroundTransparency = 1
    jobLbl.Text = "Job ID: " .. game.JobId
    jobLbl.TextColor3 = colors.text3
    jobLbl.Font = Enum.Font.Code
    jobLbl.TextSize = 9
    jobLbl.TextXAlignment = Enum.TextXAlignment.Center
    jobLbl.ZIndex = 2

    -- ==================== INFO ====================
    local infoSection = createSection("INFO", 7)
    local infoCard = createCard(infoSection, 1)

    local infoLbl = Instance.new("TextLabel", infoCard)
    infoLbl.Size = UDim2.new(1, 0, 0, 20)
    infoLbl.BackgroundTransparency = 1
    infoLbl.Text = "Version 2.2.0"
    infoLbl.TextColor3 = colors.text3
    infoLbl.Font = Enum.Font.Gotham
    infoLbl.TextSize = 9
    infoLbl.TextXAlignment = Enum.TextXAlignment.Center
    infoLbl.LayoutOrder = 0

    local copyrightLbl = Instance.new("TextLabel", infoCard)
    copyrightLbl.Size = UDim2.new(1, 0, 0, 16)
    copyrightLbl.BackgroundTransparency = 1
    copyrightLbl.Text = "Copyright 2024 " .. (Config.DEVELOPER_USERNAME or "AlfreadR0rw")
    copyrightLbl.TextColor3 = colors.text3
    copyrightLbl.Font = Enum.Font.Gotham
    copyrightLbl.TextSize = 8
    copyrightLbl.TextXAlignment = Enum.TextXAlignment.Center
    copyrightLbl.LayoutOrder = 1
end

print("[Settings] App loaded!")