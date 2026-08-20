-- ================================================
-- APPLICATIONS/CLONE.LUA — Personal Clone Manager (Premium)
-- Client-side visual clone system. Clones are local-only (LocalPlayer's
-- own view), do not affect the real Character, and never touch other
-- players' Tools/inventory/appearance.
--
-- Sections: CONSTANTS, CloneData, CloneManager, Movement, Rotation,
--           Emote, Follow, Item, Chat, CloneController(UI), Cleanup
-- ================================================

local Services    = _G.Services
local T           = _G.T or {}
local Helpers     = _G.Helpers or {}
local LocalPlayer = _G.LocalPlayer
local Storage     = _G.Storage
local appContent  = _G.appContent

local RunService       = Services.RunService or game:GetService("RunService")
local TweenService     = Services.TweenService or game:GetService("TweenService")
local Players           = Services.Players or game:GetService("Players")
local Workspace         = Services.Workspace or game:GetService("Workspace")
local HttpService       = Services.HttpService or game:GetService("HttpService")

-- ==================== CONSTANTS ====================
local WHITE        = Color3.fromRGB(255, 255, 255)
local BLACK        = Color3.fromRGB(15, 15, 20)
local LIGHT_GRAY    = Color3.fromRGB(247, 246, 250)
local DARK_GRAY     = Color3.fromRGB(120, 118, 132)
local ACCENT        = Color3.fromRGB(24, 22, 32)
local PURPLE        = Color3.fromRGB(124, 58, 237)
local PURPLE_LIGHT  = Color3.fromRGB(167, 120, 244)
local PURPLE_SOFT   = Color3.fromRGB(237, 231, 250)
local GREEN         = Color3.fromRGB(0, 200, 100)
local RED           = Color3.fromRGB(255, 80, 80)

-- Satu variabel tunggal untuk mengatur batas jumlah clone.
local MAX_CLONES = 5

local CLONE_FOLDER_NAME = "PhoneIDViewer_Clones"
local CLONE_TAG = "PIV_Clone" -- ditaruh di Model:SetAttribute untuk identifikasi cepat
local DEFAULT_MOVE_DISTANCE = 2
local DEFAULT_ROTATE_STEP = 45
local FOLLOW_UPDATE_HZ = 1 / 20 -- 20 update/detik cukup halus, hemat performa

-- ==================== FOLDER SETUP ====================
-- Semua clone ditaruh dalam satu folder khusus supaya rapi dan gampang
-- dibersihkan total (mis. saat script di-reload).
local cloneFolder = Workspace:FindFirstChild(CLONE_FOLDER_NAME)
if not cloneFolder then
    cloneFolder = Instance.new("Folder")
    cloneFolder.Name = CLONE_FOLDER_NAME
    cloneFolder.Parent = Workspace
end

-- ==================== CLONE DATA STORE ====================
-- CloneData: representasi murni data (bukan instance) untuk tiap clone.
-- Dipisah dari CloneManager supaya gampang di-serialize/disimpan/ditampilkan
-- di UI tanpa perlu bergantung pada instance Roblox yang bisa hilang.
local CloneData = {}
CloneData.__index = CloneData

function CloneData.new(id, name)
    local self = setmetatable({}, CloneData)
    self.id = id
    self.name = name or ("Clone " .. tostring(id):sub(1, 4))
    self.position = Vector3.new(0, 0, 0)
    self.rotationY = 0
    self.currentEmote = nil
    self.emoteLooping = false
    self.followTarget = nil -- Player instance atau nil
    self.followMode = "both" -- "position" | "rotation" | "both"
    self.followDistance = 3
    self.followEnabled = false
    self.heldItemName = nil
    self.visible = true
    self.locked = false
    self.chatHistory = {} -- {text, timestamp}
    return self
end

-- ==================== GLOBAL REGISTRY ====================
-- _G.CloneRegistry menyimpan semua clone aktif sepanjang sesi script,
-- supaya app lain / reload UI tetap bisa mengakses clone yang sama.
_G.CloneRegistry = _G.CloneRegistry or {
    clones = {},      -- [id] = { data = CloneData, model, humanoid, connections = {} }
    order = {},        -- urutan id untuk list stabil
    selectedId = nil,
    presets = {},       -- [presetName] = { [id] = {position, rotationY} }
}
local Registry = _G.CloneRegistry

-- Load presets tersimpan (jika ada)
if Storage and Storage.appSettings and Storage.appSettings.clonePresets then
    Registry.presets = Storage.appSettings.clonePresets
end

local function savePresetsToStorage()
    if Storage and Storage.appSettings then
        Storage.appSettings.clonePresets = Registry.presets
        pcall(function() if Storage.persistSettings then Storage.persistSettings() end end)
    end
end

local function genId()
    return HttpService:GenerateGUID(false)
end

local function notify(text, color)
    if _G.showDynamicNotification then
        _G.showDynamicNotification(text, color or PURPLE)
    end
end

-- ==================== FORWARD DECLARATIONS ====================
local refreshCloneListUI -- didefinisikan di bagian UI, dipanggil dari manager
local openClonePanel     -- didefinisikan di bagian UI

-- ==================== CLONE MANAGER ====================
local CloneManager = {}

function CloneManager.getCount()
    return #Registry.order
end

function CloneManager.getEntry(id)
    return Registry.clones[id]
end

function CloneManager.getAll()
    local list = {}
    for _, id in ipairs(Registry.order) do
        local entry = Registry.clones[id]
        if entry then table.insert(list, entry) end
    end
    return list
end

