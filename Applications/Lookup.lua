-- ================================================
-- PLAYER LOOKUP APP - Fixed dengan Synapse Request
-- ================================================

local Services = _G.Services
local LocalPlayer = _G.LocalPlayer
local Players = Services.Players
local HttpService = Services.HttpService
local ReplicatedStorage = Services.ReplicatedStorage
local T = _G.T
local Helpers = _G.Helpers
local Config = _G.Config

local appContent = _G.appContent

local corner = Helpers.corner
local stroke = Helpers.stroke
local tween = Helpers.tween
local pressFX = Helpers.pressFX

local colors = {
    card = Color3.fromRGB(22, 22, 28),
    card2 = Color3.fromRGB(28, 28, 35),
    accent = Color3.fromRGB(255, 255, 255),
    text = Color3.fromRGB(255, 255, 255),
    text2 = Color3.fromRGB(160, 160, 170),
    text3 = Color3.fromRGB(90, 90, 100),
    border = Color3.fromRGB(40, 40, 48),
    tabActive = Color3.fromRGB(255, 255, 255),
    tabInactive = Color3.fromRGB(28, 28, 35),
}

-- ==================== PERSISTENT STATE ====================
_G.LookupState = _G.LookupState or {
    userId = nil,
    displayName = nil,
    username = nil,
    selectedTab = "Profile",
}

local lookupState = _G.LookupState

-- ==================== HTTP REQUEST - FIXED ====================
local function httpGet(url)
    print("[Lookup] GET:", url)
    
    if syn and syn.request then
        local ok, result = pcall(function()
            return syn.request({Url = url, Method = "GET"})
        end)
        if ok and result and result.StatusCode == 200 and result.Body then
            print("[Lookup] syn.request success")
            return result.Body
        end
    end
    
    if http_request then
        local ok, result = pcall(function()
            return http_request({Url = url, Method = "GET"})
        end)
        if ok and result and result.StatusCode == 200 and result.Body then
            print("[Lookup] http_request success")
            return result.Body
        end
    end
    
    if request then
        local ok, result = pcall(function()
            return request({Url = url, Method = "GET"})
        end)
        if ok and result then
            local body = result.Body or result
            if body and body ~= "" then
                print("[Lookup] request success")
                return body
            end
        end
    end
    
    local ok, result = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and result and result ~= "" then
        print("[Lookup] game:HttpGet success")
        return result
    end
    
    print("[Lookup] All HTTP methods failed")
    return nil
end

local function httpPost(url, body)
    print("[Lookup] POST:", url)
    
    local jsonBody = HttpService:JSONEncode(body)
    
    if syn and syn.request then
        local ok, result = pcall(function()
            return syn.request({
                Url = url,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = jsonBody,
            })
        end)
        if ok and result and result.StatusCode == 200 and result.Body then
            print("[Lookup] syn.request POST success")
            return result.Body
        end
    end
    
    local ok, result = pcall(function()
        return HttpService:RequestAsync({
            Url = url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = jsonBody,
        })
    end)
    if ok and result and result.Success then
        print("[Lookup] HttpService POST success")
        return result.Body
    end
    
    print("[Lookup] POST failed")
    return nil
end

local function fireHat(ids)
    if #ids == 0 then return end
    local remote = ReplicatedStorage
    for _, part in ipairs(Config.REMOTE_PATH:split(".")) do
        remote = remote:FindFirstChild(part)
        if not remote then return end
    end
    pcall(function() remote:FireServer("hat", {"hat", unpack(ids)}) end)
end

