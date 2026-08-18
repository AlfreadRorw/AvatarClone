-- ================================================
-- EMOTE APP — Roblox Emote Catalog + Favorites
-- Full integration with Phone ID Viewer
-- Dark theme, search, sort, playback controls
-- ================================================

local Services    = _G.Services
local LocalPlayer = _G.LocalPlayer
local Helpers     = _G.Helpers or {}
local Storage     = _G.Storage or {}
local appContent  = _G.appContent

local HttpService       = Services.HttpService
local MarketplaceService = game:GetService("MarketplaceService")
local ContextActionService = game:GetService("ContextActionService")

local corner  = Helpers.corner
local stroke  = Helpers.stroke
local tween   = Helpers.tween
local pressFX = Helpers.pressFX

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
    pink      = Color3.fromRGB(255, 120, 200),
    orange    = Color3.fromRGB(255, 150, 50),
}

-- ==================== STATE ====================
local Emotes = {}               -- semua emote yang sudah di-load
local EmoteLoadingStatus = {}   -- track loading tiap emote (id -> bool)
local Favorites = {}            -- daftar id emote favorit (integer)
local currentAnimTrack = nil    -- AnimatorTrack yang sedang diputar
local currentAnimId = nil       -- assetId emote yang sedang diputar
local isPaused = false
local loopEnabled = false
local currentSpeed = 1.0
local pageSize = 30
local currentPage = 1
local totalPages = 1
local searchQuery = ""
local currentSort = "recentfirst" -- recentfirst | recentlast | alphabeticfirst | alphabeticlast | highestprice | lowestprice
local isLoading = false
local isFetchingMore = false
local allLoaded = false
local lastCursor = ""

-- ==================== LOAD FAVORITES ====================
local function loadFavorites()
    if Storage and Storage.appSettings then
        Storage.appSettings.emoteFavorites = Storage.appSettings.emoteFavorites or {}
        Favorites = Storage.appSettings.emoteFavorites
        -- pastikan semua id adalah integer
        for i, v in ipairs(Favorites) do
            Favorites[i] = tonumber(v) or v
        end
    end
end

local function saveFavorites()
    if Storage and Storage.appSettings then
        Storage.appSettings.emoteFavorites = Favorites
        pcall(function()
            if Storage.persistSettings then Storage.persistSettings() end
        end)
    end
end

loadFavorites()

-- ==================== HELPER: GET EMOTE INFO ====================
local function getEmoteInfo(assetId)
    -- Cari di Emotes yang sudah di-load
    for _, e in ipairs(Emotes) do
        if e.id == assetId then return e end
    end
    return nil
end

-- ==================== FETCH EMOTES FROM ROBLOX CATALOG ====================
-- Roblox API: Category=12 (Animations), Subcategory=39 (Emotes)
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

-- Ambil semua halaman (dibatasi agar tidak terlalu berat)
local function fetchAllEmotes(maxPages)
    maxPages = maxPages or 5 -- ambil sampai ~150 emotes, cukup
    local cursor = ""
    local pages = 0

    while pages < maxPages do
        local page = fetchEmotePage(cursor)
        if not page or not page.data or #page.data == 0 then break end

        for _, item in ipairs(page.data) do
            if item.id and item.name then
                -- Cegah duplikat
                local exists = false
                for _, e in ipairs(Emotes) do
                    if e.id == item.id then exists = true; break end
                end
                if not exists then
                    table.insert(Emotes, {
                        id    = item.id,
                        name  = item.name,
                        price = item.price or 0,
                        icon  = "rbxthumb://type=Asset&id=" .. item.id .. "&w=150&h=150",
                        updated = item.updated or "",
                    })
                    EmoteLoadingStatus[item.id] = false
                    -- Load thumbnail secara asinkron (pakai ImageLabel otomatis)
                end
            end
        end

        cursor = page.nextPageCursor or ""
        pages = pages + 1
        if cursor == "" then break end
        task.wait(0.5) -- rate limit
    end

    -- Tambahkan beberapa emote populer yang mungkin tidak muncul di catalog API
    local popular = {
        {id = 5915773155, name = "Arm Wave"},
        {id = 5915779725, name = "Head Banging"},
        {id = 9830731012, name = "Face Calisthenics"},
        {id = 7832585357, name = "Floss"},
        {id = 7043924239, name = "Orange Justice"},
        {id = 9999999999, name = "Take The L"}, -- dummy
    }
    for _, p in ipairs(popular) do
        local exists = false
        for _, e in ipairs(Emotes) do
            if e.id == p.id then exists = true; break end
        end
        if not exists then
            table.insert(Emotes, {
                id    = p.id,
                name  = p.name,
                price = 0,
                icon  = "rbxthumb://type=Asset&id=" .. p.id .. "&w=150&h=150",
                updated = "",
            })
            EmoteLoadingStatus[p.id] = true
        end
    end
