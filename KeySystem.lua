-- ================================================================
-- KEY SYSTEM (LICENSE GATE) — CloneBunker / PhoneIDViewer
-- Pastikan Firebase helpers (firebaseGet/Set/Delete) & LocalPlayer
-- sudah di-load sebelum file ini.
-- ================================================================

local KEY_CHECK_ROOT = "/keys"
local USER_KEY_ROOT  = "/user_keys"

local DURATION_SECONDS = {
    ["3d"]  = 3  * 24 * 60 * 60,
    ["7d"]  = 7  * 24 * 60 * 60,
    ["30d"] = 30 * 24 * 60 * 60,
}

-- ================= VALIDASI / BIND KEY =================
local function tryActivateKey(code)
    code = tostring(code or ""):upper():gsub("%s+", "")
    if code == "" then
        return false, "Key tidak boleh kosong."
    end

    local keyData = firebaseGet(KEY_CHECK_ROOT .. "/" .. code)
    if not keyData or type(keyData) ~= "table" then
        return false, "Key tidak ditemukan. Cek kembali kode kamu."
    end

    local now = os.time()

    if keyData.used then
        if tostring(keyData.boundUserId) == tostring(LocalPlayer.UserId) then
            if keyData.expiresAt and now > keyData.expiresAt then
                return false, "Key kamu sudah expired. Silakan beli key baru."
            end
            return true, "Key valid, selamat datang kembali!", keyData.expiresAt
        else
            return false, "Key ini sudah dipakai oleh pemain lain."
        end
    end

    local durationSecs = DURATION_SECONDS[keyData.duration] or (7 * 24 * 60 * 60)
    local expiresAt    = now + durationSecs

    firebaseSet(KEY_CHECK_ROOT .. "/" .. code, {
        duration      = keyData.duration,
        durationDays  = keyData.durationDays,
        durationLabel = keyData.durationLabel,
        createdAt     = keyData.createdAt,
        used          = true,
        boundUserId   = LocalPlayer.UserId,
        boundUsername = LocalPlayer.Name,
        activatedAt   = now,
        expiresAt     = expiresAt,
    })

    firebaseSet(USER_KEY_ROOT .. "/" .. tostring(LocalPlayer.UserId), {
        code          = code,
        expiresAt     = expiresAt,
        durationLabel = keyData.durationLabel,
    })

    return true, "Key berhasil diaktifkan! Selamat menikmati.", expiresAt
end

-- ================= CEK KEY AKTIF (AUTO-LOGIN) =================
local function checkExistingAccess()
    local userKey = firebaseGet(USER_KEY_ROOT .. "/" .. tostring(LocalPlayer.UserId))
    if userKey and type(userKey) == "table" and userKey.code then
        local keyData = firebaseGet(KEY_CHECK_ROOT .. "/" .. userKey.code)
        if keyData and type(keyData) == "table" and keyData.expiresAt then
            if os.time() <= keyData.expiresAt then
                return true, keyData.expiresAt
            end
        end
    end
    return false, nil
end

-- ================= FORMAT SISA WAKTU =================
local function formatTimeLeft(expiresAt)
    local diff = expiresAt - os.time()
    if diff <= 0 then return "Expired" end
    local days  = math.floor(diff / 86400)
    local hours = math.floor((diff % 86400) / 3600)
    if days > 0 then
        return string.format("%dh %djam lagi", days, hours)
    else
        local mins = math.floor((diff % 3600) / 60)
        return string.format("%djam %dmenit lagi", hours, mins)
    end
end

-- ================= HELPER LOKAL (corner/stroke) =================
local function corner_(inst, r)
    if corner then return corner(inst, r) end
    if _G.Helpers then return _G.Helpers.corner(inst, r) end
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = inst
    return c
end

local function stroke_(inst, color, thickness, transparency)
    if stroke then return stroke(inst, color, thickness, transparency) end
    if _G.Helpers then return _G.Helpers.stroke(inst, color, thickness, transparency) end
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1.5
    s.Transparency = transparency or 0
    s.Parent = inst
    return s
end

