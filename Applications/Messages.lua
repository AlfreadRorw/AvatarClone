-- ================================================
-- MESSAGES APP - Chat dengan Website + Notifikasi
-- ================================================

local Services = _G.Services
local LocalPlayer = _G.LocalPlayer
local Players = Services.Players
local T = _G.T
local Helpers = _G.Helpers
local Firebase = _G.Firebase

local appContent = _G.appContent

local corner = Helpers.corner
local stroke = Helpers.stroke
local tween = Helpers.tween

local colors = {
    card = Color3.fromRGB(255, 255, 255),
    accent = Color3.fromRGB(0, 150, 255),
    green = Color3.fromRGB(0, 230, 118),
    red = Color3.fromRGB(255, 82, 82),
    gold = Color3.fromRGB(255, 180, 50),
    text = Color3.fromRGB(30, 30, 35),
    text2 = Color3.fromRGB(100, 100, 110),
    text3 = Color3.fromRGB(140, 140, 150),
    border = Color3.fromRGB(220, 220, 225),
}

-- ==================== CHAT DATA ====================
local chatPath = "chat"
local lastChatTimestamp = 0

-- ==================== NOTIFIKASI BANNER (DARI ATAS) ====================
local notifBanner = nil
local notifQueue = {}
local isShowingNotif = false

local function showTopNotification(title, message, fromName)
    table.insert(notifQueue, {title = title, message = message, fromName = fromName})
    if not isShowingNotif then
        processNotifQueue()
    end
end

function processNotifQueue()
    if #notifQueue == 0 then
        isShowingNotif = false
        return
    end
    
    isShowingNotif = true
    local notif = table.remove(notifQueue, 1)
    
    -- Hapus banner lama
    if notifBanner then
        pcall(function() notifBanner:Destroy() end)
        notifBanner = nil
    end
    
    -- Buat banner baru
    local screenGui = _G.Phone and _G.Phone.gui
    if not screenGui then
        isShowingNotif = false
        return
    end
    
    notifBanner = Instance.new("Frame", screenGui)
    notifBanner.Size = UDim2.new(1, -20, 0, 70)
    notifBanner.Position = UDim2.new(0, 10, -0.3, 0)
    notifBanner.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    notifBanner.BorderSizePixel = 0
    notifBanner.ZIndex = 999
    notifBanner.ClipsDescendants = true
    corner(notifBanner, 16)
    stroke(notifBanner, colors.accent, 2, 0.3)
    
    -- Gradient
    local bgGradient = Instance.new("UIGradient", notifBanner)
    bgGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 35)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 22))
    })
    bgGradient.Rotation = 135
    
    -- Glow line
    local glowLine = Instance.new("Frame", notifBanner)
    glowLine.Size = UDim2.new(0, 4, 1, -20)
    glowLine.Position = UDim2.new(0, 8, 0, 10)
    glowLine.BackgroundColor3 = colors.accent
    glowLine.BorderSizePixel = 0
    glowLine.ZIndex = 1000
    corner(glowLine, 2)
    
    -- Title
    local titleLbl = Instance.new("TextLabel", notifBanner)
    titleLbl.Size = UDim2.new(1, -30, 0, 22)
    titleLbl.Position = UDim2.new(0, 20, 0, 8)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "📨 " .. (notif.title or "Pesan Baru")
    titleLbl.TextColor3 = Color3.new(1, 1, 1)
    titleLbl.Font = Enum.Font.GothamBlack
    titleLbl.TextSize = 12
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 1001
    
    -- Message
    local msgLbl = Instance.new("TextLabel", notifBanner)
    msgLbl.Size = UDim2.new(1, -30, 0, 18)
    msgLbl.Position = UDim2.new(0, 20, 0, 30)
    msgLbl.BackgroundTransparency = 1
    msgLbl.Text = (notif.message or "")
    msgLbl.TextColor3 = Color3.fromRGB(180, 180, 200)
    msgLbl.Font = Enum.Font.Gotham
    msgLbl.TextSize = 10
    msgLbl.TextXAlignment = Enum.TextXAlignment.Left
    msgLbl.TextTruncate = Enum.TextTruncate.AtEnd
    msgLbl.ZIndex = 1001
    
    -- From
    local fromLbl = Instance.new("TextLabel", notifBanner)
    fromLbl.Size = UDim2.new(1, -30, 0, 14)
    fromLbl.Position = UDim2.new(0, 20, 0, 48)
    fromLbl.BackgroundTransparency = 1
    fromLbl.Text = "Dari: " .. (notif.fromName or "Admin")
    fromLbl.TextColor3 = Color3.fromRGB(100, 100, 130)
    fromLbl.Font = Enum.Font.GothamBold
    fromLbl.TextSize = 8
    fromLbl.TextXAlignment = Enum.TextXAlignment.Left
    fromLbl.ZIndex = 1001
    
    -- Close button
    local closeBtn = Instance.new("TextButton", notifBanner)
    closeBtn.Size = UDim2.new(0, 20, 0, 20)
    closeBtn.Position = UDim2.new(1, -26, 0, 4)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(150, 150, 170)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.ZIndex = 1002
    
    closeBtn.MouseButton1Click:Connect(function()
        pcall(function() notifBanner:Destroy() end)
        notifBanner = nil
        isShowingNotif = false
        processNotifQueue()
    end)
    
    -- Animasi masuk
    tween(notifBanner, {Position = UDim2.new(0, 10, 0, 10)}, 0.4, Enum.EasingStyle.Back)
    
    -- Auto close setelah 5 detik
    task.delay(5, function()
        if notifBanner then
            tween(notifBanner, {Position = UDim2.new(0, 10, -0.3, 0)}, 0.3, Enum.EasingStyle.Quart)
            task.delay(0.3, function()
                pcall(function() notifBanner:Destroy() end)
                notifBanner = nil
                isShowingNotif = false
                processNotifQueue()
            end)
        end
    end)