-- Membangun clone model baru dari HumanoidDescription milik LocalPlayer.
-- Memakai R15 dummy dasar + ApplyDescription supaya ringan dan stabil,
-- alih-alih :Clone() Character penuh (yang bisa membawa script/koneksi
-- yang tidak diinginkan ikut ter-clone).
local function buildCloneModel(spawnCFrame)
    local character = LocalPlayer.Character
    if not character then
        return nil, "Character LocalPlayer belum siap"
    end
    local sourceHumanoid = character:FindFirstChildOfClass("Humanoid")
    if not sourceHumanoid then
        return nil, "Humanoid LocalPlayer tidak ditemukan"
    end

    local ok, description = pcall(function()
        return sourceHumanoid:GetAppliedDescription()
    end)
    if not ok or not description then
        return nil, "Gagal membaca appearance LocalPlayer"
    end

    -- Dummy dasar R15 dari Players service — ini API resmi Roblox
    -- (bukan exploit-only), aman dipakai di client manapun.
    -- AssetTypeVerification.ClientOnly dipakai eksplisit karena kita cuma
    -- menyalin appearance LocalPlayer sendiri (bukan asset pihak ketiga
    -- yang tidak dipercaya) dan proses ini murni berjalan di client.
    -- Lihat: Roblox HumanoidDescription API update (efektif 27 Okt 2025).
    local rigOk, dummy = pcall(function()
        return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15, Enum.AssetTypeVerification.ClientOnly)
    end)
    if not rigOk or not dummy then
        return nil, "Gagal membuat model dari appearance"
    end

    dummy.Name = "Clone"
    for _, part in ipairs(dummy:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = (part.Name == "HumanoidRootPart") and false or true
            part.Anchored = false
            part.CollisionGroup = "Default"
        elseif part:IsA("Script") or part:IsA("LocalScript") then
            -- Buang script bawaan avatar (mis. animate script default) supaya
            -- clone tidak menjalankan logika yang tidak diperlukan/berat.
            part:Destroy()
        end
    end

    local humanoid = dummy:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        humanoid.PlatformStand = false
        humanoid.RequiresNeck = false
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        humanoid.BreakJointsOnDeath = false
        humanoid.EvaluateStateMachine = false -- clone diam, tidak perlu state machine berat
    end

    local hrp = dummy:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.Anchored = true -- clone diam total by default (requirement: tidak ikut player)
        hrp.CFrame = spawnCFrame
    end

    -- Minimal animate script supaya pose tidak kaku total (idle look),
    -- tapi ringan: hanya Animator, tanpa full AnimateScript bawaan Roblox.
    if humanoid and not humanoid:FindFirstChildOfClass("Animator") then
        local animator = Instance.new("Animator")
        animator.Parent = humanoid
    end

    return dummy, nil
end

-- Membuat BillboardGui nametag di atas kepala clone (nama + status online).
local function attachNameTag(model, data)
    local head = model:FindFirstChild("Head")
    if not head then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "CloneNameTag"
    billboard.Size = UDim2.new(0, 140, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 1.1, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = head

    local wrap = Instance.new("Frame", billboard)
    wrap.Size = UDim2.new(1, 0, 1, 0)
    wrap.BackgroundTransparency = 1

    local nameLbl = Instance.new("TextLabel", wrap)
    nameLbl.Name = "NameLbl"
    nameLbl.Size = UDim2.new(1, 0, 0, 20)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = data.name
    nameLbl.TextColor3 = WHITE
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 14
    nameLbl.TextStrokeTransparency = 0.3

    local statusLbl = Instance.new("TextLabel", wrap)
    statusLbl.Name = "StatusLbl"
    statusLbl.Size = UDim2.new(1, 0, 0, 16)
    statusLbl.Position = UDim2.new(0, 0, 0, 20)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text = "● Online"
    statusLbl.TextColor3 = GREEN
    statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextSize = 11
    statusLbl.TextStrokeTransparency = 0.4

    return billboard
end

-- CREATE CLONE
function CloneManager.create()
    if CloneManager.getCount() >= MAX_CLONES then
        notify("Batas maksimal " .. MAX_CLONES .. " clone tercapai!", RED)
        return nil
    end

    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        notify("Karakter belum siap!", RED)
        return nil
    end

    -- Spawn sedikit di depan player supaya tidak menumpuk pas dibuat.
    local spawnCFrame = hrp.CFrame * CFrame.new(0, 0, -4)

    local model, err = buildCloneModel(spawnCFrame)
    if not model then
        notify(err or "Gagal membuat clone", RED)
        return nil
    end

    local id = genId()
    local data = CloneData.new(id)
    data.position = spawnCFrame.Position
    data.rotationY = select(2, spawnCFrame:ToEulerAnglesYXZ()) -- fallback, diganti di bawah

    -- Ambil rotasi Y yang benar dari CFrame
    local _, y, _ = spawnCFrame:ToOrientation()
    data.rotationY = math.deg(y)

    model:SetAttribute(CLONE_TAG, id)
    model.Parent = cloneFolder
    attachNameTag(model, data)

    local entry = {
        data = data,
        model = model,
        humanoid = model:FindFirstChildOfClass("Humanoid"),
        connections = {}, -- semua RBXScriptConnection spesifik-clone (click detector dsb)
        animTrack = nil,
        followAlive = false,
        heldTool = nil,
    }

    Registry.clones[id] = entry
    table.insert(Registry.order, id)

    -- ClickDetector supaya clone bisa disentuh/diklik untuk membuka panel.
    local clickDetector = Instance.new("ClickDetector", model.PrimaryPart or model:FindFirstChild("HumanoidRootPart"))
    clickDetector.MaxActivationDistance = 32
    table.insert(entry.connections, clickDetector.MouseClick:Connect(function()
        Registry.selectedId = id
        if openClonePanel then openClonePanel(id) end
    end))

    -- Sentuhan langsung ke HRP juga membuka panel (requirement: disentuh/diklik/tap)
    local hrpPart = model:FindFirstChild("HumanoidRootPart")
    if hrpPart then
        local lastTouch = 0
        table.insert(entry.connections, hrpPart.Touched:Connect(function(hit)
            local touchingChar = hit and hit.Parent
            if touchingChar and Players:GetPlayerFromCharacter(touchingChar) == LocalPlayer then
                local now = os.clock()
                if now - lastTouch > 1 then -- debounce
                    lastTouch = now
                    Registry.selectedId = id
                    if openClonePanel then openClonePanel(id) end
                end
            end
        end))
    end

    notify("Clone dibuat: " .. data.name, GREEN)
    if refreshCloneListUI then refreshCloneListUI() end
    return id
end

-- ==================== CLEANUP ====================
-- Cleanup terpusat: memastikan SEMUA jejak clone dibersihkan tuntas
-- (model, koneksi event, animation track, follow connection, chat UI,
-- listener lain, dan data). Dipanggil oleh Delete/DeleteAll dan saat
-- script mati.
local function cleanupCloneEntry(id)
    local entry = Registry.clones[id]
    if not entry then return end

    -- 1. Stop & clear animation track
    if entry.animTrack then
        pcall(function() entry.animTrack:Stop() end)
        entry.animTrack = nil
    end

    -- 2. Disconnect semua koneksi spesifik-clone (click, touch, dll)
    for _, conn in ipairs(entry.connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(entry.connections)

    -- 3. Follow connection ditangani lewat flag terpusat (lihat FOLLOW SYSTEM)
    entry.followAlive = false
    entry.data.followEnabled = false
    entry.data.followTarget = nil

    -- 4. Chat UI (bubble) ikut hilang otomatis karena Parent-nya model,
    --    tapi kita bersihkan referensi eksplisit untuk jaga-jaga leak.
    entry.chatBubble = nil

    -- 5. Held item representation
    if entry.heldTool then
        pcall(function() entry.heldTool:Destroy() end)
        entry.heldTool = nil
    end

    -- 6. Destroy model (ini juga menghapus BillboardGui, ClickDetector, dsb
    --    karena semuanya adalah descendant model)
    if entry.model then
        pcall(function() entry.model:Destroy() end)
    end

    -- 7. Hapus dari registry & data
    Registry.clones[id] = nil
    local idx = table.find(Registry.order, id)
    if idx then table.remove(Registry.order, idx) end
    if Registry.selectedId == id then Registry.selectedId = nil end
end

function CloneManager.delete(id)
    local entry = Registry.clones[id]
    if not entry then return false end
    local name = entry.data.name
    cleanupCloneEntry(id)
    notify("Clone dihapus: " .. name, RED)
    if refreshCloneListUI then refreshCloneListUI() end
    return true
end

function CloneManager.deleteAll()
    local ids = {}
    for _, id in ipairs(Registry.order) do table.insert(ids, id) end
    for _, id in ipairs(ids) do cleanupCloneEntry(id) end
    notify("Semua clone dihapus", RED)
    if refreshCloneListUI then refreshCloneListUI() end
end

function CloneManager.rename(id, newName)
    local entry = Registry.clones[id]
    if not entry or not newName or newName:gsub("%s", "") == "" then return false end
    entry.data.name = newName:sub(1, 24)
    local tag = entry.model and entry.model:FindFirstChild("CloneNameTag")
    local nameLbl = tag and tag:FindFirstChild("NameLbl", true)
    if not nameLbl and tag then
        local wrap = tag:FindFirstChildOfClass("Frame")
        nameLbl = wrap and wrap:FindFirstChild("NameLbl")
    end
    if nameLbl then nameLbl.Text = entry.data.name end
    if refreshCloneListUI then refreshCloneListUI() end
    return true
end

function CloneManager.setVisible(id, visible)
    local entry = Registry.clones[id]
    if not entry or not entry.model then return end
    entry.data.visible = visible
    for _, part in ipairs(entry.model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.LocalTransparencyModifier = visible and 0 or 1
        elseif part:IsA("Decal") then
            part.Transparency = visible and 0 or 1
        end
    end
    local tag = entry.model:FindFirstChild("CloneNameTag")
    if tag then tag.Enabled = visible end
    if refreshCloneListUI then refreshCloneListUI() end
end

-- ==================== PRESETS ====================
-- Preset menyimpan posisi+rotasi SEMUA clone yang sedang ada (mis. untuk
-- formasi). Disimpan ke Storage supaya persist antar sesi.
function CloneManager.savePreset(presetName)
    if not presetName or presetName:gsub("%s","") == "" then
        notify("Nama preset tidak boleh kosong", RED)
        return false
    end
    local snapshot = {}
    for _, id in ipairs(Registry.order) do
        local entry = Registry.clones[id]
        local hrp = entry and entry.model and entry.model:FindFirstChild("HumanoidRootPart")
        if hrp then
            snapshot[id] = {
                position = {hrp.Position.X, hrp.Position.Y, hrp.Position.Z},
                rotationY = entry.data.rotationY,
                name = entry.data.name,
            }
        end
    end
    Registry.presets[presetName] = snapshot
    savePresetsToStorage()
    notify("Preset disimpan: " .. presetName, GREEN)
    return true
end

function CloneManager.loadPreset(presetName)
    local snapshot = Registry.presets[presetName]
    if not snapshot then
        notify("Preset tidak ditemukan", RED)
        return false
    end
    for id, saved in pairs(snapshot) do
        local entry = Registry.clones[id]
        local hrp = entry and entry.model and entry.model:FindFirstChild("HumanoidRootPart")
        if hrp then
            local pos = Vector3.new(saved.position[1], saved.position[2], saved.position[3])
            hrp.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(saved.rotationY or 0), 0)
            entry.data.position = pos
            entry.data.rotationY = saved.rotationY or 0
        end
    end
    notify("Preset dimuat: " .. presetName, PURPLE)
    return true
end

function CloneManager.deletePreset(presetName)
    if Registry.presets[presetName] then
        Registry.presets[presetName] = nil
        savePresetsToStorage()
        notify("Preset dihapus: " .. presetName, RED)
        return true
    end
    return false
end

function CloneManager.listPresetNames()
    local names = {}
    for name in pairs(Registry.presets) do table.insert(names, name) end
    table.sort(names)
    return names
end

function CloneManager.duplicate(id)
    if CloneManager.getCount() >= MAX_CLONES then
        notify("Batas maksimal " .. MAX_CLONES .. " clone tercapai!", RED)
        return nil
    end
    local source = Registry.clones[id]
    if not source then return nil end

    local sourceHRP = source.model:FindFirstChild("HumanoidRootPart")
    local spawnCFrame = sourceHRP and (sourceHRP.CFrame * CFrame.new(2, 0, 0)) or (LocalPlayer.Character.HumanoidRootPart.CFrame)

    local newId = CloneManager.create()
    if not newId then return nil end
    local newEntry = Registry.clones[newId]
    if newEntry and newEntry.model then
        local newHRP = newEntry.model:FindFirstChild("HumanoidRootPart")
        if newHRP then newHRP.CFrame = spawnCFrame end
        newEntry.data.position = spawnCFrame.Position
        CloneManager.rename(newId, source.data.name .. " Copy")
    end
    return newId
end

-- ==================== MOVEMENT ====================
-- Semua pergerakan clone bersifat sekali-tembak (set CFrame langsung),
-- BUKAN RenderStepped per-clone — sesuai requirement performa.
local Movement = {}

function Movement.move(id, direction, distance)
    local entry = Registry.clones[id]
    if not entry or not entry.model or entry.data.locked then return end
    local hrp = entry.model:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    distance = distance or DEFAULT_MOVE_DISTANCE
    local offset

    if direction == "forward" then offset = Vector3.new(0, 0, -distance)
    elseif direction == "backward" then offset = Vector3.new(0, 0, distance)
    elseif direction == "left" then offset = Vector3.new(-distance, 0, 0)
    elseif direction == "right" then offset = Vector3.new(distance, 0, 0)
    elseif direction == "up" then offset = Vector3.new(0, distance, 0)
    elseif direction == "down" then offset = Vector3.new(0, -distance, 0)
    else return end

    local wasAnchored = hrp.Anchored
    hrp.Anchored = true -- pastikan tetap diam, tidak jatuh krn gravitasi
    hrp.CFrame = hrp.CFrame * CFrame.new(offset)
    entry.data.position = hrp.Position
end

function Movement.moveAxis(id, axis, delta)
    local entry = Registry.clones[id]
    if not entry or not entry.model or entry.data.locked then return end
    local hrp = entry.model:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local pos = hrp.Position
    if axis == "x" then pos = Vector3.new(pos.X + delta, pos.Y, pos.Z)
    elseif axis == "y" then pos = Vector3.new(pos.X, pos.Y + delta, pos.Z)
    elseif axis == "z" then pos = Vector3.new(pos.X, pos.Y, pos.Z + delta)
    else return end

    hrp.CFrame = CFrame.new(pos) * (hrp.CFrame - hrp.CFrame.Position)
    entry.data.position = pos
end

function Movement.resetPosition(id)
    local entry = Registry.clones[id]
    if not entry or not entry.model then return end
    local hrp = entry.model:FindFirstChild("HumanoidRootPart")
    local character = LocalPlayer.Character
    local playerHRP = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp or not playerHRP then return end

    local spawnCFrame = playerHRP.CFrame * CFrame.new(0, 0, -4)
    hrp.CFrame = spawnCFrame
    entry.data.position = spawnCFrame.Position
    notify("Posisi clone direset", PURPLE)
end

-- ==================== ROTATION ====================
local Rotation = {}

function Rotation.rotate(id, degrees)
    local entry = Registry.clones[id]
    if not entry or not entry.model or entry.data.locked then return end
    local hrp = entry.model:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(degrees), 0)
    local _, y = hrp.CFrame:ToOrientation()
    entry.data.rotationY = math.deg(y)
end

function Rotation.resetRotation(id)
    local entry = Registry.clones[id]
    if not entry or not entry.model then return end
    local hrp = entry.model:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    hrp.CFrame = CFrame.new(hrp.Position) -- hadap default (0 derajat)
    entry.data.rotationY = 0
    notify("Rotasi clone direset", PURPLE)
end

-- ==================== EMOTE SYSTEM ====================
-- PENTING: fungsi ini HANYA memainkan animasi pada humanoid milik clone.
-- Tidak pernah menyentuh LocalPlayer.Character atau LocalPlayer.Humanoid,
-- sehingga emote LocalPlayer sendiri tidak pernah ikut berubah.
local CloneEmote = {}

-- Cache emote milik LocalPlayer (dipakai untuk daftar "All"), memakai
-- _G.EmoteCache dari Emote.lua kalau sudah pernah di-load supaya tidak
-- fetch ulang dan konsisten dengan app Emote yang sudah ada.
local function getAvailableEmotes()
    if _G.EmoteCache and _G.EmoteCache.emotes and #_G.EmoteCache.emotes > 0 then
        return _G.EmoteCache.emotes
    end
    return {}
end

local recentEmotesKey = "cloneRecentEmotes"
local function getRecentEmotes()
    if Storage and Storage.appSettings and Storage.appSettings[recentEmotesKey] then
        return Storage.appSettings[recentEmotesKey]
    end
    return {}
end
local function pushRecentEmote(emoteId, emoteName)
    if not Storage or not Storage.appSettings then return end
    local recents = getRecentEmotes()
    -- Hapus duplikat lama
    for i = #recents, 1, -1 do
        if recents[i].id == emoteId then table.remove(recents, i) end
    end
    table.insert(recents, 1, {id = emoteId, name = emoteName})
    while #recents > 10 do table.remove(recents, #recents) end
    Storage.appSettings[recentEmotesKey] = recents
    pcall(function() if Storage.persistSettings then Storage.persistSettings() end end)
end

function CloneEmote.play(id, assetId, emoteName, loop)
    local entry = Registry.clones[id]
    if not entry or not entry.humanoid then return end

    -- Hentikan emote sebelumnya milik clone ini saja
    if entry.animTrack then
        pcall(function() entry.animTrack:Stop() end)
        entry.animTrack = nil
    end

    local track = nil
    local ok = pcall(function()
        track = entry.humanoid:PlayEmoteAndGetAnimTrackById(assetId)
    end)
    if not ok or not track then
        -- Fallback: coba lewat HumanoidDescription clone (bukan LocalPlayer)
        local desc = entry.humanoid:FindFirstChildOfClass("HumanoidDescription")
        if desc then
            pcall(function()
                desc:AddEmote("CloneEmote_" .. assetId, assetId)
                track = entry.humanoid:PlayEmoteAndGetAnimTrackById(assetId)
            end)
        end
    end

    if track then
        entry.animTrack = track
        track.Looped = loop or false
        track:Play()
        entry.data.currentEmote = emoteName or ("Emote " .. tostring(assetId))
        entry.data.emoteLooping = loop or false
        pushRecentEmote(assetId, entry.data.currentEmote)
        notify("Playing: " .. entry.data.currentEmote, PURPLE)
    else
        notify("Gagal memainkan emote", RED)
    end
end

function CloneEmote.stop(id)
    local entry = Registry.clones[id]
    if not entry then return end
    if entry.animTrack then
        pcall(function() entry.animTrack:Stop() end)
        entry.animTrack = nil
    end
    entry.data.currentEmote = nil
    entry.data.emoteLooping = false
end

-- ==================== FOLLOW SYSTEM ====================
-- Satu Heartbeat loop TERPUSAT untuk seluruh clone (bukan per-clone),
-- sesuai requirement performa. Loop ini hanya berjalan tiap FOLLOW_UPDATE_HZ
-- detik dan hanya memproses clone yang followEnabled = true.
local Follow = {}
local followLoopConnection = nil
local followAccum = 0

local function anyCloneFollowing()
    for _, id in ipairs(Registry.order) do
        local e = Registry.clones[id]
        if e and e.data.followEnabled then return true end
    end
    return false
end

local function ensureFollowLoop()
    if followLoopConnection then return end
    followLoopConnection = RunService.Heartbeat:Connect(function(dt)
        followAccum = followAccum + dt
        if followAccum < FOLLOW_UPDATE_HZ then return end
        followAccum = 0

        if not anyCloneFollowing() then
            followLoopConnection:Disconnect()
            followLoopConnection = nil
            return
        end

        for _, id in ipairs(Registry.order) do
            local entry = Registry.clones[id]
            if entry and entry.data.followEnabled and entry.data.followTarget then
                local target = entry.data.followTarget
                if not target.Parent then
                    -- Target sudah leave game
                    entry.data.followEnabled = false
                    entry.data.followTarget = nil
                else
                    local targetChar = target.Character
                    local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                    local hrp = entry.model and entry.model:FindFirstChild("HumanoidRootPart")
                    if targetHRP and hrp then
                        local mode = entry.data.followMode
                        local dist = entry.data.followDistance or 3

                        local goalPos = hrp.Position
                        local goalRot = nil

                        if mode == "position" or mode == "both" then
                            local behind = targetHRP.CFrame.LookVector * -dist
                            goalPos = targetHRP.Position + behind + Vector3.new(0, 0, 0)
                        end
                        if mode == "rotation" or mode == "both" then
                            local _, ry = targetHRP.CFrame:ToOrientation()
                            goalRot = ry
                        end

                        local goalCFrame
                        if goalRot then
                            goalCFrame = CFrame.new(goalPos) * CFrame.Angles(0, goalRot, 0)
                        else
                            goalCFrame = CFrame.new(goalPos) * (hrp.CFrame - hrp.CFrame.Position)
                        end

                        -- Interpolasi ringan supaya gerakan tidak patah-patah,
                        -- memakai Lerp per-update alih-alih Tween baru tiap frame
                        -- (jauh lebih murah, tidak spam TweenService).
                        hrp.CFrame = hrp.CFrame:Lerp(goalCFrame, 0.35)
                        entry.data.position = hrp.Position
                        local _, finalY = hrp.CFrame:ToOrientation()
                        entry.data.rotationY = math.deg(finalY)
                    end
                end
            end
        end
    end)
end

function Follow.setTarget(id, targetPlayer)
    local entry = Registry.clones[id]
    if not entry then return end
    entry.data.followTarget = targetPlayer
    notify("Follow Target: @" .. targetPlayer.Name, PURPLE)
end

function Follow.setMode(id, mode)
    local entry = Registry.clones[id]
    if not entry then return end
    entry.data.followMode = mode
end

function Follow.setDistance(id, distance)
    local entry = Registry.clones[id]
    if not entry then return end
    entry.data.followDistance = distance
end

function Follow.enable(id)
    local entry = Registry.clones[id]
    if not entry or not entry.data.followTarget then
        notify("Pilih target follow dulu!", RED)
        return
    end
    entry.data.followEnabled = true
    local hrp = entry.model and entry.model:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.Anchored = true end -- tetap Anchored, kita set CFrame manual (bukan physics)
    ensureFollowLoop()
    notify("Follow ON", GREEN)
end

function Follow.disable(id)
    local entry = Registry.clones[id]
    if not entry then return end
    entry.data.followEnabled = false
    notify("Follow OFF", RED)
end

-- ==================== ITEM SYSTEM ====================
-- PENTING: Tool asli LocalPlayer TIDAK PERNAH dipindahkan/di-reparent.
-- Yang dibuat adalah representasi visual (Handle di-Clone lalu di-weld
-- ke tangan kanan clone) sehingga inventory & Tool asli tetap utuh.
local CloneItem = {}

local function getHeldTool()
    local character = LocalPlayer.Character
    if not character then return nil end
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then return child end
    end
    return nil
end

function CloneItem.give(id)
    local entry = Registry.clones[id]
    if not entry or not entry.model then return end

    local tool = getHeldTool()
    if not tool then
        notify("LocalPlayer tidak sedang memegang item!", RED)
        return
    end
    local handle = tool:FindFirstChild("Handle")
    if not handle or not handle:IsA("BasePart") then
        notify("Item tidak punya Handle, tidak bisa direpresentasikan", RED)
        return
    end

    -- Bersihkan representasi item lama (kalau ada) sebelum pasang baru.
    if entry.heldTool then
        pcall(function() entry.heldTool:Destroy() end)
        entry.heldTool = nil
    end

    local rightHand = entry.model:FindFirstChild("RightHand") or entry.model:FindFirstChild("Right Arm")
    if not rightHand then
        notify("Clone tidak punya tangan kanan untuk memegang item", RED)
        return
    end

    -- Clone hanya Handle-nya (visual saja), bukan seluruh Tool dengan
    -- scriptnya — jadi tidak ada resiko memicu behavior Tool asli.
    local visualHandle = handle:Clone()
    visualHandle.Name = "CloneHeldItem"
    visualHandle.CanCollide = false
    visualHandle.Anchored = false
    visualHandle.Massless = true

    -- Buang script apa pun yang ikut ter-clone dari Handle (mis. jika
    -- Handle punya child script) supaya representasi ini murni visual.
    for _, d in ipairs(visualHandle:GetDescendants()) do
        if d:IsA("Script") or d:IsA("LocalScript") then d:Destroy() end
    end

    visualHandle.Parent = entry.model

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = rightHand
    weld.Part1 = visualHandle
    weld.Parent = visualHandle
    visualHandle.CFrame = rightHand.CFrame * CFrame.new(0, -0.6, 0)

    entry.heldTool = visualHandle
    entry.data.heldItemName = tool.Name
    notify("Item diberikan ke clone: " .. tool.Name, GREEN)
end

function CloneItem.remove(id)
    local entry = Registry.clones[id]
    if not entry then return end
    if entry.heldTool then
        pcall(function() entry.heldTool:Destroy() end)
        entry.heldTool = nil
    end
    entry.data.heldItemName = nil
    notify("Item dilepas dari clone", PURPLE)
end

function CloneItem.drop(id)
    -- "Drop" secara visual: lepas weld, biarkan jatuh sebentar lalu hapus.
    local entry = Registry.clones[id]
    if not entry or not entry.heldTool then return end
    local dropped = entry.heldTool
    entry.heldTool = nil
    entry.data.heldItemName = nil

    local weld = dropped:FindFirstChildOfClass("WeldConstraint")
    if weld then weld:Destroy() end
    dropped.Anchored = false
    dropped.CanCollide = true

    task.delay(3, function()
        if dropped and dropped.Parent then dropped:Destroy() end
    end)
    notify("Item dijatuhkan", PURPLE)
end

function CloneItem.replace(id)
    -- Replace = remove lalu give ulang dengan item yang sedang dipegang saat ini.
    CloneItem.remove(id)
    CloneItem.give(id)
end

-- ==================== CHAT SYSTEM ====================
-- Chat bubble murni visual (BillboardGui di atas nametag clone). TIDAK
-- mengirim pesan sebagai LocalPlayer/akun asli — jelas berasal dari clone.
local CloneChat = {}
local CHAT_BUBBLE_DURATION = 4

function CloneChat.send(id, text)
    local entry = Registry.clones[id]
    if not entry or not entry.model then return end
    text = text:sub(1, 120)
    if text:gsub("%s", "") == "" then return end

    table.insert(entry.data.chatHistory, {text = text, timestamp = os.time()})
    while #entry.data.chatHistory > 30 do table.remove(entry.data.chatHistory, 1) end

    local head = entry.model:FindFirstChild("Head")
    if not head then return end

    -- Bersihkan bubble lama biar tidak menumpuk
    local old = head:FindFirstChild("CloneChatBubble")
    if old then old:Destroy() end

    local bubble = Instance.new("BillboardGui")
    bubble.Name = "CloneChatBubble"
    bubble.Size = UDim2.new(0, 180, 0, 50)
    bubble.StudsOffset = Vector3.new(0, 2.1, 0)
    bubble.AlwaysOnTop = true
    bubble.Parent = head

    local bg = Instance.new("Frame", bubble)
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = WHITE
    bg.BackgroundTransparency = 0.05
    Helpers.corner(bg, 12)
    Helpers.stroke(bg, PURPLE_SOFT, 1, 0.2)

    local senderLbl = Instance.new("TextLabel", bg)
    senderLbl.Size = UDim2.new(1, -10, 0, 16)
    senderLbl.Position = UDim2.new(0, 5, 0, 3)
    senderLbl.BackgroundTransparency = 1
    senderLbl.Text = "\"" .. entry.data.name .. "\""
    senderLbl.TextColor3 = PURPLE
    senderLbl.Font = Enum.Font.GothamBold
    senderLbl.TextSize = 11
    senderLbl.TextXAlignment = Enum.TextXAlignment.Left

    local textLbl = Instance.new("TextLabel", bg)
    textLbl.Size = UDim2.new(1, -10, 1, -20)
    textLbl.Position = UDim2.new(0, 5, 0, 19)
    textLbl.BackgroundTransparency = 1
    textLbl.Text = text
    textLbl.TextColor3 = BLACK
    textLbl.Font = Enum.Font.Gotham
    textLbl.TextSize = 12
    textLbl.TextWrapped = true
    textLbl.TextXAlignment = Enum.TextXAlignment.Left
    textLbl.TextYAlignment = Enum.TextYAlignment.Top

    entry.chatBubble = bubble
    task.delay(CHAT_BUBBLE_DURATION, function()
        if bubble and bubble.Parent then bubble:Destroy() end
        if entry.chatBubble == bubble then entry.chatBubble = nil end
    end)
end

function CloneChat.clear(id)
    local entry = Registry.clones[id]
    if not entry then return end
    table.clear(entry.data.chatHistory)
    if entry.chatBubble then
        entry.chatBubble:Destroy()
        entry.chatBubble = nil
    end
end

-- ==================== UI HELPERS ====================
local function tween(obj, props, dur)
    if Helpers.tween then return Helpers.tween(obj, props, dur) end
    local tw = TweenService:Create(obj, TweenInfo.new(dur or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

local function corner(obj, radius)
    if Helpers.corner then return Helpers.corner(obj, radius) end
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = obj
    return c
end

local function stroke(obj, color, thick, transp)
    if Helpers.stroke then return Helpers.stroke(obj, color, thick, transp) end
    local s = Instance.new("UIStroke")
    s.Color = color or BLACK
    s.Thickness = thick or 1
    s.Transparency = transp or 0
    s.Parent = obj
    return s
end

local function pressFX(btn)
    if Helpers.pressFX then return Helpers.pressFX(btn) end
    btn.MouseButton1Down:Connect(function() tween(btn, {Size = btn.Size - UDim2.new(0,2,0,2)}, 0.08) end)
    btn.MouseButton1Up:Connect(function() tween(btn, {Size = btn.Size + UDim2.new(0,2,0,2)}, 0.08) end)
end

local function makeButton(parent, text, size, pos, bg, fg)
    local btn = Instance.new("TextButton", parent)
    btn.Size = size
    btn.Position = pos or UDim2.new(0, 0, 0, 0)
    btn.BackgroundColor3 = bg or ACCENT
    btn.Text = text
    btn.TextColor3 = fg or WHITE
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.AutoButtonColor = false
    corner(btn, 10)
    pressFX(btn)
    return btn
end

-- Panel/App state (mirip app lain: satu "screen" utama + panel controller)
local currentScreen = "manager" -- "manager" | "controller"
local managerScrollFrame = nil
local controllerContainer = nil

local function clearAppContent()
    if not appContent then return end
    for _, child in ipairs(appContent:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
end

local buildManagerScreen -- forward
local buildControllerScreen -- forward

-- ==================== CLONE MANAGER SCREEN ====================
local function createCloneListCard(parent, id, order)
    local entry = Registry.clones[id]
    if not entry then return end
    local data = entry.data

    local card = Instance.new("Frame", parent)
    card.Size = UDim2.new(1, 0, 0, 74)
    card.BackgroundColor3 = WHITE
    card.BorderSizePixel = 0
    card.LayoutOrder = order
    card.ClipsDescendants = true
    corner(card, 16)
    stroke(card, PURPLE_SOFT, 1, 0.35)

    -- Avatar preview (headshot LocalPlayer dipakai sebagai representasi
    -- cepat karena clone identik dengan appearance LocalPlayer)
    local avatarWrap = Instance.new("Frame", card)
    avatarWrap.Size = UDim2.new(0, 50, 0, 50)
    avatarWrap.Position = UDim2.new(0, 10, 0.5, -25)
    avatarWrap.AnchorPoint = Vector2.new(0, 0.5)
    avatarWrap.BackgroundColor3 = LIGHT_GRAY
    corner(avatarWrap, 25)
    stroke(avatarWrap, PURPLE_LIGHT, 1.5, 0.15)

    local avatar = Instance.new("ImageLabel", avatarWrap)
    avatar.Size = UDim2.new(1, 0, 1, 0)
    avatar.BackgroundTransparency = 1
    avatar.ScaleType = Enum.ScaleType.Crop
    corner(avatar, 25)
    pcall(function()
        avatar.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)

    local infoFrame = Instance.new("Frame", card)
    infoFrame.Size = UDim2.new(1, -160, 1, -16)
    infoFrame.Position = UDim2.new(0, 70, 0, 8)
    infoFrame.BackgroundTransparency = 1

    local nameLabel = Instance.new("TextLabel", infoFrame)
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0, 22)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = data.name
    nameLabel.TextColor3 = BLACK
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left

    local statusLabel = Instance.new("TextLabel", infoFrame)
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, 0, 0, 18)
    statusLabel.Position = UDim2.new(0, 0, 0, 22)
    statusLabel.BackgroundTransparency = 1
    local statusText = data.currentEmote and ("● Playing: " .. data.currentEmote)
        or (data.followEnabled and ("● Following @" .. (data.followTarget and data.followTarget.Name or "?")) or "● Idle")
    statusLabel.Text = statusText
    statusLabel.TextColor3 = (data.currentEmote or data.followEnabled) and GREEN or DARK_GRAY
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 10
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left

    local selectBtn = makeButton(card, "SELECT", UDim2.new(0, 66, 0, 30), UDim2.new(1, -148, 0.5, -15), ACCENT, WHITE)
    selectBtn.TextSize = 11
    local gradient1 = Instance.new("UIGradient", selectBtn)
    gradient1.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(50,34,75)), ColorSequenceKeypoint.new(1, ACCENT)}
    gradient1.Rotation = 90
    selectBtn.MouseButton1Click:Connect(function()
        Registry.selectedId = id
        openClonePanel(id)
    end)

    local delBtn = makeButton(card, "DEL", UDim2.new(0, 66, 0, 30), UDim2.new(1, -76, 0.5, -15), WHITE, RED)
    delBtn.TextSize = 11
    stroke(delBtn, RED, 1, 0.5)
    delBtn.MouseButton1Click:Connect(function()
        CloneManager.delete(id)
    end)

    return card
end

refreshCloneListUI = function()
    if not managerScrollFrame or not managerScrollFrame.Parent then return end
    for _, c in ipairs(managerScrollFrame:GetChildren()) do
        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
    end

    local ids = Registry.order
    if #ids == 0 then
        local emptyLbl = Instance.new("TextLabel", managerScrollFrame)
        emptyLbl.Size = UDim2.new(1, 0, 0, 80)
        emptyLbl.BackgroundTransparency = 1
        emptyLbl.Text = "Belum ada clone.\nTekan + CREATE CLONE untuk mulai."
        emptyLbl.TextColor3 = DARK_GRAY
        emptyLbl.Font = Enum.Font.Gotham
        emptyLbl.TextSize = 12
        emptyLbl.TextWrapped = true
    else
        for i, id in ipairs(ids) do
            createCloneListCard(managerScrollFrame, id, i)
        end
    end
end

buildManagerScreen = function()
    currentScreen = "manager"
    clearAppContent()

    -- Header
    local header = Instance.new("Frame", appContent)
    header.Size = UDim2.new(1, 0, 0, 46)
    header.BackgroundTransparency = 1
    header.LayoutOrder = 1

    local titleLbl = Instance.new("TextLabel", header)
    titleLbl.Size = UDim2.new(1, 0, 0, 26)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "CLONE ✨"
    titleLbl.TextColor3 = BLACK
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 20
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left

    local subtitleLbl = Instance.new("TextLabel", header)
    subtitleLbl.Size = UDim2.new(1, 0, 0, 18)
    subtitleLbl.Position = UDim2.new(0, 0, 0, 26)
    subtitleLbl.BackgroundTransparency = 1
    subtitleLbl.Text = "Manage your clones (" .. CloneManager.getCount() .. "/" .. MAX_CLONES .. ")"
    subtitleLbl.TextColor3 = DARK_GRAY
    subtitleLbl.Font = Enum.Font.Gotham
    subtitleLbl.TextSize = 12
    subtitleLbl.TextXAlignment = Enum.TextXAlignment.Left

    -- Create Clone button
    local createBtn = makeButton(appContent, "+  CREATE CLONE", UDim2.new(1, 0, 0, 44), nil, PURPLE, WHITE)
    createBtn.LayoutOrder = 2
    createBtn.TextSize = 14
    corner(createBtn, 14)
    local cGrad = Instance.new("UIGradient", createBtn)
    cGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, PURPLE_LIGHT), ColorSequenceKeypoint.new(1, PURPLE)}
    cGrad.Rotation = 0
    createBtn.MouseButton1Click:Connect(function()
        CloneManager.create()
        subtitleLbl.Text = "Manage your clones (" .. CloneManager.getCount() .. "/" .. MAX_CLONES .. ")"
    end)

    -- Section label
    local sectionLbl = Instance.new("TextLabel", appContent)
    sectionLbl.Size = UDim2.new(1, 0, 0, 24)
    sectionLbl.BackgroundTransparency = 1
    sectionLbl.Text = "MY CLONES"
    sectionLbl.TextColor3 = DARK_GRAY
    sectionLbl.Font = Enum.Font.GothamBold
    sectionLbl.TextSize = 12
    sectionLbl.TextXAlignment = Enum.TextXAlignment.Left
    sectionLbl.LayoutOrder = 3

    -- Delete All button (kecil, di samping section label secara visual lewat layout terpisah)
    local deleteAllBtn = makeButton(appContent, "DELETE ALL CLONES", UDim2.new(1, 0, 0, 34), nil, WHITE, RED)
    deleteAllBtn.LayoutOrder = 4
    deleteAllBtn.TextSize = 12
    stroke(deleteAllBtn, RED, 1, 0.5)
    deleteAllBtn.MouseButton1Click:Connect(function()
        CloneManager.deleteAll()
        subtitleLbl.Text = "Manage your clones (" .. CloneManager.getCount() .. "/" .. MAX_CLONES .. ")"
    end)

    -- Preset row (Save/Load formasi seluruh clone)
    local presetWrap = Instance.new("Frame", appContent)
    presetWrap.Size = UDim2.new(1, 0, 0, 34)
    presetWrap.BackgroundTransparency = 1
    presetWrap.LayoutOrder = 5

    local presetBox = Instance.new("TextBox", presetWrap)
    presetBox.Size = UDim2.new(1, -140, 1, 0)
    presetBox.BackgroundColor3 = LIGHT_GRAY
    presetBox.PlaceholderText = "Preset name (e.g. Formation)"
    presetBox.PlaceholderColor3 = DARK_GRAY
    presetBox.TextColor3 = BLACK
    presetBox.Font = Enum.Font.Gotham
    presetBox.TextSize = 11
    presetBox.TextXAlignment = Enum.TextXAlignment.Left
    presetBox.TextYAlignment = Enum.TextYAlignment.Center
    presetBox.ClearTextOnFocus = false
    corner(presetBox, 10)
    stroke(presetBox, PURPLE_SOFT, 1, 0.3)
    local presetPad = Instance.new("UIPadding", presetBox)
    presetPad.PaddingLeft = UDim.new(0, 8)

    local savePresetBtn = makeButton(presetWrap, "SAVE", UDim2.new(0, 66, 1, 0), UDim2.new(1, -136, 0, 0), PURPLE, WHITE)
    savePresetBtn.TextSize = 10
    savePresetBtn.MouseButton1Click:Connect(function()
        CloneManager.savePreset(presetBox.Text)
    end)

    local loadPresetBtn = makeButton(presetWrap, "LOAD", UDim2.new(0, 66, 1, 0), UDim2.new(1, -66, 0, 0), LIGHT_GRAY, BLACK)
    loadPresetBtn.TextSize = 10
    stroke(loadPresetBtn, PURPLE_SOFT, 1, 0.3)
    loadPresetBtn.MouseButton1Click:Connect(function()
        if presetBox.Text:gsub("%s","") ~= "" then
            CloneManager.loadPreset(presetBox.Text)
        end
    end)

    -- Scroll list
    managerScrollFrame = Instance.new("ScrollingFrame", appContent)
    managerScrollFrame.Size = UDim2.new(1, 0, 1, -224)
    managerScrollFrame.BackgroundTransparency = 1
    managerScrollFrame.BorderSizePixel = 0
    managerScrollFrame.ScrollBarThickness = 2
    managerScrollFrame.ScrollBarImageColor3 = PURPLE
    managerScrollFrame.LayoutOrder = 6
    managerScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    managerScrollFrame.CanvasSize = UDim2.new(0,0,0,0)

    local listLayout = Instance.new("UIListLayout", managerScrollFrame)
    listLayout.Padding = UDim.new(0, 8)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    refreshCloneListUI()
