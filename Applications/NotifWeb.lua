-- ================================================
-- NOTIFWEB APP - Notifikasi dari Website
-- ================================================

local Services = _G.Services
local LocalPlayer = _G.LocalPlayer
local Players = Services.Players
local T = _G.T
local Helpers = _G.Helpers
local Firebase = _G.Firebase
local Assets = _G.Assets

local appContent = _G.appContent

local corner = Helpers.corner
local stroke = Helpers.stroke
local tween = Helpers.tween
local pressFX = Helpers.pressFX

-- Colors
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
    unread = Color3.fromRGB(235, 240, 255),
}

-- ==================== OPEN NOTIFWEB APP ====================
function _G.openNotifWebApp()
    -- ==================== HEADER ====================
    local header = Instance.new("Frame", appContent)
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = colors.card
    header.LayoutOrder = 0
    corner(header, 14)
    stroke(header, colors.border, 1, 0.3)

    -- Bell icon
    local bellIcon = Instance.new("ImageLabel", header)
    bellIcon.Size = UDim2.new(0, 28, 0, 28)
    bellIcon.Position = UDim2.new(0, 10, 0.5, -14)
    bellIcon.BackgroundTransparency = 1
    bellIcon.Image = Assets.GetIcon("bell")
    bellIcon.ScaleType = Enum.ScaleType.Fit
    bellIcon.ZIndex = 2

    -- Title
    local headerTitle = Instance.new("TextLabel", header)
    headerTitle.Size = UDim2.new(1, -50, 0, 22)
    headerTitle.Position = UDim2.new(0, 45, 0, 6)
    headerTitle.BackgroundTransparency = 1
    headerTitle.Text = "Notifikasi Website"
    headerTitle.TextColor3 = colors.text
    headerTitle.Font = Enum.Font.GothamBlack
    headerTitle.TextSize = 13
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    headerTitle.ZIndex = 2

    -- Subtitle
    local headerSub = Instance.new("TextLabel", header)
    headerSub.Size = UDim2.new(1, -50, 0, 16)
    headerSub.Position = UDim2.new(0, 45, 0, 27)
    headerSub.BackgroundTransparency = 1
    headerSub.Text = "Pesan dari admin akan muncul di sini"
    headerSub.TextColor3 = colors.text3
    headerSub.Font = Enum.Font.Gotham
    headerSub.TextSize = 8
    headerSub.TextXAlignment = Enum.TextXAlignment.Left
    headerSub.ZIndex = 2

    -- ==================== LIST HOLDER ====================
    local listHolder = Instance.new("Frame", appContent)
    listHolder.Size = UDim2.new(1, 0, 0, 0)
    listHolder.AutomaticSize = Enum.AutomaticSize.Y
    listHolder.BackgroundTransparency = 1
    listHolder.LayoutOrder = 1

    local listLayout = Instance.new("UIListLayout", listHolder)
    listLayout.Padding = UDim.new(0, 8)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- ==================== REFRESH BUTTON ====================
    local refreshBtn = Instance.new("TextButton", appContent)
    refreshBtn.Size = UDim2.new(1, 0, 0, 40)
    refreshBtn.BackgroundColor3 = colors.accent
    refreshBtn.Text = "Refresh Notifications"
    refreshBtn.TextColor3 = Color3.new(1, 1, 1)
    refreshBtn.Font = Enum.Font.GothamBold
    refreshBtn.TextSize = 11
    refreshBtn.AutoButtonColor = false
    refreshBtn.LayoutOrder = 2
    corner(refreshBtn, 10)
    pressFX(refreshBtn)

    -- Refresh icon
    local refreshIcon = Instance.new("ImageLabel", refreshBtn)
    refreshIcon.Size = UDim2.new(0, 20, 0, 20)
    refreshIcon.Position = UDim2.new(0, 10, 0.5, -10)
    refreshIcon.BackgroundTransparency = 1
    refreshIcon.Image = Assets.GetIcon("refresh")
    refreshIcon.ScaleType = Enum.ScaleType.Fit
    refreshIcon.ZIndex = 2

    -- ==================== LOAD NOTIFICATIONS ====================
    local function loadNotifications()
        -- Clear
        for _, c in ipairs(listHolder:GetChildren()) do
            if not c:IsA("UIListLayout") then c:Destroy() end
        end

        if not Firebase or not Firebase.GetNotifications then
            local empty = Instance.new("TextLabel", listHolder)
            empty.Size = UDim2.new(1, 0, 0, 60)
            empty.BackgroundTransparency = 1
            empty.Text = "Firebase tidak tersedia"
            empty.TextColor3 = colors.text3
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 11
            empty.LayoutOrder = 0
            return
        end

        local notifs = Firebase.GetNotifications(LocalPlayer.UserId)

        if not notifs or type(notifs) ~= "table" or next(notifs) == nil then
            -- Empty state
            local emptyFrame = Instance.new("Frame", listHolder)
            emptyFrame.Size = UDim2.new(1, 0, 0, 80)
            emptyFrame.BackgroundColor3 = colors.card
            emptyFrame.LayoutOrder = 0
            corner(emptyFrame, 14)
            stroke(emptyFrame, colors.border, 1, 0.3)

            -- Empty icon
            local emptyIcon = Instance.new("ImageLabel", emptyFrame)
            emptyIcon.Size = UDim2.new(0, 40, 0, 40)
            emptyIcon.Position = UDim2.new(0.5, -20, 0, 10)
            emptyIcon.BackgroundTransparency = 1
            emptyIcon.Image = Assets.GetIcon("check")
            emptyIcon.ScaleType = Enum.ScaleType.Fit
            emptyIcon.ZIndex = 2

            local emptyText = Instance.new("TextLabel", emptyFrame)
            emptyText.Size = UDim2.new(1, 0, 0, 20)
            emptyText.Position = UDim2.new(0, 0, 0, 55)
            emptyText.BackgroundTransparency = 1
            emptyText.Text = "Tidak ada notifikasi"
            emptyText.TextColor3 = colors.text3
            emptyText.Font = Enum.Font.Gotham
            emptyText.TextSize = 10
            emptyText.ZIndex = 2
            return
        end

        -- Convert to array
        local notifList = {}
        for notifId, notifData in pairs(notifs) do
            table.insert(notifList, {id = notifId, data = notifData})
        end

        -- Sort by timestamp (newest first)
        table.sort(notifList, function(a, b)
            return (a.data.timestamp or 0) > (b.data.timestamp or 0)
        end)

        -- Render notifications
        for i, notif in ipairs(notifList) do
            local isRead = notif.data.read == true

            local card = Instance.new("Frame", listHolder)
            card.Size = UDim2.new(1, 0, 0, 70)
            card.BackgroundColor3 = isRead and colors.card or colors.unread
            card.LayoutOrder = i
            corner(card, 14)
            stroke(card, isRead and colors.border or colors.accent2, isRead and 1 or 2, isRead and 0.3 or 0)

            -- Unread indicator
            if not isRead then
                local unreadDot = Instance.new("Frame", card)
                unreadDot.Size = UDim2.new(0, 8, 0, 8)
                unreadDot.Position = UDim2.new(0, 8, 0, 8)
                unreadDot.BackgroundColor3 = colors.accent2
                unreadDot.ZIndex = 3
                corner(unreadDot, 100)
            end

            -- Title
            local titleLbl = Instance.new("TextLabel", card)
            titleLbl.Size = UDim2.new(1, -20, 0, 20)
            titleLbl.Position = UDim2.new(0, 12, 0, 8)
            titleLbl.BackgroundTransparency = 1
            titleLbl.Text = notif.data.title or "Notification"
            titleLbl.TextColor3 = colors.text
            titleLbl.Font = Enum.Font.GothamBlack
            titleLbl.TextSize = 12
            titleLbl.TextXAlignment = Enum.TextXAlignment.Left
            titleLbl.ZIndex = 2

            -- Message
            local msgLbl = Instance.new("TextLabel", card)
            msgLbl.Size = UDim2.new(1, -20, 0, 18)
            msgLbl.Position = UDim2.new(0, 12, 0, 28)
            msgLbl.BackgroundTransparency = 1
            msgLbl.Text = notif.data.message or ""
            msgLbl.TextColor3 = colors.text2
            msgLbl.Font = Enum.Font.Gotham
            msgLbl.TextSize = 9
            msgLbl.TextXAlignment = Enum.TextXAlignment.Left
            msgLbl.TextTruncate = Enum.TextTruncate.AtEnd
            msgLbl.ZIndex = 2

            -- Footer (from + time)
            local footerLbl = Instance.new("TextLabel", card)
            footerLbl.Size = UDim2.new(1, -20, 0, 14)
            footerLbl.Position = UDim2.new(0, 12, 0, 48)
            footerLbl.BackgroundTransparency = 1
            footerLbl.Text = "From: " .. (notif.data.from or "Admin") .. " | " .. os.date("%d/%m %H:%M", notif.data.timestamp or os.time())
            footerLbl.TextColor3 = colors.text3
            footerLbl.Font = Enum.Font.Gotham
            footerLbl.TextSize = 8
            footerLbl.TextXAlignment = Enum.TextXAlignment.Left
            footerLbl.ZIndex = 2

            -- Delete button
            local deleteBtn = Instance.new("TextButton", card)
            deleteBtn.Size = UDim2.new(0, 30, 0, 30)
            deleteBtn.Position = UDim2.new(1, -38, 0.5, -15)
            deleteBtn.BackgroundColor3 = colors.cardHover
            deleteBtn.Text = "×"
            deleteBtn.TextColor3 = colors.red
            deleteBtn.Font = Enum.Font.GothamBlack
            deleteBtn.TextSize = 16
            deleteBtn.AutoButtonColor = false
            deleteBtn.ZIndex = 3
            corner(deleteBtn, 8)
            stroke(deleteBtn, colors.border, 1, 0.3)
            pressFX(deleteBtn)

            deleteBtn.MouseButton1Click:Connect(function()
                if Firebase.DeleteNotification then
                    Firebase.DeleteNotification(LocalPlayer.UserId, notif.id)
                    _G.showDynamicNotification("Notification deleted", colors.red)
                    loadNotifications()
                end
            end)
        end
    end

    -- Refresh button click
    refreshBtn.MouseButton1Click:Connect(loadNotifications)

    -- Initial load
    loadNotifications()

    -- Auto refresh every 15 seconds
    task.spawn(function()
        while listHolder.Parent do
            task.wait(15)
            loadNotifications()
        end
    end)
end

print("[NotifWeb] App loaded!")