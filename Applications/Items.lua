-- ================================================
-- ITEMS APP - Dark Theme
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

-- ==================== DARK THEME ====================
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
}

local favItems = Storage.favItems or {}

-- ==================== LIFECYCLE ====================
local ItemsLifecycle = {
    active = false,
    tasks = {},
}

local function cleanupItems()
    ItemsLifecycle.active = false
    for _, task in ipairs(ItemsLifecycle.tasks) do
        pcall(function() task.cancel() end)
    end
    ItemsLifecycle.tasks = {}
end

table.insert(_G.AvatarCloneCleanupTasks or {}, cleanupItems)

-- ==================== HELPERS ====================
local function persistFavItems()
    if Storage.persistFavItems then
        Storage.persistFavItems()
    end
end

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
    
    local ok, result = pcall(function()
        return HttpService:JSONDecode(HttpService:GetAsync("https://avatar.roblox.com/v1/users/" .. player.UserId .. "/avatar"))
    end)
    
    if not ok or not result or not result.assets then
        return items
    end
    
    for _, asset in ipairs(result.assets) do
        if asset and asset.id then
            local assetId = tonumber(asset.id)
            if assetId and assetId > 0 then
                local assetType = "ACC"
                
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
                    Label = asset.name or "Item " .. assetId,
                    Type = assetType,
                })
            end
        end
    end
    
    return items
end

-- ==================== BUILD ITEM ROW ====================
local function buildItemRow(parent, item, order)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, 0, 0, 52)
    row.BackgroundColor3 = colors.card2
    row.LayoutOrder = order
    corner(row, 10)
    stroke(row, colors.border, 1, 0.3)
    
    -- Thumbnail
    local thumb = Instance.new("ImageLabel", row)
    thumb.Size = UDim2.new(0, 42, 0, 42)
    thumb.Position = UDim2.new(0, 5, 0.5, -21)
    thumb.BackgroundColor3 = colors.card
    thumb.Image = "https://www.roblox.com/asset-thumbnail/image?assetId=" .. item.Value .. "&width=100&height=100&format=png"
    thumb.ScaleType = Enum.ScaleType.Fit
    corner(thumb, 8)
    stroke(thumb, colors.border, 1, 0.3)
    
    -- Name
    local nameLbl = Instance.new("TextLabel", row)
    nameLbl.Size = UDim2.new(1, -180, 0, 18)
    nameLbl.Position = UDim2.new(0, 52, 0, 6)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = item.Label
    nameLbl.TextColor3 = colors.text
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 12
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    
    -- ID
    local idLbl = Instance.new("TextLabel", row)
    idLbl.Size = UDim2.new(1, -180, 0, 16)
    idLbl.Position = UDim2.new(0, 52, 0, 24)
    idLbl.BackgroundTransparency = 1
    idLbl.Text = item.Value
    idLbl.TextColor3 = colors.green
    idLbl.Font = Enum.Font.Code
    idLbl.TextSize = 10
    idLbl.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Type badge
    local typeBadge = Instance.new("TextLabel", row)
    typeBadge.Size = UDim2.new(0, 35, 0, 14)
    typeBadge.Position = UDim2.new(0, 52, 0, 40)
    typeBadge.BackgroundColor3 = item.Type == "BODY" and colors.gold or colors.accent2
    typeBadge.BackgroundTransparency = 0.7
    typeBadge.Text = item.Type
    typeBadge.TextColor3 = item.Type == "BODY" and colors.gold or colors.accent2
    typeBadge.Font = Enum.Font.GothamBlack
    typeBadge.TextSize = 6
    typeBadge.ZIndex = 3
    corner(typeBadge, 7)
    
    -- Wear button
    local wearBtn = Instance.new("TextButton", row)
    wearBtn.Size = UDim2.new(0, 60, 0, 28)
    wearBtn.Position = UDim2.new(1, -130, 0.5, -14)
    wearBtn.BackgroundColor3 = colors.green
    wearBtn.Text = "Wear"
    wearBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    wearBtn.Font = Enum.Font.GothamBold
    wearBtn.TextSize = 10
    wearBtn.AutoButtonColor = false
    corner(wearBtn, 6)
    pressFX(wearBtn)
    
    wearBtn.MouseButton1Click:Connect(function()
        fireHat({item.Value})
        _G.showDynamicNotification("Wearing " .. item.Value, colors.green)
    end)
    
    -- Favorite button
    local favBtn = Instance.new("TextButton", row)
    favBtn.Size = UDim2.new(0, 60, 0, 28)
    favBtn.Position = UDim2.new(1, -66, 0.5, -14)
    favBtn.BackgroundColor3 = colors.accent
    favBtn.Text = "Fav"
    favBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    favBtn.Font = Enum.Font.GothamBold
    favBtn.TextSize = 10
    favBtn.AutoButtonColor = false
    corner(favBtn, 6)
    pressFX(favBtn)
    
    favBtn.MouseButton1Click:Connect(function()
        -- Cek apakah sudah ada di favorites
        for _, fav in ipairs(favItems) do
            if tostring(fav.id) == item.Value then
                _G.showDynamicNotification("Already in favorites", colors.red)
                return
            end
        end
        
        table.insert(favItems, {
            id = item.Value,
            label = item.Label,
            date = os.date("%d/%m/%Y %H:%M"),
        })
        
        persistFavItems()
        _G.showDynamicNotification("Added to fav items", colors.green)
    end)
    
    return row
end

-- ==================== OPEN ITEMS APP ====================
function _G.openItemsApp()
    cleanupItems()
    ItemsLifecycle.active = true
    
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
    headerCard.BackgroundColor3 = colors.card2
    headerCard.LayoutOrder = 0
    corner(headerCard, 12)
    stroke(headerCard, colors.accent2, 1.5, 0.3)
    
    local avatar = Instance.new("ImageLabel", headerCard)
    avatar.Size = UDim2.new(0, 36, 0, 36)
    avatar.Position = UDim2.new(0, 8, 0.5, -18)
    avatar.BackgroundColor3 = colors.card
    avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. selectedPlayer.UserId .. "&width=100&height=100&format=png"
    corner(avatar, 100)
    
    local nameLbl = Instance.new("TextLabel", headerCard)
    nameLbl.Size = UDim2.new(1, -60, 0, 24)
    nameLbl.Position = UDim2.new(0, 50, 0, 6)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = selectedPlayer.DisplayName
    nameLbl.TextColor3 = colors.text
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 13
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local userLbl = Instance.new("TextLabel", headerCard)
    userLbl.Size = UDim2.new(1, -60, 0, 16)
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
        empty.Text = "No items found for " .. selectedPlayer.DisplayName
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
    counterText.TextColor3 = colors.green
    counterText.Font = Enum.Font.GothamBold
    counterText.TextSize = 10
    counterText.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Items list
    for i, item in ipairs(items) do
        buildItemRow(appContent, item, i + 1)
    end
end

print("[Items] App loaded!")