-- ================================================
-- EMOTE.LUA — Neon Purple Premium Theme (UI V4)
-- Feature: Load ALL Emotes, Smart Play, Gradient UI
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

local function smoothTween(object, properties, duration)
    local tw = TweenService:Create(object, TweenInfo.new(duration or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
    tw:Play()
    return tw
end

local CACHE_FILE_NAME = "PhoneIDViewer_EmoteCache.json"

-- ==================== PALETTE (NEON PURPLE) ====================
local C = {
    white       = Color3.fromRGB(255, 255, 255),
    searchBg    = Color3.fromRGB(248, 245, 255), -- Light purpleish white
    textPurple  = Color3.fromRGB(80, 50, 120),
    
    cardBg      = Color3.fromRGB(30, 25, 45),    -- Dark violet background
    cardStroke  = Color3.fromRGB(110, 80, 150),  -- Purple glow stroke
    
    purpleLight = Color3.fromRGB(138, 43, 226),  -- Gradient Top
    purpleDark  = Color3.fromRGB(75, 0, 130),    -- Gradient Bottom
    
    blackTab    = Color3.fromRGB(20, 15, 25),    -- Inactive Tab Dark
}

-- ==================== CACHE GLOBAL ====================
_G.EmoteCache = _G.EmoteCache or {
    emotes = {}, favorites = {}, idSet = {}, loaded = false, loading = false,
}

local Emotes = _G.EmoteCache.emotes
local Favorites = _G.EmoteCache.favorites
local IdSet = _G.EmoteCache.idSet

local currentAnimTrack = nil
local activeEmoteId = nil
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

-- ==================== FETCH API (LOAD ALL EMOTES) ====================
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

local function fetchAllEmotes()
    if _G.EmoteCache.loading then return end
    _G.EmoteCache.loading = true

    task.spawn(function()
        local cursor = ""
        local newItemsAdded = false

        -- Infinite loop until cursor is nil (Loads ALL Roblox Emotes)
        while true do
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
            if cursor == "" then break end
            task.wait(0.3) -- Jeda aman agar tidak kena rate limit (Error 429)
        end

        _G.EmoteCache.loaded = true
        _G.EmoteCache.loading = false
        if newItemsAdded then saveEmotesToDisk() end
        if _G.renderEmotesRefresh then _G.renderEmotesRefresh() end
    end)
end

-- ==================== ANIMATION & SMART BUTTONS ====================
local function updateAllPlayButtons()
    for _, cardWrapper in ipairs(cardPool) do
        if cardWrapper.Visible then
            local card = cardWrapper:FindFirstChildOfClass("Frame")
            local playBtn = card and card:FindFirstChild("PlayBtn")
            local eId = cardWrapper:GetAttribute("EmoteId")
            
            if playBtn and eId then
                local btnGradient = playBtn:FindFirstChildOfClass("UIGradient")
                if eId == activeEmoteId then
                    playBtn.Text = "■ Playing"
                    if btnGradient then btnGradient.Enabled = false end
                    smoothTween(playBtn, {BackgroundColor3 = C.cardBg, TextColor3 = C.purpleLight}, 0.1)
                    stroke(playBtn, C.purpleLight, 1, 0) -- Glowing outline active
                else
                    playBtn.Text = "▶ Play"
                    if btnGradient then btnGradient.Enabled = true end
                    smoothTween(playBtn, {BackgroundColor3 = C.white, TextColor3 = C.white}, 0.1)
                    local s = playBtn:FindFirstChildOfClass("UIStroke")
                    if s then s:Destroy() end
                end
            end
        end
    end
end

local function stopAnimation()
    if currentAnimTrack then
        pcall(function() currentAnimTrack:Stop() end)
        currentAnimTrack = nil
    end
    activeEmoteId = nil
    updateAllPlayButtons()
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
        activeEmoteId = assetId
        updateAllPlayButtons()
        
        track:AdjustSpeed(currentSpeed)
        track.Looped = loopEnabled
        track:Play()
        
        track.Stopped:Connect(function()
            if activeEmoteId == assetId then
                activeEmoteId = nil
                updateAllPlayButtons()
            end
        end)
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
    card.BackgroundColor3 = C.cardBg
    card.BorderSizePixel = 0
    corner(card, 12)
    stroke(card, C.cardStroke, 1.5, 0) -- Neon Purple Outline

    -- Thumbnail langsung di atas kartu (tidak ada box terpisah)
    local thumb = Instance.new("ImageLabel", card)
    thumb.Name = "Thumb"
    thumb.Size = UDim2.new(1, -12, 0, 80)
    thumb.Position = UDim2.new(0, 6, 0, 6)
    thumb.BackgroundTransparency = 1
    thumb.ScaleType = Enum.ScaleType.Crop
    corner(thumb, 8)

    local favBtn = Instance.new("TextButton", card)
    favBtn.Name = "FavBtn"
    favBtn.Size = UDim2.new(0, 24, 0, 24)
    favBtn.Position = UDim2.new(1, -26, 0, 6)
    favBtn.BackgroundTransparency = 1
    favBtn.Text = ""
    favBtn.Font = Enum.Font.GothamBold
    favBtn.TextSize = 16
    favBtn.AutoButtonColor = false
    favBtn.ZIndex = 2
    
    local favStroke = Instance.new("UIStroke", favBtn)
    favStroke.Color = C.white; favStroke.Thickness = 1; favStroke.Enabled = true

    local nameLbl = Instance.new("TextLabel", card)
    nameLbl.Name = "NameLbl"
    nameLbl.Size = UDim2.new(1, -12, 0, 16)
    nameLbl.Position = UDim2.new(0, 6, 0, 92)
    nameLbl.BackgroundTransparency = 1
    nameLbl.TextColor3 = C.white
    nameLbl.Text = ""
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 10
    nameLbl.TextXAlignment = Enum.TextXAlignment.Center
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

    local playBtn = Instance.new("TextButton", card)
    playBtn.Name = "PlayBtn"
    playBtn.Size = UDim2.new(1, -16, 0, 22)
    playBtn.Position = UDim2.new(0, 8, 0, 114)
    playBtn.BackgroundColor3 = C.white
    playBtn.Text = "▶ Play"
    playBtn.TextColor3 = C.white
    playBtn.Font = Enum.Font.GothamBold
    playBtn.TextSize = 11
    playBtn.AutoButtonColor = false
    corner(playBtn, 12)
    
    local btnGrad = Instance.new("UIGradient", playBtn)
    btnGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, C.purpleLight),
        ColorSequenceKeypoint.new(1, C.purpleDark)
    }
    btnGrad.Rotation = 45

    return cardWrapper
