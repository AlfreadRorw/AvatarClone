-- ================================================
-- CLONE APP - Fixed Avatar API & Tab System
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

-- ==================== DARK THEME COLORS ====================
local colors = {
    card = Color3.fromRGB(25, 25, 32),
    card2 = Color3.fromRGB(30, 30, 38),
    cardHover = Color3.fromRGB(35, 35, 45),
    accent = Color3.fromRGB(255, 255, 255),
    accent2 = Color3.fromRGB(0, 200, 255),
    gold = Color3.fromRGB(255, 180, 50),
    green = Color3.fromRGB(0, 230, 118),
    red = Color3.fromRGB(255, 82, 82),
    text = Color3.fromRGB(255, 255, 255),
    text2 = Color3.fromRGB(170, 170, 180),
    text3 = Color3.fromRGB(100, 100, 115),
    border = Color3.fromRGB(45, 45, 55),
    tabActive = Color3.fromRGB(0, 200, 255),
    tabInactive = Color3.fromRGB(35, 35, 45),
}

-- ==================== LIFECYCLE MANAGER ====================
local CloneLifecycle = {
    active = false,
    tasks = {},
    currentTab = "ALL",
}

local function cleanupClone()
    CloneLifecycle.active = false
    for _, task in ipairs(CloneLifecycle.tasks) do
        pcall(function() task.cancel() end)
    end
    CloneLifecycle.tasks = {}
end

table.insert(_G.AvatarCloneCleanupTasks or {}, cleanupClone)

