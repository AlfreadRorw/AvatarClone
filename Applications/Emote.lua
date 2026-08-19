-- ================================================
-- EMOTE.LUA — Premium Futuristic Mobile UI (Fixed Loading & Search)
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

-- ==================== PALETTE (PREMIUM PURPLE ACCENT) ====================
local C = {
    white       = Color3.fromRGB(255, 255, 255),
    offWhite    = Color3.fromRGB(248, 247, 252),
    black       = Color3.fromRGB(10, 10, 14),
    purple      = Color3.fromRGB(125, 65, 255),
    lightPurple = Color3.fromRGB(220, 205, 255),
    darkPurple  = Color3.fromRGB(55, 25, 100),
    gray        = Color3.fromRGB(150, 150, 160),
    searchBg    = Color3.fromRGB(238, 234, 250)
}

-- ==================== CACHE GLOBAL ====================
_G.EmoteCache = _G.EmoteCache or {
    emotes = {}, favorites = {}, idSet = {}, loaded = false, loading = false,
}

local Emotes = _G.EmoteCache.emotes
local Favorites = _G.EmoteCache.favorites
local IdSet = _G.EmoteCache.idSet

-- NEW: LoadedEmotes tracking per emote ID
local LoadedEmotes = {} -- [emoteId] = true/false

local currentAnimTrack = nil
local activeEmoteId = nil
local currentSpeed = 1.0
local loopEnabled = false
local currentTab = "all"
local searchQuery = ""
local renderToken = 0

local cardPool = {} 
local cardConnections = {}

-- UI state references (assigned in buildEmoteApp)
local loadingState = nil
local emptyState = nil
local contentOverlay = nil

-- ==================== JSON & FAVORITES ====================
local function loadEmotesFromDisk()
    if isfile and isfile(CACHE_FILE_NAME) then
        local success, result = pcall(function() return HttpService:JSONDecode(readfile(CACHE_FILE_NAME)) end)
        if success and type(result) == "table" and #result > 0 then
            table.clear(Emotes); table.clear(IdSet); table.clear(LoadedEmotes)
            for _, item in ipairs(result) do
                if item.id then
                    table.insert(Emotes, item)
                    IdSet[item.id] = true
                    LoadedEmotes[item.id] = true -- cached items considered loaded
                end
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

-- ==================== EMOTE LOADED CHECK ====================
local function EmotesLoaded()
    for _, loaded in pairs(LoadedEmotes) do
        if not loaded then
            return false
        end
    end
    return true
end

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
    if not ok or not result or not result.Body then
        warn("[Emote] Fetch failed:", ok and "no body" or result)
        return nil
    end
    local dok, data = pcall(function() return HttpService:JSONDecode(result.Body) end)
    if not dok then
        warn("[Emote] JSON decode failed:", data)
        return nil
    end
    return data
end

