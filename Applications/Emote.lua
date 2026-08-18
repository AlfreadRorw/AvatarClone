-- ================================================
-- EMOTE APP — Roblox Emote Catalog + Favorites (Optimized V2)
-- High Performance, UI Pooling, Instant Load, Dual-Tab System
-- ================================================

local Services    = _G.Services
local LocalPlayer = _G.LocalPlayer
local Helpers     = _G.Helpers or {}
local Storage     = _G.Storage or {}
local appContent  = _G.appContent

local HttpService          = Services.HttpService
local ContextActionService = game:GetService("ContextActionService")

local corner  = Helpers.corner
local stroke  = Helpers.stroke
local pressFX = Helpers.pressFX

-- ==================== PALETTE ====================
local C = {
    bg        = Color3.fromRGB(12, 12, 18),
    card      = Color3.fromRGB(20, 20, 28),
    card2     = Color3.fromRGB(28, 28, 38),
    border    = Color3.fromRGB(45, 45, 60),
    text      = Color3.fromRGB(240, 238, 250),
    text2     = Color3.fromRGB(160, 158, 180),
    text3     = Color3.fromRGB(100, 98, 120),
    accent    = Color3.fromRGB(115, 92, 255),
    accent2   = Color3.fromRGB(80, 200, 255),
    gold      = Color3.fromRGB(255, 195, 70),
    green     = Color3.fromRGB(80, 220, 150),
    red       = Color3.fromRGB(255, 80, 90),
}

-- ==================== DEFAULT/PRELOADED EMOTES (INSTANT LOAD) ====================
local BuiltInEmotes = {
    {id = 5915773155, name = "Arm Wave", price = 0},
    {id = 5915779725, name = "Head Banging", price = 0},
    {id = 9830731012, name = "Face Calisthenics", price = 0},
    {id = 7832585357, name = "Floss", price = 0},
    {id = 7043924239, name = "Orange Justice", price = 0},
    {id = 3696759999, name = "Stadium", price = 0},
    {id = 3360686498, name = "Tilt", price = 0},
    {id = 3360689775, name = "Salute", price = 0},
    {id = 3360692915, name = "Point", price = 0},
    {id = 3360696222, name = "Wave", price = 0},
    {id = 3360699272, name = "Cheer", price = 0},
    {id = 3360702425, name = "Laugh", price = 0},
}

-- ==================== STATE ====================
local Emotes           = {}
local Favorites        = {}
local currentAnimTrack = nil
local isPaused         = false
local loopEnabled      = false
local currentSpeed     = 1.0

local activeTab        = "all" -- "all" | "favorites"
local pageSize         = 20
local currentPage      = 1
local totalPages       = 1
local searchQuery      = ""
local currentSort      = "recentfirst"
local isFetching       = false

-- Card UI Pool (Mencegah Frame Drop)
local CardPool         = {}

-- Referensi UI Global dalam App
local resultsContainer = nil
local infoLbl          = nil
local prevBtn          = nil
local nextBtn          = nil
local tabAllBtn        = nil
local tabFavBtn        = nil

-- Inisialisasi daftar emote awal agar langsung bisa dibuka
for _, item in ipairs(BuiltInEmotes) do
    table.insert(Emotes, {
        id      = item.id,
        name    = item.name,
        price   = item.price,
        icon    = "rbxthumb://type=Asset&id=" .. item.id .. "&w=150&h=150",
        updated = "2026-01-01",
    })
end

-- ==================== DATA FAVORITE ====================
local function loadFavorites()
    if Storage and Storage.appSettings then
        Storage.appSettings.emoteFavorites = Storage.appSettings.emoteFavorites or {}
        Favorites = Storage.appSettings.emoteFavorites
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

