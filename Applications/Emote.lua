-- ================================================
-- EMOTE.LUA — Performance Optimized
-- Fix: Emotes appear as they load (no lag spike)
-- Fix: Render in small batches to prevent frame drop
-- Fix: Fetch limited to 20 pages for stability
-- ================================================

local Services    = _G.Services or {}
local LocalPlayer = _G.LocalPlayer
local Helpers     = _G.Helpers or {}
local Storage     = _G.Storage or {}
local appContent  = _G.appContent
local appTitle    = _G.appTitle

local HttpService = Services.HttpService or game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local ContextActionService = game:GetService("ContextActionService")

local corner  = Helpers.corner  or function(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 10); c.Parent = o; return c end
local stroke  = Helpers.stroke  or function(o, c, t, tr) local s = Instance.new("UIStroke"); s.Color = c or Color3.fromRGB(80,80,80); s.Thickness = t or 1; s.Transparency = tr or 0; s.Parent = o; return s end
local tween   = Helpers.tween   or function(o, props) for k, v in pairs(props) do pcall(function() o[k] = v end) end end
local pressFX = Helpers.pressFX or function() end

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

local FALLBACK_ICON = "rbxasset://textures/ui/GuiImagePlaceholder.png"

_G.EmoteCache = _G.EmoteCache or {
    emotes = {},
    favorites = {},
    loaded = false,
    loading = false,
}

local Emotes = _G.EmoteCache.emotes
local Favorites = _G.EmoteCache.favorites

local function isLoaded() return _G.EmoteCache.loaded end
local function isLoading() return _G.EmoteCache.loading end

local currentAnimTrack = nil
local currentAnimId = nil
local isPaused = false
local loopEnabled = false
local currentSpeed = 1.0
local currentTab = "all"
local searchQuery = ""
local currentSort = "recentfirst"
local renderToken = 0

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

