-- ================================================
-- CLONE APP - Grid 2 Kolom + Clone Per Tab + Anti Frame Drop
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
    bg = Color3.fromRGB(15, 15, 20),
    card = Color3.fromRGB(22, 22, 28),
    card2 = Color3.fromRGB(28, 28, 35),
    gridBg = Color3.fromRGB(18, 18, 24),
    accent = Color3.fromRGB(255, 255, 255),
    text = Color3.fromRGB(255, 255, 255),
    text2 = Color3.fromRGB(160, 160, 170),
    text3 = Color3.fromRGB(90, 90, 100),
    border = Color3.fromRGB(40, 40, 48),
    tabActive = Color3.fromRGB(255, 255, 255),
    tabInactive = Color3.fromRGB(28, 28, 35),
}

-- ==================== CACHE ====================
-- Cache items per player agar tidak fetch ulang
local itemCache = {}

-- ==================== LIFECYCLE ====================
local CloneLifecycle = {
    active = false,
    currentTab = "ALL",
    isCloning = false,
}

local function cleanupClone()
    CloneLifecycle.active = false
    CloneLifecycle.isCloning = false
end

table.insert(_G.AvatarCloneCleanupTasks or {}, cleanupClone)

-- ==================== HTTP REQUEST (dengan cache) ====================
local function httpGet(url)
    -- Cek cache dulu
    if itemCache[url] and (os.time() - itemCache[url].timestamp) < 60 then
        return itemCache[url].data
    end
    
    if syn and syn.request then
        local ok, result = pcall(function()
            return syn.request({Url = url, Method = "GET"})
        end)
        if ok and result and result.StatusCode == 200 and result.Body then
            itemCache[url] = {data = result.Body, timestamp = os.time()}
            return result.Body
        end
    end
    
    if http_request then
        local ok, result = pcall(function()
            return http_request({Url = url, Method = "GET"})
        end)
        if ok and result and result.StatusCode == 200 and result.Body then
            itemCache[url] = {data = result.Body, timestamp = os.time()}
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
                itemCache[url] = {data = body, timestamp = os.time()}
                return body
            end
        end
    end
    
    local ok, result = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and result and result ~= "" then
        itemCache[url] = {data = result, timestamp = os.time()}
        return result
    end
    
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

-- ==================== GET ITEMS (dengan cache) ====================
local function getItems(player)
    local items = {}
    if not player then return items end
    
    local cacheKey = "avatar_" .. player.UserId
    if itemCache[cacheKey] and (os.time() - itemCache[cacheKey].timestamp) < 60 then
        return itemCache[cacheKey].items
    end
    
    local raw = httpGet("https://avatar.roblox.com/v1/users/" .. player.UserId .. "/avatar")
    if not raw then return items end
    
    local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok or not data or not data.assets then return items end
    
    for _, asset in ipairs(data.assets) do
        if asset and asset.id then
            local assetId = tonumber(asset.id)
            if assetId and assetId > 0 then
                local assetType = "ACC"
                local typeName = ""
                if type(asset.assetType) == "table" then
                    typeName = string.lower(asset.assetType.name or "")
                elseif asset.assetType then
                    typeName = string.lower(tostring(asset.assetType))
                end
                if typeName:find("body") or typeName:find("torso") or typeName:find("leg") or typeName:find("head") or typeName:find("arm") then
                    assetType = "BODY"
                end
                
                table.insert(items, {
                    Value = tostring(assetId),
                    Label = asset.name or "Item " .. assetId,
                    Type = assetType,
                })
            end
        end
    end
    
    -- Cache hasil
    itemCache[cacheKey] = {items = items, timestamp = os.time()}
    
    return items
end

