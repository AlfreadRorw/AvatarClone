-- ================================================
-- CLONE APP - Fixed with Multiple API Fallback
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

-- ==================== LIFECYCLE ====================
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

-- ==================== GET ITEMS - FIXED WITH MULTIPLE API ====================
local function getItems(player)
    local items = {}
    if not player then 
        print("[Clone] No player selected")
        return items 
    end
    
    local userId = player.UserId
    print("[Clone] Fetching items for:", player.Name, "UserId:", userId)
    
    -- ==================== METHOD 1: Avatar API ====================
    local function tryAvatarAPI()
        local ok, response = pcall(function()
            return HttpService:GetAsync("https://avatar.roblox.com/v1/users/" .. userId .. "/avatar")
        end)
        
        if not ok then
            print("[Clone] Avatar API HTTP failed:", response)
            return false
        end
        
        local decodeOk, data = pcall(function()
            return HttpService:JSONDecode(response)
        end)
        
        if not decodeOk then
            print("[Clone] Avatar API JSON decode failed:", data)
            return false
        end
        
        print("[Clone] Avatar API response:", data)
        
        -- Cek berbagai struktur data
        if data.assets and type(data.assets) == "table" then
            for _, asset in ipairs(data.assets) do
                if asset and asset.id and type(asset.id) == "number" then
                    local assetType = "ACC"
                    local assetName = asset.name or "Item " .. asset.id
                    
                    if asset.assetType then
                        local at = string.lower(tostring(asset.assetType))
                        if at:find("body") or at:find("torso") or at:find("leg") or at:find("head") or at:find("arm") then
                            assetType = "BODY"
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
        
        return #items > 0
    end
    
    -- ==================== METHOD 2: Outfit API ====================
    local function tryOutfitAPI()
        local ok, response = pcall(function()
            return HttpService:GetAsync("https://avatar.roblox.com/v1/users/" .. userId .. "/outfits?itemsPerPage=1")
        end)
        
        if not ok then
            print("[Clone] Outfit API failed:", response)
            return false
        end
        
        local decodeOk, data = pcall(function()
            return HttpService:JSONDecode(response)
        end)
        
        if not decodeOk or not data or not data.data then
            return false
        end
        
        print("[Clone] Outfit API response:", data)
        
        if data.data[1] and data.data[1].id then
            -- Get outfit details
            local outfitOk, outfitResponse = pcall(function()
                return HttpService:GetAsync("https://avatar.roblox.com/v1/outfits/" .. data.data[1].id .. "/details")
            end)
            
            if outfitOk then
                local outfitData = pcall(function()
                    return HttpService:JSONDecode(outfitResponse)
                end)
                
                if outfitData then
                    local details = outfitData
                    if details.assets and type(details.assets) == "table" then
                        for _, asset in ipairs(details.assets) do
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
            end
        end
        
        return #items > 0
    end
    
    -- ==================== METHOD 3: Inventory API (Wearing) ====================
    local function tryInventoryAPI()
        local ok, response = pcall(function()
            return HttpService:GetAsync("https://inventory.roblox.com/v1/users/" .. userId .. "/assets/collectibles?assetType=Hat&sortOrder=Asc&limit=100")
        end)
        
        if not ok then
            print("[Clone] Inventory API failed:", response)
            return false
        end
        
        local decodeOk, data = pcall(function()
            return HttpService:JSONDecode(response)
        end)
        
        if not decodeOk or not data or not data.data then
            return false
        end
        
        print("[Clone] Inventory API found", #data.data, "items")
        
        for _, asset in ipairs(data.data) do
            if asset and asset.assetId and type(asset.assetId) == "number" then
                table.insert(items, {
                    Value = tostring(asset.assetId),
                    Label = asset.name or "Item " .. asset.assetId,
                    Type = "ACC",
                })
            end
        end
        
        return #items > 0
    end
    
    -- ==================== METHOD 4: Roblox Users API (Avatar Headshot) ====================
    local function tryUsersAPI()
        local ok, response = pcall(function()
            return HttpService:GetAsync("https://users.roblox.com/v1/users/" .. userId)
        end)
        
        if not ok then
            return false
        end
        
        local decodeOk, data = pcall(function()
            return HttpService:JSONDecode(response)
        end)
        
        -- This API doesn't return items, just user info
        return false
    end
    
    -- ==================== METHOD 5: Characters API ====================
    local function tryCharactersAPI()
        local ok, response = pcall(function()
            return HttpService:GetAsync("https://avatar.roblox.com/v1/users/" .. userId .. "/avatar")
        end)
        
        if not ok then
            return false
        end
        
        local decodeOk, data = pcall(function()
            return HttpService:JSONDecode(response)
        end)
        
        if not decodeOk or not data then
            return false
        end
        
        -- Check for different response structure
        if data.playerAvatarType and data.assets then
            for _, asset in ipairs(data.assets) do
                if asset and asset.id then
                    local id = tonumber(asset.id)
                    if id and id > 0 then
                        table.insert(items, {
                            Value = tostring(id),
                            Label = asset.name or "Item " .. id,
                            Type = "ACC",
                        })
                    end
                end
            end
        end
        
        -- Check bodyColors
        if data.bodyColors then
            -- Body colors are not wearable items, skip
        end
        
        return #items > 0
    end
    
    -- Try all methods
    local methods = {
        tryAvatarAPI,
        tryOutfitAPI,
        tryInventoryAPI,
        tryCharactersAPI,
    }
    
    for _, method in ipairs(methods) do
        local success = method()
        if success and #items > 0 then
            print("[Clone] Success using method, found", #items, "items")
            break
        end
    end
    
    -- Remove duplicates
    local seen = {}
    local uniqueItems = {}
    for _, item in ipairs(items) do
        if not seen[item.Value] then
            seen[item.Value] = true
            table.insert(uniqueItems, item)
        end
    end
    
    print("[Clone] Final unique items:", #uniqueItems)
    
    return uniqueItems
end

-- ==================== FIRE HAT REMOTE ====================
local function fireHat(ids)
    if #ids == 0 then return end
    
    local remote = ReplicatedStorage
    for _, part in ipairs(Config.REMOTE_PATH:split(".")) do
        remote = remote:FindFirstChild(part)
        if not remote then 
            print("[Clone] Remote not found at:", part)
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
    
    -- Loading indicator
    local loadingCard = Instance.new("Frame", appContent)
    loadingCard.Size = UDim2.new(1, 0, 0, 60)
    loadingCard.BackgroundColor3 = colors.card2
    loadingCard.LayoutOrder = 0
    corner(loadingCard, 12)
    
    local loadingText = Instance.new("TextLabel", loadingCard)
    loadingText.Size = UDim2.new(1, 0, 1, 0)
    loadingText.BackgroundTransparency = 1
    loadingText.Text = "Fetching items for " .. selectedPlayer.DisplayName .. "..."
    loadingText.TextColor3 = colors.text2
    loadingText.Font = Enum.Font.Gotham
    loadingText.TextSize = 11
    loadingText.TextWrapped = true
    
    -- Fetch items asynchronously
    task.spawn(function()
        local allItems = getItems(selectedPlayer)
        
        -- Remove loading
        pcall(function() loadingCard:Destroy() end)
        
        if #allItems == 0 then
            local empty = Instance.new("TextLabel", appContent)
            empty.Size = UDim2.new(1, 0, 0, 100)
            empty.BackgroundTransparency = 1
            empty.Text = "No wearable items found for " .. selectedPlayer.DisplayName .. "\n\nPlayer might not have any hats or body items.\nTry selecting a different player."
            empty.TextColor3 = colors.text3
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 11
            empty.TextWrapped = true
            empty.LayoutOrder = 0
            return
        end
        
        -- Render the app UI with items
        renderCloneUI(selectedPlayer, allItems)
    end)
end

-- ==================== RENDER CLONE UI ====================
function renderCloneUI(selectedPlayer, allItems)
    -- Player info header
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
    itemCountLbl.Text = #allItems .. " items found"
    itemCountLbl.TextColor3 = colors.green
    itemCountLbl.Font = Enum.Font.Gotham
    itemCountLbl.TextSize = 11
    itemCountLbl.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Clone all button
    local cloneBtn = Instance.new("TextButton", appContent)
    cloneBtn.Size = UDim2.new(1, 0, 0, 46)
    cloneBtn.BackgroundColor3 = colors.accent
    cloneBtn.Text = "Clone All Items (" .. #allItems .. ")"
    cloneBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    cloneBtn.Font = Enum.Font.GothamBlack
    cloneBtn.TextSize = 13
    cloneBtn.AutoButtonColor = false
    cloneBtn.LayoutOrder = 1
    corner(cloneBtn, 10)
    pressFX(cloneBtn)
    
    cloneBtn.MouseButton1Click:Connect(function()
        if _G.PhoneState and _G.PhoneState.isCloning then return end
        
        local ids = {}
        for _, item in ipairs(allItems) do
            table.insert(ids, item.Value)
        end
        
        if _G.PhoneState then
            _G.PhoneState.isCloning = true
        end
        
        cloneBtn.Text = "Cloning..."
        cloneBtn.BackgroundColor3 = colors.gold
        
        cloneItems(allItems, function(done, batchNum, totalBatches)
            if done then
                if _G.PhoneState then
                    _G.PhoneState.isCloning = false
                end
                cloneBtn.Text = "Clone Complete!"
                cloneBtn.BackgroundColor3 = colors.green
                _G.showDynamicNotification("Clone complete! (" .. #allItems .. " items)", colors.green)
            else
                cloneBtn.Text = string.format("Cloning %d/%d", batchNum, totalBatches)
            end
        end)
    end)
    
    -- Items list
    for i, item in ipairs(allItems) do
        buildItemRow(appContent, item, i + 1)
    end
end

print("[Clone] App loaded!")