-- FETCH: Sekarang setiap halaman langsung ditambahkan dan dirender
local function fetchAllEmotes(maxPages)
    if isLoading() or isLoaded() then return end
    _G.EmoteCache.loading = true

    maxPages = maxPages or 20  -- batasi 20 halaman (≈600 emote)

    task.spawn(function()
        local cursor = ""
        local pages = 0
        local totalAdded = 0

        while pages < maxPages do
            local page = fetchEmotePage(cursor)
            if not page or not page.data or #page.data == 0 then break end

            local newThisPage = {}
            for _, item in ipairs(page.data) do
                if item.id and item.name then
                    local exists = false
                    for _, e in ipairs(Emotes) do
                        if e.id == item.id then exists = true; break end
                    end
                    if not exists then
                        local emoteData = {
                            id    = item.id,
                            name  = item.name,
                            price = item.price or 0,
                            icon  = "rbxthumb://type=Asset&id=" .. item.id .. "&w=150&h=150",
                            updated = item.updated or "",
                        }
                        table.insert(Emotes, emoteData)
                        table.insert(newThisPage, emoteData)
                        totalAdded = totalAdded + 1
                    end
                end
            end

            -- Update UI setelah setiap halaman (jika app sudah terbuka)
            if resultsContainer and resultsContainer.Parent then
                renderEmotes()
            end

            cursor = page.nextPageCursor or ""
            pages = pages + 1
            if cursor == "" then break end
            task.wait(0.5)  -- jeda antar request
        end

        -- Tambahkan emote populer jika belum ada
        local popular = {
            {id = 5915773155, name = "Arm Wave"},
            {id = 5915779725, name = "Head Banging"},
            {id = 9830731012, name = "Face Calisthenics"},
            {id = 7832585357, name = "Floss"},
            {id = 7043924239, name = "Orange Justice"},
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
            end
        end

        _G.EmoteCache.loaded = true
        _G.EmoteCache.loading = false

        if resultsContainer and resultsContainer.Parent then
            renderEmotes()
        end

        if _G.showDynamicNotification then
            _G.showDynamicNotification("📦 " .. #Emotes .. " emotes siap!", C.green)
        end
    end)
end

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
            _G.showDynamicNotification("▶ " .. (name or "Emote"), C.accent2)
        end
    else
        if _G.showDynamicNotification then
            _G.showDynamicNotification("Gagal memutar emote", C.red)
        end
    end
end

-- ==================== RENDER CARD ====================
local function renderEmoteCard(parent, emote, order, isFavorite)
    local card = Instance.new("Frame", parent)
    card.Size = UDim2.new(0.333, -4, 1, 0)
    card.BackgroundColor3 = C.card
    card.LayoutOrder = order
    card.BackgroundTransparency = 0
    card.BorderSizePixel = 0
    corner(card, 12)
    stroke(card, C.border, 1, 0.3)

    -- Gradient card
    local cardGradient = Instance.new("UIGradient", card)
    cardGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 18, 26)),
    })
    cardGradient.Rotation = 45

    local hasIcon = type(emote.icon) == "string" and emote.icon ~= "" and emote.icon ~= "rbxassetid://0"

    local thumb = Instance.new("ImageLabel", card)
    thumb.Size = UDim2.new(1, 0, 0, 100)
    thumb.Position = UDim2.new(0, 0, 0, 0)
    thumb.BackgroundColor3 = C.card2
    thumb.BackgroundTransparency = 0
    thumb.Image = hasIcon and emote.icon or ""
    thumb.ScaleType = Enum.ScaleType.Crop
    thumb.BorderSizePixel = 0
    corner(thumb, 12)
    stroke(thumb, C.border, 1, 0.2)

    if not hasIcon then
        local placeholder = Instance.new("TextLabel", thumb)
        placeholder.Size = UDim2.new(1, 0, 1, 0)
        placeholder.BackgroundTransparency = 1
        placeholder.Text = "💃"
        placeholder.TextColor3 = C.text3
        placeholder.Font = Enum.Font.GothamBold
        placeholder.TextSize = 28
        placeholder.ZIndex = 2
    end

    local favBtn = Instance.new("TextButton", card)
    favBtn.Size = UDim2.new(0, 26, 0, 26)
    favBtn.Position = UDim2.new(1, -30, 0, 4)
    favBtn.BackgroundTransparency = 1
    favBtn.Text = isFavorite and "★" or "☆"
    favBtn.TextColor3 = isFavorite and C.gold or C.text3
    favBtn.Font = Enum.Font.GothamBold
    favBtn.TextSize = 18
    favBtn.AutoButtonColor = false
    favBtn.ZIndex = 5
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
        if currentTab == "favorites" then
            renderEmotes()
        end
    end)

    local nameLbl = Instance.new("TextLabel", card)
    nameLbl.Size = UDim2.new(1, -8, 0, 20)
    nameLbl.Position = UDim2.new(0, 4, 0, 104)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = emote.name or "Emote"
    nameLbl.TextColor3 = C.text
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 11
    nameLbl.TextXAlignment = Enum.TextXAlignment.Center
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    nameLbl.ZIndex = 5

    local priceLbl = Instance.new("TextLabel", card)
    priceLbl.Size = UDim2.new(1, -8, 0, 14)
    priceLbl.Position = UDim2.new(0, 4, 0, 124)
    priceLbl.BackgroundTransparency = 1
    priceLbl.Text = (emote.price and emote.price > 0) and ("💰 " .. tostring(emote.price)) or "Free"
    priceLbl.TextColor3 = (emote.price and emote.price > 0) and C.gold or C.green
    priceLbl.Font = Enum.Font.Gotham
    priceLbl.TextSize = 9
    priceLbl.TextXAlignment = Enum.TextXAlignment.Center
    priceLbl.ZIndex = 5

    local playBtn = Instance.new("TextButton", card)
    playBtn.Size = UDim2.new(1, -8, 0, 28)
    playBtn.Position = UDim2.new(0, 4, 0, 138)
    playBtn.BackgroundColor3 = C.accent2
    playBtn.Text = "▶ Play"
    playBtn.TextColor3 = Color3.new(1, 1, 1)
    playBtn.Font = Enum.Font.GothamBlack
    playBtn.TextSize = 12
    playBtn.AutoButtonColor = false
    corner(playBtn, 8)
    pressFX(playBtn)
    playBtn.ZIndex = 5

    local playGradient = Instance.new("UIGradient", playBtn)
    playGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 200, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 140, 255)),
    })
    playGradient.Rotation = 90

    playBtn.MouseButton1Click:Connect(function()
        playEmote(emote.id)
    end)

    return card
end

-- ==================== RENDER UTAMA (dengan batch) ====================
local resultsContainer = nil
local infoLbl = nil