end

-- ==================== CHAT MONITOR ====================
local lastChatCount = 0

task.spawn(function()
    while true do
        task.wait(3)
        
        if Firebase and Firebase.GetData then
            local chatData = Firebase.GetData("chat")
            if chatData and type(chatData) == "table" then
                local chatList = {}
                for chatId, chatInfo in pairs(chatData) do
                    table.insert(chatList, {id = chatId, data = chatInfo})
                end
                
                table.sort(chatList, function(a, b)
                    return (a.data.timestamp or 0) > (b.data.timestamp or 0)
                end)
                
                if #chatList > lastChatCount and #chatList > 0 then
                    local latestChat = chatList[1]
                    if latestChat and latestChat.data then
                        local chat = latestChat.data
                        local isFromAdmin = chat.from == "admin"
                        local isForMe = chat.target == tostring(LocalPlayer.UserId) or chat.target == "all"
                        
                        if isFromAdmin and isForMe then
                            -- Tampilkan notifikasi dari atas
                            showTopNotification(
                                "Pesan dari Admin",
                                chat.message or "",
                                chat.fromName or "Admin"
                            )
                            
                            -- Juga tampilkan di Dynamic Island
                            _G.showDynamicNotification("💬 " .. (chat.message or "Pesan baru"), colors.accent)
                        end
                    end
                end
                
                lastChatCount = #chatList
            end
        end
    end
end)

