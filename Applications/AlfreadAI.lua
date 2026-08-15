-- ================================================
-- ALFREADAI.LUA — Asisten AI "Alfread AI" (Groq)
-- Liquid Glass Design — frosted glass, blur-simulated, instant text render
-- ================================================

local Services    = _G.Services
local LocalPlayer = _G.LocalPlayer
local T           = _G.T or {}
local Helpers     = _G.Helpers or {}
local appContent  = _G.appContent
local Config      = _G.Config or {}
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local corner  = Helpers.corner
local stroke  = Helpers.stroke
local pressFX = Helpers.pressFX

-- ==================== KONFIGURASI GROQ ====================
local GROQ_API_KEY = "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"
local GROQ_MODEL   = "llama-3.3-70b-versatile"
local GROQ_URL     = "https://api.groq.com/openai/v1/chat/completions"

-- ==================== LIQUID GLASS PALETTE ====================
-- Bukan hitam pekat lagi. Dasar gelap kebiruan lembut + banyak transparansi
-- + highlight cahaya di tepi atas, meniru efek "frosted glass" iOS.
local C = {
    bgBase    = Color3.fromRGB(18, 20, 30),   -- dasar di belakang layer glass
    glass     = Color3.fromRGB(255, 255, 255), -- dipakai dengan transparansi tinggi
    glassCard = Color3.fromRGB(40, 42, 58),
    border    = Color3.fromRGB(255, 255, 255), -- stroke tipis putih transparan = kesan kaca
    text      = Color3.fromRGB(245, 246, 250),
    text2     = Color3.fromRGB(190, 192, 210),
    text3     = Color3.fromRGB(140, 142, 165),
    accent    = Color3.fromRGB(140, 130, 255),
    accent2   = Color3.fromRGB(100, 200, 255),
    green     = Color3.fromRGB(110, 235, 175),
    userBub   = Color3.fromRGB(120, 110, 255),
}

-- ==================== SYSTEM PROMPT ====================
local SYSTEM_PROMPT = [[
Kamu adalah "Alfread AI", asisten virtual resmi di dalam script Roblox bernama AvatarClone / PhoneIDViewer, dibuat oleh developer bernama Alfread (username Roblox: ]] .. (Config.DEVELOPER_USERNAME or "AlfreadR0rw") .. [[).

Kepribadianmu: ramah, santai tapi jelas, jawab dalam Bahasa Indonesia casual kecuali user menulis dalam bahasa lain. Jawaban ringkas, tidak bertele-tele, langsung ke inti — tapi tetap lengkap kalau user minta penjelasan detail.

Kamu HARUS mengerti dan bisa menjelaskan fitur-fitur berikut kepada user dengan akurat:

## SISTEM KEY
- Ada 4 jenis key: 3 Hari, 7 Hari, 30 Hari, dan Permanen (tidak pernah expired).
- Cara pakai: buka Phone, muncul layar "Masukkan Key", ketik kode key, tekan Unlock.
- Key hanya bisa dipakai satu akun (terikat ke UserId pertama yang memasukkannya).
- Kalau sudah pernah masuk key valid, buka Phone lagi otomatis langsung masuk (auto-login).
- Cek sisa waktu key di app Settings.

## DAFTAR APP
1. Players — daftar pemain di server.
2. Clone — fitur cloning avatar.
3. Messages — chat dengan Admin, bisa dibalas dari notifikasi langsung.
4. Settings — status key, profil developer, link social media.
5. Premium (👑) — khusus Key Permanen/Developer. TP ke Aku, TP-on-Tap lintas server.
6. Alfread AI (aku) — chat AI ini.

## ATURAN JAWAB
- Jelaskan langkah-langkah cara pakai fitur secara berurutan.
- Kalau ditanya soal Premium tapi user sepertinya bukan pemilik key permanen, jelaskan itu eksklusif dan sarankan hubungi admin.
- Jangan mengarang fitur yang tidak ada di daftar. Kalau tidak yakin, sarankan tanya ke Admin lewat app Messages.
- Kamu bukan sistem pembayaran — soal harga arahkan ke Settings > Buy Key.
- Jangan berpura-pura bisa mengeksekusi aksi di game — kamu hanya menjelaskan.
]]

-- ==================== STATE ====================
local chatHistory = {}
local isTyping = false
local chatScrollRef = nil

