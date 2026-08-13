-- ================================================
-- SETTINGS APP - Elegant Version
-- ================================================

local Services = _G.Services
local LocalPlayer = _G.LocalPlayer
local Players = Services.Players
local TweenService = Services.TweenService
local TeleportService = Services.TeleportService
local HttpService = Services.HttpService
local T = _G.T
local Helpers = _G.Helpers
local Storage = _G.Storage
local Firebase = _G.Firebase
local Config = _G.Config

local appContent = _G.appContent
local appSettings = Storage.appSettings

local corner = Helpers.corner
local stroke = Helpers.stroke
local tween = Helpers.tween
local pressFX = Helpers.pressFX
local gradient = Helpers.gradient

-- ==================== COLOR PALETTE ====================
local colors = {
    bg = Color3.fromRGB(18, 18, 24),
    card = Color3.fromRGB(25, 25, 32),
    card2 = Color3.fromRGB(30, 30, 38),
    accent = Color3.fromRGB(255, 255, 255),
    accent2 = Color3.fromRGB(0, 200, 255),
    gold = Color3.fromRGB(255, 200, 50),
    green = Color3.fromRGB(0, 255, 100),
    red = Color3.fromRGB(255, 80, 80),
    text = Color3.fromRGB(255, 255, 255),
    text2 = Color3.fromRGB(150, 150, 170),
    text3 = Color3.fromRGB(100, 100, 120),
    border = Color3.fromRGB(50, 50, 60),
}

-- ==================== SECTION BUILDER ====================
local function createSection(title, subtitle, order)
    local section = Instance.new("Frame", appContent)
    section.Size = UDim2.new(1, 0, 0, 0)
    section.AutomaticSize = Enum.AutomaticSize.Y
    section.BackgroundTransparency = 1
    section.LayoutOrder = order
    
    local sectionLayout = Instance.new("UIListLayout", section)
    sectionLayout.Padding = UDim.new(0, 8)
    sectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- Title container
    local titleFrame = Instance.new("Frame", section)
    titleFrame.Size = UDim2.new(1, 0, 0, 35)
    titleFrame.BackgroundTransparency = 1
    titleFrame.LayoutOrder = 0
    
    -- Accent line
    local accentLine = Instance.new("Frame", titleFrame)
    accentLine.Size = UDim2.new(0, 3, 0, 20)
    accentLine.Position = UDim2.new(0, 0, 0.5, -10)
    accentLine.BackgroundColor3 = colors.accent2
    accentLine.BorderSizePixel = 0
    accentLine.ZIndex = 2
    corner(accentLine, 2)
    
    -- Title text
    local titleLbl = Instance.new("TextLabel", titleFrame)
    titleLbl.Size = UDim2.new(1, -20, 0, 18)
    titleLbl.Position = UDim2.new(0, 10, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = colors.text
    titleLbl.Font = Enum.Font.GothamBlack
    titleLbl.TextSize = 11
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 2
    
    -- Subtitle
    if subtitle then
        local subtitleLbl = Instance.new("TextLabel", titleFrame)
        subtitleLbl.Size = UDim2.new(1, -20, 0, 14)
        subtitleLbl.Position = UDim2.new(0, 10, 0, 18)
        subtitleLbl.BackgroundTransparency = 1
        subtitleLbl.Text = subtitle
        subtitleLbl.TextColor3 = colors.text3
        subtitleLbl.Font = Enum.Font.Gotham
        subtitleLbl.TextSize = 8
        subtitleLbl.TextXAlignment = Enum.TextXAlignment.Left
        subtitleLbl.ZIndex = 2
    end
    
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
    stroke(card, colors.border, 1, 0.5)
    
    -- Gradient
    gradient(card, ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 36)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 26))
    }), 135)
    
    local cardLayout = Instance.new("UIListLayout", card)
    cardLayout.Padding = UDim.new(0, 6)
    cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    return card
end

