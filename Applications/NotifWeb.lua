-- ================================================
-- NOTIFWEB APP - Notifikasi dari Website
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

function _G.openNotifWebApp()
    -- Header info
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
    headerTitle.Text = "Notifikasi dari Website"
    headerTitle.TextColor3 = colors.text
    headerTitle.Font = Enum.Font.GothamBold
    headerTitle.TextSize = 12
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    
    local headerSub = Instance.new("TextLabel", header)
    headerSub.Size = UDim2.new(1, -20, 0, 14)
    headerSub.Position = UDim2.new(0, 10, 0, 24)
    headerSub.BackgroundTransparency = 1
    headerSub.Text = "Pesan dari admin akan muncul di sini"
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
    refreshBtn.Text = "Refresh Notifications"
    refreshBtn.TextColor3 = Color3.new(1, 1, 1)
    refreshBtn.Font = Enum.Font.GothamBold
    refreshBtn.TextSize = 11
    refreshBtn.AutoButtonColor = false
    refreshBtn.LayoutOrder = 2
    corner(refreshBtn, 10)
    Helpers.pressFX(refreshBtn)
    
    local function loadNotifications()
        -- Clear
        for _, c in ipairs(listHolder:GetChildren()) do
            if not c:IsA("UIListLayout") then c:Destroy() end
        end
        
        if not Firebase or not Firebase.GetNotifications then
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
        
        local notifs = Firebase.GetNotifications(LocalPlayer.UserId)
        
        if not notifs or type(notifs) ~= "table" then
            local empty = Instance.new("TextLabel", listHolder)
            empty.Size = UDim2.new(1, 0, 0, 50)
            empty.BackgroundTransparency = 1
            empty.Text = "Tidak ada notifikasi"
            empty.TextColor3 = colors.text3
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 11
            empty.LayoutOrder = 0
            return
        end
        
        local notifList = {}
        for notifId, notifData in pairs(notifs) do
            table.insert(notifList, {id = notifId, data = notifData})
        end
        
        table.sort(notifList, function(a, b)
            return (a.data.timestamp or 0) > (b.data.timestamp or 0)
        end)
        
        for i, notif in ipairs(notifList) do
            local card = Instance.new("Frame", listHolder)
            card.Size = UDim2.new(1, 0, 0, 60)
            card.BackgroundColor3 = colors.card
            card.BackgroundTransparency = 0.1
            card.LayoutOrder = i
            corner(card, 12)
            stroke(card, colors.border, 1, 0.3)
            
            -- Title
            local titleLbl = Instance.new("TextLabel", card)
            titleLbl.Size = UDim2.new(1, -20, 0, 20)
            titleLbl.Position = UDim2.new(0, 10, 0, 8)
            titleLbl.BackgroundTransparency = 1
            titleLbl.Text = notif.data.title or "Notification"
            titleLbl.TextColor3 = colors.text
            titleLbl.Font = Enum.Font.GothamBlack
            titleLbl.TextSize = 11
            titleLbl.TextXAlignment = Enum.TextXAlignment.Left
            
            -- Message
            local msgLbl = Instance.new("TextLabel", card)
            msgLbl.Size = UDim2.new(1, -20, 0, 16)
            msgLbl.Position = UDim2.new(0, 10, 0, 28)
            msgLbl.BackgroundTransparency = 1
            msgLbl.Text = notif.data.message or ""
            msgLbl.TextColor3 = colors.text2
            msgLbl.Font = Enum.Font.Gotham
            msgLbl.TextSize = 9
            msgLbl.TextXAlignment = Enum.TextXAlignment.Left
            msgLbl.TextTruncate = Enum.TextTruncate.AtEnd
            
            -- From
            local fromLbl = Instance.new("TextLabel", card)
            fromLbl.Size = UDim2.new(1, -20, 0, 14)
            fromLbl.Position = UDim2.new(0, 10, 0, 44)
            fromLbl.BackgroundTransparency = 1
            fromLbl.Text = "From: " .. (notif.data.from or "Admin")
            fromLbl.TextColor3 = colors.text3
            fromLbl.Font = Enum.Font.Gotham
            fromLbl.TextSize = 8
            fromLbl.TextXAlignment = Enum.TextXAlignment.Left
        end
    end
    
    refreshBtn.MouseButton1Click:Connect(loadNotifications)
    
    -- Load awal
    loadNotifications()
    
    -- Auto refresh setiap 10 detik
    task.spawn(function()
        while listHolder.Parent do
            task.wait(10)
            loadNotifications()
        end
    end)
end

print("[NotifWeb] App loaded!")