-- ================================================
-- SETTINGS APP - FIXED & ERROR-FREE
-- ================================================

local Services = _G.Services
local LocalPlayer = _G.LocalPlayer
local Players = Services.Players
local TeleportService = Services.TeleportService
local T = _G.T or {}
local Helpers = _G.Helpers or {}
local Storage = _G.Storage or {}
local Firebase = _G.Firebase
local Config = _G.Config or {}

local appContent = _G.appContent

-- Jika appContent nil, buat fallback
if not appContent then
    warn("[Settings] appContent is nil, creating fallback")
    appContent = Instance.new("ScrollingFrame")
    appContent.Size = UDim2.new(1, 0, 1, 0)
    appContent.BackgroundTransparency = 1
end

local appSettings = Storage.appSettings or {}

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

-- ==================== SAFE HELPERS ====================
local function safeCorner(obj, radius)
    pcall(function()
        if obj and obj.Parent then
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, radius or 10)
            c.Parent = obj
        end
    end)
end

local function safeStroke(obj, color, thickness, transparency)
    pcall(function()
        if obj and obj.Parent then
            local s = Instance.new("UIStroke")
            s.Color = color or Color3.fromRGB(200, 200, 200)
            s.Thickness = thickness or 1
            s.Transparency = transparency or 0
            s.Parent = obj
        end
    end)
end

local function safeTween(obj, props, time)
    pcall(function()
        if obj and obj.Parent then
            game:GetService("TweenService"):Create(obj, TweenInfo.new(time or 0.25), props):Play()
        end
    end)
end

local function safePressFX(btn)
    pcall(function()
        if not btn then return end
        local origSize = btn.Size
        btn.MouseButton1Down:Connect(function()
            safeTween(btn, {Size = UDim2.new(origSize.X.Scale * 0.95, origSize.X.Offset * 0.95, origSize.Y.Scale * 0.95, origSize.Y.Offset * 0.95)}, 0.1)
        end)
        btn.MouseButton1Up:Connect(function()
            safeTween(btn, {Size = origSize}, 0.1)
        end)
    end)
end

-- ==================== UI BUILDERS ====================
local function createSection(title, order)
    local section = Instance.new("Frame")
    section.Name = "Section_" .. title
    section.Size = UDim2.new(1, 0, 0, 0)
    section.AutomaticSize = Enum.AutomaticSize.Y
    section.BackgroundTransparency = 1
    section.LayoutOrder = order
    section.Parent = appContent
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = section
    
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, 0, 0, 25)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title or "Section"
    titleLbl.TextColor3 = colors.text2
    titleLbl.Font = Enum.Font.GothamBlack
    titleLbl.TextSize = 10
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.LayoutOrder = 0
    titleLbl.Parent = section
    
    return section
end

local function createCard(parent, order)
    local card = Instance.new("Frame")
    card.Name = "Card"
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = colors.card
    card.BorderSizePixel = 0
    card.LayoutOrder = order
    card.Parent = parent
    safeCorner(card, 14)
    safeStroke(card, colors.border, 1, 0.3)
    
    local cardLayout = Instance.new("UIListLayout")
    cardLayout.Padding = UDim.new(0, 8)
    cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
    cardLayout.Parent = card
    
    return card
end

local function createLabel(parent, text, fontSize, color, font, order, textAlign)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, fontSize + 6)
    lbl.BackgroundTransparency = 1
    lbl.Text = text or ""
    lbl.TextColor3 = color or colors.text
    lbl.Font = font or Enum.Font.Gotham
    lbl.TextSize = fontSize or 10
    lbl.TextXAlignment = textAlign or Enum.TextXAlignment.Center
    lbl.LayoutOrder = order or 0
    lbl.TextWrapped = true
    lbl.Parent = parent
    return lbl
end

