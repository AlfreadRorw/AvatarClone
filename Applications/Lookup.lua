-- ================================================
-- PLAYER LOOKUP APP - Fixed Search API
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

-- ==================== DARK THEME ====================
local colors = {
    card = Color3.fromRGB(25, 25, 32),
    card2 = Color3.fromRGB(30, 30, 38),
    accent = Color3.fromRGB(255, 255, 255),
    blue = Color3.fromRGB(80, 150, 255),
    gold = Color3.fromRGB(255, 180, 50),
    green = Color3.fromRGB(0, 230, 118),
    red = Color3.fromRGB(255, 82, 82),
    purple = Color3.fromRGB(180, 130, 255),
    text = Color3.fromRGB(255, 255, 255),
    text2 = Color3.fromRGB(170, 170, 180),
    text3 = Color3.fromRGB(100, 100, 115),
    border = Color3.fromRGB(45, 45, 55),
}

local playerLookupData = {}

-- ==================== LIFECYCLE ====================
local LookupLifecycle = {
    active = false,
    tasks = {},
}

local function cleanupLookup()
    LookupLifecycle.active = false
    for _, task in ipairs(LookupLifecycle.tasks) do
        pcall(function() task.cancel() end)
    end
    LookupLifecycle.tasks = {}
end

table.insert(_G.AvatarCloneCleanupTasks or {}, cleanupLookup)

-- ==================== HTTP HELPER ====================
local function httpGet(url)
    local ok, result = pcall(function()
        return HttpService:GetAsync(url)
    end)
    if ok and result and result ~= "" and result ~= "null" then
        return result
    end
    return nil
end

-- ==================== HELPERS ====================
local function fireHat(ids)
    if #ids == 0 then return end
    
    local remote = ReplicatedStorage
    for _, part in ipairs(Config.REMOTE_PATH:split(".")) do
        remote = remote:FindFirstChild(part)
        if not remote then return end
    end
    
    pcall(function()
        remote:FireServer("hat", {"hat", unpack(ids)})
    end)
end

local function cloneFromUserId(userId, cb)
    local raw = httpGet("https://avatar.roblox.com/v1/users/" .. userId .. "/avatar")
    if not raw then
        if cb then cb(false) end
        return
    end
    
    local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok or not data or not data.assets then
        if cb then cb(false) end
        return
    end
    
    local ids = {}
    for _, asset in ipairs(data.assets) do
        if asset and asset.id and type(asset.id) == "number" then
            table.insert(ids, tostring(asset.id))
        end
    end
    
    if #ids > 0 then
        fireHat(ids)
        if cb then cb(true) end
    else
        if cb then cb(false) end
    end
end

