-- ================================================
-- PLAYERS APP - Complete Player List
-- ================================================

local Services = _G.Services
local LocalPlayer = _G.LocalPlayer
local Players = Services.Players
local T = _G.T
local Helpers = _G.Helpers
local Storage = _G.Storage
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
    online = Color3.fromRGB(0, 230, 118),
    offline = Color3.fromRGB(150, 150, 160),
}

-- ==================== OPEN PLAYERS APP ====================
function _G.openPlayersApp()
    -- ==================== SEARCH BOX ====================
    local searchFrame = Instance.new("Frame", appContent)
    searchFrame.Size = UDim2.new(1, 0, 0, 40)
    searchFrame.BackgroundColor3 = colors.card
    searchFrame.LayoutOrder = 0
    corner(searchFrame, 12)
    stroke(searchFrame, colors.border, 1, 0.3)

    -- Search icon
    local searchIcon = Instance.new("ImageLabel", searchFrame)
    searchIcon.Size = UDim2.new(0, 20, 0, 20)
    searchIcon.Position = UDim2.new(0, 10, 0.5, -10)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Image = Assets.GetIcon("search")
    searchIcon.ScaleType = Enum.ScaleType.Fit
    searchIcon.ZIndex = 2

    local searchInput = Instance.new("TextBox", searchFrame)
    searchInput.Size = UDim2.new(1, -40, 1, 0)
    searchInput.Position = UDim2.new(0, 35, 0, 0)
    searchInput.BackgroundTransparency = 1
    searchInput.PlaceholderText = "Search player..."
    searchInput.Text = ""
    searchInput.TextColor3 = colors.text
    searchInput.Font = Enum.Font.Gotham
    searchInput.TextSize = 12
    searchInput.ClearTextOnFocus = false
    searchInput.ZIndex = 2

    -- ==================== LIST HOLDER ====================
    local listHolder = Instance.new("Frame", appContent)
    listHolder.Size = UDim2.new(1, 0, 0, 0)
    listHolder.AutomaticSize = Enum.AutomaticSize.Y
    listHolder.BackgroundTransparency = 1
    listHolder.LayoutOrder = 1

    local listLayout = Instance.new("UIListLayout", listHolder)
    listLayout.Padding = UDim.new(0, 8)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- ==================== RENDER FUNCTION ====================
    local function renderList(filter)
        -- Clear
        for _, c in ipairs(listHolder:GetChildren()) do
            if not c:IsA("UIListLayout") then c:Destroy() end
        end

        filter = (filter or ""):lower()
        local playerList = Players:GetPlayers()
        local favSet = Storage.favSet or {}
        local selectedPlayer = _G.PhoneState and _G.PhoneState.selectedPlayer or nil

        -- Sort: You first, then favorites, then alphabetical
        table.sort(playerList, function(a, b)
            if a == LocalPlayer then return true end
            if b == LocalPlayer then return false end
            local af = favSet[tostring(a.UserId)] and 1 or 0
            local bf = favSet[tostring(b.UserId)] and 1 or 0
            if af ~= bf then return af > bf end
            return a.DisplayName < b.DisplayName
        end)

        local renderedCount = 0

        for i, player in ipairs(playerList) do
            local isMe = player == LocalPlayer
            local isFav = favSet[tostring(player.UserId)] == true
            local isSelected = selectedPlayer == player

            -- Filter
            local searchableText = (player.Name .. " " .. player.DisplayName):lower()
            if filter ~= "" and not searchableText:find(filter, 1, true) then
                continue
            end

            renderedCount = renderedCount + 1

            -- ==================== PLAYER ROW ====================
            local row = Instance.new("Frame", listHolder)
            row.Size = UDim2.new(1, 0, 0, 65)
            row.BackgroundColor3 = isSelected and Color3.fromRGB(235, 240, 255) or colors.card
            row.LayoutOrder = renderedCount
            corner(row, 14)
            stroke(row, isSelected and colors.accent2 or colors.border, isSelected and 2 or 1, isSelected and 0 or 0.3)

            -- Online indicator dot
            local onlineDot = Instance.new("Frame", row)
            onlineDot.Size = UDim2.new(0, 8, 0, 8)
            onlineDot.Position = UDim2.new(0, 8, 0, 8)
            onlineDot.BackgroundColor3 = isMe and colors.online or colors.offline
            onlineDot.ZIndex = 3
            corner(onlineDot, 100)

            -- Avatar
            local avatarFrame = Instance.new("Frame", row)
            avatarFrame.Size = UDim2.new(0, 45, 0, 45)
            avatarFrame.Position = UDim2.new(0, 10, 0.5, -22)
            avatarFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            avatarFrame.BackgroundTransparency = 0.5
            avatarFrame.ZIndex = 2
            corner(avatarFrame, 100)
            stroke(avatarFrame, colors.border, 1, 0.3)

            local avatarImage = Instance.new("ImageLabel", avatarFrame)
            avatarImage.Size = UDim2.new(1, -6, 1, -6)
            avatarImage.Position = UDim2.new(0, 3, 0, 3)
            avatarImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            avatarImage.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=100&height=100&format=png"
            avatarImage.ZIndex = 3
            corner(avatarImage, 100)

            -- Display name
            local displayName = Instance.new("TextLabel", row)
            displayName.Size = UDim2.new(1, -170, 0, 20)
            displayName.Position = UDim2.new(0, 65, 0, 10)
            displayName.BackgroundTransparency = 1
            displayName.Text = (isMe and "(You) " or "") .. player.DisplayName
            displayName.TextColor3 = isMe and colors.accent2 or colors.text
            displayName.Font = Enum.Font.GothamBlack
            displayName.TextSize = 13
            displayName.TextXAlignment = Enum.TextXAlignment.Left
            displayName.TextTruncate = Enum.TextTruncate.AtEnd
            displayName.ZIndex = 2

            -- Username
            local usernameLbl = Instance.new("TextLabel", row)
            usernameLbl.Size = UDim2.new(1, -170, 0, 16)
            usernameLbl.Position = UDim2.new(0, 65, 0, 32)
            usernameLbl.BackgroundTransparency = 1
            usernameLbl.Text = "@" .. player.Name
            usernameLbl.TextColor3 = colors.text2
            usernameLbl.Font = Enum.Font.Gotham
            usernameLbl.TextSize = 10
            usernameLbl.TextXAlignment = Enum.TextXAlignment.Left
            usernameLbl.ZIndex = 2

            -- User ID
            local userIdLbl = Instance.new("TextLabel", row)
            userIdLbl.Size = UDim2.new(1, -170, 0, 14)
            userIdLbl.Position = UDim2.new(0, 65, 0, 46)
            userIdLbl.BackgroundTransparency = 1
            userIdLbl.Text = "ID: " .. player.UserId
            userIdLbl.TextColor3 = colors.text3
            userIdLbl.Font = Enum.Font.Code
            userIdLbl.TextSize = 8
            userIdLbl.TextXAlignment = Enum.TextXAlignment.Left
            userIdLbl.ZIndex = 2

            -- Favorite button (bukan untuk player sendiri)
            if not isMe then
                local favBtn = Instance.new("TextButton", row)
                favBtn.Size = UDim2.new(0, 35, 0, 30)
                favBtn.Position = UDim2.new(1, -115, 0.5, -15)
                favBtn.BackgroundColor3 = isFav and colors.gold or colors.cardHover
                favBtn.Text = isFav and "★" or "☆"
                favBtn.TextColor3 = isFav and Color3.new(1, 1, 1) or colors.text2
                favBtn.Font = Enum.Font.GothamBlack
                favBtn.TextSize = 14
                favBtn.AutoButtonColor = false
                favBtn.ZIndex = 3
                corner(favBtn, 8)
                stroke(favBtn, colors.border, 1, 0.3)
                pressFX(favBtn)

                favBtn.MouseButton1Click:Connect(function()
                    local key = tostring(player.UserId)
                    if favSet[key] then
                        favSet[key] = nil
                        _G.showDynamicNotification("Removed from favorites", colors.text2)
                    else
                        favSet[key] = true
                        _G.showDynamicNotification("Added to favorites", colors.gold)
                    end
                    if Storage.persistFav then
                        Storage.persistFav()
                    end
                    renderList(searchInput.Text)
                end)
            end

            -- Select button
            local selectBtn = Instance.new("TextButton", row)
            selectBtn.Size = UDim2.new(0, 65, 0, 30)
            selectBtn.Position = UDim2.new(1, -75, 0.5, -15)
            selectBtn.BackgroundColor3 = isSelected and colors.green or colors.accent
            selectBtn.Text = isSelected and "Selected" or "Select"
            selectBtn.TextColor3 = Color3.new(1, 1, 1)
            selectBtn.Font = Enum.Font.GothamBold
            selectBtn.TextSize = 10
            selectBtn.AutoButtonColor = false
            selectBtn.ZIndex = 3
            corner(selectBtn, 8)
            pressFX(selectBtn)

            selectBtn.MouseButton1Click:Connect(function()
                if _G.PhoneState then
                    _G.PhoneState.selectedPlayer = player
                end
                _G.showDynamicNotification("Target: " .. player.DisplayName, colors.green)
                renderList(searchInput.Text)
            end)
        end

        -- Empty state
        if renderedCount == 0 then
            local empty = Instance.new("TextLabel", listHolder)
            empty.Size = UDim2.new(1, 0, 0, 60)
            empty.BackgroundTransparency = 1
            empty.Text = "No players found"
            empty.TextColor3 = colors.text3
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 12
            empty.LayoutOrder = 0
        end
    end

    -- Initial render
    renderList("")

    -- Search listener
    searchInput:GetPropertyChangedSignal("Text"):Connect(function()
        renderList(searchInput.Text)
    end)
end

print("[Players] App loaded!")