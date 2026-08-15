-- ================================================
-- AICHAT.LUA — Alfread AI Chat Assistant (Groq)
-- AI Premium: Chat dengan Alfread AI langsung dari game
-- ================================================

local Services    = _G.Services
local LocalPlayer = _G.LocalPlayer
local T           = _G.T or {}
local Helpers     = _G.Helpers or {}
local appContent  = _G.appContent
local HttpService = game:GetService("HttpService")

local corner  = Helpers.corner
local stroke  = Helpers.stroke
local pressFX = Helpers.pressFX
local tween   = Helpers.tween

-- ==================== KONFIGURASI GROQ ====================
local GROQ_API_KEY = "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"
local GROQ_MODEL   = "llama-3.3-70b-versatile"
local GROQ_URL     = "https://api.groq.com/openai/v1/chat/completions"

-- ==================== DARK THEME PREMIUM ====================
local C = {
    bg      = Color3.fromRGB(8, 8, 14),
    card    = Color3.fromRGB(18, 16, 28),
    card2   = Color3.fromRGB(26, 22, 40),
    border  = Color3.fromRGB(50, 42, 75),
    text    = Color3.fromRGB(240, 238, 250),
    text2   = Color3.fromRGB(165, 158, 190),
    text3   = Color3.fromRGB(95, 88, 125),
    accent  = Color3.fromRGB(130, 120, 255),
    accent2 = Color3.fromRGB(80, 200, 255),
    green   = Color3.fromRGB(90, 230, 160),
    gold    = Color3.fromRGB(255, 200, 80),
    red     = Color3.fromRGB(255, 90, 90),
    userBub = Color3.fromRGB(90, 80, 220),
    aiBub   = Color3.fromRGB(24, 20, 38),
}

-- ==================== ALFREAD AI PERSONA ====================
local ALFREAD_SYSTEM_PROMPT = [[
Kamu adalah "Alfread AI" — asisten pintar yang tertanam di dalam Phone ID Viewer untuk Roblox.

Kamu mengenal SEMUA fitur Phone ID Viewer. Berikut daftar lengkapnya:

## FITUR UTAMA PHONE ID VIEWER:
1. **Players** — Melihat daftar player di server, mencari player, menandai favorit
2. **Clone** — Clone avatar/items dari player lain (All/Body/Accessories tabs)
3. **Preset** — Menyimpan kombinasi item sebagai preset, bisa di-clone ulang
4. **Profile** — Melihat profil lengkap player (avatar, User ID, item count)
5. **Favorites** — Menyimpan player dan item favorit (Players/Items tabs)
6. **Items** — Melihat semua item yang dipakai player, wear/fav item
7. **Volume** — Mengatur volume suara game (master volume, per-sound)
8. **Who's Online** — Melihat siapa saja yang online (map, server info)
9. **Lookup** — Mencari player Roblox berdasarkan username (Profile/Items/Outfits)
10. **Messages** — Chat dengan admin
11. **NotifWeb** — Melihat notifikasi dari website admin
12. **Settings** — Pengaturan, key status, developer info, social media
13. **Chat AI** — Chat dengan kamu (Alfread AI)

## CARA MENGGUNAKAN:
- Pilih player di "Players" app dulu, lalu buka Clone/Items/Profile
- Gunakan Preset untuk menyimpan outfit favorit
- Favorites untuk akses cepat
- Lookup untuk mencari player yang tidak di server

## INFORMASI KEY:
- Key bersifat 1 player = 1 key
- Key tidak bisa dipakai 2 kali
- Saat key expired, user harus input key baru
- Key bisa dibeli dari developer

Gaya bicara: Santai, ramah, menggunakan Bahasa Indonesia. Jawaban maksimal 150 kata kecuali diminta detail. Jangan pernah menyebutkan bahwa kamu adalah AI dari Groq. Kamu adalah Alfread AI, asisten pribadi Phone ID Viewer.
]]

-- ==================== STATE ====================
_G.AIChatState = _G.AIChatState or {
    history = {},
    isGenerating = false,
}

local chatHistory = _G.AIChatState.history
local isTyping = false

-- ==================== LIFECYCLE ====================
local AILifecycle = {
    active = false,
    tasks = {},
}

local function cleanupAI()
    AILifecycle.active = false
    for _, task in ipairs(AILifecycle.tasks) do
        pcall(function() task.cancel() end)
    end
    AILifecycle.tasks = {}
