-- ================================================
-- EMOTE.LUA — Light Theme (iOS Style) & JSON Cache
-- Fix: Layout Hancur, Tema Bentrok, Tab Bar Error
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

local function smoothTween(object, properties, duration)
    local tw = TweenService:Create(object, TweenInfo.new(duration or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
    tw:Play()
    return tw
end

local CACHE_FILE_NAME = "PhoneIDViewer_EmoteCache.json"

-- ==================== PALETTE (iOS LIGHT THEME) ====================
local C = {
    bg          = Color3.fromRGB(255, 255, 255), -- White Phone BG
    card        = Color3.fromRGB(255, 255, 255), -- Pure White Card
    cardHover   = Color3.fromRGB(245, 245, 248), -- Slight Grey Hover
    thumbBg     = Color3.fromRGB(242, 242, 247), -- Thumb Container
    searchBg    = Color3.fromRGB(238, 238, 240), -- iOS Search Gray
    border      = Color3.fromRGB(225, 225, 230), -- Soft Border
    textTitle   = Color3.fromRGB(28, 28, 30),    -- iOS Black Text
    textDesc    = Color3.fromRGB(142, 142, 147), -- iOS Gray Text
    accent      = Color3.fromRGB(0, 122, 255),   -- iOS Blue
    accentHover = Color3.fromRGB(0, 100, 230),
    gold        = Color3.fromRGB(255, 179, 64),
    redBtn      = Color3.fromRGB(255, 59, 48),   -- iOS Red
    redHover    = Color3.fromRGB(220, 40, 40),
}

-- ==================== CACHE GLOBAL ====================
_G.EmoteCache = _G.EmoteCache or {
    emotes = {}, favorites = {}, idSet = {}, loaded = false, loading = false,
}

local Emotes = _G.EmoteCache.emotes
local Favorites = _G.EmoteCache.favorites
local IdSet = _G.EmoteCache.idSet

local currentAnimTrack = nil
local currentSpeed = 1.0
local loopEnabled = false
local currentTab = "all"
local searchQuery = ""
local renderToken = 0

local cardPool = {} 
local cardConnections = {}

-- ==================== JSON & FAVORITES ====================
local function loadEmotesFromDisk()
    if isfile and isfile(CACHE_FILE_NAME) then
        local success, result = pcall(function() return HttpService:JSONDecode(readfile(CACHE_FILE_NAME)) end)
        if success and type(result) == "table" and #result > 0 then
            table.clear(Emotes); table.clear(IdSet)
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
        pcall(function() if Storage.persistSettings then Storage.persistSettings() end end)
    end
end
loadFavorites()

-- ==================== FETCH API ====================
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
    maxPages = maxPages or 30

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

-- ==================== CARDS & UI POOLING ====================
local function clearCardConnections(cardWrapper)
    if cardConnections[cardWrapper] then
        for _, conn in ipairs(cardConnections[cardWrapper]) do conn:Disconnect() end
        table.clear(cardConnections[cardWrapper])
    else
        cardConnections[cardWrapper] = {}
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
    corner(card, 10)
    stroke(card, C.border, 1, 0) -- Clean border

    local thumbWrap = Instance.new("Frame", card)
    thumbWrap.Size = UDim2.new(1, -12, 0, 80)
    thumbWrap.Position = UDim2.new(0, 6, 0, 6)
    thumbWrap.BackgroundColor3 = C.thumbBg
    corner(thumbWrap, 8)

    local thumb = Instance.new("ImageLabel", thumbWrap)
    thumb.Name = "Thumb"
    thumb.Size = UDim2.new(1, 0, 1, 0)
    thumb.BackgroundTransparency = 1
    thumb.ScaleType = Enum.ScaleType.Crop
    corner(thumb, 8)

    local favBtn = Instance.new("TextButton", card)
    favBtn.Name = "FavBtn"
    favBtn.Size = UDim2.new(0, 24, 0, 24)
    favBtn.Position = UDim2.new(1, -30, 0, 8)
    favBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    favBtn.BackgroundTransparency = 0.2
    favBtn.Font = Enum.Font.GothamBold
    favBtn.TextSize = 14
    favBtn.AutoButtonColor = false
    favBtn.ZIndex = 2
    corner(favBtn, 12)
    stroke(favBtn, C.border, 1, 0)

    local nameLbl = Instance.new("TextLabel", card)
    nameLbl.Name = "NameLbl"
    nameLbl.Size = UDim2.new(1, -12, 0, 16)
    nameLbl.Position = UDim2.new(0, 6, 0, 92)
    nameLbl.BackgroundTransparency = 1
    nameLbl.TextColor3 = C.textTitle
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 10
    nameLbl.TextXAlignment = Enum.TextXAlignment.Center
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

    local playBtn = Instance.new("TextButton", card)
    playBtn.Name = "PlayBtn"
    playBtn.Size = UDim2.new(1, -12, 0, 24)
    playBtn.Position = UDim2.new(0, 6, 0, 114)
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
    card.Thumb.Parent.Thumb.Image = emote.icon or ""
    card.NameLbl.Text = emote.name or "Emote"
    
    local favBtn = card.FavBtn
    local playBtn = card.PlayBtn

    favBtn.Text = isFavorite and "★" or "☆"
    favBtn.TextColor3 = isFavorite and C.gold or C.textDesc

    local conns = cardConnections[cardWrapper]

    table.insert(conns, card.MouseEnter:Connect(function() smoothTween(card, {Size = UDim2.new(1.03, 0, 1.03, 0), BackgroundColor3 = C.cardHover}, 0.1) end))
    table.insert(conns, card.MouseLeave:Connect(function() smoothTween(card, {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = C.card}, 0.1) end))

    table.insert(conns, favBtn.MouseButton1Click:Connect(function()
        smoothTween(favBtn, {Size = UDim2.new(0, 28, 0, 28)}, 0.1)
        task.wait(0.1)
        smoothTween(favBtn, {Size = UDim2.new(0, 24, 0, 24)}, 0.1)

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

    table.insert(conns, playBtn.MouseButton1Down:Connect(function() smoothTween(playBtn, {BackgroundColor3 = C.accentHover}, 0.1) end))
    table.insert(conns, playBtn.MouseButton1Up:Connect(function() smoothTween(playBtn, {BackgroundColor3 = C.accent}, 0.1); playEmote(emote.id) end))
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
            updateCardData(card, emote, idx, table.find(Favorites, emote.id) ~= nil)
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
        appLayout.Padding = UDim.new(0, 10)
        appLayout.SortOrder = Enum.SortOrder.LayoutOrder
    end

    -- Search Bar (Pill Shape)
    local searchFrame = Instance.new("Frame", appContent)
    searchFrame.Size = UDim2.new(1, 0, 0, 36)
    searchFrame.BackgroundColor3 = C.searchBg
    searchFrame.BorderSizePixel = 0
    searchFrame.LayoutOrder = 1
    corner(searchFrame, 18)

    local searchIcon = Instance.new("TextLabel", searchFrame)
    searchIcon.Size = UDim2.new(0, 34, 1, 0)
    searchIcon.Position = UDim2.new(0, 4, 0, 0)
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

    -- Native iOS Segmented Control
    local tabWrap = Instance.new("Frame", appContent)
    tabWrap.Size = UDim2.new(1, 0, 0, 32)
    tabWrap.BackgroundColor3 = C.searchBg
    tabWrap.LayoutOrder = 2
    corner(tabWrap, 8)

    local tabLayout = Instance.new("UIListLayout", tabWrap)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    local tabPad = Instance.new("UIPadding", tabWrap)
    tabPad.PaddingTop = UDim.new(0, 2); tabPad.PaddingBottom = UDim.new(0, 2)
    tabPad.PaddingLeft = UDim.new(0, 2); tabPad.PaddingRight = UDim.new(0, 2)

    local btnAll = Instance.new("TextButton", tabWrap)
    btnAll.Size = UDim2.new(0.5, -1, 1, 0)
    btnAll.BackgroundColor3 = currentTab == "all" and C.bg or C.searchBg
    btnAll.BackgroundTransparency = currentTab == "all" and 0 or 1
    btnAll.Text = "Semua"
    btnAll.TextColor3 = C.textTitle
    btnAll.Font = Enum.Font.GothamBold
    btnAll.TextSize = 12
    corner(btnAll, 6)
    if currentTab == "all" then stroke(btnAll, Color3.fromRGB(0,0,0), 1, 0.9) end

    local btnFav = Instance.new("TextButton", tabWrap)
    btnFav.Size = UDim2.new(0.5, 0, 1, 0)
    btnFav.BackgroundColor3 = currentTab == "favorites" and C.bg or C.searchBg
    btnFav.BackgroundTransparency = currentTab == "favorites" and 0 or 1
    btnFav.Text = "Favorit ⭐"
    btnFav.TextColor3 = C.textTitle
    btnFav.Font = Enum.Font.GothamBold
    btnFav.TextSize = 12
    corner(btnFav, 6)
    if currentTab == "favorites" then stroke(btnFav, Color3.fromRGB(0,0,0), 1, 0.9) end

    local function updateTabs()
        btnAll.BackgroundTransparency = currentTab == "all" and 0 or 1
        btnFav.BackgroundTransparency = currentTab == "favorites" and 0 or 1
        
        -- Clean up old strokes
        local s1 = btnAll:FindFirstChildOfClass("UIStroke")
        if s1 then s1:Destroy() end
        local s2 = btnFav:FindFirstChildOfClass("UIStroke")
        if s2 then s2:Destroy() end
        
        -- Add shadow to active
        if currentTab == "all" then stroke(btnAll, Color3.fromRGB(0,0,0), 1, 0.9) end
        if currentTab == "favorites" then stroke(btnFav, Color3.fromRGB(0,0,0), 1, 0.9) end
    end

    btnAll.MouseButton1Click:Connect(function()
        if currentTab == "all" then return end
        currentTab = "all"; updateTabs(); renderEmotes()
    end)
    btnFav.MouseButton1Click:Connect(function()
        if currentTab == "favorites" then return end
        currentTab = "favorites"; updateTabs(); renderEmotes()
    end)

    -- Scroll Grid Container
    resultsContainer = Instance.new("ScrollingFrame", appContent)
    resultsContainer.Size = UDim2.new(1, 0, 0, 245)
    resultsContainer.BackgroundTransparency = 1
    resultsContainer.BorderSizePixel = 0
    resultsContainer.ScrollBarThickness = 2
    resultsContainer.ScrollBarImageColor3 = C.border
    resultsContainer.LayoutOrder = 3

    local grid = Instance.new("UIGridLayout", resultsContainer)
    grid.CellSize = UDim2.new(0.31, 0, 0, 144)
    grid.CellPadding = UDim2.new(0.035, 0, 0, 8)
    grid.SortOrder = Enum.SortOrder.LayoutOrder

    local resPad = Instance.new("UIPadding", resultsContainer)
    resPad.PaddingTop = UDim.new(0, 2)
    resPad.PaddingBottom = UDim.new(0, 10)

    grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        resultsContainer.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y + 20)
    end)

    -- Stop Emote Button
    local stopBtnWrap = Instance.new("Frame", appContent)
    stopBtnWrap.Size = UDim2.new(1, 0, 0, 42)
    stopBtnWrap.BackgroundTransparency = 1
    stopBtnWrap.LayoutOrder = 4

    local stopBtn = Instance.new("TextButton", stopBtnWrap)
    stopBtn.Size = UDim2.new(1, 0, 1, -4)
    stopBtn.Position = UDim2.new(0, 0, 0, 2)
    stopBtn.BackgroundColor3 = C.redBtn
    stopBtn.Text = "⏹ Hentikan Emote"
    stopBtn.TextColor3 = Color3.new(1, 1, 1)
    stopBtn.Font = Enum.Font.GothamBold
    stopBtn.TextSize = 13
    stopBtn.AutoButtonColor = false
    corner(stopBtn, 8)

    stopBtn.MouseButton1Down:Connect(function() smoothTween(stopBtn, {BackgroundColor3 = C.redHover}, 0.1) end)
    stopBtn.MouseButton1Up:Connect(function() smoothTween(stopBtn, {BackgroundColor3 = C.redBtn}, 0.1); stopAnimation() end)
    stopBtn.MouseLeave:Connect(function() smoothTween(stopBtn, {BackgroundColor3 = C.redBtn}, 0.1) end)

    renderEmotes()
    if #Emotes == 0 or not isLoaded() then fetchAllEmotes(30) end
    return true
end

function _G.openEmoteApp() pcall(buildEmoteApp) end
print("[Emote] Light Theme Applied Successfully!")