local function renderEmotes()
    local token = renderToken + 1
    renderToken = token

    if not resultsContainer then return end

    -- Hapus semua row yang ada (kecuali layout & padding)
    for _, c in ipairs(resultsContainer:GetChildren()) do
        if c:IsA("Frame") or c:IsA("ImageLabel") or c:IsA("TextLabel") or c:IsA("TextButton") then
            if c.Name ~= "UIListLayout" and c.Name ~= "UIPadding" then
                c:Destroy()
            end
        end
    end

    local filtered = {}
    local q = searchQuery:lower()

    for _, e in ipairs(Emotes) do
        local include = true
        if currentTab == "favorites" then
            include = table.find(Favorites, e.id) ~= nil
        elseif currentTab == "search" then
            if q ~= "" and not e.name:lower():find(q, 1, true) then
                include = false
            end
        else
            if q ~= "" and not e.name:lower():find(q, 1, true) then
                include = false
            end
        end

        if include then
            table.insert(filtered, e)
        end
    end

    local sorted = sortEmotes(filtered, currentSort)

    if infoLbl then
        if not isLoaded() and isLoading() then
            infoLbl.Text = "Memuat... (" .. #Emotes .. " emotes)"
        else
            infoLbl.Text = #sorted .. " emote" .. (#sorted ~= 1 and "s" or "")
        end
    end

    if #sorted == 0 then
        local empty = Instance.new("TextLabel", resultsContainer)
        empty.Size = UDim2.new(1, 0, 0, 60)
        empty.BackgroundTransparency = 1
        empty.Text = currentTab == "favorites" and "Belum ada emote favorit\n★ Tambahkan dengan tap bintang!" or (isLoading() and "Memuat emote..." or "😢 Tidak ada emote ditemukan")
        empty.TextColor3 = C.text3
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 12
        empty.TextWrapped = true
        empty.LayoutOrder = 0
        return
    end

    -- Render dengan batch kecil untuk menghindari frame drop
    local BATCH_SIZE = 6
    local total = #sorted
    local currentIndex = 1

    task.spawn(function()
        while currentIndex <= total do
            if renderToken ~= token then return end

            local batchEnd = math.min(currentIndex + BATCH_SIZE - 1, total)
            for idx = currentIndex, batchEnd do
                local emote = sorted[idx]
                local isFav = table.find(Favorites, emote.id) ~= nil

                local rowIndex = math.floor((idx - 1) / 3) + 1
                local posInRow = ((idx - 1) % 3) + 1

                local row = resultsContainer:FindFirstChild("Row_" .. rowIndex)
                if not row then
                    row = Instance.new("Frame", resultsContainer)
                    row.Name = "Row_" .. rowIndex
                    row.Size = UDim2.new(1, 0, 0, 170)
                    row.BackgroundTransparency = 1
                    row.LayoutOrder = rowIndex
                    corner(row, 8)

                    local rowLayout = Instance.new("UIListLayout", row)
                    rowLayout.FillDirection = Enum.FillDirection.Horizontal
                    rowLayout.Padding = UDim.new(0, 6)
                    rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                    rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                end

                renderEmoteCard(row, emote, posInRow, isFav)
            end

            currentIndex = batchEnd + 1
            if currentIndex <= total then
                task.wait(0.03) -- jeda kecil antar batch
            end
        end

        -- Update CanvasSize setelah render selesai
        if renderToken == token then
            resultsContainer.CanvasSize = UDim2.new(0, 0, 0, math.ceil(total / 3) * 170 + 12)
        end
    end)
end
_G.renderEmotesRefresh = renderEmotes

