-- ================================================
-- CHAT AI APP - Groq AI Assistant (Fixed White Screen)
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

local corner = Helpers.corner or function(o, r) local c = Instance.new("UICorner", o) c.CornerRadius = UDim.new(0, r) end
local stroke = Helpers.stroke or function(o, c, t) local s = Instance.new("UIStroke", o) s.Color = c s.Thickness = t end
local pressFX = Helpers.pressFX or function() end

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
            return syn.request({ Url = GROQ_API_URL, Method = "POST", Headers = { ["Content-Type"] = "application/json", ["Authorization"] = "Bearer " .. GROQ_API_KEY }, Body = body })
        end
        if http_request then
            return http_request({ Url = GROQ_API_URL, Method = "POST", Headers = { ["Content-Type"] = "application/json", ["Authorization"] = "Bearer " .. GROQ_API_KEY }, Body = body })
        end
        if request then
            return request({ Url = GROQ_API_URL, Method = "POST", Headers = { ["Content-Type"] = "application/json", ["Authorization"] = "Bearer " .. GROQ_API_KEY }, Body = body })
        end
        return HttpService:RequestAsync({ Url = GROQ_API_URL, Method = "POST", Headers = { ["Content-Type"] = "application/json", ["Authorization"] = "Bearer " .. GROQ_API_KEY }, Body = body })
    end)

    if not ok or not result then return nil, "Request failed" end

    local statusCode = result.StatusCode or (result.Success and 200) or 0
    if statusCode ~= 200 and statusCode ~= 201 then return nil, "HTTP " .. tostring(statusCode) end

    local rawBody = result.Body or ""
    if rawBody == "" then return nil, "Empty response" end

    local decodeOk, data = pcall(function() return HttpService:JSONDecode(rawBody) end)
    if not decodeOk or not data then return nil, "JSON decode failed" end

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
    bubbleContainer.LayoutOrder = order or 0
    
    local alignment = isUser and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
    
    local bubble = Instance.new("Frame", bubbleContainer)
    bubble.Size = UDim2.new(0.85, 0, 0, 0)
    bubble.AutomaticSize = Enum.AutomaticSize.Y
    bubble.Position = isUser and UDim2.new(0.15, 0, 0, 0) or UDim2.new(0, 0, 0, 0)
    bubble.BackgroundColor3 = isUser and colors.userBubble or colors.aiBubble
    corner(bubble, 16)
    
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
    
    local senderLabel = Instance.new("TextLabel", bubbleContainer)
    senderLabel.Size = UDim2.new(0.85, 0, 0, 14)
    senderLabel.Position = isUser and UDim2.new(0.15, 0, 0, 0) or UDim2.new(0, 0, 0, 0)
    senderLabel.BackgroundTransparency = 1
    senderLabel.Text = isUser and LocalPlayer.DisplayName or "PhoneAI"
    senderLabel.TextColor3 = isUser and colors.accentGlow or colors.green
    senderLabel.Font = Enum.Font.GothamBold
    senderLabel.TextSize = 9
    senderLabel.TextXAlignment = isUser and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
    
    local spacer = Instance.new("Frame", bubbleContainer)
    spacer.Size = UDim2.new(1, 0, 0, 18)
    spacer.BackgroundTransparency = 1
    
    return bubbleContainer
end

