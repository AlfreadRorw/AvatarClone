-- ================================================
-- Model3D.lua — 3D Model & Image Viewer with Gizmo + Firebase Sync
-- ================================================
-- Fitur:
--   1. Load 3D Model dari Asset ID (InsertService:LoadAsset)
--   2. Load Gambar dari URL (Catbox, dll) ke Part dengan SurfaceGui
--   3. Gizmo Posisi (Handles Movement), Rotasi (ArcHandles), Ukuran (Handles Resize)
--   4. Save/Load Config lokal (nama bebas)
--   5. Firebase: Dev config → terlihat SEMUA player
--   6. Firebase: Player config → hanya pemilik (dev bisa load punya player lain)
--   7. Semua player bisa load Model3D yang dipasang dev
-- ================================================

local Services = _G.Services or {
    Players = game:GetService("Players"),
    Workspace = game:GetService("Workspace"),
    TweenService = game:GetService("TweenService"),
    UserInputService = game:GetService("UserInputService"),
    HttpService = game:GetService("HttpService"),
    RunService = game:GetService("RunService"),
    CoreGui = game:GetService("CoreGui"),
    InsertService = game:GetService("InsertService"),
    TeleportService = game:GetService("TeleportService"),
}
local Players = Services.Players
local Workspace = Services.Workspace
local TweenService = Services.TweenService
local UserInputService = Services.UserInputService
local HttpService = Services.HttpService
local RunService = Services.RunService
local CoreGui = Services.CoreGui
local InsertService = Services.InsertService
local LocalPlayer = Players.LocalPlayer

local T = _G.T or {}
local Helpers = _G.Helpers or {}
local Storage = _G.Storage or {}
local Firebase = _G.Firebase or {}
local Config = _G.Config or {}
local appContent = _G.appContent

-- ==================== LOCAL HELPERS (fallback) ====================
local corner = Helpers.corner or function(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
end

local stroke = Helpers.stroke or function(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(60, 60, 80)
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.Parent = parent
end

local pressFX = Helpers.pressFX or function(btn)
    local orig = btn.Size
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.08), {Size = UDim2.new(orig.X.Scale, orig.X.Offset - 2, orig.Y.Scale, orig.Y.Offset - 2)}):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.08), {Size = UDim2.new(orig.X.Scale, orig.X.Offset, orig.Y.Scale, orig.Y.Offset)}):Play()
    end)
end

local function splitPath(path, sep)
    sep = sep or "."
    local parts = {}
    for part in string.gmatch(path or "", "([^" .. sep .. "]+)") do
        table.insert(parts, part)
    end
    return parts
end

local function notify(text, color)
    if _G.showDynamicNotification then
        _G.showDynamicNotification(text, color)
    end
end

local DEVELOPER_USER_ID = Config.DEVELOPER_USER_ID or 10164114772
local isDeveloper = (LocalPlayer.UserId == DEVELOPER_USER_ID)

-- ==================== PALETTE ====================
local C = {
    bg          = Color3.fromRGB(10, 10, 16),
    card        = Color3.fromRGB(18, 18, 26),
    card2       = Color3.fromRGB(24, 24, 34),
    card3       = Color3.fromRGB(32, 32, 44),
    border      = Color3.fromRGB(48, 48, 62),
    accent      = Color3.fromRGB(100, 180, 255),
    accent2     = Color3.fromRGB(150, 120, 255),
    green       = Color3.fromRGB(80, 220, 140),
    red         = Color3.fromRGB(255, 90, 100),
    gold        = Color3.fromRGB(255, 195, 80),
    text        = Color3.fromRGB(240, 240, 250),
    text2       = Color3.fromRGB(160, 160, 178),
    text3       = Color3.fromRGB(95, 95, 112),
    dev         = Color3.fromRGB(255, 160, 60),
}

-- ==================== STATE ====================
_G.Model3DState = _G.Model3DState or {
    selectedObject = nil,          -- Model atau Part yang dipilih
    objects = {},                  -- {[instance] = {type="model"|"image", name, assetId, url, cframe, size, configRef}}
    gizmoMode = "position",        -- "position" | "rotation" | "resize"
    currentTab = "Models",         -- "Models" | "Images" | "Config"
    selectedConfigName = nil,
    objectCounter = 0,
    syncEnabled = false,
}

local State = _G.Model3DState
local Gizmos = _G.Model3DGizmos or {}
_G.Model3DGizmos = Gizmos

-- ==================== GIZMO HELPER ====================
local function setupGizmo(handles, mode)
    if not handles then return end
    handles.Adornee = nil
    handles.Enabled = false

    if not State.selectedObject then return end

    local primary = State.selectedObject:FindFirstChild("PrimaryPart") or State.selectedObject:FindFirstChildOfClass("BasePart")
    if not primary then return end

    handles.Adornee = primary
    handles.Enabled = true

    if mode == "position" then
        handles.Style = Enum.HandlesStyle.Movement
        handles.Color3 = C.accent
    elseif mode == "rotation" then
        handles.Style = Enum.HandlesStyle.Rotation
        handles.Color3 = C.accent2
    elseif mode == "resize" then
        handles.Style = Enum.HandlesStyle.Resize
        handles.Color3 = C.gold
    end
end

-- ==================== CREATE GIZMO ====================
local function createGizmo()
    if Gizmos.Handles then
        pcall(function() Gizmos.Handles:Destroy() end)
    end

    local handles = Instance.new("Handles")
    handles.Name = "Model3DGizmo"
    handles.Parent = CoreGui
    handles.Enabled = false
    handles.Color3 = C.accent
    handles.Style = Enum.HandlesStyle.Movement
    handles.Adornee = nil

    -- Drag handler
    handles.MouseButton1Down:Connect(function()
        if not State.selectedObject then return end
        local primary = State.selectedObject:FindFirstChild("PrimaryPart") or State.selectedObject:FindFirstChildOfClass("BasePart")
        if primary then
            primary:SetAttribute("_GizmoDragStart", primary.CFrame)
        end
    end)

    handles.MouseDrag:Connect(function(face, distance)
        if not State.selectedObject then return end
        local primary = State.selectedObject:FindFirstChild("PrimaryPart") or State.selectedObject:FindFirstChildOfClass("BasePart")
        if not primary then return end

        local start = primary:GetAttribute("_GizmoDragStart")
        if not start then return end

        local delta = Vector3.FromNormalId(face) * distance
        local newCF = start * CFrame.new(delta)

        if State.gizmoMode == "position" then
            State.selectedObject:PivotTo(CFrame.new(newCF.Position) * (primary.CFrame - primary.CFrame.Position))
        elseif State.gizmoMode == "rotation" then
            -- Rotation handles already update CFrame directly
        elseif State.gizmoMode == "resize" then
            -- Resize handles update size directly
        end

        -- Update stored CFrame
        local objData = State.objects[State.selectedObject]
        if objData then
            objData.cframe = primary.CFrame
        end
    end)

    handles.MouseButton1Up:Connect(function()
        if State.selectedObject then
            local primary = State.selectedObject:FindFirstChild("PrimaryPart") or State.selectedObject:FindFirstChildOfClass("BasePart")
            if primary then
                primary:SetAttribute("_GizmoDragStart", nil)
            end
        end
    end)

    Gizmos.Handles = handles
    return handles