-- ==================== FETCH CATALOG ASYNC ====================
local function fetchEmotesAsync()
    if isFetching then return end
    isFetching = true

    task.spawn(function()
        local url = "https://catalog.roblox.com/v1/search/items/details?Category=12&Subcategory=39&SortType=1&limit=30&IncludeNotForSale=true"
        
        local ok, result = pcall(function()
            local opts = {Url = url, Method = "GET"}
            if syn and syn.request then return syn.request(opts)
            elseif http_request then return http_request(opts)
            elseif request then return request(opts)
            else return {Body = game:HttpGet(url)} end
        end)

        if ok and result and (result.Body or result.body) then
            local dok, data = pcall(function() return HttpService:JSONDecode(result.Body or result.body) end)
            if dok and data and data.data then
                for _, item in ipairs(data.data) do
                    if item.id and item.name then
                        local exists = false
                        for _, e in ipairs(Emotes) do
                            if e.id == item.id then exists = true; break end
                        end
                        if not exists then
                            table.insert(Emotes, {
                                id      = item.id,
                                name    = item.name,
                                price   = item.price or 0,
                                icon    = "rbxthumb://type=Asset&id=" .. item.id .. "&w=150&h=150",
                                updated = item.updated or "",
                            })
                        end
                    end
                end
            end
        end

        isFetching = false
        if _G.updateEmoteDisplay then
            _G.updateEmoteDisplay()
        end
    end)
end

-- ==================== SORTING ====================
local function getSortedList(list)
    local sorted = {}
    for _, e in ipairs(list) do table.insert(sorted, e) end

    if currentSort == "recentfirst" then
        table.sort(sorted, function(a, b) return (a.updated or "") > (b.updated or "") end)
    elseif currentSort == "recentlast" then
        table.sort(sorted, function(a, b) return (a.updated or "") < (b.updated or "") end)
    elseif currentSort == "alphabeticfirst" then
        table.sort(sorted, function(a, b) return a.name:lower() < b.name:lower() end)
    elseif currentSort == "alphabeticlast" then
        table.sort(sorted, function(a, b) return a.name:lower() > b.name:lower() end)
    elseif currentSort == "highestprice" then
        table.sort(sorted, function(a, b) return (a.price or 0) > (b.price or 0) end)
    elseif currentSort == "lowestprice" then
        table.sort(sorted, function(a, b) return (a.price or 0) < (b.price or 0) end)
    end

    return sorted
end

-- ==================== PLAYBACK CONTROLLER ====================
local function stopAnimation()
    if currentAnimTrack then
        pcall(function() currentAnimTrack:Stop() end)
        currentAnimTrack = nil
        isPaused = false
    end
end

