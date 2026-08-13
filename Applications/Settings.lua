-- ================================================
-- SETTINGS APP - With Developer Info & Countdown Timer
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

-- ==================== SECTION BUILDER ====================
local function createSection(title, order)
    local section = Instance.new("Frame", appContent)
    section.Size = UDim2.new(1, 0, 0, 0)
    section.AutomaticSize = Enum.AutomaticSize.Y
    section.BackgroundTransparency = 1
    section.LayoutOrder = order
    
    local sectionLayout = Instance.new("UIListLayout", section)
    sectionLayout.Padding = UDim.new(0, 8)
    sectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- Section title
    local titleLbl = Instance.new("TextLabel", section)
    titleLbl.Size = UDim2.new(1, 0, 0, 20)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = T.Text2 or Color3.fromRGB(120, 120, 120)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 10
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.LayoutOrder = 0
    
    return section
end

local function createCard(parent, order)
    local card = Instance.new("Frame", parent)
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = T.Card or Color3.fromRGB(245, 245, 245)
    card.LayoutOrder = order
    corner(card, 12)
    stroke(card, T.Border or Color3.fromRGB(200, 200, 200), 1, 0.3)
    
    local cardLayout = Instance.new("UIListLayout", card)
    cardLayout.Padding = UDim.new(0, 6)
    cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    return card
end