-- ================= UI KEY GATE =================
local function showKeyGateUI(onSuccess)
    local CoreGui = game:GetService("CoreGui")
    local gui = Instance.new("ScreenGui")
    gui.Name = "PhoneIDViewerKeyGate"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 9999
    pcall(function()
        gui.Parent = (gethui and gethui()) or CoreGui
    end)
    if not gui.Parent then gui.Parent = CoreGui end

    -- Dim backdrop
    local dim = Instance.new("Frame", gui)
    dim.Size = UDim2.new(1, 0, 1, 0)
    dim.BackgroundColor3 = Color3.fromRGB(6, 6, 8)
    dim.BackgroundTransparency = 0.08
    dim.ZIndex = 100

    -- Card
    local card = Instance.new("Frame", gui)
    card.Size = UDim2.new(0, 320, 0, 310)
    card.Position = UDim2.new(0.5, -160, 0.5, -155)
    card.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
    card.ZIndex = 101
    corner_(card, 18)
    stroke_(card, Color3.fromRGB(70, 70, 78), 1.3, 0.2)

    -- Glow line top
    local glowLine = Instance.new("Frame", card)
    glowLine.Size = UDim2.new(1, 0, 0, 2)
    glowLine.BackgroundColor3 = Color3.fromRGB(125, 211, 252)
    glowLine.BorderSizePixel = 0
    glowLine.ZIndex = 102
    corner_(glowLine, 1)

    -- Badge ikon
    local badge = Instance.new("Frame", card)
    badge.Size = UDim2.new(0, 56, 0, 56)
    badge.Position = UDim2.new(0.5, -28, 0, 22)
    badge.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    badge.ZIndex = 102
    corner_(badge, 16)
    stroke_(badge, Color3.fromRGB(125, 211, 252), 1.2, 0.35)

    local badgeIcon = Instance.new("TextLabel", badge)
    badgeIcon.Size = UDim2.new(1, 0, 1, 0)
    badgeIcon.BackgroundTransparency = 1
    badgeIcon.Text = "🔑"
    badgeIcon.TextSize = 24
    badgeIcon.ZIndex = 103

    -- Title
    local title = Instance.new("TextLabel", card)
    title.Size = UDim2.new(1, -32, 0, 24)
    title.Position = UDim2.new(0, 16, 0, 88)
    title.BackgroundTransparency = 1
    title.Text = "Phone ID Viewer"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 17
    title.ZIndex = 102

    local sub = Instance.new("TextLabel", card)
    sub.Size = UDim2.new(1, -32, 0, 36)
    sub.Position = UDim2.new(0, 16, 0, 114)
    sub.BackgroundTransparency = 1
    sub.Text = "Masukkan key untuk membuka akses.\nBeli key di discord / tanya alfread."
    sub.TextColor3 = Color3.fromRGB(155, 155, 165)
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 11
    sub.TextWrapped = true
    sub.ZIndex = 102

    -- Input box
    local inputFrame = Instance.new("Frame", card)
    inputFrame.Size = UDim2.new(1, -32, 0, 44)
    inputFrame.Position = UDim2.new(0, 16, 0, 158)
    inputFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    inputFrame.ZIndex = 102
    corner_(inputFrame, 12)
    stroke_(inputFrame, Color3.fromRGB(50, 50, 58), 1, 0.2)

    local keyInput = Instance.new("TextBox", inputFrame)
    keyInput.Size = UDim2.new(1, -20, 1, 0)
    keyInput.Position = UDim2.new(0, 10, 0, 0)
    keyInput.BackgroundTransparency = 1
    keyInput.PlaceholderText = "CBK-XXXX-XXXX"
    keyInput.PlaceholderColor3 = Color3.fromRGB(80, 80, 90)
    keyInput.Text = ""
    keyInput.TextColor3 = Color3.new(1, 1, 1)
    keyInput.Font = Enum.Font.Code
    keyInput.TextSize = 14
    keyInput.TextXAlignment = Enum.TextXAlignment.Left
    keyInput.ClearTextOnFocus = false
    keyInput.ZIndex = 103

    -- Status label
    local statusLbl = Instance.new("TextLabel", card)
    statusLbl.Size = UDim2.new(1, -32, 0, 28)
    statusLbl.Position = UDim2.new(0, 16, 0, 208)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text = ""
    statusLbl.TextColor3 = Color3.fromRGB(245, 145, 154)
    statusLbl.Font = Enum.Font.GothamBold
    statusLbl.TextSize = 11
    statusLbl.TextWrapped = true
    statusLbl.ZIndex = 102

    -- Submit button
    local submitBtn = Instance.new("TextButton", card)
    submitBtn.Size = UDim2.new(1, -32, 0, 44)
    submitBtn.Position = UDim2.new(0, 16, 1, -58)
    submitBtn.BackgroundColor3 = Color3.fromRGB(125, 211, 252)
    submitBtn.Text = "Aktifkan Key"
    submitBtn.TextColor3 = Color3.fromRGB(8, 18, 24)
    submitBtn.Font = Enum.Font.GothamBlack
    submitBtn.TextSize = 13
    submitBtn.AutoButtonColor = false
    submitBtn.ZIndex = 102
    corner_(submitBtn, 12)

    local checking = false
    local function attemptSubmit()
        if checking then return end
        local code = keyInput.Text
        if not code or code:match("^%s*$") then
            statusLbl.TextColor3 = Color3.fromRGB(245, 145, 154)
            statusLbl.Text = "Masukkan key dulu."
            return
        end

        checking = true
        submitBtn.Text = "Memeriksa..."
        submitBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
        statusLbl.TextColor3 = Color3.fromRGB(155, 155, 165)
        statusLbl.Text = "Menghubungi server..."

        task.spawn(function()
            local ok, msg, expiresAt = tryActivateKey(code)
            checking = false

            if ok then
                statusLbl.TextColor3 = Color3.fromRGB(110, 231, 183)
                statusLbl.Text = msg
                submitBtn.Text = "✓ Berhasil!"
                submitBtn.BackgroundColor3 = Color3.fromRGB(110, 231, 183)
                task.wait(0.7)
                pcall(function() gui:Destroy() end)
                if onSuccess then onSuccess(expiresAt) end
            else
                statusLbl.TextColor3 = Color3.fromRGB(245, 145, 154)
                statusLbl.Text = msg
                submitBtn.Text = "Aktifkan Key"
                submitBtn.BackgroundColor3 = Color3.fromRGB(125, 211, 252)
            end
        end)
    end

    submitBtn.MouseButton1Click:Connect(attemptSubmit)
    keyInput.FocusLost:Connect(function(enter) if enter then attemptSubmit() end end)
end

-- ================= ENTRY POINT =================
function requireValidKey(onDone)
    task.spawn(function()
        local hasAccess, expiresAt = checkExistingAccess()
        if hasAccess then
            print("[PhoneIDViewer] Key aktif, sisa: " .. formatTimeLeft(expiresAt))
            onDone(true)
            return
        end
        showKeyGateUI(function()
            onDone(true)
        end)
    end)
end

print("[PhoneIDViewer] Key system loaded.")