-- ==================== GET ITEMS - FIXED ====================
local function getItems(player)
    local items = {}
    if not player then 
        return items 
    end
    
    local userId = player.UserId
    
    -- Coba beberapa API endpoint
    local endpoints = {
        string.format("https://avatar.roblox.com/v1/users/%d/avatar", userId),
        string.format("https://avatar.roblox.com/v1/users/%d/outfits", userId),
        string.format("https://inventory.roblox.com/v1/users/%d/assets/collectibles?assetType=Hat&limit=100", userId),
    }
    
    local ok, data
    
    -- Try avatar API first
    ok, data = pcall(function()
        return HttpService:JSONDecode(HttpService:GetAsync(endpoints[1]))
    end)
    
    if ok and data then
        -- Debug print untuk melihat struktur data
        print("[Clone] Avatar API response keys:", data)
        
        -- Cek berbagai kemungkinan struktur
        if data.assets and type(data.assets) == "table" then
            for _, asset in ipairs(data.assets) do
                if asset and asset.id and type(asset.id) == "number" then
                    local assetType = "ACC"
                    local assetName = asset.name or "Item " .. asset.id
                    
                    -- Cek assetType
                    if asset.assetType then
                        local at = string.lower(asset.assetType)
                        if at:find("body") or at:find("torso") or at:find("leg") or at:find("head") then
                            assetType = "BODY"
                        elseif at:find("hat") or at:find("face") or at:find("gear") or at:find("shirt") or at:find("pants") then
                            assetType = "ACC"
                        else
                            assetType = "ACC"
                        end
                    end
                    
                    table.insert(items, {
                        Value = tostring(asset.id),
                        Label = assetName,
                        Type = assetType,
                    })
                end
            end
        end
        
        -- Cek struktur lain
        if #items == 0 and data.data and type(data.data) == "table" then
            for _, asset in ipairs(data.data) do
                if asset and asset.id and type(asset.id) == "number" then
                    table.insert(items, {
                        Value = tostring(asset.id),
                        Label = asset.name or "Item " .. asset.id,
                        Type = "ACC",
                    })
                end
            end
        end
    end
    
    -- Jika avatar API gagal, coba inventory API
    if #items == 0 then
        ok, data = pcall(function()
            return HttpService:JSONDecode(HttpService:GetAsync(endpoints[3]))
        end)
        
        if ok and data and data.data and type(data.data) == "table" then
            for _, asset in ipairs(data.data) do
                if asset and asset.assetId and type(asset.assetId) == "number" then
                    table.insert(items, {
                        Value = tostring(asset.assetId),
                        Label = asset.name or "Item " .. asset.assetId,
                        Type = "ACC",
                    })
                end
            end
        end
    end
    
    -- Debug
    print("[Clone] Found", #items, "items for", player.Name)
    
    return items
end

-- ==================== FIRE HAT REMOTE ====================
local function fireHat(ids)
    if #ids == 0 then return end
    
    local remote = ReplicatedStorage
    for _, part in ipairs(Config.REMOTE_PATH:split(".")) do
        remote = remote:FindFirstChild(part)
        if not remote then 
            print("[Clone] Remote not found:", part)
            return 
        end
    end
    
    pcall(function()
        remote:FireServer("hat", {"hat", unpack(ids)})
    end)
end

-- ==================== CLONE ITEMS ====================
local function cloneItems(items, cb)
    if not items or #items == 0 then
        if cb then cb(false, "Tidak ada item") end
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

-- ==================== BUILD ITEM ROW ====================
local function buildItemRow(parent, item, order)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, 0, 0, 52)
    row.BackgroundColor3 = colors.card2
    row.LayoutOrder = order
    corner(row, 10)
    stroke(row, colors.border, 1, 0.3)
    
    local thumb = Instance.new("ImageLabel", row)
    thumb.Size = UDim2.new(0, 42, 0, 42)
    thumb.Position = UDim2.new(0, 5, 0.5, -21)
    thumb.BackgroundColor3 = colors.card
    thumb.Image = "https://www.roblox.com/asset-thumbnail/image?assetId=" .. item.Value .. "&width=100&height=100&format=png"
    thumb.ScaleType = Enum.ScaleType.Fit
    corner(thumb, 8)
    
    local nameLbl = Instance.new("TextLabel", row)
    nameLbl.Size = UDim2.new(1, -130, 0, 18)
    nameLbl.Position = UDim2.new(0, 52, 0, 6)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = item.Label
    nameLbl.TextColor3 = colors.text
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 12
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local idLbl = Instance.new("TextLabel", row)
    idLbl.Size = UDim2.new(1, -130, 0, 16)
    idLbl.Position = UDim2.new(0, 52, 0, 24)
    idLbl.BackgroundTransparency = 1
    idLbl.Text = item.Value
    idLbl.TextColor3 = colors.green
    idLbl.Font = Enum.Font.Code
    idLbl.TextSize = 10
    idLbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local copyBtn = Instance.new("TextButton", row)
    copyBtn.Size = UDim2.new(0, 60, 0, 28)
    copyBtn.Position = UDim2.new(1, -66, 0.5, -14)
    copyBtn.BackgroundColor3 = colors.accent
    copyBtn.Text = "Copy"
    copyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    copyBtn.Font = Enum.Font.GothamBold
    copyBtn.TextSize = 10
    copyBtn.AutoButtonColor = false
    corner(copyBtn, 6)
    pressFX(copyBtn)
    
    copyBtn.MouseButton1Click:Connect(function()
        Helpers.copyToClipboard(item.Value)
        _G.showDynamicNotification("Copied: " .. item.Value, colors.green)
    end)
    
    return row
end

