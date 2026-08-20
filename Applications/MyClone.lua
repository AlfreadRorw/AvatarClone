-- ================================================
-- MYCLONE.LUA — Kelola Clone Avatar (Mode Edit + Gizmo 3D)
-- Fitur: daftar clone, mode edit dengan gizmo panah 3D
-- (merah=X, hijau=Y, biru=Z) untuk geser & putar,
-- serta tombol aksi: reset posisi, reset rotasi,
-- hapus clone, hapus semua, reset karakter, load pemain.
-- ================================================

local Services    = _G.Services
local LocalPlayer = _G.LocalPlayer
local Players     = Services.Players
local Helpers     = _G.Helpers or {}
local Config      = _G.Config or {}
local appContent  = _G.appContent
local ReplicatedStorage = Services.ReplicatedStorage
local Workspace   = Services.Workspace
local RunService  = Services.RunService

local corner  = Helpers.corner
local stroke  = Helpers.stroke
local pressFX = Helpers.pressFX
local tween   = Helpers.tween

-- ==================== PALETTE ====================
local C = {
    bg      = Color3.fromRGB(10, 10, 16),
    card    = Color3.fromRGB(20, 20, 28),
    card2   = Color3.fromRGB(30, 30, 40),
    border  = Color3.fromRGB(48, 48, 62),
    text    = Color3.fromRGB(240, 240, 250),
    text2   = Color3.fromRGB(155, 155, 172),
    text3   = Color3.fromRGB(95, 95, 112),
    accent  = Color3.fromRGB(100, 160, 255),
    accent2 = Color3.fromRGB(168, 100, 255),
    green   = Color3.fromRGB(90, 220, 150),
    gold    = Color3.fromRGB(255, 195, 70),
    red     = Color3.fromRGB(255, 95, 105),
    -- Warna gizmo 3D
    axisX   = Color3.fromRGB(255, 60, 60),   -- merah
    axisY   = Color3.fromRGB(60, 255, 60),   -- hijau
    axisZ   = Color3.fromRGB(60, 160, 255),  -- biru
}

-- ==================== REMOTE HELPER ====================
local function fireRemote(cmd, arg1, arg2)
    pcall(function()
        local pathParts = string.split(Config.REMOTE_PATH or "Remotes.Command.CommandEvent", ".")
        local obj = game
        for _, p in ipairs(pathParts) do
            obj = obj:WaitForChild(p, 2)
        end
        if obj and obj:IsA("RemoteEvent") then
            obj:FireServer(cmd, arg1 or "me", arg2)
        end
    end)
end

-- ==================== STATE ====================
local cloneList = {}
local selectedCloneIndex = nil
local gizmoActive = false
local gizmoParts = {} -- {arrowX, arrowY, arrowZ, ringX, ringY, ringZ, center}
local selectedCharacter = nil
local targetUserId = nil

-- ==================== BUAT GIZMO 3D ====================
local function createGizmoPart(parent, color, size, offset)
    local part = Instance.new("Part")
    part.Size = size or Vector3.new(0.3, 2, 0.3)
    part.BrickColor = BrickColor.new(color)
    part.Material = Enum.Material.Neon
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 0.2
    part.Parent = parent or Workspace
    return part
end

local function createArrow(parent, color, dir, offset)
    -- Batang panah
    local shaft = Instance.new("Part")
    shaft.Size = Vector3.new(0.2, 2, 0.2)
    shaft.BrickColor = BrickColor.new(color)
    shaft.Material = Enum.Material.Neon
    shaft.Anchored = true
    shaft.CanCollide = false
    shaft.Transparency = 0.15
    shaft.Parent = parent or Workspace

    -- Kepala panah (kerucut)
    local head = Instance.new("Part")
    head.Size = Vector3.new(0.6, 0.6, 0.6)
    head.BrickColor = BrickColor.new(color)
    head.Material = Enum.Material.Neon
    head.Anchored = true
    head.CanCollide = false
    head.Transparency = 0.1
    head.Shape = Enum.PartType.Cylinder
    head.Parent = parent or Workspace

    return shaft, head
end

