-- ================================================
-- PLAYER LOOKUP APP - Dark Theme with Tabs
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
    cardHover = Color3.fromRGB(35, 35, 45),
    accent = Color3.fromRGB(255, 255, 255),
    accent2 = Color3.fromRGB(0, 200, 255),
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
    
    local tabPadding = Instance.new("UIPadding", tabFrame)
    tabPadding.PaddingLeft = UDim.new(0, 3)
    tabPadding.PaddingRight = UDim.new(0, 3)
    tabPadding.PaddingTop = UDim.new(0, 3)
    tabPadding.PaddingBottom = UDim.new(0, 3)
    
    local lookupSelectedTab = playerLookupData.selectedTab or "Items"
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
        playerLookupData = {username = username, selectedTab = "Items"}
        
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
            local userId = nil
            local displayName = username
            
            -- Method 1: Search API
            local searchRaw = httpGet("https://users.roblox.com/v1/users/search?keyword=" .. HttpService:UrlEncode(username) .. "&limit=10")
            if searchRaw then
                local ok, data = pcall(function() return HttpService:JSONDecode(searchRaw) end)
                if ok and data and data.data and #data.data > 0 then
                    for _, user in ipairs(data.data) do
                        if user.name:lower() == username:lower() or (user.displayName and user.displayName:lower() == username:lower()) then
                            userId = user.id
                            displayName = user.displayName or user.name
                            break
                        end
                    end
                    if not userId then
                        userId = data.data[1].id
                        displayName = data.data[1].displayName or data.data[1].name
                    end
                end
            end
            
            -- Method 2: Direct API
            if not userId then
                local userRaw = httpGet("https://api.roblox.com/users/get-by-username?username=" .. HttpService:UrlEncode(username))
                if userRaw then
                    local ok, data = pcall(function() return HttpService:JSONDecode(userRaw) end)
                    if ok and data and data.Id and data.Id > 0 then
                        userId = data.Id
                        displayName = data.Username or username
                    end
                end
            end
            
            loadingCard:Destroy()
            
            if not userId then
                local notFoundCard = Instance.new("Frame", contentFrame)
                notFoundCard.Size = UDim2.new(1, 0, 0, 90)
                notFoundCard.BackgroundColor3 = colors.card
                corner(notFoundCard, 14)
                stroke(notFoundCard, colors.border, 1, 0.3)
                
                local notFoundText = Instance.new("TextLabel", notFoundCard)
                notFoundText.Size = UDim2.new(1, 0, 1, 0)
                notFoundText.BackgroundTransparency = 1
                notFoundText.Text = "Player not found!\n@" .. username
                notFoundText.TextColor3 = colors.text3
                notFoundText.Font = Enum.Font.GothamBlack
                notFoundText.TextSize = 13
                notFoundText.TextWrapped = true
                notFoundText.TextXAlignment = Enum.TextXAlignment.Center
                return
            end
            
            playerLookupData.userId = userId
            playerLookupData.displayName = displayName
            playerLookupData.username = username
            
            _G.showDynamicNotification("Found: " .. displayName, colors.green)
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
        
        local copyBtn = Instance.new("TextButton", quickRow)
        copyBtn.Size = UDim2.new(0, 85, 1, 0)
        copyBtn.Position = UDim2.new(0, 186, 0, 0)
        copyBtn.BackgroundColor3 = colors.card2
        copyBtn.Text = "Copy ID"
        copyBtn.TextColor3 = colors.text
        copyBtn.Font = Enum.Font.GothamBold
        copyBtn.TextSize = 10
        copyBtn.AutoButtonColor = false
        corner(copyBtn, 8)
        stroke(copyBtn, colors.border, 1, 0.3)
        pressFX(copyBtn)
        copyBtn.MouseButton1Click:Connect(function()
            Helpers.copyToClipboard(tostring(userId))
            _G.showDynamicNotification("ID copied!", colors.green)
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
                                itemType = "BODY",
                                typeColor = Color3.fromRGB(255, 130, 80)
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
                local counter = Instance.new("TextLabel", contentFrame)
                counter.Size = UDim2.new(1, 0, 0, 18)
                counter.BackgroundTransparency = 1
                counter.Text = #allItems .. " items found"
                counter.TextColor3 = colors.text2
                counter.Font = Enum.Font.GothamBold
                counter.TextSize = 9
                counter.TextXAlignment = Enum.TextXAlignment.Left
                
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
                    
                    local idLbl = Instance.new("TextLabel", card)
                    idLbl.Size = UDim2.new(1, -120, 0, 14)
                    idLbl.Position = UDim2.new(0, 52, 0, 26)
                    idLbl.BackgroundTransparency = 1
                    idLbl.Text = "ID: " .. item.id
                    idLbl.TextColor3 = colors.text2
                    idLbl.Font = Enum.Font.Code
                    idLbl.TextSize = 8
                    idLbl.TextXAlignment = Enum.TextXAlignment.Left
                    
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
                    
                    local copyBtn = Instance.new("TextButton", card)
                    copyBtn.Size = UDim2.new(0, 50, 0, 22)
                    copyBtn.Position = UDim2.new(1, -114, 0.5, -11)
                    copyBtn.BackgroundColor3 = colors.card2
                    copyBtn.Text = "Copy"
                    copyBtn.TextColor3 = colors.text
                    copyBtn.Font = Enum.Font.GothamBold
                    copyBtn.TextSize = 8
                    copyBtn.AutoButtonColor = false
                    corner(copyBtn, 6)
                    pressFX(copyBtn)
                    copyBtn.MouseButton1Click:Connect(function()
                        Helpers.copyToClipboard(item.id)
                        _G.showDynamicNotification("Copied!", colors.green)
                    end)
                end
            end
        end)
    end
    
    -- ==================== RENDER OUTFITS TAB ====================
    if lookupSelectedTab == "Outfits" and playerLookupData.userId then
        local userId = playerLookupData.userId
        
        local loadingText = Instance.new("TextLabel", contentFrame)
        loadingText.Size = UDim2.new(1, 0, 0, 24)
        loadingText.BackgroundTransparency = 1
        loadingText.Text = "Loading outfits..."
        loadingText.TextColor3 = colors.text2
        loadingText.Font = Enum.Font.Gotham
        loadingText.TextSize = 10
        
        task.spawn(function()
            local allOutfits = {}
            
            local raw = httpGet("https://avatar.roblox.com/v1/users/" .. userId .. "/outfits?page=1&itemsPerPage=30")
            if raw then
                local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
                if ok and data and data.data then
                    for _, outfit in ipairs(data.data) do
                        if outfit.name and outfit.id then
                            table.insert(allOutfits, {id = outfit.id, name = outfit.name})
                        end
                    end
                end
            end
            
            loadingText:Destroy()
            
            if #allOutfits == 0 then
                local emptyText = Instance.new("TextLabel", contentFrame)
                emptyText.Size = UDim2.new(1, 0, 0, 60)
                emptyText.BackgroundTransparency = 1
                emptyText.Text = "No outfits found"
                emptyText.TextColor3 = colors.text3
                emptyText.Font = Enum.Font.GothamBold
                emptyText.TextSize = 12
                emptyText.TextXAlignment = Enum.TextXAlignment.Center
            else
                local grid = Instance.new("UIGridLayout", contentFrame)
                grid.CellSize = UDim2.new(0.5, -5, 0, 140)
                grid.CellPadding = UDim2.new(0, 8, 0, 8)
                grid.FillDirection = Enum.FillDirection.Horizontal
                grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
                grid.SortOrder = Enum.SortOrder.LayoutOrder
                
                for i, outfit in ipairs(allOutfits) do
                    local card = Instance.new("Frame", contentFrame)
                    card.Size = UDim2.new(0, 0, 0, 140)
                    card.BackgroundColor3 = colors.card
                    card.LayoutOrder = i
                    corner(card, 12)
                    stroke(card, colors.border, 1, 0.3)
                    
                    local img = Instance.new("ImageLabel", card)
                    img.Size = UDim2.new(0, 70, 0, 70)
                    img.Position = UDim2.new(0.5, -35, 0, 10)
                    img.BackgroundColor3 = colors.card2
                    img.Image = "https://www.roblox.com/outfit-thumbnail/image?userOutfitId=" .. outfit.id .. "&width=150&height=150&format=png"
                    img.ScaleType = Enum.ScaleType.Fit
                    corner(img, 8)
                    
                    local nameLbl = Instance.new("TextLabel", card)
                    nameLbl.Size = UDim2.new(1, -14, 0, 30)
                    nameLbl.Position = UDim2.new(0, 7, 0, 84)
                    nameLbl.BackgroundTransparency = 1
                    nameLbl.Text = outfit.name
                    nameLbl.TextColor3 = colors.text
                    nameLbl.Font = Enum.Font.GothamBold
                    nameLbl.TextSize = 10
                    nameLbl.TextXAlignment = Enum.TextXAlignment.Center
                    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
                    nameLbl.TextWrapped = true
                    
                    local wearBtn = Instance.new("TextButton", card)
                    wearBtn.Size = UDim2.new(0, 65, 0, 24)
                    wearBtn.Position = UDim2.new(0.5, -32, 0, 114)
                    wearBtn.BackgroundColor3 = colors.purple
                    wearBtn.Text = "Wear"
                    wearBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
                    wearBtn.Font = Enum.Font.GothamBold
                    wearBtn.TextSize = 9
                    wearBtn.AutoButtonColor = false
                    corner(wearBtn, 6)
                    pressFX(wearBtn)
                    wearBtn.MouseButton1Click:Connect(function()
                        wearBtn.Text = "..."
                        local detailRaw = httpGet("https://avatar.roblox.com/v1/outfits/" .. outfit.id .. "/details")
                        if detailRaw then
                            local ok, detail = pcall(function() return HttpService:JSONDecode(detailRaw) end)
                            if ok and detail and detail.assets then
                                local ids = {}
                                for _, asset in ipairs(detail.assets) do
                                    if asset.id then table.insert(ids, tostring(asset.id)) end
                                end
                                if #ids > 0 then
                                    fireHat(ids)
                                    _G.showDynamicNotification("Outfit applied!", colors.green)
                                end
                            end
                        end
                        task.wait(1)
                        wearBtn.Text = "Wear"
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