local function playEmote(assetId)
    stopAnimation()

    local char = LocalPlayer and LocalPlayer.Character
    if not char then return end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    if humanoid.RigType ~= Enum.HumanoidRigType.R15 then
        if _G.showDynamicNotification then _G.showDynamicNotification("Emote hanya untuk R15!", C.red) end
        return
    end

    local track = nil
    pcall(function()
        track = humanoid:PlayEmoteAndGetAnimTrackById(assetId)
    end)

    if not track then
        local description = humanoid:FindFirstChildOfClass("HumanoidDescription")
        if description then
            pcall(function()
                description:AddEmote("Emote_" .. assetId, assetId)
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
        if _G.showDynamicNotification then _G.showDynamicNotification("▶ Memutar Emote", C.accent2) end
    end
end

-- ==================== UI CARD POOLING SYSTEM (NO FRAME DROP) ====================
local function getOrCreateCard(index)
    if CardPool[index] then
        CardPool[index].Frame.Visible = true
        return CardPool[index]
    end

    local card = Instance.new("Frame", resultsContainer)
    card.Size = UDim2.new(1, 0, 0, 58)
    card.BackgroundColor3 = C.card
    corner(card, 10)
    stroke(card, C.border, 1, 0.3)

    local thumb = Instance.new("ImageLabel", card)
    thumb.Size = UDim2.new(0, 42, 0, 42)
    thumb.Position = UDim2.new(0, 8, 0.5, -21)
    thumb.BackgroundColor3 = C.card2
    thumb.ScaleType = Enum.ScaleType.Fit
    corner(thumb, 6)

    local nameLbl = Instance.new("TextLabel", card)
    nameLbl.Size = UDim2.new(1, -145, 0, 18)
    nameLbl.Position = UDim2.new(0, 58, 0, 10)
    nameLbl.BackgroundTransparency = 1
    nameLbl.TextColor3 = C.text
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 12
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

    local infoLblCard = Instance.new("TextLabel", card)
    infoLblCard.Size = UDim2.new(1, -145, 0, 14)
    infoLblCard.Position = UDim2.new(0, 58, 0, 30)
    infoLblCard.BackgroundTransparency = 1
    infoLblCard.TextColor3 = C.text2
    infoLblCard.Font = Enum.Font.Gotham
    infoLblCard.TextSize = 9
    infoLblCard.TextXAlignment = Enum.TextXAlignment.Left

    local playBtn = Instance.new("TextButton", card)
    playBtn.Size = UDim2.new(0, 44, 0, 28)
    playBtn.Position = UDim2.new(1, -52, 0.5, -14)
    playBtn.BackgroundColor3 = C.accent
    playBtn.Text = "▶"
    playBtn.TextColor3 = Color3.new(1, 1, 1)
    playBtn.Font = Enum.Font.GothamBlack
    playBtn.TextSize = 12
    playBtn.AutoButtonColor = false
    corner(playBtn, 6)
    pressFX(playBtn)

    local favBtn = Instance.new("TextButton", card)
    favBtn.Size = UDim2.new(0, 28, 0, 28)
    favBtn.Position = UDim2.new(1, -84, 0.5, -14)
    favBtn.BackgroundTransparency = 1
    favBtn.Font = Enum.Font.GothamBold
    favBtn.TextSize = 16
    favBtn.AutoButtonColor = false

    local cardData = {
        Frame = card,
        Thumb = thumb,
        Name  = nameLbl,
        Info  = infoLblCard,
        Play  = playBtn,
        Fav   = favBtn,
        ConnPlay = nil,
        ConnFav  = nil,
    }

    CardPool[index] = cardData
    return cardData
end

local function hideUnusedCards(fromIndex)
    for i = fromIndex, #CardPool do
        CardPool[i].Frame.Visible = false
    end
end

-- ==================== UPDATE DISPLAY ====================
function _G.updateEmoteDisplay()
    if not resultsContainer then return end

    -- Filter tab & pencarian
    local filtered = {}
    local q = searchQuery:lower()

    for _, e in ipairs(Emotes) do
        local matchesTab = (activeTab == "all") or (activeTab == "favorites" and table.find(Favorites, e.id) ~= nil)
        local matchesSearch = (q == "" or e.name:lower():find(q, 1, true) or tostring(e.id):find(q, 1, true))

        if matchesTab and matchesSearch then
            table.insert(filtered, e)
        end
    end

    local sorted = getSortedList(filtered)

    -- Pagination
    totalPages = math.max(1, math.ceil(#sorted / pageSize))
    currentPage = math.clamp(currentPage, 1, totalPages)

    local startIdx = (currentPage - 1) * pageSize + 1
    local endIdx   = math.min(currentPage * pageSize, #sorted)

    local renderCount = 0
    for i = startIdx, endIdx do
        renderCount = renderCount + 1
        local emote = sorted[i]
        local card = getOrCreateCard(renderCount)

        card.Frame.LayoutOrder = renderCount
        card.Thumb.Image = emote.icon
        card.Name.Text = emote.name
        
        local priceStr = (emote.price and emote.price > 0) and ("💰 " .. emote.price) or "🆓 Gratis"
        card.Info.Text = "ID: " .. emote.id .. " | " .. priceStr

        -- Bind Play Event
        if card.ConnPlay then card.ConnPlay:Disconnect() end
        card.ConnPlay = card.Play.MouseButton1Click:Connect(function()
            playEmote(emote.id)
        end)

        -- Bind Favorite Event
        local isFav = table.find(Favorites, emote.id) ~= nil
        card.Fav.Text = isFav and "★" or "☆"
        card.Fav.TextColor3 = isFav and C.gold or C.text3

        if card.ConnFav then card.ConnFav:Disconnect() end
        card.ConnFav = card.Fav.MouseButton1Click:Connect(function()
            local idx = table.find(Favorites, emote.id)
            if idx then
                table.remove(Favorites, idx)
            else
                table.insert(Favorites, emote.id)
            end
            saveFavorites()
            _G.updateEmoteDisplay()
        end)
    end

    hideUnusedCards(renderCount + 1)

    -- Update Info & Button States
    if infoLbl then
        infoLbl.Text = "Menampilkan " .. #sorted .. " emote"
    end

    if prevBtn and nextBtn then
        prevBtn.TextColor3 = (currentPage > 1) and C.text or C.text3
        nextBtn.TextColor3 = (currentPage < totalPages) and C.text or C.text3
    end

    -- Update Tab Labels
    if tabAllBtn and tabFavBtn then
        tabAllBtn.Text = "💃 Semua (" .. #Emotes .. ")"
        tabFavBtn.Text = "⭐ Favorit (" .. #Favorites .. ")"
        
        tabAllBtn.BackgroundColor3 = (activeTab == "all") and C.accent or C.card2
        tabFavBtn.BackgroundColor3 = (activeTab == "favorites") and C.accent or C.card2
    end
end

-- ==================== BUKA APP ====================
function _G.openEmoteApp()
    if not appContent then return end

    -- CRITICAL FIX: Bersihkan UI lama agar tidak menumpuk / Layar Putih
    appContent:ClearAllChildren()
    CardPool = {}

    -- ===== TABS BAR =====
    local tabRow = Instance.new("Frame", appContent)
    tabRow.Size = UDim2.new(1, 0, 0, 32)
    tabRow.BackgroundTransparency = 1
    tabRow.LayoutOrder = 0

    local tabLayout = Instance.new("UIListLayout", tabRow)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 8)

    tabAllBtn = Instance.new("TextButton", tabRow)
    tabAllBtn.Size = UDim2.new(0.5, -4, 1, 0)
    tabAllBtn.BackgroundColor3 = C.accent
    tabAllBtn.Text = "💃 Semua"
    tabAllBtn.TextColor3 = C.text
    tabAllBtn.Font = Enum.Font.GothamBold
    tabAllBtn.TextSize = 11
    corner(tabAllBtn, 8)
    pressFX(tabAllBtn)

    tabFavBtn = Instance.new("TextButton", tabRow)
    tabFavBtn.Size = UDim2.new(0.5, -4, 1, 0)
    tabFavBtn.BackgroundColor3 = C.card2
    tabFavBtn.Text = "⭐ Favorit"
    tabFavBtn.TextColor3 = C.text
    tabFavBtn.Font = Enum.Font.GothamBold
    tabFavBtn.TextSize = 11
    corner(tabFavBtn, 8)
    pressFX(tabFavBtn)

    tabAllBtn.MouseButton1Click:Connect(function()
        activeTab = "all"
        currentPage = 1
        _G.updateEmoteDisplay()
    end)

    tabFavBtn.MouseButton1Click:Connect(function()
        activeTab = "favorites"
        currentPage = 1
        _G.updateEmoteDisplay()
    end)

    -- ===== SEARCH BAR =====
    local searchFrame = Instance.new("Frame", appContent)
    searchFrame.Size = UDim2.new(1, 0, 0, 34)
    searchFrame.BackgroundColor3 = C.card2
    searchFrame.LayoutOrder = 1
    corner(searchFrame, 8)
    stroke(searchFrame, C.border, 1, 0.3)

    local searchBox = Instance.new("TextBox", searchFrame)
    searchBox.Size = UDim2.new(1, -30, 1, 0)
    searchBox.Position = UDim2.new(0, 10, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.PlaceholderText = "Cari Emote / ID..."
    searchBox.PlaceholderColor3 = C.text3
    searchBox.Text = ""
    searchBox.TextColor3 = C.text
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 11
    searchBox.ClearTextOnFocus = false

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        searchQuery = searchBox.Text
        currentPage = 1
        _G.updateEmoteDisplay()
    end)

    -- ===== RESULTS CONTAINER =====
    resultsContainer = Instance.new("ScrollingFrame", appContent)
    resultsContainer.Size = UDim2.new(1, 0, 0, 270)
    resultsContainer.BackgroundColor3 = C.bg
    resultsContainer.BorderSizePixel = 0
    resultsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    resultsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    resultsContainer.ScrollBarThickness = 2
    resultsContainer.ScrollBarImageColor3 = C.accent
    resultsContainer.LayoutOrder = 2
    corner(resultsContainer, 10)

    local resPad = Instance.new("UIPadding", resultsContainer)
    resPad.PaddingTop = UDim.new(0, 4)
    resPad.PaddingBottom = UDim.new(0, 4)

    local resLayout = Instance.new("UIListLayout", resultsContainer)
    resLayout.Padding = UDim.new(0, 5)
    resLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- ===== PAGINATION & CONTROLS =====
    local pageRow = Instance.new("Frame", appContent)
    pageRow.Size = UDim2.new(1, 0, 0, 28)
    pageRow.BackgroundTransparency = 1
    pageRow.LayoutOrder = 3

    infoLbl = Instance.new("TextLabel", pageRow)
    infoLbl.Size = UDim2.new(0.5, 0, 1, 0)
    infoLbl.BackgroundTransparency = 1
    infoLbl.Text = "Memuat..."
    infoLbl.TextColor3 = C.text3
    infoLbl.Font = Enum.Font.Gotham
    infoLbl.TextSize = 9
    infoLbl.TextXAlignment = Enum.TextXAlignment.Left

    local pageBtnFrame = Instance.new("Frame", pageRow)
    pageBtnFrame.Size = UDim2.new(0.5, 0, 1, 0)
    pageBtnFrame.Position = UDim2.new(0.5, 0, 0, 0)
    pageBtnFrame.BackgroundTransparency = 1

    local pLayout = Instance.new("UIListLayout", pageBtnFrame)
    pLayout.FillDirection = Enum.FillDirection.Horizontal
    pLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    pLayout.Padding = UDim.new(0, 6)

    prevBtn = Instance.new("TextButton", pageBtnFrame)
    prevBtn.Size = UDim2.new(0, 50, 1, 0)
    prevBtn.BackgroundColor3 = C.card2
    prevBtn.Text = "◀ Prev"
    prevBtn.TextColor3 = C.text
    prevBtn.Font = Enum.Font.GothamBold
    prevBtn.TextSize = 9
    corner(prevBtn, 6)

    nextBtn = Instance.new("TextButton", pageBtnFrame)
    nextBtn.Size = UDim2.new(0, 50, 1, 0)
    nextBtn.BackgroundColor3 = C.card2
    nextBtn.Text = "Next ▶"
    nextBtn.TextColor3 = C.text
    nextBtn.Font = Enum.Font.GothamBold
    nextBtn.TextSize = 9
    corner(nextBtn, 6)

    prevBtn.MouseButton1Click:Connect(function()
        if currentPage > 1 then
            currentPage = currentPage - 1
            _G.updateEmoteDisplay()
        end
    end)

    nextBtn.MouseButton1Click:Connect(function()
        if currentPage < totalPages then
            currentPage = currentPage + 1
            _G.updateEmoteDisplay()
        end
    end)

    -- ===== PLAYBACK CONTROLS =====
    local controls = Instance.new("Frame", appContent)
    controls.Size = UDim2.new(1, 0, 0, 36)
    controls.BackgroundColor3 = C.card2
    controls.LayoutOrder = 4
    corner(controls, 8)

    local cLayout = Instance.new("UIListLayout", controls)
    cLayout.FillDirection = Enum.FillDirection.Horizontal
    cLayout.Padding = UDim.new(0, 6)
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

    -- Tampilkan emote bawaan secara INSTAN saat pertama kali dibuka
    _G.updateEmoteDisplay()

    -- Ambil katalog lengkap di latar belakang
    fetchEmotesAsync()

    -- ESC Key handler
    ContextActionService:BindCoreAction("EmoteAppEscape", function(input)
        if input.KeyCode == Enum.KeyCode.Escape and input.UserInputState == Enum.UserInputState.Begin then
            if _G.goHome then _G.goHome() end
        end
    end, false, Enum.KeyCode.Escape)

    return true
end

_G.openEmoteApp = _G.openEmoteApp or openEmoteApp