end

-- ==================== CLONE CONTROLLER SCREEN ====================
-- Sub-section builders dipisah supaya buildControllerScreen tidak jadi
-- satu fungsi raksasa. Masing-masing menerima `parent` (appContent) dan
-- `id` (clone id) lalu me-return frame section-nya.

local function sectionHeader(parent, text, order)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = DARK_GRAY
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order
    return lbl
end

-- --- Header dengan nama clone + status + tombol kembali ke manager ---
local function buildControllerHeader(parent, id, order)
    local entry = Registry.clones[id]
    local wrap = Instance.new("Frame", parent)
    wrap.Size = UDim2.new(1, 0, 0, 60)
    wrap.BackgroundTransparency = 1
    wrap.LayoutOrder = order

    local backBtn = makeButton(wrap, "‹", UDim2.new(0, 34, 0, 34), UDim2.new(0, 0, 0, 0), LIGHT_GRAY, PURPLE)
    backBtn.TextSize = 18
    corner(backBtn, 12)
    backBtn.MouseButton1Click:Connect(function()
        buildManagerScreen()
    end)

    local nameLbl = Instance.new("TextLabel", wrap)
    nameLbl.Size = UDim2.new(1, -44, 0, 24)
    nameLbl.Position = UDim2.new(0, 44, 0, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = entry.data.name
    nameLbl.TextColor3 = BLACK
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 17
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left

    local statusLbl = Instance.new("TextLabel", wrap)
    statusLbl.Name = "ControllerStatus"
    statusLbl.Size = UDim2.new(1, -44, 0, 18)
    statusLbl.Position = UDim2.new(0, 44, 0, 26)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text = "● Idle"
    statusLbl.TextColor3 = GREEN
    statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextSize = 11
    statusLbl.TextXAlignment = Enum.TextXAlignment.Left

    local delBtn = makeButton(wrap, "DELETE", UDim2.new(0, 70, 0, 30), UDim2.new(1, -70, 0, 2), WHITE, RED)
    delBtn.TextSize = 11
    stroke(delBtn, RED, 1, 0.4)
    delBtn.MouseButton1Click:Connect(function()
        CloneManager.delete(id)
        buildManagerScreen()
    end)

    return wrap, statusLbl
end

-- --- MOVE + ROTATE controller ---
local function buildMoveRotateSection(parent, id, order)
    local entry = Registry.clones[id]
    local section = Instance.new("Frame", parent)
    section.Size = UDim2.new(1, 0, 0, 230)
    section.BackgroundColor3 = WHITE
    section.LayoutOrder = order
    corner(section, 16)
    stroke(section, PURPLE_SOFT, 1, 0.3)

    local pad = Instance.new("UIPadding", section)
    pad.PaddingTop = UDim.new(0, 10)
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)

    local title = Instance.new("TextLabel", section)
    title.Size = UDim2.new(1, 0, 0, 18)
    title.BackgroundTransparency = 1
    title.Text = "POSITION"
    title.TextColor3 = DARK_GRAY
    title.Font = Enum.Font.GothamBold
    title.TextSize = 11
    title.TextXAlignment = Enum.TextXAlignment.Left

    -- Koordinat live
    local coordLbl = Instance.new("TextLabel", section)
    coordLbl.Name = "CoordLbl"
    coordLbl.Size = UDim2.new(1, 0, 0, 16)
    coordLbl.Position = UDim2.new(0, 0, 0, 18)
    coordLbl.BackgroundTransparency = 1
    coordLbl.Font = Enum.Font.Code
    coordLbl.TextSize = 10
    coordLbl.TextColor3 = PURPLE
    coordLbl.TextXAlignment = Enum.TextXAlignment.Left

    local function refreshCoord()
        local p = entry.data.position
        coordLbl.Text = string.format("X: %.2f   Y: %.2f   Z: %.2f   |   Rot: %.0f°", p.X, p.Y, p.Z, entry.data.rotationY)
    end
    refreshCoord()

    -- Move distance value shown + slider-like +/- stepper (mobile friendly,
    -- lebih reliable daripada drag-slider di UI kecil)
    local distanceOptions = {0.5, 1, 2, 5, 10}
    local distanceIndex = 3 -- default 2
    local moveDistance = distanceOptions[distanceIndex]

    -- D-Pad
    local padWrap = Instance.new("Frame", section)
    padWrap.Size = UDim2.new(0, 130, 0, 130)
    padWrap.Position = UDim2.new(0, 0, 0, 42)
    padWrap.BackgroundTransparency = 1

    local function dpadBtn(text, x, y)
        local b = makeButton(padWrap, text, UDim2.new(0, 40, 0, 40), UDim2.new(0, x, 0, y), ACCENT, WHITE)
        b.TextSize = 16
        corner(b, 12)
        return b
    end

    local btnUp = dpadBtn("▲", 45, 0)
    local btnLeft = dpadBtn("◀", 0, 45)
    local btnCenter = dpadBtn("●", 45, 45)
    btnCenter.BackgroundColor3 = PURPLE_SOFT
    btnCenter.TextColor3 = PURPLE
    local btnRight = dpadBtn("▶", 90, 45)
    local btnDown = dpadBtn("▼", 45, 90)

    btnUp.MouseButton1Click:Connect(function() Movement.move(id, "forward", moveDistance); refreshCoord() end)
    btnDown.MouseButton1Click:Connect(function() Movement.move(id, "backward", moveDistance); refreshCoord() end)
    btnLeft.MouseButton1Click:Connect(function() Movement.move(id, "left", moveDistance); refreshCoord() end)
    btnRight.MouseButton1Click:Connect(function() Movement.move(id, "right", moveDistance); refreshCoord() end)
    btnCenter.MouseButton1Click:Connect(function()
        Movement.resetPosition(id)
        refreshCoord()
    end)

    -- UP / DOWN (vertical) + distance stepper, di kanan D-Pad
    local vertWrap = Instance.new("Frame", section)
    vertWrap.Size = UDim2.new(1, -140, 0, 130)
    vertWrap.Position = UDim2.new(0, 140, 0, 42)
    vertWrap.BackgroundTransparency = 1

    local upBtn = makeButton(vertWrap, "UP ▲", UDim2.new(1, 0, 0, 30), UDim2.new(0,0,0,0), LIGHT_GRAY, BLACK)
    upBtn.TextSize = 11
    stroke(upBtn, PURPLE_SOFT, 1, 0.3)
    upBtn.MouseButton1Click:Connect(function() Movement.move(id, "up", moveDistance); refreshCoord() end)

    local downBtn = makeButton(vertWrap, "DOWN ▼", UDim2.new(1, 0, 0, 30), UDim2.new(0,0,0,36), LIGHT_GRAY, BLACK)
    downBtn.TextSize = 11
    stroke(downBtn, PURPLE_SOFT, 1, 0.3)
    downBtn.MouseButton1Click:Connect(function() Movement.move(id, "down", moveDistance); refreshCoord() end)

    -- Distance stepper label + < >
    local distLbl = Instance.new("TextLabel", vertWrap)
    distLbl.Size = UDim2.new(1, 0, 0, 16)
    distLbl.Position = UDim2.new(0, 0, 0, 74)
    distLbl.BackgroundTransparency = 1
    distLbl.Text = "Move Distance: " .. tostring(moveDistance)
    distLbl.TextColor3 = DARK_GRAY
    distLbl.Font = Enum.Font.Gotham
    distLbl.TextSize = 10
    distLbl.TextXAlignment = Enum.TextXAlignment.Left

    local distMinus = makeButton(vertWrap, "-", UDim2.new(0, 30, 0, 26), UDim2.new(0, 0, 0, 94), LIGHT_GRAY, BLACK)
    stroke(distMinus, PURPLE_SOFT, 1, 0.3)
    local distPlus = makeButton(vertWrap, "+", UDim2.new(0, 30, 0, 26), UDim2.new(0, 36, 0, 94), LIGHT_GRAY, BLACK)
    stroke(distPlus, PURPLE_SOFT, 1, 0.3)

    distMinus.MouseButton1Click:Connect(function()
        distanceIndex = math.max(1, distanceIndex - 1)
        moveDistance = distanceOptions[distanceIndex]
        distLbl.Text = "Move Distance: " .. tostring(moveDistance)
    end)
    distPlus.MouseButton1Click:Connect(function()
        distanceIndex = math.min(#distanceOptions, distanceIndex + 1)
        moveDistance = distanceOptions[distanceIndex]
        distLbl.Text = "Move Distance: " .. tostring(moveDistance)
    end)

    -- Rotation row
    local rotWrap = Instance.new("Frame", section)
    rotWrap.Size = UDim2.new(1, 0, 0, 40)
    rotWrap.Position = UDim2.new(0, 0, 0, 182)
    rotWrap.BackgroundTransparency = 1

    local rotLeft = makeButton(rotWrap, "↶ Rotate", UDim2.new(0.48, 0, 1, 0), UDim2.new(0,0,0,0), ACCENT, WHITE)
    rotLeft.TextSize = 12
    local rotRight = makeButton(rotWrap, "Rotate ↷", UDim2.new(0.48, 0, 1, 0), UDim2.new(0.52,0,0,0), ACCENT, WHITE)
    rotRight.TextSize = 12

    local rotateStep = DEFAULT_ROTATE_STEP
    rotLeft.MouseButton1Click:Connect(function() Rotation.rotate(id, -rotateStep); refreshCoord() end)
    rotRight.MouseButton1Click:Connect(function() Rotation.rotate(id, rotateStep); refreshCoord() end)

    return section, refreshCoord
end

-- --- FREE POSITION MODE (X+/X-/Y+/Y-/Z+/Z- presisi + reset) ---
local function buildFreePositionSection(parent, id, order)
    local entry = Registry.clones[id]
    local section = Instance.new("Frame", parent)
    section.Size = UDim2.new(1, 0, 0, 150)
    section.BackgroundColor3 = WHITE
    section.LayoutOrder = order
    corner(section, 16)
    stroke(section, PURPLE_SOFT, 1, 0.3)

    local pad = Instance.new("UIPadding", section)
    pad.PaddingTop = UDim.new(0, 10)
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)

    local title = Instance.new("TextLabel", section)
    title.Size = UDim2.new(1, -90, 0, 18)
    title.BackgroundTransparency = 1
    title.Text = "FREE POSITION MODE"
    title.TextColor3 = DARK_GRAY
    title.Font = Enum.Font.GothamBold
    title.TextSize = 11
    title.TextXAlignment = Enum.TextXAlignment.Left

    local coordLbl = Instance.new("TextLabel", section)
    coordLbl.Size = UDim2.new(1, 0, 0, 16)
    coordLbl.Position = UDim2.new(0, 0, 0, 18)
    coordLbl.BackgroundTransparency = 1
    coordLbl.Font = Enum.Font.Code
    coordLbl.TextSize = 10
    coordLbl.TextColor3 = PURPLE
    coordLbl.TextXAlignment = Enum.TextXAlignment.Left

    local function refreshFreeCoord()
        local p = entry.data.position
        coordLbl.Text = string.format("X: %.2f   Y: %.2f   Z: %.2f", p.X, p.Y, p.Z)
    end
    refreshFreeCoord()

    local step = 0.5

    local axisRow = Instance.new("Frame", section)
    axisRow.Size = UDim2.new(1, 0, 0, 34)
    axisRow.Position = UDim2.new(0, 0, 0, 38)
    axisRow.BackgroundTransparency = 1
    local axisLayout = Instance.new("UIListLayout", axisRow)
    axisLayout.FillDirection = Enum.FillDirection.Horizontal
    axisLayout.Padding = UDim.new(0, 4)

    local function axisBtn(label, axis, delta)
        local b = makeButton(axisRow, label, UDim2.new(0, 0, 1, 0), nil, LIGHT_GRAY, BLACK)
        b.Size = UDim2.new(1/6, -3, 1, 0)
        b.TextSize = 11
        stroke(b, PURPLE_SOFT, 1, 0.3)
        b.MouseButton1Click:Connect(function()
            Movement.moveAxis(id, axis, delta)
            refreshFreeCoord()
        end)
        return b
    end

    axisBtn("X+", "x", step)
    axisBtn("X-", "x", -step)
    axisBtn("Y+", "y", step)
    axisBtn("Y-", "y", -step)
    axisBtn("Z+", "z", step)
    axisBtn("Z-", "z", -step)

    local resetBtn = makeButton(section, "RESET POSITION", UDim2.new(1, 0, 0, 32), UDim2.new(0, 0, 0, 80), WHITE, RED)
    resetBtn.TextSize = 11
    stroke(resetBtn, RED, 1, 0.5)
    resetBtn.MouseButton1Click:Connect(function()
        Movement.resetPosition(id)
        refreshFreeCoord()
    end)

    return section, refreshFreeCoord
