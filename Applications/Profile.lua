-- ================================================
-- PROFILE APP - Dark Theme
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

local function getItems(player)
    local items = {}
    if not player then return items end
    
    local ok, data = pcall(function()
        return HttpService:JSONDecode(HttpService:GetAsync("https://avatar.roblox.com/v1/users/" .. player.UserId .. "/avatar"))
    end)
    
    if not ok or not data or not data.assets then
        return items
    end
    
    for _, asset in ipairs(data.assets) do
        if asset.id and type(asset.id) == "number" then
            table.insert(items, {
                Value = tostring(asset.id),
                Label = asset.name or "Item " .. asset.id,
                Type = "ACC",
            })
        end
    end
    
    return items
end

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

function _G.openProfileApp()
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
    
    local p = selectedPlayer
    
    -- ==================== PROFILE CARD ====================
    local card = Instance.new("Frame", appContent)
    card.Size = UDim2.new(1, 0, 0, 100)
    card.BackgroundColor3 = colors.card2
    card.LayoutOrder = 0
    corner(card, 14)
    stroke(card, colors.accent2, 1.5, 0.3)
    
    local avatar = Instance.new("ImageLabel", card)
    avatar.Size = UDim2.new(0, 70, 0, 70)
    avatar.Position = UDim2.new(0, 12, 0.5, -35)
    avatar.BackgroundColor3 = colors.card
    avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. p.UserId .. "&width=150&height=150&format=png"
    corner(avatar, 100)
    stroke(avatar, colors.accent2, 2, 0.2)
    
    local nameLbl = Instance.new("TextLabel", card)
    nameLbl.Size = UDim2.new(1, -94, 0, 24)
    nameLbl.Position = UDim2.new(0, 90, 0, 10)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = p.DisplayName
    nameLbl.TextColor3 = colors.text
    nameLbl.Font = Enum.Font.GothamBlack
    nameLbl.TextSize = 16
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local userLbl = Instance.new("TextLabel", card)
    userLbl.Size = UDim2.new(1, -94, 0, 18)
    userLbl.Position = UDim2.new(0, 90, 0, 34)
    userLbl.BackgroundTransparency = 1
    userLbl.Text = "@" .. p.Name
    userLbl.TextColor3 = colors.text2
    userLbl.Font = Enum.Font.Gotham
    userLbl.TextSize = 12
    userLbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local idLbl = Instance.new("TextLabel", card)
    idLbl.Size = UDim2.new(1, -94, 0, 16)
    idLbl.Position = UDim2.new(0, 90, 0, 52)
    idLbl.BackgroundTransparency = 1
    idLbl.Text = "ID: " .. p.UserId
    idLbl.TextColor3 = colors.text3
    idLbl.Font = Enum.Font.Code
    idLbl.TextSize = 10
    idLbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local items = getItems(p)
    local statsLbl = Instance.new("TextLabel", card)
    statsLbl.Size = UDim2.new(1, -94, 0, 18)
    statsLbl.Position = UDim2.new(0, 90, 0, 68)
    statsLbl.BackgroundTransparency = 1
    statsLbl.Text = #items .. " items total"
    statsLbl.TextColor3 = colors.green
    statsLbl.Font = Enum.Font.Gotham
    statsLbl.TextSize = 11
    statsLbl.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Clone button
    local cloneBtn = Instance.new("TextButton", appContent)
    cloneBtn.Size = UDim2.new(1, 0, 0, 46)
    cloneBtn.BackgroundColor3 = colors.accent
    cloneBtn.Text = "Clone Avatar"
    cloneBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    cloneBtn.Font = Enum.Font.GothamBlack
    cloneBtn.TextSize = 14
    cloneBtn.AutoButtonColor = false
    cloneBtn.LayoutOrder = 1
    corner(cloneBtn, 10)
    pressFX(cloneBtn)
    
    cloneBtn.MouseButton1Click:Connect(function()
        if _G.PhoneState and _G.PhoneState.isCloning then return end
        
        local ids = {}
        for _, item in ipairs(items) do
            table.insert(ids, item.Value)
        end
        
        fireHat(ids)
        _G.showDynamicNotification("Cloning " .. #ids .. " items!", colors.green)
    end)
    
    -- Items list
    local itemLbl = Instance.new("TextLabel", appContent)
    itemLbl.Size = UDim2.new(1, 0, 0, 20)
    itemLbl.BackgroundTransparency = 1
    itemLbl.Text = "Items (" .. #items .. ")"
    itemLbl.TextColor3 = colors.text2
    itemLbl.Font = Enum.Font.GothamBold
    itemLbl.TextSize = 11
    itemLbl.TextXAlignment = Enum.TextXAlignment.Left
    itemLbl.LayoutOrder = 2
    
    for i, item in ipairs(items) do
        buildItemRow(appContent, item, i + 2)
    end
end

print("[Profile] App loaded!")