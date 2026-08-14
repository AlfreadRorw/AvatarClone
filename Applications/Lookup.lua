-- ================================================
-- PLAYER LOOKUP APP - Fixed dengan Robust HTTP
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

-- ==================== ROBUST HTTP REQUEST ====================
local function httpRequest(options)
    local url = options.Url or options.url
    local method = options.Method or options.method or "GET"
    local headers = options.Headers or options.headers or {}
    local body = options.Body or options.body
    
    print("[Lookup] HTTP Request:", method, url)
    
    -- Method 1: syn.request
    if syn and syn.request then
        local ok, result = pcall(function()
            return syn.request({
                Url = url,
                Method = method,
                Headers = headers,
                Body = body,
            })
        end)
        
        if ok and result then
            print("[Lookup] syn.request Status:", result.StatusCode)
            return {
                success = result.StatusCode and result.StatusCode >= 200 and result.StatusCode < 300,
                statusCode = result.StatusCode,
                body = result.Body or "",
                error = result.StatusCode and result.StatusCode >= 200 and result.StatusCode < 300 and nil or ("HTTP " .. tostring(result.StatusCode)),
            }
        end
    end
    
    -- Method 2: http_request
    if http_request then
        local ok, result = pcall(function()
            return http_request({
                Url = url,
                Method = method,
                Headers = headers,
                Body = body,
            })
        end)
        
        if ok and result then
            print("[Lookup] http_request Status:", result.StatusCode)
            return {
                success = result.StatusCode and result.StatusCode >= 200 and result.StatusCode < 300,
                statusCode = result.StatusCode,
                body = result.Body or "",
                error = result.StatusCode and result.StatusCode >= 200 and result.StatusCode < 300 and nil or ("HTTP " .. tostring(result.StatusCode)),
            }
        end
    end
    
    -- Method 3: request (Fluxus style)
    if request then
        local ok, result = pcall(function()
            return request({
                Url = url,
                Method = method,
                Headers = headers,
                Body = body,
            })
        end)
        
        if ok and result then
            print("[Lookup] request Status:", result.StatusCode)
            return {
                success = result.StatusCode and result.StatusCode >= 200 and result.StatusCode < 300,
                statusCode = result.StatusCode,
                body = result.Body or "",
                error = result.StatusCode and result.StatusCode >= 200 and result.StatusCode < 300 and nil or ("HTTP " .. tostring(result.StatusCode)),
            }
        end
    end
    
    -- Method 4: HttpService:RequestAsync
    local ok, result = pcall(function()
        return HttpService:RequestAsync({
            Url = url,
            Method = method,
            Headers = headers,
            Body = body,
        })
    end)
    
    if ok and result then
        print("[Lookup] HttpService:RequestAsync Status:", result.StatusCode)
        return {
            success = result.Success,
            statusCode = result.StatusCode,
            body = result.Body or "",
            error = result.Success and nil or ("HTTP " .. tostring(result.StatusCode)),
        }
    end
    
    -- Method 5: HttpService:GetAsync (GET only)
    if method == "GET" then
        local ok2, result2 = pcall(function()
            return HttpService:GetAsync(url)
        end)
        
        if ok2 and result2 and result2 ~= "" and result2 ~= "null" then
            print("[Lookup] HttpService:GetAsync success")
            return {
                success = true,
                statusCode = 200,
                body = result2,
                error = nil,
            }
        end
    end
    
    print("[Lookup] All HTTP methods failed")
    return {
        success = false,
        statusCode = nil,
        body = "",
        error = "All HTTP methods failed",
    }
end

-- ==================== NORMALIZE USERNAME ====================
local function normalizeUsername(username)
    if not username then return "" end
    -- Trim leading/trailing whitespace
    return username:gsub("^%s+", ""):gsub("%s+$", "")
end