end

-- --- Rotation preset row (15°/45°/90°/180° + step slider-stepper) ---
local function buildRotationPresetSection(parent, id, order)
    local section = Instance.new("Frame", parent)
    section.Size = UDim2.new(1, 0, 0, 50)
    section.BackgroundTransparency = 1
    section.LayoutOrder = order

    local layout = Instance.new("UIListLayout", section)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local presets = {15, 45, 90, 180}
    for i, deg in ipairs(presets) do
        local btn = makeButton(section, deg .. "°", UDim2.new(0, 0, 1, 0), nil, LIGHT_GRAY, BLACK)
        btn.Size = UDim2.new(0.24, -5, 1, 0)
        btn.TextSize = 12
        btn.LayoutOrder = i
        stroke(btn, PURPLE_SOFT, 1, 0.3)
        btn.MouseButton1Click:Connect(function()
            Rotation.rotate(id, deg)
        end)
    end

    return section
end

-- --- EMOTE section (search, All/Favorites/Recently Used tabs, play/stop) ---
local function buildEmoteSection(parent, id, order)
    local entry = Registry.clones[id]
    local section = Instance.new("Frame", parent)
    section.Size = UDim2.new(1, 0, 0, 250)
    section.BackgroundColor3 = WHITE
    section.LayoutOrder = order
    section.ClipsDescendants = true
    corner(section, 16)
    stroke(section, PURPLE_SOFT, 1, 0.3)

    local pad = Instance.new("UIPadding", section)
    pad.PaddingTop = UDim.new(0, 10)
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)

    local title = Instance.new("TextLabel", section)
    title.Size = UDim2.new(1, 0, 0, 18)
    title.BackgroundTransparency = 1
    title.Text = "EMOTE"
    title.TextColor3 = DARK_GRAY
    title.Font = Enum.Font.GothamBold
    title.TextSize = 11
    title.TextXAlignment = Enum.TextXAlignment.Left

    -- Now playing status
    local nowPlaying = Instance.new("TextLabel", section)
    nowPlaying.Name = "NowPlaying"
    nowPlaying.Size = UDim2.new(1, -70, 0, 18)
    nowPlaying.Position = UDim2.new(0, 0, 0, 18)
    nowPlaying.BackgroundTransparency = 1
    nowPlaying.Text = entry.data.currentEmote and ("Playing: " .. entry.data.currentEmote) or "Playing: -"
    nowPlaying.TextColor3 = entry.data.currentEmote and GREEN or DARK_GRAY
    nowPlaying.Font = Enum.Font.Gotham
    nowPlaying.TextSize = 11
    nowPlaying.TextXAlignment = Enum.TextXAlignment.Left

    local stopBtn = makeButton(section, "STOP", UDim2.new(0, 60, 0, 22), UDim2.new(1, -60, 0, 16), WHITE, RED)
    stopBtn.TextSize = 10
    stroke(stopBtn, RED, 1, 0.5)
    stopBtn.MouseButton1Click:Connect(function()
        CloneEmote.stop(id)
        nowPlaying.Text = "Playing: -"
        nowPlaying.TextColor3 = DARK_GRAY
    end)

    -- Search box
    local searchFrame = Instance.new("Frame", section)
    searchFrame.Size = UDim2.new(1, 0, 0, 34)
    searchFrame.Position = UDim2.new(0, 0, 0, 40)
    searchFrame.BackgroundColor3 = LIGHT_GRAY
    corner(searchFrame, 12)
    stroke(searchFrame, PURPLE_SOFT, 1, 0.3)

    local searchBox = Instance.new("TextBox", searchFrame)
    searchBox.Size = UDim2.new(1, -16, 1, 0)
    searchBox.Position = UDim2.new(0, 10, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.PlaceholderText = "Search emote..."
    searchBox.PlaceholderColor3 = DARK_GRAY
    searchBox.TextColor3 = BLACK
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 12
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.TextYAlignment = Enum.TextYAlignment.Center
    searchBox.ClearTextOnFocus = false

    -- Tabs: All / Favorites / Recently Used
    local tabWrap = Instance.new("Frame", section)
    tabWrap.Size = UDim2.new(1, 0, 0, 28)
    tabWrap.Position = UDim2.new(0, 0, 0, 78)
    tabWrap.BackgroundTransparency = 1
    local tabLayout = Instance.new("UIListLayout", tabWrap)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 4)

    local emoteTab = "all"
    local tabButtons = {}
    local function makeTab(label, key)
        local b = makeButton(tabWrap, label, UDim2.new(0.33, -3, 1, 0), nil, emoteTab == key and PURPLE or LIGHT_GRAY, emoteTab == key and WHITE or BLACK)
        b.TextSize = 10
        stroke(b, PURPLE_SOFT, 1, 0.3)
        tabButtons[key] = b
        return b
    end

    -- Result list
    local resultList = Instance.new("ScrollingFrame", section)
    resultList.Size = UDim2.new(1, 0, 1, -112)
    resultList.Position = UDim2.new(0, 0, 0, 112)
    resultList.BackgroundTransparency = 1
    resultList.BorderSizePixel = 0
    resultList.ScrollBarThickness = 2
    resultList.ScrollBarImageColor3 = PURPLE
    resultList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    resultList.CanvasSize = UDim2.new(0,0,0,0)
    local resultLayout = Instance.new("UIListLayout", resultList)
    resultLayout.Padding = UDim.new(0, 4)

    local function renderEmoteResults()
        for _, c in ipairs(resultList:GetChildren()) do
            if not c:IsA("UIListLayout") then c:Destroy() end
        end

        local pool
        if emoteTab == "favorites" then
            local favs = (_G.EmoteCache and _G.EmoteCache.favorites) or {}
            pool = {}
            local all = getAvailableEmotes()
            for _, e in ipairs(all) do
                if table.find(favs, e.id) then table.insert(pool, e) end
            end
        elseif emoteTab == "recent" then
            local recents = getRecentEmotes()
            pool = {}
            for _, r in ipairs(recents) do
                table.insert(pool, {id = r.id, name = r.name})
            end
        else
            pool = getAvailableEmotes()
        end

        local q = searchBox.Text:lower()
        local shown = 0
        for _, emote in ipairs(pool) do
            if q == "" or emote.name:lower():find(q, 1, true) then
                shown = shown + 1
                if shown > 40 then break end -- batasi render, hemat performa
                local row = Instance.new("TextButton", resultList)
                row.Size = UDim2.new(1, 0, 0, 30)
                row.BackgroundColor3 = LIGHT_GRAY
                row.Text = "▶  " .. emote.name
                row.TextColor3 = BLACK
                row.Font = Enum.Font.Gotham
                row.TextSize = 11
                row.TextXAlignment = Enum.TextXAlignment.Left
                row.AutoButtonColor = false
                corner(row, 8)
                local rowPad = Instance.new("UIPadding", row)
                rowPad.PaddingLeft = UDim.new(0, 8)

                row.MouseButton1Click:Connect(function()
                    CloneEmote.play(id, emote.id, emote.name, false)
                    nowPlaying.Text = "Playing: " .. emote.name
                    nowPlaying.TextColor3 = GREEN
                end)
            end
        end

        if shown == 0 then
            local emptyLbl = Instance.new("TextLabel", resultList)
            emptyLbl.Size = UDim2.new(1, 0, 0, 40)
            emptyLbl.BackgroundTransparency = 1
            emptyLbl.Text = (emoteTab == "all" and #getAvailableEmotes() == 0)
                and "Buka app Emote dulu untuk memuat daftar"
                or "Tidak ada emote"
            emptyLbl.TextColor3 = DARK_GRAY
            emptyLbl.Font = Enum.Font.Gotham
            emptyLbl.TextSize = 11
            emptyLbl.TextWrapped = true
        end
    end

    local tabAll = makeTab("All", "all")
    local tabFav = makeTab("Favorites", "favorites")
    local tabRecent = makeTab("Recent", "recent")

    local function selectTab(key)
        emoteTab = key
        for k, b in pairs(tabButtons) do
            tween(b, {BackgroundColor3 = (k == key) and PURPLE or LIGHT_GRAY, TextColor3 = (k == key) and WHITE or BLACK}, 0.12)
        end
        renderEmoteResults()
    end
    tabAll.MouseButton1Click:Connect(function() selectTab("all") end)
    tabFav.MouseButton1Click:Connect(function() selectTab("favorites") end)
    tabRecent.MouseButton1Click:Connect(function() selectTab("recent") end)

    searchBox:GetPropertyChangedSignal("Text"):Connect(renderEmoteResults)
    renderEmoteResults()

    return section
end

-- --- FOLLOW section (search players, pilih target, mode, distance, on/off) ---
local function buildFollowSection(parent, id, order)
    local entry = Registry.clones[id]
    local section = Instance.new("Frame", parent)
    section.Size = UDim2.new(1, 0, 0, 250)
    section.BackgroundColor3 = WHITE
    section.LayoutOrder = order
    section.ClipsDescendants = true
    corner(section, 16)
    stroke(section, PURPLE_SOFT, 1, 0.3)

    local pad = Instance.new("UIPadding", section)
    pad.PaddingTop = UDim.new(0, 10)
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)

    local title = Instance.new("TextLabel", section)
    title.Size = UDim2.new(1, 0, 0, 18)
    title.BackgroundTransparency = 1
    title.Text = "FOLLOW"
    title.TextColor3 = DARK_GRAY
    title.Font = Enum.Font.GothamBold
    title.TextSize = 11
    title.TextXAlignment = Enum.TextXAlignment.Left

    local targetLbl = Instance.new("TextLabel", section)
    targetLbl.Name = "TargetLbl"
    targetLbl.Size = UDim2.new(1, -90, 0, 18)
    targetLbl.Position = UDim2.new(0, 0, 0, 18)
    targetLbl.BackgroundTransparency = 1
    targetLbl.Text = entry.data.followTarget and ("Follow Target: @" .. entry.data.followTarget.Name) or "Follow Target: -"
    targetLbl.TextColor3 = entry.data.followTarget and PURPLE or DARK_GRAY
    targetLbl.Font = Enum.Font.Gotham
    targetLbl.TextSize = 11
    targetLbl.TextXAlignment = Enum.TextXAlignment.Left

    local toggleBtn = makeButton(section, entry.data.followEnabled and "Follow ON" or "Follow OFF", UDim2.new(0, 90, 0, 24),
        UDim2.new(1, -90, 0, 14), entry.data.followEnabled and GREEN or LIGHT_GRAY, entry.data.followEnabled and WHITE or BLACK)
    toggleBtn.TextSize = 10
    stroke(toggleBtn, PURPLE_SOFT, 1, 0.3)

    local searchFrame = Instance.new("Frame", section)
    searchFrame.Size = UDim2.new(1, 0, 0, 32)
    searchFrame.Position = UDim2.new(0, 0, 0, 42)
    searchFrame.BackgroundColor3 = LIGHT_GRAY
    corner(searchFrame, 12)
    stroke(searchFrame, PURPLE_SOFT, 1, 0.3)

    local searchBox = Instance.new("TextBox", searchFrame)
    searchBox.Size = UDim2.new(1, -16, 1, 0)
    searchBox.Position = UDim2.new(0, 10, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.PlaceholderText = "Search players..."
    searchBox.PlaceholderColor3 = DARK_GRAY
    searchBox.TextColor3 = BLACK
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 12
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.TextYAlignment = Enum.TextYAlignment.Center
    searchBox.ClearTextOnFocus = false

    local modeWrap = Instance.new("Frame", section)
    modeWrap.Size = UDim2.new(1, 0, 0, 26)
    modeWrap.Position = UDim2.new(0, 0, 0, 78)
    modeWrap.BackgroundTransparency = 1
    local modeLayout = Instance.new("UIListLayout", modeWrap)
    modeLayout.FillDirection = Enum.FillDirection.Horizontal
    modeLayout.Padding = UDim.new(0, 4)

    local modes = {{key="position", label="POS"}, {key="rotation", label="ROT"}, {key="both", label="BOTH"}}
    local modeButtons = {}
    for i, m in ipairs(modes) do
        local isActive = entry.data.followMode == m.key
        local b = makeButton(modeWrap, m.label, UDim2.new(0.33, -3, 1, 0), nil, isActive and PURPLE or LIGHT_GRAY, isActive and WHITE or BLACK)
        b.TextSize = 10
        stroke(b, PURPLE_SOFT, 1, 0.3)
        modeButtons[m.key] = b
        b.MouseButton1Click:Connect(function()
            Follow.setMode(id, m.key)
            for k, btn in pairs(modeButtons) do
                tween(btn, {BackgroundColor3 = (k == m.key) and PURPLE or LIGHT_GRAY, TextColor3 = (k == m.key) and WHITE or BLACK}, 0.12)
            end
        end)
    end

    local distWrap = Instance.new("Frame", section)
    distWrap.Size = UDim2.new(1, 0, 0, 26)
    distWrap.Position = UDim2.new(0, 0, 0, 108)
    distWrap.BackgroundTransparency = 1

    local distLbl = Instance.new("TextLabel", distWrap)
    distLbl.Size = UDim2.new(1, -70, 1, 0)
    distLbl.BackgroundTransparency = 1
    distLbl.Text = "Distance: " .. entry.data.followDistance .. " studs"
    distLbl.TextColor3 = DARK_GRAY
    distLbl.Font = Enum.Font.Gotham
    distLbl.TextSize = 11
    distLbl.TextXAlignment = Enum.TextXAlignment.Left

    local distOptions = {1, 2, 3, 5, 10}
    local distIdx = table.find(distOptions, entry.data.followDistance) or 3
    local dMinus = makeButton(distWrap, "-", UDim2.new(0, 30, 1, 0), UDim2.new(1, -66, 0, 0), LIGHT_GRAY, BLACK)
    stroke(dMinus, PURPLE_SOFT, 1, 0.3)
    local dPlus = makeButton(distWrap, "+", UDim2.new(0, 30, 1, 0), UDim2.new(1, -32, 0, 0), LIGHT_GRAY, BLACK)
    stroke(dPlus, PURPLE_SOFT, 1, 0.3)
    dMinus.MouseButton1Click:Connect(function()
        distIdx = math.max(1, distIdx - 1)
        Follow.setDistance(id, distOptions[distIdx])
        distLbl.Text = "Distance: " .. distOptions[distIdx] .. " studs"
    end)
    dPlus.MouseButton1Click:Connect(function()
        distIdx = math.min(#distOptions, distIdx + 1)
        Follow.setDistance(id, distOptions[distIdx])
        distLbl.Text = "Distance: " .. distOptions[distIdx] .. " studs"
    end)

    local resultList = Instance.new("ScrollingFrame", section)
    resultList.Size = UDim2.new(1, 0, 1, -140)
    resultList.Position = UDim2.new(0, 0, 0, 140)
    resultList.BackgroundTransparency = 1
    resultList.BorderSizePixel = 0
    resultList.ScrollBarThickness = 2
    resultList.ScrollBarImageColor3 = PURPLE
    resultList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    resultList.CanvasSize = UDim2.new(0,0,0,0)
    local resultLayout = Instance.new("UIListLayout", resultList)
    resultLayout.Padding = UDim.new(0, 4)

    local function renderPlayerResults()
        for _, c in ipairs(resultList:GetChildren()) do
            if not c:IsA("UIListLayout") then c:Destroy() end
        end
        local q = searchBox.Text:lower()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                if q == "" or plr.Name:lower():find(q, 1, true) or plr.DisplayName:lower():find(q, 1, true) then
                    local row = Instance.new("Frame", resultList)
                    row.Size = UDim2.new(1, 0, 0, 36)
                    row.BackgroundColor3 = LIGHT_GRAY
                    corner(row, 10)

                    local rowName = Instance.new("TextLabel", row)
                    rowName.Size = UDim2.new(1, -80, 0, 18)
                    rowName.Position = UDim2.new(0, 8, 0, 2)
                    rowName.BackgroundTransparency = 1
                    rowName.Text = plr.DisplayName
                    rowName.TextColor3 = BLACK
                    rowName.Font = Enum.Font.GothamBold
                    rowName.TextSize = 11
                    rowName.TextXAlignment = Enum.TextXAlignment.Left

                    local rowUser = Instance.new("TextLabel", row)
                    rowUser.Size = UDim2.new(1, -80, 0, 14)
                    rowUser.Position = UDim2.new(0, 8, 0, 19)
                    rowUser.BackgroundTransparency = 1
                    rowUser.Text = "@" .. plr.Name
                    rowUser.TextColor3 = DARK_GRAY
                    rowUser.Font = Enum.Font.Gotham
                    rowUser.TextSize = 9
                    rowUser.TextXAlignment = Enum.TextXAlignment.Left

                    local followBtn = makeButton(row, "FOLLOW", UDim2.new(0, 68, 0, 26), UDim2.new(1, -74, 0.5, -13), PURPLE, WHITE)
                    followBtn.TextSize = 10
                    followBtn.MouseButton1Click:Connect(function()
                        Follow.setTarget(id, plr)
                        targetLbl.Text = "Follow Target: @" .. plr.Name
                        targetLbl.TextColor3 = PURPLE
                    end)
                end
            end
        end
    end
    searchBox:GetPropertyChangedSignal("Text"):Connect(renderPlayerResults)
    renderPlayerResults()

    toggleBtn.MouseButton1Click:Connect(function()
        if entry.data.followEnabled then
            Follow.disable(id)
            toggleBtn.Text = "Follow OFF"
            tween(toggleBtn, {BackgroundColor3 = LIGHT_GRAY, TextColor3 = BLACK}, 0.12)
        else
            Follow.enable(id)
            toggleBtn.Text = "Follow ON"
            tween(toggleBtn, {BackgroundColor3 = GREEN, TextColor3 = WHITE}, 0.12)
        end
    end)

    return section
end

-- --- ITEM section ---
local function buildItemSection(parent, id, order)
    local entry = Registry.clones[id]
    local section = Instance.new("Frame", parent)
    section.Size = UDim2.new(1, 0, 0, 110)
    section.BackgroundColor3 = WHITE
    section.LayoutOrder = order
    corner(section, 16)
    stroke(section, PURPLE_SOFT, 1, 0.3)

    local pad = Instance.new("UIPadding", section)
    pad.PaddingTop = UDim.new(0, 10)
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)

    local title = Instance.new("TextLabel", section)
    title.Size = UDim2.new(1, 0, 0, 18)
    title.BackgroundTransparency = 1
    title.Text = "ITEM"
    title.TextColor3 = DARK_GRAY
    title.Font = Enum.Font.GothamBold
    title.TextSize = 11
    title.TextXAlignment = Enum.TextXAlignment.Left

    local heldLbl = Instance.new("TextLabel", section)
    heldLbl.Name = "HeldLbl"
    heldLbl.Size = UDim2.new(1, 0, 0, 18)
    heldLbl.Position = UDim2.new(0, 0, 0, 18)
    heldLbl.BackgroundTransparency = 1
    heldLbl.Text = "Current Held Item: " .. (entry.data.heldItemName or "-")
    heldLbl.TextColor3 = entry.data.heldItemName and PURPLE or DARK_GRAY
    heldLbl.Font = Enum.Font.Gotham
    heldLbl.TextSize = 11
    heldLbl.TextXAlignment = Enum.TextXAlignment.Left

    local btnRow = Instance.new("Frame", section)
    btnRow.Size = UDim2.new(1, 0, 0, 32)
    btnRow.Position = UDim2.new(0, 0, 0, 42)
    btnRow.BackgroundTransparency = 1
    local rowLayout = Instance.new("UIListLayout", btnRow)
    rowLayout.FillDirection = Enum.FillDirection.Horizontal
    rowLayout.Padding = UDim.new(0, 6)

    local giveBtn = makeButton(btnRow, "GIVE TO CLONE", UDim2.new(0.4, -4, 1, 0), nil, PURPLE, WHITE)
    giveBtn.TextSize = 10
    local removeBtn = makeButton(btnRow, "REMOVE", UDim2.new(0.3, -4, 1, 0), nil, LIGHT_GRAY, BLACK)
    removeBtn.TextSize = 10
    stroke(removeBtn, PURPLE_SOFT, 1, 0.3)
    local dropBtn = makeButton(btnRow, "DROP", UDim2.new(0.3, -4, 1, 0), nil, LIGHT_GRAY, BLACK)
    dropBtn.TextSize = 10
    stroke(dropBtn, PURPLE_SOFT, 1, 0.3)

    local function refreshHeldLbl()
        heldLbl.Text = "Current Held Item: " .. (entry.data.heldItemName or "-")
        heldLbl.TextColor3 = entry.data.heldItemName and PURPLE or DARK_GRAY
    end

    giveBtn.MouseButton1Click:Connect(function() CloneItem.give(id); refreshHeldLbl() end)
    removeBtn.MouseButton1Click:Connect(function() CloneItem.remove(id); refreshHeldLbl() end)
    dropBtn.MouseButton1Click:Connect(function() CloneItem.drop(id); refreshHeldLbl() end)

    return section
end

-- --- CHAT section ---
local function buildChatSection(parent, id, order)
    local entry = Registry.clones[id]
    local section = Instance.new("Frame", parent)
    section.Size = UDim2.new(1, 0, 0, 100)
    section.BackgroundColor3 = WHITE
    section.LayoutOrder = order
    corner(section, 16)
    stroke(section, PURPLE_SOFT, 1, 0.3)

    local pad = Instance.new("UIPadding", section)
    pad.PaddingTop = UDim.new(0, 10)
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)

    local title = Instance.new("TextLabel", section)
    title.Size = UDim2.new(1, 0, 0, 18)
    title.BackgroundTransparency = 1
    title.Text = "CHAT"
    title.TextColor3 = DARK_GRAY
    title.Font = Enum.Font.GothamBold
    title.TextSize = 11
    title.TextXAlignment = Enum.TextXAlignment.Left

    local clearBtn = makeButton(section, "Clear", UDim2.new(0, 50, 0, 18), UDim2.new(1, -50, 0, 0), LIGHT_GRAY, DARK_GRAY)
    clearBtn.TextSize = 9
    clearBtn.MouseButton1Click:Connect(function() CloneChat.clear(id) end)

    local inputFrame = Instance.new("Frame", section)
    inputFrame.Size = UDim2.new(1, -66, 0, 34)
    inputFrame.Position = UDim2.new(0, 0, 0, 24)
    inputFrame.BackgroundColor3 = LIGHT_GRAY
    corner(inputFrame, 12)
    stroke(inputFrame, PURPLE_SOFT, 1, 0.3)

    local chatBox = Instance.new("TextBox", inputFrame)
    chatBox.Size = UDim2.new(1, -16, 1, 0)
    chatBox.Position = UDim2.new(0, 10, 0, 0)
    chatBox.BackgroundTransparency = 1
    chatBox.PlaceholderText = "Type message..."
    chatBox.PlaceholderColor3 = DARK_GRAY
    chatBox.TextColor3 = BLACK
    chatBox.Font = Enum.Font.Gotham
    chatBox.TextSize = 12
    chatBox.TextXAlignment = Enum.TextXAlignment.Left
    chatBox.TextYAlignment = Enum.TextYAlignment.Center
    chatBox.ClearTextOnFocus = false

    local sendBtn = makeButton(section, "SEND", UDim2.new(0, 58, 0, 34), UDim2.new(1, -58, 0, 24), PURPLE, WHITE)
    sendBtn.TextSize = 11

    local function doSend()
        if chatBox.Text:gsub("%s","") ~= "" then
            CloneChat.send(id, chatBox.Text)
            chatBox.Text = ""
        end
    end
    sendBtn.MouseButton1Click:Connect(doSend)
    chatBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then doSend() end
    end)

    return section
