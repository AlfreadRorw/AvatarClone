-- ================================================
-- PLAYER LOOKUP APP - Fixed Tab Persistence
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

-- ==================== CLEAN DARK THEME (Hitam Putih) ====================
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
-- Simpan di _G agar tidak hilang saat refresh
_G.LookupState = _G.LookupState or {
    userId = nil,
    displayName = nil,
    username = nil,
    selectedTab = "Profile",
    items = {},
    outfits = {},
}

local lookupState = _G.LookupState

-- ==================== LIFECYCLE ====================
local LookupLifecycle = {
    active = false,
    tasks = {},
    isSearching = false,
}

local function cleanupLookup()
    LookupLifecycle.active = false
    LookupLifecycle.isSearching = false
    for _, task in ipairs(LookupLifecycle.tasks) do
        pcall(function() task.cancel() end)
    end
    LookupLifecycle.tasks = {}
end

table.insert(_G.AvatarCloneCleanupTasks or {}, cleanupLookup)

-- ==================== HTTP HELPERS ====================
local function httpGet(url)
    local ok, result = pcall(function()
        return HttpService:GetAsync(url)
    end)
    if ok and result and result ~= "" and result ~= "null" then
        return result
    end
    return nil
end

local function httpPost(url, body)
    local ok, result = pcall(function()
        return HttpService:RequestAsync({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Accept"] = "application/json",
            },
            Body = HttpService:JSONEncode(body),
        })
    end)
    
    if ok and result and result.Success then
        return result.Body
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

local function normalizeUsername(username)
    if not username then return "" end
    return username:gsub("^%s+", ""):gsub("%s+$", "")
end

-- ==================== SEARCH USER ====================
local function searchUserByUsername(username)
    local normalized = normalizeUsername(username)
    
    if normalized == "" then
        return {success = false, errorType = "empty"}
    end
    
    -- POST API
    local raw = httpPost("https://users.roblox.com/v1/usernames/users", {
        usernames = {normalized},
        excludeBannedUsers = false,
    })
    
    if not raw then
        -- Fallback GET search
        local encoded = HttpService:UrlEncode(normalized)
        raw = httpGet("https://users.roblox.com/v1/users/search?keyword=" .. encoded .. "&limit=10")
        
        if not raw then
            return {success = false, errorType = "http_error"}
        end
        
        local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
        if not ok or not data or not data.data or #data.data == 0 then
            return {success = false, errorType = "not_found"}
        end
        
        -- Cari exact match
        for _, user in ipairs(data.data) do
            if string.lower(user.name or "") == string.lower(normalized) then
                return {
                    success = true,
                    userId = user.id,
                    displayName = user.displayName or user.name,
                    username = user.name,
                }
            end
        end
        
        return {success = false, errorType = "not_found"}
    end
    
    local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok or not data or not data.data or #data.data == 0 then
        return {success = false, errorType = "not_found"}
    end
    
    local user = data.data[1]
    return {
        success = true,
        userId = user.id,
        displayName = user.displayName or user.name,
        username = user.name,
    }
end

