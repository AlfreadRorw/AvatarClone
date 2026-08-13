-- ================================================
-- SETTINGS APP - Complete with Timer, Developer Info
-- ================================================

local Services = _G.Services
local LocalPlayer = _G.LocalPlayer
local Players = Services.Players
local TeleportService = Services.TeleportService
local T = _G.T
local Helpers = _G.Helpers
local Storage = _G.Storage
local Firebase = _G.Firebase
local Config = _G.Config

local appContent = _G.appContent
local appSettings = Storage and Storage.appSettings or {}

local corner = Helpers.corner
local stroke = Helpers.stroke
local tween = Helpers.tween
local pressFX = Helpers.pressFX

-- Colors - Clean light theme
local colors = {
    card = Color3.fromRGB(255, 255, 255),
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

-- ==================== HELPER FUNCTIONS ====================
local function createSection(title, order)
    local section = Instance.new("Frame", appContent)
    section.Size = UDim2.new(1, 0, 0, 0)
    section.AutomaticSize = Enum.AutomaticSize.Y
    section.BackgroundTransparency = 1
    section.LayoutOrder = order
    
    local layout = Instance.new("UIListLayout", section)
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    
    local titleLbl = Instance.new("TextLabel", section)
    titleLbl.Size = UDim2.new(1, 0, 0, 25)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = colors.text2
    titleLbl.Font = Enum.Font.GothamBlack
    titleLbl.TextSize = 10
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.LayoutOrder = 0
    
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
    cardLayout.Padding = UDim.new(0, 8)
    cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    return card
end

local function createDivider(parent, order)
    local divider = Instance.new("Frame", parent)
    divider.Size = UDim2.new(1, -20, 0, 1)
    divider.Position = UDim2.new(0, 10, 0, 0)
    divider.BackgroundColor3 = colors.border
    divider.BackgroundTransparency = 0.5
    divider.BorderSizePixel = 0
    divider.LayoutOrder = order
    return divider
end

local function createToggle(parent, order, title, description, initial, onChange)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, 0, 0, 50)
    container.BackgroundTransparency = 1
    container.LayoutOrder = order
    
    local titleLbl = Instance.new("TextLabel", container)
    titleLbl.Size = UDim2.new(1, -60, 0, 20)
    titleLbl.Position = UDim2.new(0, 0, 0, 6)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = colors.text
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 11
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local descLbl = Instance.new("TextLabel", container)
    descLbl.Size = UDim2.new(1, -60, 0, 16)
    descLbl.Position = UDim2.new(0, 0, 0, 26)
    descLbl.BackgroundTransparency = 1
    descLbl.Text = description or ""
    descLbl.TextColor3 = colors.text3
    descLbl.Font = Enum.Font.Gotham
    descLbl.TextSize = 8
    descLbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local toggle = Helpers.buildToggle(container, initial, onChange)
    toggle.Position = UDim2.new(1, -50, 0.5, -13)
    
    return container
end