end

-- --- RENAME section ---
local function buildRenameSection(parent, id, order)
    local entry = Registry.clones[id]
    local section = Instance.new("Frame", parent)
    section.Size = UDim2.new(1, 0, 0, 90)
    section.BackgroundColor3 = WHITE
    section.LayoutOrder = order
    corner(section, 16)
    stroke(section, PURPLE_SOFT, 1, 0.3)

    local pad = Instance.new("UIPadding", section)
    pad.PaddingTop = UDim.new(0, 10)
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)

    local title = Instance.new("TextLabel", section)
    title.Size = UDim2.new(1, 0, 0, 18)
    title.BackgroundTransparency = 1
    title.Text = "CLONE NAME"
    title.TextColor3 = DARK_GRAY
    title.Font = Enum.Font.GothamBold
    title.TextSize = 11
    title.TextXAlignment = Enum.TextXAlignment.Left

    local inputFrame = Instance.new("Frame", section)
    inputFrame.Size = UDim2.new(1, -66, 0, 34)
    inputFrame.Position = UDim2.new(0, 0, 0, 24)
    inputFrame.BackgroundColor3 = LIGHT_GRAY
    corner(inputFrame, 12)
    stroke(inputFrame, PURPLE_SOFT, 1, 0.3)

    local nameBox = Instance.new("TextBox", inputFrame)
    nameBox.Size = UDim2.new(1, -16, 1, 0)
    nameBox.Position = UDim2.new(0, 10, 0, 0)
    nameBox.BackgroundTransparency = 1
    nameBox.Text = entry.data.name
    nameBox.TextColor3 = BLACK
    nameBox.Font = Enum.Font.Gotham
    nameBox.TextSize = 12
    nameBox.TextXAlignment = Enum.TextXAlignment.Left
    nameBox.TextYAlignment = Enum.TextYAlignment.Center
    nameBox.ClearTextOnFocus = false

    local saveBtn = makeButton(section, "SAVE NAME", UDim2.new(0, 58, 0, 34), UDim2.new(1, -58, 0, 24), PURPLE, WHITE)
    saveBtn.TextSize = 9

    return section, nameBox, saveBtn
