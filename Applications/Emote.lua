-- ================================================
-- EMOTE.LUA — Highly Optimized with UI Pooling & Staggered Rendering
-- Zero Frame Drop | UI Object Reuse | Native UIGridLayout | Async Preload
-- ================================================

local Services    = _G.Services or {}
local LocalPlayer = _G.LocalPlayer
local Helpers     = _G.Helpers or {}
local Storage     = _G.Storage or {}
local appContent  = _G.appContent
local appTitle    = _G.appTitle

local HttpService = Services.HttpService or game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")
local MarketplaceService = game:GetService("MarketplaceService")

local corner  = Helpers.corner  or function(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 10); c.Parent = o; return c end
local stroke  = Helpers.stroke  or function(o, c, t, tr) local s = Instance.new("UIStroke"); s.Color = c or Color3.fromRGB(80,80,80); s.Thickness = t or 1; s.Transparency = tr or 0; s.Parent = o; return s end
local tween   = Helpers.tween   or function(o, props) for k, v in pairs(props) do pcall(function() o[k] = v end) end end
local pressFX = Helpers.pressFX or function() end

-- ==================== PALETTE ====================
local C = {
    bg        = Color3.fromRGB(12, 12, 18),
    card      = Color3.fromRGB(20, 20, 28),
    card2     = Color3.fromRGB(28, 28, 38),
    cardHover = Color3.fromRGB(38, 38, 50),
    border    = Color3.fromRGB(50, 50, 65),
    text      = Color3.fromRGB(240, 238, 250),
    text2     = Color3.fromRGB(160, 158, 180),
    text3     = Color3.fromRGB(100, 98, 120),
    accent    = Color3.fromRGB(120, 140, 255),
    accent2   = Color3.fromRGB(80, 200, 255),
    gold      = Color3.fromRGB(255, 195, 70),
    green     = Color3.fromRGB(80, 220, 150),
    red       = Color3.fromRGB(255, 90, 100),
}

-- ==================== CACHE GLOBAL ====================
_G.EmoteCache = _G.EmoteCache or {
    emotes = {},
    favorites = {},
    idSet = {}, -- O(1) Lookup
    loaded = false,
    loading = false,
}

local Emotes = _G.EmoteCache.emotes
local Favorites = _G.EmoteCache.favorites
local IdSet = _G.EmoteCache.idSet

local function isLoaded() return _G.EmoteCache.loaded end
local function isLoading() return _G.EmoteCache.loading end

-- ==================== STATE ====================
local currentAnimTrack = nil
local isPaused = false
local loopEnabled = false
local currentSpeed = 1.0
local currentTab = "all"
local searchQuery = ""
local currentSort = "recentfirst"
local renderToken = 0

-- UI Pool Storage
local cardPool = {} 
local cardConnections = {}

-- ==================== LOAD & SAVE FAVORITES ====================
local function loadFavorites()
    if Storage and Storage.appSettings then
        Storage.appSettings.emoteFavorites = Storage.appSettings.emoteFavorites or {}
        Favorites = Storage.appSettings.emoteFavorites
        for i, v in ipairs(Favorites) do
            Favorites[i] = tonumber(v) or v
        end
        _G.EmoteCache.favorites = Favorites
    end
end

local function saveFavorites()
    if Storage and Storage.appSettings then
        Storage.appSettings.emoteFavorites = Favorites
        _G.EmoteCache.favorites = Favorites
        pcall(function()
            if Storage.persistSettings then Storage.persistSettings() end
        end)
    end
end

loadFavorites()

-- ==================== FETCH EMOTES ====================
local function fetchEmotePage(cursor)
    local url = "https://catalog.roblox.com/v1/search/items/details?"
        .. "Category=12&Subcategory=39&SortType=1&SortAggregation=&limit=30"
        .. "&IncludeNotForSale=true"
    if cursor and cursor ~= "" then
        url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
    end

    local ok, result = pcall(function()
        local opts = {Url = url, Method = "GET"}
        if syn and syn.request then return syn.request(opts)
        elseif http_request then return http_request(opts)
        elseif request then return request(opts)
        else return {Body = game:HttpGet(url)} end
    end)

    if not ok or not result or not result.Body then return nil end
    local dok, data = pcall(function() return HttpService:JSONDecode(result.Body) end)
    return dok and data or nil