end

table.insert(_G.AvatarCloneCleanupTasks or {}, cleanupAI)

-- ==================== HTTP REQUEST KE GROQ ====================
local function callGroqAPI(messages, callback)
    local body = {
        model = GROQ_MODEL,
        messages = messages,
        temperature = 0.7,
        max_tokens = 500,
        top_p = 1,
        stream = false,
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
                Body = HttpService:JSONEncode(body),
            }
            if syn and syn.request then return syn.request(opts)
            elseif http_request then return http_request(opts)
            elseif request then return request(opts)
            else return HttpService:RequestAsync(opts) end
        end)

        if not ok or not result then
            callback(false, "Gagal terhubung ke server AI. Cek koneksi internet.")
            return
        end

        local success = result.Success or (result.StatusCode and result.StatusCode < 300)
        if not success then
            local status = result.StatusCode or "?"
            callback(false, "Server AI error (kode " .. tostring(status) .. ").")
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

-- ==================== BUILD CHAT BUBBLE ====================
local function buildChatBubble(parent, message, isUser, order)
    local wrap = Instance.new("Frame", parent)
    wrap.Size = UDim2.new(1, 0, 0, 0)
    wrap.AutomaticSize = Enum.AutomaticSize.Y
    wrap.BackgroundTransparency = 1
    wrap.LayoutOrder = order

    -- Sender label
    local sender = Instance.new("TextLabel", wrap)
    sender.Size = UDim2.new(0.85, 0, 0, 14)
    sender.AnchorPoint = isUser and Vector2.new(1, 0) or Vector2.new(0, 0)
    sender.Position = isUser and UDim2.new(1, 0, 0, 4) or UDim2.new(0, 0, 0, 4)
    sender.BackgroundTransparency = 1
    sender.Text = isUser and LocalPlayer.DisplayName or "Alfread AI"
    sender.TextColor3 = isUser and C.accent2 or C.green
    sender.Font = Enum.Font.GothamBold
    sender.TextSize = 9
    sender.TextXAlignment = isUser and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left

    -- Bubble
    local bubble = Instance.new("Frame", wrap)
    bubble.AutomaticSize = Enum.AutomaticSize.Y
    bubble.Size = UDim2.new(0.85, 0, 0, 0)
    bubble.AnchorPoint = isUser and Vector2.new(1, 0) or Vector2.new(0, 0)
    bubble.Position = isUser and UDim2.new(1, 0, 0, 20) or UDim2.new(0, 0, 0, 20)
    bubble.BackgroundColor3 = isUser and C.userBub or C.aiBub
    corner(bubble, 16)
    if not isUser then stroke(bubble, C.border, 1, 0.4) end

    local pad = Instance.new("UIPadding", bubble)
    pad.PaddingTop = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)
    pad.PaddingLeft = UDim.new(0, 14)
    pad.PaddingRight = UDim.new(0, 14)

    local msgText = Instance.new("TextLabel", bubble)
    msgText.Size = UDim2.new(1, 0, 0, 0)
    msgText.AutomaticSize = Enum.AutomaticSize.Y
    msgText.BackgroundTransparency = 1
    msgText.Text = message
    msgText.TextColor3 = C.text
    msgText.Font = Enum.Font.Gotham
    msgText.TextSize = 12
    msgText.TextWrapped = true
    msgText.TextXAlignment = isUser and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
    msgText.RichText = true

    return wrap
end

