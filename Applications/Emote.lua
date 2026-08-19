-- ================================================
-- EMOTE.LUA — Ultimate UI/UX Edition & JSON Cache
-- Modern Sleek Design | Tween Animations | Zero Lag
-- ================================================

local Services    = _G.Services or {}
local LocalPlayer = _G.LocalPlayer
local Helpers     = _G.Helpers or {}
local Storage     = _G.Storage or {}
local appContent  = _G.appContent

local HttpService = Services.HttpService or game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

local corner  = Helpers.corner  or function(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 10); c.Parent = o; return c end
local stroke  = Helpers.stroke  or function(o, c, t, tr) local s = Instance.new("UIStroke"); s.Color = c or Color3.fromRGB(80,80,80); s.Thickness = t or 1; s.Transparency = tr or 0; s.Parent = o; return s end

-- Helper Animasi Tween
local function smoothTween(object, properties, duration)
    local tw = TweenService:Create(object, TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
    tw:Play()
    return tw
end

local function addClickEffect(button)
    button.MouseButton1Down:Connect(function() smoothTween(button, {Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset - 4, button.Size.Y.Scale, button.Size.Y.Offset - 4)}, 0.1) end)
    button.MouseButton1Up:Connect(function() smoothTween(button, {Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset + 4, button.Size.Y.Scale, button.Size.Y.Offset + 4)}, 0.1) end)
    button.MouseLeave:Connect(function() smoothTween(button, {Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset, button.Size.Y.Scale, button.Size.Y.Offset)}, 0.1) end)
end

-- ==================== FILE & PATH CONSTANTS ====================
local CACHE_FILE_NAME = "PhoneIDViewer_EmoteCache.json"

-- ==================== PALETTE (MODERN DARK THEME) ====================
local C = {
    bg          = Color3.fromRGB(15, 16, 21),    -- Main background
    card        = Color3.fromRGB(26, 28, 35),    -- Card background
    cardHover   = Color3.fromRGB(36, 39, 48),    -- Card hover
    searchBg    = Color3.fromRGB(22, 24, 30),    -- Search bar
    border      = Color3.fromRGB(55, 60, 75),    -- Borders
    textTitle   = Color3.fromRGB(255, 255, 255), -- White
    textDesc    = Color3.fromRGB(170, 175, 190), -- Gray text
    accent      = Color3.fromRGB(90, 110, 255),  -- Soft Blue
    accentHover = Color3.fromRGB(110, 130, 255), -- Lighter Blue
    gold        = Color3.fromRGB(255, 200, 50),  -- Star Yellow
    greenBtn    = Color3.fromRGB(10, 180, 110),  -- Play Button Green
    redBtn      = Color3.fromRGB(255, 75, 75),   -- Stop Button Red
}

-- ==================== CACHE GLOBAL ====================
_G.EmoteCache = _G.EmoteCache or {
    emotes = {},
    favorites = {},
    idSet = {},
    loaded = false,
    loading = false,
}

local Emotes = _G.EmoteCache.emotes
local Favorites = _G.EmoteCache.favorites
local IdSet = _G.EmoteCache.idSet

-- ==================== STATE ====================
local currentAnimTrack = nil
local currentSpeed = 1.0
local loopEnabled = false
local currentTab = "all"
local searchQuery = ""
local currentSort = "recentfirst"
local renderToken = 0

local cardPool = {} 
local cardConnections = {}

-- ==================== JSON FILE I/O ====================
local function loadEmotesFromDisk()
    if isfile and isfile(CACHE_FILE_NAME) then
        local success, result = pcall(function() return HttpService:JSONDecode(readfile(CACHE_FILE_NAME)) end)
        if success and type(result) == "table" and #result > 0 then
            table.clear(Emotes)
            table.clear(IdSet)
            for _, item in ipairs(result) do
                if item.id then table.insert(Emotes, item); IdSet[item.id] = true end
            end
            _G.EmoteCache.loaded = true
            return true
        end
    end
    return false
end

local function saveEmotesToDisk()
    if writefile and #Emotes > 0 then
        pcall(function() writefile(CACHE_FILE_NAME, HttpService:JSONEncode(Emotes)) end)
    end
end
loadEmotesFromDisk()

