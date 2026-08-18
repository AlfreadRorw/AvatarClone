-- ================================================
-- EMOTE.LUA — Grid UI Update (3 Columns Card)
-- Features: All/Fav Tabs, Search, Floating Fav Star
-- ================================================

local Services    = _G.Services
local LocalPlayer = _G.LocalPlayer
local Helpers     = _G.Helpers or {}
local Storage     = _G.Storage or {}
local appContent  = _G.appContent
local appTitle    = _G.appTitle

local HttpService = Services.HttpService
local MarketplaceService = game:GetService("MarketplaceService")
local ContextActionService = game:GetService("ContextActionService")

local corner  = Helpers.corner
local stroke  = Helpers.stroke
local tween   = Helpers.tween
local pressFX = Helpers.pressFX

-- ==================== PALETTE ====================
local C = {
    bg        = Color3.fromRGB(12, 12, 18),
    card      = Color3.fromRGB(22, 22, 30),
    card2     = Color3.fromRGB(30, 30, 42),
    cardHover = Color3.fromRGB(40, 40, 55),
    border    = Color3.fromRGB(55, 55, 75),
    text      = Color3.fromRGB(240, 238, 250),
    text2     = Color3.fromRGB(170, 168, 190),
    text3     = Color3.fromRGB(110, 108, 130),
    accent    = Color3.fromRGB(120, 140, 255),
    accent2   = Color3.fromRGB(80, 220, 150), -- Hijau untuk tombol play
    gold      = Color3.fromRGB(255, 200, 50),
    red       = Color3.fromRGB(255, 90, 100),
    orange    = Color3.fromRGB(255, 150, 50),
    darkOverlay = Color3.fromRGB(0, 0, 0)
}

-- ==================== CACHE GLOBAL ====================
_G.EmoteCache = _G.EmoteCache or {
    emotes = {},           
    favorites = {},        
    loaded = false,
    loading = false,
}

local Emotes = _G.EmoteCache.emotes
local Favorites = _G.EmoteCache.favorites
local isLoaded = _G.EmoteCache.loaded
local isLoading = _G.EmoteCache.loading

-- ==================== STATE ====================
local currentAnimTrack = nil
local currentAnimId = nil
local isPaused = false
local loopEnabled = false
local currentSpeed = 1.0
local currentTab = "all"  
local searchQuery = ""
local currentSort = "recentfirst"
local renderToken = 0

-- ==================== LOAD FAVORITES ====================
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

-- ==================== FETCH EMOTES FROM ROBLOX ====================
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

    if not ok or not result then return nil end
    local body = result.Body or result.body
    if not body then return nil end

    local dok, data = pcall(function() return HttpService:JSONDecode(body) end)
    return dok and data or nil
end