end

-- ==================== LOAD 3D MODEL ====================
local function loadModelFromAssetId(assetId, name)
    if not assetId or assetId == "" then
        notify("Masukkan Asset ID terlebih dahulu!", C.red)
        return nil
    end

    local idNum = tonumber(assetId)
    if not idNum or idNum <= 0 then
        notify("Asset ID tidak valid!", C.red)
        return nil
    end

    local success, model = pcall(function()
        return InsertService:LoadAsset(idNum)
    end)

    if not success or not model then
        notify("Gagal load model! ID tidak valid atau tidak memiliki akses.", C.red)
        return nil
    end

    -- Bersihkan script
    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
            obj:Destroy()
        end
    end

    -- Cari PrimaryPart
    local primary = model:FindFirstChild("PrimaryPart") or model:FindFirstChildOfClass("BasePart")
    if primary then
        model.PrimaryPart = primary
    end

    -- Posisikan di depan player
    local char = LocalPlayer.Character
    local spawnCF = CFrame.new(0, 3, -10)
    if char and char:FindFirstChild("HumanoidRootPart") then
        local root = char.HumanoidRootPart
        spawnCF = root.CFrame * CFrame.new(0, 0, -8)
        spawnCF = CFrame.new(spawnCF.Position + Vector3.new(0, 2, 0))
    end
    model:PivotTo(spawnCF)

    model.Name = name or ("Model3D_" .. tostring(State.objectCounter + 1))
    model.Parent = Workspace

    -- Anchor semua part
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
            part.CanCollide = false
        end
    end

    State.objectCounter = State.objectCounter + 1
    State.objects[model] = {
        type = "model",
        name = model.Name,
        assetId = tostring(assetId),
        cframe = spawnCF,
        size = nil, -- will be computed if needed
    }

    State.selectedObject = model
    setupGizmo(Gizmos.Handles, State.gizmoMode)

    notify("✅ Model " .. model.Name .. " berhasil dimuat!", C.green)
    return model
end

-- ==================== LOAD IMAGE ====================
local function loadImageFromUrl(url, name)
    if not url or url == "" then
        notify("Masukkan URL gambar terlebih dahulu!", C.red)
        return nil
    end

    -- Buat Part sebagai media gambar
    local part = Instance.new("Part")
    part.Name = name or ("Image_" .. tostring(State.objectCounter + 1))
    part.Size = Vector3.new(8, 8, 1)
    part.Material = Enum.Material.SmoothPlastic
    part.Anchored = true
    part.CanCollide = false
    part.Color = Color3.new(1, 1, 1)
    part.Reflectance = 0

    -- Posisi di depan player
    local char = LocalPlayer.Character
    local spawnCF = CFrame.new(0, 3, -10)
    if char and char:FindFirstChild("HumanoidRootPart") then
        local root = char.HumanoidRootPart
        spawnCF = root.CFrame * CFrame.new(0, 1.5, -8)
        spawnCF = CFrame.new(spawnCF.Position + Vector3.new(0, 2, 0))
    end
    part.CFrame = spawnCF
    part.Parent = Workspace

    -- SurfaceGui untuk gambar
    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Front
    gui.Parent = part

    local imageLabel = Instance.new("ImageLabel")
    imageLabel.Size = UDim2.new(1, 0, 1, 0)
    imageLabel.BackgroundTransparency = 1
    imageLabel.Image = url
    imageLabel.ScaleType = Enum.ScaleType.Fit
    imageLabel.Parent = gui

    -- Coba load thumbnail sebagai fallback
    task.spawn(function()
        local ok, result = pcall(function()
            return HttpService:GetAsync(url)
        end)
        if not ok then
            -- URL mungkin gambar langsung, tetap pakai ImageLabel
        end
    end)

    State.objectCounter = State.objectCounter + 1
    State.objects[part] = {
        type = "image",
        name = part.Name,
        url = url,
        cframe = spawnCF,
        size = part.Size,
    }

    State.selectedObject = part
    setupGizmo(Gizmos.Handles, State.gizmoMode)

    notify("✅ Gambar " .. part.Name .. " berhasil dimuat!", C.green)
    return part
end

-- ==================== DELETE OBJECT ====================
local function deleteSelectedObject()
    if not State.selectedObject then
        notify("Tidak ada objek yang dipilih!", C.text3)
        return
    end

    local obj = State.selectedObject
    State.objects[obj] = nil
    State.selectedObject = nil
    setupGizmo(Gizmos.Handles, State.gizmoMode)

    pcall(function() obj:Destroy() end)
    notify("Objek dihapus", C.text2)
end

-- ==================== CLEAR ALL OBJECTS ====================
local function clearAllObjects()
    local count = 0
    for obj, _ in pairs(State.objects) do
        pcall(function() obj:Destroy() end)
        count = count + 1
    end
    table.clear(State.objects)
    State.selectedObject = nil
    setupGizmo(Gizmos.Handles, State.gizmoMode)
    notify("Semua objek dihapus (" .. count .. ")", C.text2)
end