-- ==================== OPEN SETTINGS APP ====================
function _G.openSettingsApp()
    -- ==================== DEVELOPER PROFILE ====================
    local devSection = createSection("DEVELOPER", "Pembuat script ini", 1)
    
    local devCard = createCard(devSection, 1)
    devCard.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    stroke(devCard, colors.gold, 2, 0.3)
    
    -- Developer header
    local devHeader = Instance.new("Frame", devCard)
    devHeader.Size = UDim2.new(1, 0, 0, 75)
    devHeader.BackgroundTransparency = 1
    devHeader.LayoutOrder = 0
    
    -- Avatar dengan glow
    local avatarGlow = Instance.new("Frame", devHeader)
    avatarGlow.Size = UDim2.new(0, 60, 0, 60)
    avatarGlow.Position = UDim2.new(0, 10, 0.5, -30)
    avatarGlow.BackgroundColor3 = colors.gold
    avatarGlow.BackgroundTransparency = 0.7
    avatarGlow.ZIndex = 1
    corner(avatarGlow, 100)
    
    local avatarFrame = Instance.new("Frame", devHeader)
    avatarFrame.Size = UDim2.new(0, 52, 0, 52)
    avatarFrame.Position = UDim2.new(0, 14, 0.5, -26)
    avatarFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
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
    
    -- Developer info
    local devName = Instance.new("TextLabel", devHeader)
    devName.Size = UDim2.new(1, -80, 0, 22)
    devName.Position = UDim2.new(0, 76, 0, 15)
    devName.BackgroundTransparency = 1
    devName.Text = Config.DEVELOPER_USERNAME or "AlfreadR0rw"
    devName.TextColor3 = colors.text
    devName.Font = Enum.Font.GothamBlack
    devName.TextSize = 14
    devName.TextXAlignment = Enum.TextXAlignment.Left
    devName.ZIndex = 2
    
    -- Role badge
    local devRole = Instance.new("TextLabel", devHeader)
    devRole.Size = UDim2.new(0, 45, 0, 18)
    devRole.Position = UDim2.new(0, 76, 0, 40)
    devRole.BackgroundColor3 = colors.gold
    devRole.Text = "OWNER"
    devRole.TextColor3 = Color3.fromRGB(0, 0, 0)
    devRole.Font = Enum.Font.GothamBlack
    devRole.TextSize = 8
    devRole.ZIndex = 2
    corner(devRole, 9)
    
    -- User ID
    local devUserId = Instance.new("TextLabel", devHeader)
    devUserId.Size = UDim2.new(1, -80, 0, 16)
    devUserId.Position = UDim2.new(0, 126, 0, 40)
    devUserId.BackgroundTransparency = 1
    devUserId.Text = "ID: " .. (Config.DEVELOPER_USER_ID or LocalPlayer.UserId)
    devUserId.TextColor3 = colors.text3
    devUserId.Font = Enum.Font.Code
    devUserId.TextSize = 9
    devUserId.TextXAlignment = Enum.TextXAlignment.Left
    devUserId.ZIndex = 2
    
    -- Divider
    local divider = Instance.new("Frame", devCard)
    divider.Size = UDim2.new(1, -24, 0, 1)
    divider.Position = UDim2.new(0, 12, 0, 75)
    divider.BackgroundColor3 = colors.border
    divider.BorderSizePixel = 0
    divider.LayoutOrder = 1
    
    -- ==================== KEY COUNTDOWN ====================
    local timerSection = createSection("KEY STATUS", "Masa berlaku key Anda", 2)
    
    local timerCard = createCard(timerSection, 1)
    
    -- Timer display
    local timerContainer = Instance.new("Frame", timerCard)
    timerContainer.Size = UDim2.new(1, 0, 0, 60)
    timerContainer.BackgroundTransparency = 1
    timerContainer.LayoutOrder = 0
    
    -- Timer label
    local timerLabel = Instance.new("TextLabel", timerContainer)
    timerLabel.Size = UDim2.new(1, 0, 0, 15)
    timerLabel.BackgroundTransparency = 1
    timerLabel.Text = "WAKTU TERSISA"
    timerLabel.TextColor3 = colors.text3
    timerLabel.Font = Enum.Font.GothamBold
    timerLabel.TextSize = 8
    timerLabel.TextXAlignment = Enum.TextXAlignment.Center
    timerLabel.ZIndex = 2
    
    -- Timer display
    local timerDisplay = Instance.new("TextLabel", timerContainer)
    timerDisplay.Size = UDim2.new(1, 0, 0, 35)
    timerDisplay.Position = UDim2.new(0, 0, 0, 15)
    timerDisplay.BackgroundTransparency = 1
    timerDisplay.Text = "--:--:--"
    timerDisplay.TextColor3 = colors.text
    timerDisplay.Font = Enum.Font.GothamBlack
    timerDisplay.TextSize = 24
    timerDisplay.ZIndex = 2
    
    -- Status badge
    local statusBadge = Instance.new("TextLabel", timerContainer)
    statusBadge.Size = UDim2.new(0, 80, 0, 16)
    statusBadge.Position = UDim2.new(0.5, -40, 0, 50)
    statusBadge.BackgroundColor3 = colors.green
    statusBadge.BackgroundTransparency = 0.8
    statusBadge.Text = "ACTIVE"
    statusBadge.TextColor3 = colors.green
    statusBadge.Font = Enum.Font.GothamBlack
    statusBadge.TextSize = 8
    statusBadge.ZIndex = 2
    corner(statusBadge, 8)
    
    -- Update timer
    task.spawn(function()
        while timerDisplay.Parent do
            local savedKey = appSettings.savedKey
            if savedKey and savedKey ~= "" then
                local keyData = Firebase.GetData("keys/" .. savedKey)
                if keyData and keyData.expires then
                    local now = os.time()
                    local remaining = keyData.expires - now
                    
                    if remaining > 0 then
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
                        timerDisplay.Text = "EXPIRED"
                        timerDisplay.TextColor3 = colors.red
                        statusBadge.Text = "EXPIRED"
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
            
            task.wait(1)
        end
    end)
    
    -- ==================== TOGGLES ====================
    local toggleSection = createSection("PENGATURAN", "Atur preferensi Anda", 3)
    
    local toggleCard = createCard(toggleSection, 1)
    
    local function createToggleRow(parent, order, title, description, initialState, onChange)
        local row = Instance.new("Frame", parent)
        row.Size = UDim2.new(1, 0, 0, 45)
        row.BackgroundTransparency = 1
        row.LayoutOrder = order
        
        -- Text
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
        
        -- Toggle
        local toggle = Helpers.buildToggle(row, initialState, onChange)
        toggle.Position = UDim2.new(1, -50, 0.5, -13)
        
        return row
    end
    
    createToggleRow(toggleCard, 0, "Dynamic Island", "Notifikasi di atas layar", appSettings.toastEnabled ~= false, function(state)
        appSettings.toastEnabled = state
        Storage.persistSettings()
        Helpers.showDynamicNotification("Toast " .. (state and "ON" or "OFF"), colors.accent2)
    end)
    
    createToggleRow(toggleCard, 1, "Glow Effect", "Efek cahaya di pinggir phone", appSettings.glowEnabled ~= false, function(state)
        appSettings.glowEnabled = state
        Storage.persistSettings()
    end)
    
    -- ==================== QUICK ACTIONS ====================
    local actionSection = createSection("AKSI CEPAT", "Fungsi berguna", 4)
    
    local actionCard = createCard(actionSection, 1)
    
    local function createActionButton(parent, order, title, subtitle, onClick)
        local btn = Instance.new("TextButton", parent)
        btn.Size = UDim2.new(1, 0, 0, 48)
        btn.BackgroundColor3 = colors.card2
        btn.LayoutOrder = order
        btn.AutoButtonColor = false
        btn.BorderSizePixel = 0
        corner(btn, 10)
        stroke(btn, colors.border, 1, 0.3)
        pressFX(btn)
        
        -- Title
        local titleLbl = Instance.new("TextLabel", btn)
        titleLbl.Size = UDim2.new(1, -20, 0, 20)
        titleLbl.Position = UDim2.new(0, 10, 0, 6)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = title
        titleLbl.TextColor3 = colors.text
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.TextSize = 11
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        
        -- Subtitle
        if subtitle then
            local subtitleLbl = Instance.new("TextLabel", btn)
            subtitleLbl.Size = UDim2.new(1, -20, 0, 16)
            subtitleLbl.Position = UDim2.new(0, 10, 0, 26)
            subtitleLbl.BackgroundTransparency = 1
            subtitleLbl.Text = subtitle
            subtitleLbl.TextColor3 = colors.text3
            subtitleLbl.Font = Enum.Font.Gotham
            subtitleLbl.TextSize = 8
            subtitleLbl.TextXAlignment = Enum.TextXAlignment.Left
        end
        
        btn.MouseButton1Click:Connect(onClick)
        
        return btn
    end
    
    createActionButton(actionCard, 0, "Rejoin Server", "Bergabung kembali ke server", function()
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId)
        end)
    end)
    
    createActionButton(actionCard, 1, "Copy User ID", "Salin ID Roblox Anda", function()
        Helpers.copyToClipboard(tostring(LocalPlayer.UserId))
        Helpers.showDynamicNotification("User ID copied!", colors.green)
    end)
    
    createActionButton(actionCard, 2, "Copy Key", "Salin key yang tersimpan", function()
        local savedKey = appSettings.savedKey
        if savedKey and savedKey ~= "" then
            Helpers.copyToClipboard(savedKey)
            Helpers.showDynamicNotification("Key copied!", colors.green)
        else
            Helpers.showDynamicNotification("No key saved", colors.red)
        end
    end)
    
    createActionButton(actionCard, 3, "Buy Key", "Dapatkan key baru", function()
        local url = Config.BUY_KEY_URL or "https://discord.gg/"
        Helpers.copyToClipboard(url)
        Helpers.showDynamicNotification("Link copied!", colors.gold)
    end)
    
    -- ==================== INFO ====================
    local infoSection = createSection("INFORMASI", "Tentang script ini", 5)
    
    local infoCard = createCard(infoSection, 1)
    
    -- Version
    local versionRow = Instance.new("Frame", infoCard)
    versionRow.Size = UDim2.new(1, 0, 0, 25)
    versionRow.BackgroundTransparency = 1
    versionRow.LayoutOrder = 0
    
    local versionLabel = Instance.new("TextLabel", versionRow)
    versionLabel.Size = UDim2.new(0, 80, 1, 0)
    versionLabel.BackgroundTransparency = 1
    versionLabel.Text = "Version"
    versionLabel.TextColor3 = colors.text3
    versionLabel.Font = Enum.Font.Gotham
    versionLabel.TextSize = 9
    versionLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local versionValue = Instance.new("TextLabel", versionRow)
    versionValue.Size = UDim2.new(1, -90, 1, 0)
    versionValue.Position = UDim2.new(0, 85, 0, 0)
    versionValue.BackgroundTransparency = 1
    versionValue.Text = "2.1.0"
    versionValue.TextColor3 = colors.accent2
    versionValue.Font = Enum.Font.GothamBold
    versionValue.TextSize = 9
    versionValue.TextXAlignment = Enum.TextXAlignment.Right
    
    -- Copyright
    local copyrightRow = Instance.new("Frame", infoCard)
    copyrightRow.Size = UDim2.new(1, 0, 0, 25)
    copyrightRow.BackgroundTransparency = 1
    copyrightRow.LayoutOrder = 1
    
    local copyrightLbl = Instance.new("TextLabel", copyrightRow)
    copyrightLbl.Size = UDim2.new(1, 0, 1, 0)
    copyrightLbl.BackgroundTransparency = 1
    copyrightLbl.Text = "© 2024 " .. (Config.DEVELOPER_USERNAME or "AlfreadR0rw")
    copyrightLbl.TextColor3 = colors.text3
    copyrightLbl.Font = Enum.Font.Gotham
    copyrightLbl.TextSize = 8
    copyrightLbl.TextXAlignment = Enum.TextXAlignment.Center
    
    -- Credit
    local creditLbl = Instance.new("TextLabel", infoCard)
    creditLbl.Size = UDim2.new(1, 0, 0, 20)
    creditLbl.BackgroundTransparency = 1
    creditLbl.Text = "Dibuat dengan dedikasi"
    creditLbl.TextColor3 = colors.text3
    creditLbl.Font = Enum.Font.Gotham
    creditLbl.TextSize = 8
    creditLbl.TextXAlignment = Enum.TextXAlignment.Center
    creditLbl.LayoutOrder = 2
end

print("[Settings] App loaded!")