-- ==================== SEARCH USER - FIXED ====================
local function searchUserByUsername(username)
    print("[Lookup] Searching for:", username)
    
    -- Method 1: users.roblox.com search API (POST)
    local function tryPostSearch()
        print("[Lookup] Trying POST search API...")
        
        local ok, response = pcall(function()
            return HttpService:RequestAsync({
                Url = "https://users.roblox.com/v1/usernames/users",
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["Accept"] = "application/json"
                },
                Body = HttpService:JSONEncode({
                    usernames = {username},
                    excludeBannedUsers = true
                })
            })
        end)
        
        if not ok or not response or not response.Success then
            print("[Lookup] POST search failed")
            return nil
        end
        
        local decodeOk, data = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)
        
        if not decodeOk or not data or not data.data or #data.data == 0 then
            print("[Lookup] POST search: no results")
            return nil
        end
        
        local user = data.data[1]
        print("[Lookup] POST search found:", user.name, user.id)
        
        return {
            userId = user.id,
            displayName = user.displayName or user.name,
            username = user.name,
        }
    end
    
    -- Method 2: users.roblox.com search API (GET)
    local function tryGetSearch()
        print("[Lookup] Trying GET search API...")
        
        local encodedName = HttpService:UrlEncode(username)
        local raw = httpGet("https://users.roblox.com/v1/users/search?keyword=" .. encodedName .. "&limit=10")
        
        if not raw then
            print("[Lookup] GET search failed")
            return nil
        end
        
        local ok, data = pcall(function()
            return HttpService:JSONDecode(raw)
        end)
        
        if not ok or not data or not data.data or #data.data == 0 then
            print("[Lookup] GET search: no results")
            return nil
        end
        
        -- Cari yang paling cocok
        for _, user in ipairs(data.data) do
            if user.name:lower() == username:lower() then
                print("[Lookup] GET search exact match:", user.name, user.id)
                return {
                    userId = user.id,
                    displayName = user.displayName or user.name,
                    username = user.name,
                }
            end
        end
        
        -- Fallback ke hasil pertama
        local user = data.data[1]
        print("[Lookup] GET search first result:", user.name, user.id)
        return {
            userId = user.id,
            displayName = user.displayName or user.name,
            username = user.name,
        }
    end
    
    -- Method 3: Old API (fallback)
    local function tryOldAPI()
        print("[Lookup] Trying old API...")
        
        local encodedName = HttpService:UrlEncode(username)
        local raw = httpGet("https://api.roblox.com/users/get-by-username?username=" .. encodedName)
        
        if not raw then
            print("[Lookup] Old API failed")
            return nil
        end
        
        local ok, data = pcall(function()
            return HttpService:JSONDecode(raw)
        end)
        
        if not ok or not data or not data.Id or data.Id == 0 then
            print("[Lookup] Old API: no result")
            return nil
        end
        
        print("[Lookup] Old API found:", data.Username, data.Id)
        return {
            userId = data.Id,
            displayName = data.Username or username,
            username = data.Username or username,
        }
    end
    
    -- Try all methods
    local methods = {tryPostSearch, tryGetSearch, tryOldAPI}
    
    for _, method in ipairs(methods) do
        local result = method()
        if result and result.userId then
            return result
        end
    end
    
    print("[Lookup] All search methods failed")
    return nil
end