-- ==================== SEARCH USER BY USERNAME ====================
local function searchUserByUsername(username)
    local normalized = normalizeUsername(username)
    
    print("[Lookup] ========== SEARCHING ==========")
    print("[Lookup] Searching username:", normalized)
    
    if normalized == "" then
        return {success = false, errorType = "empty", error = "Username kosong"}
    end
    
    -- POST API untuk search
    local postBody = HttpService:JSONEncode({
        usernames = {normalized},
        excludeBannedUsers = false,
    })
    
    local result = httpRequest({
        Url = "https://users.roblox.com/v1/usernames/users",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Accept"] = "application/json",
        },
        Body = postBody,
    })
    
    if not result.success then
        print("[Lookup] HTTP ERROR:", result.error, "Status:", result.statusCode)
        return {
            success = false,
            errorType = "http_error",
            error = result.error or "HTTP request failed",
            statusCode = result.statusCode,
        }
    end
    
    print("[Lookup] HTTP status:", result.statusCode)
    print("[Lookup] Response received")
    
    -- Decode JSON
    local decodeOk, data = pcall(function()
        return HttpService:JSONDecode(result.body)
    end)
    
    if not decodeOk then
        print("[Lookup] JSON DECODE ERROR:", data)
        return {
            success = false,
            errorType = "json_error",
            error = "JSON decode error: " .. tostring(data),
        }
    end
    
    if not data or not data.data or type(data.data) ~= "table" then
        print("[Lookup] Invalid response structure")
        return {
            success = false,
            errorType = "invalid_response",
            error = "Invalid API response structure",
        }
    end
    
    print("[Lookup] Results:", #data.data)
    
    if #data.data == 0 then
        print("[Lookup] No results - user not found")
        return {
            success = false,
            errorType = "not_found",
            error = "Player not found",
        }
    end
    
    -- Cari exact match
    for _, user in ipairs(data.data) do
        local userName = user.name or ""
        local displayName = user.displayName or user.name or ""
        
        if string.lower(userName) == string.lower(normalized) 
           or string.lower(displayName) == string.lower(normalized) then
            print("[Lookup] Exact match:", userName, "| UserId:", user.id)
            return {
                success = true,
                userId = user.id,
                displayName = displayName,
                username = userName,
            }
        end
    end
    
    -- Tidak ada exact match
    print("[Lookup] No exact match found")
    return {
        success = false,
        errorType = "not_found",
        error = "Player not found",
    }
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
    local result = httpRequest({
        Url = "https://avatar.roblox.com/v1/users/" .. userId .. "/avatar",
        Method = "GET",
    })
    
    if not result.success or not result.body then
        if cb then cb(false) end
        return
    end
    
    local ok, data = pcall(function() return HttpService:JSONDecode(result.body) end)
    if not ok or not data or not data.assets then
        if cb then cb(false) end
        return
    end
    
    local ids = {}
    for _, asset in ipairs(data.assets) do
        if asset and asset.id then
            local id = tonumber(asset.id)
            if id and id > 0 then
                table.insert(ids, tostring(id))
            end
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
        if LookupLifecycle.isSearching then
            print("[Lookup] Search already in progress")
            return
        end
        
        playerLookupData = {username = normalizeUsername(username), selectedTab = "Profile"}
        
        for _, child in ipairs(contentFrame:GetChildren()) do
            if not child:IsA("UIListLayout") and not child:IsA("UIGridLayout") then
                child:Destroy()
            end
        end
        
        local normalized = normalizeUsername(username)
        
        if normalized == "" then
            _G.showDynamicNotification("Enter a username!", colors.red)
            return
        end
        
        LookupLifecycle.isSearching = true
        searchBtn.Text = "..."
        searchBtn.BackgroundColor3 = colors.gold
        
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
            local result = searchUserByUsername(normalized)
            
            LookupLifecycle.isSearching = false
            searchBtn.Text = "Search"
            searchBtn.BackgroundColor3 = colors.blue
            loadingCard:Destroy()
            
            if result.success then
                playerLookupData.userId = result.userId
                playerLookupData.displayName = result.displayName
                playerLookupData.username = result.username
                
                _G.showDynamicNotification("Found: " .. result.displayName, colors.green)
                if _G.refreshCurr then
                    _G.refreshCurr()
                end
                
            elseif result.errorType == "not_found" then
                local notFoundCard = Instance.new("Frame", contentFrame)
                notFoundCard.Size = UDim2.new(1, 0, 0, 100)
                notFoundCard.BackgroundColor3 = colors.card
                corner(notFoundCard, 14)
                stroke(notFoundCard, colors.border, 1, 0.3)
                
                local notFoundText = Instance.new("TextLabel", notFoundCard)
                notFoundText.Size = UDim2.new(1, 0, 1, 0)
                notFoundText.BackgroundTransparency = 1
                notFoundText.Text = "Player not found!\n\n@" .. normalized
                notFoundText.TextColor3 = colors.text3
                notFoundText.Font = Enum.Font.GothamBold
                notFoundText.TextSize = 13
                notFoundText.TextWrapped = true
                notFoundText.TextXAlignment = Enum.TextXAlignment.Center
                
            else
                -- HTTP/API Error
                local errorCard = Instance.new("Frame", contentFrame)
                errorCard.Size = UDim2.new(1, 0, 0, 140)
                errorCard.BackgroundColor3 = colors.card
                corner(errorCard, 14)
                stroke(errorCard, colors.red, 2, 0.3)
                
                local errorTitle = Instance.new("TextLabel", errorCard)
                errorTitle.Size = UDim2.new(1, -20, 0, 22)
                errorTitle.Position = UDim2.new(0, 10, 0, 15)
                errorTitle.BackgroundTransparency = 1
                errorTitle.Text = "Unable to contact Roblox API"
                errorTitle.TextColor3 = colors.red
                errorTitle.Font = Enum.Font.GothamBlack
                errorTitle.TextSize = 13
                errorTitle.TextXAlignment = Enum.TextXAlignment.Center
                
                local errorMsg = Instance.new("TextLabel", errorCard)
                errorMsg.Size = UDim2.new(1, -20, 0, 20)
                errorMsg.Position = UDim2.new(0, 10, 0, 40)
                errorMsg.BackgroundTransparency = 1
                errorMsg.Text = result.error or "Unknown error"
                if result.statusCode then
                    errorMsg.Text = errorMsg.Text .. "\nHTTP Status: " .. tostring(result.statusCode)
                end
                errorMsg.TextColor3 = colors.text2
                errorMsg.Font = Enum.Font.Gotham
                errorMsg.TextSize = 10
                errorMsg.TextXAlignment = Enum.TextXAlignment.Center
                errorMsg.TextWrapped = true
                
                local retryBtn = Instance.new("TextButton", errorCard)
                retryBtn.Size = UDim2.new(0, 100, 0, 32)
                retryBtn.Position = UDim2.new(0.5, -50, 0, 90)
                retryBtn.BackgroundColor3 = colors.accent
                retryBtn.Text = "Retry"
                retryBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
                retryBtn.Font = Enum.Font.GothamBlack
                retryBtn.TextSize = 11
                retryBtn.AutoButtonColor = false
                corner(retryBtn, 8)
                pressFX(retryBtn)
                
                retryBtn.MouseButton1Click:Connect(function()
                    searchPlayer(normalized)
                end)
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