-- ==================== LOAD & SAVE FAVORITES ====================
local function loadFavorites()
    if Storage and Storage.appSettings then
        Storage.appSettings.emoteFavorites = Storage.appSettings.emoteFavorites or {}
        Favorites = Storage.appSettings.emoteFavorites
        for i, v in ipairs(Favorites) do Favorites[i] = tonumber(v) or v end
        _G.EmoteCache.favorites = Favorites
    end
end

local function saveFavorites()
    if Storage and Storage.appSettings then
        Storage.appSettings.emoteFavorites = Favorites
        _G.EmoteCache.favorites = Favorites
        pcall(function() if Storage.persistSettings then Storage.persistSettings() end end)
    end
end
loadFavorites()

-- ==================== FETCH NEW EMOTES ====================
local function fetchEmotePage(cursor)
    local url = "https://catalog.roblox.com/v1/search/items/details?Category=12&Subcategory=39&SortType=1&SortAggregation=&limit=30&IncludeNotForSale=true"
    if cursor and cursor ~= "" then url = url .. "&cursor=" .. HttpService:UrlEncode(cursor) end
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
    if _G.EmoteCache.loading then return end
    _G.EmoteCache.loading = true
    maxPages = maxPages or 50

    task.spawn(function()
        local cursor = ""
        local pages = 0
        local newItemsAdded = false

        while pages < maxPages do
            local page = fetchEmotePage(cursor)
            if not page or not page.data or #page.data == 0 then break end
            local newBatch = {}
            for _, item in ipairs(page.data) do
                if item.id and item.name and not IdSet[item.id] then
                    IdSet[item.id] = true
                    newItemsAdded = true
                    local emoteObj = { id = item.id, name = item.name, icon = "rbxthumb://type=Asset&id=" .. item.id .. "&w=150&h=150", updated = item.updated or "" }
                    table.insert(Emotes, emoteObj)
                    table.insert(newBatch, emoteObj.icon)
                end
            end
            if #newBatch > 0 then task.spawn(function() pcall(function() ContentProvider:PreloadAsync(newBatch) end) end) end
            cursor = page.nextPageCursor or ""
            pages = pages + 1
            if cursor == "" then break end
            task.wait(0.2)
        end

        _G.EmoteCache.loaded = true
        _G.EmoteCache.loading = false
        if newItemsAdded then saveEmotesToDisk() end
        if _G.renderEmotesRefresh then _G.renderEmotesRefresh() end
    end)
end

-- ==================== ANIMATION ====================
local function stopAnimation()
    if currentAnimTrack then
        pcall(function() currentAnimTrack:Stop() end)
        currentAnimTrack = nil
    end
end

local function playEmote(assetId)
    stopAnimation()
    local char = LocalPlayer.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local track = nil
    pcall(function() track = humanoid:PlayEmoteAndGetAnimTrackById(assetId) end)
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
    end
end

-- ==================== UI POOLING & CARDS ====================
local function clearCardConnections(card)
    if cardConnections[card] then
        for _, conn in ipairs(cardConnections[card]) do conn:Disconnect() end
        table.clear(cardConnections[card])
    else
        cardConnections[card] = {}
    end
end