end

-- --- Merangkai seluruh controller screen ---
buildControllerScreen = function(id)
    currentScreen = "controller"
    Registry.selectedId = id
    local entry = Registry.clones[id]
    if not entry then buildManagerScreen(); return end

    clearAppContent()

    local headerWrap, statusLbl = buildControllerHeader(appContent, id, 1)

    local scroll = Instance.new("ScrollingFrame", appContent)
    scroll.Size = UDim2.new(1, 0, 1, -66)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 2
    scroll.ScrollBarImageColor3 = PURPLE
    scroll.LayoutOrder = 2
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.CanvasSize = UDim2.new(0,0,0,0)

    local scrollLayout = Instance.new("UIListLayout", scroll)
    scrollLayout.Padding = UDim.new(0, 10)
    scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local moveSection, refreshCoord = buildMoveRotateSection(scroll, id, 1)
    buildRotationPresetSection(scroll, id, 2)
    buildFreePositionSection(scroll, id, 3)
    buildEmoteSection(scroll, id, 4)
    buildFollowSection(scroll, id, 5)
    buildItemSection(scroll, id, 6)
    buildChatSection(scroll, id, 7)
    local renameSection, nameBox, saveBtn = buildRenameSection(scroll, id, 8)

    -- Visibility toggle + Duplicate, taruh di bawah rename
    local utilRow = Instance.new("Frame", scroll)
    utilRow.Size = UDim2.new(1, 0, 0, 40)
    utilRow.BackgroundTransparency = 1
    utilRow.LayoutOrder = 9
    local utilLayout = Instance.new("UIListLayout", utilRow)
    utilLayout.FillDirection = Enum.FillDirection.Horizontal
    utilLayout.Padding = UDim.new(0, 6)

    local visBtn = makeButton(utilRow, entry.data.visible and "HIDE" or "SHOW", UDim2.new(0.48, -3, 1, 0), nil, LIGHT_GRAY, BLACK)
    visBtn.TextSize = 11
    stroke(visBtn, PURPLE_SOFT, 1, 0.3)
    visBtn.MouseButton1Click:Connect(function()
        CloneManager.setVisible(id, not entry.data.visible)
        visBtn.Text = entry.data.visible and "HIDE" or "SHOW"
    end)

    local dupBtn = makeButton(utilRow, "DUPLICATE", UDim2.new(0.48, -3, 1, 0), nil, LIGHT_GRAY, BLACK)
    dupBtn.TextSize = 11
    stroke(dupBtn, PURPLE_SOFT, 1, 0.3)
    dupBtn.MouseButton1Click:Connect(function()
        local newId = CloneManager.duplicate(id)
        if newId then buildControllerScreen(newId) end
    end)

    saveBtn.MouseButton1Click:Connect(function()
        if CloneManager.rename(id, nameBox.Text) then
            headerWrap:FindFirstChild("TextLabel") -- no-op guard
        end
        buildControllerScreen(id) -- refresh header dengan nama baru
    end)

    -- Live status update ringan: dipanggil manual saat tombol ditekan
    -- (bukan RenderStepped loop) untuk menjaga performa.
    local function refreshStatus()
        if entry.data.currentEmote then
            statusLbl.Text = "● Playing: " .. entry.data.currentEmote
            statusLbl.TextColor3 = GREEN
        elseif entry.data.followEnabled then
            statusLbl.Text = "● Following @" .. (entry.data.followTarget and entry.data.followTarget.Name or "?")
            statusLbl.TextColor3 = GREEN
        else
            statusLbl.Text = "● Idle"
            statusLbl.TextColor3 = DARK_GRAY
        end
    end
    refreshStatus()

    -- Refresh status setiap kali user berinteraksi dengan tombol-tombol utama
    task.spawn(function()
        while scroll.Parent do
            task.wait(1)
            refreshStatus()
        end
    end)
end

openClonePanel = function(id)
    buildControllerScreen(id)
end

-- ==================== MAIN APP ENTRY ====================
function _G.openCloneApp()
    appContent = _G.appContent
    if not appContent then return end
    local ok, err = pcall(function()
        if Registry.selectedId and Registry.clones[Registry.selectedId] then
            buildControllerScreen(Registry.selectedId)
        else
            buildManagerScreen()
        end
    end)
    if not ok then
        warn("[Clone] Failed to open Clone app: " .. tostring(err))
    end
    return true
end

-- ==================== GLOBAL CLEANUP ON SCRIPT UNLOAD ====================
-- Jika ada mekanisme unload script (mis. _G.onScriptUnload hook dari
-- framework utama), pastikan semua clone ikut dibersihkan tuntas.
_G.cleanupAllClones = function()
    CloneManager.deleteAll()
    if followLoopConnection then
        followLoopConnection:Disconnect()
        followLoopConnection = nil
    end
end

print("[Clone] Personal Clone Manager Loaded! Max clones: " .. MAX_CLONES)