-- ==================== OPEN CLONE APP ====================
function _G.openCloneApp()
    cleanupClone()
    CloneLifecycle.active = true
    CloneLifecycle.currentTab = "ALL"
    
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
    
    -- Debug
    print("[Clone] Selected player:", selectedPlayer.Name, "UserId:", selectedPlayer.UserId)
    
    local allItems = getItems(selectedPlayer)
    
    if #allItems == 0 then
        local empty = Instance.new("TextLabel", appContent)
        empty.Size = UDim2.new(1, 0, 0, 80)
        empty.BackgroundTransparency = 1
        empty.Text = "No items found for " .. selectedPlayer.DisplayName .. "\n\nTry selecting another player or check if the player has wearable items."
        empty.TextColor3 = colors.text3
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 11
        empty.TextWrapped = true
        empty.LayoutOrder = 0
        return
    end
    
    -- ==================== PLAYER INFO HEADER ====================
    local playerFrame = Instance.new("Frame", appContent)
    playerFrame.Size = UDim2.new(1, 0, 0, 60)
    playerFrame.BackgroundColor3 = colors.card2
    playerFrame.LayoutOrder = 0
    corner(playerFrame, 10)
    stroke(playerFrame, colors.accent2, 1.5, 0.3)
    
    local avatar = Instance.new("ImageLabel", playerFrame)
    avatar.Size = UDim2.new(0, 44, 0, 44)
    avatar.Position = UDim2.new(0, 8, 0.5, -22)
    avatar.BackgroundColor3 = colors.card
    avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. selectedPlayer.UserId .. "&width=100&height=100&format=png"
    corner(avatar, 100)
    
    local nameLbl = Instance.new("TextLabel", playerFrame)
    nameLbl.Size = UDim2.new(1, -100, 0, 30)
    nameLbl.Position = UDim2.new(0, 56, 0, 14)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = selectedPlayer.DisplayName
    nameLbl.TextColor3 = colors.text
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 14
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local itemCountLbl = Instance.new("TextLabel", playerFrame)
    itemCountLbl.Size = UDim2.new(1, -100, 0, 20)
    itemCountLbl.Position = UDim2.new(0, 56, 0, 36)
    itemCountLbl.BackgroundTransparency = 1
    itemCountLbl.Text = #allItems .. " items total"
    itemCountLbl.TextColor3 = colors.green
    itemCountLbl.Font = Enum.Font.Gotham
    itemCountLbl.TextSize = 11
    itemCountLbl.TextXAlignment = Enum.TextXAlignment.Left
    
    -- ==================== TAB SYSTEM ====================
    local tabFrame = Instance.new("Frame", appContent)
    tabFrame.Size = UDim2.new(1, 0, 0, 40)
    tabFrame.BackgroundTransparency = 1
    tabFrame.LayoutOrder = 1
    
    local tabLayout = Instance.new("UIGridLayout", tabFrame)
    tabLayout.CellSize = UDim2.new(1/3, -4, 0, 36)
    tabLayout.CellPadding = UDim2.new(0, 6, 0, 0)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    
    local tabs = {
        {name = "All", filter = "ALL"},
        {name = "Body", filter = "BODY"},
        {name = "Accs", filter = "ACC"},
    }
    
    local tabButtons = {}
    
    for _, tab in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton", tabFrame)
        tabBtn.Size = UDim2.new(1, 0, 0, 36)
        tabBtn.BackgroundColor3 = tab.filter == "ALL" and colors.tabActive or colors.tabInactive
        tabBtn.Text = tab.name
        tabBtn.TextColor3 = tab.filter == "ALL" and Color3.fromRGB(0, 0, 0) or colors.text
        tabBtn.Font = Enum.Font.GothamBlack
        tabBtn.TextSize = 11
        tabBtn.AutoButtonColor = false
        corner(tabBtn, 8)
        pressFX(tabBtn)
        
        tabBtn.MouseButton1Click:Connect(function()
            CloneLifecycle.currentTab = tab.filter
            
            for _, btn in ipairs(tabButtons) do
                btn.BackgroundColor3 = colors.tabInactive
                btn.TextColor3 = colors.text
            end
            
            tabBtn.BackgroundColor3 = colors.tabActive
            tabBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
            
            renderFilteredItems(tab.filter)
        end)
        
        table.insert(tabButtons, tabBtn)
    end
    
    -- ==================== CLONE BUTTON ====================
    local cloneBtn = Instance.new("TextButton", appContent)
    cloneBtn.Size = UDim2.new(1, 0, 0, 46)
    cloneBtn.BackgroundColor3 = colors.accent
    cloneBtn.Text = "Clone Current Tab"
    cloneBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    cloneBtn.Font = Enum.Font.GothamBlack
    cloneBtn.TextSize = 14
    cloneBtn.AutoButtonColor = false
    cloneBtn.LayoutOrder = 2
    corner(cloneBtn, 10)
    pressFX(cloneBtn)
    
    -- ==================== ITEMS LIST ====================
    local listHolder = Instance.new("Frame", appContent)
    listHolder.Size = UDim2.new(1, 0, 0, 0)
    listHolder.AutomaticSize = Enum.AutomaticSize.Y
    listHolder.BackgroundTransparency = 1
    listHolder.LayoutOrder = 3
    
    local listLayout = Instance.new("UIListLayout", listHolder)
    listLayout.Padding = UDim.new(0, 8)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    function renderFilteredItems(filterType)
        for _, c in ipairs(listHolder:GetChildren()) do
            if not c:IsA("UIListLayout") then c:Destroy() end
        end
        
        local filteredItems = {}
        for _, item in ipairs(allItems) do
            if filterType == "ALL" then
                table.insert(filteredItems, item)
            elseif filterType == "BODY" and item.Type == "BODY" then
                table.insert(filteredItems, item)
            elseif filterType == "ACC" and item.Type == "ACC" then
                table.insert(filteredItems, item)
            end
        end
        
        if #filteredItems == 0 then
            local empty = Instance.new("TextLabel", listHolder)
            empty.Size = UDim2.new(1, 0, 0, 40)
            empty.BackgroundTransparency = 1
            empty.Text = "No items in this tab."
            empty.TextColor3 = colors.text3
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 12
            empty.LayoutOrder = 0
            return
        end
        
        for i, item in ipairs(filteredItems) do
            buildItemRow(listHolder, item, i)
        end
    end
    
    -- Clone button click
    cloneBtn.MouseButton1Click:Connect(function()
        local isCloning = _G.PhoneState and _G.PhoneState.isCloning
        if isCloning then return end
        
        local filteredItems = {}
        for _, item in ipairs(allItems) do
            if CloneLifecycle.currentTab == "ALL" then
                table.insert(filteredItems, item)
            elseif CloneLifecycle.currentTab == "BODY" and item.Type == "BODY" then
                table.insert(filteredItems, item)
            elseif CloneLifecycle.currentTab == "ACC" and item.Type == "ACC" then
                table.insert(filteredItems, item)
            end
        end
        
        if #filteredItems == 0 then
            _G.showDynamicNotification("No items to clone in this tab", colors.red)
            return
        end
        
        if _G.PhoneState then
            _G.PhoneState.isCloning = true
        end
        
        cloneBtn.Text = "Cloning..."
        cloneBtn.BackgroundColor3 = colors.gold
        
        local bar = Instance.new("Frame", appContent)
        bar.Size = UDim2.new(1, 0, 0, 8)
        bar.BackgroundColor3 = colors.card2
        bar.LayoutOrder = 4
        corner(bar, 4)
        
        local fill = Instance.new("Frame", bar)
        fill.Size = UDim2.new(0, 0, 1, 0)
        fill.BackgroundColor3 = colors.green
        corner(fill, 4)
        
        cloneItems(filteredItems, function(done, batchNum, totalBatches)
            if done then
                if _G.PhoneState then
                    _G.PhoneState.isCloning = false
                end
                cloneBtn.Text = "Clone Complete"
                tween(cloneBtn, {BackgroundColor3 = colors.green}, 0.3)
                fill:Destroy()
                _G.showDynamicNotification("Clone complete!", colors.green)
            else
                local ratio = batchNum / totalBatches
                tween(fill, {Size = UDim2.new(ratio, 0, 1, 0)}, 0.3)
                cloneBtn.Text = string.format("Cloning %d/%d", batchNum, totalBatches)
            end
        end)
    end)
    
    -- Initial render
    renderFilteredItems("ALL")
end

print("[Clone] App loaded!")