-- ================================================
-- SETTINGS APP - Glass Morphism & Fixed Social Icons
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
local appSettings = Storage and Storage.appSettings or {}

local corner = Helpers.corner
local stroke = Helpers.stroke
local tween = Helpers.tween
local pressFX = Helpers.pressFX

-- Colors (Glass Morphism Style)
local colors = {
    glass = Color3.fromRGB(255, 255, 255),
    glassBorder = Color3.fromRGB(255, 255, 255),
    accent = Color3.fromRGB(0, 150, 255),
    gold = Color3.fromRGB(255, 180, 50),
    green = Color3.fromRGB(0, 230, 118),
    red = Color3.fromRGB(255, 82, 82),
    text = Color3.fromRGB(30, 30, 35),
    text2 = Color3.fromRGB(100, 100, 110),
    text3 = Color3.fromRGB(140, 140, 150),
}

-- Glass card builder
local function createGlassCard(parent, order)
    local card = Instance.new("Frame", parent)
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    card.BackgroundTransparency = 0.15 -- Glass effect (semi-transparent)
    card.LayoutOrder = order
    card.BorderSizePixel = 0
    corner(card, 16)
    stroke(card, Color3.fromRGB(255, 255, 255), 1.5, 0.3)
    
    -- Glass gradient
    local glassGradient = Instance.new("UIGradient", card)
    glassGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(240, 240, 245))
    })
    glassGradient.Rotation = 135
    glassGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(1, 0.25)
    })
    
    local cardLayout = Instance.new("UIListLayout", card)
    cardLayout.Padding = UDim.new(0, 8)
    cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    return card
end

-- Section builder
local function createSection(title, order)
    local section = Instance.new("Frame", appContent)
    section.Size = UDim2.new(1, 0, 0, 0)
    section.AutomaticSize = Enum.AutomaticSize.Y
    section.BackgroundTransparency = 1
    section.LayoutOrder = order
    
    local sectionLayout = Instance.new("UIListLayout", section)
    sectionLayout.Padding = UDim.new(0, 8)
    sectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    local titleFrame = Instance.new("Frame", section)
    titleFrame.Size = UDim2.new(1, 0, 0, 30)
    titleFrame.BackgroundTransparency = 1
    titleFrame.LayoutOrder = 0
    
    local accentLine = Instance.new("Frame", titleFrame)
    accentLine.Size = UDim2.new(0, 3, 0, 18)
    accentLine.Position = UDim2.new(0, 0, 0.5, -9)
    accentLine.BackgroundColor3 = colors.accent
    accentLine.BorderSizePixel = 0
    accentLine.ZIndex = 2
    corner(accentLine, 2)
    
    local titleLbl = Instance.new("TextLabel", titleFrame)
    titleLbl.Size = UDim2.new(1, -20, 0, 20)
    titleLbl.Position = UDim2.new(0, 10, 0, 5)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = colors.text
    titleLbl.Font = Enum.Font.GothamBlack
    titleLbl.TextSize = 11
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 2
    
    return section
end