-- ==================== HTTP REQUEST KE GROQ ====================
local function callGroqAPI(messages, callback)
    local payload = {
        model = GROQ_MODEL,
        messages = messages,
        temperature = 0.7,
        max_tokens = 1024,
    }

    task.spawn(function()
        local ok, result = pcall(function()
            local opts = {
                Url = GROQ_URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"]  = "application/json",
                    ["Authorization"] = "Bearer " .. GROQ_API_KEY,
                },
                Body = HttpService:JSONEncode(payload),
            }
            if syn and syn.request then return syn.request(opts)
            elseif http_request then return http_request(opts)
            elseif request then return request(opts)
            else return HttpService:RequestAsync(opts) end
        end)

        if not ok or not result then
            callback(false, "Gagal terhubung ke server AI. Cek koneksi internet kamu.")
            return
        end

        local success = result.Success or (result.StatusCode and result.StatusCode < 300)
        if not success then
            local status = result.StatusCode or "?"
            local msg = "Server AI merespons error (kode " .. tostring(status) .. ")."
            if status == 401 then msg = "API key tidak valid. Hubungi developer." end
            if status == 429 then msg = "Terlalu banyak permintaan, coba lagi sebentar." end
            callback(false, msg)
            return
        end

        local dok, data = pcall(function()
            return HttpService:JSONDecode(result.Body or result.body or "")
        end)

        if not dok or not data or not data.choices or not data.choices[1] then
            callback(false, "Respons AI tidak bisa dibaca.")
            return
        end

        local reply = data.choices[1].message and data.choices[1].message.content
        if not reply then
            callback(false, "AI tidak memberikan balasan.")
            return
        end

        callback(true, reply)
    end)
end

-- ==================== GLASS PANEL HELPER ====================
-- Simulasi "liquid glass": layer semi-transparan + stroke tipis putih +
-- gradient highlight di sudut atas (seperti pantulan cahaya di kaca).
local function makeGlassPanel(parent, cornerRadius)
    local panel = Instance.new("Frame", parent)
    panel.BackgroundColor3 = C.glass
    panel.BackgroundTransparency = 0.88
    panel.BorderSizePixel = 0
    corner(panel, cornerRadius or 16)
    stroke(panel, C.border, 1, 0.75)

    -- Highlight gradient tipis di bagian atas, kesan cahaya memantul di kaca
    local grad = Instance.new("UIGradient", panel)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
        ColorSequenceKeypoint.new(0.4, Color3.new(1,1,1)),
        ColorSequenceKeypoint.new(1, Color3.new(1,1,1)),
    })
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.75),
        NumberSequenceKeypoint.new(0.35, 0.94),
        NumberSequenceKeypoint.new(1, 0.97),
    })
    grad.Rotation = 90

    return panel
end

