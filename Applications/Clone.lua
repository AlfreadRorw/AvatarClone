-- ================================================
-- CLONE APP - Fixed dengan API Avatar yang Benar
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

-- ==================== GET ITEMS - API SAMA SEPERTI FAVORITES ====================
local function getItems(player)
    local items = {}
    if not player then return items end
    
    print("[Clone] Fetching items for:", player.Name, "UserId:", player.UserId)
    
    -- Gunakan API yang sama seperti Favorites
    local ok, result = pcall(function()
        return HttpService:JSONDecode(HttpService:GetAsync("https://avatar.roblox.com/v1/users/" .. player.UserId .. "/avatar"))
    end)
    
    if not ok then
        print("[Clone] Avatar API error:", result)
        return items
    end
    
    if not result then
        print("[Clone] Avatar API returned nil")
        return items
    end
    
    print("[Clone] Avatar API response:", result)
    
    if not result.assets then
        print("[Clone] No 'assets' field in response")
        return items
    end
    
    for _, asset in ipairs(result.assets) do
        if asset and asset.id then
            local assetId = tonumber(asset.id)
            if assetId and assetId > 0 then
                local assetType = "ACC"
                local assetName = asset.name or "Item " .. assetId
                
                -- Deteksi tipe asset
                if asset.assetType then
                    local at = string.lower(tostring(asset.assetType))
                    if at:find("body") or at:find("torso") or at:find("leg") or at:find("head") or at:find("arm") then
                        assetType = "BODY"
                    else
                        assetType = "ACC"
                    end
                end
                
                table.insert(items, {
                    Value = tostring(assetId),
                    Label = assetName,
                    Type = assetType,
                })
                
                print("[Clone] Added:", assetName, "ID:", assetId, "Type:", assetType)
            end
        end
    end
    
    print("[Clone] Total items found:", #items)
    
    return items
end

-- ==================== CLONE ITEMS BATCH ====================
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
    
    -- Type badge
    local typeBadge = Instance.new("TextLabel", row)
    typeBadge.Size = UDim2.new(0, 40, 0, 16)
    typeBadge.Position = UDim2.new(1, -130, 0, 4)
    typeBadge.BackgroundColor3 = item.Type == "BODY" and colors.gold or colors.accent2
    typeBadge.BackgroundTransparency = 0.7
    typeBadge.Text = item.Type
    typeBadge.TextColor3 = item.Type == "BODY" and colors.gold or colors.accent2
    typeBadge.Font = Enum.Font.GothamBlack
    typeBadge.TextSize = 7
    typeBadge.ZIndex = 3
    corner(typeBadge, 8)
    
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
    
    -- Fetch items secara synchronous
    local allItems = getItems(selectedPlayer)
    
    if #allItems == 0 then
        local empty = Instance.new("TextLabel", appContent)
        empty.Size = UDim2.new(1, 0, 0, 80)
        empty.BackgroundTransparency = 1
        empty.Text = "No items found for " .. selectedPlayer.DisplayName .. "\n\nPlayer might not have any wearable items."
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
    itemCountLbl.Text = #allItems .. " items found"
    itemCountLbl.TextColor3 = colors.green
    itemCountLbl.Font = Enum.Font.Gotham
    itemCountLbl.TextSize = 11
    itemCountLbl.TextXAlignment = Enum.TextXAlignment.Left
    
    -- ==================== CLONE ALL BUTTON ====================
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
    
    -- ==================== ITEMS LIST ====================
    for i, item in ipairs(allItems) do
        buildItemRow(appContent, item, i + 1)
    end
end

print("[Clone] App loaded!")