-- Fungsi untuk menampilkan gizmo pada clone yang dipilih
local function showGizmo(userId)
    -- Hapus gizmo lama
    for _, p in ipairs(gizmoParts) do
        pcall(function() p:Destroy() end)
    end
    gizmoParts = {}

    -- Cari player
    local player = Players:GetPlayerByUserId(userId)
    if not player then return end

    local char = player.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local pos = hrp.Position
    local cf = hrp.CFrame

    -- Gizmo Container (invisible part sebagai parent)
    local container = Instance.new("Part")
    container.Name = "GizmoContainer_" .. userId
    container.Size = Vector3.new(0.1, 0.1, 0.1)
    container.Anchored = true
    container.CanCollide = false
    container.Transparency = 1
    container.CFrame = cf
    container.Parent = Workspace

    -- --- SUMBU X (MERAH) ---
    local xShaft = createGizmoPart(container, C.axisX, Vector3.new(0.2, 2.5, 0.2))
    xShaft.CFrame = cf * CFrame.new(0, 1.25, 0)
    local xHead = createGizmoPart(container, C.axisX, Vector3.new(0.5, 0.5, 0.5))
    xHead.Shape = Enum.PartType.Cylinder
    xHead.CFrame = cf * CFrame.new(0, 2.8, 0)
    table.insert(gizmoParts, xShaft)
    table.insert(gizmoParts, xHead)

    -- Label X (menggunakan Attachment + BillboardGui sebenarnya lebih baik, tapi sederhanakan pakai Part)
    local xLabel = Instance.new("Part")
    xLabel.Size = Vector3.new(0.4, 0.4, 0.1)
    xLabel.BrickColor = BrickColor.new(C.axisX)
    xLabel.Material = Enum.Material.Neon
    xLabel.Anchored = true
    xLabel.CanCollide = false
    xLabel.Transparency = 0.3
    xLabel.CFrame = cf * CFrame.new(0, 3.3, 0)
    xLabel.Parent = container
    table.insert(gizmoParts, xLabel)

    -- --- SUMBU Y (HIJAU) ---
    local yShaft = createGizmoPart(container, C.axisY, Vector3.new(0.2, 2.5, 0.2))
    yShaft.CFrame = cf * CFrame.new(0, 0, 1.25) * CFrame.Angles(math.rad(90), 0, 0)
    local yHead = createGizmoPart(container, C.axisY, Vector3.new(0.5, 0.5, 0.5))
    yHead.Shape = Enum.PartType.Cylinder
    yHead.CFrame = cf * CFrame.new(0, 0, 2.8) * CFrame.Angles(math.rad(90), 0, 0)
    table.insert(gizmoParts, yShaft)
    table.insert(gizmoParts, yHead)

    -- --- SUMBU Z (BIRU) ---
    local zShaft = createGizmoPart(container, C.axisZ, Vector3.new(0.2, 2.5, 0.2))
    zShaft.CFrame = cf * CFrame.new(1.25, 0, 0) * CFrame.Angles(0, 0, math.rad(-90))
    local zHead = createGizmoPart(container, C.axisZ, Vector3.new(0.5, 0.5, 0.5))
    zHead.Shape = Enum.PartType.Cylinder
    zHead.CFrame = cf * CFrame.new(2.8, 0, 0) * CFrame.Angles(0, 0, math.rad(-90))
    table.insert(gizmoParts, zShaft)
    table.insert(gizmoParts, zHead)

    -- --- LINGKARAN PUTAR (RING) ---
    -- Ring X (merah) - putar di sumbu X
    local ringX = Instance.new("Part")
    ringX.Size = Vector3.new(0.1, 2.5, 2.5)
    ringX.BrickColor = BrickColor.new(C.axisX)
    ringX.Material = Enum.Material.Neon
    ringX.Anchored = true
    ringX.CanCollide = false
    ringX.Transparency = 0.4
    ringX.Shape = Enum.PartType.Cylinder
    ringX.CFrame = cf * CFrame.Angles(0, 0, math.rad(90))
    ringX.Parent = container
    table.insert(gizmoParts, ringX)

    -- Ring Y (hijau) - putar di sumbu Y
    local ringY = Instance.new("Part")
    ringY.Size = Vector3.new(0.1, 2.5, 2.5)
    ringY.BrickColor = BrickColor.new(C.axisY)
    ringY.Material = Enum.Material.Neon
    ringY.Anchored = true
    ringY.CanCollide = false
    ringY.Transparency = 0.4
    ringY.Shape = Enum.PartType.Cylinder
    ringY.CFrame = cf
    ringY.Parent = container
    table.insert(gizmoParts, ringY)

    -- Ring Z (biru) - putar di sumbu Z
    local ringZ = Instance.new("Part")
    ringZ.Size = Vector3.new(0.1, 2.5, 2.5)
    ringZ.BrickColor = BrickColor.new(C.axisZ)
    ringZ.Material = Enum.Material.Neon
    ringZ.Anchored = true
    ringZ.CanCollide = false
    ringZ.Transparency = 0.4
    ringZ.Shape = Enum.PartType.Cylinder
    ringZ.CFrame = cf * CFrame.Angles(math.rad(90), 0, 0)
    ringZ.Parent = container
    table.insert(gizmoParts, ringZ)

    -- Center point (bola di tengah)
    local center = Instance.new("Part")
    center.Size = Vector3.new(0.3, 0.3, 0.3)
    center.BrickColor = BrickColor.new("White")
    center.Material = Enum.Material.Neon
    center.Anchored = true
    center.CanCollide = false
    center.Shape = Enum.PartType.Ball
    center.CFrame = cf
    center.Parent = container
    table.insert(gizmoParts, center)

    -- Simpan container untuk update posisi
    table.insert(gizmoParts, container)
    gizmoActive = true
    selectedCharacter = char
    targetUserId = userId

    _G.showDynamicNotification("Gizmo 3D aktif! Geser/putar clone dengan drag panah.", C.accent2)