-- ==================== RENDER BUBBLE (INSTANT TEXT, FADE-IN) ====================
local function renderChatBubble(parent, msg, order, animateIn)
    local isUser = msg.role == "user"

    local wrap = Instance.new("Frame", parent)
    wrap.Size = UDim2.new(1,0,0,0)
    wrap.AutomaticSize = Enum.AutomaticSize.Y
    wrap.BackgroundTransparency = 1
    wrap.LayoutOrder = order

    local bubble = Instance.new("Frame", wrap)
    bubble.AutomaticSize = Enum.AutomaticSize.Y
    bubble.Size = UDim2.new(0, 240, 0, 0)
    bubble.AnchorPoint = isUser and Vector2.new(1,0) or Vector2.new(0,0)
    bubble.Position = isUser and UDim2.new(1,0,0,0) or UDim2.new(0,0,0,0)
    bubble.BackgroundTransparency = 1 -- transparansi diatur lewat child glass di bawah
    bubble.ClipsDescendants = false

    -- Layer kaca di belakang teks
    if isUser then
        -- Bubble user: warna accent tapi tetap semi-transparan, kesan kaca berwarna
        local glassBg = Instance.new("Frame", bubble)
        glassBg.Size = UDim2.new(1,0,1,0)
        glassBg.BackgroundColor3 = C.userBub
        glassBg.BackgroundTransparency = 0.25
        glassBg.BorderSizePixel = 0
        glassBg.ZIndex = 0
        corner(glassBg, 16)
        stroke(glassBg, Color3.new(1,1,1), 1, 0.7)

        local ugrad = Instance.new("UIGradient", glassBg)
        ugrad.Color = ColorSequence.new(Color3.new(1,1,1))
        ugrad.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.6),
            NumberSequenceKeypoint.new(0.5, 0.92),
            NumberSequenceKeypoint.new(1, 0.96),
        })
        ugrad.Rotation = 90
    else
        makeGlassPanel(bubble, 16).ZIndex = 0
    end

    local pad = Instance.new("UIPadding", bubble)
    pad.PaddingTop = UDim.new(0,9); pad.PaddingBottom = UDim.new(0,9)
    pad.PaddingLeft = UDim.new(0,12); pad.PaddingRight = UDim.new(0,12)

    local lay = Instance.new("UIListLayout", bubble)
    lay.Padding = UDim.new(0,3)

    if not isUser then
        local tag = Instance.new("TextLabel", bubble)
        tag.Size = UDim2.new(1,0,0,13)
        tag.BackgroundTransparency = 1
        tag.Text = "✨ Alfread AI"
        tag.TextColor3 = C.accent2
        tag.Font = Enum.Font.GothamBlack
        tag.TextSize = 9
        tag.TextXAlignment = Enum.TextXAlignment.Left
        tag.LayoutOrder = 0
        tag.ZIndex = 1
    end

    -- ===== TEKS LANGSUNG DITAMPILKAN PENUH (TIDAK PER-HURUF) =====
    -- Ini bedanya dengan versi lama: msg.content di-set sekaligus ke .Text,
    -- bukan di-loop karakter demi karakter dengan task.wait(). Efek "muncul"
    -- cuma dari fade-in transparansi di seluruh bubble (animateIn di bawah),
    -- yang jauh lebih cepat dan terasa "instan" seperti AI chat modern.
    local textLbl = Instance.new("TextLabel", bubble)
    textLbl.Size = UDim2.new(1,0,0,0)
    textLbl.AutomaticSize = Enum.AutomaticSize.Y
    textLbl.BackgroundTransparency = 1
    textLbl.Text = msg.content
    textLbl.TextColor3 = C.text
    textLbl.Font = Enum.Font.Gotham
    textLbl.TextSize = 12
    textLbl.TextWrapped = true
    textLbl.TextXAlignment = Enum.TextXAlignment.Left
    textLbl.LayoutOrder = 1
    textLbl.ZIndex = 1
    textLbl.TextTransparency = 1 -- mulai invisible untuk fade-in

    -- Fade-in cepat (0.18 detik) — kesan halus tapi TIDAK lambat/ketik-per-huruf
    if animateIn then
        TweenService:Create(textLbl, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
            TextTransparency = 0
        }):Play()

        -- Bubble sendiri juga sedikit slide+fade biar terasa hidup
        bubble.Position = bubble.Position + UDim2.new(0, 0, 0, 6)
        local targetPos = isUser and UDim2.new(1,0,0,0) or UDim2.new(0,0,0,0)
        TweenService:Create(bubble, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = targetPos
        }):Play()
    else
        textLbl.TextTransparency = 0
    end

    return wrap
end

local function renderTypingBubble(parent, order)
    local wrap = Instance.new("Frame", parent)
    wrap.Name = "TypingBubble"
    wrap.Size = UDim2.new(1,0,0,0)
    wrap.AutomaticSize = Enum.AutomaticSize.Y
    wrap.BackgroundTransparency = 1
    wrap.LayoutOrder = order

    local bubble = Instance.new("Frame", wrap)
    bubble.Size = UDim2.new(0, 60, 0, 32)
    bubble.BackgroundTransparency = 1
    makeGlassPanel(bubble, 16)

    local dotsRow = Instance.new("Frame", bubble)
    dotsRow.Size = UDim2.new(0, 34, 0, 8)
    dotsRow.Position = UDim2.new(0.5, -17, 0.5, -4)
    dotsRow.BackgroundTransparency = 1
    dotsRow.ZIndex = 1

    local layout = Instance.new("UIListLayout", dotsRow)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 4)

    for i = 1, 3 do
        local dot = Instance.new("Frame", dotsRow)
        dot.Size = UDim2.new(0, 6, 0, 6)
        dot.BackgroundColor3 = C.accent2
        dot.ZIndex = 1
        corner(dot, 100)

        task.spawn(function()
            while dot.Parent do
                for _, t in ipairs({0.3, 1, 0.3}) do
                    if not dot.Parent then break end
                    TweenService:Create(dot, TweenInfo.new(0.35), {BackgroundTransparency = t}):Play()
                    task.wait(0.35)
                end
                task.wait(i * 0.1)
            end
        end)
    end

    return wrap