-- ==================== OPEN AI CHAT APP ====================
function _G.openAIChatApp()
    cleanupAI()
    AILifecycle.active = true

    -- ==================== HEADER ====================
    local header = Instance.new("Frame", appContent)
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundColor3 = C.card
    header.LayoutOrder = 0
    corner(header, 16)
    stroke(header, C.accent, 2, 0.5)

    -- Gradient
    local grad = Instance.new("UIGradient", header)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.accent),
        ColorSequenceKeypoint.new(1, C.accent2),
    })
    grad.Transparency = NumberSequence.new(0.85)
    grad.Rotation = 135

    -- AI Avatar
    local aiAvatar = Instance.new("Frame", header)
    aiAvatar.Size = UDim2.new(0, 42, 0, 42)
    aiAvatar.Position = UDim2.new(0, 10, 0.5, -21)
    aiAvatar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    aiAvatar.BackgroundTransparency = 0.9
    corner(aiAvatar, 100)
    stroke(aiAvatar, Color3.fromRGB(255, 255, 255), 2, 0.5)

    local aiText = Instance.new("TextLabel", aiAvatar)
    aiText.Size = UDim2.new(1, 0, 1, 0)
    aiText.BackgroundTransparency = 1
    aiText.Text = "AI"
    aiText.TextColor3 = Color3.fromRGB(255, 255, 255)
    aiText.Font = Enum.Font.GothamBlack
    aiText.TextSize = 16

    local headerTitle = Instance.new("TextLabel", header)
    headerTitle.Size = UDim2.new(1, -60, 0, 24)
    headerTitle.Position = UDim2.new(0, 60, 0, 8)
    headerTitle.BackgroundTransparency = 1
    headerTitle.Text = "Alfread AI"
    headerTitle.TextColor3 = Color3.new(1, 1, 1)
    headerTitle.Font = Enum.Font.GothamBlack
    headerTitle.TextSize = 16
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left

    local headerSub = Instance.new("TextLabel", header)
    headerSub.Size = UDim2.new(1, -60, 0, 16)
    headerSub.Position = UDim2.new(0, 60, 0, 34)
    headerSub.BackgroundTransparency = 1
    headerSub.Text = "Tanya apa saja tentang Phone ID Viewer!"
    headerSub.TextColor3 = Color3.fromRGB(200, 200, 220)
    headerSub.Font = Enum.Font.Gotham
    headerSub.TextSize = 10
    headerSub.TextXAlignment = Enum.TextXAlignment.Left

    -- Status dot
    local statusDot = Instance.new("Frame", header)
    statusDot.Size = UDim2.new(0, 8, 0, 8)
    statusDot.Position = UDim2.new(1, -18, 0, 10)
    statusDot.BackgroundColor3 = C.green
    corner(statusDot, 100)

    -- ==================== CHAT AREA ====================
    local chatArea = Instance.new("ScrollingFrame", appContent)
    chatArea.Size = UDim2.new(1, 0, 0, 0)
    chatArea.AutomaticSize = Enum.AutomaticSize.Y
    chatArea.BackgroundColor3 = C.bg
    chatArea.BorderSizePixel = 0
    chatArea.ScrollBarThickness = 3
    chatArea.ScrollBarImageColor3 = C.accent
    chatArea.CanvasSize = UDim2.new(0, 0, 0, 0)
    chatArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
    chatArea.LayoutOrder = 1
    corner(chatArea, 12)
    stroke(chatArea, C.border, 1, 0.3)

    local chatPadding = Instance.new("UIPadding", chatArea)
    chatPadding.PaddingLeft = UDim.new(0, 10)
    chatPadding.PaddingRight = UDim.new(0, 10)
    chatPadding.PaddingTop = UDim.new(0, 10)
    chatPadding.PaddingBottom = UDim.new(0, 10)

    local chatList = Instance.new("UIListLayout", chatArea)
    chatList.Padding = UDim.new(0, 12)
    chatList.SortOrder = Enum.SortOrder.LayoutOrder

    -- Welcome message
    local welcomeText = "Halo! Saya **Alfread AI**, asisten pintar di Phone ID Viewer.\n\nSaya bisa membantu kamu dengan:\n• Menjelaskan semua fitur Phone ID Viewer\n• Tips menggunakan aplikasi\n• Informasi tentang key system\n• Pertanyaan umum lainnya\n\nSilakan tanya apa saja!"

    buildChatBubble(chatArea, welcomeText, false, 0)

    -- ==================== INPUT AREA ====================
    local inputContainer = Instance.new("Frame", appContent)
    inputContainer.Size = UDim2.new(1, 0, 0, 50)
    inputContainer.BackgroundColor3 = C.card
    inputContainer.LayoutOrder = 2
    corner(inputContainer, 14)
    stroke(inputContainer, C.border, 1, 0.3)

    local inputField = Instance.new("TextBox", inputContainer)
    inputField.Size = UDim2.new(1, -60, 0, 32)
    inputField.Position = UDim2.new(0, 10, 0, 9)
    inputField.PlaceholderText = "Tulis pesan..."
    inputField.PlaceholderColor3 = C.text3
    inputField.Text = ""
    inputField.TextColor3 = C.text
    inputField.Font = Enum.Font.Gotham
    inputField.TextSize = 12
    inputField.ClearTextOnFocus = false
    inputField.BackgroundColor3 = C.card2
    corner(inputField, 8)
    stroke(inputField, C.border, 1, 0.3)

    local sendBtn = Instance.new("TextButton", inputContainer)
    sendBtn.Size = UDim2.new(0, 40, 0, 32)
    sendBtn.Position = UDim2.new(1, -50, 0, 9)
    sendBtn.BackgroundColor3 = C.accent
    sendBtn.Text = ">"
    sendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    sendBtn.Font = Enum.Font.GothamBlack
    sendBtn.TextSize = 16
    sendBtn.AutoButtonColor = false
    corner(sendBtn, 8)
    pressFX(sendBtn)

    -- ==================== SEND MESSAGE ====================
    local function sendMessage()
        local message = inputField.Text:gsub("^%s+", ""):gsub("%s+$", "")
        if message == "" or isTyping then return end

        inputField.Text = ""

        -- Tambah user message
        buildChatBubble(chatArea, message, true, #chatArea:GetChildren() - 1)
        chatArea.CanvasPosition = Vector2.new(0, chatArea.AbsoluteCanvasSize.Y)

        -- Tambah ke history
        table.insert(chatHistory, {role = "user", content = message})
        if #chatHistory > 20 then
            table.remove(chatHistory, 1)
        end

        isTyping = true
        sendBtn.Text = "..."
        sendBtn.BackgroundColor3 = C.card2

        -- Typing indicator bubble
        local typingBubble = buildChatBubble(chatArea, "Mengetik...", false, #chatArea:GetChildren() - 1)

        task.spawn(function()
            -- Build messages
            local messages = {}
            table.insert(messages, {role = "system", content = ALFREAD_SYSTEM_PROMPT})
            for _, msg in ipairs(chatHistory) do
                table.insert(messages, msg)
            end

            callGroqAPI(messages, function(success, reply)
                isTyping = false
                sendBtn.Text = ">"
                sendBtn.BackgroundColor3 = C.accent

                -- Hapus typing indicator
                pcall(function() typingBubble:Destroy() end)

                if success and reply and reply ~= "" then
                    buildChatBubble(chatArea, reply, false, #chatArea:GetChildren() - 1)
                    table.insert(chatHistory, {role = "assistant", content = reply})
                else
                    buildChatBubble(chatArea, "Maaf, terjadi kesalahan. Coba lagi nanti.", false, #chatArea:GetChildren() - 1)
                end

                chatArea.CanvasPosition = Vector2.new(0, chatArea.AbsoluteCanvasSize.Y)
            end)
        end)
    end

    sendBtn.MouseButton1Click:Connect(sendMessage)
    inputField.FocusLost:Connect(function(enterPressed)
        if enterPressed then sendMessage() end
    end)

    -- ==================== QUICK SUGGESTIONS ====================
    local suggestionContainer = Instance.new("Frame", appContent)
    suggestionContainer.Size = UDim2.new(1, 0, 0, 30)
    suggestionContainer.BackgroundTransparency = 1
    suggestionContainer.LayoutOrder = 3

    local suggestionLayout = Instance.new("UIGridLayout", suggestionContainer)
    suggestionLayout.CellSize = UDim2.new(1/3, -4, 0, 26)
    suggestionLayout.CellPadding = UDim2.new(0, 4, 0, 0)

    local suggestions = {
        "Apa itu Phone ID Viewer?",
        "Fitur apa saja?",
        "Cara clone avatar?",
    }

    for _, suggestion in ipairs(suggestions) do
        local suggBtn = Instance.new("TextButton", suggestionContainer)
        suggBtn.Size = UDim2.new(1, 0, 0, 26)
        suggBtn.BackgroundColor3 = C.card
        suggBtn.Text = suggestion
        suggBtn.TextColor3 = C.text2
        suggBtn.Font = Enum.Font.GothamBold
        suggBtn.TextSize = 8
        suggBtn.AutoButtonColor = false
        corner(suggBtn, 8)
        stroke(suggBtn, C.border, 1, 0.3)
        pressFX(suggBtn)

        suggBtn.MouseButton1Click:Connect(function()
            inputField.Text = suggestion
            sendMessage()
        end)
    end
end

print("[AIChat] Alfread AI loaded!")