local function fetchAllEmotes(maxPages)
    if _G.EmoteCache.loading then return end
    _G.EmoteCache.loading = true
    maxPages = maxPages or 30

    task.spawn(function()
        print("[Emote] Fetch started")
        local cursor = ""
        local pages = 0
        local newItemsAdded = false

        while pages < maxPages do
            local page = fetchEmotePage(cursor)
            if not page or not page.data or #page.data == 0 then
                print("[Emote] No more data or fetch failed, breaking")
                break
            end
            print("[Emote] Page loaded:", #page.data)
            local newBatch = {}
            for _, item in ipairs(page.data) do
                if item.id and item.name and not IdSet[item.id] then
                    IdSet[item.id] = true
                    newItemsAdded = true
                    local emoteObj = {
                        id = item.id,
                        name = item.name,
                        icon = "rbxthumb://type=Asset&id=" .. item.id .. "&w=150&h=150",
                        updated = item.updated or ""
                    }
                    table.insert(Emotes, emoteObj)
                    table.insert(newBatch, emoteObj.icon)
                    -- Mark as not loaded initially, will become true after preload
                    LoadedEmotes[item.id] = false
                end
            end
            -- Preload icons asynchronously
            if #newBatch > 0 then
                task.spawn(function()
                    pcall(function() ContentProvider:PreloadAsync(newBatch) end)
                    -- Mark all newly added as loaded after preload attempt
                    for _, emote in ipairs(Emotes) do
                        if not LoadedEmotes[emote.id] then
                            LoadedEmotes[emote.id] = true
                        end
                    end
                end)
            end
            cursor = page.nextPageCursor or ""
            pages = pages + 1
            if cursor == "" then break end
            task.wait(0.2)
        end

        print("[Emote] Total after fetch:", #Emotes)
        _G.EmoteCache.loaded = true
        _G.EmoteCache.loading = false
        if newItemsAdded then saveEmotesToDisk() end
        -- Ensure all loaded flags are true (if any missed)
        for _, emote in ipairs(Emotes) do
            LoadedEmotes[emote.id] = true
        end
        if _G.renderEmotesRefresh then
            print("[Emote] Calling renderEmotesRefresh")
            _G.renderEmotesRefresh()
        end
    end)
end

-- ==================== ANIMATION & SMART BUTTONS ====================
local function updateAllPlayButtons()
    for _, cardWrapper in ipairs(cardPool) do
        if cardWrapper.Visible then
            local card = cardWrapper:FindFirstChild("Card")
            local playBtn = card and card:FindFirstChild("PlayBtn")
            local cardStroke = card and card:FindFirstChild("CardStroke")
            local eId = cardWrapper:GetAttribute("EmoteId")
            
            if playBtn and eId then
                if eId == activeEmoteId then
                    smoothTween(playBtn, {BackgroundColor3 = C.darkPurple, TextColor3 = C.white}, 0.1)
                    playBtn.Text = "■ Playing"
                    if playBtn:FindFirstChild("UIStroke") then
                        smoothTween(playBtn.UIStroke, {Color = C.purple, Thickness = 2}, 0.1)
                    end
                    if cardStroke then
                        smoothTween(cardStroke, {Color = C.purple, Thickness = 2}, 0.1)
                    end
                else
                    smoothTween(playBtn, {BackgroundColor3 = C.white, TextColor3 = C.black}, 0.1)
                    playBtn.Text = "▶ Play"
                    if playBtn:FindFirstChild("UIStroke") then
                        smoothTween(playBtn.UIStroke, {Color = C.purple, Thickness = 1}, 0.1)
                    end
                    if cardStroke then
                        smoothTween(cardStroke, {Color = C.black, Thickness = 1}, 0.1)
                    end
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

local function createEmoteCard(parent)
    local cardWrapper = Instance.new("Frame", parent)
    cardWrapper.BackgroundTransparency = 1
    cardWrapper.Size = UDim2.new(1, 0, 1, 0)
    cardWrapper.ClipsDescendants = false

    local shadow = Instance.new("Frame", cardWrapper)
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 0, 1, 0)
    shadow.Position = UDim2.new(0, 1, 0, 1)
    shadow.BackgroundColor3 = C.black
    shadow.BackgroundTransparency = 0.8
    shadow.BorderSizePixel = 0
    corner(shadow, 16)
    shadow.ZIndex = 0

    local card = Instance.new("Frame", cardWrapper)
    card.Name = "Card"
    card.Size = UDim2.new(1, 0, 1, 0)
    card.Position = UDim2.new(0.5, 0, 0.5, 0)
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.BackgroundColor3 = C.white
    card.BorderSizePixel = 0
    corner(card, 16)
    local cardStroke = stroke(card, C.black, 1, 0)
    cardStroke.Name = "CardStroke"
    card.ZIndex = 1

    local thumbWrap = Instance.new("Frame", card)
    thumbWrap.Name = "ThumbWrap"
    thumbWrap.Size = UDim2.new(1, -10, 0, 88)
    thumbWrap.Position = UDim2.new(0, 5, 0, 5)
    thumbWrap.BackgroundColor3 = C.searchBg
    thumbWrap.BorderSizePixel = 0
    corner(thumbWrap, 12)
    local thumbStroke = stroke(thumbWrap, C.black, 1, 0)
    thumbStroke.Name = "ThumbStroke"
    thumbWrap.ZIndex = 2

    local thumb = Instance.new("ImageLabel", thumbWrap)
    thumb.Name = "Thumb"
    thumb.Size = UDim2.new(1, 0, 1, 0)
    thumb.BackgroundTransparency = 1
    thumb.ScaleType = Enum.ScaleType.Crop
    corner(thumb, 12)
    thumb.ZIndex = 3

    local favBtn = Instance.new("TextButton", card)
    favBtn.Name = "FavBtn"
    favBtn.Size = UDim2.new(0, 24, 0, 24)
    favBtn.Position = UDim2.new(1, -30, 0, 8)
    favBtn.BackgroundTransparency = 1
    favBtn.Text = ""
    favBtn.Font = Enum.Font.GothamBold
    favBtn.TextSize = 16
    favBtn.AutoButtonColor = false
    favBtn.ZIndex = 4
    
    local favStroke = Instance.new("UIStroke", favBtn)
    favStroke.Color = C.black
    favStroke.Thickness = 1
    favStroke.Enabled = true

    local nameLbl = Instance.new("TextLabel", card)
    nameLbl.Name = "NameLbl"
    nameLbl.Size = UDim2.new(1, -10, 0, 18)
    nameLbl.Position = UDim2.new(0, 5, 0, 96)
    nameLbl.BackgroundTransparency = 1
    nameLbl.TextColor3 = C.black
    nameLbl.Text = ""
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 11
    nameLbl.TextXAlignment = Enum.TextXAlignment.Center
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    nameLbl.ZIndex = 2

    local playBtn = Instance.new("TextButton", card)
    playBtn.Name = "PlayBtn"
    playBtn.Size = UDim2.new(1, -10, 0, 26)
    playBtn.Position = UDim2.new(0, 5, 0, 116)
    playBtn.BackgroundColor3 = C.white
    playBtn.Text = "▶ Play"
    playBtn.TextColor3 = C.black
    playBtn.Font = Enum.Font.GothamBold
    playBtn.TextSize = 11
    playBtn.AutoButtonColor = false
    playBtn.ZIndex = 3
    corner(playBtn, 8)
    local playStroke = stroke(playBtn, C.purple, 1, 0)
    playStroke.Name = "UIStroke"

    card.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            smoothTween(card, {Size = UDim2.new(0.96, 0, 0.96, 0)}, 0.1)
        end
    end)
    card.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            smoothTween(card, {Size = UDim2.new(1, 0, 1, 0)}, 0.1)
        end
    end)

    playBtn.MouseButton1Down:Connect(function()
        smoothTween(playBtn, {Size = UDim2.new(0.96, -10, 0.96, 0)}, 0.08)
    end)
    playBtn.MouseButton1Up:Connect(function()
        smoothTween(playBtn, {Size = UDim2.new(1, -10, 1, 0)}, 0.08)
    end)
    playBtn.MouseLeave:Connect(function()
        smoothTween(playBtn, {Size = UDim2.new(1, -10, 1, 0)}, 0.1)
    end)

    return cardWrapper