-- ==================== SAVE CONFIG (LOKAL + FIREBASE) ====================
local function saveConfig(name, isPublic)
    if not name or name == "" then
        notify("Masukkan nama config!", C.red)
        return false
    end

    local objectsData = {}
    for obj, data in pairs(State.objects) do
        local primary = obj:FindFirstChild("PrimaryPart") or obj:FindFirstChildOfClass("BasePart")
        local cframe = primary and primary.CFrame or data.cframe or CFrame.new(0, 3, 0)
        local size = nil
        if data.type == "image" and obj:IsA("BasePart") then
            size = obj.Size
        elseif data.type == "model" then
            -- ambil ukuran bounding box
            local min, max = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9)
            for _, part in ipairs(obj:GetDescendants()) do
                if part:IsA("BasePart") then
                    local pos = part.Position
                    local s = part.Size / 2
                    min = Vector3.new(math.min(min.X, pos.X - s.X), math.min(min.Y, pos.Y - s.Y), math.min(min.Z, pos.Z - s.Z))
                    max = Vector3.new(math.max(max.X, pos.X + s.X), math.max(max.Y, pos.Y + s.Y), math.max(max.Z, pos.Z + s.Z))
                end
            end
            if min.X < 1e8 then
                size = max - min
            end
        end

        table.insert(objectsData, {
            type = data.type,
            name = data.name,
            assetId = data.assetId,
            url = data.url,
            cframe = cframe,
            size = size or Vector3.new(4, 4, 1),
        })
    end

    if #objectsData == 0 then
        notify("Tidak ada objek untuk disimpan!", C.red)
        return false
    end

    local configData = {
        name = name,
        objects = objectsData,
        savedAt = os.time(),
        savedBy = LocalPlayer.UserId,
        savedByName = LocalPlayer.DisplayName,
    }

    -- Simpan ke Storage lokal
    if not Storage.appSettings then Storage.appSettings = {} end
    Storage.appSettings.model3dConfigs = Storage.appSettings.model3dConfigs or {}
    Storage.appSettings.model3dConfigs[name] = configData
    pcall(function()
        if Storage.persistSettings then Storage.persistSettings() end
    end)

    -- Firebase
    local fbSuccess = false
    if isDeveloper then
        -- Dev config → semua orang bisa lihat
        if Firebase and Firebase.SaveDevModel3DConfig then
            local ok, err = pcall(function()
                Firebase.SaveDevModel3DConfig(name, configData, function(success)
                    fbSuccess = success
                end)
            end)
            if ok then
                notify("✅ Config '" .. name .. "' disimpan sebagai PUBLIC (dev)!", C.dev)
            else
                notify("⚠ Gagal sync ke Firebase dev", C.red)
            end
        end
    else
        -- Player config → privat (hanya dirinya)
        if Firebase and Firebase.SavePlayerModel3DConfig then
            local ok, err = pcall(function()
                Firebase.SavePlayerModel3DConfig(name, configData, function(success)
                    fbSuccess = success
                end)
            end)
            if ok then
                notify("✅ Config '" .. name .. "' disimpan PRIVAT!", C.green)
            else
                notify("⚠ Gagal sync ke Firebase player", C.red)
            end
        end
    end

    return true
end

-- ==================== LOAD CONFIG ====================
local function loadConfig(name, sourceData)
    local data = sourceData

    if not data then
        -- Cek lokal dulu
        if Storage.appSettings and Storage.appSettings.model3dConfigs then
            data = Storage.appSettings.model3dConfigs[name]
        end
        if not data then
            notify("Config '" .. name .. "' tidak ditemukan.", C.red)
            return false
        end
    end

    -- Hapus semua objek saat ini
    clearAllObjects()

    local successCount = 0
    for _, objData in ipairs(data.objects) do
        if objData.type == "model" and objData.assetId then
            local model = loadModelFromAssetId(objData.assetId, objData.name)
            if model then
                if objData.cframe then
                    model:PivotTo(objData.cframe)
                end
                -- Update stored data
                local stored = State.objects[model]
                if stored then
                    stored.cframe = objData.cframe or model.PrimaryPart and model.PrimaryPart.CFrame or CFrame.new(0, 3, 0)
                    stored.name = objData.name or model.Name
                end
                successCount = successCount + 1
            end
        elseif objData.type == "image" and objData.url then
            local part = loadImageFromUrl(objData.url, objData.name)
            if part then
                if objData.cframe then
                    part.CFrame = objData.cframe
                end
                if objData.size then
                    part.Size = objData.size
                end
                local stored = State.objects[part]
                if stored then
                    stored.cframe = objData.cframe or part.CFrame
                    stored.size = objData.size or part.Size
                    stored.name = objData.name or part.Name
                end
                successCount = successCount + 1
            end
        end
    end

    State.selectedObject = nil
    setupGizmo(Gizmos.Handles, State.gizmoMode)

    if successCount > 0 then
        notify("✅ Config '" .. name .. "' dimuat (" .. successCount .. " objek)", C.green)
        return true
    else
        notify("⚠ Tidak ada objek yang berhasil dimuat dari config.", C.text3)
        return false
    end
end

-- ==================== GET FIREBASE CONFIGS ====================
local function fetchConfigsFromFirebase(callback)
    local results = {dev = {}, players = {}}

    if not Firebase then
        if callback then callback(results) end
        return results
    end

    local function fetchDev()
        if not Firebase.GetDevModel3DConfigs then
            if callback then callback(results) end
            return
        end
        pcall(function()
            Firebase.GetDevModel3DConfigs(function(success, data)
                if success and type(data) == "table" then
                    for name, cfg in pairs(data) do
                        if type(cfg) == "table" and cfg.objects then
                            table.insert(results.dev, {name = name, data = cfg, source = "dev"})
                        end
                    end
                end
                -- Lanjut ke player configs
                fetchPlayers()
            end)
        end)
    end

    local function fetchPlayers()
        if not Firebase.GetPlayerModel3DConfigs then
            if callback then callback(results) end
            return
        end
        -- Ambil config player sendiri
        pcall(function()
            Firebase.GetPlayerModel3DConfigs(LocalPlayer.UserId, function(success, data)
                if success and type(data) == "table" then
                    for name, cfg in pairs(data) do
                        if type(cfg) == "table" and cfg.objects then
                            table.insert(results.players, {name = name, data = cfg, source = "self"})
                        end
                    end
                end
                if callback then callback(results) end
            end)
        end)
    end

    fetchDev()
    return results
end

-- ==================== LOAD CONFIG BY USER ID (DEV ONLY) ====================
local function loadPlayerConfigByUserId(targetUserId, configName)
    if not isDeveloper then
        notify("Hanya developer yang bisa load config player lain!", C.red)
        return false
    end

    if not Firebase or not Firebase.GetPlayerModel3DConfigs then
        notify("Firebase tidak tersedia!", C.red)
        return false
    end

    pcall(function()
        Firebase.GetPlayerModel3DConfigs(targetUserId, function(success, data)
            if success and type(data) == "table" then
                local found = data[configName]
                if found and type(found) == "table" and found.objects then
                    loadConfig(configName, found)
                else
                    notify("Config '" .. configName .. "' tidak ditemukan untuk User ID " .. tostring(targetUserId), C.red)
                end
            else
                notify("Gagal mengambil config player", C.red)
            end
        end)
    end)
    return true
end

-- ==================== RENDER UI ====================
local rebuildUI = nil