local function cloneItems(items, cb)
    if not items or #items == 0 then
        if cb then cb(false) end
        return
    end
    
    local ids = {}
    for _, item in ipairs(items) do
        table.insert(ids, item.Value)
    end
    
    local batch = Config.CLONE_BATCH_SIZE or 5
    local delay = Config.CLONE_DELAY or 6
    local total = math.ceil(#ids / batch)
    local current = 0
    
    local function nextBatch()
        if not CloneLifecycle.active then return end
        
        current = current + 1
        if current > total then
            if cb then cb(true) end
            return
        end
        
        local startIdx = (current - 1) * batch + 1
        local endIdx = math.min(current * batch, #ids)
        local batchIds = {}
        
        for i = startIdx, endIdx do
            table.insert(batchIds, ids[i])
        end
        
        fireHat(batchIds)
        
        if cb then
            cb(nil, current, total)
        end
        
        task.delay(delay, nextBatch)
    end
    
    nextBatch()
end

-- ==================== OPEN CLONE APP ====================
function _G.openCloneApp()
    cleanupClone()
    CloneLifecycle.active = true
    CloneLifecycle.currentTab = "ALL"
    CloneLifecycle.isCloning = false
    
    local selectedPlayer = _G.PhoneState and _G.PhoneState.selectedPlayer
    
    if not selectedPlayer then
        local empty = Instance.new("TextLabel", appContent)
        empty.Size = UDim2.new(1, 0, 0, 60)
        empty.BackgroundTransparency = 1
        empty.Text = "Select a player first."
        empty.TextColor3 = colors.text3
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 12
        empty.TextWrapped = true
        empty.LayoutOrder = 0
        return
    end
    
    local allItems = getItems(selectedPlayer)
    
    if #allItems == 0 then
        local empty = Instance.new("TextLabel", appContent)
        empty.Size = UDim2.new(1, 0, 0, 80)
        empty.BackgroundTransparency = 1
        empty.Text = "No items found for " .. selectedPlayer.DisplayName
        empty.TextColor3 = colors.text3
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 11
        empty.TextWrapped = true
        empty.LayoutOrder = 0
        return
    end
    
    -- ==================== PLAYER HEADER (Compact) ====================
    local playerFrame = Instance.new("Frame", appContent)
    playerFrame.Size = UDim2.new(1, 0, 0, 42)
    playerFrame.BackgroundColor3 = colors.card
    playerFrame.LayoutOrder = 0
    corner(playerFrame, 10)
    stroke(playerFrame, colors.border, 1, 0.3)
    
    local avatar = Instance.new("ImageLabel", playerFrame)
    avatar.Size = UDim2.new(0, 28, 0, 28)
    avatar.Position = UDim2.new(0, 7, 0.5, -14)
    avatar.BackgroundColor3 = colors.card2
    avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. selectedPlayer.UserId .. "&width=100&height=100&format=png"
    corner(avatar, 100)
    
    local nameLbl = Instance.new("TextLabel", playerFrame)
    nameLbl.Size = UDim2.new(1, -45, 0, 18)
    nameLbl.Position = UDim2.new(0, 40, 0, 4)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = selectedPlayer.DisplayName
    nameLbl.TextColor3 = colors.text
    nameLbl.Font = Enum.Font.GothamBlack
    nameLbl.TextSize = 10
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local countLbl = Instance.new("TextLabel", playerFrame)
    countLbl.Size = UDim2.new(1, -45, 0, 14)
    countLbl.Position = UDim2.new(0, 40, 0, 22)
    countLbl.BackgroundTransparency = 1
    countLbl.Text = #allItems .. " items"
    countLbl.TextColor3 = colors.text3
    countLbl.Font = Enum.Font.Gotham
    countLbl.TextSize = 8
    countLbl.TextXAlignment = Enum.TextXAlignment.Left
    
    -- ==================== TAB SYSTEM ====================
    local tabFrame = Instance.new("Frame", appContent)
    tabFrame.Size = UDim2.new(1, 0, 0, 34)
    tabFrame.BackgroundColor3 = colors.card
    tabFrame.LayoutOrder = 1
    corner(tabFrame, 8)
    stroke(tabFrame, colors.border, 1, 0.3)
    
    local tabLayout = Instance.new("UIGridLayout", tabFrame)
    tabLayout.CellSize = UDim2.new(1/3, -4, 0, 28)
    tabLayout.CellPadding = UDim2.new(0, 4, 0, 0)
    
    local tabs = {
        {name = "All", filter = "ALL"},
        {name = "Body", filter = "BODY"},
        {name = "Accs", filter = "ACC"},
    }
    
    local tabButtons = {}
    
    -- ==================== GRID CONTAINER (Hitam Background) ====================
    local gridContainer = Instance.new("Frame", appContent)
    gridContainer.Size = UDim2.new(1, 0, 0, 0)
    gridContainer.AutomaticSize = Enum.AutomaticSize.Y
    gridContainer.BackgroundColor3 = colors.gridBg
    gridContainer.LayoutOrder = 2
    corner(gridContainer, 10)
    stroke(gridContainer, colors.border, 1, 0.3)
    
    local gridPadding = Instance.new("UIPadding", gridContainer)
    gridPadding.PaddingLeft = UDim.new(0, 6)
    gridPadding.PaddingRight = UDim.new(0, 6)
    gridPadding.PaddingTop = UDim.new(0, 6)
    gridPadding.PaddingBottom = UDim.new(0, 6)
    
    local gridLayout = Instance.new("UIGridLayout", gridContainer)
    gridLayout.CellSize = UDim2.new(0.5, -5, 0, 145)
    gridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- ==================== RENDER GRID (Optimized) ====================
    local function getFilteredItems(filterType)
        if filterType == "ALL" then
            return allItems
        end
        
        local filtered = {}
        for _, item in ipairs(allItems) do
            if item.Type == filterType then
                table.insert(filtered, item)
            end
        end
        return filtered
    end
    
    local function renderGrid(filterType)
        -- Clear grid (hanya destroy children, bukan layout)
        for _, c in ipairs(gridContainer:GetChildren()) do
            if not c:IsA("UIGridLayout") and not c:IsA("UIPadding") then
                c:Destroy()
            end
        end
        
        local filteredItems = getFilteredItems(filterType)
        
        if #filteredItems == 0 then
            local empty = Instance.new("TextLabel", gridContainer)
            empty.Size = UDim2.new(1, 0, 0, 40)
            empty.BackgroundTransparency = 1
            empty.Text = "No items in this tab"
            empty.TextColor3 = colors.text3
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 10
            empty.TextXAlignment = Enum.TextXAlignment.Center
            empty.LayoutOrder = 0
            return
        end
        
        -- Render items (maksimal 20 untuk performa)
        local maxShow = math.min(20, #filteredItems)
        
        for i = 1, maxShow do
            local item = filteredItems[i]
            
            local card = Instance.new("Frame", gridContainer)
            card.Size = UDim2.new(0, 0, 0, 145)
            card.BackgroundColor3 = colors.card
            card.LayoutOrder = i
            corner(card, 10)
            stroke(card, colors.border, 1, 0.3)
            
            -- Thumbnail
            local imgContainer = Instance.new("Frame", card)
            imgContainer.Size = UDim2.new(0, 58, 0, 58)
            imgContainer.Position = UDim2.new(0.5, -29, 0, 7)
            imgContainer.BackgroundColor3 = colors.card2
            corner(imgContainer, 8)
            
            local thumb = Instance.new("ImageLabel", imgContainer)
            thumb.Size = UDim2.new(1, -6, 1, -6)
            thumb.Position = UDim2.new(0.5, 0, 0.5, 0)
            thumb.AnchorPoint = Vector2.new(0.5, 0.5)
            thumb.BackgroundColor3 = colors.card2
            thumb.Image = "https://www.roblox.com/asset-thumbnail/image?assetId=" .. item.Value .. "&width=120&height=120&format=png"
            thumb.ScaleType = Enum.ScaleType.Fit
            corner(thumb, 6)
            
            -- ID
            local idLabel = Instance.new("TextLabel", card)
            idLabel.Size = UDim2.new(1, -12, 0, 14)
            idLabel.Position = UDim2.new(0, 6, 0, 68)
            idLabel.BackgroundTransparency = 1
            idLabel.Text = item.Value
            idLabel.TextColor3 = colors.text3
            idLabel.Font = Enum.Font.Code
            idLabel.TextSize = 8
            idLabel.TextXAlignment = Enum.TextXAlignment.Center
            
            -- Name
            local itemName = Instance.new("TextLabel", card)
            itemName.Size = UDim2.new(1, -12, 0, 14)
            itemName.Position = UDim2.new(0, 6, 0, 83)
            itemName.BackgroundTransparency = 1
            itemName.Text = item.Label
            itemName.TextColor3 = colors.text
            itemName.Font = Enum.Font.GothamBold
            itemName.TextSize = 7
            itemName.TextXAlignment = Enum.TextXAlignment.Center
            itemName.TextTruncate = Enum.TextTruncate.AtEnd
            
            -- Type badge
            local typeBadge = Instance.new("TextLabel", card)
            typeBadge.Size = UDim2.new(0, 30, 0, 12)
            typeBadge.Position = UDim2.new(0.5, -15, 0, 99)
            typeBadge.BackgroundColor3 = colors.card2
            typeBadge.Text = item.Type
            typeBadge.TextColor3 = colors.text3
            typeBadge.Font = Enum.Font.GothamBlack
            typeBadge.TextSize = 6
            corner(typeBadge, 6)
            
            -- Buttons
            local copyBtn = Instance.new("TextButton", card)
            copyBtn.Size = UDim2.new(0, 45, 0, 20)
            copyBtn.Position = UDim2.new(0.5, -48, 0, 118)
            copyBtn.BackgroundColor3 = colors.card2
            copyBtn.Text = "Copy"
            copyBtn.TextColor3 = colors.text
            copyBtn.Font = Enum.Font.GothamBold
            copyBtn.TextSize = 7
            copyBtn.AutoButtonColor = false
            corner(copyBtn, 5)
            stroke(copyBtn, colors.border, 1, 0.3)
            pressFX(copyBtn)
            
            copyBtn.MouseButton1Click:Connect(function()
                Helpers.copyToClipboard(item.Value)
            end)
            
            local wearBtn = Instance.new("TextButton", card)
            wearBtn.Size = UDim2.new(0, 45, 0, 20)
            wearBtn.Position = UDim2.new(0.5, 3, 0, 118)
            wearBtn.BackgroundColor3 = colors.accent
            wearBtn.Text = "Wear"
            wearBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
            wearBtn.Font = Enum.Font.GothamBold
            wearBtn.TextSize = 7
            wearBtn.AutoButtonColor = false
            corner(wearBtn, 5)
            pressFX(wearBtn)
            
            wearBtn.MouseButton1Click:Connect(function()
                fireHat({item.Value})
            end)
        end
        
        -- Jika ada lebih dari 20 item
        if #filteredItems > maxShow then
            local moreLbl = Instance.new("TextLabel", gridContainer)
            moreLbl.Size = UDim2.new(1, 0, 0, 20)
            moreLbl.BackgroundTransparency = 1
            moreLbl.Text = "+" .. (#filteredItems - maxShow) .. " more items"
            moreLbl.TextColor3 = colors.text3
            moreLbl.Font = Enum.Font.Gotham
            moreLbl.TextSize = 8
            moreLbl.LayoutOrder = 999
        end
    end
    
    -- ==================== BUILD TABS ====================
    for i, tab in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton", tabFrame)
        tabBtn.Size = UDim2.new(1, 0, 0, 28)
        tabBtn.BackgroundColor3 = tab.filter == "ALL" and colors.tabActive or colors.tabInactive
        tabBtn.Text = tab.name
        tabBtn.TextColor3 = tab.filter == "ALL" and Color3.fromRGB(0, 0, 0) or colors.text2
        tabBtn.Font = Enum.Font.GothamBlack
        tabBtn.TextSize = 8
        tabBtn.AutoButtonColor = false
        corner(tabBtn, 7)
        pressFX(tabBtn)
        
        tabBtn.MouseButton1Click:Connect(function()
            CloneLifecycle.currentTab = tab.filter
            
            for _, btn in ipairs(tabButtons) do
                btn.BackgroundColor3 = colors.tabInactive
                btn.TextColor3 = colors.text2
            end
            
            tabBtn.BackgroundColor3 = colors.tabActive
            tabBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
            
            renderGrid(tab.filter)
        end)
        
        table.insert(tabButtons, tabBtn)
    end
    
    -- ==================== CLONE BUTTON (Clone per Tab) ====================
    local cloneBtn = Instance.new("TextButton", appContent)
    cloneBtn.Size = UDim2.new(1, 0, 0, 38)
    cloneBtn.BackgroundColor3 = colors.accent
    cloneBtn.Text = "Clone " .. CloneLifecycle.currentTab .. " (" .. #getFilteredItems(CloneLifecycle.currentTab) .. ")"
    cloneBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    cloneBtn.Font = Enum.Font.GothamBlack
    cloneBtn.TextSize = 11
    cloneBtn.AutoButtonColor = false
    cloneBtn.LayoutOrder = 3
    corner(cloneBtn, 10)
    pressFX(cloneBtn)
    
    -- Update clone button text saat tab berubah
    local function updateCloneBtnText()
        local filtered = getFilteredItems(CloneLifecycle.currentTab)
        cloneBtn.Text = "Clone " .. CloneLifecycle.currentTab .. " (" .. #filtered .. ")"
    end
    
    cloneBtn.MouseButton1Click:Connect(function()
        if CloneLifecycle.isCloning then return end
        
        local filteredItems = getFilteredItems(CloneLifecycle.currentTab)
        
        if #filteredItems == 0 then
            _G.showDynamicNotification("No items to clone", colors.text)
            return
        end
        
        CloneLifecycle.isCloning = true
        cloneBtn.Text = "Cloning..."
        
        cloneItems(filteredItems, function(done, batchNum, totalBatches)
            if done then
                CloneLifecycle.isCloning = false
                cloneBtn.Text = "Done!"
                _G.showDynamicNotification("Clone complete!", colors.text)
                task.wait(1.5)
                updateCloneBtnText()
            else
                cloneBtn.Text = string.format("Cloning %d/%d", batchNum, totalBatches)
            end
        end)
    end)
    
    -- Override tab click untuk update clone button text
    for _, tabBtn in ipairs(tabButtons) do
        local originalConnect = tabBtn.MouseButton1Click
        -- Update di renderGrid
    end
    
    -- Initial render
    renderGrid("ALL")
end

print("[Clone] App loaded!")