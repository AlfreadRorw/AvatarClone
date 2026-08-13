-- ================================================
-- SETTINGS APP - Fixed, Beautiful, Timer Works
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

function _G.openSettingsApp()
    -- ==================== KEY TIMER (FIXED) ====================
    local timerSection = createSection("KEY STATUS", 1)
    local timerCard = createCard(timerSection, 1)
    
    -- Timer label
    local timerLabel = Instance.new("TextLabel", timerCard)
    timerLabel.Size = UDim2.new(1, 0, 0, 18)
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
    
    -- Update setiap detik
    task.spawn(function()
        while timerDisplay.Parent do
            updateTimer()
            task.wait(1)
        end
    end)
    
    -- ==================== DEVELOPER ====================
    local devSection = createSection("DEVELOPER", 2)
    local devCard = createCard(devSection, 1)
    
    local devHeader = Instance.new("Frame", devCard)
    devHeader.Size = UDim2.new(1, 0, 0, 60)
    devHeader.BackgroundTransparency = 1
    devHeader.LayoutOrder = 0
    
    -- Avatar
    local avatarFrame = Instance.new("Frame", devHeader)
    avatarFrame.Size = UDim2.new(0, 45, 0, 45)
    avatarFrame.Position = UDim2.new(0, 10, 0.5, -22)
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
    devName.Size = UDim2.new(1, -60, 0, 20)
    devName.Position = UDim2.new(0, 60, 0, 12)
    devName.BackgroundTransparency = 1
    devName.Text = Config.DEVELOPER_USERNAME or "AlfreadR0rw"
    devName.TextColor3 = colors.text
    devName.Font = Enum.Font.GothamBlack
    devName.TextSize = 13
    devName.TextXAlignment = Enum.TextXAlignment.Left
    devName.ZIndex = 2
    
    local devRole = Instance.new("TextLabel", devHeader)
    devRole.Size = UDim2.new(0, 45, 0, 16)
    devRole.Position = UDim2.new(0, 60, 0, 34)
    devRole.BackgroundColor3 = colors.gold
    devRole.Text = "OWNER"
    devRole.TextColor3 = Color3.fromRGB(255, 255, 255)
    devRole.Font = Enum.Font.GothamBlack
    devRole.TextSize = 7
    devRole.ZIndex = 2
    corner(devRole, 8)
    
    -- ==================== SOCIAL MEDIA ====================
    local socialSection = createSection("SOCIAL MEDIA", 3)
    local socialCard = createCard(socialSection, 1)
    
    local function createSocialButton(parent, order, name, iconURL, link)
        local btn = Instance.new("TextButton", parent)
        btn.Size = UDim2.new(1, 0, 0, 48)
        btn.BackgroundColor3 = Color3.fromRGB(248, 248, 252)
        btn.LayoutOrder = order
        btn.AutoButtonColor = false
        btn.BorderSizePixel = 0
        corner(btn, 10)
        stroke(btn, colors.border, 1, 0.3)
        pressFX(btn)
        
        -- Icon image dari Catbox
        local iconImage = Instance.new("ImageLabel", btn)
        iconImage.Size = UDim2.new(0, 28, 0, 28)
        iconImage.Position = UDim2.new(0, 10, 0.5, -14)
        iconImage.BackgroundTransparency = 1
        iconImage.Image = iconURL
        iconImage.ScaleType = Enum.ScaleType.Fit
        iconImage.ZIndex = 2
        
        local nameLbl = Instance.new("TextLabel", btn)
        nameLbl.Size = UDim2.new(1, -50, 0, 25)
        nameLbl.Position = UDim2.new(0, 45, 0.5, -12)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = name
        nameLbl.TextColor3 = colors.text
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 11
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.ZIndex = 2
        
        btn.MouseButton1Click:Connect(function()
            Helpers.copyToClipboard(link)
            _G.showDynamicNotification(name .. " link copied!", colors.accent2)
        end)
        
        return btn
    end
    
    createSocialButton(socialCard, 0, "Discord", Config.DiscordIconURL or "", Config.DiscordURL or "")
    createSocialButton(socialCard, 1, "WhatsApp", Config.WhatsAppIconURL or "", Config.WhatsAppURL or "")
    createSocialButton(socialCard, 2, "Telegram", Config.TelegramIconURL or "", Config.TelegramURL or "")
    
    -- ==================== QUICK ACTIONS ====================
    local actionSection = createSection("AKSI CEPAT", 4)
    local actionCard = createCard(actionSection, 1)
    
    local function createActionButton(parent, order, title, onClick)
        local btn = Instance.new("TextButton", parent)
        btn.Size = UDim2.new(1, 0, 0, 40)
        btn.BackgroundColor3 = Color3.fromRGB(248, 248, 252)
        btn.LayoutOrder = order
        btn.AutoButtonColor = false
        btn.BorderSizePixel = 0
        corner(btn, 10)
        stroke(btn, colors.border, 1, 0.3)
        pressFX(btn)
        
        local titleLbl = Instance.new("TextLabel", btn)
        titleLbl.Size = UDim2.new(1, -20, 1, 0)
        titleLbl.Position = UDim2.new(0, 10, 0, 0)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = title
        titleLbl.TextColor3 = colors.text
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.TextSize = 11
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        
        btn.MouseButton1Click:Connect(onClick)
        
        return btn
    end
    
    createActionButton(actionCard, 0, "Rejoin Server", function()
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId)
        end)
    end)
    
    createActionButton(actionCard, 1, "Copy User ID", function()
        Helpers.copyToClipboard(tostring(LocalPlayer.UserId))
        _G.showDynamicNotification("User ID copied!", colors.green)
    end)
    
    createActionButton(actionCard, 2, "Buy Key", function()
        local url = Config.BUY_KEY_URL or "https://discord.gg/"
        Helpers.copyToClipboard(url)
        _G.showDynamicNotification("Link copied!", colors.gold)
    end)
    
    -- ==================== INFO ====================
    local infoSection = createSection("INFO", 5)
    local infoCard = createCard(infoSection, 1)
    
    local infoLbl = Instance.new("TextLabel", infoCard)
    infoLbl.Size = UDim2.new(1, 0, 0, 20)
    infoLbl.BackgroundTransparency = 1
    infoLbl.Text = "Version 2.1.0"
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