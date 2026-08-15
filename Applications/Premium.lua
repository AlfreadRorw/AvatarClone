-- ================================================
-- PREMIUM APP - Exclusive Control Panel
-- Fitur: Remote Teleport, TP-On-Tap, Cross-Server Join
-- ================================================

local Services       = _G.Services
local LocalPlayer    = _G.LocalPlayer
local Firebase       = _G.Firebase
local Config         = _G.Config or {}
local Helpers        = _G.Helpers or {}
local T              = _G.T or {}
local appContent     = _G.appContent

local UIS            = Services.UserInputService
local Workspace      = Services.Workspace

-- ==================== STATE MANAGEMENT ====================
local selectedTargetId = nil
local selectedTargetName = "Pilih Player"
local tpOnTapActive = false
local tapConnection = nil

-- ==================== ACCESS VALIDATION ====================
local function hasAccess()
    if LocalPlayer.UserId == (Config.DEVELOPER_USER_ID or 10164114772) then return true end
    if Firebase and Firebase.IsPermanentUser then
        return Firebase.IsPermanentUser(LocalPlayer.UserId)
    end
    return false
end

-- Export fungsi ini supaya Icons.lua bisa mengecek status gembok
_G.hasPremiumAccess = hasAccess

-- ==================== TP-ON-TAP LOGIC ====================
local function setupTapListener(state)
    tpOnTapActive = state
    
    if tapConnection then
        tapConnection:Disconnect()
        tapConnection = nil
    end

    if tpOnTapActive then
        _G.showDynamicNotification("TP On-Tap: AKTIF! Sentuh layar untuk memindahkan target.", Color3.fromRGB(168, 100, 255))
        
        tapConnection = UIS.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed or not selectedTargetId then return end
            
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                local pos = input.Position
                local cam = Workspace.CurrentCamera
                local ray = cam:ScreenPointToRay(pos.X, pos.Y)
                
                local params = RaycastParams.new()
                params.FilterDescendantsInstances = {LocalPlayer.Character}
                params.FilterType = Enum.RaycastFilterType.Exclude

                local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
                
                if result then
                    local hitPos = result.Position
                    
                    -- Kirim perintah Teleport Point ke Firebase
                    local cmdData = {
                        type = "teleport_to_point",
                        x = hitPos.X,
                        y = hitPos.Y + 3.5, -- Offset supaya tidak nyangkut di tanah
                        z = hitPos.Z,
                        fromPlaceId = game.PlaceId,
                        fromJobId = game.JobId,
                        timestamp = os.time()
                    }
                    
                    pcall(function()
                        Firebase.PushCommand(selectedTargetId, cmdData)
                    end)
                    
                    -- Visual Effect kecil di layar dev
                    local part = Instance.new("Part")
                    part.Size = Vector3.new(2, 0.2, 2)
                    part.Position = hitPos
                    part.Anchored = true
                    part.CanCollide = false
                    part.Material = Enum.Material.Neon
                    part.Color = Color3.fromRGB(168, 100, 255)
                    part.Parent = Workspace
                    Helpers.corner(part, 100) -- Jika GUI, tapi untuk 3D pakai Cylinder/Ball
                    part.Shape = Enum.PartType.Cylinder
                    
                    task.delay(1.5, function() part:Destroy() end)
                    
                    _G.showDynamicNotification("📍 Target dikirim ke koordinat!", Color3.fromRGB(168, 100, 255))
                end
            end
        end)
    else
        _G.showDynamicNotification("TP On-Tap: NONAKTIF", Color3.fromRGB(200, 200, 200))
    end
end

-- ==================== UI BUILDER HELPERS ====================
local function createSection(title, order)
    local sec = Instance.new("Frame")
    sec.Size = UDim2.new(1, 0, 0, 0)
    sec.AutomaticSize = Enum.AutomaticSize.Y
    sec.BackgroundTransparency = 1
    sec.LayoutOrder = order
    sec.Parent = appContent

    local lay = Instance.new("UIListLayout", sec)
    lay.Padding = UDim.new(0, 6)
    lay.SortOrder = Enum.SortOrder.LayoutOrder

    local lbl = Instance.new("TextLabel", sec)
    lbl.Size = UDim2.new(1, -8, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Text = title
    lbl.TextColor3 = Color3.fromRGB(100, 100, 115)
    lbl.Font = Enum.Font.GothamBlack
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    return sec
end

local function createCard(parent)
    local c = Instance.new("Frame")
    c.Size = UDim2.new(1, 0, 0, 0)
    c.AutomaticSize = Enum.AutomaticSize.Y
    c.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    c.Parent = parent
    Helpers.corner(c, 14)
    Helpers.stroke(c, Color3.fromRGB(220, 220, 228), 1, 0.3)

    local lay = Instance.new("UIListLayout", c)
    lay.Padding = UDim.new(0, 0)
    lay.SortOrder = Enum.SortOrder.LayoutOrder

    local pad = Instance.new("UIPadding", c)
    pad.PaddingTop = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)
    pad.PaddingLeft = UDim.new(0, 12)
    pad.PaddingRight = UDim.new(0, 12)

    return c