local function renderHeader(parent)
    local header = Instance.new("Frame", parent)
    header.Size = UDim2.new(1, 0, 0, 48)
    header.BackgroundColor3 = C.card
    header.LayoutOrder = 0
    corner(header, 12)
    stroke(header, C.accent, 1, 0.4)

    local title = Instance.new("TextLabel", header)
    title.Size = UDim2.new(1, -80, 0, 22)
    title.Position = UDim2.new(0, 12, 0, 4)
    title.BackgroundTransparency = 1
    title.Text = "🧊 Model3D Studio"
    title.TextColor3 = isDeveloper and C.dev or C.text
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left

    local sub = Instance.new("TextLabel", header)
    sub.Size = UDim2.new(1, -80, 0, 14)
    sub.Position = UDim2.new(0, 12, 0, 26)
    sub.BackgroundTransparency = 1
    sub.Text = isDeveloper and "👑 Developer Mode — Config bersifat PUBLIC" or "Mode Player — Config PRIVAT"
    sub.TextColor3 = isDeveloper and C.dev or C.text3
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 9
    sub.TextXAlignment = Enum.TextXAlignment.Left

    local countLbl = Instance.new("TextLabel", header)
    countLbl.Size = UDim2.new(0, 80, 0, 18)
    countLbl.Position = UDim2.new(1, -88, 0, 14)
    countLbl.BackgroundTransparency = 1
    countLbl.Text = "Objek: " .. (#State.objects)
    countLbl.TextColor3 = C.text2
    countLbl.Font = Enum.Font.GothamBold
    countLbl.TextSize = 11
    countLbl.TextXAlignment = Enum.TextXAlignment.Right

    return header
end

local function renderTabBar(parent)
    local tabBar = Instance.new("Frame", parent)
    tabBar.Size = UDim2.new(1, 0, 0, 36)
    tabBar.BackgroundColor3 = C.card2
    tabBar.LayoutOrder = 1
    corner(tabBar, 10)

    local tabs = {"Models", "Images", "Config"}
    local tabBtns = {}

    for i, tabName in ipairs(tabs) do
        local btn = Instance.new("TextButton", tabBar)
        btn.Size = UDim2.new(1 / #tabs, -4, 1, -6)
        btn.Position = UDim2.new((i - 1) / #tabs + 0.02, 0, 0.03, 0)
        btn.BackgroundColor3 = (State.currentTab == tabName) and C.accent or C.card3
        btn.Text = tabName
        btn.TextColor3 = (State.currentTab == tabName) and Color3.new(1, 1, 1) or C.text2
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.AutoButtonColor = false
        corner(btn, 6)
        pressFX(btn)

        btn.MouseButton1Click:Connect(function()
            State.currentTab = tabName
            for _, b in ipairs(tabBtns) do
                b.BackgroundColor3 = C.card3
                b.TextColor3 = C.text2
            end
            btn.BackgroundColor3 = C.accent
            btn.TextColor3 = Color3.new(1, 1, 1)
            rebuildUI()
        end)

        table.insert(tabBtns, btn)
    end

    return tabBar
end

local function renderModelsTab(parent)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, 0, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.BackgroundTransparency = 1
    container.LayoutOrder = 2

    -- Input Asset ID
    local inputFrame = Instance.new("Frame", container)
    inputFrame.Size = UDim2.new(1, 0, 0, 44)
    inputFrame.BackgroundColor3 = C.card2
    corner(inputFrame, 10)
    stroke(inputFrame, C.border, 1, 0.4)

    local inputBox = Instance.new("TextBox", inputFrame)
    inputBox.Size = UDim2.new(1, -90, 0, 32)
    inputBox.Position = UDim2.new(0, 8, 0.5, -16)
    inputBox.BackgroundColor3 = C.card3
    inputBox.PlaceholderText = "Asset ID (contoh: 1234567890)"
    inputBox.Text = ""
    inputBox.TextColor3 = C.text
    inputBox.Font = Enum.Font.Gotham
    inputBox.TextSize = 11
    inputBox.ClearTextOnFocus = false
    corner(inputBox, 6)

    local loadBtn = Instance.new("TextButton", inputFrame)
    loadBtn.Size = UDim2.new(0, 72, 0, 32)
    loadBtn.Position = UDim2.new(1, -80, 0.5, -16)
    loadBtn.BackgroundColor3 = C.accent
    loadBtn.Text = "Load"
    loadBtn.TextColor3 = Color3.new(1, 1, 1)
    loadBtn.Font = Enum.Font.GothamBold
    loadBtn.TextSize = 11
    loadBtn.AutoButtonColor = false
    corner(loadBtn, 6)
    pressFX(loadBtn)

    loadBtn.MouseButton1Click:Connect(function()
        local id = inputBox.Text:gsub("%s+", "")
        if id ~= "" then
            loadModelFromAssetId(id)
            inputBox.Text = ""
            rebuildUI()
        end
    end)

    inputBox.FocusLost:Connect(function(enter)
        if enter then loadBtn.MouseButton1Click:Fire() end
    end)

    -- List objek model
    local listLbl = Instance.new("TextLabel", container)
    listLbl.Size = UDim2.new(1, 0, 0, 20)
    listLbl.Position = UDim2.new(0, 0, 0, 52)
    listLbl.BackgroundTransparency = 1
    listLbl.Text = "Model Aktif:"
    listLbl.TextColor3 = C.text2
    listLbl.Font = Enum.Font.GothamBold
    listLbl.TextSize = 10
    listLbl.TextXAlignment = Enum.TextXAlignment.Left

    local listScroll = Instance.new("ScrollingFrame", container)
    listScroll.Size = UDim2.new(1, 0, 0, 160)
    listScroll.Position = UDim2.new(0, 0, 0, 74)
    listScroll.BackgroundColor3 = C.card3
    listScroll.BorderSizePixel = 0
    listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    listScroll.ScrollBarThickness = 2

    local listLayout = Instance.new("UIListLayout", listScroll)
    listLayout.Padding = UDim.new(0, 4)

    local listPad = Instance.new("UIPadding", listScroll)
    listPad.PaddingTop = UDim.new(0, 4)
    listPad.PaddingBottom = UDim.new(0, 4)

    -- Render model list
    local order = 0
    for obj, data in pairs(State.objects) do
        if data.type == "model" then
            order = order + 1
            local isSel = (State.selectedObject == obj)

            local row = Instance.new("Frame", listScroll)
            row.Size = UDim2.new(1, 0, 0, 28)
            row.BackgroundColor3 = isSel and C.accent or C.card2
            row.LayoutOrder = order
            corner(row, 6)

            local nameLbl = Instance.new("TextLabel", row)
            nameLbl.Size = UDim2.new(1, -50, 0, 20)
            nameLbl.Position = UDim2.new(0, 8, 0, 4)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text = data.name or "Model"
            nameLbl.TextColor3 = isSel and Color3.new(1, 1, 1) or C.text
            nameLbl.Font = Enum.Font.Gotham
            nameLbl.TextSize = 10
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

            local selBtn = Instance.new("TextButton", row)
            selBtn.Size = UDim2.new(0, 40, 0, 20)
            selBtn.Position = UDim2.new(1, -44, 0.5, -10)
            selBtn.BackgroundColor3 = isSel and Color3.new(1, 1, 1) or C.card3
            selBtn.Text = isSel and "✓" or "Pilih"
            selBtn.TextColor3 = isSel and C.accent or C.text2
            selBtn.Font = Enum.Font.GothamBold
            selBtn.TextSize = 8
            selBtn.AutoButtonColor = false
            corner(selBtn, 4)
            pressFX(selBtn)

            selBtn.MouseButton1Click:Connect(function()
                State.selectedObject = obj
                setupGizmo(Gizmos.Handles, State.gizmoMode)
                rebuildUI()
            end)

            local delBtn = Instance.new("TextButton", row)
            delBtn.Size = UDim2.new(0, 20, 0, 20)
            delBtn.Position = UDim2.new(1, -22, 0.5, -10)
            delBtn.BackgroundColor3 = C.red
            delBtn.Text = "✕"
            delBtn.TextColor3 = Color3.new(1, 1, 1)
            delBtn.Font = Enum.Font.GothamBold
            delBtn.TextSize = 10
            delBtn.AutoButtonColor = false
            corner(delBtn, 4)
            pressFX(delBtn)

            delBtn.MouseButton1Click:Connect(function()
                State.objects[obj] = nil
                if State.selectedObject == obj then
                    State.selectedObject = nil
                    setupGizmo(Gizmos.Handles, State.gizmoMode)
                end
                pcall(function() obj:Destroy() end)
                rebuildUI()
            end)
        end
    end

    if order == 0 then
        local empty = Instance.new("TextLabel", listScroll)
        empty.Size = UDim2.new(1, 0, 0, 30)
        empty.BackgroundTransparency = 1
        empty.Text = "Belum ada model. Load Asset ID di atas!"
        empty.TextColor3 = C.text3
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 9
        empty.LayoutOrder = 1
    end

    return container
end

local function renderImagesTab(parent)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, 0, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.BackgroundTransparency = 1
    container.LayoutOrder = 2

    -- Input URL
    local inputFrame = Instance.new("Frame", container)
    inputFrame.Size = UDim2.new(1, 0, 0, 44)
    inputFrame.BackgroundColor3 = C.card2
    corner(inputFrame, 10)
    stroke(inputFrame, C.border, 1, 0.4)

    local inputBox = Instance.new("TextBox", inputFrame)
    inputBox.Size = UDim2.new(1, -90, 0, 32)
    inputBox.Position = UDim2.new(0, 8, 0.5, -16)
    inputBox.BackgroundColor3 = C.card3
    inputBox.PlaceholderText = "URL Gambar (Catbox, Imgur, dll)"
    inputBox.Text = ""
    inputBox.TextColor3 = C.text
    inputBox.Font = Enum.Font.Gotham
    inputBox.TextSize = 10
    inputBox.ClearTextOnFocus = false
    corner(inputBox, 6)

    local loadBtn = Instance.new("TextButton", inputFrame)
    loadBtn.Size = UDim2.new(0, 72, 0, 32)
    loadBtn.Position = UDim2.new(1, -80, 0.5, -16)
    loadBtn.BackgroundColor3 = C.gold
    loadBtn.Text = "Load"
    loadBtn.TextColor3 = Color3.fromRGB(10, 10, 10)
    loadBtn.Font = Enum.Font.GothamBold
    loadBtn.TextSize = 11
    loadBtn.AutoButtonColor = false
    corner(loadBtn, 6)
    pressFX(loadBtn)

    loadBtn.MouseButton1Click:Connect(function()
        local url = inputBox.Text:gsub("%s+", "")
        if url ~= "" then
            loadImageFromUrl(url)
            inputBox.Text = ""
            rebuildUI()
        end
    end)

    inputBox.FocusLost:Connect(function(enter)
        if enter then loadBtn.MouseButton1Click:Fire() end
    end)

    -- List objek gambar
    local listLbl = Instance.new("TextLabel", container)
    listLbl.Size = UDim2.new(1, 0, 0, 20)
    listLbl.Position = UDim2.new(0, 0, 0, 52)
    listLbl.BackgroundTransparency = 1
    listLbl.Text = "Gambar Aktif:"
    listLbl.TextColor3 = C.text2
    listLbl.Font = Enum.Font.GothamBold
    listLbl.TextSize = 10
    listLbl.TextXAlignment = Enum.TextXAlignment.Left

    local listScroll = Instance.new("ScrollingFrame", container)
    listScroll.Size = UDim2.new(1, 0, 0, 160)
    listScroll.Position = UDim2.new(0, 0, 0, 74)
    listScroll.BackgroundColor3 = C.card3
    listScroll.BorderSizePixel = 0
    listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    listScroll.ScrollBarThickness = 2

    local listLayout = Instance.new("UIListLayout", listScroll)
    listLayout.Padding = UDim.new(0, 4)

    local listPad = Instance.new("UIPadding", listScroll)
    listPad.PaddingTop = UDim.new(0, 4)
    listPad.PaddingBottom = UDim.new(0, 4)

    -- Render image list
    local order = 0
    for obj, data in pairs(State.objects) do
        if data.type == "image" then
            order = order + 1
            local isSel = (State.selectedObject == obj)

            local row = Instance.new("Frame", listScroll)
            row.Size = UDim2.new(1, 0, 0, 28)
            row.BackgroundColor3 = isSel and C.gold or C.card2
            row.LayoutOrder = order
            corner(row, 6)

            local nameLbl = Instance.new("TextLabel", row)
            nameLbl.Size = UDim2.new(1, -50, 0, 20)
            nameLbl.Position = UDim2.new(0, 8, 0, 4)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text = data.name or "Image"
            nameLbl.TextColor3 = isSel and Color3.fromRGB(10, 10, 10) or C.text
            nameLbl.Font = Enum.Font.Gotham
            nameLbl.TextSize = 10
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

            local selBtn = Instance.new("TextButton", row)
            selBtn.Size = UDim2.new(0, 40, 0, 20)
            selBtn.Position = UDim2.new(1, -44, 0.5, -10)
            selBtn.BackgroundColor3 = isSel and Color3.new(1, 1, 1) or C.card3
            selBtn.Text = isSel and "✓" or "Pilih"
            selBtn.TextColor3 = isSel and C.gold or C.text2
            selBtn.Font = Enum.Font.GothamBold
            selBtn.TextSize = 8
            selBtn.AutoButtonColor = false
            corner(selBtn, 4)
            pressFX(selBtn)

            selBtn.MouseButton1Click:Connect(function()
                State.selectedObject = obj
                setupGizmo(Gizmos.Handles, State.gizmoMode)
                rebuildUI()
            end)

            local delBtn = Instance.new("TextButton", row)
            delBtn.Size = UDim2.new(0, 20, 0, 20)
            delBtn.Position = UDim2.new(1, -22, 0.5, -10)
            delBtn.BackgroundColor3 = C.red
            delBtn.Text = "✕"
            delBtn.TextColor3 = Color3.new(1, 1, 1)
            delBtn.Font = Enum.Font.GothamBold
            delBtn.TextSize = 10
            delBtn.AutoButtonColor = false
            corner(delBtn, 4)
            pressFX(delBtn)

            delBtn.MouseButton1Click:Connect(function()
                State.objects[obj] = nil
                if State.selectedObject == obj then
                    State.selectedObject = nil
                    setupGizmo(Gizmos.Handles, State.gizmoMode)
                end
                pcall(function() obj:Destroy() end)
                rebuildUI()
            end)
        end
    end

    if order == 0 then
        local empty = Instance.new("TextLabel", listScroll)
        empty.Size = UDim2.new(1, 0, 0, 30)
        empty.BackgroundTransparency = 1
        empty.Text = "Belum ada gambar. Load URL di atas!"
        empty.TextColor3 = C.text3
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 9
        empty.LayoutOrder = 1
    end

    return container
end

local function renderConfigTab(parent)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, 0, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.BackgroundTransparency = 1
    container.LayoutOrder = 2

    -- ===== SAVE SECTION =====
    local saveFrame = Instance.new("Frame", container)
    saveFrame.Size = UDim2.new(1, 0, 0, 44)
    saveFrame.BackgroundColor3 = C.card2
    saveFrame.LayoutOrder = 0
    corner(saveFrame, 10)
    stroke(saveFrame, C.border, 1, 0.4)

    local saveInput = Instance.new("TextBox", saveFrame)
    saveInput.Size = UDim2.new(1, -180, 0, 32)
    saveInput.Position = UDim2.new(0, 8, 0.5, -16)
    saveInput.BackgroundColor3 = C.card3
    saveInput.PlaceholderText = "Nama config..."
    saveInput.Text = ""
    saveInput.TextColor3 = C.text
    saveInput.Font = Enum.Font.Gotham
    saveInput.TextSize = 11
    saveInput.ClearTextOnFocus = false
    corner(saveInput, 6)

    local saveBtn = Instance.new("TextButton", saveFrame)
    saveBtn.Size = UDim2.new(0, 78, 0, 32)
    saveBtn.Position = UDim2.new(1, -86, 0.5, -16)
    saveBtn.BackgroundColor3 = C.green
    saveBtn.Text = isDeveloper and "Save Public" or "Save Private"
    saveBtn.TextColor3 = Color3.fromRGB(10, 10, 10)
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.TextSize = 9
    saveBtn.AutoButtonColor = false
    corner(saveBtn, 6)
    pressFX(saveBtn)

    saveBtn.MouseButton1Click:Connect(function()
        local name = saveInput.Text:gsub("%s+", " ")
        if name ~= "" then
            saveConfig(name)
            saveInput.Text = ""
            rebuildUI()
        else
            notify("Masukkan nama config!", C.red)
        end
    end)

    -- ===== LOAD SECTION =====
    local loadFrame = Instance.new("Frame", container)
    loadFrame.Size = UDim2.new(1, 0, 0, 0)
    loadFrame.AutomaticSize = Enum.AutomaticSize.Y
    loadFrame.BackgroundTransparency = 1
    loadFrame.LayoutOrder = 1

    local loadLbl = Instance.new("TextLabel", loadFrame)
    loadLbl.Size = UDim2.new(1, 0, 0, 22)
    loadLbl.BackgroundTransparency = 1
    loadLbl.Text = "📂 Load Config"
    loadLbl.TextColor3 = C.text2
    loadLbl.Font = Enum.Font.GothamBold
    loadLbl.TextSize = 11
    loadLbl.TextXAlignment = Enum.TextXAlignment.Left

    -- Tabs: Lokal | Dev (Public) | Player (Self)
    local subTabBar = Instance.new("Frame", loadFrame)
    subTabBar.Size = UDim2.new(1, 0, 0, 28)
    subTabBar.BackgroundTransparency = 1

    local subTabLayout = Instance.new("UIListLayout", subTabBar)
    subTabLayout.FillDirection = Enum.FillDirection.Horizontal
    subTabLayout.Padding = UDim.new(0, 4)

    local loadSource = "local"
    local configListCache = {localConfigs = {}, devConfigs = {}, playerConfigs = {}}
    local loadingFlags = {local = false, dev = false, player = false}

    local function refreshConfigList(source)
        loadSource = source
        rebuildUI()
    end

    local function renderConfigList(container, configs, source)
        for _, child in ipairs(container:GetChildren()) do
            if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
                child:Destroy()
            end
        end

        if #configs == 0 then
            local empty = Instance.new("TextLabel", container)
            empty.Size = UDim2.new(1, 0, 0, 30)
            empty.BackgroundTransparency = 1
            empty.Text = "Tidak ada config " .. (source == "dev" and "PUBLIC" or source == "player" and "PRIVAT" or "lokal")
            empty.TextColor3 = C.text3
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 9
            empty.LayoutOrder = 1
            return
        end

        for i, entry in ipairs(configs) do
            local row = Instance.new("Frame", container)
            row.Size = UDim2.new(1, 0, 0, 32)
            row.BackgroundColor3 = C.card2
            row.LayoutOrder = i
            corner(row, 6)
            stroke(row, C.border, 1, 0.3)

            local nameLbl = Instance.new("TextLabel", row)
            nameLbl.Size = UDim2.new(1, -100, 0, 20)
            nameLbl.Position = UDim2.new(0, 8, 0, 6)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text = entry.name
            nameLbl.TextColor3 = C.text
            nameLbl.Font = Enum.Font.GothamBold
            nameLbl.TextSize = 10
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

            if source == "dev" and entry.ownerName then
                local ownerLbl = Instance.new("TextLabel", row)
                ownerLbl.Size = UDim2.new(0, 100, 0, 14)
                ownerLbl.Position = UDim2.new(1, -108, 0.5, -2)
                ownerLbl.BackgroundTransparency = 1
                ownerLbl.Text = "👤 " .. entry.ownerName
                ownerLbl.TextColor3 = C.dev
                ownerLbl.Font = Enum.Font.Gotham
                ownerLbl.TextSize = 7
                ownerLbl.TextXAlignment = Enum.TextXAlignment.Right
            end

            local loadBtn = Instance.new("TextButton", row)
            loadBtn.Size = UDim2.new(0, 50, 0, 24)
            loadBtn.Position = UDim2.new(1, -56, 0.5, -12)
            loadBtn.BackgroundColor3 = C.accent
            loadBtn.Text = "Load"
            loadBtn.TextColor3 = Color3.new(1, 1, 1)
            loadBtn.Font = Enum.Font.GothamBold
            loadBtn.TextSize = 8
            loadBtn.AutoButtonColor = false
            corner(loadBtn, 4)
            pressFX(loadBtn)

            loadBtn.MouseButton1Click:Connect(function()
                if source == "local" then
                    loadConfig(entry.name)
                elseif source == "dev" then
                    loadConfig(entry.name, entry.data)
                elseif source == "player" then
                    loadConfig(entry.name, entry.data)
                end
                rebuildUI()
            end)
        end
    end

    -- Build sub-tabs: Lokal, Public (Dev), Private (Self)
    local subTabs = {}
    local function makeSubTab(label, source)
        local btn = Instance.new("TextButton", subTabBar)
        btn.Size = UDim2.new(0, 0, 1, 0)
        btn.AutomaticSize = Enum.AutomaticSize.X
        btn.BackgroundColor3 = (loadSource == source) and C.accent or C.card3
        btn.Text = ""
        btn.AutoButtonColor = false
        corner(btn, 6)

        local pad = Instance.new("UIPadding", btn)
        pad.PaddingLeft = UDim.new(0, 12)
        pad.PaddingRight = UDim.new(0, 12)

        local lbl = Instance.new("TextLabel", btn)
        lbl.Size = UDim2.new(0, 0, 1, 0)
        lbl.AutomaticSize = Enum.AutomaticSize.X
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = (loadSource == source) and Color3.new(1, 1, 1) or C.text2
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 9

        pressFX(btn)

        btn.MouseButton1Click:Connect(function()
            loadSource = source
            for _, tb in ipairs(subTabs) do
                tb.BackgroundColor3 = C.card3
                local lbl = tb:FindFirstChildOfClass("TextLabel")
                if lbl then lbl.TextColor3 = C.text2 end
            end
            btn.BackgroundColor3 = C.accent
            if lbl then lbl.TextColor3 = Color3.new(1, 1, 1) end
            rebuildUI()
        end)

        table.insert(subTabs, btn)
        return btn
    end

    makeSubTab("📁 Lokal", "local")
    makeSubTab("🌍 Public (Dev)", "dev")
    makeSubTab("🔒 Private (Saya)", "player")

    -- Container list config
    local listContainer = Instance.new("ScrollingFrame", loadFrame)
    listContainer.Size = UDim2.new(1, 0, 0, 180)
    listContainer.BackgroundColor3 = C.card3
    listContainer.BorderSizePixel = 0
    listContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    listContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    listContainer.ScrollBarThickness = 2

    local listLayout = Instance.new("UIListLayout", listContainer)
    listLayout.Padding = UDim.new(0, 4)

    local listPad = Instance.new("UIPadding", listContainer)
    listPad.PaddingTop = UDim.new(0, 4)
    listPad.PaddingBottom = UDim.new(0, 4)

    -- ===== FETCH & RENDER LIST =====
    local function fetchAndRenderConfigs()
        if loadSource == "local" then
            local configs = {}
            if Storage.appSettings and Storage.appSettings.model3dConfigs then
                for name, data in pairs(Storage.appSettings.model3dConfigs) do
                    if type(data) == "table" and data.objects then
                        table.insert(configs, {name = name, data = data})
                    end
                end
            end
            table.sort(configs, function(a, b) return a.name < b.name end)
            renderConfigList(listContainer, configs, "local")

        elseif loadSource == "dev" then
            if not loadingFlags.dev then
                loadingFlags.dev = true
                if Firebase and Firebase.GetDevModel3DConfigs then
                    pcall(function()
                        Firebase.GetDevModel3DConfigs(function(success, data)
                            configListCache.devConfigs = {}
                            if success and type(data) == "table" then
                                for name, cfg in pairs(data) do
                                    if type(cfg) == "table" and cfg.objects then
                                        local ownerName = cfg.savedByName or "Developer"
                                        table.insert(configListCache.devConfigs, {
                                            name = name,
                                            data = cfg,
                                            ownerName = ownerName,
                                        })
                                    end
                                end
                                table.sort(configListCache.devConfigs, function(a, b) return a.name < b.name end)
                            end
                            loadingFlags.dev = false
                            rebuildUI()
                        end)
                    end)
                end
            end
            renderConfigList(listContainer, configListCache.devConfigs, "dev")

        elseif loadSource == "player" then
            if not loadingFlags.player then
                loadingFlags.player = true
                if Firebase and Firebase.GetPlayerModel3DConfigs then
                    pcall(function()
                        Firebase.GetPlayerModel3DConfigs(LocalPlayer.UserId, function(success, data)
                            configListCache.playerConfigs = {}
                            if success and type(data) == "table" then
                                for name, cfg in pairs(data) do
                                    if type(cfg) == "table" and cfg.objects then
                                        table.insert(configListCache.playerConfigs, {name = name, data = cfg})
                                    end
                                end
                                table.sort(configListCache.playerConfigs, function(a, b) return a.name < b.name end)
                            end
                            loadingFlags.player = false
                            rebuildUI()
                        end)
                    end)
                end
            end
            renderConfigList(listContainer, configListCache.playerConfigs, "player")
        end
    end

    -- Load initial
    task.spawn(function()
        task.wait(0.1)
        fetchAndRenderConfigs()
    end)

    -- Override rebuildUI untuk tab config agar refresh list
    local oldRebuild = rebuildUI
    rebuildUI = function()
        oldRebuild()
        if State.currentTab == "Config" then
            fetchAndRenderConfigs()
        end
    end

    -- ===== DEV ONLY: LOAD PLAYER CONFIG BY USER ID =====
    if isDeveloper then
        local devFrame = Instance.new("Frame", container)
        devFrame.Size = UDim2.new(1, 0, 0, 44)
        devFrame.BackgroundColor3 = C.card2
        devFrame.LayoutOrder = 2
        corner(devFrame, 10)
        stroke(devFrame, C.dev, 1, 0.5)

        local devLabel = Instance.new("TextLabel", devFrame)
        devLabel.Size = UDim2.new(1, -180, 0, 16)
        devLabel.Position = UDim2.new(0, 8, 0, 4)
        devLabel.BackgroundTransparency = 1
        devLabel.Text = "👑 Load Config Player Lain (User ID)"
        devLabel.TextColor3 = C.dev
        devLabel.Font = Enum.Font.GothamBold
        devLabel.TextSize = 9
        devLabel.TextXAlignment = Enum.TextXAlignment.Left

        local devInput = Instance.new("TextBox", devFrame)
        devInput.Size = UDim2.new(1, -180, 0, 24)
        devInput.Position = UDim2.new(0, 8, 0, 22)
        devInput.BackgroundColor3 = C.card3
        devInput.PlaceholderText = "User ID | Nama Config"
        devInput.Text = ""
        devInput.TextColor3 = C.text
        devInput.Font = Enum.Font.Gotham
        devInput.TextSize = 9
        devInput.ClearTextOnFocus = false
        corner(devInput, 4)

        local devLoadBtn = Instance.new("TextButton", devFrame)
        devLoadBtn.Size = UDim2.new(0, 78, 0, 28)
        devLoadBtn.Position = UDim2.new(1, -86, 0.5, -8)
        devLoadBtn.BackgroundColor3 = C.dev
        devLoadBtn.Text = "Load Player"
        devLoadBtn.TextColor3 = Color3.fromRGB(10, 10, 10)
        devLoadBtn.Font = Enum.Font.GothamBold
        devLoadBtn.TextSize = 9
        devLoadBtn.AutoButtonColor = false
        corner(devLoadBtn, 6)
        pressFX(devLoadBtn)

        devLoadBtn.MouseButton1Click:Connect(function()
            local parts = splitPath(devInput.Text, "|")
            if #parts >= 2 then
                local userId = tonumber(parts[1]:gsub("%s+", ""))
                local configName = parts[2]:gsub("^%s+", ""):gsub("%s+$", "")
                if userId and configName ~= "" then
                    loadPlayerConfigByUserId(userId, configName)
                    devInput.Text = ""
                else
                    notify("Format: UserID | NamaConfig", C.red)
                end
            else
                notify("Format: UserID | NamaConfig", C.red)
            end
        end)
    end

    return container
end

-- ==================== RENDER ACTION BAR ====================
local function renderActionBar(parent)
    local bar = Instance.new("Frame", parent)
    bar.Size = UDim2.new(1, 0, 0, 40)
    bar.BackgroundColor3 = C.card2
    bar.LayoutOrder = 3
    corner(bar, 10)
    stroke(bar, C.border, 1, 0.3)

    local actionLayout = Instance.new("UIListLayout", bar)
    actionLayout.FillDirection = Enum.FillDirection.Horizontal
    actionLayout.Padding = UDim.new(0, 4)

    local pad = Instance.new("UIPadding", bar)
    pad.PaddingLeft = UDim.new(0, 4)
    pad.PaddingRight = UDim.new(0, 4)
    pad.PaddingTop = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 4)

    -- Gizmo mode buttons
    local modes = {
        {key = "position", label = "📍 Posisi", color = C.accent},
        {key = "rotation", label = "🔄 Rotasi", color = C.accent2},
        {key = "resize", label = "📐 Ukuran", color = C.gold},
    }

    for _, m in ipairs(modes) do
        local isActive = (State.gizmoMode == m.key)
        local btn = Instance.new("TextButton", bar)
        btn.Size = UDim2.new(0, 0, 1, 0)
        btn.AutomaticSize = Enum.AutomaticSize.X
        btn.BackgroundColor3 = isActive and m.color or C.card3
        btn.Text = ""
        btn.AutoButtonColor = false
        corner(btn, 6)

        local p = Instance.new("UIPadding", btn)
        p.PaddingLeft = UDim.new(0, 8)
        p.PaddingRight = UDim.new(0, 8)

        local lbl = Instance.new("TextLabel", btn)
        lbl.Size = UDim2.new(0, 0, 1, 0)
        lbl.AutomaticSize = Enum.AutomaticSize.X
        lbl.BackgroundTransparency = 1
        lbl.Text = m.label
        lbl.TextColor3 = isActive and Color3.new(1, 1, 1) or C.text2
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 9

        pressFX(btn)

        btn.MouseButton1Click:Connect(function()
            State.gizmoMode = m.key
            setupGizmo(Gizmos.Handles, State.gizmoMode)
            rebuildUI()
        end)
    end

    -- Spacer
    local spacer = Instance.new("Frame", bar)
    spacer.Size = UDim2.new(1, -320, 1, 0)
    spacer.BackgroundTransparency = 1

    -- Delete selected
    local delBtn = Instance.new("TextButton", bar)
    delBtn.Size = UDim2.new(0, 48, 1, 0)
    delBtn.BackgroundColor3 = C.red
    delBtn.Text = "✕"
    delBtn.TextColor3 = Color3.new(1, 1, 1)
    delBtn.Font = Enum.Font.GothamBold
    delBtn.TextSize = 14
    delBtn.AutoButtonColor = false
    corner(delBtn, 6)
    pressFX(delBtn)
    delBtn.MouseButton1Click:Connect(deleteSelectedObject)

    -- Clear all
    local clearBtn = Instance.new("TextButton", bar)
    clearBtn.Size = UDim2.new(0, 48, 1, 0)
    clearBtn.BackgroundColor3 = C.border
    clearBtn.Text = "🗑"
    clearBtn.TextColor3 = C.text2
    clearBtn.Font = Enum.Font.GothamBold
    clearBtn.TextSize = 14
    clearBtn.AutoButtonColor = false
    corner(clearBtn, 6)
    pressFX(clearBtn)
    clearBtn.MouseButton1Click:Connect(clearAllObjects)

    return bar
end

-- ==================== REBUILD UI ====================
rebuildUI = function()
    if not appContent then return end

    -- Clear all children
    for _, child in ipairs(appContent:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end

    -- Create layout
    local layout = Instance.new("UIListLayout", appContent)
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    -- Render all sections
    renderHeader(appContent)
    renderTabBar(appContent)

    if State.currentTab == "Models" then
        renderModelsTab(appContent)
    elseif State.currentTab == "Images" then
        renderImagesTab(appContent)
    elseif State.currentTab == "Config" then
        renderConfigTab(appContent)
    end

    renderActionBar(appContent)
end

-- ==================== ENTRY POINT ====================
function _G.openModel3DApp()
    -- Pastikan gizmo ada
    if not Gizmos.Handles then
        createGizmo()
    end

    -- Setup gizmo sesuai mode
    setupGizmo(Gizmos.Handles, State.gizmoMode)

    -- Render UI
    rebuildUI()

    notify("🧊 Model3D Studio siap! Load model atau gambar.", C.accent)
end

-- ==================== AUTO INITIALIZE GIZMO ====================
task.spawn(function()
    task.wait(0.5)
    if not Gizmos.Handles then
        createGizmo()
    end
end)

print("[Model3D] Loaded! Developer mode:", isDeveloper)