-- ==================== OPEN SETTINGS APP ====================
function _G.openSettingsApp()
    -- ==================== KEY STATUS & TIMER ====================
    local timerSection = createSection("KEY STATUS", 1)
    local timerCard = createCard(timerSection, 1)
    
    -- Label kecil
    local timerLabel = Instance.new("TextLabel", timerCard)
    timerLabel.Size = UDim2.new(1, 0, 0, 18)
    timerLabel.BackgroundTransparency = 1
    timerLabel.Text = "⏰ WAKTU TERSISA"
    timerLabel.TextColor3 = colors.text3
    timerLabel.Font = Enum.Font.GothamBold
    timerLabel.TextSize = 8
    timerLabel.TextXAlignment = Enum.TextXAlignment.Center
    timerLabel.LayoutOrder = 0
    
    -- Display timer
    local timerDisplay = Instance.new("TextLabel", timerCard)
    timerDisplay.Size = UDim2.new(1, 0, 0, 40)
    timerDisplay.BackgroundTransparency = 1
    timerDisplay.Text = "00:00:00"
    timerDisplay.TextColor3 = colors.text
    timerDisplay.Font = Enum.Font.GothamBlack
    timerDisplay.TextSize = 26
    timerDisplay.LayoutOrder = 1
    
    -- Status badge
    local statusBadge = Instance.new("TextLabel", timerCard)
    statusBadge.Size = UDim2.new(0, 80, 0, 18)
    statusBadge.Position = UDim2.new(0.5, -40, 0, 62)
    statusBadge.BackgroundColor3 = colors.green
    statusBadge.BackgroundTransparency = 0.85
    statusBadge.Text = "ACTIVE"
    statusBadge.TextColor3 = colors.green
    statusBadge.Font = Enum.Font.GothamBlack
    statusBadge.TextSize = 8
    statusBadge.LayoutOrder = 2
    corner(statusBadge, 9)
    
    -- Info key detail
    local keyInfoLbl = Instance.new("TextLabel", timerCard)
    keyInfoLbl.Size = UDim2.new(1, 0, 0, 50)
    keyInfoLbl.BackgroundTransparency = 1
    keyInfoLbl.Text = "Key: -"
    keyInfoLbl.TextColor3 = colors.text2
    keyInfoLbl.Font = Enum.Font.Gotham
    keyInfoLbl.TextSize = 9
    keyInfoLbl.LayoutOrder = 3
    keyInfoLbl.TextWrapped = true
    
    -- Progress bar
    local progressBg = Instance.new("Frame", timerCard)
    progressBg.Size = UDim2.new(1, -20, 0, 6)
    progressBg.Position = UDim2.new(0, 10, 0, 0)
    progressBg.BackgroundColor3 = Color3.fromRGB(230, 230, 235)
    progressBg.BorderSizePixel = 0
    progressBg.LayoutOrder = 4
    corner(progressBg, 3)
    
    local progressFill = Instance.new("Frame", progressBg)
    progressFill.Size = UDim2.new(1, 0, 1, 0)
    progressFill.BackgroundColor3 = colors.green
    progressFill.BorderSizePixel = 0
    corner(progressFill, 3)
    
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
                
                -- Warna berdasarkan sisa waktu
                if remaining > 3600 then
                    timerDisplay.TextColor3 = colors.green
                    statusBadge.Text = "ACTIVE"
                    statusBadge.TextColor3 = colors.green
                    statusBadge.BackgroundColor3 = colors.green
                    progressFill.BackgroundColor3 = colors.green
                elseif remaining > 600 then
                    timerDisplay.TextColor3 = colors.gold
                    statusBadge.Text = "WARNING"
                    statusBadge.TextColor3 = colors.gold
                    statusBadge.BackgroundColor3 = colors.gold
                    progressFill.BackgroundColor3 = colors.gold
                else
                    timerDisplay.TextColor3 = colors.red
                    statusBadge.Text = "CRITICAL"
                    statusBadge.TextColor3 = colors.red
                    statusBadge.BackgroundColor3 = colors.red
                    progressFill.BackgroundColor3 = colors.red
                end
                
                -- Progress bar
                local keyInfo = Firebase.GetKeyInfo(savedKey)
                if keyInfo and keyInfo.expires then
                    local totalDuration = keyInfo.duration or 24
                    local totalSeconds = totalDuration * 3600
                    local progress = math.clamp(remaining / totalSeconds, 0, 1)
                    tween(progressFill, {Size = UDim2.new(progress, 0, 1, 0)}, 1)
                end
                
                -- Info lengkap
                local mapName = "Unknown"
                local playerName = "Unknown"
                local playerUsername = "Unknown"
                local usedBy = "-"
                
                if keyInfo then
                    mapName = keyInfo.mapName or "Unknown"
                    playerName = keyInfo.playerName or "Unknown"
                    playerUsername = keyInfo.playerUsername or "Unknown"
                    usedBy = keyInfo.usedBy or "-"
                end
                
                keyInfoLbl.Text = string.format(
                    "🔑 Key: %s\n👤 Player: %s (@%s)\n🆔 User ID: %s\n🗺️ Map: %s",
                    savedKey,
                    playerName,
                    playerUsername,
                    usedBy,
                    mapName
                )
            else
                timerDisplay.Text = "EXPIRED"
                timerDisplay.TextColor3 = colors.text3
                statusBadge.Text = "INACTIVE"
                statusBadge.TextColor3 = colors.text3
                statusBadge.BackgroundColor3 = colors.text3
                progressFill.Size = UDim2.new(0, 0, 1, 0)
                keyInfoLbl.Text = "Key: " .. (savedKey or "-") .. "\nStatus: Expired"
            end
        else
            timerDisplay.Text = "NO KEY"
            timerDisplay.TextColor3 = colors.text3
            statusBadge.Text = "INACTIVE"
            statusBadge.TextColor3 = colors.text3
            statusBadge.BackgroundColor3 = colors.text3
            progressFill.Size = UDim2.new(0, 0, 1, 0)
            keyInfoLbl.Text = "Belum ada key tersimpan"
        end
    end
    
    -- Update setiap detik
    task.spawn(function()
        while timerDisplay.Parent do
            updateTimer()
            task.wait(1)
        end
    end)
    
    -- ==================== DEVELOPER INFO ====================
    local devSection = createSection("DEVELOPER", 2)
    local devCard = createCard(devSection, 1)
    
    local devHeader = Instance.new("Frame", devCard)
    devHeader.Size = UDim2.new(1, 0, 0, 70)
    devHeader.BackgroundTransparency = 1
    devHeader.LayoutOrder = 0
    
    -- Avatar frame dengan glow
    local avatarGlow = Instance.new("Frame", devHeader)
    avatarGlow.Size = UDim2.new(0, 52, 0, 52)
    avatarGlow.Position = UDim2.new(0, 10, 0.5, -26)
    avatarGlow.BackgroundColor3 = colors.gold
    avatarGlow.BackgroundTransparency = 0.7
    avatarGlow.ZIndex = 1
    corner(avatarGlow, 100)
    
    local avatarFrame = Instance.new("Frame", devHeader)
    avatarFrame.Size = UDim2.new(0, 48, 0, 48)
    avatarFrame.Position = UDim2.new(0, 12, 0.5, -24)
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
    
    local devName = Instance.new("TextLabel", devHeader)
    devName.Size = UDim2.new(1, -70, 0, 22)
    devName.Position = UDim2.new(0, 68, 0, 14)
    devName.BackgroundTransparency = 1
    devName.Text = Config.DEVELOPER_USERNAME or "AlfreadR0rw"
    devName.TextColor3 = colors.text
    devName.Font = Enum.Font.GothamBlack
    devName.TextSize = 14
    devName.TextXAlignment = Enum.TextXAlignment.Left
    devName.ZIndex = 2
    
    local devRole = Instance.new("TextLabel", devHeader)
    devRole.Size = UDim2.new(0, 50, 0, 18)
    devRole.Position = UDim2.new(0, 68, 0, 38)
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
    
    local function createSocialButton(parent, order, name, iconURL, link, emojiFallback)
        local btn = Instance.new("TextButton", parent)
        btn.Size = UDim2.new(1, 0, 0, 52)
        btn.BackgroundColor3 = Color3.fromRGB(248, 248, 252)
        btn.LayoutOrder = order
        btn.AutoButtonColor = false
        btn.BorderSizePixel = 0
        corner(btn, 10)
        stroke(btn, colors.border, 1, 0.3)
        pressFX(btn)
        
        -- Icon container
        local iconContainer = Instance.new("Frame", btn)
        iconContainer.Size = UDim2.new(0, 36, 0, 36)
        iconContainer.Position = UDim2.new(0, 8, 0.5, -18)
        iconContainer.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
        iconContainer.ZIndex = 2
        corner(iconContainer, 100)
        
        -- Icon image
        local iconImage = Instance.new("ImageLabel", iconContainer)
        iconImage.Size = UDim2.new(1, -8, 1, -8)
        iconImage.Position = UDim2.new(0, 4, 0, 4)
        iconImage.BackgroundTransparency = 1
        iconImage.Image = iconURL or ""
        iconImage.ScaleType = Enum.ScaleType.Fit
        iconImage.ZIndex = 3
        
        -- Fallback emoji jika image gagal
        if emojiFallback then
            local emojiLbl = Instance.new("TextLabel", iconContainer)
            emojiLbl.Size = UDim2.new(1, 0, 1, 0)
            emojiLbl.BackgroundTransparency = 1
            emojiLbl.Text = emojiFallback
            emojiLbl.Font = Enum.Font.GothamBold
            emojiLbl.TextSize = 18
            emojiLbl.ZIndex = 2
        end
        
        local nameLbl = Instance.new("TextLabel", btn)
        nameLbl.Size = UDim2.new(1, -100, 0, 20)
        nameLbl.Position = UDim2.new(0, 52, 0.5, -14)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = name
        nameLbl.TextColor3 = colors.text
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 11
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.ZIndex = 2
        
        local hintLbl = Instance.new("TextLabel", btn)
        hintLbl.Size = UDim2.new(1, -100, 0, 16)
        hintLbl.Position = UDim2.new(0, 52, 0.5, 6)
        hintLbl.BackgroundTransparency = 1
        hintLbl.Text = "Tap untuk salin link"
        hintLbl.TextColor3 = colors.text3
        hintLbl.Font = Enum.Font.Gotham
        hintLbl.TextSize = 8
        hintLbl.TextXAlignment = Enum.TextXAlignment.Left
        hintLbl.ZIndex = 2
        
        btn.MouseButton1Click:Connect(function()
            Helpers.copyToClipboard(link)
            _G.showDynamicNotification("✅ Link " .. name .. " disalin!", colors.green)
        end)
        
        return btn
    end
    
    createSocialButton(socialCard, 0, "Discord", Config.DiscordIconURL or "", Config.DiscordURL or "", "💬")
    createSocialButton(socialCard, 1, "WhatsApp", Config.WhatsAppIconURL or "", Config.WhatsAppURL or "", "📱")
    createSocialButton(socialCard, 2, "Telegram", Config.TelegramIconURL or "", Config.TelegramURL or "", "✈️")
    
    -- ==================== QUICK ACTIONS ====================
    local actionSection = createSection("AKSI CEPAT", 4)
    local actionCard = createCard(actionSection, 1)
    
    local function createActionButton(parent, order, title, emoji, onClick)
        local btn = Instance.new("TextButton", parent)
        btn.Size = UDim2.new(1, 0, 0, 44)
        btn.BackgroundColor3 = Color3.fromRGB(248, 248, 252)
        btn.LayoutOrder = order
        btn.AutoButtonColor = false
        btn.BorderSizePixel = 0
        corner(btn, 10)
        stroke(btn, colors.border, 1, 0.3)
        pressFX(btn)
        
        local emojiLbl = Instance.new("TextLabel", btn)
        emojiLbl.Size = UDim2.new(0, 30, 0, 30)
        emojiLbl.Position = UDim2.new(0, 8, 0.5, -15)
        emojiLbl.BackgroundTransparency = 1
        emojiLbl.Text = emoji or "⚡"
        emojiLbl.Font = Enum.Font.GothamBold
        emojiLbl.TextSize = 18
        emojiLbl.ZIndex = 2
        
        local titleLbl = Instance.new("TextLabel", btn)
        titleLbl.Size = UDim2.new(1, -50, 1, 0)
        titleLbl.Position = UDim2.new(0, 42, 0, 0)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = title
        titleLbl.TextColor3 = colors.text
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.TextSize = 11
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.ZIndex = 2
        
        btn.MouseButton1Click:Connect(onClick)
        
        return btn
    end
    
    createActionButton(actionCard, 0, "Rejoin Server", "🔄", function()
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId)
        end)
    end)
    
    createActionButton(actionCard, 1, "Copy User ID", "🆔", function()
        Helpers.copyToClipboard(tostring(LocalPlayer.UserId))
        _G.showDynamicNotification("✅ User ID disalin!", colors.green)
    end)
    
    createActionButton(actionCard, 2, "Buy Key", "💳", function()
        local url = Config.BUY_KEY_URL or "https://discord.gg/"
        Helpers.copyToClipboard(url)
        _G.showDynamicNotification("✅ Link pembelian disalin!", colors.gold)
    end)
    
    createActionButton(actionCard, 3, "Clear Key", "🗑️", function()
        if Storage and Storage.appSettings then
            Storage.appSettings.savedKey = nil
            if Storage.persistSettings then
                Storage.persistSettings()
            end
        end
        _G.showDynamicNotification("Key dihapus dari device", colors.red)
        updateTimer()
    end)
    
    -- ==================== INFO ====================
    local infoSection = createSection("INFO", 5)
    local infoCard = createCard(infoSection, 1)
    
    local infoLbl = Instance.new("TextLabel", infoCard)
    infoLbl.Size = UDim2.new(1, 0, 0, 20)
    infoLbl.BackgroundTransparency = 1
    infoLbl.Text = "📱 PhoneIDViewer v2.1.0"
    infoLbl.TextColor3 = colors.text
    infoLbl.Font = Enum.Font.GothamBold
    infoLbl.TextSize = 10
    infoLbl.TextXAlignment = Enum.TextXAlignment.Center
    infoLbl.LayoutOrder = 0
    
    local copyrightLbl = Instance.new("TextLabel", infoCard)
    copyrightLbl.Size = UDim2.new(1, 0, 0, 16)
    copyrightLbl.BackgroundTransparency = 1
    copyrightLbl.Text = "© 2025 " .. (Config.DEVELOPER_USERNAME or "AlfreadR0rw") .. " - All Rights Reserved"
    copyrightLbl.TextColor3 = colors.text3
    copyrightLbl.Font = Enum.Font.Gotham
    copyrightLbl.TextSize = 8
    copyrightLbl.TextXAlignment = Enum.TextXAlignment.Center
    copyrightLbl.LayoutOrder = 1
    
    local buildLbl = Instance.new("TextLabel", infoCard)
    buildLbl.Size = UDim2.new(1, 0, 0, 14)
    buildLbl.BackgroundTransparency = 1
    buildLbl.Text = "Build: Stable | Last Update: 2025"
    buildLbl.TextColor3 = colors.text3
    buildLbl.Font = Enum.Font.Gotham
    buildLbl.TextSize = 7
    buildLbl.TextXAlignment = Enum.TextXAlignment.Center
    buildLbl.LayoutOrder = 2
end

print("[Settings] App loaded successfully!")<