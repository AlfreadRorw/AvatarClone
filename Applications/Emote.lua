-- ================================================
-- EMOTE.LUA — Purple Glass Theme (matches reference UI)
-- Fix: isLoaded() nil call bug, favorites tab, search bar
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
local stroke  = Helpers.stroke  or function(o, c, t, tr) local s = Instance.new("UIStroke"); s.Color = c or Color3.fromRGB(0,0,0); s.Thickness = t or 1; s.Transparency = tr or 0; s.Parent = o; return s end
local gradient = function(o, colorSeq, rotation)
    local g = Instance.new("UIGradient")
    g.Color = colorSeq
    g.Rotation = rotation or 90
    g.Parent = o
    return g
end

local function smoothTween(object, properties, duration)
    local tw = TweenService:Create(object, TweenInfo.new(duration or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
    tw:Play()
    return tw
end

local CACHE_FILE_NAME = "PhoneIDViewer_EmoteCache.json"

-- ==================== PALETTE (PURPLE GLASS) ====================
local C = {
    white       = Color3.fromRGB(255, 255, 255),
    black       = Color3.fromRGB(0, 0, 0),
    bg          = Color3.fromRGB(247, 244, 253),   -- background phone lavender-putih
    cardBg      = Color3.fromRGB(38, 20, 58),      -- ungu gelap kartu
    cardBg2     = Color3.fromRGB(58, 32, 90),
    purple      = Color3.fromRGB(124, 58, 237),    -- ungu utama (tab aktif, judul)
    purpleLight = Color3.fromRGB(167, 120, 244),
    purpleDeep  = Color3.fromRGB(88, 40, 170),
    textDark    = Color3.fromRGB(30, 20, 45),
    textGray    = Color3.fromRGB(140, 130, 155),
    star        = Color3.fromRGB(255, 255, 255),
}

-- ==================== CACHE GLOBAL ====================
_G.EmoteCache = _G.EmoteCache or {
    emotes = {}, favorites = {}, idSet = {}, loaded = false, loading = false,
}

local Emotes = _G.EmoteCache.emotes
local Favorites = _G.EmoteCache.favorites
local IdSet = _G.EmoteCache.idSet

-- FIX: isLoaded/isLoading harus baca langsung dari _G.EmoteCache (bukan
-- variabel lokal yang di-snapshot), supaya status fetch selalu akurat
-- walau script di-load ulang atau closure async lain yang mengubahnya.
local function isLoaded() return _G.EmoteCache.loaded end
local function isLoading() return _G.EmoteCache.loading end

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
    if isLoading() then return end
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
local function playEmote(assetId)
    if currentAnimTrack then
        pcall(function() currentAnimTrack:Stop() end)
        currentAnimTrack = nil
    end
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
    card.Name = "Card"
    card.Size = UDim2.new(1, 0, 1, 0)
    card.Position = UDim2.new(0.5, 0, 0.5, 0)
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.BackgroundColor3 = C.cardBg
    card.BorderSizePixel = 0
    corner(card, 14)
    gradient(card, ColorSequence.new{
        ColorSequenceKeypoint.new(0, C.cardBg2),
        ColorSequenceKeypoint.new(1, C.cardBg)
    }, 60)

    local thumbWrap = Instance.new("Frame", card)
    thumbWrap.Name = "ThumbWrap"
    thumbWrap.Size = UDim2.new(1, -12, 0, 82)
    thumbWrap.Position = UDim2.new(0, 6, 0, 6)
    thumbWrap.BackgroundColor3 = C.purpleDeep
    thumbWrap.BackgroundTransparency = 0.35
    corner(thumbWrap, 10)

    local thumb = Instance.new("ImageLabel", thumbWrap)
    thumb.Name = "Thumb"
    thumb.Size = UDim2.new(1, 0, 1, 0)
    thumb.BackgroundTransparency = 1
    thumb.ScaleType = Enum.ScaleType.Crop
    thumb.ImageColor3 = C.white
    corner(thumb, 10)

    local favBtn = Instance.new("TextButton", card)
    favBtn.Name = "FavBtn"
    favBtn.Size = UDim2.new(0, 24, 0, 24)
    favBtn.Position = UDim2.new(1, -30, 0, 10)
    favBtn.BackgroundColor3 = C.white
    favBtn.BackgroundTransparency = 0.15
    favBtn.Text = "★"
    favBtn.TextColor3 = C.purpleDeep
    favBtn.Font = Enum.Font.GothamBold
    favBtn.TextSize = 14
    favBtn.AutoButtonColor = false
    favBtn.ZIndex = 2
    corner(favBtn, 12)

    local nameLbl = Instance.new("TextLabel", card)
    nameLbl.Name = "NameLbl"
    nameLbl.Size = UDim2.new(1, -12, 0, 16)
    nameLbl.Position = UDim2.new(0, 6, 0, 94)
    nameLbl.BackgroundTransparency = 1
    nameLbl.TextColor3 = C.white
    nameLbl.Text = ""
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 11
    nameLbl.TextXAlignment = Enum.TextXAlignment.Center
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

    local playBtn = Instance.new("TextButton", card)
    playBtn.Name = "PlayBtn"
    playBtn.Size = UDim2.new(1, -12, 0, 26)
    playBtn.Position = UDim2.new(0, 6, 0, 114)
    playBtn.BackgroundColor3 = C.purpleLight
    playBtn.Text = "▶ Play"
    playBtn.TextColor3 = C.white
    playBtn.Font = Enum.Font.GothamBold
    playBtn.TextSize = 12
    playBtn.AutoButtonColor = false
    corner(playBtn, 13)
    gradient(playBtn, ColorSequence.new{
        ColorSequenceKeypoint.new(0, C.purple),
        ColorSequenceKeypoint.new(1, C.purpleDeep)
    }, 0)

    return cardWrapper
end

local function updateCardData(cardWrapper, emote, order, isFavorite)
    clearCardConnections(cardWrapper)
    cardWrapper.LayoutOrder = order
    cardWrapper.Visible = true

    local card = cardWrapper.Card
    card.ThumbWrap.Thumb.Image = emote.icon or ""
    card.NameLbl.Text = emote.name or "Emote"

    local favBtn = card.FavBtn
    local playBtn = card.PlayBtn

    favBtn.Text = isFavorite and "★" or "☆"

    local conns = cardConnections[cardWrapper]

    table.insert(conns, favBtn.MouseButton1Click:Connect(function()
        smoothTween(favBtn, {Size = UDim2.new(0, 28, 0, 28)}, 0.1)
        task.wait(0.1)
        smoothTween(favBtn, {Size = UDim2.new(0, 24, 0, 24)}, 0.1)

        local idx = table.find(Favorites, emote.id)
        if idx then
            table.remove(Favorites, idx)
            favBtn.Text = "☆"
        else
            table.insert(Favorites, emote.id)
            favBtn.Text = "★"
        end
        saveFavorites()
        if currentTab == "favorites" and _G.renderEmotesRefresh then _G.renderEmotesRefresh() end
    end))

    table.insert(conns, playBtn.MouseButton1Down:Connect(function()
        smoothTween(playBtn, {BackgroundColor3 = C.purpleDeep}, 0.1)
    end))
    table.insert(conns, playBtn.MouseButton1Up:Connect(function()
        smoothTween(playBtn, {BackgroundColor3 = C.purpleLight}, 0.1); playEmote(emote.id)
    end))
    table.insert(conns, playBtn.MouseLeave:Connect(function()
        smoothTween(playBtn, {BackgroundColor3 = C.purpleLight}, 0.1)
    end))
end

-- ==================== RENDER ENGINE ====================
local resultsContainer = nil
local emptyLabel = nil

local function renderEmotes()
    local token = renderToken + 1
    renderToken = token

    if not resultsContainer or not resultsContainer.Parent then return end

    local filtered = {}
    local q = searchQuery:lower()
    for _, e in ipairs(Emotes) do
        local include = true
        if currentTab == "favorites" then include = table.find(Favorites, e.id) ~= nil end
        if include and q ~= "" then include = e.name:lower():find(q, 1, true) ~= nil end
        if include then table.insert(filtered, e) end
    end

    table.sort(filtered, function(a, b) return (a.updated or "") > (b.updated or "") end)
    for _, card in ipairs(cardPool) do card.Visible = false end

    if emptyLabel then
        emptyLabel.Visible = (#filtered == 0)
        if #filtered == 0 then
            emptyLabel.Text = isLoading() and "Memuat emote..." or "Tidak ada emote ditemukan"
        end
    end

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
        appLayout.Padding = UDim.new(0, 12)
        appLayout.SortOrder = Enum.SortOrder.LayoutOrder
    end

    -- Search Bar (bulat, putih, ikon kaca pembesar + tombol clear)
    local searchFrame = Instance.new("Frame", appContent)
    searchFrame.Size = UDim2.new(1, 0, 0, 40)
    searchFrame.BackgroundColor3 = C.white
    searchFrame.BorderSizePixel = 0
    searchFrame.LayoutOrder = 1
    corner(searchFrame, 20)
    stroke(searchFrame, Color3.fromRGB(225, 215, 245), 1, 0.3)

    local searchIcon = Instance.new("TextLabel", searchFrame)
    searchIcon.Size = UDim2.new(0, 34, 1, 0)
    searchIcon.Position = UDim2.new(0, 8, 0, 0)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Text = "🔍"
    searchIcon.TextSize = 14
    searchIcon.TextColor3 = C.purple

    local searchBox = Instance.new("TextBox", searchFrame)
    searchBox.Name = "SearchBox"
    searchBox.Size = UDim2.new(1, -76, 1, 0)
    searchBox.Position = UDim2.new(0, 40, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.PlaceholderText = "Cari gaya emote..."
    searchBox.PlaceholderColor3 = C.textGray
    searchBox.Text = searchQuery
    searchBox.TextColor3 = C.purpleDeep
    searchBox.Font = Enum.Font.GothamBold
    searchBox.TextSize = 13
    searchBox.ClearTextOnFocus = false
    searchBox.TextXAlignment = Enum.TextXAlignment.Left

    local clearBtn = Instance.new("TextButton", searchFrame)
    clearBtn.Size = UDim2.new(0, 32, 1, 0)
    clearBtn.Position = UDim2.new(1, -36, 0, 0)
    clearBtn.BackgroundTransparency = 1
    clearBtn.Text = "✕"
    clearBtn.TextColor3 = C.textGray
    clearBtn.Font = Enum.Font.GothamBold
    clearBtn.TextSize = 14
    clearBtn.Visible = searchQuery ~= ""

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        searchQuery = searchBox.Text
        clearBtn.Visible = searchQuery ~= ""
        renderEmotes()
    end)
    clearBtn.MouseButton1Click:Connect(function()
        searchBox.Text = ""
    end)

    -- Tab Bar (pill ungu untuk tab aktif)
    local tabWrap = Instance.new("Frame", appContent)
    tabWrap.Size = UDim2.new(1, 0, 0, 40)
    tabWrap.BackgroundColor3 = Color3.fromRGB(25, 15, 40)
    tabWrap.LayoutOrder = 2
    corner(tabWrap, 20)

    local tabPad = Instance.new("UIPadding", tabWrap)
    tabPad.PaddingLeft = UDim.new(0, 4)
    tabPad.PaddingRight = UDim.new(0, 4)
    tabPad.PaddingTop = UDim.new(0, 4)
    tabPad.PaddingBottom = UDim.new(0, 4)

    local tabLayout = Instance.new("UIListLayout", tabWrap)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 4)

    local btnAll = Instance.new("TextButton", tabWrap)
    btnAll.Size = UDim2.new(0.5, -2, 1, 0)
    btnAll.BackgroundColor3 = currentTab == "all" and C.purple or Color3.fromRGB(25, 15, 40)
    btnAll.Text = "Semua ✨"
    btnAll.TextColor3 = C.white
    btnAll.Font = Enum.Font.GothamBold
    btnAll.TextSize = 13
    btnAll.AutoButtonColor = false
    corner(btnAll, 16)
    gradient(btnAll, ColorSequence.new{
        ColorSequenceKeypoint.new(0, C.purpleLight),
        ColorSequenceKeypoint.new(1, C.purple)
    }, 0)

    local btnFav = Instance.new("TextButton", tabWrap)
    btnFav.Size = UDim2.new(0.5, -2, 1, 0)
    btnFav.BackgroundColor3 = Color3.fromRGB(25, 15, 40)
    btnFav.Text = "Favorit ★"
    btnFav.TextColor3 = C.white
    btnFav.Font = Enum.Font.GothamBold
    btnFav.TextSize = 13
    btnFav.AutoButtonColor = false
    corner(btnFav, 16)

    local function updateTabs()
        btnAll.BackgroundTransparency = 1
        for _, ch in ipairs(btnAll:GetChildren()) do if ch:IsA("UIGradient") then ch:Destroy() end end
        for _, ch in ipairs(btnFav:GetChildren()) do if ch:IsA("UIGradient") then ch:Destroy() end end

        if currentTab == "all" then
            btnAll.BackgroundColor3 = C.purple
            gradient(btnAll, ColorSequence.new{
                ColorSequenceKeypoint.new(0, C.purpleLight),
                ColorSequenceKeypoint.new(1, C.purple)
            }, 0)
            btnFav.BackgroundColor3 = Color3.fromRGB(25, 15, 40)
        else
            btnFav.BackgroundColor3 = C.purple
            gradient(btnFav, ColorSequence.new{
                ColorSequenceKeypoint.new(0, C.purpleLight),
                ColorSequenceKeypoint.new(1, C.purple)
            }, 0)
            btnAll.BackgroundColor3 = Color3.fromRGB(25, 15, 40)
        end
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
    resultsContainer.Size = UDim2.new(1, 0, 1, -100)
    resultsContainer.BackgroundTransparency = 1
    resultsContainer.BorderSizePixel = 0
    resultsContainer.ScrollBarThickness = 2
    resultsContainer.ScrollBarImageColor3 = C.purple
    resultsContainer.LayoutOrder = 3

    local grid = Instance.new("UIGridLayout", resultsContainer)
    grid.CellSize = UDim2.new(0.31, 0, 0, 144)
    grid.CellPadding = UDim2.new(0.035, 0, 0, 10)
    grid.SortOrder = Enum.SortOrder.LayoutOrder

    local resPad = Instance.new("UIPadding", resultsContainer)
    resPad.PaddingTop = UDim.new(0, 4)
    resPad.PaddingBottom = UDim.new(0, 10)

    grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        resultsContainer.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y + 20)
    end)

    emptyLabel = Instance.new("TextLabel", resultsContainer)
    emptyLabel.Size = UDim2.new(1, 0, 0, 60)
    emptyLabel.BackgroundTransparency = 1
    emptyLabel.Text = "Memuat emote..."
    emptyLabel.TextColor3 = C.textGray
    emptyLabel.Font = Enum.Font.GothamBold
    emptyLabel.TextSize = 13
    emptyLabel.Visible = (#Emotes == 0)
    emptyLabel.ZIndex = 0

    renderEmotes()
    -- FIX: bug asli — isLoaded() dipanggil sebagai fungsi tapi tidak pernah
    -- didefinisikan, jadi app selalu error/gagal build saat dibuka.
    if #Emotes == 0 or not isLoaded() then fetchAllEmotes(30) end
    return true
end

function _G.openEmoteApp() pcall(buildEmoteApp) end
print("[Emote] Purple Glass Theme Applied Successfully!")