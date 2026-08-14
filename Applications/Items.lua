-- ================================================
-- ITEMS APP - Fixed dengan Synapse Request
-- ================================================

local Services = _G.Services
local LocalPlayer = _G.LocalPlayer
local Players = Services.Players
local HttpService = Services.HttpService
local ReplicatedStorage = Services.ReplicatedStorage
local T = _G.T
local Helpers = _G.Helpers
local Config = _G.Config
local Storage = _G.Storage

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
}

local favItems = Storage.favItems or {}

-- ==================== HTTP REQUEST - FIXED ====================
local function httpGet(url)
    print("[Items] Fetching:", url)
    
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
        
        if ok and result and result.StatusCode == 200 and result.Body then
            print("[Items] syn.request success, body length:", #result.Body)
            return result.Body
        elseif ok and result then
            print("[Items] syn.request status:", result.StatusCode)
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
        
        if ok and result and result.StatusCode == 200 and result.Body then
            print("[Items] http_request success")
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
                print("[Items] request success")
                return body
            end
        end
    end
    
    -- Method 4: game:HttpGet
    local ok, result = pcall(function()
        return game:HttpGet(url)
    end)
    
    if ok and result and result ~= "" and result ~= "null" then
        print("[Items] game:HttpGet success")
        return result
    end
    
    print("[Items] All HTTP methods failed")
    return nil
end

-- ==================== FIRE HAT REMOTE ====================
local function fireHat(ids)
    if #ids == 0 then return end
    
    local remote = ReplicatedStorage
    for _, part in ipairs(Config.REMOTE_PATH:split(".")) do
        remote = remote:FindFirstChild(part)
        if not remote then 
            print("[Items] Remote not found at:", part)
            return 
        end
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
        print("[Items] Failed to get avatar data")
        return items 
    end
    
    local ok, data = pcall(function() 
        return HttpService:JSONDecode(raw) 
    end)
    
    if not ok then
        print("[Items] JSON decode failed:", data)
        return items
    end
    
    if not data or not data.assets then
        print("[Items] No assets field")
        return items
    end
    
    print("[Items] Found", #data.assets, "assets")
    
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
    
    print("[Items] Total items:", #items)
    return items
end

-- ==================== BUILD ITEM ROW ====================
local function buildItemRow(parent, item, order)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, 0, 0, 48)
    row.BackgroundColor3 = colors.card2
    row.LayoutOrder = order
    corner(row, 10)
    stroke(row, colors.border, 1, 0.3)
    
    -- Thumbnail
    local thumb = Instance.new("ImageLabel", row)
    thumb.Size = UDim2.new(0, 36, 0, 36)
    thumb.Position = UDim2.new(0, 6, 0.5, -18)
    thumb.BackgroundColor3 = colors.card
    thumb.Image = "https://www.roblox.com/asset-thumbnail/image?assetId=" .. item.Value .. "&width=100&height=100&format=png"
    thumb.ScaleType = Enum.ScaleType.Fit
    corner(thumb, 8)
    stroke(thumb, colors.border, 1, 0.3)
    
    -- Name
    local nameLbl = Instance.new("TextLabel", row)
    nameLbl.Size = UDim2.new(1, -190, 0, 18)
    nameLbl.Position = UDim2.new(0, 48, 0, 5)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = item.Label
    nameLbl.TextColor3 = colors.text
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 11
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    
    -- ID
    local idLbl = Instance.new("TextLabel", row)
    idLbl.Size = UDim2.new(1, -190, 0, 14)
    idLbl.Position = UDim2.new(0, 48, 0, 24)
    idLbl.BackgroundTransparency = 1
    idLbl.Text = item.Value
    idLbl.TextColor3 = colors.text3
    idLbl.Font = Enum.Font.Code
    idLbl.TextSize = 9
    idLbl.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Type badge
    local typeBadge = Instance.new("TextLabel", row)
    typeBadge.Size = UDim2.new(0, 35, 0, 14)
    typeBadge.Position = UDim2.new(0, 48, 0, 36)
    typeBadge.BackgroundColor3 = colors.card
    typeBadge.Text = item.Type
    typeBadge.TextColor3 = colors.text3
    typeBadge.Font = Enum.Font.GothamBlack
    typeBadge.TextSize = 7
    typeBadge.ZIndex = 3
    corner(typeBadge, 7)
    stroke(typeBadge, colors.border, 1, 0.3)
    
    -- Wear button
    local wearBtn = Instance.new("TextButton", row)
    wearBtn.Size = UDim2.new(0, 55, 0, 26)
    wearBtn.Position = UDim2.new(1, -120, 0.5, -13)
    wearBtn.BackgroundColor3 = colors.accent
    wearBtn.Text = "Wear"
    wearBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    wearBtn.Font = Enum.Font.GothamBold
    wearBtn.TextSize = 9
    wearBtn.AutoButtonColor = false
    corner(wearBtn, 6)
    pressFX(wearBtn)
    
    wearBtn.MouseButton1Click:Connect(function()
        fireHat({item.Value})
        _G.showDynamicNotification("Wearing " .. item.Value, colors.text)
    end)
    
    -- Favorite button
    local favBtn = Instance.new("TextButton", row)
    favBtn.Size = UDim2.new(0, 55, 0, 26)
    favBtn.Position = UDim2.new(1, -60, 0.5, -13)
    favBtn.BackgroundColor3 = colors.card
    favBtn.Text = "Fav"
    favBtn.TextColor3 = colors.text
    favBtn.Font = Enum.Font.GothamBold
    favBtn.TextSize = 9
    favBtn.AutoButtonColor = false
    corner(favBtn, 6)
    stroke(favBtn, colors.border, 1, 0.3)
    pressFX(favBtn)
    
    favBtn.MouseButton1Click:Connect(function()
        -- Cek duplikat
        for _, fav in ipairs(favItems) do
            if tostring(fav.id) == item.Value then
                _G.showDynamicNotification("Already in favorites", colors.text)
                return
            end
        end
        
        table.insert(favItems, {
            id = item.Value,
            label = item.Label,
            date = os.date("%d/%m/%Y %H:%M"),
        })
        
        if Storage.persistFavItems then
            Storage.persistFavItems()
        end
        
        _G.showDynamicNotification("Added to favorites", colors.text)
    end)
    
    return row
end

-- ==================== OPEN ITEMS APP ====================
function _G.openItemsApp()
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
    
    -- Player info header
    local headerCard = Instance.new("Frame", appContent)
    headerCard.Size = UDim2.new(1, 0, 0, 50)
    headerCard.BackgroundColor3 = colors.card
    headerCard.LayoutOrder = 0
    corner(headerCard, 12)
    stroke(headerCard, colors.border, 1, 0.3)
    
    local avatar = Instance.new("ImageLabel", headerCard)
    avatar.Size = UDim2.new(0, 36, 0, 36)
    avatar.Position = UDim2.new(0, 8, 0.5, -18)
    avatar.BackgroundColor3 = colors.card2
    avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. selectedPlayer.UserId .. "&width=100&height=100&format=png"
    corner(avatar, 100)
    
    local nameLbl = Instance.new("TextLabel", headerCard)
    nameLbl.Size = UDim2.new(1, -60, 0, 22)
    nameLbl.Position = UDim2.new(0, 50, 0, 6)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = selectedPlayer.DisplayName
    nameLbl.TextColor3 = colors.text
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 12
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local userLbl = Instance.new("TextLabel", headerCard)
    userLbl.Size = UDim2.new(1, -60, 0, 14)
    userLbl.Position = UDim2.new(0, 50, 0, 28)
    userLbl.BackgroundTransparency = 1
    userLbl.Text = "@" .. selectedPlayer.Name
    userLbl.TextColor3 = colors.text3
    userLbl.Font = Enum.Font.Gotham
    userLbl.TextSize = 9
    userLbl.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Get items
    local items = getItems(selectedPlayer)
    
    if #items == 0 then
        local empty = Instance.new("TextLabel", appContent)
        empty.Size = UDim2.new(1, 0, 0, 60)
        empty.BackgroundTransparency = 1
        empty.Text = "No items found for " .. selectedPlayer.DisplayName .. "\n\nCheck console for API errors"
        empty.TextColor3 = colors.text3
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 11
        empty.TextWrapped = true
        empty.LayoutOrder = 1
        return
    end
    
    -- Item counter
    local counterFrame = Instance.new("Frame", appContent)
    counterFrame.Size = UDim2.new(1, 0, 0, 20)
    counterFrame.BackgroundTransparency = 1
    counterFrame.LayoutOrder = 1
    
    local counterText = Instance.new("TextLabel", counterFrame)
    counterText.Size = UDim2.new(0, 120, 1, 0)
    counterText.BackgroundTransparency = 1
    counterText.Text = #items .. " items found"
    counterText.TextColor3 = colors.text2
    counterText.Font = Enum.Font.GothamBold
    counterText.TextSize = 10
    counterText.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Items list
    for i, item in ipairs(items) do
        buildItemRow(appContent, item, i + 1)
    end
end

print("[Items] App loaded!")