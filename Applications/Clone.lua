-- ================================================
-- CLONE APP - Fixed dengan Robust HTTP Request
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
}

-- ==================== LIFECYCLE ====================
local CloneLifecycle = {
    active = false,
    tasks = {},
    isFetching = false,
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
local function robustHttpGet(url)
    print("[Clone] Fetching URL:", url)
    
    -- Method 1: syn.request
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
        
        if ok and result then
            print("[Clone] syn.request Status:", result.StatusCode)
            if result.StatusCode == 200 and result.Body then
                return {
                    success = true,
                    statusCode = result.StatusCode,
                    body = result.Body,
                }
            else
                return {
                    success = false,
                    statusCode = result.StatusCode,
                    error = "HTTP " .. tostring(result.StatusCode),
                }
            end
        end
    end
    
    -- Method 2: http_request
    if http_request then
        local ok, result = pcall(function()
            return http_request({
                Url = url,
                Method = "GET",
            })
        end)
        
        if ok and result then
            print("[Clone] http_request Status:", result.StatusCode)
            if result.StatusCode == 200 and result.Body then
                return {
                    success = true,
                    statusCode = result.StatusCode,
                    body = result.Body,
                }
            else
                return {
                    success = false,
                    statusCode = result.StatusCode,
                    error = "HTTP " .. tostring(result.StatusCode),
                }
            end
        end
    end
    
    -- Method 3: game:HttpGet (HttpService)
    local ok, result = pcall(function()
        return HttpService:GetAsync(url)
    end)
    
    if ok and result and result ~= "" and result ~= "null" then
        print("[Clone] HttpService:GetAsync success")
        return {
            success = true,
            statusCode = 200,
            body = result,
        }
    end
    
    -- Method 4: request (Fluxus style)
    if request then
        local ok2, result2 = pcall(function()
            return request({
                Url = url,
                Method = "GET",
            })
        end)
        
        if ok2 and result2 then
            print("[Clone] request success")
            return {
                success = true,
                statusCode = 200,
                body = result2.Body or result2,
            }
        end
    end
    
    print("[Clone] All HTTP methods failed")
    return {
        success = false,
        statusCode = nil,
        error = "All HTTP methods failed",
    }
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

-- ==================== CLASSIFY ASSET TYPE ====================
local function classifyAssetType(asset)
    if not asset then return "ACC" end
    
    local assetType = asset.assetType
    
    -- assetType bisa berupa table/object
    local typeName = ""
    local typeId = 0
    
    if type(assetType) == "table" then
        typeName = assetType.name or ""
        typeId = assetType.id or 0
    else
        typeName = tostring(assetType or "")
    end
    
    typeName = string.lower(typeName)
    
    -- Body parts
    if typeName:find("body") or typeName:find("torso") or typeName:find("leg") 
       or typeName:find("head") or typeName:find("arm") or typeName:find("skin")
       or typeName:find("bodyparts") or typeName:find("character") then
        return "BODY"
    end
    
    -- Clothing
    if typeName:find("shirt") or typeName:find("pants") or typeName:find("tshirt")
       or typeName:find("clothing") or typeName:find("layered") then
        return "ACC"
    end
    
    -- Accessories (semua jenis)
    if typeName:find("hat") or typeName:find("hair") or typeName:find("face")
       or typeName:find("neck") or typeName:find("shoulder") or typeName:find("front")
       or typeName:find("back") or typeName:find("waist") or typeName:find("accessory")
       or typeName:find("gear") or typeName:find("eyebrow") or typeName:find("eyelash")
       or typeName:find("beard") or typeName:find("mask") or typeName:find("helmet")
       or typeName:find("glasses") or typeName:find("ear") or typeName:find("nose") then
        return "ACC"
    end
    
    -- Default: ACC (semua yang bisa di-wear)
    return "ACC"
end

-- ==================== GET ITEMS ====================
local function getItems(player)
    local items = {}
    if not player then return items end
    
    local userId = player.UserId
    print("[Clone] ========== FETCHING AVATAR ==========")
    print("[Clone] Player:", player.Name)
    print("[Clone] UserId:", userId)
    
    local httpResult = robustHttpGet("https://avatar.roblox.com/v1/users/" .. userId .. "/avatar")
    
    if not httpResult.success then
        print("[Clone] HTTP request failed:", httpResult.error)
        return items, {
            success = false,
            errorType = "request_failed",
            error = httpResult.error or "Unknown error",
            statusCode = httpResult.statusCode,
        }
    end
    
    print("[Clone] HTTP status:", httpResult.statusCode)
    
    local decodeOk, data = pcall(function()
        return HttpService:JSONDecode(httpResult.body)
    end)
    
    if not decodeOk then
        print("[Clone] JSON decode failed:", data)
        return items, {
            success = false,
            errorType = "invalid_response",
            error = "JSON decode failed: " .. tostring(data),
        }
    end
    
    if not data then
        print("[Clone] Response is nil")
        return items, {
            success = false,
            errorType = "invalid_response",
            error = "Response is nil",
        }
    end
    
    if not data.assets then
        print("[Clone] No 'assets' field in response")
        return items, {
            success = false,
            errorType = "invalid_response",
            error = "No 'assets' field in response",
        }
    end
    
    if type(data.assets) ~= "table" then
        print("[Clone] 'assets' is not a table")
        return items, {
            success = false,
            errorType = "invalid_response",
            error = "'assets' is not a table",
        }
    end
    
    print("[Clone] Assets received:", #data.assets)
    
    for _, asset in ipairs(data.assets) do
        if asset and asset.id then
            local assetId = tonumber(asset.id)
            
            if assetId and assetId > 0 then
                local assetName = asset.name or "Item " .. assetId
                local assetType = classifyAssetType(asset)
                
                -- Get type name for logging
                local typeName = "Unknown"
                if type(asset.assetType) == "table" then
                    typeName = asset.assetType.name or "Unknown"
                elseif asset.assetType then
                    typeName = tostring(asset.assetType)
                end
                
                table.insert(items, {
                    Value = tostring(assetId),
                    Label = assetName,
                    Type = assetType,
                    TypeName = typeName,
                })
                
                print("[Clone] Added asset:", assetName, "| ID:", assetId, "| Type:", typeName)
            end
        end
    end
    
    print("[Clone] Total items:", #items)
    print("[Clone] ========================================")
    
    if #items == 0 then
        return items, {
            success = true,
            errorType = "empty",
            error = "No assets found",
        }
    end
    
    return items, {success = true}
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
        if not CloneLifecycle.active then
            print("[Clone] Clone cancelled - app closed")
            return
        end
        
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
        
        local delayTask = task.delay(delay, nextBatch)
        table.insert(CloneLifecycle.tasks, delayTask)
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
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    
    local idLbl = Instance.new("TextLabel", row)
    idLbl.Size = UDim2.new(1, -130, 0, 16)
    idLbl.Position = UDim2.new(0, 52, 0, 24)
    idLbl.BackgroundTransparency = 1
    idLbl.Text = item.Value
    idLbl.TextColor3 = colors.green
    idLbl.Font = Enum.Font.Code
    idLbl.TextSize = 10
    idLbl.TextXAlignment = Enum.TextXAlignment.Left
    
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
    CloneLifecycle.isFetching = false
    
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
    
    -- Main render function
    local function renderCloneUI()
        -- Clear existing content
        for _, c in ipairs(appContent:GetChildren()) do
            if not c:IsA("UIListLayout") then c:Destroy() end
        end
        
        if CloneLifecycle.isFetching then
            return
        end
        
        CloneLifecycle.isFetching = true
        
        -- Loading indicator
        local loadingCard = Instance.new("Frame", appContent)
        loadingCard.Size = UDim2.new(1, 0, 0, 50)
        loadingCard.BackgroundColor3 = colors.card2
        loadingCard.LayoutOrder = 0
        corner(loadingCard, 12)
        
        local loadingText = Instance.new("TextLabel", loadingCard)
        loadingText.Size = UDim2.new(1, -20, 1, 0)
        loadingText.Position = UDim2.new(0, 10, 0, 0)
        loadingText.BackgroundTransparency = 1
        loadingText.Text = "Fetching items for " .. selectedPlayer.DisplayName .. "..."
        loadingText.TextColor3 = colors.text2
        loadingText.Font = Enum.Font.Gotham
        loadingText.TextSize = 11
        loadingText.TextWrapped = true
        
        task.spawn(function()
            local items, result = getItems(selectedPlayer)
            
            CloneLifecycle.isFetching = false
            pcall(function() loadingCard:Destroy() end)
            
            if not result.success then
                -- Error state
                local errorCard = Instance.new("Frame", appContent)
                errorCard.Size = UDim2.new(1, 0, 0, 120)
                errorCard.BackgroundColor3 = colors.card
                errorCard.LayoutOrder = 0
                corner(errorCard, 14)
                stroke(errorCard, colors.red, 2, 0.3)
                
                local errorTitle = Instance.new("TextLabel", errorCard)
                errorTitle.Size = UDim2.new(1, -20, 0, 22)
                errorTitle.Position = UDim2.new(0, 10, 0, 15)
                errorTitle.BackgroundTransparency = 1
                errorTitle.Text = "Failed to load avatar items"
                errorTitle.TextColor3 = colors.red
                errorTitle.Font = Enum.Font.GothamBlack
                errorTitle.TextSize = 13
                errorTitle.TextXAlignment = Enum.TextXAlignment.Center
                
                local errorMsg = Instance.new("TextLabel", errorCard)
                errorMsg.Size = UDim2.new(1, -20, 0, 20)
                errorMsg.Position = UDim2.new(0, 10, 0, 40)
                errorMsg.BackgroundTransparency = 1
                errorMsg.Text = result.errorType == "request_failed" 
                    and ("HTTP status: " .. tostring(result.statusCode or "unknown"))
                    or result.error or "Unknown error"
                errorMsg.TextColor3 = colors.text2
                errorMsg.Font = Enum.Font.Gotham
                errorMsg.TextSize = 10
                errorMsg.TextXAlignment = Enum.TextXAlignment.Center
                errorMsg.TextWrapped = true
                
                local retryBtn = Instance.new("TextButton", errorCard)
                retryBtn.Size = UDim2.new(0, 100, 0, 32)
                retryBtn.Position = UDim2.new(0.5, -50, 0, 72)
                retryBtn.BackgroundColor3 = colors.accent
                retryBtn.Text = "Retry"
                retryBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
                retryBtn.Font = Enum.Font.GothamBlack
                retryBtn.TextSize = 11
                retryBtn.AutoButtonColor = false
                corner(retryBtn, 8)
                pressFX(retryBtn)
                
                retryBtn.MouseButton1Click:Connect(function()
                    renderCloneUI()
                end)
                
                return
            end
            
            if #items == 0 then
                -- Empty state (valid response, no items)
                local emptyCard = Instance.new("Frame", appContent)
                emptyCard.Size = UDim2.new(1, 0, 0, 100)
                emptyCard.BackgroundColor3 = colors.card
                emptyCard.LayoutOrder = 0
                corner(emptyCard, 14)
                stroke(emptyCard, colors.border, 1, 0.3)
                
                local emptyText = Instance.new("TextLabel", emptyCard)
                emptyText.Size = UDim2.new(1, -20, 1, 0)
                emptyText.Position = UDim2.new(0, 10, 0, 0)
                emptyText.BackgroundTransparency = 1
                emptyText.Text = "No wearable items found for " .. selectedPlayer.DisplayName
                emptyText.TextColor3 = colors.text3
                emptyText.Font = Enum.Font.GothamBold
                emptyText.TextSize = 12
                emptyText.TextWrapped = true
                emptyText.TextXAlignment = Enum.TextXAlignment.Center
                return
            end
            
            -- Player header
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
            itemCountLbl.Text = #items .. " items found"
            itemCountLbl.TextColor3 = colors.green
            itemCountLbl.Font = Enum.Font.Gotham
            itemCountLbl.TextSize = 11
            itemCountLbl.TextXAlignment = Enum.TextXAlignment.Left
            
            -- Clone All button
            local cloneBtn = Instance.new("TextButton", appContent)
            cloneBtn.Size = UDim2.new(1, 0, 0, 46)
            cloneBtn.BackgroundColor3 = colors.accent
            cloneBtn.Text = "Clone All Items (" .. #items .. ")"
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
                
                cloneItems(items, function(done, batchNum, totalBatches)
                    if done then
                        if _G.PhoneState then
                            _G.PhoneState.isCloning = false
                        end
                        cloneBtn.Text = "Clone Complete!"
                        cloneBtn.BackgroundColor3 = colors.green
                        _G.showDynamicNotification("Clone complete! (" .. #items .. " items)", colors.green)
                    else
                        cloneBtn.Text = string.format("Cloning %d/%d", batchNum, totalBatches)
                    end
                end)
            end)
            
            -- Items list
            for i, item in ipairs(items) do
                buildItemRow(appContent, item, i + 1)
            end
        end)
    end
    
    -- Initial render
    renderCloneUI()
end

print("[Clone] App loaded!")