end

local function updateCardData(cardWrapper, emote, order, isFavorite)
    clearCardConnections(cardWrapper)
    cardWrapper.LayoutOrder = order
    cardWrapper.Visible = true
    cardWrapper:SetAttribute("EmoteId", emote.id)

    local card = cardWrapper:FindFirstChild("Card")
    card.ThumbWrap.Thumb.Image = emote.icon or ""
    card.NameLbl.Text = emote.name or "Emote"
    
    local favBtn = card.FavBtn
    local playBtn = card.PlayBtn

    favBtn.Text = isFavorite and "★" or "☆"
    favBtn.TextColor3 = isFavorite and C.purple or C.black
    
    if emote.id == activeEmoteId then
        playBtn.BackgroundColor3 = C.darkPurple
        playBtn.TextColor3 = C.white
        playBtn.Text = "■ Playing"
        playBtn.UIStroke.Color = C.purple
        playBtn.UIStroke.Thickness = 2
        card.CardStroke.Color = C.purple
        card.CardStroke.Thickness = 2
        card.ThumbWrap.ThumbStroke.Color = C.purple
        card.ThumbWrap.ThumbStroke.Thickness = 1
    else
        playBtn.BackgroundColor3 = C.white
        playBtn.TextColor3 = C.black
        playBtn.Text = "▶ Play"
        playBtn.UIStroke.Color = C.purple
        playBtn.UIStroke.Thickness = 1
        card.CardStroke.Color = C.black
        card.CardStroke.Thickness = 1
        card.ThumbWrap.ThumbStroke.Color = C.black
        card.ThumbWrap.ThumbStroke.Thickness = 1
    end

    if card.BackgroundTransparency > 0 then
        smoothTween(card, {BackgroundTransparency = 0}, 0.15)
    end

    local conns = cardConnections[cardWrapper]

    table.insert(conns, favBtn.MouseButton1Click:Connect(function()
        smoothTween(favBtn, {Size = UDim2.new(0, 30, 0, 30)}, 0.08)
        task.wait(0.08)
        smoothTween(favBtn, {Size = UDim2.new(0, 24, 0, 24)}, 0.08)

        local idx = table.find(Favorites, emote.id)
        if idx then
            table.remove(Favorites, idx)
            favBtn.Text = "☆"
            favBtn.TextColor3 = C.black
        else
            table.insert(Favorites, emote.id)
            favBtn.Text = "★"
            favBtn.TextColor3 = C.purple
        end
        saveFavorites()
        if currentTab == "favorites" and _G.renderEmotesRefresh then _G.renderEmotesRefresh() end
    end))

    table.insert(conns, playBtn.MouseButton1Click:Connect(function()
        if activeEmoteId == emote.id then
            stopAnimation()
        else
            playEmote(emote.id)
        end
    end))
    
    table.insert(conns, playBtn.MouseEnter:Connect(function() 
        if activeEmoteId ~= emote.id then smoothTween(playBtn, {BackgroundColor3 = C.searchBg}, 0.1) end
    end))
    table.insert(conns, playBtn.MouseLeave:Connect(function() 
        if activeEmoteId ~= emote.id then smoothTween(playBtn, {BackgroundColor3 = C.white}, 0.1) end
    end))
