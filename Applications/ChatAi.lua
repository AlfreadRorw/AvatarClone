-- ================================================
-- CHAT AI APP - Groq AI Assistant
-- ================================================

local Services = _G.Services
local LocalPlayer = _G.LocalPlayer
local Players = Services.Players
local HttpService = Services.HttpService
local T = _G.T
local Helpers = _G.Helpers
local Config = _G.Config

local appContent = _G.appContent
local appTitle = _G.appTitle

local corner = Helpers.corner
local stroke = Helpers.stroke
local tween = Helpers.tween
local pressFX = Helpers.pressFX

-- ==================== AI CONFIG ====================
local GROQ_API_KEY = "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"
local GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"
local MODEL_NAME = "llama-3.1-70b-versatile"

-- ==================== DARK THEME ====================
local colors = {
    bg = Color3.fromRGB(10, 10, 15),
    card = Color3.fromRGB(18, 18, 25),
    card2 = Color3.fromRGB(25, 25, 35),
    accent = Color3.fromRGB(139, 92, 246),
    accentGlow = Color3.fromRGB(167, 139, 250),
    text = Color3.fromRGB(255, 255, 255),
    text2 = Color3.fromRGB(170, 170, 185),
    text3 = Color3.fromRGB(100, 100, 115),
    border = Color3.fromRGB(35, 35, 45),
    userBubble = Color3.fromRGB(139, 92, 246),
    aiBubble = Color3.fromRGB(30, 30, 40),
    green = Color3.fromRGB(0, 230, 118),
    red = Color3.fromRGB(255, 82, 82),
}

-- ==================== AI STATE ====================
_G.AIState = _G.AIState or {
    history = {},
    isGenerating = false,
}

local aiState = _G.AIState

-- ==================== SYSTEM PROMPT ====================
local SYSTEM_PROMPT = [[
Kamu adalah AI Assistant bernama "PhoneAI" yang tertanam di Roblox Phone ID Viewer.
Kamu membantu pemain dengan:
1. Menjawab pertanyaan tentang game Roblox
2. Memberikan tips dan trik
3. Membantu dengan pertanyaan umum
4. Menjelaskan fitur Phone ID Viewer

Gaya bicara: Santai, ramah, dan menggunakan Bahasa Indonesia yang baik.
Jawaban singkat dan jelas, maksimal 150 kata kecuali diminta panjang.
Jangan pernah menyebutkan bahwa kamu adalah AI dari Groq.
Kamu adalah PhoneAI, asisten pribadi di Phone ID Viewer.
]]

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

-- ==================== HTTP REQUEST ====================
local function sendGroqRequest(messages)
    local body = HttpService:JSONEncode({
        model = MODEL_NAME,
        messages = messages,
        temperature = 0.7,
        max_tokens = 500,
        top_p = 1,
        stream = false,
    })

    local ok, result = pcall(function()
        if syn and syn.request then
            return syn.request({
                Url = GROQ_API_URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["Authorization"] = "Bearer " .. GROQ_API_KEY,
                },
                Body = body,
            })
        end
        
        if http_request then
            return http_request({
                Url = GROQ_API_URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["Authorization"] = "Bearer " .. GROQ_API_KEY,
                },
                Body = body,
            })
        end
        
        if request then
            return request({
                Url = GROQ_API_URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["Authorization"] = "Bearer " .. GROQ_API_KEY,
                },
                Body = body,
            })
        end
        
        return HttpService:RequestAsync({
            Url = GROQ_API_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Authorization"] = "Bearer " .. GROQ_API_KEY,
            },
            Body = body,
        })
    end)

    if not ok or not result then
        return nil, "Request failed"
    end

    local statusCode = result.StatusCode or result.Success and 200 or 0
    if statusCode ~= 200 and statusCode ~= 201 then
        return nil, "HTTP " .. tostring(statusCode)
    end

    local rawBody = result.Body or ""
    if rawBody == "" then
        return nil, "Empty response"
    end

    local decodeOk, data = pcall(function()
        return HttpService:JSONDecode(rawBody)
    end)

    if not decodeOk or not data then
        return nil, "JSON decode failed"
    end

    if data.choices and data.choices[1] and data.choices[1].message then
        return data.choices[1].message.content or "", nil
    end

    return nil, "Invalid response format"