end

local function updateCardData(cardWrapper, emote, order, isFavorite)
    clearCardConnections(cardWrapper)
    cardWrapper.LayoutOrder = order
    cardWrapper.Visible = true
    cardWrapper:SetAttribute("EmoteId", emote.id)

    local card = cardWrapper:FindFirstChildOfClass("Frame")
    card.Thumb.Image = emote.icon or ""
    card.NameLbl.Text = emote.name or "Emote"
    
    local favBtn = card.FavBtn
    local playBtn = card.PlayBtn
    local btnGrad = playBtn:FindFirstChildOfClass("UIGradient")

    favBtn.Text = isFavorite and "★" or "☆"
    favBtn.TextColor3 = C.white
    
    if emote.id == activeEmoteId then
        playBtn.Text = "■ Playing"
        if btnGrad then btnGrad.Enabled = false end
        playBtn.BackgroundColor3 = C.cardBg
        playBtn.TextColor3 = C.purpleLight
        local s = playBtn:FindFirstChildOfClass("UIStroke")
        if not s then stroke(playBtn, C.purpleLight, 1, 0) end
    else
        playBtn.Text = "▶ Play"
        if btnGrad then btnGrad.Enabled = true end
        playBtn.BackgroundColor3 = C.white
        playBtn.TextColor3 = C.white
        local s = playBtn:FindFirstChildOfClass("UIStroke")
        if s then s:Destroy() end
    end

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

    table.insert(conns, playBtn.MouseButton1Click:Connect(function()
        if activeEmoteId == emote.id then stopAnimation() else playEmote(emote.id) end
    end))
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
        appLayout.Padding = UDim.new(0, 12)
        appLayout.SortOrder = Enum.SortOrder.LayoutOrder
    end

    -- Search Bar Neon
    local searchFrame = Instance.new("Frame", appContent)
    searchFrame.Size = UDim2.new(1, 0, 0, 36)
    searchFrame.BackgroundColor3 = C.searchBg
    searchFrame.BorderSizePixel = 0
    searchFrame.LayoutOrder = 1
    corner(searchFrame, 18)
    stroke(searchFrame, C.cardStroke, 1, 0)

    local searchIcon = Instance.new("TextLabel", searchFrame)
    searchIcon.Size = UDim2.new(0, 34, 1, 0)
    searchIcon.Position = UDim2.new(0, 4, 0, 0)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Text = "🔍"
    searchIcon.TextColor3 = C.textPurple
    searchIcon.TextSize = 14

    local clearBtn = Instance.new("TextButton", searchFrame)
    clearBtn.Size = UDim2.new(0, 30, 1, 0)
    clearBtn.Position = UDim2.new(1, -34, 0, 0)
    clearBtn.BackgroundTransparency = 1
    clearBtn.Text = "✕"
    clearBtn.TextColor3 = C.textPurple
    clearBtn.Font = Enum.Font.GothamMedium
    clearBtn.TextSize = 14
    clearBtn.Visible = false

    local searchBox = Instance.new("TextBox", searchFrame)
    searchBox.Size = UDim2.new(1, -70, 1, 0)
    searchBox.Position = UDim2.new(0, 34, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.PlaceholderText = "Cari gaya emote..."
    searchBox.PlaceholderColor3 = Color3.fromRGB(150, 140, 170)
    searchBox.Text = searchQuery
    searchBox.TextColor3 = C.textPurple
    searchBox.Font = Enum.Font.GothamMedium
    searchBox.TextSize = 12
    searchBox.ClearTextOnFocus = false
    searchBox.TextXAlignment = Enum.TextXAlignment.Left

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        searchQuery = searchBox.Text
        clearBtn.Visible = (searchQuery ~= "")
        renderEmotes()
    end)
    
    clearBtn.MouseButton1Click:Connect(function()
        searchBox.Text = ""
    end)

    -- Segmented Tab Bar (Gradient)
    local tabWrap = Instance.new("Frame", appContent)
    tabWrap.Size = UDim2.new(1, 0, 0, 38)
    tabWrap.BackgroundColor3 = C.blackTab
    tabWrap.LayoutOrder = 2
    corner(tabWrap, 10)
    stroke(tabWrap, C.cardStroke, 1.5, 0)

    local tabLayout = Instance.new("UIListLayout", tabWrap)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local btnAll = Instance.new("TextButton", tabWrap)
    btnAll.Size = UDim2.new(0.5, 0, 1, 0)
    btnAll.BackgroundColor3 = C.white
    btnAll.BackgroundTransparency = currentTab == "all" and 0 or 1
    btnAll.Text = "Semua ✨"
    btnAll.TextColor3 = C.white
    btnAll.Font = Enum.Font.GothamBold
    btnAll.TextSize = 12
    corner(btnAll, 10)
    
    local allGrad = Instance.new("UIGradient", btnAll)
    allGrad.Color = ColorSequence.new{ ColorSequenceKeypoint.new(0, C.purpleLight), ColorSequenceKeypoint.new(1, C.purpleDark) }
    allGrad.Enabled = (currentTab == "all")

    local btnFav = Instance.new("TextButton", tabWrap)
    btnFav.Size = UDim2.new(0.5, 0, 1, 0)
    btnFav.BackgroundColor3 = C.white
    btnFav.BackgroundTransparency = currentTab == "favorites" and 0 or 1
    btnFav.Text = "Favorit ★"
    btnFav.TextColor3 = C.white
    btnFav.Font = Enum.Font.GothamBold
    btnFav.TextSize = 12
    corner(btnFav, 10)
    
    local favGrad = Instance.new("UIGradient", btnFav)
    favGrad.Color = ColorSequence.new{ ColorSequenceKeypoint.new(0, C.purpleLight), ColorSequenceKeypoint.new(1, C.purpleDark) }
    favGrad.Enabled = (currentTab == "favorites")

    local function updateTabs()
        btnAll.BackgroundTransparency = currentTab == "all" and 0 or 1
        allGrad.Enabled = (currentTab == "all")
        
        btnFav.BackgroundTransparency = currentTab == "favorites" and 0 or 1
        favGrad.Enabled = (currentTab == "favorites")
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
    resultsContainer.Size = UDim2.new(1, 0, 1, -95) 
    resultsContainer.BackgroundTransparency = 1
    resultsContainer.BorderSizePixel = 0
    resultsContainer.ScrollBarThickness = 2
    resultsContainer.ScrollBarImageColor3 = C.purpleLight
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

    renderEmotes()
    
    -- Load ALL Emotes logic
    if not _G.EmoteCache.loaded or #Emotes < 100 then fetchAllEmotes() end
    return true
end

function _G.openEmoteApp() pcall(buildEmoteApp) end
print("[Emote] V4 Neon Purple Gradient (All Emotes) Loaded!")