end

-- ==================== RENDER ENGINE ====================
local resultsContainer = nil

local function renderEmotes()
    local token = renderToken + 1
    renderToken = token

    if not resultsContainer or not resultsContainer.Parent then
        print("[Emote] renderEmotes: resultsContainer not ready")
        return
    end

    local filtered = {}
    local q = searchQuery:lower()
    for _, e in ipairs(Emotes) do
        local include = true
        if currentTab == "favorites" then
            include = table.find(Favorites, e.id) ~= nil
        elseif q ~= "" then
            include = e.name:lower():find(q, 1, true) ~= nil
        end
        if include then
            table.insert(filtered, e)
        end
    end

    table.sort(filtered, function(a, b) return (a.updated or "") > (b.updated or "") end)
    for _, card in ipairs(cardPool) do card.Visible = false end

    local showLoading = false
    local showEmpty = false
    if currentTab == "favorites" then
        if #filtered == 0 then showEmpty = true end
    else
        if #Emotes == 0 and (_G.EmoteCache.loading or not _G.EmoteCache.loaded) then
            showLoading = true
        end
    end

    if contentOverlay then
        contentOverlay.Visible = showLoading or showEmpty
        if loadingState then loadingState.Visible = showLoading end
        if emptyState then emptyState.Visible = showEmpty end
    end

    if showLoading or showEmpty then
        for _, card in ipairs(cardPool) do card.Visible = false end
        return
    end

    task.spawn(function()
        local batchSize = 15
        for idx, emote in ipairs(filtered) do
            if renderToken ~= token then return end
            local card = cardPool[idx]
            if not card or not card.Parent then
                card = createEmoteCard(resultsContainer)
                cardPool[idx] = card
            end
            updateCardData(card, emote, idx, table.find(Favorites, emote.id) ~= nil)
            if idx % batchSize == 0 then task.wait() end
        end
        for i = #filtered + 1, #cardPool do
            cardPool[i].Visible = false
        end
    end)
    print("[Emote] Rendering:", #filtered, "emotes")
end
_G.renderEmotesRefresh = renderEmotes

-- ==================== UI CREATION FUNCTIONS ====================
local function createHeader(parent)
    local header = Instance.new("Frame", parent)
    header.Size = UDim2.new(1, 0, 0, 42)
    header.BackgroundTransparency = 1
    header.LayoutOrder = 1

    local title = Instance.new("TextLabel", header)
    title.Size = UDim2.new(1, 0, 1, 0)
    title.Position = UDim2.new(0.5, 0, 0.5, 0)
    title.AnchorPoint = Vector2.new(0.5, 0.5)
    title.BackgroundTransparency = 1
    title.Text = "Emote"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 22
    title.TextColor3 = C.darkPurple
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.TextYAlignment = Enum.TextYAlignment.Center
    title.ZIndex = 2

    local sparkle = Instance.new("TextLabel", header)
    sparkle.Size = UDim2.new(0, 18, 0, 18)
    sparkle.Position = UDim2.new(0.5, 40, 0.5, -2)
    sparkle.AnchorPoint = Vector2.new(0, 0.5)
    sparkle.BackgroundTransparency = 1
    sparkle.Text = "✦"
    sparkle.Font = Enum.Font.GothamBold
    sparkle.TextSize = 14
    sparkle.TextColor3 = C.purple
    sparkle.ZIndex = 2

    return header
end

local function createSearchBar(parent)
    local searchFrame = Instance.new("Frame", parent)
    searchFrame.Size = UDim2.new(1, 0, 0, 40)
    searchFrame.BackgroundColor3 = C.searchBg
    searchFrame.BorderSizePixel = 0
    searchFrame.LayoutOrder = 2
    searchFrame.ZIndex = 1
    corner(searchFrame, 20)
    local searchStroke = stroke(searchFrame, C.purple, 1, 0)
    searchStroke.Name = "SearchStroke"

    local glow = Instance.new("Frame", searchFrame.Parent)
    glow.Name = "SearchGlow"
    glow.Size = UDim2.new(1, 4, 1, 4)
    glow.Position = UDim2.new(0, -2, 0, -2)
    glow.BackgroundColor3 = C.lightPurple
    glow.BackgroundTransparency = 0.7
    glow.BorderSizePixel = 0
    corner(glow, 22)
    glow.ZIndex = 0
    glow.Visible = false

    local searchIcon = Instance.new("TextLabel", searchFrame)
    searchIcon.Size = UDim2.new(0, 30, 1, 0)
    searchIcon.Position = UDim2.new(0, 4, 0, 0)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Text = "🔍"
    searchIcon.TextSize = 14
    searchIcon.Font = Enum.Font.Gotham
    searchIcon.TextColor3 = C.gray
    searchIcon.TextXAlignment = Enum.TextXAlignment.Center
    searchIcon.TextYAlignment = Enum.TextYAlignment.Center
    searchIcon.ZIndex = 2

    local searchBox = Instance.new("TextBox", searchFrame)
    searchBox.Size = UDim2.new(1, -70, 1, 0)
    searchBox.Position = UDim2.new(0, 34, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.PlaceholderText = "Cari emote..."
    searchBox.PlaceholderColor3 = C.gray
    searchBox.Text = searchQuery
    searchBox.TextColor3 = C.black
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 13
    searchBox.ClearTextOnFocus = false
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.TextYAlignment = Enum.TextYAlignment.Center
    searchBox.ZIndex = 2

    local clearBtn = Instance.new("TextButton", searchFrame)
    clearBtn.Size = UDim2.new(0, 20, 0, 20)
    clearBtn.Position = UDim2.new(1, -26, 0.5, 0)
    clearBtn.AnchorPoint = Vector2.new(0, 0.5)
    clearBtn.BackgroundTransparency = 1
    clearBtn.Text = "×"
    clearBtn.Font = Enum.Font.GothamBold
    clearBtn.TextSize = 16
    clearBtn.TextColor3 = C.gray
    clearBtn.AutoButtonColor = false
    clearBtn.Visible = searchQuery ~= ""
    clearBtn.ZIndex = 3
    clearBtn.MouseButton1Click:Connect(function()
        searchBox.Text = ""
    end)

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        searchQuery = searchBox.Text
        clearBtn.Visible = searchQuery ~= ""
        renderEmotes()
    end)

    searchBox.Focused:Connect(function()
        glow.Visible = true
        smoothTween(searchStroke, {Color = C.purple, Thickness = 2}, 0.15)
        smoothTween(searchFrame, {BackgroundColor3 = C.white}, 0.15)
    end)
    searchBox.FocusLost:Connect(function()
        glow.Visible = false
        smoothTween(searchStroke, {Color = C.purple, Thickness = 1}, 0.15)
        smoothTween(searchFrame, {BackgroundColor3 = C.searchBg}, 0.15)
    end)

    return searchFrame
end

local function createTabBar(parent)
    local tabWrap = Instance.new("Frame", parent)
    tabWrap.Size = UDim2.new(1, 0, 0, 40)
    tabWrap.BackgroundColor3 = C.offWhite
    tabWrap.BorderSizePixel = 0
    tabWrap.LayoutOrder = 3
    tabWrap.ZIndex = 1
    corner(tabWrap, 14)
    stroke(tabWrap, C.black, 1, 0)

    local tabLayout = Instance.new("UIListLayout", tabWrap)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 4)

    local btnAll = Instance.new("TextButton", tabWrap)
    btnAll.Size = UDim2.new(0.5, 0, 1, 0)
    btnAll.BackgroundTransparency = 1
    btnAll.Text = ""
    btnAll.AutoButtonColor = false
    btnAll.LayoutOrder = 1
    btnAll.ZIndex = 2

    local btnFav = Instance.new("TextButton", tabWrap)
    btnFav.Size = UDim2.new(0.5, 0, 1, 0)
    btnFav.BackgroundTransparency = 1
    btnFav.Text = ""
    btnFav.AutoButtonColor = false
    btnFav.LayoutOrder = 2
    btnFav.ZIndex = 2

    local function createTabVisual(btn, text)
        local bg = Instance.new("Frame", btn)
        bg.Name = "TabBg"
        bg.Size = UDim2.new(1, -8, 1, -6)
        bg.Position = UDim2.new(0, 4, 0, 3)
        bg.BackgroundColor3 = C.offWhite
        bg.BorderSizePixel = 0
        corner(bg, 10)
        local bgStroke = stroke(bg, C.black, 1, 0)
        bgStroke.Name = "TabStroke"
        bg.ZIndex = 1

        local gradient = Instance.new("UIGradient", bg)
        gradient.Enabled = false
        gradient.Color = ColorSequence.new(C.darkPurple, C.purple)
        gradient.Rotation = 0

        local label = Instance.new("TextLabel", btn)
        label.Name = "TabLabel"
        label.Size = UDim2.new(1, 0, 1, 0)
        label.Position = UDim2.new(0, 0, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = C.black
        label.Font = Enum.Font.GothamBold
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.TextYAlignment = Enum.TextYAlignment.Center
        label.ZIndex = 2

        return bg, bgStroke, gradient, label
    end

    local allBg, allStroke, allGradient, allLabel = createTabVisual(btnAll, "Semua")
    local favBg, favStroke, favGradient, favLabel = createTabVisual(btnFav, "Favorit ★")

    local function updateTabs()
        local allActive = currentTab == "all"
        local favActive = currentTab == "favorites"

        if allActive then
            allGradient.Enabled = true
            allBg.BackgroundColor3 = C.purple
            smoothTween(allLabel, {TextColor3 = C.white}, 0.15)
            smoothTween(allStroke, {Color = C.purple, Thickness = 2}, 0.15)
        else
            allGradient.Enabled = false
            smoothTween(allBg, {BackgroundColor3 = C.offWhite}, 0.15)
            smoothTween(allLabel, {TextColor3 = C.black}, 0.15)
            smoothTween(allStroke, {Color = C.black, Thickness = 1}, 0.15)
        end

        if favActive then
            favGradient.Enabled = true
            favBg.BackgroundColor3 = C.purple
            smoothTween(favLabel, {TextColor3 = C.white}, 0.15)
            smoothTween(favStroke, {Color = C.purple, Thickness = 2}, 0.15)
        else
            favGradient.Enabled = false
            smoothTween(favBg, {BackgroundColor3 = C.offWhite}, 0.15)
            smoothTween(favLabel, {TextColor3 = C.black}, 0.15)
            smoothTween(favStroke, {Color = C.black, Thickness = 1}, 0.15)
        end
    end

    btnAll.MouseButton1Click:Connect(function()
        if currentTab == "all" then return end
        currentTab = "all"
        updateTabs()
        renderEmotes()
    end)
    btnFav.MouseButton1Click:Connect(function()
        if currentTab == "favorites" then return end
        currentTab = "favorites"
        updateTabs()
        renderEmotes()
    end)

    updateTabs()

    return tabWrap
end

local function createLoadingState(parent)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.ZIndex = 10

    local spinner = Instance.new("TextLabel", frame)
    spinner.Size = UDim2.new(0, 40, 0, 40)
    spinner.Position = UDim2.new(0.5, 0, 0.5, -20)
    spinner.AnchorPoint = Vector2.new(0.5, 0.5)
    spinner.BackgroundTransparency = 1
    spinner.Text = "⏳"
    spinner.Font = Enum.Font.GothamBold
    spinner.TextSize = 32
    spinner.TextColor3 = C.purple
    spinner.TextXAlignment = Enum.TextXAlignment.Center
    spinner.TextYAlignment = Enum.TextYAlignment.Center
    spinner.ZIndex = 1

    local text = Instance.new("TextLabel", frame)
    text.Size = UDim2.new(1, 0, 0, 20)
    text.Position = UDim2.new(0.5, 0, 0.5, 20)
    text.AnchorPoint = Vector2.new(0.5, 0)
    text.BackgroundTransparency = 1
    text.Text = "Loading Emotes..."
    text.Font = Enum.Font.GothamMedium
    text.TextSize = 13
    text.TextColor3 = C.gray
    text.TextXAlignment = Enum.TextXAlignment.Center
    text.ZIndex = 1

    task.spawn(function()
        while frame and frame.Visible do
            local tw = TweenService:Create(spinner, TweenInfo.new(1, Enum.EasingStyle.Linear), {Rotation = spinner.Rotation + 360})
            tw:Play()
            tw.Completed:Wait()
            if spinner.Rotation >= 360 then spinner.Rotation = 0 end
        end
    end)

    return frame
end

local function createEmptyState(parent)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.ZIndex = 10

    local star = Instance.new("TextLabel", frame)
    star.Size = UDim2.new(0, 50, 0, 50)
    star.Position = UDim2.new(0.5, 0, 0.5, -40)
    star.AnchorPoint = Vector2.new(0.5, 0.5)
    star.BackgroundTransparency = 1
    star.Text = "★"
    star.Font = Enum.Font.GothamBold
    star.TextSize = 36
    star.TextColor3 = C.lightPurple
    star.ZIndex = 1

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 24)
    title.Position = UDim2.new(0.5, 0, 0.5, 10)
    title.AnchorPoint = Vector2.new(0.5, 0)
    title.BackgroundTransparency = 1
    title.Text = "Belum ada favorit"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextColor3 = C.black
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.ZIndex = 1

    local desc = Instance.new("TextLabel", frame)
    desc.Size = UDim2.new(1, -20, 0, 34)
    desc.Position = UDim2.new(0.5, 0, 0.5, 34)
    desc.AnchorPoint = Vector2.new(0.5, 0)
    desc.BackgroundTransparency = 1
    desc.Text = "Tambahkan emote ke favorit untuk melihatnya di sini."
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 12
    desc.TextColor3 = C.gray
    desc.TextXAlignment = Enum.TextXAlignment.Center
    desc.TextYAlignment = Enum.TextYAlignment.Top
    desc.TextWrapped = true
    desc.ZIndex = 1

    return frame