local function fetchAllEmotes(maxPages)
    if isLoading or isLoaded then return end
    isLoading = true
    _G.EmoteCache.loading = true

    maxPages = maxPages or 4 

    task.spawn(function()
        local cursor = ""
        local pages = 0
        local newEmotes = {}

        while pages < maxPages do
            local page = fetchEmotePage(cursor)
            if not page or not page.data or #page.data == 0 then break end

            for _, item in ipairs(page.data) do
                if item.id and item.name then
                    local exists = false
                    for _, e in ipairs(newEmotes) do
                        if e.id == item.id then exists = true; break end
                    end
                    if not exists then
                        table.insert(newEmotes, {
                            id    = item.id,
                            name  = item.name,
                            price = item.price or 0,
                            icon  = "rbxthumb://type=Asset&id=" .. item.id .. "&w=150&h=150",
                            updated = item.updated or "",
                        })
                    end
                end
            end

            cursor = page.nextPageCursor or ""
            pages = pages + 1
            if cursor == "" then break end
            task.wait(0.3)
        end

        local popular = {
            {id = 5915773155, name = "Arm Wave"},
            {id = 5915779725, name = "Head Banging"},
            {id = 9830731012, name = "Face Calisthenics"},
            {id = 7832585357, name = "Floss"},
            {id = 7043924239, name = "Orange Justice"},
        }
        for _, p in ipairs(popular) do
            local exists = false
            for _, e in ipairs(newEmotes) do
                if e.id == p.id then exists = true; break end
            end
            if not exists then
                table.insert(newEmotes, {
                    id    = p.id,
                    name  = p.name,
                    price = 0,
                    icon  = "rbxthumb://type=Asset&id=" .. p.id .. "&w=150&h=150",
                    updated = "",
                })
            end
        end

        for _, e in ipairs(newEmotes) do
            table.insert(Emotes, e)
        end

        isLoaded = true
        isLoading = false
        _G.EmoteCache.loaded = true
        _G.EmoteCache.loading = false

        if appTitle and appTitle.Text == "Emote" then
            if _G.renderEmotesRefresh then _G.renderEmotesRefresh() end
        end

        if _G.showDynamicNotification then
            _G.showDynamicNotification("📦 " .. #Emotes .. " emotes siap!", C.accent2)
        end
    end)
end

-- ==================== SORTING ====================
local function sortEmotes(list, sortType)
    local sorted = {}
    for _, e in ipairs(list) do table.insert(sorted, e) end

    if sortType == "recentfirst" then
        table.sort(sorted, function(a, b) return (a.updated or "") > (b.updated or "") end)
    elseif sortType == "alphabeticfirst" then
        table.sort(sorted, function(a, b) return a.name:lower() < b.name:lower() end)
    end

    return sorted
end

-- ==================== ANIMATION ====================
local function stopAnimation()
    if currentAnimTrack then
        pcall(function() currentAnimTrack:Stop() end)
        currentAnimTrack = nil
        currentAnimId = nil
        isPaused = false
    end
end

local function playEmote(assetId)
    stopAnimation()

    local char = LocalPlayer.Character
    if not char then
        if _G.showDynamicNotification then _G.showDynamicNotification("Karakter tidak ditemukan", C.red) end
        return
    end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    if humanoid.RigType ~= Enum.HumanoidRigType.R15 then
        if _G.showDynamicNotification then _G.showDynamicNotification("Emote hanya untuk R15", C.orange) end
        return
    end

    local track = nil
    local success = false

    pcall(function()
        track = humanoid:PlayEmoteAndGetAnimTrackById(assetId)
        if track then success = true end
    end)

    if not success then
        local description = humanoid:FindFirstChildOfClass("HumanoidDescription")
        if description then
            local emoteName = ""
            for _, e in ipairs(Emotes) do
                if e.id == assetId then emoteName = e.name; break end
            end
            if emoteName == "" then emoteName = "Emote_" .. assetId end 

            pcall(function()
                description:AddEmote(emoteName, assetId)
                track = humanoid:PlayEmoteAndGetAnimTrackById(assetId)
                if track then success = true end
            end)
        end
    end

    if success and track then
        currentAnimTrack = track
        currentAnimId = assetId
        track:AdjustSpeed(currentSpeed)
        track.Looped = loopEnabled
        track:Play()
        isPaused = false

        local name = ""
        for _, e in ipairs(Emotes) do
            if e.id == assetId then name = e.name; break end
        end
        if _G.showDynamicNotification then
            _G.showDynamicNotification("▶ Memutar: " .. (name or "Emote"), C.accent2)
        end
    end
end

-- ==================== RENDER CARD (NEW GRID DESIGN) ====================
local function renderEmoteCard(parent, emote, order, isFavorite)
    local card = Instance.new("Frame", parent)
    -- Ukuran diatur oleh UIGridLayout, tapi kita sediakan default
    card.BackgroundColor3 = C.card
    card.LayoutOrder = order
    card.BackgroundTransparency = 1  
    corner(card, 10)
    stroke(card, C.border, 1, 0.4)

    -- Thumbnail (Gambar)
    local thumb = Instance.new("ImageLabel", card)
    thumb.Size = UDim2.new(1, -8, 0, 75) -- Menyisakan margin 4px tiap sisi
    thumb.Position = UDim2.new(0, 4, 0, 4)
    thumb.BackgroundColor3 = C.card2
    thumb.Image = emote.icon or "rbxassetid://0"
    thumb.ScaleType = Enum.ScaleType.Fit
    corner(thumb, 8)

    -- Tombol Bintang Favorit (Melayang di dalam gambar, Pojok Kanan Atas)
    local favBtn = Instance.new("TextButton", thumb)
    favBtn.Size = UDim2.new(0, 24, 0, 24)
    favBtn.Position = UDim2.new(1, -26, 0, 2)
    favBtn.BackgroundTransparency = 1
    favBtn.Text = isFavorite and "★" or "☆"
    favBtn.TextColor3 = isFavorite and C.gold or Color3.new(1, 1, 1)
    favBtn.Font = Enum.Font.GothamBold
    favBtn.TextSize = 18
    favBtn.AutoButtonColor = false
    
    -- Outline pada bintang agar terbaca walau background gambar terang
    local favStroke = Instance.new("TextStroke", favBtn)
    favStroke.Color = Color3.new(0,0,0)
    favStroke.Transparency = 0.3
    favStroke.Thickness = 1.5

    favBtn.MouseButton1Click:Connect(function()
        local idx = table.find(Favorites, emote.id)
        if idx then
            table.remove(Favorites, idx)
            favBtn.Text = "☆"
            favBtn.TextColor3 = Color3.new(1, 1, 1)
        else
            table.insert(Favorites, emote.id)
            favBtn.Text = "★"
            favBtn.TextColor3 = C.gold
        end
        saveFavorites()
        if currentTab == "favorites" and _G.renderEmotesRefresh then
            _G.renderEmotesRefresh()
        end
    end)

    -- Nama Emote
    local nameLbl = Instance.new("TextLabel", card)
    nameLbl.Size = UDim2.new(1, -10, 0, 16)
    nameLbl.Position = UDim2.new(0, 5, 0, 84)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = emote.name or "Emote"
    nameLbl.TextColor3 = C.text
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 10
    nameLbl.TextXAlignment = Enum.TextXAlignment.Center
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

    -- Tombol Play (Di Bawah)
    local playBtn = Instance.new("TextButton", card)
    playBtn.Size = UDim2.new(1, -12, 0, 26)
    playBtn.Position = UDim2.new(0, 6, 1, -32)
    playBtn.BackgroundColor3 = C.card2
    playBtn.Text = "▶ PLAY"
    playBtn.TextColor3 = C.text
    playBtn.Font = Enum.Font.GothamBlack
    playBtn.TextSize = 10
    playBtn.AutoButtonColor = false
    corner(playBtn, 6)
    stroke(playBtn, C.border, 1, 0.5)
    pressFX(playBtn)
    
    playBtn.MouseEnter:Connect(function() tween(playBtn, {BackgroundColor3 = C.accent}, 0.2) end)
    playBtn.MouseLeave:Connect(function() tween(playBtn, {BackgroundColor3 = C.card2}, 0.2) end)

    playBtn.MouseButton1Click:Connect(function()
        playEmote(emote.id)
    end)

    -- Animasi Masuk
    task.spawn(function()
        task.wait(order * 0.01)  
        if card.Parent then
            tween(card, {BackgroundTransparency = 0}, 0.2)
        end
    end)

    return card
end

-- ==================== BUKA APP ====================
local resultsContainer = nil
local infoLbl = nil

local function renderEmotes()
    local token = renderToken + 1
    renderToken = token

    if not resultsContainer then return end
    for _, c in ipairs(resultsContainer:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    local filtered = {}
    local q = searchQuery:lower()

    for _, e in ipairs(Emotes) do
        if currentTab == "favorites" then
            local isFav = table.find(Favorites, e.id) ~= nil
            if not isFav then continue end
        end

        if q == "" or e.name:lower():find(q, 1, true) then
            table.insert(filtered, e)
        end
    end

    local sorted = sortEmotes(filtered, currentSort)

    if infoLbl then
        infoLbl.Text = #sorted .. " emote" .. (#sorted ~= 1 and "s" or "")
    end

    if #sorted == 0 then
        local empty = Instance.new("TextLabel", resultsContainer)
        empty.Size = UDim2.new(1, 0, 0, 60)
        empty.BackgroundTransparency = 1
        empty.Text = currentTab == "favorites" and "Belum ada emote favorit\n★ Tap bintang di emote!" or "😢 Emote tidak ditemukan"
        empty.TextColor3 = C.text3
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 12
        empty.TextWrapped = true
        empty.LayoutOrder = 0
        
        -- Override grid behavior for the empty text temporarily
        local tempLayout = resultsContainer:FindFirstChild("UIGridLayout")
        if tempLayout then tempLayout.CellSize = UDim2.new(1, -12, 0, 60) end
        return
    else
        -- Restore grid size if previously empty
        local tempLayout = resultsContainer:FindFirstChild("UIGridLayout")
        if tempLayout then tempLayout.CellSize = UDim2.new(0.315, 0, 0, 140) end
    end

    local BATCH_SIZE = 6 -- Render 6 sekaligus agar lebih cepat
    local total = #sorted

    task.spawn(function()
        local i = 1
        while i <= total do
            if renderToken ~= token then return end 

            local batchEnd = math.min(i + BATCH_SIZE - 1, total)
            for idx = i, batchEnd do
                local emote = sorted[idx]
                local isFav = table.find(Favorites, emote.id) ~= nil
                renderEmoteCard(resultsContainer, emote, idx, isFav)
            end

            i = batchEnd + 1
            if i <= total then task.wait() end
        end
    end)
end
_G.renderEmotesRefresh = renderEmotes

function _G.openEmoteApp()
    if appContent then
        appContent:ClearAllChildren()
    end

    -- ===== SEARCH & TAB BAR (Digabung agar ringkas) =====
    local topBar = Instance.new("Frame", appContent)
    topBar.Size = UDim2.new(1, 0, 0, 40)
    topBar.BackgroundTransparency = 1
    topBar.LayoutOrder = 1

    local searchFrame = Instance.new("Frame", topBar)
    searchFrame.Size = UDim2.new(1, -150, 1, 0)
    searchFrame.BackgroundColor3 = C.card
    corner(searchFrame, 10)
    stroke(searchFrame, C.border, 1, 0.4)

    local searchBox = Instance.new("TextBox", searchFrame)
    searchBox.Size = UDim2.new(1, -30, 1, 0)
    searchBox.Position = UDim2.new(0, 25, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.PlaceholderText = "Cari emote..."
    searchBox.PlaceholderColor3 = C.text3
    searchBox.Text = ""
    searchBox.TextColor3 = C.text
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 11
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.ClearTextOnFocus = false
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        searchQuery = searchBox.Text
        renderEmotes()
    end)
    
    local searchIcon = Instance.new("TextLabel", searchFrame)
    searchIcon.Size = UDim2.new(0, 20, 1, 0)
    searchIcon.Position = UDim2.new(0, 5, 0, 0)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Text = "🔍"
    searchIcon.TextSize = 11

    -- TABS
    local tabFrame = Instance.new("Frame", topBar)
    tabFrame.Size = UDim2.new(0, 140, 1, 0)
    tabFrame.Position = UDim2.new(1, -140, 0, 0)
    tabFrame.BackgroundColor3 = C.card
    corner(tabFrame, 10)
    stroke(tabFrame, C.border, 1, 0.4)

    local tabLayout = Instance.new("UIListLayout", tabFrame)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local tabs = { {id = "all", label = "Semua"}, {id = "favorites", label = "★ Fav"} }
    local tabBtns = {}
    
    for i, tab in ipairs(tabs) do
        local btn = Instance.new("TextButton", tabFrame)
        btn.Size = UDim2.new(0, 65, 0, 32)
        btn.BackgroundColor3 = (currentTab == tab.id) and C.accent or C.card2
        btn.Text = tab.label
        btn.TextColor3 = (currentTab == tab.id) and Color3.new(1, 1, 1) or C.text2
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.AutoButtonColor = false
        corner(btn, 8)
        pressFX(btn)
        
        btn.MouseButton1Click:Connect(function()
            currentTab = tab.id
            for _, b in ipairs(tabBtns) do
                b.BackgroundColor3 = C.card2
                b.TextColor3 = C.text2
            end
            btn.BackgroundColor3 = C.accent
            btn.TextColor3 = Color3.new(1, 1, 1)
            renderEmotes()
        end)
        tabBtns[i] = btn
    end

    -- ===== INFO BAR =====
    local infoBar = Instance.new("Frame", appContent)
    infoBar.Size = UDim2.new(1, 0, 0, 20)
    infoBar.BackgroundTransparency = 1
    infoBar.LayoutOrder = 2

    infoLbl = Instance.new("TextLabel", infoBar)
    infoLbl.Size = UDim2.new(1, 0, 1, 0)
    infoLbl.BackgroundTransparency = 1
    infoLbl.Text = "Memuat data..."
    infoLbl.TextColor3 = C.text3
    infoLbl.Font = Enum.Font.Gotham
    infoLbl.TextSize = 10
    infoLbl.TextXAlignment = Enum.TextXAlignment.Left

    -- ===== RESULTS (THE GRID) =====
    resultsContainer = Instance.new("ScrollingFrame", appContent)
    resultsContainer.Size = UDim2.new(1, 0, 0, 280)
    resultsContainer.BackgroundColor3 = C.bg
    resultsContainer.BorderSizePixel = 0
    resultsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    resultsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    resultsContainer.ScrollBarThickness = 2
    resultsContainer.ScrollBarImageColor3 = C.border
    resultsContainer.LayoutOrder = 3
    corner(resultsContainer, 12)

    local resPad = Instance.new("UIPadding", resultsContainer)
    resPad.PaddingTop = UDim.new(0, 4)
    resPad.PaddingBottom = UDim.new(0, 4)
    resPad.PaddingLeft = UDim.new(0, 4)
    resPad.PaddingRight = UDim.new(0, 4)

    -- INI ADALAH KUNCI UNTUK 3 KE SAMPING (GRID)
    local gridLayout = Instance.new("UIGridLayout", resultsContainer)
    gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
    gridLayout.CellSize = UDim2.new(0.315, 0, 0, 140) -- Skala width agar pas 3 item
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- ===== PLAYBACK CONTROLS =====
    local controls = Instance.new("Frame", appContent)
    controls.Size = UDim2.new(1, 0, 0, 45)
    controls.BackgroundColor3 = C.card
    controls.LayoutOrder = 4
    corner(controls, 12)
    stroke(controls, C.border, 1, 0.4)

    local cLayout = Instance.new("UIListLayout", controls)
    cLayout.FillDirection = Enum.FillDirection.Horizontal
    cLayout.Padding = UDim.new(0, 6)
    cLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    cLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local stopBtn = Instance.new("TextButton", controls)
    stopBtn.Size = UDim2.new(0, 36, 0, 30)
    stopBtn.BackgroundColor3 = C.red
    stopBtn.Text = "⏹"
    stopBtn.TextColor3 = Color3.new(1, 1, 1)
    stopBtn.Font = Enum.Font.GothamBlack
    stopBtn.TextSize = 14
    stopBtn.AutoButtonColor = false
    corner(stopBtn, 8)
    pressFX(stopBtn)
    stopBtn.MouseButton1Click:Connect(function() stopAnimation() end)

    local pauseBtn = Instance.new("TextButton", controls)
    pauseBtn.Size = UDim2.new(0, 36, 0, 30)
    pauseBtn.BackgroundColor3 = C.card2
    pauseBtn.Text = "⏸"
    pauseBtn.TextColor3 = C.text
    pauseBtn.Font = Enum.Font.GothamBlack
    pauseBtn.TextSize = 14
    pauseBtn.AutoButtonColor = false
    corner(pauseBtn, 8)
    pressFX(pauseBtn)
    pauseBtn.MouseButton1Click:Connect(function()
        if not currentAnimTrack then return end
        if isPaused then
            currentAnimTrack:Play()
            isPaused = false
            pauseBtn.Text = "⏸"
        else
            currentAnimTrack:Pause()
            isPaused = true
            pauseBtn.Text = "▶"
        end
    end)

    local loopBtn = Instance.new("TextButton", controls)
    loopBtn.Size = UDim2.new(0, 48, 0, 30)
    loopBtn.BackgroundColor3 = loopEnabled and C.accent or C.card2
    loopBtn.Text = "Loop"
    loopBtn.TextColor3 = loopEnabled and Color3.new(1, 1, 1) or C.text2
    loopBtn.Font = Enum.Font.GothamBold
    loopBtn.TextSize = 11
    loopBtn.AutoButtonColor = false
    corner(loopBtn, 8)
    pressFX(loopBtn)
    loopBtn.MouseButton1Click:Connect(function()
        loopEnabled = not loopEnabled
        if currentAnimTrack then currentAnimTrack.Looped = loopEnabled end
        loopBtn.BackgroundColor3 = loopEnabled and C.accent or C.card2
        loopBtn.TextColor3 = loopEnabled and Color3.new(1, 1, 1) or C.text2
    end)

    -- ===== INITIALIZE =====
    if not isLoaded and not isLoading then
        fetchAllEmotes(4)
    end

    task.spawn(function()
        task.wait(0.1)
        renderEmotes()
    end)

    return true
end
