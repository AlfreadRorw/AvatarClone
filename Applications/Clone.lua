-- ================================================
-- CLONE APP - Clean Dark Theme dengan Tab System
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
    bg = Color3.fromRGB(15, 15, 20),
    card = Color3.fromRGB(22, 22, 28),
    card2 = Color3.fromRGB(28, 28, 35),
    accent = Color3.fromRGB(255, 255, 255),
    text = Color3.fromRGB(255, 255, 255),
    text2 = Color3.fromRGB(160, 160, 170),
    text3 = Color3.fromRGB(90, 90, 100),
    border = Color3.fromRGB(40, 40, 48),
    tabActive = Color3.fromRGB(255, 255, 255),
    tabInactive = Color3.fromRGB(28, 28, 35),
    green = Color3.fromRGB(255, 255, 255),
    red = Color3.fromRGB(255, 255, 255),
    gold = Color3.fromRGB(255, 255, 255),
}

-- ==================== LIFECYCLE ====================
local CloneLifecycle = {
    active = false,
    tasks = {},
    isFetching = false,
    currentTab = "ALL",
}

local function cleanupClone()
    CloneLifecycle.active = false
    CloneLifecycle.isFetching = false
    for _, task in ipairs(CloneLifecycle.tasks) do
        pcall(function() task.cancel() end)
    end
    CloneLifecycle.tasks = {}
end

table.insert(_G.AvatarCloneCleanupTasks or {}, cleanupClone)

-- ==================== ROBUST HTTP REQUEST ====================
local function httpGet(url)
    local ok, result = pcall(function()
        return HttpService:GetAsync(url)
    end)
    if ok and result and result ~= "" and result ~= "null" then
        return result
    end
    return nil
end

-- ==================== FIRE HAT REMOTE ====================
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

-- ==================== GET ITEMS ====================
local function getItems(player)
    local items = {}
    if not player then return items end
    
    local raw = httpGet("https://avatar.roblox.com/v1/users/" .. player.UserId .. "/avatar")
    if not raw then return items end
    
    local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok or not data or not data.assets then return items end
    
    for _, asset in ipairs(data.assets) do
        if asset and asset.id then
            local assetId = tonumber(asset.id)
            if assetId and assetId > 0 then
                local assetType = "ACC"
                local assetName = asset.name or "Item " .. assetId
                
                -- Klasifikasi sederhana
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
                    Label = assetName,
                    Type = assetType,
                })
            end
        end
    end
    
    return items
end

-- ==================== CLONE ITEMS ====================
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