end

-- Fungsi untuk menyembunyikan gizmo
local function hideGizmo()
    for _, p in ipairs(gizmoParts) do
        pcall(function() p:Destroy() end)
    end
    gizmoParts = {}
    gizmoActive = false
    selectedCharacter = nil
    targetUserId = nil
end

-- Update posisi gizmo mengikuti clone (jika bergerak)
local gizmoHeartbeat
local function startGizmoHeartbeat()
    if gizmoHeartbeat then
        gizmoHeartbeat:Disconnect()
        gizmoHeartbeat = nil
    end

    gizmoHeartbeat = RunService.Heartbeat:Connect(function()
        if not gizmoActive then return end
        if not selectedCharacter or not selectedCharacter.Parent then
            hideGizmo()
            return
        end

        local hrp = selectedCharacter:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local container = gizmoParts[#gizmoParts] -- container adalah yang terakhir di table
        if container and container:IsA("Part") then
            container.CFrame = hrp.CFrame
        end
    end)
end

-- ==================== FUNGSI TOMBOL ====================
local function toggleGizmo()
    local uid = getSelectedUserId()
    if not uid then
        _G.showDynamicNotification("Pilih clone terlebih dahulu!", C.gold)
        return
    end

    if gizmoActive and targetUserId == uid then
        hideGizmo()
        _G.showDynamicNotification("Gizmo disembunyikan", C.text2)
    else
        showGizmo(uid)
        startGizmoHeartbeat()
    end
end

-- ==================== RENDER DAFTAR CLONE ====================
local function renderCloneList(container)
    for _, c in ipairs(container:GetChildren()) do
        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
            c:Destroy()
        end
    end

    if #cloneList == 0 then
        local empty = Instance.new("TextLabel", container)
        empty.Size = UDim2.new(1,0,0,40)
        empty.BackgroundTransparency = 1
        empty.Text = "Belum ada clone. Gunakan fitur Clone atau load pemain."
        empty.TextColor3 = C.text3
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 10
        empty.TextWrapped = true
        return
    end

    for i, info in ipairs(cloneList) do
        local row = Instance.new("Frame", container)
        row.Size = UDim2.new(1,0,0,44)
        row.BackgroundColor3 = (i == selectedCloneIndex) and C.card2 or C.card
        row.LayoutOrder = i
        corner(row, 10)
        stroke(row, (i == selectedCloneIndex) and C.accent2 or C.border, 1, (i == selectedCloneIndex) and 0.6 or 0.3)

        local nameLbl = Instance.new("TextLabel", row)
        nameLbl.Size = UDim2.new(1,-90,1,0)
        nameLbl.Position = UDim2.new(0,12,0,0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = info.name .. (info.isClone and " ✨" or "")
        nameLbl.TextColor3 = (i == selectedCloneIndex) and C.text or C.text2
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 11
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left

        local selectBtn = Instance.new("TextButton", row)
        selectBtn.Size = UDim2.new(0,70,0,28)
        selectBtn.Position = UDim2.new(1,-76,0.5,-14)
        selectBtn.BackgroundColor3 = (i == selectedCloneIndex) and C.accent2 or C.card2
        selectBtn.Text = (i == selectedCloneIndex) and "✓" or "Pilih"
        selectBtn.TextColor3 = (i == selectedCloneIndex) and Color3.new(1,1,1) or C.text2
        selectBtn.Font = Enum.Font.GothamBold
        selectBtn.TextSize = 10
        selectBtn.AutoButtonColor = false
        corner(selectBtn, 6)
        pressFX(selectBtn)

        selectBtn.MouseButton1Click:Connect(function()
            if selectedCloneIndex == i then
                -- Klik dua kali = toggle gizmo
                toggleGizmo()
            else
                selectedCloneIndex = i
                renderCloneList(container)
                -- Auto tampilkan gizmo saat clone dipilih
                task.wait(0.1)
                toggleGizmo()
            end
        end)
    end
end

-- ==================== OPEN APP ====================
function _G.openMyCloneApp()
    -- ===== HEADER =====
    local header = Instance.new("Frame", appContent)
    header.Size = UDim2.new(1,0,0,48)
    header.BackgroundColor3 = C.card
    header.LayoutOrder = 0
    corner(header, 12)
    stroke(header, C.accent2, 1, 0.5)

    local hTitle = Instance.new("TextLabel", header)
    hTitle.Size = UDim2.new(1,-20,0,22)
    hTitle.Position = UDim2.new(0,14,0,4)
    hTitle.BackgroundTransparency = 1
    hTitle.Text = "🔄 My Clone"
    hTitle.TextColor3 = C.text
    hTitle.Font = Enum.Font.GothamBlack
    hTitle.TextSize = 14
    hTitle.TextXAlignment = Enum.TextXAlignment.Left

    local hSub = Instance.new("TextLabel", header)
    hSub.Size = UDim2.new(1,-20,0,16)
    hSub.Position = UDim2.new(0,14,0,28)
    hSub.BackgroundTransparency = 1
    hSub.Text = "Kelola clone avatar & mode edit"
    hSub.TextColor3 = C.text3
    hSub.Font = Enum.Font.Gotham
    hSub.TextSize = 9
    hSub.TextXAlignment = Enum.TextXAlignment.Left

    -- ===== CONTENT =====
    local content = Instance.new("ScrollingFrame", appContent)
    content.Size = UDim2.new(1,0,0,0)
    content.AutomaticSize = Enum.AutomaticSize.Y
    content.BackgroundTransparency = 1
    content.LayoutOrder = 1
    content.ScrollBarThickness = 3
    content.CanvasSize = UDim2.new(0,0,0,0)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local contentLayout = Instance.new("UIListLayout", content)
    contentLayout.Padding = UDim.new(0,10)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- ===== BAGIAN DAFTAR CLONE =====
    local listSection = Instance.new("Frame", content)
    listSection.Size = UDim2.new(1,0,0,0)
    listSection.AutomaticSize = Enum.AutomaticSize.Y
    listSection.BackgroundColor3 = C.card2
    listSection.LayoutOrder = 1
    corner(listSection, 12)
    stroke(listSection, C.border, 1, 0.4)

    local listTitle = Instance.new("TextLabel", listSection)
    listTitle.Size = UDim2.new(1,-20,0,30)
    listTitle.Position = UDim2.new(0,10,0,4)
    listTitle.BackgroundTransparency = 1
    listTitle.Text = "📋 Daftar Clone"
    listTitle.TextColor3 = C.text
    listTitle.Font = Enum.Font.GothamBold
    listTitle.TextSize = 12
    listTitle.TextXAlignment = Enum.TextXAlignment.Left

    local listContainer = Instance.new("Frame", listSection)
    listContainer.Size = UDim2.new(1,-16,0,0)
    listContainer.Position = UDim2.new(0,8,0,36)
    listContainer.AutomaticSize = Enum.AutomaticSize.Y
    listContainer.BackgroundTransparency = 1

    local listPad = Instance.new("UIPadding", listContainer)
    listPad.PaddingBottom = UDim.new(0,6)

    local listLayout = Instance.new("UIListLayout", listContainer)
    listLayout.Padding = UDim.new(0,6)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    renderCloneList(listContainer)

    -- ===== BAGIAN TOMBOL AKSI =====
    local actionSection = Instance.new("Frame", content)
    actionSection.Size = UDim2.new(1,0,0,0)
    actionSection.AutomaticSize = Enum.AutomaticSize.Y
    actionSection.BackgroundColor3 = C.card2
    actionSection.LayoutOrder = 2
    corner(actionSection, 12)
    stroke(actionSection, C.border, 1, 0.4)

    local actionTitle = Instance.new("TextLabel", actionSection)
    actionTitle.Size = UDim2.new(1,-20,0,30)
    actionTitle.Position = UDim2.new(0,10,0,4)
    actionTitle.BackgroundTransparency = 1
    actionTitle.Text = "🎮 Mode Edit"
    actionTitle.TextColor3 = C.text
    actionTitle.Font = Enum.Font.GothamBold
    actionTitle.TextSize = 12
    actionTitle.TextXAlignment = Enum.TextXAlignment.Left

    -- Tombol Gizmo On/Off (yang utama)
    local gizmoBtn = Instance.new("TextButton", actionSection)
    gizmoBtn.Size = UDim2.new(1,-16,0,40)
    gizmoBtn.Position = UDim2.new(0,8,0,38)
    gizmoBtn.BackgroundColor3 = C.accent2
    gizmoBtn.BackgroundTransparency = 0.8
    gizmoBtn.Text = "🔄 Tampilkan Gizmo 3D (Panah Merah/Hijau/Biru)"
    gizmoBtn.TextColor3 = C.text
    gizmoBtn.Font = Enum.Font.GothamBold
    gizmoBtn.TextSize = 11
    gizmoBtn.AutoButtonColor = false
    corner(gizmoBtn, 10)
    stroke(gizmoBtn, C.accent2, 1.5, 0.5)
    pressFX(gizmoBtn)

    gizmoBtn.MouseButton1Click:Connect(function()
        if gizmoActive then
            hideGizmo()
            gizmoBtn.Text = "🔄 Tampilkan Gizmo 3D (Panah Merah/Hijau/Biru)"
            gizmoBtn.BackgroundColor3 = C.accent2
            gizmoBtn.BackgroundTransparency = 0.8
            _G.showDynamicNotification("Gizmo dimatikan", C.text2)
        else
            local uid = getSelectedUserId()
            if not uid then
                _G.showDynamicNotification("Pilih clone terlebih dahulu!", C.gold)
                return
            end
            showGizmo(uid)
            startGizmoHeartbeat()
            gizmoBtn.Text = "❌ Sembunyikan Gizmo"
            gizmoBtn.BackgroundColor3 = C.red
            gizmoBtn.BackgroundTransparency = 0.7
        end
    end)

    local actionGrid = Instance.new("Frame", actionSection)
    actionGrid.Size = UDim2.new(1,-16,0,0)
    actionGrid.Position = UDim2.new(0,8,0,88)
    actionGrid.AutomaticSize = Enum.AutomaticSize.Y
    actionGrid.BackgroundTransparency = 1

    local gridLayout = Instance.new("UIGridLayout", actionGrid)
    gridLayout.CellSize = UDim2.new(0.5,-4,0,36)
    gridLayout.CellPadding = UDim2.new(0,6,0,6)
    gridLayout.FillDirection = Enum.FillDirection.Vertical
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local function makeActionButton(text, callback, color)
        color = color or C.accent
        local btn = Instance.new("TextButton", actionGrid)
        btn.Size = UDim2.new(1,0,1,0)
        btn.BackgroundColor3 = color
        btn.BackgroundTransparency = 0.85
        btn.Text = text
        btn.TextColor3 = C.text
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.AutoButtonColor = false
        corner(btn, 8)
        stroke(btn, color, 1, 0.5)
        pressFX(btn)

        btn.MouseButton1Click:Connect(function()
            local uid = getSelectedUserId()
            if not uid then
                _G.showDynamicNotification("Pilih clone terlebih dahulu!", C.gold)
                return
            end
            callback(uid)
        end)
        return btn
    end

    -- Tombol aksi sesuai gambar
    makeActionButton("📍 Posisi", function(uid)
        fireRemote("pos", uid)
        _G.showDynamicNotification("Posisi disesuaikan", C.accent)
    end)

    makeActionButton("🔄 Putar", function(uid)
        fireRemote("rot", uid)
        _G.showDynamicNotification("Rotasi diterapkan", C.accent)
    end)

    makeActionButton("💃 Mode Tari", function(uid)
        fireRemote("dance", uid)
        _G.showDynamicNotification("Mode tari aktif", C.accent)
    end)

    makeActionButton("🤝 Pegang", function(uid)
        fireRemote("hold", uid)
        _G.showDynamicNotification("Pegangan aktif", C.accent)
    end)

    makeActionButton("↩ Batalkan", function(uid)
        fireRemote("undo", uid)
        _G.showDynamicNotification("Undo berhasil", C.gold)
    end)

    makeActionButton("↪ Ulangi", function(uid)
        fireRemote("redo", uid)
        _G.showDynamicNotification("Redo berhasil", C.gold)
    end)

    makeActionButton("🔄 Reset Posisi", function(uid)
        fireRemote("resetpos", uid)
        _G.showDynamicNotification("Posisi di-reset", C.red)
    end, C.red)

    makeActionButton("🔄 Reset Rotasi", function(uid)
        fireRemote("resetrot", uid)
        _G.showDynamicNotification("Rotasi di-reset", C.red)
    end, C.red)

    makeActionButton("🗑 Hapus Klon", function(uid)
        fireRemote("deleteclone", uid)
        for i, info in ipairs(cloneList) do
            if info.userId == uid then
                table.remove(cloneList, i)
                if selectedCloneIndex == i then selectedCloneIndex = nil end
                break
            end
        end
        if gizmoActive and targetUserId == uid then
            hideGizmo()
        end
        renderCloneList(listContainer)
        _G.showDynamicNotification("Klon dihapus", C.red)
    end, C.red)

    makeActionButton("🗑 Hapus Semua", function()
        if #cloneList == 0 then
            _G.showDynamicNotification("Tidak ada clone", C.text3)
            return
        end
        fireRemote("deleteall")
        cloneList = {}
        selectedCloneIndex = nil
        hideGizmo()
        renderCloneList(listContainer)
        _G.showDynamicNotification("Semua clone dihapus", C.red)
    end, C.red)

    makeActionButton("🔄 Reset Karakter", function()
        fireRemote("resetchar")
        _G.showDynamicNotification("Karakter di-reset", C.green)
    end, C.green)

    -- ===== BAGIAN LOAD PEMAIN =====
    local loadSection = Instance.new("Frame", content)
    loadSection.Size = UDim2.new(1,0,0,0)
    loadSection.AutomaticSize = Enum.AutomaticSize.Y
    loadSection.BackgroundColor3 = C.card2
    loadSection.LayoutOrder = 3
    corner(loadSection, 12)
    stroke(loadSection, C.border, 1, 0.4)

    local loadTitle = Instance.new("TextLabel", loadSection)
    loadTitle.Size = UDim2.new(1,-20,0,26)
    loadTitle.Position = UDim2.new(0,10,0,4)
    loadTitle.BackgroundTransparency = 1
    loadTitle.Text = "👤 Load Pemain Lain"
    loadTitle.TextColor3 = C.text
    loadTitle.Font = Enum.Font.GothamBold
    loadTitle.TextSize = 12
    loadTitle.TextXAlignment = Enum.TextXAlignment.Left

    local loadFrame = Instance.new("Frame", loadSection)
    loadFrame.Size = UDim2.new(1,-16,0,40)
    loadFrame.Position = UDim2.new(0,8,0,34)
    loadFrame.BackgroundColor3 = C.bg
    corner(loadFrame, 10)
    stroke(loadFrame, C.border, 1, 0.4)

    local loadInput = Instance.new("TextBox", loadFrame)
    loadInput.Size = UDim2.new(1,-90,1,0)
    loadInput.Position = UDim2.new(0,8,0,0)
    loadInput.BackgroundTransparency = 1
    loadInput.PlaceholderText = "Nama pengguna atau User ID"
    loadInput.PlaceholderColor3 = C.text3
    loadInput.Text = ""
    loadInput.TextColor3 = C.text
    loadInput.Font = Enum.Font.Gotham
    loadInput.TextSize = 11
    loadInput.TextXAlignment = Enum.TextXAlignment.Left
    loadInput.ClearTextOnFocus = false

    local loadBtn = Instance.new("TextButton", loadFrame)
    loadBtn.Size = UDim2.new(0,72,0,30)
    loadBtn.Position = UDim2.new(1,-78,0.5,-15)
    loadBtn.BackgroundColor3 = C.green
    loadBtn.Text = "Load"
    loadBtn.TextColor3 = Color3.new(0,0,0)
    loadBtn.Font = Enum.Font.GothamBold
    loadBtn.TextSize = 11
    loadBtn.AutoButtonColor = false
    corner(loadBtn, 8)
    pressFX(loadBtn)

    loadBtn.MouseButton1Click:Connect(function()
        local input = loadInput.Text:gsub("%s+", "")
        if input == "" then
            _G.showDynamicNotification("Masukkan nama atau ID", C.gold)
            return
        end

        local targetPlayer = nil
        if tonumber(input) then
            targetPlayer = Players:GetPlayerByUserId(tonumber(input))
        else
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Name:lower():find(input:lower()) then
                    targetPlayer = p
                    break
                end
            end
        end

        if not targetPlayer then
            _G.showDynamicNotification("Pemain tidak ditemukan", C.red)
            return
        end

        local uid = targetPlayer.UserId
        for _, info in ipairs(cloneList) do
            if info.userId == uid then
                _G.showDynamicNotification("Sudah ada di daftar", C.gold)
                return
            end
        end

        -- Kirim perintah clone
        fireRemote("clone", uid)
        table.insert(cloneList, {userId = uid, name = targetPlayer.DisplayName, isClone = true})
        selectedCloneIndex = #cloneList
        renderCloneList(listContainer)
        _G.showDynamicNotification("Mengklone avatar " .. targetPlayer.DisplayName, C.green)

        -- Auto tampilkan gizmo
        task.wait(0.2)
        showGizmo(uid)
        startGizmoHeartbeat()
        gizmoBtn.Text = "❌ Sembunyikan Gizmo"
        gizmoBtn.BackgroundColor3 = C.red
        gizmoBtn.BackgroundTransparency = 0.7
    end)

    -- ===== DEMO: tambahkan beberapa clone contoh =====
    if #cloneList == 0 then
        table.insert(cloneList, {userId = 10164114772, name = "Alfread (Dev)", isClone = true})
        table.insert(cloneList, {userId = 123456789, name = "Klon", isClone = true})
        selectedCloneIndex = 1
        renderCloneList(listContainer)

        -- Auto tampilkan gizmo untuk clone pertama
        task.wait(0.5)
        showGizmo(10164114772)
        startGizmoHeartbeat()
        gizmoBtn.Text = "❌ Sembunyikan Gizmo"
        gizmoBtn.BackgroundColor3 = C.red
        gizmoBtn.BackgroundTransparency = 0.7
    end

    -- ===== FOOTER =====
    local footer = Instance.new("TextLabel", content)
    footer.Size = UDim2.new(1,0,0,20)
    footer.BackgroundTransparency = 1
    footer.Text = "v1.0 · Studio Lumiere"
    footer.TextColor3 = C.text3
    footer.Font = Enum.Font.Gotham
    footer.TextSize = 8
    footer.LayoutOrder = 4
    footer.TextXAlignment = Enum.TextXAlignment.Center
end

print("[MyClone] Loaded! Dengan Gizmo 3D panah merah/hijau/biru.")