local function createPooledCard(parent)
    local cardWrapper = Instance.new("Frame", parent)
    cardWrapper.BackgroundTransparency = 1
    
    local card = Instance.new("Frame", cardWrapper)
    card.Size = UDim2.new(1, 0, 1, 0)
    card.Position = UDim2.new(0.5, 0, 0.5, 0)
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.BackgroundColor3 = C.card
    card.BorderSizePixel = 0
    corner(card, 12)
    stroke(card, C.border, 1, 0.5)

    -- Thumbnail Wrapper
    local thumbWrap = Instance.new("Frame", card)
    thumbWrap.Size = UDim2.new(1, -10, 0, 85)
    thumbWrap.Position = UDim2.new(0, 5, 0, 5)
    thumbWrap.BackgroundColor3 = C.bg
    corner(thumbWrap, 8)

    local thumb = Instance.new("ImageLabel", thumbWrap)
    thumb.Name = "Thumb"
    thumb.Size = UDim2.new(1, 0, 1, 0)
    thumb.BackgroundTransparency = 1
    thumb.ScaleType = Enum.ScaleType.Crop
    corner(thumb, 8)

    -- Favorite Button (Floating on thumbnail)
    local favBtn = Instance.new("TextButton", card)
    favBtn.Name = "FavBtn"
    favBtn.Size = UDim2.new(0, 28, 0, 28)
    favBtn.Position = UDim2.new(1, -33, 0, 8)
    favBtn.BackgroundColor3 = Color3.fromRGB(0,0,0)
    favBtn.BackgroundTransparency = 0.6
    favBtn.Font = Enum.Font.GothamBold
    favBtn.TextSize = 16
    favBtn.AutoButtonColor = false
    favBtn.ZIndex = 2
    corner(favBtn, 14) -- Round perfect circle

    local nameLbl = Instance.new("TextLabel", card)
    nameLbl.Name = "NameLbl"
    nameLbl.Size = UDim2.new(1, -12, 0, 16)
    nameLbl.Position = UDim2.new(0, 6, 0, 96)
    nameLbl.BackgroundTransparency = 1
    nameLbl.TextColor3 = C.textTitle
    nameLbl.Font = Enum.Font.GothamMedium
    nameLbl.TextSize = 11
    nameLbl.TextXAlignment = Enum.TextXAlignment.Center
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

    local playBtn = Instance.new("TextButton", card)
    playBtn.Name = "PlayBtn"
    playBtn.Size = UDim2.new(1, -12, 0, 26)
    playBtn.Position = UDim2.new(0, 6, 0, 118)
    playBtn.BackgroundColor3 = C.accent
    playBtn.Text = "▶ Play"
    playBtn.TextColor3 = Color3.new(1, 1, 1)
    playBtn.Font = Enum.Font.GothamBold
    playBtn.TextSize = 11
    playBtn.AutoButtonColor = false
    corner(playBtn, 6)

    return cardWrapper
end

local function updateCardData(cardWrapper, emote, order, isFavorite)
    clearCardConnections(cardWrapper)
    cardWrapper.LayoutOrder = order
    cardWrapper.Visible = true

    local card = cardWrapper:FindFirstChildOfClass("Frame")
    local thumb = card.Frame.Thumb
    local favBtn = card.FavBtn
    local nameLbl = card.NameLbl
    local playBtn = card.PlayBtn

    thumb.Image = emote.icon or ""
    nameLbl.Text = emote.name or "Emote"
    favBtn.Text = isFavorite and "★" or "☆"
    favBtn.TextColor3 = isFavorite and C.gold or C.textDesc

    local conns = cardConnections[cardWrapper]

    -- Hover Animation Card
    table.insert(conns, card.MouseEnter:Connect(function()
        smoothTween(card, {Size = UDim2.new(1.05, 0, 1.05, 0), BackgroundColor3 = C.cardHover}, 0.15)
        smoothTween(playBtn, {BackgroundColor3 = C.accentHover}, 0.15)
    end))
    table.insert(conns, card.MouseLeave:Connect(function()
        smoothTween(card, {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = C.card}, 0.15)
        smoothTween(playBtn, {BackgroundColor3 = C.accent}, 0.15)
    end))

    -- Favorite Click
    table.insert(conns, favBtn.MouseButton1Click:Connect(function()
        smoothTween(favBtn, {Size = UDim2.new(0, 32, 0, 32)}, 0.1)
        task.wait(0.1)
        smoothTween(favBtn, {Size = UDim2.new(0, 28, 0, 28)}, 0.1)

        local idx = table.find(Favorites, emote.id)
        if idx then
            table.remove(Favorites, idx)
            favBtn.Text = "☆"; favBtn.TextColor3 = C.textDesc
        else
            table.insert(Favorites, emote.id)
            favBtn.Text = "★"; favBtn.TextColor3 = C.gold
        end
        saveFavorites()
        if currentTab == "favorites" and _G.renderEmotesRefresh then _G.renderEmotesRefresh() end
    end))

    -- Play Click
    table.insert(conns, playBtn.MouseButton1Down:Connect(function() smoothTween(playBtn, {BackgroundColor3 = C.greenBtn}, 0.1) end))
    table.insert(conns, playBtn.MouseButton1Up:Connect(function() smoothTween(playBtn, {BackgroundColor3 = C.accentHover}, 0.1); playEmote(emote.id) end))
    table.insert(conns, playBtn.MouseLeave:Connect(function() smoothTween(playBtn, {BackgroundColor3 = C.accent}, 0.1) end))
end

-- ==================== RENDER ENGINE ====================
local resultsContainer = nil