end

-- ==================== MAIN APP UI ====================
function _G.openPremiumApp()
    -- 1. GATE KEEPER: Validasi Akses
    if not hasAccess() then
        _G.showDynamicNotification("Akses Ditolak! App khusus Key Permanen.", Color3.fromRGB(255, 70, 70))
        if _G.goHome then _G.goHome() end
        return
    end

    -- Reset state saat dibuka ulang
    selectedTargetId = nil
    selectedTargetName = "Belum Ada Target"
    if tpOnTapActive then setupTapListener(false) end

    -- 2. KONTROL PANEL DEV
    local ctrlSec = createSection("CONTROL PANEL (OVERRIDE)", 1)
    local ctrlCard = createCard(ctrlSec)

    -- Status Target Label
    local targetStatus = Instance.new("TextLabel", ctrlCard)
    targetStatus.Size = UDim2.new(1, 0, 0, 28)
    targetStatus.BackgroundTransparency = 1
    targetStatus.Text = "Target: " .. selectedTargetName
    targetStatus.TextColor3 = Color3.fromRGB(168, 100, 255)
    targetStatus.Font = Enum.Font.GothamBold
    targetStatus.TextSize = 13
    targetStatus.TextXAlignment = Enum.TextXAlignment.Left
    targetStatus.LayoutOrder = 1

    -- Separator
    local sep1 = Instance.new("Frame", ctrlCard)
    sep1.Size = UDim2.new(1, 0, 0, 1)
    sep1.BackgroundColor3 = Color3.fromRGB(220, 220, 228)
    sep1.LayoutOrder = 2

    -- Toggle TP On Tap
    local tapRow = Instance.new("Frame", ctrlCard)
    tapRow.Size = UDim2.new(1, 0, 0, 44)
    tapRow.BackgroundTransparency = 1
    tapRow.LayoutOrder = 3

    local tapLabel = Instance.new("TextLabel", tapRow)
    tapLabel.Size = UDim2.new(1, -60, 1, 0)
    tapLabel.BackgroundTransparency = 1
    tapLabel.Text = "Teleport On Tap 👆"
    tapLabel.TextColor3 = Color3.fromRGB(20, 20, 28)
    tapLabel.Font = Enum.Font.GothamBold
    tapLabel.TextSize = 12
    tapLabel.TextXAlignment = Enum.TextXAlignment.Left

    local tapToggleContainer = Instance.new("Frame", tapRow)
    tapToggleContainer.Size = UDim2.new(0, 46, 0, 26)
    tapToggleContainer.Position = UDim2.new(1, -46, 0.5, -13)
    tapToggleContainer.BackgroundTransparency = 1
    
    Helpers.buildToggle(tapToggleContainer, false, function(state)
        if state and not selectedTargetId then
            _G.showDynamicNotification("Pilih player target terlebih dahulu!", Color3.fromRGB(255, 70, 70))
            return false -- Idealnya toggle balik ke false, namun butuh penyesuaian di helper
        end
        setupTapListener(state)
    end)

    -- Separator
    local sep2 = Instance.new("Frame", ctrlCard)
    sep2.Size = UDim2.new(1, 0, 0, 1)
    sep2.BackgroundColor3 = Color3.fromRGB(220, 220, 228)
    sep2.LayoutOrder = 4

    -- Tombol Tarik Target Ke Dev
    local pullBtn = Instance.new("TextButton", ctrlCard)
    pullBtn.Size = UDim2.new(1, 0, 0, 36)
    pullBtn.BackgroundColor3 = Color3.fromRGB(168, 100, 255)
    pullBtn.Text = "Tarik Target Ke Saya (Cross-Server)"
    pullBtn.TextColor3 = Color3.new(1, 1, 1)
    pullBtn.Font = Enum.Font.GothamBold
    pullBtn.TextSize = 11
    pullBtn.AutoButtonColor = false
    pullBtn.LayoutOrder = 5
    Helpers.corner(pullBtn, 8)
    Helpers.pressFX(pullBtn)

    pullBtn.MouseButton1Click:Connect(function()
        if not selectedTargetId then
            _G.showDynamicNotification("Pilih target di bawah!", Color3.fromRGB(255, 70, 70))
            return
        end
        local cmdData = {
            type = "teleport_to_dev",
            devUserId = LocalPlayer.UserId,
            devPlaceId = game.PlaceId,
            devJobId = game.JobId,
            timestamp = os.time()
        }
        pcall(function() Firebase.PushCommand(selectedTargetId, cmdData) end)
        _G.showDynamicNotification("Perintah penarikan dikirim ke " .. selectedTargetName, Color3.fromRGB(168, 100, 255))
    end)


    -- 3. DAFTAR PLAYER ONLINE GLOBAL
    local listSec = createSection("GLOBAL SCRIPT USERS", 2)
    local listCard = createCard(listSec)

    local function refreshOnlinePlayers()
        for _, child in ipairs(listCard:GetChildren()) do
            if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
                child:Destroy()
            end
        end

        local loadingLbl = Instance.new("TextLabel", listCard)
        loadingLbl.Size = UDim2.new(1, 0, 0, 30)
        loadingLbl.BackgroundTransparency = 1
        loadingLbl.Text = "Memuat data Firebase..."
        loadingLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
        loadingLbl.Font = Enum.Font.Gotham
        loadingLbl.TextSize = 10

        task.spawn(function()
            local ok, players = pcall(function() return Firebase.GetOnlinePlayers() end)
            loadingLbl:Destroy()

            if not ok or not players then
                local err = Instance.new("TextLabel", listCard)
                err.Size = UDim2.new(1, 0, 0, 30)
                err.BackgroundTransparency = 1
                err.Text = "Gagal memuat atau kosong."
                err.TextColor3 = Color3.fromRGB(255, 70, 70)
                err.Font = Enum.Font.Gotham
                err.TextSize = 10
                return
            end

            local order = 1
            for uidStr, pData in pairs(players) do
                local uid = tonumber(uidStr)
                if uid == LocalPlayer.UserId then continue end -- Jangan munculkan diri sendiri

                local pRow = Instance.new("TextButton", listCard)
                pRow.Size = UDim2.new(1, 0, 0, 48)
                pRow.BackgroundTransparency = 1
                pRow.Text = ""
                pRow.LayoutOrder = order
                
                -- Avatar Mini
                local av = Instance.new("ImageLabel", pRow)
                av.Size = UDim2.new(0, 36, 0, 36)
                av.Position = UDim2.new(0, 0, 0.5, -18)
                av.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
                av.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. uidStr .. "&width=150&height=150&format=png"
                Helpers.corner(av, 100)

                -- Name Labels
                local nameLbl = Instance.new("TextLabel", pRow)
                nameLbl.Size = UDim2.new(1, -50, 0, 16)
                nameLbl.Position = UDim2.new(0, 46, 0, 6)
                nameLbl.BackgroundTransparency = 1
                nameLbl.Text = pData.username or ("User_" .. uidStr)
                nameLbl.TextColor3 = Color3.fromRGB(20, 20, 28)
                nameLbl.Font = Enum.Font.GothamBold
                nameLbl.TextSize = 12
                nameLbl.TextXAlignment = Enum.TextXAlignment.Left

                local mapLbl = Instance.new("TextLabel", pRow)
                mapLbl.Size = UDim2.new(1, -50, 0, 14)
                mapLbl.Position = UDim2.new(0, 46, 0, 24)
                mapLbl.BackgroundTransparency = 1
                mapLbl.Text = pData.mapName or "Unknown Map"
                mapLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
                mapLbl.Font = Enum.Font.Gotham
                mapLbl.TextSize = 9
                mapLbl.TextXAlignment = Enum.TextXAlignment.Left

                -- Seleksi Target
                pRow.MouseButton1Click:Connect(function()
                    selectedTargetId = uid
                    selectedTargetName = pData.username or tostring(uid)
                    targetStatus.Text = "Target: " .. selectedTargetName
                    
                    -- Reset tombol lain
                    for _, child in ipairs(listCard:GetChildren()) do
                        if child:IsA("TextButton") then
                            child.BackgroundTransparency = 1
                            Helpers.stroke(child, Color3.new(1,1,1), 0, 1)
                        end
                    end
                    
                    -- Highlight yang dipilih
                    pRow.BackgroundTransparency = 0.95
                    pRow.BackgroundColor3 = Color3.fromRGB(168, 100, 255)
                    Helpers.corner(pRow, 8)
                    Helpers.stroke(pRow, Color3.fromRGB(168, 100, 255), 1, 0)

                    _G.showDynamicNotification("Target diset: " .. selectedTargetName, Color3.fromRGB(168, 100, 255))
                end)

                order = order + 1
            end
        end)
    end

    refreshOnlinePlayers()
    
    -- Tombol Refresh Manual di bawah list
    local refBtn = Instance.new("TextButton", listSec)
    refBtn.Size = UDim2.new(1, 0, 0, 30)
    refBtn.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
    refBtn.Text = "🔄 Refresh Daftar"
    refBtn.TextColor3 = Color3.fromRGB(100, 100, 115)
    refBtn.Font = Enum.Font.GothamBold
    refBtn.TextSize = 10
    refBtn.LayoutOrder = 3
    Helpers.corner(refBtn, 8)
    Helpers.pressFX(refBtn)
    
    refBtn.MouseButton1Click:Connect(refreshOnlinePlayers)

end

print("[Premium] Aplikasi Premium Panel Dimuat!")
