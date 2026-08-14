-- ================================================
-- CLONE APP - Fixed dengan Synapse Request
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

-- ==================== CLEAN DARK THEME ====================
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

-- ==================== LIFECYCLE ====================
local CloneLifecycle = {
    active = false,
    tasks = {},
}

local function cleanupClone()
    CloneLifecycle.active = false
    for _, task in ipairs(CloneLifecycle.tasks) do
        pcall(function() task.cancel() end)
    end
    CloneLifecycle.tasks = {}
end

table.insert(_G.AvatarCloneCleanupTasks or {}, cleanupClone)

-- ==================== HTTP REQUEST - FIXED ====================
local function httpGet(url)
    print("[Clone] Fetching:", url)
    
    -- Method 1: syn.request (Synapse X)
    if syn and syn.request then
        local ok, result = pcall(function()
            return syn.request({
                Url = url,
                Method = "GET",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["Accept"] = "application/json",
                }
            })
        end)
        
        if ok and result and result.StatusCode == 200 and result.Body then
            print("[Clone] syn.request success, body length:", #result.Body)
            return result.Body
        elseif ok and result then
            print("[Clone] syn.request status:", result.StatusCode)
        end
    end
    
    -- Method 2: http_request (Krnl)
    if http_request then
        local ok, result = pcall(function()
            return http_request({
                Url = url,
                Method = "GET",
            })
        end)
        
        if ok and result and result.StatusCode == 200 and result.Body then
            print("[Clone] http_request success, body length:", #result.Body)
            return result.Body
        end
    end
    
    -- Method 3: request (Fluxus)
    if request then
        local ok, result = pcall(function()
            return request({
                Url = url,
                Method = "GET",
            })
        end)
        
        if ok and result then
            local body = result.Body or result
            if body and body ~= "" and body ~= "null" then
                print("[Clone] request success")
                return body
            end
        end
    end
    
    -- Method 4: game:HttpGet (fallback)
    local ok, result = pcall(function()
        return game:HttpGet(url)
    end)
    
    if ok and result and result ~= "" and result ~= "null" then
        print("[Clone] game:HttpGet success")
        return result
    end
    
    print("[Clone] All HTTP methods failed")
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
    if not raw then 
        print("[Clone] Failed to get avatar data")
        return items 
    end
    
    local ok, data = pcall(function() 
        return HttpService:JSONDecode(raw) 
    end)
    
    if not ok then
        print("[Clone] JSON decode failed:", data)
        return items
    end
    
    if not data or not data.assets then
        print("[Clone] No assets field")
        return items
    end
    
    print("[Clone] Found", #data.assets, "assets")
    
    for _, asset in ipairs(data.assets) do
        if asset and asset.id then
            local assetId = tonumber(asset.id)
            if assetId and assetId > 0 then
                local assetType = "ACC"
                local assetName = asset.name or "Item " .. assetId
                
                local typeName = ""
                if type(asset.assetType) == "table" then
                    typeName = string.lower(asset.assetType.name or "")
                elseif asset.assetType then
                    typeName = string.lower(tostring(asset.assetType))
                end
                
                if typeName:find("body") or typeName:find("torso") or typeName:find("leg") 
                   or typeName:find("head") or typeName:find("arm") then
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
    
    print("[Clone] Total items:", #items)
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
    row.Size = UDim2.new(1, 0, 0, 48)
    row.BackgroundColor3 = colors.card2
    row.LayoutOrder = order
    corner(row, 10)
    stroke(row, colors.border, 1, 0.3)
    
    local thumb = Instance.new("ImageLabel", row)
    thumb.Size = UDim2.new(0, 36, 0, 36)
    thumb.Position = UDim2.new(0, 6, 0.5, -18)
    thumb.BackgroundColor3 = colors.card
    thumb.Image = "https://www.roblox.com/asset-thumbnail/image?assetId=" .. item.Value .. "&width=100&height=100&format=png"
    thumb.ScaleType = Enum.ScaleType.Fit
    corner(thumb, 8)
    
    local nameLbl = Instance.new("TextLabel", row)
    nameLbl.Size = UDim2.new(1, -130, 0, 18)
    nameLbl.Position = UDim2.new(0, 48, 0, 5)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = item.Label
    nameLbl.TextColor3 = colors.text
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 11
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    
    local idLbl = Instance.new("TextLabel", row)
    idLbl.Size = UDim2.new(1, -130, 0, 14)
    idLbl.Position = UDim2.new(0, 48, 0, 24)
    idLbl.BackgroundTransparency = 1
    idLbl.Text = item.Value
    idLbl.TextColor3 = colors.text3
    idLbl.Font = Enum.Font.Code
    idLbl.TextSize = 9
    idLbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local copyBtn = Instance.new("TextButton", row)
    copyBtn.Size = UDim2.new(0, 50, 0, 24)
    copyBtn.Position = UDim2.new(1, -56, 0.5, -12)
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
    end)
end

-- ==================== OPEN CLONE APP ====================
function _G.openCloneApp()
    cleanupClone()
    CloneLifecycle.active = true
    
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
        empty.Text = "No items found for " .. selectedPlayer.DisplayName .. "\n\nCheck console for API errors"
        empty.TextColor3 = colors.text3
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 11
        empty.TextWrapped = true
        empty.LayoutOrder = 0
        return
    end
    
    -- Player header
    local playerFrame = Instance.new("Frame", appContent)
    playerFrame.Size = UDim2.new(1, 0, 0, 50)
    playerFrame.BackgroundColor3 = colors.card
    playerFrame.LayoutOrder = 0
    corner(playerFrame, 10)
    stroke(playerFrame, colors.border, 1, 0.3)
    
    local avatar = Instance.new("ImageLabel", playerFrame)
    avatar.Size = UDim2.new(0, 38, 0, 38)
    avatar.Position = UDim2.new(0, 6, 0.5, -19)
    avatar.BackgroundColor3 = colors.card2
    avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. selectedPlayer.UserId .. "&width=100&height=100&format=png"
    corner(avatar, 100)
    
    local nameLbl = Instance.new("TextLabel", playerFrame)
    nameLbl.Size = UDim2.new(1, -55, 0, 22)
    nameLbl.Position = UDim2.new(0, 50, 0, 6)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = selectedPlayer.DisplayName
    nameLbl.TextColor3 = colors.text
    nameLbl.Font = Enum.Font.GothamBlack
    nameLbl.TextSize = 12
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local countLbl = Instance.new("TextLabel", playerFrame)
    countLbl.Size = UDim2.new(1, -55, 0, 14)
    countLbl.Position = UDim2.new(0, 50, 0, 28)
    countLbl.BackgroundTransparency = 1
    countLbl.Text = #allItems .. " items"
    countLbl.TextColor3 = colors.text2
    countLbl.Font = Enum.Font.Gotham
    countLbl.TextSize = 9
    countLbl.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Tab system
    local tabFrame = Instance.new("Frame", appContent)
    tabFrame.Size = UDim2.new(1, 0, 0, 36)
    tabFrame.BackgroundColor3 = colors.card
    tabFrame.LayoutOrder = 1
    corner(tabFrame, 10)
    stroke(tabFrame, colors.border, 1, 0.3)
    
    local tabLayout = Instance.new("UIGridLayout", tabFrame)
    tabLayout.CellSize = UDim2.new(1/3, -4, 0, 30)
    tabLayout.CellPadding = UDim2.new(0, 4, 0, 0)
    
    local tabs = {{"All", "ALL"}, {"Body", "BODY"}, {"Accs", "ACC"}}
    local tabButtons = {}
    
    local listHolder = Instance.new("Frame", appContent)
    listHolder.Size = UDim2.new(1, 0, 0, 0)
    listHolder.AutomaticSize = Enum.AutomaticSize.Y
    listHolder.BackgroundTransparency = 1
    listHolder.LayoutOrder = 2
    
    local listLayout = Instance.new("UIListLayout", listHolder)
    listLayout.Padding = UDim.new(0, 6)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    local function renderItems(filterType)
        for _, c in ipairs(listHolder:GetChildren()) do
            if not c:IsA("UIListLayout") then c:Destroy() end
        end
        
        local filtered = {}
        for _, item in ipairs(allItems) do
            if filterType == "ALL" or item.Type == filterType then
                table.insert(filtered, item)
            end
        end
        
        if #filtered == 0 then
            local empty = Instance.new("TextLabel", listHolder)
            empty.Size = UDim2.new(1, 0, 0, 30)
            empty.BackgroundTransparency = 1
            empty.Text = "No items in this tab"
            empty.TextColor3 = colors.text3
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 10
            return
        end
        
        for i, item in ipairs(filtered) do
            buildItemRow(listHolder, item, i)
        end
    end
    
    for i, tabData in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton", tabFrame)
        tabBtn.Size = UDim2.new(1, 0, 0, 30)
        tabBtn.BackgroundColor3 = i == 1 and colors.tabActive or colors.tabInactive
        tabBtn.Text = tabData[1]
        tabBtn.TextColor3 = i == 1 and Color3.fromRGB(0, 0, 0) or colors.text2
        tabBtn.Font = Enum.Font.GothamBlack
        tabBtn.TextSize = 9
        tabBtn.AutoButtonColor = false
        corner(tabBtn, 8)
        pressFX(tabBtn)
        
        tabBtn.MouseButton1Click:Connect(function()
            for _, btn in ipairs(tabButtons) do
                btn.BackgroundColor3 = colors.tabInactive
                btn.TextColor3 = colors.text2
            end
            tabBtn.BackgroundColor3 = colors.tabActive
            tabBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
            renderItems(tabData[2])
        end)
        
        table.insert(tabButtons, tabBtn)
    end
    
    -- Clone button
    local cloneBtn = Instance.new("TextButton", appContent)
    cloneBtn.Size = UDim2.new(1, 0, 0, 40)
    cloneBtn.BackgroundColor3 = colors.accent
    cloneBtn.Text = "Clone All"
    cloneBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    cloneBtn.Font = Enum.Font.GothamBlack
    cloneBtn.TextSize = 12
    cloneBtn.AutoButtonColor = false
    cloneBtn.LayoutOrder = 3
    corner(cloneBtn, 10)
    pressFX(cloneBtn)
    
    cloneBtn.MouseButton1Click:Connect(function()
        cloneBtn.Text = "Cloning..."
        cloneItems(allItems, function(done, batch, total)
            if done then
                cloneBtn.Text = "Done!"
                task.wait(1.5)
                cloneBtn.Text = "Clone All"
            else
                cloneBtn.Text = string.format("Clone %d/%d", batch, total)
            end
        end)
    end)
    
    -- Initial render
    renderItems("ALL")
end

print("[Clone] App loaded!")