local function renderEmotes()
    local token = renderToken + 1
    renderToken = token

    if not resultsContainer or not resultsContainer.Parent then return end

    local filtered = {}
    local q = searchQuery:lower()
    for _, e in ipairs(Emotes) do
        local include = true
        if currentTab == "favorites" then include = table.find(Favorites, e.id) ~= nil
        elseif q ~= "" then include = e.name:lower():find(q, 1, true) ~= nil end
        if include then table.insert(filtered, e) end
    end

    table.sort(filtered, function(a, b) return (a.updated or "") > (b.updated or "") end)

    for _, card in ipairs(cardPool) do card.Visible = false end

    task.spawn(function()
        local batchSize = 15
        for idx, emote in ipairs(filtered) do
            if renderToken ~= token then return end
            local card = cardPool[idx]
            if not card or not card.Parent then
                card = createPooledCard(resultsContainer)
                cardPool[idx] = card
            end
            local isFav = table.find(Favorites, emote.id) ~= nil
            updateCardData(card, emote, idx, isFav)
            if idx % batchSize == 0 then task.wait() end
        end
    end)
end
_G.renderEmotesRefresh = renderEmotes

-- ==================== APP BUILDER ====================
local function buildEmoteApp()
    if not appContent then return end

    table.clear(cardPool)
    table.clear(cardConnections)

    local existingLayout = appContent:FindFirstChildOfClass("UIListLayout")
    if not existingLayout then
        local appLayout = Instance.new("UIListLayout", appContent)
        appLayout.Padding = UDim.new(0, 8)
        appLayout.SortOrder = Enum.SortOrder.LayoutOrder
    end

    -- Title
    local titleLbl = Instance.new("TextLabel", appContent)
    titleLbl.Size = UDim2.new(1, 0, 0, 24)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "🕺 Emote Catalog"
    titleLbl.TextColor3 = C.textTitle
    titleLbl.Font = Enum.Font.GothamBlack
    titleLbl.TextSize = 16
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.LayoutOrder = 1

    -- Search Bar (Pill Shape)
    local searchFrame = Instance.new("Frame", appContent)
    searchFrame.Size = UDim2.new(1, 0, 0, 36)
    searchFrame.BackgroundColor3 = C.searchBg
    searchFrame.BorderSizePixel = 0
    searchFrame.LayoutOrder = 2
    corner(searchFrame, 18) -- Fully rounded
    stroke(searchFrame, C.border, 1, 0.4)

    local searchIcon = Instance.new("TextLabel", searchFrame)
    searchIcon.Size = UDim2.new(0, 30, 1, 0)
    searchIcon.Position = UDim2.new(0, 6, 0, 0)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Text = "🔍"
    searchIcon.TextSize = 14

    local searchBox = Instance.new("TextBox", searchFrame)
    searchBox.Size = UDim2.new(1, -40, 1, 0)
    searchBox.Position = UDim2.new(0, 34, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.PlaceholderText = "Cari gaya emote..."
    searchBox.PlaceholderColor3 = C.textDesc
    searchBox.Text = searchQuery
    searchBox.TextColor3 = C.textTitle
    searchBox.Font = Enum.Font.GothamMedium
    searchBox.TextSize = 12
    searchBox.ClearTextOnFocus = false
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        searchQuery = searchBox.Text
        renderEmotes()
    end)

    -- Segmented Tab Bar
    local tabWrap = Instance.new("Frame", appContent)
    tabWrap.Size = UDim2.new(1, 0, 0, 34)
    tabWrap.BackgroundColor3 = C.card
    tabWrap.LayoutOrder = 3
    corner(tabWrap, 8)
    stroke(tabWrap, C.border, 1, 0.5)

    local indicator = Instance.new("Frame", tabWrap)
    indicator.Size = UDim2.new(0.5, -4, 1, -6)
    indicator.Position = currentTab == "all" and UDim2.new(0, 3, 0, 3) or UDim2.new(0.5, 1, 0, 3)
    indicator.BackgroundColor3 = C.accent
    corner(indicator, 6)

    local tabLayout = Instance.new("UIListLayout", tabWrap)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local btnAll = Instance.new("TextButton", tabWrap)
    btnAll.Size = UDim2.new(0.5, 0, 1, 0)
    btnAll.BackgroundTransparency = 1
    btnAll.Text = "Semua"
    btnAll.TextColor3 = currentTab == "all" and C.textTitle or C.textDesc
    btnAll.Font = Enum.Font.GothamBold
    btnAll.TextSize = 12
    btnAll.ZIndex = 2

    local btnFav = Instance.new("TextButton", tabWrap)
    btnFav.Size = UDim2.new(0.5, 0, 1, 0)
    btnFav.BackgroundTransparency = 1
    btnFav.Text = "Favorit ⭐"
    btnFav.TextColor3 = currentTab == "favorites" and C.textTitle or C.textDesc
    btnFav.Font = Enum.Font.GothamBold
    btnFav.TextSize = 12
    btnFav.ZIndex = 2

    btnAll.MouseButton1Click:Connect(function()
        if currentTab == "all" then return end
        currentTab = "all"
        smoothTween(indicator, {Position = UDim2.new(0, 3, 0, 3)}, 0.2)
        smoothTween(btnAll, {TextColor3 = C.textTitle}, 0.2)
        smoothTween(btnFav, {TextColor3 = C.textDesc}, 0.2)
        renderEmotes()
    end)

    btnFav.MouseButton1Click:Connect(function()
        if currentTab == "favorites" then return end
        currentTab = "favorites"
        smoothTween(indicator, {Position = UDim2.new(0.5, 1, 0, 3)}, 0.2)
        smoothTween(btnFav, {TextColor3 = C.textTitle}, 0.2)
        smoothTween(btnAll, {TextColor3 = C.textDesc}, 0.2)
        renderEmotes()
    end)

    -- Scroll Grid Container
    resultsContainer = Instance.new("ScrollingFrame", appContent)
    resultsContainer.Size = UDim2.new(1, 0, 0, 240)
    resultsContainer.BackgroundColor3 = C.bg
    resultsContainer.BackgroundTransparency = 1
    resultsContainer.BorderSizePixel = 0
    resultsContainer.ScrollBarThickness = 2
    resultsContainer.ScrollBarImageColor3 = C.accent
    resultsContainer.LayoutOrder = 4

    local grid = Instance.new("UIGridLayout", resultsContainer)
    grid.CellSize = UDim2.new(0.31, 0, 0, 150)
    grid.CellPadding = UDim2.new(0.035, 0, 0, 10)
    grid.SortOrder = Enum.SortOrder.LayoutOrder

    local resPad = Instance.new("UIPadding", resultsContainer)
    resPad.PaddingTop = UDim.new(0, 2)
    resPad.PaddingBottom = UDim.new(0, 10)

    grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        resultsContainer.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y + 20)
    end)

    -- Stop Emote Button (Sticky Bottom)
    local stopBtnWrap = Instance.new("Frame", appContent)
    stopBtnWrap.Size = UDim2.new(1, 0, 0, 38)
    stopBtnWrap.BackgroundTransparency = 1
    stopBtnWrap.LayoutOrder = 5

    local stopBtn = Instance.new("TextButton", stopBtnWrap)
    stopBtn.Size = UDim2.new(1, 0, 1, 0)
    stopBtn.BackgroundColor3 = C.redBtn
    stopBtn.Text = "⏹ Hentikan Emote"
    stopBtn.TextColor3 = Color3.new(1, 1, 1)
    stopBtn.Font = Enum.Font.GothamBold
    stopBtn.TextSize = 13
    stopBtn.AutoButtonColor = false
    corner(stopBtn, 8)
    
    local stopGradient = Instance.new("UIGradient", stopBtn)
    stopGradient.Color = ColorSequence.new(Color3.fromRGB(255, 100, 100), C.redBtn)
    stopGradient.Rotation = 90

    stopBtn.MouseButton1Down:Connect(function() smoothTween(stopBtn, {Size = UDim2.new(0.96, 0, 0.9, 0), Position = UDim2.new(0.02, 0, 0.05, 0)}, 0.1) end)
    stopBtn.MouseButton1Up:Connect(function() smoothTween(stopBtn, {Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0)}, 0.1); stopAnimation() end)
    stopBtn.MouseLeave:Connect(function() smoothTween(stopBtn, {Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0)}, 0.1) end)

    renderEmotes()

    if #Emotes == 0 or not isLoaded() then fetchAllEmotes(50) end
    return true
end

function _G.openEmoteApp() pcall(buildEmoteApp) end
print("[Emote] UI/UX Upgrade Edition Loaded!")
