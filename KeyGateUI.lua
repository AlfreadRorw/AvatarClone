-- ================================================================
-- KEY GATE UI — Popup input key untuk PhoneIDViewer / CloneBunker
-- Butuh: tryActivateKey(code) dari KeySystem.lua
-- Helper yang dipakai: corner(inst, radius), stroke(inst, color, thickness, transparency)
-- Kalau helper itu belum ada secara global, definisi fallback disediakan di bawah.
-- ================================================================

-- ================= FALLBACK HELPER (kalau belum global) =================
if not corner then
    function corner(inst, radius)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, radius or 8)
        c.Parent = inst
        return c
    end
end

if not stroke then
    function stroke(inst, color, thickness, transparency)
        local s = Instance.new("UIStroke")
        s.Color = color or Color3.fromRGB(60, 60, 68)
        s.Thickness = thickness or 1
        s.Transparency = transparency or 0
        s.Parent = inst
        return s
    end
end

-- ================= ENTRY POINT =================
function showKeyGateUI(onSuccess)
    local TS = game:GetService("TweenService")
    local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

    -- Cegah dobel popup kalau dipanggil 2x
    local existing = PlayerGui:FindFirstChild("KeyGateUI")
    if existing then existing:Destroy() end

    local gateGui = Instance.new("ScreenGui")
    gateGui.Name = "KeyGateUI"
    gateGui.IgnoreGuiInset = true
    gateGui.ResetOnSpawn = false
    gateGui.DisplayOrder = 999
    gateGui.Parent = PlayerGui

    -- Overlay gelap full-screen
    local overlay = Instance.new("Frame", gateGui)
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 1
    overlay.ZIndex = 100

    TS:Create(overlay, TweenInfo.new(0.25), {BackgroundTransparency = 0.45}):Play()

    -- Card utama
    local card = Instance.new("Frame", gateGui)
    card.Size = UDim2.new(0, 340, 0, 300)
    card.Position = UDim2.new(0.5, -170, 0.5, -160)
    card.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    card.ZIndex = 101
    card.ClipsDescendants = true
    corner(card, 20)
    stroke(card, Color3.fromRGB(50, 50, 58), 1.5, 0)

    -- Animasi masuk (scale-ish via position/transparency, aman tanpa UIScale)
    card.Position = UDim2.new(0.5, -170, 0.55, -160)
    card.BackgroundTransparency = 1
    for _, d in ipairs(card:GetDescendants()) do end
    TS:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -170, 0.5, -160),
        BackgroundTransparency = 0,
    }):Play()

    -- Bar hijau atas
    local topBar = Instance.new("Frame", card)
    topBar.Size = UDim2.new(1, 0, 0, 4)
    topBar.BackgroundColor3 = Color3.fromRGB(0, 132, 255)
    topBar.ZIndex = 102

    -- Icon gembok
    local iconFrame = Instance.new("Frame", card)
    iconFrame.Size = UDim2.new(0, 52, 0, 52)
    iconFrame.Position = UDim2.new(0.5, -26, 0, 22)
    iconFrame.BackgroundColor3 = Color3.fromRGB(0, 132, 255)
    iconFrame.BackgroundTransparency = 0.85
    iconFrame.ZIndex = 102
    corner(iconFrame, 100)

    local iconLbl = Instance.new("TextLabel", iconFrame)
    iconLbl.Size = UDim2.new(1, 0, 1, 0)
    iconLbl.BackgroundTransparency = 1
    iconLbl.Text = "🔑"
    iconLbl.TextSize = 22
    iconLbl.ZIndex = 103
    iconLbl.Font = Enum.Font.Gotham

    -- Judul
    local titleLbl = Instance.new("TextLabel", card)
    titleLbl.Size = UDim2.new(1, -40, 0, 24)
    titleLbl.Position = UDim2.new(0, 20, 0, 82)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "Masukkan Key Akses"
    titleLbl.TextColor3 = Color3.new(1, 1, 1)
    titleLbl.Font = Enum.Font.GothamBlack
    titleLbl.TextSize = 17
    titleLbl.ZIndex = 102

    -- Subjudul
    local subLbl = Instance.new("TextLabel", card)
    subLbl.Size = UDim2.new(1, -40, 0, 18)
    subLbl.Position = UDim2.new(0, 20, 0, 108)
    subLbl.BackgroundTransparency = 1
    subLbl.Text = "Key diperlukan untuk mengakses fitur ini"
    subLbl.TextColor3 = Color3.fromRGB(150, 150, 158)
    subLbl.Font = Enum.Font.Gotham
    subLbl.TextSize = 11
    subLbl.ZIndex = 102

    -- Input box
    local inputWrap = Instance.new("Frame", card)
    inputWrap.Size = UDim2.new(1, -40, 0, 42)
    inputWrap.Position = UDim2.new(0, 20, 0, 136)
    inputWrap.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    inputWrap.ZIndex = 102
    corner(inputWrap, 12)
    stroke(inputWrap, Color3.fromRGB(50, 50, 58), 1.5, 0)

    local keyInput = Instance.new("TextBox", inputWrap)
    keyInput.Size = UDim2.new(1, -20, 1, 0)
    keyInput.Position = UDim2.new(0, 10, 0, 0)
    keyInput.BackgroundTransparency = 1
    keyInput.PlaceholderText = "Masukkan kode key di sini..."
    keyInput.PlaceholderColor3 = Color3.fromRGB(95, 95, 102)
    keyInput.Text = ""
    keyInput.TextColor3 = Color3.new(1, 1, 1)
    keyInput.Font = Enum.Font.GothamBold
    keyInput.TextSize = 13
    keyInput.TextXAlignment = Enum.TextXAlignment.Left
    keyInput.ClearTextOnFocus = false
    keyInput.ZIndex = 103

    -- Pesan error/status (tersembunyi awal)
    local statusLbl = Instance.new("TextLabel", card)
    statusLbl.Size = UDim2.new(1, -40, 0, 16)
    statusLbl.Position = UDim2.new(0, 20, 0, 182)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text = ""
    statusLbl.TextColor3 = Color3.fromRGB(255, 90, 90)
    statusLbl.Font = Enum.Font.GothamBold
    statusLbl.TextSize = 10
    statusLbl.TextWrapped = true
    statusLbl.TextXAlignment = Enum.TextXAlignment.Left
    statusLbl.ZIndex = 102

    -- Tombol Aktifkan
    local activateBtn = Instance.new("TextButton", card)
    activateBtn.Size = UDim2.new(1, -40, 0, 44)
    activateBtn.Position = UDim2.new(0, 20, 0, 204)
    activateBtn.BackgroundColor3 = Color3.fromRGB(0, 132, 255)
    activateBtn.Text = "Aktifkan"
    activateBtn.TextColor3 = Color3.new(1, 1, 1)
    activateBtn.Font = Enum.Font.GothamBlack
    activateBtn.TextSize = 14
    activateBtn.AutoButtonColor = false
    activateBtn.ZIndex = 102
    corner(activateBtn, 12)

    -- Tombol Beli Key (link, cuma info dulu)
    local buyBtn = Instance.new("TextButton", card)
    buyBtn.Size = UDim2.new(1, -40, 0, 30)
    buyBtn.Position = UDim2.new(0, 20, 0, 256)
    buyBtn.BackgroundTransparency = 1
    buyBtn.Text = "Belum punya key? Beli Key"
    buyBtn.TextColor3 = Color3.fromRGB(120, 170, 255)
    buyBtn.Font = Enum.Font.GothamBold
    buyBtn.TextSize = 11
    buyBtn.ZIndex = 102

    -- ================= LOGIC =================
    local isProcessing = false

    local function setStatus(text, isError)
        statusLbl.Text = text or ""
        statusLbl.TextColor3 = isError and Color3.fromRGB(255, 90, 90) or Color3.fromRGB(90, 220, 140)
    end

    local function closeGate()
        TS:Create(overlay, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
        local tw = TS:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -170, 0.55, -160),
            BackgroundTransparency = 1,
        })
        tw:Play()
        tw.Completed:Wait()
        pcall(function() gateGui:Destroy() end)
    end

    local function doActivate()
        if isProcessing then return end
        local code = keyInput.Text
        if not code or code:match("^%s*$") then
            setStatus("Key tidak boleh kosong.", true)
            return
        end

        isProcessing = true
        activateBtn.Text = "Memeriksa..."
        activateBtn.BackgroundColor3 = Color3.fromRGB(60, 70, 85)
        setStatus("", false)

        task.spawn(function()
            local ok, success, msg = pcall(tryActivateKey, code)
            isProcessing = false

            if not ok then
                activateBtn.Text = "Aktifkan"
                activateBtn.BackgroundColor3 = Color3.fromRGB(0, 132, 255)
                setStatus("Terjadi kesalahan, coba lagi.", true)
                return
            end

            if success then
                activateBtn.Text = "Berhasil ✓"
                activateBtn.BackgroundColor3 = Color3.fromRGB(0, 190, 100)
                setStatus(msg or "Key berhasil diaktifkan!", false)
                task.wait(0.8)
                closeGate()
                if onSuccess then onSuccess() end
            else
                activateBtn.Text = "Aktifkan"
                activateBtn.BackgroundColor3 = Color3.fromRGB(0, 132, 255)
                setStatus(msg or "Key tidak valid.", true)
            end
        end)
    end

    activateBtn.MouseButton1Click:Connect(doActivate)
    keyInput.FocusLost:Connect(function(enter)
        if enter then doActivate() end
    end)

    buyBtn.MouseButton1Click:Connect(function()
        setStatus("Hubungi admin/Discord untuk membeli key.", false)
    end)
end

print("[KeyGateUI] Loaded.")
