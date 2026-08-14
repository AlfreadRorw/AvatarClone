-- ================================================
-- CLONE APP - Grid 2 Kolom Seperti Favorites
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
    text = Color3.fromRGB(255, 255, 255),
    text2 = Color3.fromRGB(170, 170, 180),
    text3 = Color3.fromRGB(100, 100, 115),
    border = Color3.fromRGB(45, 45, 55),
    tabActive = Color3.fromRGB(255, 255, 255),
    tabInactive = Color3.fromRGB(30, 30, 38),
}

-- ==================== LIFECYCLE ====================
local CloneLifecycle = {
    active = false,
    currentTab = "ALL",
}

local function cleanupClone()
    CloneLifecycle.active = false
end

table.insert(_G.AvatarCloneCleanupTasks or {}, cleanupClone)

-- ==================== HTTP REQUEST ====================
local function httpGet(url)
    if syn and syn.request then
        local ok, result = pcall(function()
            return syn.request({Url = url, Method = "GET"})
        end)
        if ok and result and result.StatusCode == 200 and result.Body then
            return result.Body
        end
    end
    
    if http_request then
        local ok, result = pcall(function()
            return http_request({Url = url, Method = "GET"})
        end)
        if ok and result and result.StatusCode == 200 and result.Body then
            return result.Body
        end
    end
    
    if request then
        local ok, result = pcall(function()
            return request({Url = url, Method = "GET"})
        end)
        if ok and result then
            local body = result.Body or result
            if body and body ~= "" then return body end
        end
    end
    
    local ok, result = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and result and result ~= "" then return result end
    
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
    
    -- ==================== PLAYER HEADER ====================
    local playerFrame = Instance.new("Frame", appContent)
    playerFrame.Size = UDim2.new(1, 0, 0, 46)
    playerFrame.BackgroundColor3 = colors.card
    playerFrame.LayoutOrder = 0
    corner(playerFrame, 12)
    stroke(playerFrame, colors.border, 1, 0.3)
    
    local avatar = Instance.new("ImageLabel", playerFrame)
    avatar.Size = UDim2.new(0, 32, 0, 32)
    avatar.Position = UDim2.new(0, 8, 0.5, -16)
    avatar.BackgroundColor3 = colors.card2
    avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. selectedPlayer.UserId .. "&width=100&height=100&format=png"
    corner(avatar, 100)
    
    local nameLbl = Instance.new("TextLabel", playerFrame)
    nameLbl.Size = UDim2.new(1, -50, 0, 20)
    nameLbl.Position = UDim2.new(0, 44, 0, 5)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = selectedPlayer.DisplayName
    nameLbl.TextColor3 = colors.text
    nameLbl.Font = Enum.Font.GothamBlack
    nameLbl.TextSize = 11
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local countLbl = Instance.new("TextLabel", playerFrame)
    countLbl.Size = UDim2.new(1, -50, 0, 14)
    countLbl.Position = UDim2.new(0, 44, 0, 26)
    countLbl.BackgroundTransparency = 1
    countLbl.Text = #allItems .. " items"
    countLbl.TextColor3 = colors.text3
    countLbl.Font = Enum.Font.Gotham
    countLbl.TextSize = 8
    countLbl.TextXAlignment = Enum.TextXAlignment.Left
    
    -- ==================== TAB SYSTEM ====================
    local tabFrame = Instance.new("Frame", appContent)
    tabFrame.Size = UDim2.new(1, 0, 0, 36)
    tabFrame.BackgroundColor3 = colors.card
    tabFrame.LayoutOrder = 1
    corner(tabFrame, 10)
    stroke(tabFrame, colors.border, 1, 0.3)
    
    local tabLayout = Instance.new("UIGridLayout", tabFrame)
    tabLayout.CellSize = UDim2.new(1/3, -4, 0, 30)
    tabLayout.CellPadding = UDim2.new(0, 4, 0, 0)
    
    local tabs = {
        {name = "All", filter = "ALL"},
        {name = "Body", filter = "BODY"},
        {name = "Accs", filter = "ACC"},
    }
    
    local tabButtons = {}
    
    -- ==================== GRID HOLDER ====================
    local gridHolder = Instance.new("Frame", appContent)
    gridHolder.Size = UDim2.new(1, 0, 0, 0)
    gridHolder.AutomaticSize = Enum.AutomaticSize.Y
    gridHolder.BackgroundTransparency = 1
    gridHolder.LayoutOrder = 2
    
    local gridLayout = Instance.new("UIGridLayout", gridHolder)
    gridLayout.CellSize = UDim2.new(0.5, -6, 0, 155)
    gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- ==================== RENDER GRID ====================
    local function renderGrid(filterType)
        -- Clear grid
        for _, c in ipairs(gridHolder:GetChildren()) do
            if not c:IsA("UIGridLayout") then c:Destroy() end
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
            local empty = Instance.new("TextLabel", gridHolder)
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
        
        for i, item in ipairs(filteredItems) do
            local card = Instance.new("Frame", gridHolder)
            card.Size = UDim2.new(0, 0, 0, 155)
            card.BackgroundColor3 = colors.card
            card.LayoutOrder = i
            corner(card, 12)
            stroke(card, colors.border, 1, 0.3)
            
            -- Thumbnail
            local imgContainer = Instance.new("Frame", card)
            imgContainer.Size = UDim2.new(0, 65, 0, 65)
            imgContainer.Position = UDim2.new(0.5, -32, 0, 8)
            imgContainer.BackgroundColor3 = colors.card2
            corner(imgContainer, 10)
            stroke(imgContainer, colors.border, 1, 0.3)
            
            local thumb = Instance.new("ImageLabel", imgContainer)
            thumb.Size = UDim2.new(1, -8, 1, -8)
            thumb.Position = UDim2.new(0.5, 0, 0.5, 0)
            thumb.AnchorPoint = Vector2.new(0.5, 0.5)
            thumb.BackgroundColor3 = colors.card2
            thumb.Image = "https://www.roblox.com/asset-thumbnail/image?assetId=" .. item.Value .. "&width=150&height=150&format=png"
            thumb.ScaleType = Enum.ScaleType.Fit
            corner(thumb, 7)
            
            -- ID
            local idContainer = Instance.new("Frame", card)
            idContainer.Size = UDim2.new(1, -14, 0, 16)
            idContainer.Position = UDim2.new(0, 7, 0, 78)
            idContainer.BackgroundColor3 = colors.card2
            corner(idContainer, 5)
            
            local idLabel = Instance.new("TextLabel", idContainer)
            idLabel.Size = UDim2.new(1, 0, 1, 0)
            idLabel.BackgroundTransparency = 1
            idLabel.Text = item.Value
            idLabel.TextColor3 = colors.text2
            idLabel.Font = Enum.Font.Code
            idLabel.TextSize = 8
            idLabel.TextXAlignment = Enum.TextXAlignment.Center
            
            -- Name
            local itemName = Instance.new("TextLabel", card)
            itemName.Size = UDim2.new(1, -14, 0, 14)
            itemName.Position = UDim2.new(0, 7, 0, 96)
            itemName.BackgroundTransparency = 1
            itemName.Text = item.Label
            itemName.TextColor3 = colors.text
            itemName.Font = Enum.Font.GothamBold
            itemName.TextSize = 8
            itemName.TextXAlignment = Enum.TextXAlignment.Center
            itemName.TextTruncate = Enum.TextTruncate.AtEnd
            
            -- Type badge
            local typeBadge = Instance.new("TextLabel", card)
            typeBadge.Size = UDim2.new(0, 32, 0, 12)
            typeBadge.Position = UDim2.new(0.5, -16, 0, 112)
            typeBadge.BackgroundColor3 = colors.card2
            typeBadge.Text = item.Type
            typeBadge.TextColor3 = colors.text3
            typeBadge.Font = Enum.Font.GothamBlack
            typeBadge.TextSize = 6
            corner(typeBadge, 6)
            stroke(typeBadge, colors.border, 1, 0.3)
            
            -- Copy button
            local copyBtn = Instance.new("TextButton", card)
            copyBtn.Size = UDim2.new(0, 50, 0, 20)
            copyBtn.Position = UDim2.new(0.5, -53, 0, 128)
            copyBtn.BackgroundColor3 = colors.card2
            copyBtn.Text = "Copy"
            copyBtn.TextColor3 = colors.text
            copyBtn.Font = Enum.Font.GothamBold
            copyBtn.TextSize = 8
            copyBtn.AutoButtonColor = false
            corner(copyBtn, 6)
            stroke(copyBtn, colors.border, 1, 0.3)
            pressFX(copyBtn)
            
            copyBtn.MouseButton1Click:Connect(function()
                Helpers.copyToClipboard(item.Value)
                _G.showDynamicNotification("Copied: " .. item.Value, colors.text)
            end)
            
            -- Wear button
            local wearBtn = Instance.new("TextButton", card)
            wearBtn.Size = UDim2.new(0, 50, 0, 20)
            wearBtn.Position = UDim2.new(0.5, 3, 0, 128)
            wearBtn.BackgroundColor3 = colors.accent
            wearBtn.Text = "Wear"
            wearBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
            wearBtn.Font = Enum.Font.GothamBold
            wearBtn.TextSize = 8
            wearBtn.AutoButtonColor = false
            corner(wearBtn, 6)
            pressFX(wearBtn)
            
            wearBtn.MouseButton1Click:Connect(function()
                fireHat({item.Value})
                _G.showDynamicNotification("Wearing " .. item.Value, colors.text)
            end)
        end
    end
    
    -- ==================== BUILD TABS ====================
    for i, tab in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton", tabFrame)
        tabBtn.Size = UDim2.new(1, 0, 0, 30)
        tabBtn.BackgroundColor3 = tab.filter == "ALL" and colors.tabActive or colors.tabInactive
        tabBtn.Text = tab.name
        tabBtn.TextColor3 = tab.filter == "ALL" and Color3.fromRGB(0, 0, 0) or colors.text2
        tabBtn.Font = Enum.Font.GothamBlack
        tabBtn.TextSize = 9
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
            
            renderGrid(tab.filter)
        end)
        
        table.insert(tabButtons, tabBtn)
    end
    
    -- ==================== CLONE ALL BUTTON ====================
    local cloneBtn = Instance.new("TextButton", appContent)
    cloneBtn.Size = UDim2.new(1, 0, 0, 40)
    cloneBtn.BackgroundColor3 = colors.accent
    cloneBtn.Text = "Clone All Items (" .. #allItems .. ")"
    cloneBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    cloneBtn.Font = Enum.Font.GothamBlack
    cloneBtn.TextSize = 12
    cloneBtn.AutoButtonColor = false
    cloneBtn.LayoutOrder = 3
    corner(cloneBtn, 10)
    pressFX(cloneBtn)
    
    cloneBtn.MouseButton1Click:Connect(function()
        if _G.PhoneState and _G.PhoneState.isCloning then return end
        
        if _G.PhoneState then
            _G.PhoneState.isCloning = true
        end
        
        cloneBtn.Text = "Cloning..."
        
        cloneItems(allItems, function(done, batchNum, totalBatches)
            if done then
                if _G.PhoneState then
                    _G.PhoneState.isCloning = false
                end
                cloneBtn.Text = "Clone Complete!"
                _G.showDynamicNotification("Clone complete! (" .. #allItems .. " items)", colors.text)
                task.wait(1.5)
                cloneBtn.Text = "Clone All Items (" .. #allItems .. ")"
            else
                cloneBtn.Text = string.format("Cloning %d/%d", batchNum, totalBatches)
            end
        end)
    end)
    
    -- ==================== INITIAL RENDER ====================
    renderGrid("ALL")
end

print("[Clone] App loaded!")