end

-- ==================== BUILD CHAT BUBBLE ====================
local function buildChatBubble(parent, message, isUser, order)
    local bubbleContainer = Instance.new("Frame", parent)
    bubbleContainer.Size = UDim2.new(1, 0, 0, 0)
    bubbleContainer.AutomaticSize = Enum.AutomaticSize.Y
    bubbleContainer.BackgroundTransparency = 1
    bubbleContainer.LayoutOrder = order
    
    local alignment = isUser and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
    
    local bubble = Instance.new("Frame", bubbleContainer)
    bubble.Size = UDim2.new(0.85, 0, 0, 0)
    bubble.AutomaticSize = Enum.AutomaticSize.Y
    bubble.Position = isUser and UDim2.new(0.15, 0, 0, 0) or UDim2.new(0, 0, 0, 0)
    bubble.BackgroundColor3 = isUser and colors.userBubble or colors.aiBubble
    corner(bubble, 16)
    
    -- Rounded corner yang berbeda untuk bubble user vs AI
    if isUser then
        corner(bubble, 16)
        -- Ganti satu corner jadi lebih kecil
        local corners = Instance.new("UICorner", bubble)
        corners.CornerRadius = UDim.new(0, 4)
    end
    
    local bubblePadding = Instance.new("UIPadding", bubble)
    bubblePadding.PaddingLeft = UDim.new(0, 14)
    bubblePadding.PaddingRight = UDim.new(0, 14)
    bubblePadding.PaddingTop = UDim.new(0, 10)
    bubblePadding.PaddingBottom = UDim.new(0, 10)
    
    local msgText = Instance.new("TextLabel", bubble)
    msgText.Size = UDim2.new(1, 0, 0, 0)
    msgText.AutomaticSize = Enum.AutomaticSize.Y
    msgText.BackgroundTransparency = 1
    msgText.Text = message
    msgText.TextColor3 = colors.text
    msgText.Font = Enum.Font.Gotham
    msgText.TextSize = 13
    msgText.TextXAlignment = alignment
    msgText.TextWrapped = true
    msgText.RichText = true
    
    -- Sender label
    local senderLabel = Instance.new("TextLabel", bubbleContainer)
    senderLabel.Size = UDim2.new(0.85, 0, 0, 14)
    senderLabel.Position = isUser and UDim2.new(0.15, 0, 0, 0) or UDim2.new(0, 0, 0, 0)
    senderLabel.BackgroundTransparency = 1
    senderLabel.Text = isUser and LocalPlayer.DisplayName or "PhoneAI"
    senderLabel.TextColor3 = isUser and colors.accentGlow or colors.green
    senderLabel.Font = Enum.Font.GothamBold
    senderLabel.TextSize = 9
    senderLabel.TextXAlignment = isUser and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
    
    -- Spacer agar bubble tidak menempel dengan sender label
    local spacer = Instance.new("Frame", bubbleContainer)
    spacer.Size = UDim2.new(1, 0, 0, 18)
    spacer.BackgroundTransparency = 1
    
    return bubbleContainer
end