end

-- ==================== APP BUILDER ====================
local function buildEmoteApp()
    if not appContent then return end

    table.clear(cardPool)
    table.clear(cardConnections)

    -- Clear appContent
    for _, child in ipairs(appContent:GetChildren()) do
        child:Destroy()
    end

    -- Purple glow behind main panel
    local glow = Instance.new("Frame", appContent)
    glow.Size = UDim2.new(1, 4, 1, 4)
    glow.Position = UDim2.new(0, -2, 0, -2)
    glow.BackgroundColor3 = C.purple
    glow.BackgroundTransparency = 0.85
    glow.BorderSizePixel = 0
    corner(glow, 26)
    glow.ZIndex = 0

    -- Main rounded panel
    local mainPanel = Instance.new("Frame", appContent)
    mainPanel.Size = UDim2.new(1, 0, 1, 0)
    mainPanel.Position = UDim2.new(0, 0, 0, 0)
    mainPanel.BackgroundColor3 = C.offWhite
    mainPanel.BorderSizePixel = 0
    corner(mainPanel, 24)
    stroke(mainPanel, C.black, 1, 0)
    mainPanel.ZIndex = 1
    mainPanel.ClipsDescendants = true

    -- Entrance animation
    mainPanel.BackgroundTransparency = 0.3
    mainPanel.Position = UDim2.new(0, 0, 0, 10)
    smoothTween(mainPanel, {BackgroundTransparency = 0, Position = UDim2.new(0, 0, 0, 0)}, 0.25)

    -- Layout
    local layout = Instance.new("UIListLayout", mainPanel)
    layout.Padding = UDim.new(0, 12)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Top

    local padding = Instance.new("UIPadding", mainPanel)
    padding.PaddingTop = UDim.new(0, 12)
    padding.PaddingBottom = UDim.new(0, 12)
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)

    -- Header (no back button)
    local header = createHeader(mainPanel)
    header.LayoutOrder = 1

    -- Search
    local searchFrame = createSearchBar(mainPanel)
    searchFrame.LayoutOrder = 2

    -- Tabs
    local tabBar = createTabBar(mainPanel)
    tabBar.LayoutOrder = 3

    -- Scroll Grid Container
    resultsContainer = Instance.new("ScrollingFrame", mainPanel)
    resultsContainer.Name = "ResultsContainer"
    resultsContainer.Size = UDim2.new(1, 0, 1, -120) -- subtract header/search/tabs/padding
    resultsContainer.BackgroundTransparency = 1
    resultsContainer.BorderSizePixel = 0
    resultsContainer.ScrollBarThickness = 2
    resultsContainer.ScrollBarImageColor3 = C.purple
    resultsContainer.ScrollBarImageTransparency = 0.3
    resultsContainer.LayoutOrder = 4
    resultsContainer.ZIndex = 2
    resultsContainer.ClipsDescendants = true
    resultsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    resultsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)

    local grid = Instance.new("UIGridLayout", resultsContainer)
    grid.CellSize = UDim2.new(0.31, 0, 0, 150)
    grid.CellPadding = UDim2.new(0.035, 0, 0, 10)
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.FillDirection = Enum.FillDirection.Horizontal

    local resPad = Instance.new("UIPadding", resultsContainer)
    resPad.PaddingTop = UDim2.new(0, 4)
    resPad.PaddingBottom = UDim2.new(0, 12)
    resPad.PaddingLeft = UDim2.new(0, 4)
    resPad.PaddingRight = UDim2.new(0, 4)

    grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        resultsContainer.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y + 20)
    end)

    -- Create overlay for loading/empty states (covers grid area)
    contentOverlay = Instance.new("Frame", mainPanel)
    contentOverlay.Name = "ContentOverlay"
    contentOverlay.Size = UDim2.new(1, 0, 1, -120)
    contentOverlay.Position = UDim2.new(0, 0, 0, 0)
    contentOverlay.BackgroundTransparency = 1
    contentOverlay.BorderSizePixel = 0
    contentOverlay.ZIndex = 5
    contentOverlay.Visible = false

    loadingState = createLoadingState(contentOverlay)
    emptyState = createEmptyState(contentOverlay)

    -- Initial render
    print("[Emote] Cache:", #Emotes)
    if #Emotes > 0 then
        -- Cache exists, render immediately
        renderEmotes()
        -- Optionally fetch in background if not loaded
        if not _G.EmoteCache.loading and not _G.EmoteCache.loaded then
            fetchAllEmotes(30)
        end
    else
        -- No cache, show loading and start fetch
        loadingState.Visible = true
        contentOverlay.Visible = true
        fetchAllEmotes(30)
    end
    return true
end

function _G.openEmoteApp() pcall(buildEmoteApp) end
print("[Emote] Premium Futuristic UI with Fixed Loading Applied!")