-- ==================== OPEN LOOKUP APP ====================
function _G.openPlayerLookupApp()
    cleanupLookup()
    LookupLifecycle.active = true
    
    -- ==================== HEADER ====================
    local headerCard = Instance.new("Frame", appContent)
    headerCard.Size = UDim2.new(1, 0, 0, 40)
    headerCard.BackgroundColor3 = colors.card
    headerCard.LayoutOrder = 0
    corner(headerCard, 12)
    stroke(headerCard, colors.border, 1, 0.3)
    
    local headerTitle = Instance.new("TextLabel", headerCard)
    headerTitle.Size = UDim2.new(1, -20, 0, 22)
    headerTitle.Position = UDim2.new(0, 10, 0, 4)
    headerTitle.BackgroundTransparency = 1
    headerTitle.Text = "Player Lookup"
    headerTitle.TextColor3 = colors.text
    headerTitle.Font = Enum.Font.GothamBlack
    headerTitle.TextSize = 13
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    
    local headerSub = Instance.new("TextLabel", headerCard)
    headerSub.Size = UDim2.new(1, -20, 0, 14)
    headerSub.Position = UDim2.new(0, 10, 0, 24)
    headerSub.BackgroundTransparency = 1
    headerSub.Text = lookupState.username and ("Viewing: @" .. lookupState.username) or "Search any player"
    headerSub.TextColor3 = colors.text2
    headerSub.Font = Enum.Font.Gotham
    headerSub.TextSize = 8
    headerSub.TextXAlignment = Enum.TextXAlignment.Left
    
    -- ==================== SEARCH BAR ====================
    local searchCard = Instance.new("Frame", appContent)
    searchCard.Size = UDim2.new(1, 0, 0, 48)
    searchCard.BackgroundColor3 = colors.card
    searchCard.LayoutOrder = 1
    corner(searchCard, 12)
    stroke(searchCard, colors.border, 1, 0.3)
    
    local searchInput = Instance.new("TextBox", searchCard)
    searchInput.Size = UDim2.new(1, -90, 0, 30)
    searchInput.Position = UDim2.new(0, 8, 0, 9)
    searchInput.PlaceholderText = "Username..."
    searchInput.Text = lookupState.username or ""
    searchInput.BackgroundColor3 = colors.card2
    searchInput.TextColor3 = colors.text
    searchInput.Font = Enum.Font.Gotham
    searchInput.TextSize = 12
    searchInput.ClearTextOnFocus = false
    corner(searchInput, 8)
    stroke(searchInput, colors.border, 1, 0.3)
    
    local searchBtn = Instance.new("TextButton", searchCard)
    searchBtn.Size = UDim2.new(0, 75, 0, 30)
    searchBtn.Position = UDim2.new(1, -83, 0, 9)
    searchBtn.BackgroundColor3 = colors.accent
    searchBtn.Text = "Search"
    searchBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    searchBtn.Font = Enum.Font.GothamBlack
    searchBtn.TextSize = 11
    searchBtn.AutoButtonColor = false
    corner(searchBtn, 8)
    pressFX(searchBtn)
    
    -- ==================== TABS ====================
    local tabFrame = Instance.new("Frame", appContent)
    tabFrame.Size = UDim2.new(1, 0, 0, 36)
    tabFrame.BackgroundColor3 = colors.card
    tabFrame.LayoutOrder = 2
    corner(tabFrame, 10)
    stroke(tabFrame, colors.border, 1, 0.3)
    
    local tabLayout = Instance.new("UIGridLayout", tabFrame)
    tabLayout.CellSize = UDim2.new(1/3, -4, 0, 30)
    tabLayout.CellPadding = UDim2.new(0, 4, 0, 0)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    
    local tabs = {"Profile", "Items", "Outfits"}
    local tabButtons = {}
    
    -- ==================== CONTENT ====================
    local contentFrame = Instance.new("Frame", appContent)
    contentFrame.Size = UDim2.new(1, 0, 0, 0)
    contentFrame.AutomaticSize = Enum.AutomaticSize.Y
    contentFrame.BackgroundTransparency = 1
    contentFrame.LayoutOrder = 3
    
    local listLayout = Instance.new("UIListLayout", contentFrame)
    listLayout.Padding = UDim.new(0, 6)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- ==================== RENDER CONTENT BASED ON TAB ====================
    local function clearContent()
        for _, c in ipairs(contentFrame:GetChildren()) do
            if not c:IsA("UIListLayout") then c:Destroy() end
        end
    end
    
    local function renderProfileTab()
        clearContent()
        
        if not lookupState.userId then
            local empty = Instance.new("TextLabel", contentFrame)
            empty.Size = UDim2.new(1, 0, 0, 80)
            empty.BackgroundTransparency = 1
            empty.Text = "Search a player first"
            empty.TextColor3 = colors.text3
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 11
            empty.TextXAlignment = Enum.TextXAlignment.Center
            return
        end
        
        local userId = lookupState.userId
        local displayName = lookupState.displayName or "Unknown"
        
        -- Profile card
        local profileCard = Instance.new("Frame", contentFrame)
        profileCard.Size = UDim2.new(1, 0, 0, 85)
        profileCard.BackgroundColor3 = colors.card
        corner(profileCard, 12)
        stroke(profileCard, colors.border, 1, 0.3)
        
        local avatar = Instance.new("ImageLabel", profileCard)
        avatar.Size = UDim2.new(0, 55, 0, 55)
        avatar.Position = UDim2.new(0, 12, 0.5, -27)
        avatar.BackgroundColor3 = colors.card2
        avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. userId .. "&width=150&height=150&format=png"
        corner(avatar, 100)
        
        local nameLbl = Instance.new("TextLabel", profileCard)
        nameLbl.Size = UDim2.new(1, -80, 0, 22)
        nameLbl.Position = UDim2.new(0, 75, 0, 12)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = displayName
        nameLbl.TextColor3 = colors.text
        nameLbl.Font = Enum.Font.GothamBlack
        nameLbl.TextSize = 15
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        
        local idLbl = Instance.new("TextLabel", profileCard)
        idLbl.Size = UDim2.new(1, -80, 0, 14)
        idLbl.Position = UDim2.new(0, 75, 0, 34)
        idLbl.BackgroundTransparency = 1
        idLbl.Text = "ID: " .. userId
        idLbl.TextColor3 = colors.text2
        idLbl.Font = Enum.Font.Code
        idLbl.TextSize = 9
        idLbl.TextXAlignment = Enum.TextXAlignment.Left
        
        local isOnline = Players:GetPlayerByUserId(userId) ~= nil
        local statusLbl = Instance.new("TextLabel", profileCard)
        statusLbl.Size = UDim2.new(0, 70, 0, 14)
        statusLbl.Position = UDim2.new(0, 75, 0, 50)
        statusLbl.BackgroundTransparency = 1
        statusLbl.Text = isOnline and "IN GAME" or "OFFLINE"
        statusLbl.TextColor3 = isOnline and colors.text or colors.text3
        statusLbl.Font = Enum.Font.GothamBold
        statusLbl.TextSize = 8
        statusLbl.TextXAlignment = Enum.TextXAlignment.Left
        
        -- Action buttons
        local btnRow = Instance.new("Frame", contentFrame)
        btnRow.Size = UDim2.new(1, 0, 0, 36)
        btnRow.BackgroundTransparency = 1
        
        local targetBtn = Instance.new("TextButton", btnRow)
        targetBtn.Size = UDim2.new(0, 80, 1, 0)
        targetBtn.BackgroundColor3 = colors.accent
        targetBtn.Text = "Target"
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
                _G.showDynamicNotification("Target: " .. displayName, colors.text)
            else
                _G.showDynamicNotification("Not in server", colors.text)
            end
        end)
        
        local cloneBtn = Instance.new("TextButton", btnRow)
        cloneBtn.Size = UDim2.new(0, 80, 1, 0)
        cloneBtn.Position = UDim2.new(0, 85, 0, 0)
        cloneBtn.BackgroundColor3 = colors.accent
        cloneBtn.Text = "Clone"
        cloneBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        cloneBtn.Font = Enum.Font.GothamBold
        cloneBtn.TextSize = 10
        cloneBtn.AutoButtonColor = false
        corner(cloneBtn, 8)
        pressFX(cloneBtn)
        cloneBtn.MouseButton1Click:Connect(function()
            local raw = httpGet("https://avatar.roblox.com/v1/users/" .. userId .. "/avatar")
            if raw then
                local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
                if ok and data and data.assets then
                    local ids = {}
                    for _, asset in ipairs(data.assets) do
                        if asset and asset.id then
                            table.insert(ids, tostring(asset.id))
                        end
                    end
                    if #ids > 0 then
                        fireHat(ids)
                        _G.showDynamicNotification("Clone complete!", colors.text)
                    end
                end
            end
        end)
    end
    
    local function renderItemsTab()
        clearContent()
        
        if not lookupState.userId then
            local empty = Instance.new("TextLabel", contentFrame)
            empty.Size = UDim2.new(1, 0, 0, 80)
            empty.BackgroundTransparency = 1
            empty.Text = "Search a player first"
            empty.TextColor3 = colors.text3
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 11
            empty.TextXAlignment = Enum.TextXAlignment.Center
            return
        end
        
        local loading = Instance.new("TextLabel", contentFrame)
        loading.Size = UDim2.new(1, 0, 0, 30)
        loading.BackgroundTransparency = 1
        loading.Text = "Loading..."
        loading.TextColor3 = colors.text3
        loading.Font = Enum.Font.Gotham
        loading.TextSize = 10
        
        task.spawn(function()
            local raw = httpGet("https://avatar.roblox.com/v1/users/" .. lookupState.userId .. "/avatar")
            loading:Destroy()
            
            if not raw then
                local err = Instance.new("TextLabel", contentFrame)
                err.Size = UDim2.new(1, 0, 0, 40)
                err.BackgroundTransparency = 1
                err.Text = "Failed to load items"
                err.TextColor3 = colors.text3
                err.Font = Enum.Font.Gotham
                err.TextSize = 11
                err.TextXAlignment = Enum.TextXAlignment.Center
                return
            end
            
            local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
            if not ok or not data or not data.assets or #data.assets == 0 then
                local empty = Instance.new("TextLabel", contentFrame)
                empty.Size = UDim2.new(1, 0, 0, 40)
                empty.BackgroundTransparency = 1
                empty.Text = "No items found"
                empty.TextColor3 = colors.text3
                empty.Font = Enum.Font.Gotham
                empty.TextSize = 11
                empty.TextXAlignment = Enum.TextXAlignment.Center
                return
            end
            
            for i, asset in ipairs(data.assets) do
                if asset and asset.id then
                    local row = Instance.new("Frame", contentFrame)
                    row.Size = UDim2.new(1, 0, 0, 46)
                    row.BackgroundColor3 = colors.card2
                    corner(row, 8)
                    stroke(row, colors.border, 1, 0.3)
                    
                    local thumb = Instance.new("ImageLabel", row)
                    thumb.Size = UDim2.new(0, 34, 0, 34)
                    thumb.Position = UDim2.new(0, 6, 0.5, -17)
                    thumb.BackgroundColor3 = colors.card
                    thumb.Image = "https://www.roblox.com/asset-thumbnail/image?assetId=" .. asset.id .. "&width=100&height=100&format=png"
                    thumb.ScaleType = Enum.ScaleType.Fit
                    corner(thumb, 6)
                    
                    local nameLbl = Instance.new("TextLabel", row)
                    nameLbl.Size = UDim2.new(1, -110, 0, 16)
                    nameLbl.Position = UDim2.new(0, 46, 0, 5)
                    nameLbl.BackgroundTransparency = 1
                    nameLbl.Text = asset.name or "Item " .. asset.id
                    nameLbl.TextColor3 = colors.text
                    nameLbl.Font = Enum.Font.GothamBold
                    nameLbl.TextSize = 10
                    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
                    
                    local idLbl = Instance.new("TextLabel", row)
                    idLbl.Size = UDim2.new(1, -110, 0, 12)
                    idLbl.Position = UDim2.new(0, 46, 0, 22)
                    idLbl.BackgroundTransparency = 1
                    idLbl.Text = tostring(asset.id)
                    idLbl.TextColor3 = colors.text3
                    idLbl.Font = Enum.Font.Code
                    idLbl.TextSize = 8
                    idLbl.TextXAlignment = Enum.TextXAlignment.Left
                    
                    local wearBtn = Instance.new("TextButton", row)
                    wearBtn.Size = UDim2.new(0, 45, 0, 24)
                    wearBtn.Position = UDim2.new(1, -50, 0.5, -12)
                    wearBtn.BackgroundColor3 = colors.accent
                    wearBtn.Text = "Wear"
                    wearBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
                    wearBtn.Font = Enum.Font.GothamBold
                    wearBtn.TextSize = 8
                    wearBtn.AutoButtonColor = false
                    corner(wearBtn, 6)
                    pressFX(wearBtn)
                    wearBtn.MouseButton1Click:Connect(function()
                        fireHat({tostring(asset.id)})
                    end)
                end
            end
        end)
    end
    
    local function renderOutfitsTab()
        clearContent()
        
        if not lookupState.userId then
            local empty = Instance.new("TextLabel", contentFrame)
            empty.Size = UDim2.new(1, 0, 0, 80)
            empty.BackgroundTransparency = 1
            empty.Text = "Search a player first"
            empty.TextColor3 = colors.text3
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 11
            empty.TextXAlignment = Enum.TextXAlignment.Center
            return
        end
        
        local loading = Instance.new("TextLabel", contentFrame)
        loading.Size = UDim2.new(1, 0, 0, 30)
        loading.BackgroundTransparency = 1
        loading.Text = "Loading..."
        loading.TextColor3 = colors.text3
        loading.Font = Enum.Font.Gotham
        loading.TextSize = 10
        
        task.spawn(function()
            local raw = httpGet("https://avatar.roblox.com/v1/users/" .. lookupState.userId .. "/outfits?page=1&itemsPerPage=20")
            loading:Destroy()
            
            if not raw then
                local err = Instance.new("TextLabel", contentFrame)
                err.Size = UDim2.new(1, 0, 0, 40)
                err.BackgroundTransparency = 1
                err.Text = "No outfits found"
                err.TextColor3 = colors.text3
                err.Font = Enum.Font.Gotham
                err.TextSize = 11
                err.TextXAlignment = Enum.TextXAlignment.Center
                return
            end
            
            local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
            if not ok or not data or not data.data or #data.data == 0 then
                local empty = Instance.new("TextLabel", contentFrame)
                empty.Size = UDim2.new(1, 0, 0, 40)
                empty.BackgroundTransparency = 1
                empty.Text = "No outfits found"
                empty.TextColor3 = colors.text3
                empty.Font = Enum.Font.Gotham
                empty.TextSize = 11
                empty.TextXAlignment = Enum.TextXAlignment.Center
                return
            end
            
            for i, outfit in ipairs(data.data) do
                local row = Instance.new("Frame", contentFrame)
                row.Size = UDim2.new(1, 0, 0, 46)
                row.BackgroundColor3 = colors.card2
                corner(row, 8)
                stroke(row, colors.border, 1, 0.3)
                
                local nameLbl = Instance.new("TextLabel", row)
                nameLbl.Size = UDim2.new(1, -60, 0, 20)
                nameLbl.Position = UDim2.new(0, 10, 0.5, -10)
                nameLbl.BackgroundTransparency = 1
                nameLbl.Text = outfit.name or "Outfit " .. outfit.id
                nameLbl.TextColor3 = colors.text
                nameLbl.Font = Enum.Font.GothamBold
                nameLbl.TextSize = 11
                nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                
                local wearBtn = Instance.new("TextButton", row)
                wearBtn.Size = UDim2.new(0, 50, 0, 26)
                wearBtn.Position = UDim2.new(1, -56, 0.5, -13)
                wearBtn.BackgroundColor3 = colors.accent
                wearBtn.Text = "Wear"
                wearBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
                wearBtn.Font = Enum.Font.GothamBold
                wearBtn.TextSize = 9
                wearBtn.AutoButtonColor = false
                corner(wearBtn, 6)
                pressFX(wearBtn)
            end
        end)
    end
    
    -- ==================== TAB RENDER DISPATCHER ====================
    local function renderCurrentTab()
        if lookupState.selectedTab == "Items" then
            renderItemsTab()
        elseif lookupState.selectedTab == "Outfits" then
            renderOutfitsTab()
        else
            renderProfileTab()
        end
    end
    
    -- ==================== BUILD TABS ====================
    for i, tabName in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton", tabFrame)
        tabBtn.Size = UDim2.new(1, 0, 0, 30)
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
    
    -- ==================== SEARCH FUNCTION ====================
    local function searchPlayer(username)
        if LookupLifecycle.isSearching then return end
        
        local normalized = normalizeUsername(username)
        if normalized == "" then return end
        
        LookupLifecycle.isSearching = true
        searchBtn.Text = "..."
        
        task.spawn(function()
            local result = searchUserByUsername(normalized)
            
            LookupLifecycle.isSearching = false
            searchBtn.Text = "Search"
            
            if result.success then
                lookupState.userId = result.userId
                lookupState.displayName = result.displayName
                lookupState.username = result.username
                lookupState.selectedTab = "Profile"
                
                -- Update tab buttons
                for _, btn in ipairs(tabButtons) do
                    btn.BackgroundColor3 = colors.tabInactive
                    btn.TextColor3 = colors.text2
                end
                
                if tabButtons[1] then
                    tabButtons[1].BackgroundColor3 = colors.tabActive
                    tabButtons[1].TextColor3 = Color3.fromRGB(0, 0, 0)
                end
                
                headerSub.Text = "Viewing: @" .. result.username
                
                _G.showDynamicNotification("Found: " .. result.displayName, colors.text)
                renderCurrentTab()
            else
                clearContent()
                local notFound = Instance.new("TextLabel", contentFrame)
                notFound.Size = UDim2.new(1, 0, 0, 60)
                notFound.BackgroundTransparency = 1
                notFound.Text = "Player not found"
                notFound.TextColor3 = colors.text3
                notFound.Font = Enum.Font.Gotham
                notFound.TextSize = 11
                notFound.TextXAlignment = Enum.TextXAlignment.Center
            end
        end)
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
    
    -- ==================== INITIAL RENDER ====================
    renderCurrentTab()
end

print("[Lookup] App loaded!")