end

-- ==================== BUKA APP ====================
function _G.openAlfreadAIApp()
    -- ===== HEADER (glass) =====
    local header = Instance.new("Frame", appContent)
    header.Size = UDim2.new(1,0,0,50)
    header.BackgroundTransparency = 1
    header.LayoutOrder = 0
    local headerGlass = makeGlassPanel(header, 16)
    stroke(headerGlass, C.accent, 1, 0.6)

    local avatarFrame = Instance.new("Frame", header)
    avatarFrame.Size = UDim2.new(0,34,0,34)
    avatarFrame.Position = UDim2.new(0,8,0.5,-17)
    avatarFrame.BackgroundColor3 = C.accent
    avatarFrame.BackgroundTransparency = 0.15
    avatarFrame.ZIndex = 2
    corner(avatarFrame, 100)
    local avatarGrad = Instance.new("UIGradient", avatarFrame)
    avatarGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.accent),
        ColorSequenceKeypoint.new(1, C.accent2),
    })

    local avatarIcon = Instance.new("TextLabel", avatarFrame)
    avatarIcon.Size = UDim2.new(1,0,1,0)
    avatarIcon.BackgroundTransparency = 1
    avatarIcon.Text = "✨"
    avatarIcon.TextSize = 16
    avatarIcon.ZIndex = 3

    local hTitle = Instance.new("TextLabel", header)
    hTitle.Size = UDim2.new(1,-130,0,20)
    hTitle.Position = UDim2.new(0,50,0,6)
    hTitle.BackgroundTransparency = 1
    hTitle.Text = "Alfread AI"
    hTitle.TextColor3 = C.text
    hTitle.Font = Enum.Font.GothamBlack
    hTitle.TextSize = 14
    hTitle.TextXAlignment = Enum.TextXAlignment.Left
    hTitle.ZIndex = 2

    local hSub = Instance.new("TextLabel", header)
    hSub.Size = UDim2.new(1,-130,0,14)
    hSub.Position = UDim2.new(0,50,0,26)
    hSub.BackgroundTransparency = 1
    hSub.Text = "🟢 Online · Paham semua fitur AvatarClone"
    hSub.TextColor3 = C.green
    hSub.Font = Enum.Font.Gotham
    hSub.TextSize = 9
    hSub.TextXAlignment = Enum.TextXAlignment.Left
    hSub.ZIndex = 2

    local clearBtn = Instance.new("TextButton", header)
    clearBtn.Size = UDim2.new(0,60,0,26)
    clearBtn.Position = UDim2.new(1,-68,0.5,-13)
    clearBtn.BackgroundColor3 = Color3.fromRGB(255,90,100)
    clearBtn.BackgroundTransparency = 0.85
    clearBtn.Text = "🗑 Clear"
    clearBtn.TextColor3 = Color3.fromRGB(255,90,100)
    clearBtn.Font = Enum.Font.GothamBold
    clearBtn.TextSize = 9
    clearBtn.AutoButtonColor = false
    clearBtn.ZIndex = 2
    corner(clearBtn, 8)
    stroke(clearBtn, Color3.fromRGB(255,90,100), 1, 0.75)
    pressFX(clearBtn)

    -- ===== QUICK PROMPT CHIPS (glass pills) =====
    local quickSec = Instance.new("Frame", appContent)
    quickSec.Size = UDim2.new(1,0,0,30)
    quickSec.BackgroundTransparency = 1
    quickSec.LayoutOrder = 1

    local quickScroll = Instance.new("ScrollingFrame", quickSec)
    quickScroll.Size = UDim2.new(1,0,1,0)
    quickScroll.BackgroundTransparency = 1
    quickScroll.ScrollBarThickness = 0
    quickScroll.ScrollingDirection = Enum.ScrollingDirection.X
    quickScroll.CanvasSize = UDim2.new(0,0,0,0)
    quickScroll.AutomaticCanvasSize = Enum.AutomaticSize.X

    local quickLayout = Instance.new("UIListLayout", quickScroll)
    quickLayout.FillDirection = Enum.FillDirection.Horizontal
    quickLayout.Padding = UDim.new(0,6)

    local QUICK_PROMPTS = {
        "Cara pakai key gimana?",
        "Fitur Premium itu apa?",
        "Cara buka Settings?",
        "Fitur Messages buat apa?",
    }

    -- ===== CHAT SCROLL (dasar gelap kebiruan lembut, BUKAN hitam pekat) =====
    local chatScroll = Instance.new("ScrollingFrame", appContent)
    chatScroll.Size = UDim2.new(1,0,0,300)
    chatScroll.BackgroundColor3 = C.bgBase
    chatScroll.BackgroundTransparency = 0.15
    chatScroll.BorderSizePixel = 0
    chatScroll.CanvasSize = UDim2.new(0,0,0,0)
    chatScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    chatScroll.ScrollBarThickness = 3
    chatScroll.ScrollBarImageColor3 = C.accent
    chatScroll.LayoutOrder = 2
    corner(chatScroll, 16)
    stroke(chatScroll, C.border, 1, 0.82)
    chatScrollRef = chatScroll

    -- Highlight halus di background chat area, kesan kaca juga
    local chatGrad = Instance.new("UIGradient", chatScroll)
    chatGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(35,30,55)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15,17,28)),
    })
    chatGrad.Rotation = 60

    local chatLayout = Instance.new("UIListLayout", chatScroll)
    chatLayout.Padding = UDim.new(0,8)
    chatLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local chatPad = Instance.new("UIPadding", chatScroll)
    chatPad.PaddingTop = UDim.new(0,10); chatPad.PaddingBottom = UDim.new(0,10)
    chatPad.PaddingLeft = UDim.new(0,10); chatPad.PaddingRight = UDim.new(0,10)

    -- ===== INPUT AREA (glass) =====
    local inputArea = Instance.new("Frame", appContent)
    inputArea.Size = UDim2.new(1,0,0,46)
    inputArea.BackgroundTransparency = 1
    inputArea.LayoutOrder = 3
    local inputGlass = makeGlassPanel(inputArea, 14)
    stroke(inputGlass, C.border, 1, 0.7)

    local inputBox = Instance.new("TextBox", inputArea)
    inputBox.Size = UDim2.new(1,-56,0,34)
    inputBox.Position = UDim2.new(0,8,0.5,-17)
    inputBox.BackgroundColor3 = C.glass
    inputBox.BackgroundTransparency = 0.92
    inputBox.PlaceholderText = "Tanya apa saja ke Alfread AI..."
    inputBox.PlaceholderColor3 = C.text3
    inputBox.Text = ""
    inputBox.TextColor3 = C.text
    inputBox.Font = Enum.Font.Gotham
    inputBox.TextSize = 11
    inputBox.TextXAlignment = Enum.TextXAlignment.Left
    inputBox.ClearTextOnFocus = false
    inputBox.ZIndex = 2
    corner(inputBox, 9)
    stroke(inputBox, C.border, 1, 0.85)
    local ip = Instance.new("UIPadding", inputBox)
    ip.PaddingLeft = UDim.new(0,10)

    -- ===== TOMBOL KIRIM — DIPASTIKAN BULAT SEMPURNA =====
    -- Bug lama: mungkin corner() gagal ter-apply karena Size tidak persegi
    -- (36x36 seharusnya oke, tapi dipastikan lagi eksplisit di sini + AspectRatio
    -- constraint sebagai jaring pengaman supaya TIDAK PERNAH jadi kotak).
    local sendBtn = Instance.new("TextButton", inputArea)
    sendBtn.Size = UDim2.new(0,36,0,36)
    sendBtn.Position = UDim2.new(1,-44,0.5,-18)
    sendBtn.BackgroundColor3 = C.accent
    sendBtn.Text = "➤"
    sendBtn.TextColor3 = Color3.new(1,1,1)
    sendBtn.Font = Enum.Font.GothamBlack
    sendBtn.TextSize = 15
    sendBtn.AutoButtonColor = false
    sendBtn.ZIndex = 2
    corner(sendBtn, 100) -- radius besar = pasti bulat penuh untuk frame persegi

    local sendAspect = Instance.new("UIAspectRatioConstraint", sendBtn)
    sendAspect.AspectRatio = 1 -- paksa selalu persegi sempurna sebelum dibulatkan

    local sendGrad = Instance.new("UIGradient", sendBtn)
    sendGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.accent),
        ColorSequenceKeypoint.new(1, C.accent2),
    })
    pressFX(sendBtn)

    -- ===== RENDER SEMUA HISTORY =====
    local function renderAllHistory(animateLast)
        for _, c in ipairs(chatScroll:GetChildren()) do
            if not c:IsA("UIListLayout") and not c:IsA("UIPadding") and not c:IsA("UIGradient") then
                c:Destroy()
            end
        end

        if #chatHistory == 0 then
            local welcome = Instance.new("TextLabel", chatScroll)
            welcome.Size = UDim2.new(1,0,0,60)
            welcome.BackgroundTransparency = 1
            welcome.Text = "✨ Halo! Aku Alfread AI.\nTanya aku apa saja soal script AvatarClone ini, atau ngobrol santai aja!"
            welcome.TextColor3 = C.text3
            welcome.Font = Enum.Font.Gotham
            welcome.TextSize = 11
            welcome.TextWrapped = true
            welcome.LayoutOrder = 0
        else
            for i, msg in ipairs(chatHistory) do
                local isLast = (i == #chatHistory)
                renderChatBubble(chatScroll, msg, i, animateLast and isLast)
            end
        end

        task.defer(function()
            pcall(function()
                chatScroll.CanvasPosition = Vector2.new(
                    0, math.max(0, chatScroll.AbsoluteCanvasSize.Y - chatScroll.AbsoluteWindowSize.Y)
                )
            end)
        end)
    end

    for _, prompt in ipairs(QUICK_PROMPTS) do
        local chip = Instance.new("TextButton", quickScroll)
        chip.Size = UDim2.new(0, 0, 1, 0)
        chip.AutomaticSize = Enum.AutomaticSize.X
        chip.BackgroundColor3 = C.glass
        chip.BackgroundTransparency = 0.9
        chip.Text = ""
        chip.AutoButtonColor = false
        corner(chip, 100)
        stroke(chip, C.border, 1, 0.75)
        pressFX(chip)

        local chipPad = Instance.new("UIPadding", chip)
        chipPad.PaddingLeft = UDim.new(0,12); chipPad.PaddingRight = UDim.new(0,12)

        local chipLbl = Instance.new("TextLabel", chip)
        chipLbl.Size = UDim2.new(0,0,1,0)
        chipLbl.AutomaticSize = Enum.AutomaticSize.X
        chipLbl.BackgroundTransparency = 1
        chipLbl.Text = prompt
        chipLbl.TextColor3 = C.text2
        chipLbl.Font = Enum.Font.GothamBold
        chipLbl.TextSize = 9

        chip.MouseButton1Click:Connect(function()
            inputBox.Text = prompt
        end)
    end

    -- ===== KIRIM PESAN =====
    local function doSend()
        if isTyping then return end
        local txt = inputBox.Text
        if txt == "" or txt:match("^%s*$") then return end
        inputBox.Text = ""

        table.insert(chatHistory, {role="user", content=txt})
        renderAllHistory(true)

        isTyping = true
        local typingBubble = renderTypingBubble(chatScroll, #chatHistory + 1)
        task.defer(function()
            pcall(function()
                chatScroll.CanvasPosition = Vector2.new(
                    0, math.max(0, chatScroll.AbsoluteCanvasSize.Y - chatScroll.AbsoluteWindowSize.Y)
                )
            end)
        end)

        local apiMessages = {{role="system", content=SYSTEM_PROMPT}}
        for _, m in ipairs(chatHistory) do
            table.insert(apiMessages, {role=m.role, content=m.content})
        end

        callGroqAPI(apiMessages, function(success, reply)
            isTyping = false
            pcall(function() typingBubble:Destroy() end)

            if success then
                table.insert(chatHistory, {role="assistant", content=reply})
            else
                table.insert(chatHistory, {role="assistant", content="⚠️ " .. reply})
            end
            -- animateLast=true -> bubble balasan AI fade-in CEPAT (0.18s) dan LANGSUNG
            -- utuh, bukan diketik satu-satu.
            renderAllHistory(true)
        end)
    end

    sendBtn.MouseButton1Click:Connect(doSend)
    inputBox.FocusLost:Connect(function(enter) if enter then doSend() end end)
    clearBtn.MouseButton1Click:Connect(function()
        chatHistory = {}
        renderAllHistory(false)
        if _G.showDynamicNotification then
            _G.showDynamicNotification("Riwayat chat dihapus", C.accent2)
        end
    end)

    renderAllHistory(false)
end

print("[Alfread AI] Loaded! Siap menjawab pertanyaan seputar AvatarClone.")
print("[Alfread AI] Loaded! Liquid Glass UI, instant text render.")