-- ==================== OPEN SETTINGS ====================
function _G.openSettingsApp()
    -- ==================== DEVELOPER ====================
    local devSection = createSection("DEVELOPER", 1)
    local devCard = createGlassCard(devSection, 1)
    
    local devHeader = Instance.new("Frame", devCard)
    devHeader.Size = UDim2.new(1, 0, 0, 70)
    devHeader.BackgroundTransparency = 1
    devHeader.LayoutOrder = 0
    
    -- Avatar
    local avatarFrame = Instance.new("Frame", devHeader)
    avatarFrame.Size = UDim2.new(0, 50, 0, 50)
    avatarFrame.Position = UDim2.new(0, 10, 0.5, -25)
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
    devName.Position = UDim2.new(0, 70, 0, 14)
    devName.BackgroundTransparency = 1
    devName.Text = Config.DEVELOPER_USERNAME or "AlfreadR0rw"
    devName.TextColor3 = colors.text
    devName.Font = Enum.Font.GothamBlack
    devName.TextSize = 14
    devName.TextXAlignment = Enum.TextXAlignment.Left
    devName.ZIndex = 2
    
    local devRole = Instance.new("TextLabel", devHeader)
    devRole.Size = UDim2.new(0, 45, 0, 18)
    devRole.Position = UDim2.new(0, 70, 0, 38)
    devRole.BackgroundColor3 = colors.gold
    devRole.Text = "OWNER"
    devRole.TextColor3 = Color3.fromRGB(255, 255, 255)
    devRole.Font = Enum.Font.GothamBlack
    devRole.TextSize = 8
    devRole.ZIndex = 2
    corner(devRole, 9)
    
    -- ==================== SOCIAL MEDIA ====================
    local socialSection = createSection("SOCIAL MEDIA", 2)
    local socialCard = createGlassCard(socialSection, 1)
    
    -- Social button dengan icon asli
    local function createSocialButton(parent, order, name, iconURL, link)
        local btn = Instance.new("TextButton", parent)
        btn.Size = UDim2.new(1, 0, 0, 50)
        btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        btn.BackgroundTransparency = 0.3
        btn.LayoutOrder = order
        btn.AutoButtonColor = false
        btn.BorderSizePixel = 0
        corner(btn, 12)
        stroke(btn, Color3.fromRGB(255, 255, 255), 1, 0.3)
        pressFX(btn)
        
        -- Icon container (putih)
        local iconFrame = Instance.new("Frame", btn)
        iconFrame.Size = UDim2.new(0, 36, 0, 36)
        iconFrame.Position = UDim2.new(0, 7, 0.5, -18)
        iconFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        iconFrame.ZIndex = 2
        corner(iconFrame, 10)
        
        -- Icon image (gunakan URL asli)
        local iconImage = Instance.new("ImageLabel", iconFrame)
        iconImage.Size = UDim2.new(1, -8, 1, -8)
        iconImage.Position = UDim2.new(0, 4, 0, 4)
        iconImage.BackgroundTransparency = 1
        iconImage.Image = iconURL
        iconImage.ScaleType = Enum.ScaleType.Fit
        iconImage.ZIndex = 3
        
        -- Name
        local nameLbl = Instance.new("TextLabel", btn)
        nameLbl.Size = UDim2.new(1, -60, 0, 20)
        nameLbl.Position = UDim2.new(0, 50, 0, 8)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = name
        nameLbl.TextColor3 = colors.text
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 11
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.ZIndex = 2
        
        -- Subtitle
        local subLbl = Instance.new("TextLabel", btn)
        subLbl.Size = UDim2.new(1, -60, 0, 16)
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
            _G.showDynamicNotification(name .. " link copied!", colors.accent)
        end)
        
        return btn
    end
    
    createSocialButton(socialCard, 0, "Discord", Config.DiscordIconURL or "", Config.DiscordURL or "")
    createSocialButton(socialCard, 1, "WhatsApp", Config.WhatsAppIconURL or "", Config.WhatsAppURL or "")
    createSocialButton(socialCard, 2, "Telegram", Config.TelegramIconURL or "", Config.TelegramURL or "")
    
    -- ==================== KEY COUNTDOWN ====================
    local timerSection = createSection("KEY STATUS", 3)
    local timerCard = createGlassCard(timerSection, 1)
    
    local timerDisplay = Instance.new("TextLabel", timerCard)
    timerDisplay.Size = UDim2.new(1, 0, 0, 40)
    timerDisplay.BackgroundTransparency = 1
    timerDisplay.Text = "--:--:--"
    timerDisplay.TextColor3 = colors.text
    timerDisplay.Font = Enum.Font.GothamBlack
    timerDisplay.TextSize = 24
    timerDisplay.LayoutOrder = 0
    
    -- Update timer
    task.spawn(function()
        while timerDisplay.Parent do
            local savedKey = nil
            if Storage and Storage.appSettings then
                savedKey = Storage.appSettings.savedKey
            end
            
            if savedKey and savedKey ~= "" and Firebase and Firebase.GetData then
                local ok, keyData = pcall(function()
                    return Firebase.GetData("keys/" .. savedKey)
                end)
                
                if ok and keyData and keyData.expires then
                    local remaining = keyData.expires - os.time()
                    
                    if remaining > 0 then
                        local hours = math.floor(remaining / 3600)
                        local minutes = math.floor((remaining % 3600) / 60)
                        local seconds = remaining % 60
                        
                        timerDisplay.Text = string.format("%02d:%02d:%02d", hours, minutes, seconds)
                        
                        if remaining > 3600 then
                            timerDisplay.TextColor3 = colors.green
                        elseif remaining > 600 then
                            timerDisplay.TextColor3 = colors.gold
                        else
                            timerDisplay.TextColor3 = colors.red
                        end
                    else
                        timerDisplay.Text = "EXPIRED"
                        timerDisplay.TextColor3 = colors.red
                    end
                else
                    timerDisplay.Text = "NO KEY"
                    timerDisplay.TextColor3 = colors.text2
                end
            else
                timerDisplay.Text = "NO KEY"
                timerDisplay.TextColor3 = colors.text2
            end
            
            task.wait(1)
        end
    end)
    
    -- ==================== QUICK ACTIONS ====================
    local actionSection = createSection("AKSI CEPAT", 4)
    local actionCard = createGlassCard(actionSection, 1)
    
    local function createActionButton(parent, order, title, onClick)
        local btn = Instance.new("TextButton", parent)
        btn.Size = UDim2.new(1, 0, 0, 40)
        btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        btn.BackgroundTransparency = 0.3
        btn.LayoutOrder = order
        btn.AutoButtonColor = false
        btn.BorderSizePixel = 0
        corner(btn, 10)
        stroke(btn, Color3.fromRGB(255, 255, 255), 1, 0.3)
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
end

print("[Settings] App loaded!")