-- ==================== OPEN CHAT AI APP ====================
function _G.openChatAIApp()
    cleanupAI()
    AILifecycle.active = true
    
    -- ==================== HEADER ====================
    local headerCard = Instance.new("Frame", appContent)
    headerCard.Size = UDim2.new(1, 0, 0, 60)
    headerCard.BackgroundColor3 = colors.card
    headerCard.LayoutOrder = 0
    corner(headerCard, 16)
    stroke(headerCard, colors.accent, 2, 0.5)
    
    -- Gradient header
    local headerGradient = Instance.new("UIGradient", headerCard)
    headerGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(139, 92, 246)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 40, 120)),
    })
    headerGradient.Rotation = 135
    
    -- AI Avatar
    local aiAvatar = Instance.new("Frame", headerCard)
    aiAvatar.Size = UDim2.new(0, 42, 0, 42)
    aiAvatar.Position = UDim2.new(0, 10, 0.5, -21)
    aiAvatar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    aiAvatar.BackgroundTransparency = 0.9
    corner(aiAvatar, 100)
    stroke(aiAvatar, Color3.fromRGB(255, 255, 255), 2, 0.5)
    
    -- AI icon (huruf AI)
    local aiText = Instance.new("TextLabel", aiAvatar)
    aiText.Size = UDim2.new(1, 0, 1, 0)
    aiText.BackgroundTransparency = 1
    aiText.Text = "AI"
    aiText.TextColor3 = Color3.fromRGB(255, 255, 255)
    aiText.Font = Enum.Font.GothamBlack
    aiText.TextSize = 16
    
    local headerTitle = Instance.new("TextLabel", headerCard)
    headerTitle.Size = UDim2.new(1, -60, 0, 24)
    headerTitle.Position = UDim2.new(0, 60, 0, 8)
    headerTitle.BackgroundTransparency = 1
    headerTitle.Text = "PhoneAI Assistant"
    headerTitle.TextColor3 = Color3.new(1, 1, 1)
    headerTitle.Font = Enum.Font.GothamBlack
    headerTitle.TextSize = 16
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    
    local headerSub = Instance.new("TextLabel", headerCard)
    headerSub.Size = UDim2.new(1, -60, 0, 16)
    headerSub.Position = UDim2.new(0, 60, 0, 34)
    headerSub.BackgroundTransparency = 1
    headerSub.Text = "Tanya apa saja, AI siap membantu!"
    headerSub.TextColor3 = Color3.fromRGB(200, 200, 220)
    headerSub.Font = Enum.Font.Gotham
    headerSub.TextSize = 10
    headerSub.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Status dot
    local statusDot = Instance.new("Frame", headerCard)
    statusDot.Size = UDim2.new(0, 8, 0, 8)
    statusDot.Position = UDim2.new(1, -20, 0, 10)
    statusDot.BackgroundColor3 = colors.green
    corner(statusDot, 100)
    
    -- ==================== CHAT AREA ====================
    local chatArea = Instance.new("ScrollingFrame", appContent)
    chatArea.Size = UDim2.new(1, 0, 0, 0)
    chatArea.AutomaticSize = Enum.AutomaticSize.Y
    chatArea.BackgroundColor3 = colors.bg
    chatArea.BorderSizePixel = 0
    chatArea.ScrollBarThickness = 3
    chatArea.ScrollBarImageColor3 = colors.accent
    chatArea.CanvasSize = UDim2.new(0, 0, 0, 0)
    chatArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
    chatArea.LayoutOrder = 1
    corner(chatArea, 12)
    stroke(chatArea, colors.border, 1, 0.3)
    
    local chatPadding = Instance.new("UIPadding", chatArea)
    chatPadding.PaddingLeft = UDim.new(0, 10)
    chatPadding.PaddingRight = UDim.new(0, 10)
    chatPadding.PaddingTop = UDim.new(0, 10)
    chatPadding.PaddingBottom = UDim.new(0, 10)
    
    local chatList = Instance.new("UIListLayout", chatArea)
    chatList.Padding = UDim.new(0, 12)
    chatList.SortOrder = Enum.SortOrder.LayoutOrder
    chatList.VerticalAlignment = Enum.VerticalAlignment.Bottom
    
    -- ==================== WELCOME MESSAGE ====================
    local welcomeText = "Halo! Saya PhoneAI, asisten pintar di Phone ID Viewer.\n\nSaya bisa membantu kamu dengan:\n• Pertanyaan tentang game Roblox\n• Tips dan trik\n• Informasi fitur\n\nSilakan tanya apa saja!"
    
    buildChatBubble(chatArea, welcomeText, false, 0)
    
    -- ==================== INPUT AREA ====================
    local inputContainer = Instance.new("Frame", appContent)
    inputContainer.Size = UDim2.new(1, 0, 0, 50)
    inputContainer.BackgroundColor3 = colors.card
    inputContainer.LayoutOrder = 2
    corner(inputContainer, 14)
    stroke(inputContainer, colors.border, 1, 0.3)
    
    local inputField = Instance.new("TextBox", inputContainer)
    inputField.Size = UDim2.new(1, -60, 0, 32)
    inputField.Position = UDim2.new(0, 10, 0, 9)
    inputField.PlaceholderText = "Tulis pesan..."
    inputField.PlaceholderColor3 = colors.text3
    inputField.Text = ""
    inputField.TextColor3 = colors.text
    inputField.Font = Enum.Font.Gotham
    inputField.TextSize = 12
    inputField.ClearTextOnFocus = false
    inputField.BackgroundColor3 = colors.card2
    corner(inputField, 8)
    stroke(inputField, colors.border, 1, 0.3)
    
    local sendBtn = Instance.new("TextButton", inputContainer)
    sendBtn.Size = UDim2.new(0, 40, 0, 32)
    sendBtn.Position = UDim2.new(1, -50, 0, 9)
    sendBtn.BackgroundColor3 = colors.accent
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
        if message == "" or aiState.isGenerating then return end
        
        inputField.Text = ""
        
        -- Tambah user message
        buildChatBubble(chatArea, message, true, #chatArea:GetChildren() - 1)
        
        -- Scroll ke bawah
        chatArea.CanvasPosition = Vector2.new(0, chatArea.AbsoluteCanvasSize.Y)
        
        -- Tambah ke history
        table.insert(aiState.history, {role = "user", content = message})
        
        -- Batasi history (max 20 pesan)
        if #aiState.history > 20 then
            table.remove(aiState.history, 1)
        end
        
        -- Tampilkan typing indicator
        aiState.isGenerating = true
        sendBtn.Text = "..."
        sendBtn.BackgroundColor3 = colors.card2
        
        local typingBubble = buildChatBubble(chatArea, "...", false, #chatArea:GetChildren() - 1)
        
        task.spawn(function()
            -- Build messages untuk API
            local messages = {}
            table.insert(messages, {role = "system", content = SYSTEM_PROMPT})
            for _, msg in ipairs(aiState.history) do
                table.insert(messages, msg)
            end
            
            local response, err = sendGroqRequest(messages)
            
            aiState.isGenerating = false
            sendBtn.Text = ">"
            sendBtn.BackgroundColor3 = colors.accent
            
            -- Hapus typing indicator
            pcall(function() typingBubble:Destroy() end)
            
            if response and response ~= "" then
                -- Tambah AI response
                buildChatBubble(chatArea, response, false, #chatArea:GetChildren() - 1)
                table.insert(aiState.history, {role = "assistant", content = response})
            else
                buildChatBubble(chatArea, "Maaf, terjadi kesalahan. Coba lagi nanti.", false, #chatArea:GetChildren() - 1)
            end
            
            -- Scroll ke bawah
            chatArea.CanvasPosition = Vector2.new(0, chatArea.AbsoluteCanvasSize.Y)
        end)
    end
    
    sendBtn.MouseButton1Click:Connect(sendMessage)
    
    inputField.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            sendMessage()
        end
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
        "Tips jadi pro",
        "Fitur apa saja?",
    }
    
    for _, suggestion in ipairs(suggestions) do
        local suggBtn = Instance.new("TextButton", suggestionContainer)
        suggBtn.Size = UDim2.new(1, 0, 0, 26)
        suggBtn.BackgroundColor3 = colors.card
        suggBtn.Text = suggestion
        suggBtn.TextColor3 = colors.text2
        suggBtn.Font = Enum.Font.GothamBold
        suggBtn.TextSize = 8
        suggBtn.AutoButtonColor = false
        corner(suggBtn, 8)
        stroke(suggBtn, colors.border, 1, 0.3)
        pressFX(suggBtn)
        
        suggBtn.MouseButton1Click:Connect(function()
            inputField.Text = suggestion
            sendMessage()
        end)
    end
end

print("[ChatAI] App loaded!")