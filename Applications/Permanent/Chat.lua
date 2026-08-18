-- ================================================
-- PERMANENT/CHAT.LUA - Chat & Banner ke Target
-- ================================================

local Services = _G.Services
local LocalPlayer = _G.LocalPlayer
local Firebase = _G.Firebase
local Helpers = _G.Helpers or {}

local function openChatApp(contentArea)
    local State = _G.PremiumState
    
    local P = {
        bgCard2 = Color3.fromRGB(26, 26, 34),
        bgElevated = Color3.fromRGB(32, 32, 42),
        accent = Color3.fromRGB(168, 110, 255),
        green = Color3.fromRGB(80, 220, 150),
        gold = Color3.fromRGB(255, 195, 90),
        red = Color3.fromRGB(255, 90, 100),
        textMain = Color3.fromRGB(240, 240, 245),
        textSub = Color3.fromRGB(150, 150, 165),
        border = Color3.fromRGB(45, 45, 58),
    }

    local COMMAND_COOLDOWN = 1.0
    local lastCommandTime = 0

    local function sendCommand(cmdType, extraData)
        if not State.selectedTargetId then
            _G.showDynamicNotification("Pilih target dulu!", P.red)
            return false
        end
        if os.clock() - lastCommandTime < COMMAND_COOLDOWN then
            _G.showDynamicNotification("Cooldown!", P.gold)
            return false
        end
        lastCommandTime = os.clock()
        
        local data = { type = cmdType, timestamp = os.time() }
        if extraData then
            for k, v in pairs(extraData) do data[k] = v end
        end
        pcall(function() Firebase.PushCommand(State.selectedTargetId, data) end)
        _G.showDynamicNotification("Terkirim!", P.green)
        return true
    end

    -- Chat input
    local chatCard = Instance.new("Frame", contentArea)
    chatCard.Size = UDim2.new(0.95, 0, 0, 46)
    chatCard.BackgroundColor3 = P.bgCard2
    Helpers.corner(chatCard, 12)
    Helpers.stroke(chatCard, P.border, 1, 0.4)

    local chatInput = Instance.new("TextBox", chatCard)
    chatInput.Size = UDim2.new(1, -16, 1, -12)
    chatInput.Position = UDim2.new(0, 8, 0, 6)
    chatInput.BackgroundColor3 = P.bgElevated
    chatInput.PlaceholderText = "Ketik pesan..."
    chatInput.Text = ""
    chatInput.Font = Enum.Font.Gotham
    chatInput.TextSize = 11
    chatInput.TextColor3 = P.textMain
    chatInput.ClearTextOnFocus = false
    Helpers.corner(chatInput, 8)

    local sendChatBtn = Instance.new("TextButton", contentArea)
    sendChatBtn.Size = UDim2.new(0.95, 0, 0, 34)
    sendChatBtn.BackgroundColor3 = P.green
    sendChatBtn.Text = "Kirim Chat Publik"
    sendChatBtn.TextColor3 = Color3.new(1, 1, 1)
    sendChatBtn.Font = Enum.Font.GothamBold
    sendChatBtn.TextSize = 11
    sendChatBtn.AutoButtonColor = false
    Helpers.corner(sendChatBtn, 8)
    sendChatBtn.MouseButton1Click:Connect(function()
        if sendCommand("force_chat", { message = chatInput.Text }) then
            chatInput.Text = ""
        end
    end)

    -- Banner input
    local bannerCard = Instance.new("Frame", contentArea)
    bannerCard.Size = UDim2.new(0.95, 0, 0, 46)
    bannerCard.BackgroundColor3 = P.bgCard2
    Helpers.corner(bannerCard, 12)
    Helpers.stroke(bannerCard, P.border, 1, 0.4)

    local bannerInput = Instance.new("TextBox", bannerCard)
    bannerInput.Size = UDim2.new(1, -16, 1, -12)
    bannerInput.Position = UDim2.new(0, 8, 0, 6)
    bannerInput.BackgroundColor3 = P.bgElevated
    bannerInput.PlaceholderText = "Pesan banner full-screen..."
    bannerInput.Text = ""
    bannerInput.Font = Enum.Font.Gotham
    bannerInput.TextSize = 11
    bannerInput.TextColor3 = P.textMain
    bannerInput.ClearTextOnFocus = false
    Helpers.corner(bannerInput, 8)

    local sendBannerBtn = Instance.new("TextButton", contentArea)
    sendBannerBtn.Size = UDim2.new(0.95, 0, 0, 34)
    sendBannerBtn.BackgroundColor3 = P.gold
    sendBannerBtn.Text = "Kirim Banner Layar"
    sendBannerBtn.TextColor3 = Color3.fromRGB(30, 25, 10)
    sendBannerBtn.Font = Enum.Font.GothamBold
    sendBannerBtn.TextSize = 11
    sendBannerBtn.AutoButtonColor = false
    Helpers.corner(sendBannerBtn, 8)
    sendBannerBtn.MouseButton1Click:Connect(function()
        if bannerInput.Text == "" then
            _G.showDynamicNotification("Isi pesan dulu!", P.red)
            return
        end
        if sendCommand("screen_message", { message = bannerInput.Text, duration = 5 }) then
            bannerInput.Text = ""
        end
    end)
end

_G.PremiumSubApps = _G.PremiumSubApps or {}
_G.PremiumSubApps["Chat"] = {
    name = "Chat",
    iconName = "Chat",
    loadFunc = openChatApp,
}

print("[Permanent/Chat] Loaded!")