-- ==================== BUKA APP ====================
local function buildEmoteApp()
    if not appContent then return end

    -- Pastikan appContent punya UIListLayout
    local existingLayout = appContent:FindFirstChildOfClass("UIListLayout")
    if not existingLayout then
        local appLayout = Instance.new("UIListLayout", appContent)
        appLayout.Padding = UDim.new(0, 8)
        appLayout.SortOrder = Enum.SortOrder.LayoutOrder
    else
        existingLayout.Padding = UDim.new(0, 8)
    end

    local header = Instance.new("Frame", appContent)
    header.Size = UDim2.new(1, 0, 0, 44)
    header.BackgroundColor3 = C.card
    header.BackgroundTransparency = 0
    header.BorderSizePixel = 0
    header.LayoutOrder = 0
    corner(header, 14)
    stroke(header, C.accent, 1, 0.5)

    local headerGradient = Instance.new("UIGradient", header)
    headerGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 45)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 18, 28)),
    })
    headerGradient.Rotation = 90

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
    hSub.Text = #Emotes .. " emotes available"
    hSub.TextColor3 = C.text2
    hSub.Font = Enum.Font.Gotham
    hSub.TextSize = 9
    hSub.TextXAlignment = Enum.TextXAlignment.Left

    local searchFrame = Instance.new("Frame", appContent)
    searchFrame.Size = UDim2.new(1, 0, 0, 36)
    searchFrame.BackgroundColor3 = C.card2
    searchFrame.BackgroundTransparency = 0
    searchFrame.BorderSizePixel = 0
    searchFrame.LayoutOrder = 1
    corner(searchFrame, 12)
    stroke(searchFrame, C.border, 1, 0.3)

    local searchBox = Instance.new("TextBox", searchFrame)
    searchBox.Size = UDim2.new(1, -46, 1, 0)
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

    local tabBar = Instance.new("Frame", appContent)
    tabBar.Size = UDim2.new(1, 0, 0, 36)
    tabBar.BackgroundColor3 = C.card2
    tabBar.BackgroundTransparency = 0
    tabBar.BorderSizePixel = 0
    tabBar.LayoutOrder = 2
    corner(tabBar, 12)

    local tabLayout = Instance.new("UIListLayout", tabBar)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local tabs = {
        {id = "all", label = "📋 Semua"},
        {id = "favorites", label = "⭐ Favorit"},
        {id = "search", label = "🔍 Cari"},
    }

    local tabBtns = {}
    for i, tab in ipairs(tabs) do
        local btn = Instance.new("TextButton", tabBar)
        btn.Size = UDim2.new(0.333, -4, 1, 0)
        btn.BackgroundColor3 = (currentTab == tab.id) and C.accent or C.card
        btn.BackgroundTransparency = 0
        btn.BorderSizePixel = 0
        btn.Text = tab.label
        btn.TextColor3 = (currentTab == tab.id) and Color3.new(1, 1, 1) or C.text2
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.AutoButtonColor = false
        corner(btn, 8)
        pressFX(btn)

        btn.MouseButton1Click:Connect(function()
            currentTab = tab.id
            for _, b in ipairs(tabBtns) do
                b.BackgroundColor3 = C.card
                b.TextColor3 = C.text2
            end
            btn.BackgroundColor3 = C.accent
            btn.TextColor3 = Color3.new(1, 1, 1)
            if currentTab == "search" then
                searchBox:CaptureFocus()
            end
            renderEmotes()
        end)
        tabBtns[i] = btn
    end

    local infoBar = Instance.new("Frame", appContent)
    infoBar.Size = UDim2.new(1, 0, 0, 22)
    infoBar.BackgroundTransparency = 1
    infoBar.LayoutOrder = 3

    infoLbl = Instance.new("TextLabel", infoBar)
    infoLbl.Size = UDim2.new(1, 0, 1, 0)
    infoLbl.BackgroundTransparency = 1
    infoLbl.Text = "Memuat..."
    infoLbl.TextColor3 = C.text3
    infoLbl.Font = Enum.Font.Gotham
    infoLbl.TextSize = 9
    infoLbl.TextXAlignment = Enum.TextXAlignment.Left

    resultsContainer = Instance.new("ScrollingFrame", appContent)
    resultsContainer.Size = UDim2.new(1, 0, 0, 280)
    resultsContainer.BackgroundColor3 = C.bg
    resultsContainer.BackgroundTransparency = 0
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

    local controls = Instance.new("Frame", appContent)
    controls.Size = UDim2.new(1, 0, 0, 44)
    controls.BackgroundColor3 = C.card2
    controls.BackgroundTransparency = 0
    controls.BorderSizePixel = 0
    controls.LayoutOrder = 5
    corner(controls, 12)
    stroke(controls, C.border, 1, 0.3)

    local cLayout = Instance.new("UIListLayout", controls)
    cLayout.FillDirection = Enum.FillDirection.Horizontal
    cLayout.Padding = UDim.new(0, 4)
    cLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    cLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local speedLbl = Instance.new("TextLabel", controls)
    speedLbl.Size = UDim2.new(0, 36, 1, 0)
    speedLbl.BackgroundTransparency = 1
    speedLbl.Text = "Speed"
    speedLbl.TextColor3 = C.text2
    speedLbl.Font = Enum.Font.GothamBold
    speedLbl.TextSize = 8

    local speedOptions = {0.5, 0.75, 1.0, 1.25, 1.5, 2.0}
    for _, spd in ipairs(speedOptions) do
        local btn = Instance.new("TextButton", controls)
        btn.Size = UDim2.new(0, 28, 0, 24)
        btn.BackgroundColor3 = (spd == currentSpeed) and C.accent or C.card
        btn.BackgroundTransparency = 0
        btn.BorderSizePixel = 0
        btn.Text = tostring(spd)
        btn.TextColor3 = (spd == currentSpeed) and Color3.new(1, 1, 1) or C.text2
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 8
        btn.AutoButtonColor = false
        corner(btn, 6)
        pressFX(btn)
        btn.MouseButton1Click:Connect(function()
            currentSpeed = spd
            if currentAnimTrack then currentAnimTrack:AdjustSpeed(spd) end
            for _, b in ipairs(controls:GetChildren()) do
                if b:IsA("TextButton") and b.Text ~= "" and tonumber(b.Text) then
                    b.BackgroundColor3 = C.card
                    b.TextColor3 = C.text2
                end
            end
            btn.BackgroundColor3 = C.accent
            btn.TextColor3 = Color3.new(1, 1, 1)
        end)
    end

    local loopBtn = Instance.new("TextButton", controls)
    loopBtn.Size = UDim2.new(0, 42, 0, 24)
    loopBtn.BackgroundColor3 = loopEnabled and C.accent or C.card
    loopBtn.BackgroundTransparency = 0
    loopBtn.BorderSizePixel = 0
    loopBtn.Text = "Loop"
    loopBtn.TextColor3 = loopEnabled and Color3.new(1, 1, 1) or C.text2
    loopBtn.Font = Enum.Font.GothamBold
    loopBtn.TextSize = 9
    loopBtn.AutoButtonColor = false
    corner(loopBtn, 6)
    pressFX(loopBtn)
    loopBtn.MouseButton1Click:Connect(function()
        loopEnabled = not loopEnabled
        if currentAnimTrack then currentAnimTrack.Looped = loopEnabled end
        loopBtn.BackgroundColor3 = loopEnabled and C.accent or C.card
        loopBtn.TextColor3 = loopEnabled and Color3.new(1, 1, 1) or C.text2
    end)

    local pauseBtn = Instance.new("TextButton", controls)
    pauseBtn.Size = UDim2.new(0, 36, 0, 24)
    pauseBtn.BackgroundColor3 = C.card
    pauseBtn.BackgroundTransparency = 0
    pauseBtn.BorderSizePixel = 0
    pauseBtn.Text = "⏸"
    pauseBtn.TextColor3 = C.text
    pauseBtn.Font = Enum.Font.GothamBlack
    pauseBtn.TextSize = 13
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

    local stopBtn = Instance.new("TextButton", controls)
    stopBtn.Size = UDim2.new(0, 36, 0, 24)
    stopBtn.BackgroundColor3 = C.red
    stopBtn.BackgroundTransparency = 0
    stopBtn.BorderSizePixel = 0
    stopBtn.Text = "⏹"
    stopBtn.TextColor3 = Color3.new(1, 1, 1)
    stopBtn.Font = Enum.Font.GothamBlack
    stopBtn.TextSize = 13
    stopBtn.AutoButtonColor = false
    corner(stopBtn, 6)
    pressFX(stopBtn)
    stopBtn.MouseButton1Click:Connect(function()
        stopAnimation()
        pauseBtn.Text = "⏸"
        if _G.showDynamicNotification then _G.showDynamicNotification("Emote dihentikan", C.text3) end
    end)

    -- Render awal
    renderEmotes()
    if hSub then hSub.Text = #Emotes .. " emotes available" end
    if infoLbl then infoLbl.Text = #Emotes .. " emotes" end

    -- Fetch jika belum dimuat
    if not isLoaded() and not isLoading() then
        fetchAllEmotes(20)
    end

    return true
end

function _G.openEmoteApp()
    local ok, err = pcall(buildEmoteApp)
    if not ok then
        warn("[Emote] Error building UI: " .. tostring(err))
        if appContent then
            local errLbl = Instance.new("TextLabel", appContent)
            errLbl.Size = UDim2.new(1, 0, 0, 80)
            errLbl.BackgroundTransparency = 1
            errLbl.Text = "⚠️ Emote app gagal dimuat:\n" .. tostring(err)
            errLbl.TextColor3 = C.red
            errLbl.Font = Enum.Font.Gotham
            errLbl.TextSize = 11
            errLbl.TextWrapped = true
            errLbl.LayoutOrder = 0
        end
        if _G.showDynamicNotification then
            _G.showDynamicNotification("Emote gagal dimuat, cek console", C.red)
        end
    end
end

print("[Emote] App loaded! " .. #Emotes .. " emotes cached.")