local function createButton(parent, order, title, emoji, onClick)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 44)
    btn.BackgroundColor3 = Color3.fromRGB(248, 248, 252)
    btn.LayoutOrder = order
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    btn.Parent = parent
    safeCorner(btn, 10)
    safeStroke(btn, colors.border, 1, 0.3)
    safePressFX(btn)
    
    local emojiLbl = Instance.new("TextLabel")
    emojiLbl.Size = UDim2.new(0, 30, 0, 30)
    emojiLbl.Position = UDim2.new(0, 8, 0.5, -15)
    emojiLbl.BackgroundTransparency = 1
    emojiLbl.Text = emoji or "⚡"
    emojiLbl.Font = Enum.Font.GothamBold
    emojiLbl.TextSize = 18
    emojiLbl.Parent = btn
    
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -50, 1, 0)
    titleLbl.Position = UDim2.new(0, 42, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title or "Button"
    titleLbl.TextColor3 = colors.text
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 11
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = btn
    
    if onClick then
        btn.MouseButton1Click:Connect(onClick)
    end
    
    return btn
end

-- ==================== OPEN SETTINGS APP ====================
function _G.openSettingsApp()
    pcall(function()
        -- ==================== KEY STATUS & TIMER ====================
        local timerSection = createSection("KEY STATUS", 1)
        local timerCard = createCard(timerSection, 1)
        
        -- Label kecil
        createLabel(timerCard, "⏰ WAKTU TERSISA", 8, colors.text3, Enum.Font.GothamBold, 0)
        
        -- Display timer
        local timerDisplay = Instance.new("TextLabel")
        timerDisplay.Size = UDim2.new(1, 0, 0, 40)
        timerDisplay.BackgroundTransparency = 1
        timerDisplay.Text = "00:00:00"
        timerDisplay.TextColor3 = colors.text
        timerDisplay.Font = Enum.Font.GothamBlack
        timerDisplay.TextSize = 26
        timerDisplay.LayoutOrder = 1
        timerDisplay.Parent = timerCard
        
        -- Status badge
        local statusBadge = Instance.new("TextLabel")
        statusBadge.Size = UDim2.new(0, 80, 0, 18)
        statusBadge.BackgroundColor3 = colors.green
        statusBadge.BackgroundTransparency = 0.85
        statusBadge.Text = "ACTIVE"
        statusBadge.TextColor3 = colors.green
        statusBadge.Font = Enum.Font.GothamBlack
        statusBadge.TextSize = 8
        statusBadge.LayoutOrder = 2
        statusBadge.Parent = timerCard
        safeCorner(statusBadge, 9)
        
        -- Info key detail
        local keyInfoLbl = Instance.new("TextLabel")
        keyInfoLbl.Size = UDim2.new(1, 0, 0, 55)
        keyInfoLbl.BackgroundTransparency = 1
        keyInfoLbl.Text = "Key: -"
        keyInfoLbl.TextColor3 = colors.text2
        keyInfoLbl.Font = Enum.Font.Gotham
        keyInfoLbl.TextSize = 9
        keyInfoLbl.TextWrapped = true
        keyInfoLbl.LayoutOrder = 3
        keyInfoLbl.Parent = timerCard
        
        -- Progress bar
        local progressBg = Instance.new("Frame")
        progressBg.Size = UDim2.new(1, 0, 0, 6)
        progressBg.BackgroundColor3 = Color3.fromRGB(230, 230, 235)
        progressBg.BorderSizePixel = 0
        progressBg.LayoutOrder = 4
        progressBg.Parent = timerCard
        safeCorner(progressBg, 3)
        
        local progressFill = Instance.new("Frame")
        progressFill.Size = UDim2.new(1, 0, 1, 0)
        progressFill.BackgroundColor3 = colors.green
        progressFill.BorderSizePixel = 0
        progressFill.Parent = progressBg
        safeCorner(progressFill, 3)
        
        local function updateTimer()
            local savedKey = nil
            if Storage.appSettings then
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
                        progressFill.BackgroundColor3 = colors.green
                    elseif remaining > 600 then
                        timerDisplay.TextColor3 = colors.gold
                        statusBadge.Text = "WARNING"
                        statusBadge.TextColor3 = colors.gold
                        progressFill.BackgroundColor3 = colors.gold
                    else
                        timerDisplay.TextColor3 = colors.red
                        statusBadge.Text = "CRITICAL"
                        statusBadge.TextColor3 = colors.red
                        progressFill.BackgroundColor3 = colors.red
                    end
                    
                    -- Info lengkap
                    local keyInfo = nil
                    if Firebase.GetKeyInfo then
                        keyInfo = Firebase.GetKeyInfo(savedKey)
                    end
                    
                    local mapName = "Unknown"
                    local playerName = "Unknown"
                    local playerUsername = "Unknown"
                    local usedBy = "-"
                    
                    if keyInfo then
                        mapName = keyInfo.mapName or "Unknown"
                        playerName = keyInfo.playerName or "Unknown"
                        playerUsername = keyInfo.playerUsername or "Unknown"
                        usedBy = tostring(keyInfo.usedBy or "-")
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
                    progressFill.Size = UDim2.new(0, 0, 1, 0)
                    keyInfoLbl.Text = "Key: " .. (savedKey or "-") .. "\nStatus: Expired"
                end
            else
                timerDisplay.Text = "NO KEY"
                timerDisplay.TextColor3 = colors.text3
                statusBadge.Text = "INACTIVE"
                statusBadge.TextColor3 = colors.text3
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
        
        local devHeader = Instance.new("Frame")
        devHeader.Size = UDim2.new(1, 0, 0, 70)
        devHeader.BackgroundTransparency = 1
        devHeader.LayoutOrder = 0
        devHeader.Parent = devCard
        
        -- Avatar frame
        local avatarFrame = Instance.new("Frame")
        avatarFrame.Size = UDim2.new(0, 50, 0, 50)
        avatarFrame.Position = UDim2.new(0, 10, 0.5, -25)
        avatarFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        avatarFrame.BackgroundTransparency = 0.5
        avatarFrame.Parent = devHeader
        safeCorner(avatarFrame, 100)
        safeStroke(avatarFrame, colors.gold, 2, 0)
        
        local avatarImage = Instance.new("ImageLabel")
        avatarImage.Size = UDim2.new(1, -6, 1, -6)
        avatarImage.Position = UDim2.new(0, 3, 0, 3)
        avatarImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        avatarImage.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. (Config.DEVELOPER_USER_ID or LocalPlayer.UserId) .. "&width=100&height=100&format=png"
        avatarImage.Parent = avatarFrame
        safeCorner(avatarImage, 100)
        
        local devName = Instance.new("TextLabel")
        devName.Size = UDim2.new(1, -70, 0, 22)
        devName.Position = UDim2.new(0, 68, 0, 14)
        devName.BackgroundTransparency = 1
        devName.Text = Config.DEVELOPER_USERNAME or "AlfreadR0rw"
        devName.TextColor3 = colors.text
        devName.Font = Enum.Font.GothamBlack
        devName.TextSize = 14
        devName.TextXAlignment = Enum.TextXAlignment.Left
        devName.Parent = devHeader
        
        local devRole = Instance.new("TextLabel")
        devRole.Size = UDim2.new(0, 50, 0, 18)
        devRole.Position = UDim2.new(0, 68, 0, 38)
        devRole.BackgroundColor3 = colors.gold
        devRole.Text = "OWNER"
        devRole.TextColor3 = Color3.fromRGB(255, 255, 255)
        devRole.Font = Enum.Font.GothamBlack
        devRole.TextSize = 8
        devRole.Parent = devHeader
        safeCorner(devRole, 9)
        
        -- ==================== SOCIAL MEDIA ====================
        local socialSection = createSection("SOCIAL MEDIA", 3)
        local socialCard = createCard(socialSection, 1)
        
        createButton(socialCard, 0, "Discord", "💬", function()
            pcall(function() Helpers.copyToClipboard(Config.DiscordURL or "") end)
            _G.showDynamicNotification("✅ Link Discord disalin!", colors.green)
        end)
        
        createButton(socialCard, 1, "WhatsApp", "📱", function()
            pcall(function() Helpers.copyToClipboard(Config.WhatsAppURL or "") end)
            _G.showDynamicNotification("✅ Link WhatsApp disalin!", colors.green)
        end)
        
        createButton(socialCard, 2, "Telegram", "✈️", function()
            pcall(function() Helpers.copyToClipboard(Config.TelegramURL or "") end)
            _G.showDynamicNotification("✅ Link Telegram disalin!", colors.green)
        end)
        
        -- ==================== QUICK ACTIONS ====================
        local actionSection = createSection("AKSI CEPAT", 4)
        local actionCard = createCard(actionSection, 1)
        
        createButton(actionCard, 0, "Rejoin Server", "🔄", function()
            pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId)
            end)
        end)
        
        createButton(actionCard, 1, "Copy User ID", "🆔", function()
            pcall(function() Helpers.copyToClipboard(tostring(LocalPlayer.UserId)) end)
            _G.showDynamicNotification("✅ User ID disalin!", colors.green)
        end)
        
        createButton(actionCard, 2, "Buy Key", "💳", function()
            local url = Config.BUY_KEY_URL or "https://discord.gg/"
            pcall(function() Helpers.copyToClipboard(url) end)
            _G.showDynamicNotification("✅ Link pembelian disalin!", colors.gold)
        end)
        
        createButton(actionCard, 3, "Clear Key", "🗑️", function()
            if Storage.appSettings then
                Storage.appSettings.savedKey = nil
                if Storage.persistSettings then
                    pcall(Storage.persistSettings)
                end
            end
            _G.showDynamicNotification("Key dihapus dari device", colors.red)
            updateTimer()
        end)
        
        -- ==================== INFO ====================
        local infoSection = createSection("INFO", 5)
        local infoCard = createCard(infoSection, 1)
        
        createLabel(infoCard, "📱 PhoneIDViewer v2.1.0", 10, colors.text, Enum.Font.GothamBold, 0)
        createLabel(infoCard, "© 2025 " .. (Config.DEVELOPER_USERNAME or "AlfreadR0rw") .. " - All Rights Reserved", 8, colors.text3, Enum.Font.Gotham, 1)
        createLabel(infoCard, "Build: Stable | Last Update: 2025", 7, colors.text3, Enum.Font.Gotham, 2)
    end)
end

print("[Settings] App loaded successfully!")