end

local function fetchAllEmotes(maxPages)
    if isLoading() or isLoaded() then return end
    _G.EmoteCache.loading = true
    maxPages = maxPages or 50

    task.spawn(function()
        local cursor = ""
        local pages = 0

        while pages < maxPages do
            local page = fetchEmotePage(cursor)
            if not page or not page.data or #page.data == 0 then break end

            local newBatch = {}
            for _, item in ipairs(page.data) do
                if item.id and item.name and not IdSet[item.id] then
                    IdSet[item.id] = true
                    local emoteObj = {
                        id      = item.id,
                        name    = item.name,
                        price   = item.price or 0,
                        icon    = "rbxthumb://type=Asset&id=" .. item.id .. "&w=150&h=150",
                        updated = item.updated or "",
                    }
                    table.insert(Emotes, emoteObj)
                    table.insert(newBatch, emoteObj.icon)
                end
            end

            -- Preload Async Thumbnail secara tidak memblokir UI
            if #newBatch > 0 then
                task.spawn(function()
                    pcall(function() ContentProvider:PreloadAsync(newBatch) end)
                end)
            end

            cursor = page.nextPageCursor or ""
            pages = pages + 1

            if cursor == "" then break end
            task.wait(0.2) -- Micro-yield antar request HTTP
        end

        -- Fallback Emote Populer
        local popular = {
            {id = 5915773155, name = "Arm Wave"},
            {id = 5915779725, name = "Head Banging"},
            {id = 9830731012, name = "Face Calisthenics"},
            {id = 7832585357, name = "Floss"},
            {id = 7043924239, name = "Orange Justice"},
        }
        for _, p in ipairs(popular) do
            if not IdSet[p.id] then
                IdSet[p.id] = true
                table.insert(Emotes, {
                    id    = p.id,
                    name  = p.name,
                    price = 0,
                    icon  = "rbxthumb://type=Asset&id=" .. p.id .. "&w=150&h=150",
                    updated = "",
                })
            end
        end

        _G.EmoteCache.loaded = true
        _G.EmoteCache.loading = false

        if resultsContainer and resultsContainer.Parent then
            renderEmotes()
        end

        if _G.showDynamicNotification then
            _G.showDynamicNotification("📦 " .. #Emotes .. " emotes dimuat!", C.green)
        end
    end)
end

-- ==================== SORTING ====================
local function sortEmotes(list, sortType)
    local sorted = table.clone(list)
    if sortType == "recentfirst" then
        table.sort(sorted, function(a, b) return (a.updated or "") > (b.updated or "") end)
    elseif sortType == "alphabeticfirst" then
        table.sort(sorted, function(a, b) return a.name:lower() < b.name:lower() end)
    elseif sortType == "highestprice" then
        table.sort(sorted, function(a, b) return (a.price or 0) > (b.price or 0) end)
    elseif sortType == "lowestprice" then
        table.sort(sorted, function(a, b) return (a.price or 0) < (b.price or 0) end)
    end
    return sorted
end

-- ==================== ANIMATION ====================
local function stopAnimation()
    if currentAnimTrack then
        pcall(function() currentAnimTrack:Stop() end)
        currentAnimTrack = nil
        isPaused = false
    end
end

local function playEmote(assetId)
    stopAnimation()

    local char = LocalPlayer.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    if humanoid.RigType ~= Enum.HumanoidRigType.R15 then
        if _G.showDynamicNotification then _G.showDynamicNotification("Emote khusus R15", C.red) end
        return
    end

    local track = nil
    pcall(function()
        track = humanoid:PlayEmoteAndGetAnimTrackById(assetId)
    end)

    if not track then
        local desc = humanoid:FindFirstChildOfClass("HumanoidDescription")
        if desc then
            pcall(function()
                desc:AddEmote("Emote_" .. assetId, assetId)
                track = humanoid:PlayEmoteAndGetAnimTrackById(assetId)
            end)
        end
    end

    if track then
        currentAnimTrack = track
        track:AdjustSpeed(currentSpeed)
        track.Looped = loopEnabled
        track:Play()
        isPaused = false
    end
end

-- ==================== UI POOLING SYSTEM ====================
local function clearCardConnections(card)
    if cardConnections[card] then
        for _, conn in ipairs(cardConnections[card]) do
            conn:Disconnect()
        end
        table.clear(cardConnections[card])
    else
        cardConnections[card] = {}
    end
end

local function createPooledCard(parent)
    local card = Instance.new("Frame", parent)
    card.BackgroundColor3 = C.card
    card.BorderSizePixel = 0
    corner(card, 12)
    stroke(card, C.border, 1, 0.3)

    local cardGradient = Instance.new("UIGradient", card)
    cardGradient.Color = ColorSequence.new(Color3.fromRGB(30, 30, 40), Color3.fromRGB(18, 18, 26))
    cardGradient.Rotation = 45

    local thumb = Instance.new("ImageLabel", card)
    thumb.Name = "Thumb"
    thumb.Size = UDim2.new(1, 0, 0, 95)
    thumb.BackgroundColor3 = C.card2
    thumb.ScaleType = Enum.ScaleType.Crop
    thumb.BorderSizePixel = 0
    corner(thumb, 12)

    local favBtn = Instance.new("TextButton", card)
    favBtn.Name = "FavBtn"
    favBtn.Size = UDim2.new(0, 26, 0, 26)
    favBtn.Position = UDim2.new(1, -28, 0, 2)
    favBtn.BackgroundTransparency = 1
    favBtn.Font = Enum.Font.GothamBold
    favBtn.TextSize = 18
    favBtn.AutoButtonColor = false
    favBtn.ZIndex = 5

    local nameLbl = Instance.new("TextLabel", card)
    nameLbl.Name = "NameLbl"
    nameLbl.Size = UDim2.new(1, -8, 0, 18)
    nameLbl.Position = UDim2.new(0, 4, 0, 98)
    nameLbl.BackgroundTransparency = 1
    nameLbl.TextColor3 = C.text
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 10
    nameLbl.TextXAlignment = Enum.TextXAlignment.Center
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

    local priceLbl = Instance.new("TextLabel", card)
    priceLbl.Name = "PriceLbl"
    priceLbl.Size = UDim2.new(1, -8, 0, 14)
    priceLbl.Position = UDim2.new(0, 4, 0, 116)
    priceLbl.BackgroundTransparency = 1
    priceLbl.Font = Enum.Font.Gotham
    priceLbl.TextSize = 9
    priceLbl.TextXAlignment = Enum.TextXAlignment.Center

    local playBtn = Instance.new("TextButton", card)
    playBtn.Name = "PlayBtn"
    playBtn.Size = UDim2.new(1, -8, 0, 24)
    playBtn.Position = UDim2.new(0, 4, 0, 132)
    playBtn.BackgroundColor3 = C.accent2
    playBtn.Text = "▶ Play"
    playBtn.TextColor3 = Color3.new(1, 1, 1)
    playBtn.Font = Enum.Font.GothamBlack
    playBtn.TextSize = 11
    playBtn.AutoButtonColor = false
    corner(playBtn, 6)

    return card
end

local function updateCardData(card, emote, order, isFavorite)
    clearCardConnections(card)
    card.LayoutOrder = order
    card.Visible = true

    local thumb = card:FindFirstChild("Thumb")
    local favBtn = card:FindFirstChild("FavBtn")
    local nameLbl = card:FindFirstChild("NameLbl")
    local priceLbl = card:FindFirstChild("PriceLbl")
    local playBtn = card:FindFirstChild("PlayBtn")

    thumb.Image = emote.icon or ""
    nameLbl.Text = emote.name or "Emote"
    priceLbl.Text = (emote.price and emote.price > 0) and ("💰 " .. emote.price) or "Free"
    priceLbl.TextColor3 = (emote.price and emote.price > 0) and C.gold or C.green

    favBtn.Text = isFavorite and "★" or "☆"
    favBtn.TextColor3 = isFavorite and C.gold or C.text3

    local conns = cardConnections[card]

    table.insert(conns, favBtn.MouseButton1Click:Connect(function()
        local idx = table.find(Favorites, emote.id)
        if idx then
            table.remove(Favorites, idx)
            favBtn.Text = "☆"
            favBtn.TextColor3 = C.text3
        else
            table.insert(Favorites, emote.id)
            favBtn.Text = "★"
            favBtn.TextColor3 = C.gold
        end
        saveFavorites()
        if currentTab == "favorites" then renderEmotes() end
    end))

    table.insert(conns, playBtn.MouseButton1Click:Connect(function()
        playEmote(emote.id)
    end))

    table.insert(conns, card.MouseEnter:Connect(function()
        card.BackgroundColor3 = C.cardHover
    end))
    table.insert(conns, card.MouseLeave:Connect(function()
        card.BackgroundColor3 = C.card
    end))
end

-- ==================== RENDER UTAMA ====================
local resultsContainer = nil
local infoLbl = nil

function renderEmotes()
    local token = renderToken + 1
    renderToken = token

    if not resultsContainer then return end

    local filtered = {}
    local q = searchQuery:lower()

    for _, e in ipairs(Emotes) do
        local include = true
        if currentTab == "favorites" then
            include = table.find(Favorites, e.id) ~= nil
        elseif q ~= "" then
            include = e.name:lower():find(q, 1, true) ~= nil
        end
        if include then table.insert(filtered, e) end
    end

    local sorted = sortEmotes(filtered, currentSort)

    if infoLbl then
        infoLbl.Text = #sorted .. " emote" .. (#sorted ~= 1 and "s" or "")
    end

    -- Sembunyikan semua card di pool terlebih dahulu
    for _, card in ipairs(cardPool) do
        card.Visible = false
    end

    -- Staggered rendering (15 card / frame) agar 0 frame drop
    task.spawn(function()
        local batchSize = 15
        for idx, emote in ipairs(sorted) do
            if renderToken ~= token then return end -- Batalkan jika ada request render baru

            local card = cardPool[idx]
            if not card then
                card = createPooledCard(resultsContainer)
                table.insert(cardPool, card)
            end

            local isFav = table.find(Favorites, emote.id) ~= nil
            updateCardData(card, emote, idx, isFav)

            if idx % batchSize == 0 then
                task.wait() -- Micro-yield menjaga FPS tetap 60
            end
        end
    end)
end
_G.renderEmotesRefresh = renderEmotes

-- ==================== BUKA APP ====================
local function buildEmoteApp()
    if not appContent then return end

    local existingLayout = appContent:FindFirstChildOfClass("UIListLayout")
    if not existingLayout then
        local appLayout = Instance.new("UIListLayout", appContent)
        appLayout.Padding = UDim.new(0, 6)
        appLayout.SortOrder = Enum.SortOrder.LayoutOrder
    end

    -- Header
    local header = Instance.new("Frame", appContent)
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = C.card
    header.BorderSizePixel = 0
    header.LayoutOrder = 0
    corner(header, 12)

    local hTitle = Instance.new("TextLabel", header)
    hTitle.Size = UDim2.new(1, -20, 1, 0)
    hTitle.Position = UDim2.new(0, 10, 0, 0)
    hTitle.BackgroundTransparency = 1
    hTitle.Text = "💃 Emote Catalog"
    hTitle.TextColor3 = C.text
    hTitle.Font = Enum.Font.GothamBlack
    hTitle.TextSize = 14
    hTitle.TextXAlignment = Enum.TextXAlignment.Left

    -- Search Box
    local searchFrame = Instance.new("Frame", appContent)
    searchFrame.Size = UDim2.new(1, 0, 0, 32)
    searchFrame.BackgroundColor3 = C.card2
    searchFrame.BorderSizePixel = 0
    searchFrame.LayoutOrder = 1
    corner(searchFrame, 10)

    local searchBox = Instance.new("TextBox", searchFrame)
    searchBox.Size = UDim2.new(1, -20, 1, 0)
    searchBox.Position = UDim2.new(0, 10, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.PlaceholderText = "🔍 Cari emote..."
    searchBox.PlaceholderColor3 = C.text3
    searchBox.Text = searchQuery
    searchBox.TextColor3 = C.text
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 11
    searchBox.ClearTextOnFocus = false
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        searchQuery = searchBox.Text
        renderEmotes()
    end)

    -- Tab Bar
    local tabBar = Instance.new("Frame", appContent)
    tabBar.Size = UDim2.new(1, 0, 0, 32)
    tabBar.BackgroundTransparency = 1
    tabBar.LayoutOrder = 2

    local tabLayout = Instance.new("UIListLayout", tabBar)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 4)

    local tabs = {
        {id = "all", label = "📋 Semua"},
        {id = "favorites", label = "⭐ Favorit"},
    }

    local tabBtns = {}
    for i, tab in ipairs(tabs) do
        local btn = Instance.new("TextButton", tabBar)
        btn.Size = UDim2.new(0.5, -2, 1, 0)
        btn.BackgroundColor3 = (currentTab == tab.id) and C.accent or C.card
        btn.BorderSizePixel = 0
        btn.Text = tab.label
        btn.TextColor3 = (currentTab == tab.id) and Color3.new(1, 1, 1) or C.text2
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.AutoButtonColor = false
        corner(btn, 8)

        btn.MouseButton1Click:Connect(function()
            currentTab = tab.id
            for _, b in ipairs(tabBtns) do
                b.BackgroundColor3 = C.card
                b.TextColor3 = C.text2
            end
            btn.BackgroundColor3 = C.accent
            btn.TextColor3 = Color3.new(1, 1, 1)
            renderEmotes()
        end)
        tabBtns[i] = btn
    end

    -- Scrolling Grid Container
    resultsContainer = Instance.new("ScrollingFrame", appContent)
    resultsContainer.Size = UDim2.new(1, 0, 0, 280)
    resultsContainer.BackgroundColor3 = C.bg
    resultsContainer.BorderSizePixel = 0
    resultsContainer.ScrollBarThickness = 3
    resultsContainer.ScrollBarImageColor3 = C.accent
    resultsContainer.LayoutOrder = 3
    corner(resultsContainer, 12)

    -- Penggunaan Native UIGridLayout menggantikan pembuatan Row Manual
    local grid = Instance.new("UIGridLayout", resultsContainer)
    grid.CellSize = UDim2.new(0.32, -4, 0, 160)
    grid.CellPadding = UDim2.new(0.015, 0, 0, 6)
    grid.SortOrder = Enum.SortOrder.LayoutOrder

    local resPad = Instance.new("UIPadding", resultsContainer)
    resPad.PaddingTop = UDim.new(0, 6)
    resPad.PaddingBottom = UDim.new(0, 6)
    resPad.PaddingLeft = UDim.new(0, 6)
    resPad.PaddingRight = UDim.new(0, 6)

    grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        resultsContainer.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y + 12)
    end)

    -- Controls (Speed / Pause / Stop)
    local controls = Instance.new("Frame", appContent)
    controls.Size = UDim2.new(1, 0, 0, 36)
    controls.BackgroundColor3 = C.card2
    controls.BorderSizePixel = 0
    controls.LayoutOrder = 4
    corner(controls, 10)

    local cLayout = Instance.new("UIListLayout", controls)
    cLayout.FillDirection = Enum.FillDirection.Horizontal
    cLayout.Padding = UDim.new(0, 4)
    cLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    cLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local stopBtn = Instance.new("TextButton", controls)
    stopBtn.Size = UDim2.new(0, 60, 0, 24)
    stopBtn.BackgroundColor3 = C.red
    stopBtn.Text = "⏹ Stop"
    stopBtn.TextColor3 = Color3.new(1, 1, 1)
    stopBtn.Font = Enum.Font.GothamBold
    stopBtn.TextSize = 10
    corner(stopBtn, 6)
    stopBtn.MouseButton1Click:Connect(stopAnimation)

    renderEmotes()

    if not isLoaded() and not isLoading() then
        fetchAllEmotes(50)
    end

    return true
end

function _G.openEmoteApp()
    pcall(buildEmoteApp)
end

print("[Emote] Optimized Script Loaded Successfully!")