-- ==================== OPEN APP ====================
function _G.openMessageApp()
    -- Header
    local header = Instance.new("Frame", appContent)
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = colors.card
    header.BackgroundTransparency = 0.1
    header.LayoutOrder = 0
    corner(header, 12)
    stroke(header, colors.border, 1, 0.3)
    
    local headerTitle = Instance.new("TextLabel", header)
    headerTitle.Size = UDim2.new(1, -20, 0, 20)
    headerTitle.Position = UDim2.new(0, 10, 0, 5)
    headerTitle.BackgroundTransparency = 1
    headerTitle.Text = "💬 Messages"
    headerTitle.TextColor3 = colors.text
    headerTitle.Font = Enum.Font.GothamBold
    headerTitle.TextSize = 12
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    
    local headerSub = Instance.new("TextLabel", header)
    headerSub.Size = UDim2.new(1, -20, 0, 14)
    headerSub.Position = UDim2.new(0, 10, 0, 24)
    headerSub.BackgroundTransparency = 1
    headerSub.Text = "Chat dengan Admin via Website"
    headerSub.TextColor3 = colors.text3
    headerSub.Font = Enum.Font.Gotham
    headerSub.TextSize = 8
    headerSub.TextXAlignment = Enum.TextXAlignment.Left
    
    -- List holder
    local listHolder = Instance.new("Frame", appContent)
    listHolder.Size = UDim2.new(1, 0, 0, 0)
    listHolder.AutomaticSize = Enum.AutomaticSize.Y
    listHolder.BackgroundTransparency = 1
    listHolder.LayoutOrder = 1
    
    local listLayout = Instance.new("UIListLayout", listHolder)
    listLayout.Padding = UDim.new(0, 8)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- Refresh button
    local refreshBtn = Instance.new("TextButton", appContent)
    refreshBtn.Size = UDim2.new(1, 0, 0, 35)
    refreshBtn.BackgroundColor3 = colors.accent
    refreshBtn.Text = "🔄 Refresh Messages"
    refreshBtn.TextColor3 = Color3.new(1, 1, 1)
    refreshBtn.Font = Enum.Font.GothamBold
    refreshBtn.TextSize = 11
    refreshBtn.AutoButtonColor = false
    refreshBtn.LayoutOrder = 2
    corner(refreshBtn, 10)
    Helpers.pressFX(refreshBtn)
    
    local function loadChats()
        -- Clear
        for _, c in ipairs(listHolder:GetChildren()) do
            if not c:IsA("UIListLayout") then c:Destroy() end
        end
        
        if not Firebase or not Firebase.GetData then
            local empty = Instance.new("TextLabel", listHolder)
            empty.Size = UDim2.new(1, 0, 0, 50)
            empty.BackgroundTransparency = 1
            empty.Text = "Firebase tidak tersedia"
            empty.TextColor3 = colors.text3
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 11
            empty.LayoutOrder = 0
            return
        end
        
        local chatData = Firebase.GetData("chat")
        
        if not chatData or type(chatData) ~= "table" then
            local empty = Instance.new("TextLabel", listHolder)
            empty.Size = UDim2.new(1, 0, 0, 50)
            empty.BackgroundTransparency = 1
            empty.Text = "Tidak ada pesan"
            empty.TextColor3 = colors.text3
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 11
            empty.LayoutOrder = 0
            return
        end
        
        local chatList = {}
        for chatId, chatInfo in pairs(chatData) do
            if chatInfo.target == "all" or chatInfo.target == tostring(LocalPlayer.UserId) then
                table.insert(chatList, {id = chatId, data = chatInfo})
            end
        end
        
        table.sort(chatList, function(a, b)
            return (a.data.timestamp or 0) > (b.data.timestamp or 0)
        end)
        
        for i, chat in ipairs(chatList) do
            local isAdmin = chat.data.from == "admin"
            
            local card = Instance.new("Frame", listHolder)
            card.Size = UDim2.new(1, 0, 0, 70)
            card.BackgroundColor3 = isAdmin and Color3.fromRGB(0, 150, 255) or colors.card
            card.BackgroundTransparency = isAdmin and 0.9 or 0.1
            card.LayoutOrder = i
            corner(card, 12)
            stroke(card, isAdmin and colors.accent or colors.border, 1, 0.3)
            
            -- Sender
            local senderLbl = Instance.new("TextLabel", card)
            senderLbl.Size = UDim2.new(1, -20, 0, 18)
            senderLbl.Position = UDim2.new(0, 10, 0, 8)
            senderLbl.BackgroundTransparency = 1
            senderLbl.Text = (isAdmin and "👑 " or "👤 ") .. (chat.data.fromName or "Unknown")
            senderLbl.TextColor3 = isAdmin and colors.accent or colors.green
            senderLbl.Font = Enum.Font.GothamBlack
            senderLbl.TextSize = 10
            senderLbl.TextXAlignment = Enum.TextXAlignment.Left
            
            -- Message
            local msgLbl = Instance.new("TextLabel", card)
            msgLbl.Size = UDim2.new(1, -20, 0, 18)
            msgLbl.Position = UDim2.new(0, 10, 0, 26)
            msgLbl.BackgroundTransparency = 1
            msgLbl.Text = chat.data.message or ""
            msgLbl.TextColor3 = colors.text
            msgLbl.Font = Enum.Font.Gotham
            msgLbl.TextSize = 11
            msgLbl.TextXAlignment = Enum.TextXAlignment.Left
            msgLbl.TextWrapped = true
            
            -- Timestamp
            local timeLbl = Instance.new("TextLabel", card)
            timeLbl.Size = UDim2.new(1, -20, 0, 14)
            timeLbl.Position = UDim2.new(0, 10, 0, 46)
            timeLbl.BackgroundTransparency = 1
            timeLbl.Text = os.date("%d/%m/%Y %H:%M", chat.data.timestamp or os.time())
            timeLbl.TextColor3 = colors.text3
            timeLbl.Font = Enum.Font.Gotham
            timeLbl.TextSize = 8
            timeLbl.TextXAlignment = Enum.TextXAlignment.Left
        end
    end
    
    refreshBtn.MouseButton1Click:Connect(loadChats)
    
    -- Load awal
    loadChats()
    
    -- Auto refresh setiap 5 detik
    task.spawn(function()
        while listHolder.Parent do
            task.wait(5)
            loadChats()
        end
    end)
end

print("[Messages] App loaded with top notification!")