-- ==================== BUILD ITEM ROW ====================
local function buildItemRow(parent, item, order)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, 0, 0, 50)
    row.BackgroundColor3 = colors.card2
    row.LayoutOrder = order
    corner(row, 10)
    stroke(row, colors.border, 1, 0.3)
    
    local thumb = Instance.new("ImageLabel", row)
    thumb.Size = UDim2.new(0, 38, 0, 38)
    thumb.Position = UDim2.new(0, 6, 0.5, -19)
    thumb.BackgroundColor3 = colors.card
    thumb.Image = "https://www.roblox.com/asset-thumbnail/image?assetId=" .. item.Value .. "&width=100&height=100&format=png"
    thumb.ScaleType = Enum.ScaleType.Fit
    corner(thumb, 8)
    
    local nameLbl = Instance.new("TextLabel", row)
    nameLbl.Size = UDim2.new(1, -140, 0, 18)
    nameLbl.Position = UDim2.new(0, 50, 0, 6)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = item.Label
    nameLbl.TextColor3 = colors.text
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 11
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    
    local idLbl = Instance.new("TextLabel", row)
    idLbl.Size = UDim2.new(1, -140, 0, 14)
    idLbl.Position = UDim2.new(0, 50, 0, 24)
    idLbl.BackgroundTransparency = 1
    idLbl.Text = item.Value
    idLbl.TextColor3 = colors.text3
    idLbl.Font = Enum.Font.Code
    idLbl.TextSize = 9
    idLbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local copyBtn = Instance.new("TextButton", row)
    copyBtn.Size = UDim2.new(0, 55, 0, 26)
    copyBtn.Position = UDim2.new(1, -61, 0.5, -13)
    copyBtn.BackgroundColor3 = colors.card
    copyBtn.Text = "Copy"
    copyBtn.TextColor3 = colors.text
    copyBtn.Font = Enum.Font.GothamBold
    copyBtn.TextSize = 9
    copyBtn.AutoButtonColor = false
    corner(copyBtn, 6)
    stroke(copyBtn, colors.border, 1, 0.3)
    pressFX(copyBtn)
    
    copyBtn.MouseButton1Click:Connect(function()
        Helpers.copyToClipboard(item.Value)
        _G.showDynamicNotification("Copied: " .. item.Value, colors.text)
    end)
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
    
    -- Fetch items
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
    
    -- ==================== PLAYER HEADER ====================
    local playerFrame = Instance.new("Frame", appContent)
    playerFrame.Size = UDim2.new(1, 0, 0, 55)
    playerFrame.BackgroundColor3 = colors.card
    playerFrame.LayoutOrder = 0
    corner(playerFrame, 10)
    stroke(playerFrame, colors.border, 1, 0.3)
    
    local avatar = Instance.new("ImageLabel", playerFrame)
    avatar.Size = UDim2.new(0, 40, 0, 40)
    avatar.Position = UDim2.new(0, 8, 0.5, -20)
    avatar.BackgroundColor3 = colors.card2
    avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. selectedPlayer.UserId .. "&width=100&height=100&format=png"
    corner(avatar, 100)
    
    local nameLbl = Instance.new("TextLabel", playerFrame)
    nameLbl.Size = UDim2.new(1, -60, 0, 24)
    nameLbl.Position = UDim2.new(0, 54, 0, 8)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = selectedPlayer.DisplayName
    nameLbl.TextColor3 = colors.text
    nameLbl.Font = Enum.Font.GothamBlack
    nameLbl.TextSize = 13
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local itemCountLbl = Instance.new("TextLabel", playerFrame)
    itemCountLbl.Size = UDim2.new(1, -60, 0, 16)
    itemCountLbl.Position = UDim2.new(0, 54, 0, 30)
    itemCountLbl.BackgroundTransparency = 1
    itemCountLbl.Text = #allItems .. " items"
    itemCountLbl.TextColor3 = colors.text2
    itemCountLbl.Font = Enum.Font.Gotham
    itemCountLbl.TextSize = 10
    itemCountLbl.TextXAlignment = Enum.TextXAlignment.Left
    
    -- ==================== TAB SYSTEM ====================
    local tabFrame = Instance.new("Frame", appContent)
    tabFrame.Size = UDim2.new(1, 0, 0, 38)
    tabFrame.BackgroundColor3 = colors.card
    tabFrame.LayoutOrder = 1
    corner(tabFrame, 10)
    stroke(tabFrame, colors.border, 1, 0.3)
    
    local tabLayout = Instance.new("UIGridLayout", tabFrame)
    tabLayout.CellSize = UDim2.new(1/3, -4, 0, 32)
    tabLayout.CellPadding = UDim2.new(0, 4, 0, 0)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    
    local tabs = {
        {name = "All", filter = "ALL"},
        {name = "Body", filter = "BODY"},
        {name = "Accs", filter = "ACC"},
    }
    
    local tabButtons = {}
    local listHolder = Instance.new("Frame", appContent)
    listHolder.Size = UDim2.new(1, 0, 0, 0)
    listHolder.AutomaticSize = Enum.AutomaticSize.Y
    listHolder.BackgroundTransparency = 1
    listHolder.LayoutOrder = 2
    
    local listLayout = Instance.new("UIListLayout", listHolder)
    listLayout.Padding = UDim.new(0, 6)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    local function renderFilteredItems(filterType)
        -- Clear list
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
            empty.TextSize = 11
            empty.LayoutOrder = 0
            return
        end
        
        for i, item in ipairs(filteredItems) do
            buildItemRow(listHolder, item, i)
        end
    end
    
    -- Build tab buttons
    for _, tab in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton", tabFrame)
        tabBtn.Size = UDim2.new(1, 0, 0, 32)
        tabBtn.BackgroundColor3 = tab.filter == "ALL" and colors.tabActive or colors.tabInactive
        tabBtn.Text = tab.name
        tabBtn.TextColor3 = tab.filter == "ALL" and Color3.fromRGB(0, 0, 0) or colors.text2
        tabBtn.Font = Enum.Font.GothamBlack
        tabBtn.TextSize = 10
        tabBtn.AutoButtonColor = false
        corner(tabBtn, 8)
        pressFX(tabBtn)
        
        tabBtn.MouseButton1Click:Connect(function()
            CloneLifecycle.currentTab = tab.filter
            
            for _, btn in ipairs(tabButtons) do
                btn.BackgroundColor3 = colors.tabInactive
                btn.TextColor3 = colors.text2
            end
            
            tabBtn.BackgroundColor3 = colors.tabActive
            tabBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
            
            renderFilteredItems(tab.filter)
        end)
        
        table.insert(tabButtons, tabBtn)
    end
    
    -- ==================== CLONE BUTTON ====================
    local cloneBtn = Instance.new("TextButton", appContent)
    cloneBtn.Size = UDim2.new(1, 0, 0, 42)
    cloneBtn.BackgroundColor3 = colors.accent
    cloneBtn.Text = "Clone Current Tab"
    cloneBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    cloneBtn.Font = Enum.Font.GothamBlack
    cloneBtn.TextSize = 12
    cloneBtn.AutoButtonColor = false
    cloneBtn.LayoutOrder = 3
    corner(cloneBtn, 10)
    pressFX(cloneBtn)
    
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
            _G.showDynamicNotification("No items to clone", colors.text)
            return
        end
        
        if _G.PhoneState then
            _G.PhoneState.isCloning = true
        end
        
        cloneBtn.Text = "Cloning..."
        
        cloneItems(filteredItems, function(done, batchNum, totalBatches)
            if done then
                if _G.PhoneState then
                    _G.PhoneState.isCloning = false
                end
                cloneBtn.Text = "Clone Complete"
                _G.showDynamicNotification("Clone complete!", colors.text)
                task.wait(1.5)
                cloneBtn.Text = "Clone Current Tab"
            else
                cloneBtn.Text = string.format("Cloning %d/%d", batchNum, totalBatches)
            end
        end)
    end)
    
    -- Initial render
    renderFilteredItems("ALL")
end

print("[Clone] App loaded!")