end

-- ==================== SORTING ====================
local function sortEmotes(list, sortType)
    local sorted = {}
    for _, e in ipairs(list) do table.insert(sorted, e) end

    if sortType == "recentfirst" then
        table.sort(sorted, function(a, b) return (a.updated or "") > (b.updated or "") end)
    elseif sortType == "recentlast" then
        table.sort(sorted, function(a, b) return (a.updated or "") < (b.updated or "") end)
    elseif sortType == "alphabeticfirst" then
        table.sort(sorted, function(a, b) return a.name:lower() < b.name:lower() end)
    elseif sortType == "alphabeticlast" then
        table.sort(sorted, function(a, b) return a.name:lower() > b.name:lower() end)
    elseif sortType == "highestprice" then
        table.sort(sorted, function(a, b) return (a.price or 0) > (b.price or 0) end)
    elseif sortType == "lowestprice" then
        table.sort(sorted, function(a, b) return (a.price or 0) < (b.price or 0) end)
    end

    return sorted
end

-- ==================== ANIMATION PLAYBACK ====================
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
    if not humanoid then
        if _G.showDynamicNotification then _G.showDynamicNotification("Humanoid tidak ditemukan", C.red) end
        return
    end

    -- Periksa apakah R15, karena sebagian besar emote membutuhkan R15
    if humanoid.RigType ~= Enum.HumanoidRigType.R15 then
        if _G.showDynamicNotification then _G.showDynamicNotification("Emote hanya untuk R15", C.orange) end
        return
    end

    local success = false
    local track = nil

    -- Coba metode standar PlayEmoteAndGetAnimTrackById (hanya R15)
    pcall(function()
        track = humanoid:PlayEmoteAndGetAnimTrackById(assetId)
        if track then success = true end
    end)

    -- Jika gagal, coba tambahkan ke HumanoidDescription dulu
    if not success then
        local description = humanoid:FindFirstChildOfClass("HumanoidDescription")
        if description then
            pcall(function()
                -- Cari nama emote
                local emoteName = ""
                for _, e in ipairs(Emotes) do
                    if e.id == assetId then emoteName = e.name; break end
                end
                if emoteName == "" then emoteName = "Emote_" .. assetId end

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

        if _G.showDynamicNotification then
            local name = ""
            for _, e in ipairs(Emotes) do
                if e.id == assetId then name = e.name; break end
            end
            _G.showDynamicNotification("▶ " .. (name or "Emote"), C.accent2)
        end
    else
        if _G.showDynamicNotification then
            _G.showDynamicNotification("Gagal memutar emote " .. assetId, C.red)
        end
    end
end

-- ==================== RENDER CARD ====================
local function renderEmoteCard(parent, emote, order)
    local card = Instance.new("Frame", parent)
    card.Size = UDim2.new(1, 0, 0, 70)
    card.BackgroundColor3 = C.card
    card.LayoutOrder = order
    corner(card, 12)
    stroke(card, C.border, 1, 0.3)

    -- Thumbnail
    local thumb = Instance.new("ImageLabel", card)
    thumb.Size = UDim2.new(0, 50, 0, 50)
    thumb.Position = UDim2.new(0, 10, 0.5, -25)
    thumb.BackgroundColor3 = C.card2
    thumb.Image = emote.icon or "rbxassetid://0"
    thumb.ScaleType = Enum.ScaleType.Fit
    corner(thumb, 8)
    stroke(thumb, C.border, 1, 0.2)

    -- Nama
    local nameLbl = Instance.new("TextLabel", card)
    nameLbl.Size = UDim2.new(1, -160, 0, 20)
    nameLbl.Position = UDim2.new(0, 68, 0, 10)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = emote.name or "Emote"
    nameLbl.TextColor3 = C.text
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 12
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

    -- ID / Price
    local infoLbl = Instance.new("TextLabel", card)
    infoLbl.Size = UDim2.new(1, -160, 0, 16)
    infoLbl.Position = UDim2.new(0, 68, 0, 30)
    infoLbl.BackgroundTransparency = 1
    local priceStr = (emote.price and emote.price > 0) and ("💰 " .. emote.price .. " Robux") or "🆓 Gratis"
    infoLbl.Text = "ID: " .. emote.id .. "  |  " .. priceStr
    infoLbl.TextColor3 = C.text2
    infoLbl.Font = Enum.Font.Gotham
    infoLbl.TextSize = 9
    infoLbl.TextXAlignment = Enum.TextXAlignment.Left

    -- Tombol Play
    local playBtn = Instance.new("TextButton", card)
    playBtn.Size = UDim2.new(0, 56, 0, 30)
    playBtn.Position = UDim2.new(1, -70, 0.5, -15)
    playBtn.BackgroundColor3 = C.accent2
    playBtn.Text = "▶"
    playBtn.TextColor3 = Color3.new(1, 1, 1)
    playBtn.Font = Enum.Font.GothamBlack
    playBtn.TextSize = 14
    playBtn.AutoButtonColor = false
    corner(playBtn, 8)
    pressFX(playBtn)

    playBtn.MouseButton1Click:Connect(function()
        playEmote(emote.id)
    end)

    -- Tombol Favorite (bintang)
    local isFav = table.find(Favorites, emote.id) ~= nil
    local favBtn = Instance.new("TextButton", card)
    favBtn.Size = UDim2.new(0, 30, 0, 30)
    favBtn.Position = UDim2.new(1, -106, 0.5, -15)
    favBtn.BackgroundTransparency = 1
    favBtn.Text = isFav and "★" or "☆"
    favBtn.TextColor3 = isFav and C.gold or C.text3
    favBtn.Font = Enum.Font.GothamBold
    favBtn.TextSize = 18
    favBtn.AutoButtonColor = false
    favBtn.MouseButton1Click:Connect(function()
        local idx = table.find(Favorites, emote.id)
        if idx then
            table.remove(Favorites, idx)
            favBtn.Text = "☆"
            favBtn.TextColor3 = C.text3
            if _G.showDynamicNotification then _G.showDynamicNotification("Dihapus dari favorit", C.text3) end
        else
            table.insert(Favorites, emote.id)
            favBtn.Text = "★"
            favBtn.TextColor3 = C.gold
            if _G.showDynamicNotification then _G.showDynamicNotification("Ditambahkan ke favorit!", C.gold) end
        end
        saveFavorites()
    end)

    return card
end

-- ==================== RENDER GRID ====================
local function renderGrid(list)
    -- Bersihkan container
    for _, c in ipairs(resultsContainer:GetChildren()) do
        if c:IsA("Frame") or c:IsA("ImageLabel") then
            if c.Name ~= "GridLayout" and c.Name ~= "UIPadding" then
                c:Destroy()
            end
        end
    end

    if #list == 0 then
        local empty = Instance.new("TextLabel", resultsContainer)
        empty.Size = UDim2.new(1, 0, 0, 60)
        empty.BackgroundTransparency = 1
        empty.Text = "😢 Tidak ada emote ditemukan"
        empty.TextColor3 = C.text3
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 13
        empty.TextWrapped = true
        empty.LayoutOrder = 0
        return
    end

    for i, emote in ipairs(list) do
        renderEmoteCard(resultsContainer, emote, i)
    end
end

-- ==================== UPDATE DISPLAY ====================
local function updateDisplay()
    if isLoading then return end

    -- Filter berdasarkan search
    local filtered = {}
    local q = searchQuery:lower()
    for _, e in ipairs(Emotes) do
        if q == "" or e.name:lower():find(q, 1, true) then
            table.insert(filtered, e)
        end
    end

    -- Sort
    local sorted = sortEmotes(filtered, currentSort)

    -- Pagination
    totalPages = math.max(1, math.ceil(#sorted / pageSize))
    currentPage = math.clamp(currentPage, 1, totalPages)

    local startIdx = (currentPage - 1) * pageSize + 1
    local endIdx = math.min(currentPage * pageSize, #sorted)

    local pageItems = {}
    for i = startIdx, endIdx do
        table.insert(pageItems, sorted[i])
    end

    renderGrid(pageItems)

    -- Update info label
    if infoLbl then
        infoLbl.Text = "Menampilkan " .. #pageItems .. " dari " .. #sorted .. " emote  |  Halaman " .. currentPage .. "/" .. totalPages
    end

    -- Update pagination buttons
    if prevBtn and nextBtn then
        prevBtn.BackgroundColor3 = (currentPage > 1) and C.card2 or C.bg
        nextBtn.BackgroundColor3 = (currentPage < totalPages) and C.card2 or C.bg
        prevBtn.TextColor3 = (currentPage > 1) and C.text or C.text3
        nextBtn.TextColor3 = (currentPage < totalPages) and C.text or C.text3
    end
end

-- ==================== LOAD ALL EMOTES (first time) ====================
local function loadAllEmotesAsync()
    if isLoading then return end
    isLoading = true

    if infoLbl then infoLbl.Text = "Memuat emote dari catalog..." end

    task.spawn(function()
        fetchAllEmotes(5) -- ambil beberapa halaman

        -- Tandai semua sudah di-load (thumbnails akan muncul otomatis)
        allLoaded = true
        isLoading = false

        if infoLbl then
            infoLbl.Text = "✅ " .. #Emotes .. " emote dimuat"
        end

        updateDisplay()

        if _G.showDynamicNotification then
            _G.showDynamicNotification("📦 " .. #Emotes .. " emote siap!", C.green)
        end
    end)
end

-- ==================== REFERENCE VARIABLES ====================
local resultsContainer = nil
local infoLbl = nil
local prevBtn = nil
local nextBtn = nil

-- ==================== BUKA APP ====================
function _G.openEmoteApp()
    -- ===== HEADER =====
    local header = Instance.new("Frame", appContent)
    header.Size = UDim2.new(1, 0, 0, 46)
    header.BackgroundColor3 = C.card
    header.LayoutOrder = 0
    corner(header, 14)
    stroke(header, C.accent, 1, 0.5)

    local hTitle = Instance.new("TextLabel", header)
    hTitle.Size = UDim2.new(1, -70, 0, 22)
    hTitle.Position = UDim2.new(0, 14, 0, 4)
    hTitle.BackgroundTransparency = 1
    hTitle.Text = "💃 Emote Catalog"
    hTitle.TextColor3 = C.text
    hTitle.Font = Enum.Font.GothamBlack
    hTitle.TextSize = 15
    hTitle.TextXAlignment = Enum.TextXAlignment.Left

    local hSub = Instance.new("TextLabel", header)
    hSub.Size = UDim2.new(1, -70, 0, 14)
    hSub.Position = UDim2.new(0, 14, 0, 26)
    hSub.BackgroundTransparency = 1
    hSub.Text = "Pilih & mainkan emote favoritmu"
    hSub.TextColor3 = C.text2
    hSub.Font = Enum.Font.Gotham
    hSub.TextSize = 9
    hSub.TextXAlignment = Enum.TextXAlignment.Left

    -- ===== SEARCH BAR =====
    local searchFrame = Instance.new("Frame", appContent)
    searchFrame.Size = UDim2.new(1, 0, 0, 38)
    searchFrame.BackgroundColor3 = C.card2
    searchFrame.LayoutOrder = 1
    corner(searchFrame, 12)
    stroke(searchFrame, C.border, 1, 0.3)

    local searchBox = Instance.new("TextBox", searchFrame)
    searchBox.Size = UDim2.new(1, -56, 1, 0)
    searchBox.Position = UDim2.new(0, 10, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.PlaceholderText = "Cari emote..."
    searchBox.PlaceholderColor3 = C.text3
    searchBox.Text = ""
    searchBox.TextColor3 = C.text
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 11
    searchBox.ClearTextOnFocus = false

    local searchIcon = Instance.new("TextLabel", searchFrame)
    searchIcon.Size = UDim2.new(0, 30, 1, 0)
    searchIcon.Position = UDim2.new(1, -36, 0, 0)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Text = "🔍"
    searchIcon.TextSize = 14

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        searchQuery = searchBox.Text
        currentPage = 1
        updateDisplay()
    end)

    -- ===== SORT & FILTER ROW =====
    local sortRow = Instance.new("Frame", appContent)
    sortRow.Size = UDim2.new(1, 0, 0, 30)
    sortRow.BackgroundTransparency = 1
    sortRow.LayoutOrder = 2

    local sortLayout = Instance.new("UIListLayout", sortRow)
    sortLayout.FillDirection = Enum.FillDirection.Horizontal
    sortLayout.Padding = UDim.new(0, 6)

    local sortOptions = {
        {label = "Terbaru",   value = "recentfirst"},
        {label = "Terlama",   value = "recentlast"},
        {label = "A-Z",       value = "alphabeticfirst"},
        {label = "Z-A",       value = "alphabeticlast"},
        {label = "Termahal",  value = "highestprice"},
        {label = "Termurah",  value = "lowestprice"},
    }

    for _, opt in ipairs(sortOptions) do
        local btn = Instance.new("TextButton", sortRow)
        btn.Size = UDim2.new(0, 0, 1, 0)
        btn.AutomaticSize = Enum.AutomaticSize.X
        btn.BackgroundColor3 = (currentSort == opt.value) and C.accent or C.card2
        btn.Text = opt.label
        btn.TextColor3 = (currentSort == opt.value) and Color3.new(1, 1, 1) or C.text2
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 9
        btn.AutoButtonColor = false
        corner(btn, 8)
        pressFX(btn)

        local pad = Instance.new("UIPadding", btn)
        pad.PaddingLeft = UDim.new(0, 8)
        pad.PaddingRight = UDim.new(0, 8)

        btn.MouseButton1Click:Connect(function()
            currentSort = opt.value
            currentPage = 1
            updateDisplay()
            -- Refresh warna tombol
            for _, child in ipairs(sortRow:GetChildren()) do
                if child:IsA("TextButton") then
                    for _, o in ipairs(sortOptions) do
                        if child.Text == o.label then
                            if o.value == currentSort then
                                child.BackgroundColor3 = C.accent
                                child.TextColor3 = Color3.new(1, 1, 1)
                            else
                                child.BackgroundColor3 = C.card2
                                child.TextColor3 = C.text2
                            end
                        end
                    end
                end
            end
        end)
    end

    -- ===== INFO BAR =====
    local infoBar = Instance.new("Frame", appContent)
    infoBar.Size = UDim2.new(1, 0, 0, 20)
    infoBar.BackgroundTransparency = 1
    infoBar.LayoutOrder = 3

    infoLbl = Instance.new("TextLabel", infoBar)
    infoLbl.Size = UDim2.new(1, -90, 1, 0)
    infoLbl.BackgroundTransparency = 1
    infoLbl.Text = "Memuat emote..."
    infoLbl.TextColor3 = C.text3
    infoLbl.Font = Enum.Font.Gotham
    infoLbl.TextSize = 9
    infoLbl.TextXAlignment = Enum.TextXAlignment.Left

    -- ===== RESULTS CONTAINER =====
    resultsContainer = Instance.new("ScrollingFrame", appContent)
    resultsContainer.Size = UDim2.new(1, 0, 0, 300)
    resultsContainer.BackgroundColor3 = C.bg
    resultsContainer.BorderSizePixel = 0
    resultsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    resultsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    resultsContainer.ScrollBarThickness = 3
    resultsContainer.ScrollBarImageColor3 = C.accent
    resultsContainer.LayoutOrder = 4
    corner(resultsContainer, 12)
    stroke(resultsContainer, C.border, 1, 0.3)

    local resPad = Instance.new("UIPadding", resultsContainer)
    resPad.PaddingTop = UDim.new(0, 6)
    resPad.PaddingBottom = UDim.new(0, 6)
    resPad.PaddingLeft = UDim.new(0, 6)
    resPad.PaddingRight = UDim.new(0, 6)

    local resLayout = Instance.new("UIListLayout", resultsContainer)
    resLayout.Padding = UDim.new(0, 6)
    resLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- ===== PAGINATION =====
    local pageRow = Instance.new("Frame", appContent)
    pageRow.Size = UDim2.new(1, 0, 0, 34)
    pageRow.BackgroundTransparency = 1
    pageRow.LayoutOrder = 5

    local pageLayout = Instance.new("UIListLayout", pageRow)
    pageLayout.FillDirection = Enum.FillDirection.Horizontal
    pageLayout.Padding = UDim.new(0, 8)
    pageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    prevBtn = Instance.new("TextButton", pageRow)
    prevBtn.Size = UDim2.new(0, 70, 1, 0)
    prevBtn.BackgroundColor3 = C.card2
    prevBtn.Text = "◀ Prev"
    prevBtn.TextColor3 = C.text2
    prevBtn.Font = Enum.Font.GothamBold
    prevBtn.TextSize = 10
    prevBtn.AutoButtonColor = false
    corner(prevBtn, 8)
    pressFX(prevBtn)
    prevBtn.MouseButton1Click:Connect(function()
        if currentPage > 1 then
            currentPage = currentPage - 1
            updateDisplay()
        end
    end)

    local pageInfo = Instance.new("TextLabel", pageRow)
    pageInfo.Size = UDim2.new(0, 80, 1, 0)
    pageInfo.BackgroundTransparency = 1
    pageInfo.Text = "1 / 1"
    pageInfo.TextColor3 = C.text2
    pageInfo.Font = Enum.Font.Gotham
    pageInfo.TextSize = 10
    pageInfo.TextXAlignment = Enum.TextXAlignment.Center

    nextBtn = Instance.new("TextButton", pageRow)
    nextBtn.Size = UDim2.new(0, 70, 1, 0)
    nextBtn.BackgroundColor3 = C.card2
    nextBtn.Text = "Next ▶"
    nextBtn.TextColor3 = C.text2
    nextBtn.Font = Enum.Font.GothamBold
    nextBtn.TextSize = 10
    nextBtn.AutoButtonColor = false
    corner(nextBtn, 8)
    pressFX(nextBtn)
    nextBtn.MouseButton1Click:Connect(function()
        if currentPage < totalPages then
            currentPage = currentPage + 1
            updateDisplay()
        end
    end)

    -- Override updateDisplay untuk update pageInfo
    local oldUpdate = updateDisplay
    updateDisplay = function()
        oldUpdate()
        if pageInfo then
            pageInfo.Text = currentPage .. " / " .. totalPages
        end
    end

    -- ===== CONTROLS (Playback) =====
    local controls = Instance.new("Frame", appContent)
    controls.Size = UDim2.new(1, 0, 0, 48)
    controls.BackgroundColor3 = C.card2
    controls.LayoutOrder = 6
    corner(controls, 12)
    stroke(controls, C.border, 1, 0.3)

    local cLayout = Instance.new("UIListLayout", controls)
    cLayout.FillDirection = Enum.FillDirection.Horizontal
    cLayout.Padding = UDim.new(0, 6)
    cLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    cLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    -- Speed buttons
    local speedLbl = Instance.new("TextLabel", controls)
    speedLbl.Size = UDim2.new(0, 42, 1, 0)
    speedLbl.BackgroundTransparency = 1
    speedLbl.Text = "Speed"
    speedLbl.TextColor3 = C.text2
    speedLbl.Font = Enum.Font.GothamBold
    speedLbl.TextSize = 9

    local speedOptions = {0.5, 0.75, 1.0, 1.25, 1.5, 2.0}
    local speedBtns = {}
    for i, spd in ipairs(speedOptions) do
        local btn = Instance.new("TextButton", controls)
        btn.Size = UDim2.new(0, 30, 0, 26)
        btn.BackgroundColor3 = (spd == currentSpeed) and C.accent or C.card
        btn.Text = tostring(spd)
        btn.TextColor3 = (spd == currentSpeed) and Color3.new(1, 1, 1) or C.text2
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 9
        btn.AutoButtonColor = false
        corner(btn, 6)
        pressFX(btn)
        btn.MouseButton1Click:Connect(function()
            currentSpeed = spd
            if currentAnimTrack then
                currentAnimTrack:AdjustSpeed(spd)
            end
            for _, b in ipairs(speedBtns) do
                b.BackgroundColor3 = C.card
                b.TextColor3 = C.text2
            end
            btn.BackgroundColor3 = C.accent
            btn.TextColor3 = Color3.new(1, 1, 1)
        end)
        speedBtns[i] = btn
    end

    -- Loop toggle
    local loopBtn = Instance.new("TextButton", controls)
    loopBtn.Size = UDim2.new(0, 50, 0, 26)
    loopBtn.BackgroundColor3 = loopEnabled and C.accent or C.card
    loopBtn.Text = "Loop"
    loopBtn.TextColor3 = loopEnabled and Color3.new(1, 1, 1) or C.text2
    loopBtn.Font = Enum.Font.GothamBold
    loopBtn.TextSize = 9
    loopBtn.AutoButtonColor = false
    corner(loopBtn, 6)
    pressFX(loopBtn)
    loopBtn.MouseButton1Click:Connect(function()
        loopEnabled = not loopEnabled
        if currentAnimTrack then
            currentAnimTrack.Looped = loopEnabled
        end
        loopBtn.BackgroundColor3 = loopEnabled and C.accent or C.card
        loopBtn.TextColor3 = loopEnabled and Color3.new(1, 1, 1) or C.text2
    end)

    -- Pause/Resume
    local pauseBtn = Instance.new("TextButton", controls)
    pauseBtn.Size = UDim2.new(0, 50, 0, 26)
    pauseBtn.BackgroundColor3 = C.card
    pauseBtn.Text = "⏸"
    pauseBtn.TextColor3 = C.text
    pauseBtn.Font = Enum.Font.GothamBlack
    pauseBtn.TextSize = 14
    pauseBtn.AutoButtonColor = false
    corner(pauseBtn, 6)
    pressFX(pauseBtn)
    pauseBtn.MouseButton1Click:Connect(function()
        if not currentAnimTrack then
            if _G.showDynamicNotification then _G.showDynamicNotification("Tidak ada emote yang diputar", C.text3) end
            return
        end
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

    -- Stop
    local stopBtn = Instance.new("TextButton", controls)
    stopBtn.Size = UDim2.new(0, 50, 0, 26)
    stopBtn.BackgroundColor3 = C.red
    stopBtn.Text = "⏹"
    stopBtn.TextColor3 = Color3.new(1, 1, 1)
    stopBtn.Font = Enum.Font.GothamBlack
    stopBtn.TextSize = 14
    stopBtn.AutoButtonColor = false
    corner(stopBtn, 6)
    pressFX(stopBtn)
    stopBtn.MouseButton1Click:Connect(function()
        stopAnimation()
        pauseBtn.Text = "⏸"
        if _G.showDynamicNotification then _G.showDynamicNotification("Emote dihentikan", C.text3) end
    end)

    -- ===== LOAD DATA =====
    if #Emotes == 0 then
        loadAllEmotesAsync()
    else
        updateDisplay()
    end

    -- ===== KEYBIND: close dengan Escape =====
    local function onEscape(input)
        if input.KeyCode == Enum.KeyCode.Escape and input.UserInputState == Enum.UserInputState.Begin then
            if _G.goHome then _G.goHome() end
        end
    end
    ContextActionService:BindCoreAction("EmoteAppEscape", onEscape, false, Enum.KeyCode.Escape)
    _G.AvatarCloneCleanupTasks = _G.AvatarCloneCleanupTasks or {}
    table.insert(_G.AvatarCloneCleanupTasks, function()
        ContextActionService:UnbindCoreAction("EmoteAppEscape")
    end)

    -- Simpan referensi untuk cleanup
    return true
end

-- ==================== REGISTER APP ====================
_G.openEmoteApp = _G.openEmoteApp or openEmoteApp
print("[Emote] App loaded! " .. #Emotes .. " emotes cached.")