-- ==================== OPEN LOOKUP APP ====================
function _G.openPlayerLookupApp()
    cleanupLookup()
    LookupLifecycle.active = true
    
    -- ==================== HEADER ====================
    local headerCard = Instance.new("Frame", appContent)
    headerCard.Size = UDim2.new(1, 0, 0, 46)
    headerCard.BackgroundColor3 = colors.card
    headerCard.LayoutOrder = 0
    corner(headerCard, 14)
    stroke(headerCard, colors.border, 1, 0.3)
    
    local headerAccent = Instance.new("Frame", headerCard)
    headerAccent.Size = UDim2.new(1, 0, 0, 2)
    headerAccent.BackgroundColor3 = colors.blue
    corner(headerAccent, 1)
    
    local headerTitle = Instance.new("TextLabel", headerCard)
    headerTitle.Size = UDim2.new(1, -24, 0, 22)
    headerTitle.Position = UDim2.new(0, 12, 0, 4)
    headerTitle.BackgroundTransparency = 1
    headerTitle.Text = "Player Lookup"
    headerTitle.TextColor3 = colors.text
    headerTitle.Font = Enum.Font.GothamBlack
    headerTitle.TextSize = 14
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    
    local headerSub = Instance.new("TextLabel", headerCard)
    headerSub.Size = UDim2.new(1, -24, 0, 14)
    headerSub.Position = UDim2.new(0, 12, 0, 26)
    headerSub.BackgroundTransparency = 1
    headerSub.Text = playerLookupData.username and ("Viewing: @" .. (playerLookupData.username or "")) or "Search any player"
    headerSub.TextColor3 = colors.text2
    headerSub.Font = Enum.Font.Gotham
    headerSub.TextSize = 8
    headerSub.TextXAlignment = Enum.TextXAlignment.Left
    
    -- ==================== SEARCH BAR ====================
    local searchCard = Instance.new("Frame", appContent)
    searchCard.Size = UDim2.new(1, 0, 0, 52)
    searchCard.BackgroundColor3 = colors.card
    searchCard.LayoutOrder = 1
    corner(searchCard, 14)
    stroke(searchCard, colors.border, 1, 0.3)
    
    local searchInput = Instance.new("TextBox", searchCard)
    searchInput.Size = UDim2.new(1, -100, 0, 32)
    searchInput.Position = UDim2.new(0, 10, 0, 10)
    searchInput.PlaceholderText = "Enter Roblox username..."
    searchInput.Text = playerLookupData.username or ""
    searchInput.BackgroundColor3 = colors.card2
    searchInput.TextColor3 = colors.text
    searchInput.Font = Enum.Font.Gotham
    searchInput.TextSize = 13
    searchInput.ClearTextOnFocus = false
    corner(searchInput, 8)
    stroke(searchInput, colors.border, 1, 0.3)
    
    local searchBtn = Instance.new("TextButton", searchCard)
    searchBtn.Size = UDim2.new(0, 80, 0, 32)
    searchBtn.Position = UDim2.new(1, -90, 0, 10)
    searchBtn.BackgroundColor3 = colors.blue
    searchBtn.Text = "Search"
    searchBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    searchBtn.Font = Enum.Font.GothamBlack
    searchBtn.TextSize = 12
    searchBtn.AutoButtonColor = false
    corner(searchBtn, 8)
    pressFX(searchBtn)
    
    -- ==================== TABS ====================
    local tabFrame = Instance.new("Frame", appContent)
    tabFrame.Size = UDim2.new(1, 0, 0, 36)
    tabFrame.BackgroundColor3 = colors.card2
    tabFrame.LayoutOrder = 2
    corner(tabFrame, 18)
    stroke(tabFrame, colors.border, 1, 0.3)
    
    local lookupSelectedTab = playerLookupData.selectedTab or "Profile"
    local tabs = {"Profile", "Items", "Outfits"}
    local tabBtns = {}
    
    for i, t in ipairs(tabs) do
        local btn = Instance.new("TextButton", tabFrame)
        btn.Size = UDim2.new(1/3, -4, 1, 0)
        btn.Position = UDim2.new((i-1)/3, 2, 0, 0)
        btn.Text = t
        btn.AutoButtonColor = false
        btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        btn.BackgroundTransparency = 1
        btn.TextColor3 = colors.text3
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 8
        corner(btn, 14)
        
        if t == lookupSelectedTab then
            btn.BackgroundColor3 = colors.accent
            btn.BackgroundTransparency = 0
            btn.TextColor3 = Color3.fromRGB(0, 0, 0)
        end
        
        btn.MouseButton1Click:Connect(function()
            lookupSelectedTab = t
            playerLookupData.selectedTab = t
            for _, b in ipairs(tabBtns) do
                b.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                b.BackgroundTransparency = 1
                b.TextColor3 = colors.text3
            end
            btn.BackgroundColor3 = colors.accent
            btn.BackgroundTransparency = 0
            btn.TextColor3 = Color3.fromRGB(0, 0, 0)
            if _G.refreshCurr then
                _G.refreshCurr()
            end
        end)
        
        table.insert(tabBtns, btn)
    end
    
    -- ==================== CONTENT ====================
    local contentFrame = Instance.new("Frame", appContent)
    contentFrame.Size = UDim2.new(1, 0, 0, 0)
    contentFrame.AutomaticSize = Enum.AutomaticSize.Y
    contentFrame.BackgroundTransparency = 1
    contentFrame.LayoutOrder = 3
    
    -- ==================== SEARCH FUNCTION ====================
    local function searchPlayer(username)
        playerLookupData = {username = username, selectedTab = "Profile"}
        
        for _, child in ipairs(contentFrame:GetChildren()) do
            if not child:IsA("UIListLayout") and not child:IsA("UIGridLayout") then
                child:Destroy()
            end
        end
        
        if username == "" or not username:match("%S") then
            _G.showDynamicNotification("Enter a username!", colors.red)
            return
        end
        
        local loadingCard = Instance.new("Frame", contentFrame)
        loadingCard.Size = UDim2.new(1, 0, 0, 40)
        loadingCard.BackgroundColor3 = colors.card2
        corner(loadingCard, 10)
        
        local loadingText = Instance.new("TextLabel", loadingCard)
        loadingText.Size = UDim2.new(1, 0, 1, 0)
        loadingText.BackgroundTransparency = 1
        loadingText.Text = "Searching..."
        loadingText.TextColor3 = colors.text2
        loadingText.Font = Enum.Font.Gotham
        loadingText.TextSize = 10
        
        task.spawn(function()
            local result = searchUserByUsername(username)
            
            loadingCard:Destroy()
            
            if not result or not result.userId then
                local notFoundCard = Instance.new("Frame", contentFrame)
                notFoundCard.Size = UDim2.new(1, 0, 0, 100)
                notFoundCard.BackgroundColor3 = colors.card
                corner(notFoundCard, 14)
                stroke(notFoundCard, colors.border, 1, 0.3)
                
                local notFoundText = Instance.new("TextLabel", notFoundCard)
                notFoundText.Size = UDim2.new(1, 0, 1, 0)
                notFoundText.BackgroundTransparency = 1
                notFoundText.Text = "Player not found!\n\n@" .. username .. "\n\nTips:\n• Check spelling\n• Make sure username is correct\n• Try again in a few seconds"
                notFoundText.TextColor3 = colors.text3
                notFoundText.Font = Enum.Font.GothamBold
                notFoundText.TextSize = 12
                notFoundText.TextWrapped = true
                notFoundText.TextXAlignment = Enum.TextXAlignment.Center
                return
            end
            
            playerLookupData.userId = result.userId
            playerLookupData.displayName = result.displayName
            playerLookupData.username = result.username
            
            _G.showDynamicNotification("Found: " .. result.displayName, colors.green)
            if _G.refreshCurr then
                _G.refreshCurr()
            end
        end)
    end
    
    -- ==================== RENDER PROFILE TAB ====================
    if lookupSelectedTab == "Profile" and playerLookupData.userId then
        local userId = playerLookupData.userId
        local displayName = playerLookupData.displayName
        
        local profileCard = Instance.new("Frame", contentFrame)
        profileCard.Size = UDim2.new(1, 0, 0, 90)
        profileCard.BackgroundColor3 = colors.card
        corner(profileCard, 14)
        stroke(profileCard, colors.blue, 2, 0.3)
        
        local avatarImg = Instance.new("ImageLabel", profileCard)
        avatarImg.Size = UDim2.new(0, 64, 0, 64)
        avatarImg.Position = UDim2.new(0, 12, 0.5, -32)
        avatarImg.BackgroundColor3 = colors.card2
        avatarImg.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. userId .. "&width=150&height=150&format=png"
        corner(avatarImg, 100)
        stroke(avatarImg, colors.blue, 2, 0)
        
        local nameLbl = Instance.new("TextLabel", profileCard)
        nameLbl.Size = UDim2.new(1, -100, 0, 24)
        nameLbl.Position = UDim2.new(0, 84, 0, 10)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = displayName
        nameLbl.TextColor3 = colors.text
        nameLbl.Font = Enum.Font.GothamBlack
        nameLbl.TextSize = 17
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        
        local idLbl = Instance.new("TextLabel", profileCard)
        idLbl.Size = UDim2.new(1, -100, 0, 16)
        idLbl.Position = UDim2.new(0, 84, 0, 34)
        idLbl.BackgroundTransparency = 1
        idLbl.Text = "ID: " .. userId
        idLbl.TextColor3 = colors.text2
        idLbl.Font = Enum.Font.Code
        idLbl.TextSize = 10
        idLbl.TextXAlignment = Enum.TextXAlignment.Left
        
        local isOnline = Players:GetPlayerByUserId(userId) ~= nil
        local onlineDot = Instance.new("Frame", profileCard)
        onlineDot.Size = UDim2.new(0, 10, 0, 10)
        onlineDot.Position = UDim2.new(0, 84, 0, 54)
        onlineDot.BackgroundColor3 = isOnline and colors.green or colors.text3
        corner(onlineDot, 100)
        
        local onlineText = Instance.new("TextLabel", profileCard)
        onlineText.Size = UDim2.new(0, 60, 0, 14)
        onlineText.Position = UDim2.new(0, 98, 0, 52)
        onlineText.BackgroundTransparency = 1
        onlineText.Text = isOnline and "IN GAME" or "OFFLINE"
        onlineText.TextColor3 = isOnline and colors.green or colors.text3
        onlineText.Font = Enum.Font.GothamBold
        onlineText.TextSize = 9
        onlineText.TextXAlignment = Enum.TextXAlignment.Left
        
        -- Quick buttons
        local quickRow = Instance.new("Frame", contentFrame)
        quickRow.Size = UDim2.new(1, 0, 0, 36)
        quickRow.BackgroundTransparency = 1
        
        local targetBtn = Instance.new("TextButton", quickRow)
        targetBtn.Size = UDim2.new(0, 85, 1, 0)
        targetBtn.BackgroundColor3 = colors.blue
        targetBtn.Text = "Set Target"
        targetBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        targetBtn.Font = Enum.Font.GothamBold
        targetBtn.TextSize = 10
        targetBtn.AutoButtonColor = false
        corner(targetBtn, 8)
        pressFX(targetBtn)
        targetBtn.MouseButton1Click:Connect(function()
            if isOnline then
                if _G.PhoneState then
                    _G.PhoneState.selectedPlayer = Players:GetPlayerByUserId(userId)
                end
                _G.showDynamicNotification("Target: " .. displayName, colors.green)
            else
                _G.showDynamicNotification("Not in server!", colors.red)
            end
        end)
        
        local cloneBtn = Instance.new("TextButton", quickRow)
        cloneBtn.Size = UDim2.new(0, 85, 1, 0)
        cloneBtn.Position = UDim2.new(0, 93, 0, 0)
        cloneBtn.BackgroundColor3 = colors.green
        cloneBtn.Text = "Clone"
        cloneBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        cloneBtn.Font = Enum.Font.GothamBold
        cloneBtn.TextSize = 10
        cloneBtn.AutoButtonColor = false
        corner(cloneBtn, 8)
        pressFX(cloneBtn)
        cloneBtn.MouseButton1Click:Connect(function()
            cloneBtn.Text = "..."
            cloneFromUserId(userId, function(done)
                if done then
                    cloneBtn.Text = "Done!"
                    _G.showDynamicNotification("Clone complete!", colors.green)
                else
                    cloneBtn.Text = "Fail!"
                end
                task.wait(1.5)
                cloneBtn.Text = "Clone"
            end)
        end)
    end
    
    -- ==================== RENDER ITEMS TAB ====================
    if lookupSelectedTab == "Items" and playerLookupData.userId then
        local userId = playerLookupData.userId
        
        local loadingText = Instance.new("TextLabel", contentFrame)
        loadingText.Size = UDim2.new(1, 0, 0, 24)
        loadingText.BackgroundTransparency = 1
        loadingText.Text = "Loading items..."
        loadingText.TextColor3 = colors.text2
        loadingText.Font = Enum.Font.Gotham
        loadingText.TextSize = 10
        
        task.spawn(function()
            local allItems = {}
            
            local avatarRaw = httpGet("https://avatar.roblox.com/v1/users/" .. userId .. "/avatar")
            if avatarRaw then
                local ok, data = pcall(function() return HttpService:JSONDecode(avatarRaw) end)
                if ok and data and data.assets then
                    for _, asset in ipairs(data.assets) do
                        if asset and asset.id then
                            table.insert(allItems, {
                                id = tostring(asset.id),
                                name = asset.name or "Item " .. asset.id,
                            })
                        end
                    end
                end
            end
            
            loadingText:Destroy()
            
            if #allItems == 0 then
                local emptyText = Instance.new("TextLabel", contentFrame)
                emptyText.Size = UDim2.new(1, 0, 0, 40)
                emptyText.BackgroundTransparency = 1
                emptyText.Text = "No items found"
                emptyText.TextColor3 = colors.text3
                emptyText.Font = Enum.Font.GothamBold
                emptyText.TextSize = 12
                emptyText.TextXAlignment = Enum.TextXAlignment.Center
            else
                local listLayout = Instance.new("UIListLayout", contentFrame)
                listLayout.Padding = UDim.new(0, 6)
                listLayout.SortOrder = Enum.SortOrder.LayoutOrder
                
                for i, item in ipairs(allItems) do
                    local card = Instance.new("Frame", contentFrame)
                    card.Size = UDim2.new(1, 0, 0, 52)
                    card.BackgroundColor3 = colors.card
                    card.LayoutOrder = i
                    corner(card, 10)
                    stroke(card, colors.border, 1, 0.3)
                    
                    local img = Instance.new("ImageLabel", card)
                    img.Size = UDim2.new(0, 40, 0, 40)
                    img.Position = UDim2.new(0, 6, 0.5, -20)
                    img.BackgroundColor3 = colors.card2
                    img.Image = "https://www.roblox.com/asset-thumbnail/image?assetId=" .. item.id .. "&width=100&height=100&format=png"
                    img.ScaleType = Enum.ScaleType.Fit
                    corner(img, 8)
                    
                    local nameLbl = Instance.new("TextLabel", card)
                    nameLbl.Size = UDim2.new(1, -120, 0, 20)
                    nameLbl.Position = UDim2.new(0, 52, 0, 6)
                    nameLbl.BackgroundTransparency = 1
                    nameLbl.Text = item.name
                    nameLbl.TextColor3 = colors.text
                    nameLbl.Font = Enum.Font.GothamBold
                    nameLbl.TextSize = 11
                    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
                    
                    local wearBtn = Instance.new("TextButton", card)
                    wearBtn.Size = UDim2.new(0, 50, 0, 22)
                    wearBtn.Position = UDim2.new(1, -58, 0.5, -11)
                    wearBtn.BackgroundColor3 = colors.accent
                    wearBtn.Text = "Wear"
                    wearBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
                    wearBtn.Font = Enum.Font.GothamBold
                    wearBtn.TextSize = 8
                    wearBtn.AutoButtonColor = false
                    corner(wearBtn, 6)
                    pressFX(wearBtn)
                    wearBtn.MouseButton1Click:Connect(function()
                        fireHat({item.id})
                        _G.showDynamicNotification("Wearing " .. item.id, colors.green)
                    end)
                end
            end
        end)
    end
    
    -- ==================== NO DATA STATE ====================
    if not playerLookupData.userId then
        local emptyCard = Instance.new("Frame", contentFrame)
        emptyCard.Size = UDim2.new(1, 0, 0, 100)
        emptyCard.BackgroundColor3 = colors.card
        corner(emptyCard, 14)
        stroke(emptyCard, colors.border, 1, 0.3)
        
        local emptyText = Instance.new("TextLabel", emptyCard)
        emptyText.Size = UDim2.new(1, 0, 1, 0)
        emptyText.BackgroundTransparency = 1
        emptyText.Text = "Search a player to get started!\n\nType a Roblox username above"
        emptyText.TextColor3 = colors.text3
        emptyText.Font = Enum.Font.GothamBold
        emptyText.TextSize = 12
        emptyText.TextWrapped = true
    end
    
    -- ==================== EVENTS ====================
    searchBtn.MouseButton1Click:Connect(function()
        searchPlayer(searchInput.Text)
    end)
    
    searchInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            searchPlayer(searchInput.Text)
        end
    end)
end

print("[Lookup] App loaded!")