-- ==================== OPEN CHAT AI APP ====================
function _G.openChatAIApp()
    cleanupAI()
    AILifecycle.active = true
    
    -- Bersihkan appContent terlebih dahulu agar tidak menumpuk
    for _, child in ipairs(appContent:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end
    
    appContent.BackgroundColor3 = colors.bg

    -- Gunakan UIListLayout pada appContent utama agar komponen tersusun rapi secara vertikal dan tidak tumpang tindih (penyebab layar putih)
    local mainLayout = Instance.new("UIListLayout", appContent)
    mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
    mainLayout.Padding = UDim.new(0, 8)
    mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    -- 1. HEADER (LayoutOrder = 0)
    local headerCard = Instance.new("Frame", appContent)
    headerCard.Size = UDim2.new(1, 0, 0, 55)
    headerCard.BackgroundColor3 = colors.card
    headerCard.LayoutOrder = 0
    corner(headerCard, 12)
    stroke(headerCard, colors.accent, 1.5)
    
    local headerTitle = Instance.new("TextLabel", headerCard)
    headerTitle.Size = UDim2.new(1, -20, 0, 24)
    headerTitle.Position = UDim2.new(0, 12, 0, 8)
    headerTitle.BackgroundTransparency = 1
    headerTitle.Text = "🤖 PhoneAI Assistant"
    headerTitle.TextColor3 = Color3.new(1, 1, 1)
    headerTitle.Font = Enum.Font.GothamBlack
    headerTitle.TextSize = 14
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    
    local headerSub = Instance.new("TextLabel", headerCard)
    headerSub.Size = UDim2.new(1, -20, 0, 16)
    headerSub.Position = UDim2.new(0, 12, 0, 30)
    headerSub.BackgroundTransparency = 1
    headerSub.Text = "Tanya apa saja, AI siap membantu!"
    headerSub.TextColor3 = colors.text2
    headerSub.Font = Enum.Font.Gotham
    headerSub.TextSize = 10
    headerSub.TextXAlignment = Enum.TextXAlignment.Left

    -- 2. CHAT AREA (ScrollingFrame) (LayoutOrder = 1)
    -- Menggunakan ukuran relatif sisa layar (misal: Scale 1 dikurangi tinggi komponen lain)
    local chatArea = Instance.new("ScrollingFrame", appContent)
    chatArea.Size = UDim2.new(1, 0, 1, -170)
    chatArea.BackgroundColor3 = colors.card2
    chatArea.BorderSizePixel = 0
    chatArea.ScrollBarThickness = 3
    chatArea.ScrollBarImageColor3 = colors.accent
    chatArea.CanvasSize = UDim2.new(0, 0, 0, 0)
    chatArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
    chatArea.LayoutOrder = 1
    corner(chatArea, 10)
    stroke(chatArea, colors.border, 1)
    
    local chatPadding = Instance.new("UIPadding", chatArea)
    chatPadding.PaddingLeft = UDim.new(0, 10)
    chatPadding.PaddingRight = UDim.new(0, 10)
    chatPadding.PaddingTop = UDim.new(0, 10)
    chatPadding.PaddingBottom = UDim.new(0, 10)
    
    local chatList = Instance.new("UIListLayout", chatArea)
    chatList.Padding = UDim.new(0, 10)
    chatList.SortOrder = Enum.SortOrder.LayoutOrder
    chatList.VerticalAlignment = Enum.VerticalAlignment.Bottom
    
    -- Welcome Message
    local welcomeText = "Halo! Saya PhoneAI, asisten pintar di Phone ID Viewer.\n\nSilakan tanya apa saja tentang game atau fitur aplikasi ini!"
    buildChatBubble(chatArea, welcomeText, false, 0)

    -- 3. QUICK SUGGESTIONS (LayoutOrder = 2)
    local suggestionContainer = Instance.new("Frame", appContent)
    suggestionContainer.Size = UDim2.new(1, 0, 0, 26)
    suggestionContainer.BackgroundTransparency = 1
    suggestionContainer.LayoutOrder = 2
    
    local suggestionLayout = Instance.new("UIGridLayout", suggestionContainer)
    suggestionLayout.CellSize = UDim2.new(1/3, -3, 0, 26)
    suggestionLayout.CellPadding = UDim2.new(0, 4, 0, 0)
    
    local suggestions = { "Apa itu Phone ID?", "Tips pro", "Fitur" }
    for _, suggestion in ipairs(suggestions) do
        local suggBtn = Instance.new("TextButton", suggestionContainer)
        suggBtn.Size = UDim2.new(1, 0, 0, 26)
        suggBtn.BackgroundColor3 = colors.card
        suggBtn.Text = suggestion
        suggBtn.TextColor3 = colors.text2
        suggBtn.Font = Enum.Font.GothamBold
        suggBtn.TextSize = 9
        suggBtn.AutoButtonColor = false
        corner(suggBtn, 6)
        stroke(suggBtn, colors.border, 1)
        
        suggBtn.MouseButton1Click:Connect(function()
            -- trigger send suggestion logic
        end)
    end

    -- 4. INPUT AREA (LayoutOrder = 3)
    local inputContainer = Instance.new("Frame", appContent)
    inputContainer.Size = UDim2.new(1, 0, 0, 45)
    inputContainer.BackgroundColor3 = colors.card
    inputContainer.LayoutOrder = 3
    corner(inputContainer, 10)
    stroke(inputContainer, colors.border, 1)
    
    local inputField = Instance.new("TextBox", inputContainer)
    inputField.Size = UDim2.new(1, -55, 0, 31)
    inputField.Position = UDim2.new(0, 8, 0, 7)
    inputField.PlaceholderText = "Tulis pesan..."
    inputField.PlaceholderColor3 = colors.text3
    inputField.Text = ""
    inputField.TextColor3 = colors.text
    inputField.Font = Enum.Font.Gotham
    inputField.TextSize = 12
    inputField.ClearTextOnFocus = false
    inputField.BackgroundColor3 = colors.card2
    corner(inputField, 6)
    
    local sendBtn = Instance.new("TextButton", inputContainer)
    sendBtn.Size = UDim2.new(0, 35, 0, 31)
    sendBtn.Position = UDim2.new(1, -43, 0, 7)
    sendBtn.BackgroundColor3 = colors.accent
    sendBtn.Text = "➤"
    sendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    sendBtn.Font = Enum.Font.GothamBold
    sendBtn.TextSize = 14
    corner(sendBtn, 6)
    
    -- Send Logic
    local function sendMessage()
        local message = inputField.Text:gsub("^%s+", ""):gsub("%s+$", "")
        if message == "" or aiState.isGenerating then return end
        
        inputField.Text = ""
        buildChatBubble(chatArea, message, true, #chatArea:GetChildren())
        chatArea.CanvasPosition = Vector2.new(0, chatArea.AbsoluteCanvasSize.Y)
        
        table.insert(aiState.history, {role = "user", content = message})
        if #aiState.history > 20 then table.remove(aiState.history, 1) end
        
        aiState.isGenerating = true
        sendBtn.Text = "..."
        local typingBubble = buildChatBubble(chatArea, "...", false, #chatArea:GetChildren())
        
        task.spawn(function()
            local messages = {{role = "system", content = SYSTEM_PROMPT}}
            for _, msg in ipairs(aiState.history) do table.insert(messages, msg) end
            
            local response, err = sendGroqRequest(messages)
            aiState.isGenerating = false
            sendBtn.Text = "➤"
            
            pcall(function() typingBubble:Destroy() end)
            
            if response and response ~= "" then
                buildChatBubble(chatArea, response, false, #chatArea:GetChildren())
                table.insert(aiState.history, {role = "assistant", content = response})
            else
                buildChatBubble(chatArea, "Maaf, terjadi kesalahan koneksi AI.", false, #chatArea:GetChildren())
            end
            chatArea.CanvasPosition = Vector2.new(0, chatArea.AbsoluteCanvasSize.Y)
        end)
    end
    
    sendBtn.MouseButton1Click:Connect(sendMessage)
    inputField.FocusLost:Connect(function(enterPressed)
        if enterPressed then sendMessage() end
    end)
end

print("[ChatAI] App successfully fixed and loaded!")