-- ==================== OPEN LOOKUP ====================
function _G.openPlayerLookupApp()
    -- Header
    local header = Instance.new("Frame", appContent)
    header.Size = UDim2.new(1, 0, 0, 38)
    header.BackgroundColor3 = colors.card
    header.LayoutOrder = 0
    corner(header, 10)
    
    local titleLbl = Instance.new("TextLabel", header)
    titleLbl.Size = UDim2.new(1, -20, 1, 0)
    titleLbl.Position = UDim2.new(0, 10, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "Player Lookup"
    titleLbl.TextColor3 = colors.text
    titleLbl.Font = Enum.Font.GothamBlack
    titleLbl.TextSize = 12
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Search bar
    local searchFrame = Instance.new("Frame", appContent)
    searchFrame.Size = UDim2.new(1, 0, 0, 46)
    searchFrame.BackgroundColor3 = colors.card
    searchFrame.LayoutOrder = 1
    corner(searchFrame, 10)
    
    local searchInput = Instance.new("TextBox", searchFrame)
    searchInput.Size = UDim2.new(1, -85, 0, 30)
    searchInput.Position = UDim2.new(0, 8, 0, 8)
    searchInput.PlaceholderText = "Username..."
    searchInput.Text = lookupState.username or ""
    searchInput.BackgroundColor3 = colors.card2
    searchInput.TextColor3 = colors.text
    searchInput.Font = Enum.Font.Gotham
    searchInput.TextSize = 12
    searchInput.ClearTextOnFocus = false
    corner(searchInput, 8)
    
    local searchBtn = Instance.new("TextButton", searchFrame)
    searchBtn.Size = UDim2.new(0, 70, 0, 30)
    searchBtn.Position = UDim2.new(1, -78, 0, 8)
    searchBtn.BackgroundColor3 = colors.accent
    searchBtn.Text = "Search"
    searchBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    searchBtn.Font = Enum.Font.GothamBlack
    searchBtn.TextSize = 10
    searchBtn.AutoButtonColor = false
    corner(searchBtn, 8)
    pressFX(searchBtn)
    
    -- Tabs
    local tabFrame = Instance.new("Frame", appContent)
    tabFrame.Size = UDim2.new(1, 0, 0, 34)
    tabFrame.BackgroundColor3 = colors.card
    tabFrame.LayoutOrder = 2
    corner(tabFrame, 10)
    
    local tabLayout = Instance.new("UIGridLayout", tabFrame)
    tabLayout.CellSize = UDim2.new(1/3, -4, 0, 28)
    tabLayout.CellPadding = UDim2.new(0, 4, 0, 0)
    
    local tabs = {"Profile", "Items", "Outfits"}
    local tabButtons = {}
    
    -- Content
    local contentFrame = Instance.new("Frame", appContent)
    contentFrame.Size = UDim2.new(1, 0, 0, 0)
    contentFrame.AutomaticSize = Enum.AutomaticSize.Y
    contentFrame.BackgroundTransparency = 1
    contentFrame.LayoutOrder = 3
    
    local listLayout = Instance.new("UIListLayout", contentFrame)
    listLayout.Padding = UDim.new(0, 6)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    local function clearContent()
        for _, c in ipairs(contentFrame:GetChildren()) do
            if not c:IsA("UIListLayout") then c:Destroy() end
        end
    end
    
    -- Render functions
    local function renderProfile()
        clearContent()
        if not lookupState.userId then
            local empty = Instance.new("TextLabel", contentFrame)
            empty.Size = UDim2.new(1, 0, 0, 60)
            empty.BackgroundTransparency = 1
            empty.Text = "Search a player first"
            empty.TextColor3 = colors.text3
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 10
            return
        end
        
        local card = Instance.new("Frame", contentFrame)
        card.Size = UDim2.new(1, 0, 0, 80)
        card.BackgroundColor3 = colors.card
        corner(card, 12)
        
        local avatar = Instance.new("ImageLabel", card)
        avatar.Size = UDim2.new(0, 55, 0, 55)
        avatar.Position = UDim2.new(0, 12, 0.5, -27)
        avatar.BackgroundColor3 = colors.card2
        avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. lookupState.userId .. "&width=150&height=150&format=png"
        corner(avatar, 100)
        
        local nameLbl = Instance.new("TextLabel", card)
        nameLbl.Size = UDim2.new(1, -80, 0, 24)
        nameLbl.Position = UDim2.new(0, 75, 0, 12)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = lookupState.displayName or "Unknown"
        nameLbl.TextColor3 = colors.text
        nameLbl.Font = Enum.Font.GothamBlack
        nameLbl.TextSize = 14
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        
        local idLbl = Instance.new("TextLabel", card)
        idLbl.Size = UDim2.new(1, -80, 0, 16)
        idLbl.Position = UDim2.new(0, 75, 0, 36)
        idLbl.BackgroundTransparency = 1
        idLbl.Text = "ID: " .. lookupState.userId
        idLbl.TextColor3 = colors.text2
        idLbl.Font = Enum.Font.Code
        idLbl.TextSize = 9
        idLbl.TextXAlignment = Enum.TextXAlignment.Left
        
        local isOnline = Players:GetPlayerByUserId(lookupState.userId) ~= nil
        local statusLbl = Instance.new("TextLabel", card)
        statusLbl.Size = UDim2.new(0, 60, 0, 14)
        statusLbl.Position = UDim2.new(0, 75, 0, 54)
        statusLbl.BackgroundTransparency = 1
        statusLbl.Text = isOnline and "IN GAME" or "OFFLINE"
        statusLbl.TextColor3 = isOnline and colors.text or colors.text3
        statusLbl.Font = Enum.Font.GothamBold
        statusLbl.TextSize = 8
        statusLbl.TextXAlignment = Enum.TextXAlignment.Left
    end
    
    local function renderItems()
        clearContent()
        if not lookupState.userId then
            local empty = Instance.new("TextLabel", contentFrame)
            empty.Size = UDim2.new(1, 0, 0, 60)
            empty.BackgroundTransparency = 1
            empty.Text = "Search a player first"
            empty.TextColor3 = colors.text3
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 10
            return
        end
        
        local raw = httpGet("https://avatar.roblox.com/v1/users/" .. lookupState.userId .. "/avatar")
        if raw then
            local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
            if ok and data and data.assets and #data.assets > 0 then
                for i, asset in ipairs(data.assets) do
                    if asset and asset.id then
                        local row = Instance.new("Frame", contentFrame)
                        row.Size = UDim2.new(1, 0, 0, 44)
                        row.BackgroundColor3 = colors.card2
                        corner(row, 8)
                        
                        local nameLbl = Instance.new("TextLabel", row)
                        nameLbl.Size = UDim2.new(1, -70, 0, 20)
                        nameLbl.Position = UDim2.new(0, 8, 0.5, -10)
                        nameLbl.BackgroundTransparency = 1
                        nameLbl.Text = asset.name or "Item " .. asset.id
                        nameLbl.TextColor3 = colors.text
                        nameLbl.Font = Enum.Font.GothamBold
                        nameLbl.TextSize = 10
                        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
                        
                        local wearBtn = Instance.new("TextButton", row)
                        wearBtn.Size = UDim2.new(0, 55, 0, 26)
                        wearBtn.Position = UDim2.new(1, -60, 0.5, -13)
                        wearBtn.BackgroundColor3 = colors.accent
                        wearBtn.Text = "Wear"
                        wearBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
                        wearBtn.Font = Enum.Font.GothamBold
                        wearBtn.TextSize = 9
                        wearBtn.AutoButtonColor = false
                        corner(wearBtn, 6)
                        pressFX(wearBtn)
                        wearBtn.MouseButton1Click:Connect(function()
                            fireHat({tostring(asset.id)})
                        end)
                    end
                end
            else
                local empty = Instance.new("TextLabel", contentFrame)
                empty.Size = UDim2.new(1, 0, 0, 40)
                empty.BackgroundTransparency = 1
                empty.Text = "No items found"
                empty.TextColor3 = colors.text3
                empty.Font = Enum.Font.Gotham
                empty.TextSize = 10
            end
        else
            local empty = Instance.new("TextLabel", contentFrame)
            empty.Size = UDim2.new(1, 0, 0, 40)
            empty.BackgroundTransparency = 1
            empty.Text = "Failed to load items"
            empty.TextColor3 = colors.text3
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 10
        end
    end
    
    local function renderOutfits()
        clearContent()
        if not lookupState.userId then
            local empty = Instance.new("TextLabel", contentFrame)
            empty.Size = UDim2.new(1, 0, 0, 60)
            empty.BackgroundTransparency = 1
            empty.Text = "Search a player first"
            empty.TextColor3 = colors.text3
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 10
            return
        end
        
        local raw = httpGet("https://avatar.roblox.com/v1/users/" .. lookupState.userId .. "/outfits?page=1&itemsPerPage=20")
        if raw then
            local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
            if ok and data and data.data and #data.data > 0 then
                for i, outfit in ipairs(data.data) do
                    local row = Instance.new("Frame", contentFrame)
                    row.Size = UDim2.new(1, 0, 0, 44)
                    row.BackgroundColor3 = colors.card2
                    corner(row, 8)
                    
                    local nameLbl = Instance.new("TextLabel", row)
                    nameLbl.Size = UDim2.new(1, -20, 1, 0)
                    nameLbl.Position = UDim2.new(0, 10, 0, 0)
                    nameLbl.BackgroundTransparency = 1
                    nameLbl.Text = outfit.name or "Outfit " .. outfit.id
                    nameLbl.TextColor3 = colors.text
                    nameLbl.Font = Enum.Font.GothamBold
                    nameLbl.TextSize = 10
                    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                end
            else
                local empty = Instance.new("TextLabel", contentFrame)
                empty.Size = UDim2.new(1, 0, 0, 40)
                empty.BackgroundTransparency = 1
                empty.Text = "No outfits found"
                empty.TextColor3 = colors.text3
                empty.Font = Enum.Font.Gotham
                empty.TextSize = 10
            end
        end
    end
    
    local function renderCurrentTab()
        if lookupState.selectedTab == "Items" then
            renderItems()
        elseif lookupState.selectedTab == "Outfits" then
            renderOutfits()
        else
            renderProfile()
        end
    end
    
    -- Build tabs
    for i, tabName in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton", tabFrame)
        tabBtn.Size = UDim2.new(1, 0, 0, 28)
        tabBtn.BackgroundColor3 = tabName == lookupState.selectedTab and colors.tabActive or colors.tabInactive
        tabBtn.Text = tabName
        tabBtn.TextColor3 = tabName == lookupState.selectedTab and Color3.fromRGB(0, 0, 0) or colors.text2
        tabBtn.Font = Enum.Font.GothamBlack
        tabBtn.TextSize = 9
        tabBtn.AutoButtonColor = false
        corner(tabBtn, 8)
        pressFX(tabBtn)
        
        tabBtn.MouseButton1Click:Connect(function()
            lookupState.selectedTab = tabName
            for _, btn in ipairs(tabButtons) do
                btn.BackgroundColor3 = colors.tabInactive
                btn.TextColor3 = colors.text2
            end
            tabBtn.BackgroundColor3 = colors.tabActive
            tabBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
            renderCurrentTab()
        end)
        
        table.insert(tabButtons, tabBtn)
    end
    
    -- Search
    searchBtn.MouseButton1Click:Connect(function()
        local username = searchInput.Text:gsub("^%s+", ""):gsub("%s+$", "")
        if username == "" then return end
        
        searchBtn.Text = "..."
        
        task.spawn(function()
            local raw = httpPost("https://users.roblox.com/v1/usernames/users", {
                usernames = {username},
                excludeBannedUsers = false,
            })
            
            searchBtn.Text = "Search"
            
            if raw then
                local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
                if ok and data and data.data and #data.data > 0 then
                    local user = data.data[1]
                    lookupState.userId = user.id
                    lookupState.displayName = user.displayName or user.name
                    lookupState.username = user.name
                    lookupState.selectedTab = "Profile"
                    
                    for _, btn in ipairs(tabButtons) do
                        btn.BackgroundColor3 = colors.tabInactive
                        btn.TextColor3 = colors.text2
                    end
                    if tabButtons[1] then
                        tabButtons[1].BackgroundColor3 = colors.tabActive
                        tabButtons[1].TextColor3 = Color3.fromRGB(0, 0, 0)
                    end
                    
                    renderCurrentTab()
                else
                    clearContent()
                    local notFound = Instance.new("TextLabel", contentFrame)
                    notFound.Size = UDim2.new(1, 0, 0, 50)
                    notFound.BackgroundTransparency = 1
                    notFound.Text = "Player not found"
                    notFound.TextColor3 = colors.text3
                    notFound.Font = Enum.Font.Gotham
                    notFound.TextSize = 10
                    notFound.TextXAlignment = Enum.TextXAlignment.Center
                end
            else
                clearContent()
                local error = Instance.new("TextLabel", contentFrame)
                error.Size = UDim2.new(1, 0, 0, 50)
                error.BackgroundTransparency = 1
                error.Text = "API request failed\nCheck console"
                error.TextColor3 = colors.text3
                error.Font = Enum.Font.Gotham
                error.TextSize = 10
                error.TextXAlignment = Enum.TextXAlignment.Center
            end
        end)
    end)
    
    searchInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            searchBtn.MouseButton1Click:Fire()
        end
    end)
    
    -- Initial render
    renderCurrentTab()
end

print("[Lookup] App loaded!")