-- ==================== OPEN SETTINGS APP ====================
function _G.openSettingsApp()
    -- ==================== DEVELOPER INFO ====================
    local devSection = createSection("DEVELOPER", 1)
    
    local devCard = createCard(devSection, 1)
    
    -- Developer header
    local devHeader = Instance.new("Frame", devCard)
    devHeader.Size = UDim2.new(1, 0, 0, 60)
    devHeader.BackgroundTransparency = 1
    devHeader.LayoutOrder = 0
    
    -- Avatar frame
    local avatarFrame = Instance.new("Frame", devHeader)
    avatarFrame.Size = UDim2.new(0, 50, 0, 50)
    avatarFrame.Position = UDim2.new(0, 8, 0.5, -25)
    avatarFrame.BackgroundColor3 = T.Accent or Color3.fromRGB(30, 30, 30)
    avatarFrame.ZIndex = 2
    corner(avatarFrame, 100)
    stroke(avatarFrame, T.Gold or Color3.fromRGB(200, 150, 0), 2, 0)
    
    -- Avatar image
    local avatarImage = Instance.new("ImageLabel", avatarFrame)
    avatarImage.Size = UDim2.new(1, -6, 1, -6)
    avatarImage.Position = UDim2.new(0, 3, 0, 3)
    avatarImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    avatarImage.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. (Config.DEVELOPER_USER_ID or LocalPlayer.UserId) .. "&width=100&height=100&format=png"
    avatarImage.ZIndex = 3
    corner(avatarImage, 100)
    
    -- Developer name
    local devName = Instance.new("TextLabel", devHeader)
    devName.Size = UDim2.new(1, -70, 0, 20)
    devName.Position = UDim2.new(0, 66, 0, 10)
    devName.BackgroundTransparency = 1
    devName.Text = Config.DEVELOPER_USERNAME or "AlfreadR0rw"
    devName.TextColor3 = T.Text or Color3.fromRGB(30, 30, 30)
    devName.Font = Enum.Font.GothamBlack
    devName.TextSize = 14
    devName.TextXAlignment = Enum.TextXAlignment.Left
    devName.ZIndex = 2
    
    -- Role label
    local devRole = Instance.new("TextLabel", devHeader)
    devRole.Size = UDim2.new(0, 50, 0, 18)
    devRole.Position = UDim2.new(0, 66, 0, 32)
    devRole.BackgroundColor3 = T.Gold or Color3.fromRGB(200, 150, 0)
    devRole.Text = "DEV"
    devRole.TextColor3 = Color3.new(1, 1, 1)
    devRole.Font = Enum.Font.GothamBlack
    devRole.TextSize = 9
    devRole.ZIndex = 2
    corner(devRole, 9)
    
    -- ==================== COUNTDOWN TIMER ====================
    local timerSection = createSection("KEY EXPIRED", 2)
    
    local timerCard = createCard(timerSection, 1)
    timerCard.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    stroke(timerCard, Color3.fromRGB(255, 255, 255), 1, 0.5)
    
    -- Timer label
    local timerTitle = Instance.new("TextLabel", timerCard)
    timerTitle.Size = UDim2.new(1, 0, 0, 20)
    timerTitle.BackgroundTransparency = 1
    timerTitle.Text = "Waktu tersisa"
    timerTitle.TextColor3 = Color3.fromRGB(150, 150, 170)
    timerTitle.Font = Enum.Font.Gotham
    timerTitle.TextSize = 10
    timerTitle.LayoutOrder = 0
    
    -- Timer display
    local timerDisplay = Instance.new("TextLabel", timerCard)
    timerDisplay.Size = UDim2.new(1, 0, 0, 40)
    timerDisplay.BackgroundTransparency = 1
    timerDisplay.Text = "--:--:--"
    timerDisplay.TextColor3 = Color3.new(1, 1, 1)
    timerDisplay.Font = Enum.Font.GothamBlack
    timerDisplay.TextSize = 24
    timerDisplay.LayoutOrder = 1
    
    -- Timer info
    local timerInfo = Instance.new("TextLabel", timerCard)
    timerInfo.Size = UDim2.new(1, 0, 0, 16)
    timerInfo.BackgroundTransparency = 1
    timerInfo.Text = "Key akan expired setelah waktu habis"
    timerInfo.TextColor3 = Color3.fromRGB(100, 100, 120)
    timerInfo.Font = Enum.Font.Gotham
    timerInfo.TextSize = 9
    timerInfo.LayoutOrder = 2
    
    -- Update timer setiap detik
    task.spawn(function()
        while timerDisplay.Parent do
            local savedKey = appSettings.savedKey
            if savedKey and savedKey ~= "" then
                -- Ambil data key dari Firebase
                local keyData = Firebase.GetData("keys/" .. savedKey)
                if keyData and keyData.expires then
                    local now = os.time()
                    local remaining = keyData.expires - now
                    
                    if remaining > 0 then
                        local hours = math.floor(remaining / 3600)
                        local minutes = math.floor((remaining % 3600) / 60)
                        local seconds = remaining % 60
                        
                        timerDisplay.Text = string.format("%02d:%02d:%02d", hours, minutes, seconds)
                        timerDisplay.TextColor3 = remaining > 3600 and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 200, 50)
                        
                        if remaining < 3600 then
                            timerInfo.Text = "⚠️ Key akan segera expired!"
                            timerInfo.TextColor3 = Color3.fromRGB(255, 200, 50)
                        end
                    else
                        timerDisplay.Text = "EXPIRED"
                        timerDisplay.TextColor3 = Color3.fromRGB(255, 80, 80)
                        timerInfo.Text = "Key sudah expired, silakan beli key baru"
                        timerInfo.TextColor3 = Color3.fromRGB(255, 80, 80)
                    end
                else
                    timerDisplay.Text = "NO KEY"
                    timerDisplay.TextColor3 = Color3.fromRGB(150, 150, 150)
                    timerInfo.Text = "Belum ada key yang dimasukkan"
                end
            else
                timerDisplay.Text = "NO KEY"
                timerDisplay.TextColor3 = Color3.fromRGB(150, 150, 150)
                timerInfo.Text = "Belum ada key yang dimasukkan"
            end
            
            task.wait(1)
        end
    end)
    
    -- ==================== TOGGLE SETTINGS ====================
    local toggleSection = createSection("PENGATURAN", 3)
    
    -- Toggle card
    local toggleCard = createCard(toggleSection, 1)
    
    -- Helper untuk membuat toggle row
    local function createToggleRow(parent, order, title, description, initialState, onChange)
        local row = Instance.new("Frame", parent)
        row.Size = UDim2.new(1, 0, 0, 40)
        row.BackgroundTransparency = 1
        row.LayoutOrder = order
        
        -- Text container
        local textFrame = Instance.new("Frame", row)
        textFrame.Size = UDim2.new(1, -60, 1, 0)
        textFrame.BackgroundTransparency = 1
        
        local titleLbl = Instance.new("TextLabel", textFrame)
        titleLbl.Size = UDim2.new(1, 0, 0, 20)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = title
        titleLbl.TextColor3 = T.Text or Color3.fromRGB(30, 30, 30)
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.TextSize = 11
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        
        local descLbl = Instance.new("TextLabel", textFrame)
        descLbl.Size = UDim2.new(1, 0, 0, 16)
        descLbl.Position = UDim2.new(0, 0, 0, 20)
        descLbl.BackgroundTransparency = 1
        descLbl.Text = description
        descLbl.TextColor3 = T.Text2 or Color3.fromRGB(120, 120, 120)
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
        Helpers.showDynamicNotification("Toast " .. (state and "ON" or "OFF"), T.Accent)
    end)
    
    createToggleRow(toggleCard, 1, "Glow Effect", "Efek cahaya di pinggir phone", appSettings.glowEnabled ~= false, function(state)
        appSettings.glowEnabled = state
        Storage.persistSettings()
    end)
    
    -- ==================== QUICK ACTIONS ====================
    local actionSection = createSection("AKSI CEPAT", 4)
    
    local actionCard = createCard(actionSection, 1)
    
    -- Helper untuk membuat button row
    local function createButtonRow(parent, order, title, icon, onClick, buttonColor)
        local row = Instance.new("TextButton", parent)
        row.Size = UDim2.new(1, 0, 0, 40)
        row.BackgroundColor3 = T.Card2 or Color3.fromRGB(230, 230, 230)
        row.LayoutOrder = order
        row.AutoButtonColor = false
        corner(row, 8)
        pressFX(row)
        
        local titleLbl = Instance.new("TextLabel", row)
        titleLbl.Size = UDim2.new(1, -50, 1, 0)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = title
        titleLbl.TextColor3 = T.Text or Color3.fromRGB(30, 30, 30)
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.TextSize = 11
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        
        row.MouseButton1Click:Connect(onClick)
        
        return row
    end
    
    -- Rejoin server
    createButtonRow(actionCard, 0, "Rejoin Server", "↻", function()
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId)
        end)
    end)
    
    -- Copy User ID
    createButtonRow(actionCard, 1, "Copy User ID", "📋", function()
        Helpers.copyToClipboard(tostring(LocalPlayer.UserId))
        Helpers.showDynamicNotification("User ID copied!", T.Green)
    end)
    
    -- Copy Key
    createButtonRow(actionCard, 2, "Copy Key", "🔑", function()
        local savedKey = appSettings.savedKey
        if savedKey and savedKey ~= "" then
            Helpers.copyToClipboard(savedKey)
            Helpers.showDynamicNotification("Key copied!", T.Green)
        else
            Helpers.showDynamicNotification("No key saved", T.Red)
        end
    end)
    
    -- Buy Key
    createButtonRow(actionCard, 3, "Buy Key", "🛒", function()
        local url = Config.BUY_KEY_URL or "https://discord.gg/"
        Helpers.copyToClipboard(url)
        Helpers.showDynamicNotification("Link copied to clipboard!", Color3.fromRGB(255, 200, 50))
    end)
    
    -- ==================== VERSION INFO ====================
    local versionSection = createSection("INFORMASI", 5)
    
    local versionCard = createCard(versionSection, 1)
    
    local versionLbl = Instance.new("TextLabel", versionCard)
    versionLbl.Size = UDim2.new(1, 0, 0, 20)
    versionLbl.BackgroundTransparency = 1
    versionLbl.Text = "Version: 2.0.0"
    versionLbl.TextColor3 = T.Text2 or Color3.fromRGB(120, 120, 120)
    versionLbl.Font = Enum.Font.Gotham
    versionLbl.TextSize = 10
    versionLbl.LayoutOrder = 0
    
    local copyrightLbl = Instance.new("TextLabel", versionCard)
    copyrightLbl.Size = UDim2.new(1, 0, 0, 16)
    copyrightLbl.BackgroundTransparency = 1
    copyrightLbl.Text = "© 2024 " .. (Config.DEVELOPER_USERNAME or "AlfreadR0rw") .. " - All Rights Reserved"
    copyrightLbl.TextColor3 = T.Text2 or Color3.fromRGB(120, 120, 120)
    copyrightLbl.Font = Enum.Font.Gotham
    copyrightLbl.TextSize = 8
    copyrightLbl.LayoutOrder = 1
    
    local creditLbl = Instance.new("TextLabel", versionCard)
    creditLbl.Size = UDim2.new(1, 0, 0, 16)
    creditLbl.BackgroundTransparency = 1
    creditLbl.Text = "Made with ♥ by " .. (Config.DEVELOPER_USERNAME or "AlfreadR0rw")
    creditLbl.TextColor3 = T.Text2 or Color3.fromRGB(120, 120, 120)
    creditLbl.Font = Enum.Font.Gotham
    creditLbl.TextSize = 8
    creditLbl.LayoutOrder = 2
end

print("[Settings] App loaded!")