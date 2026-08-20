-- ================================================
-- MyClone.lua - MyClone App (Rewritten for Phone UI)
-- Fixed: SetGizmoVisibility, EditMode toggle, gizmo drag handlers
-- ================================================

local Services = _G.Services
local Players = Services.Players
local Workspace = Services.Workspace
local TweenService = Services.TweenService
local UserInputService = Services.UserInputService
local HttpService = Services.HttpService
local RunService = Services.RunService
local CoreGui = Services.CoreGui
local TextChatService = Services.TextChatService
local ChatService = Services.Chat

local LocalPlayer = Players.LocalPlayer
local T = _G.T or {}
local Helpers = _G.Helpers or {}
local Storage = _G.Storage or {}

-- Alias helpers
local corner = Helpers.corner
local stroke = Helpers.stroke
local tween = Helpers.tween
local pressFX = Helpers.pressFX

-- ================================================
-- CONSTANTS & STATE
-- ================================================
local FOLDER_NAME = "MyCloneFolder_V15"
local CONFIG_FILE = "MyClone_Config.json"
local HISTORY_FILE = "MyClone_History.json"
local FAVORITES_FILE = "MyClone_Favorites.json"
local API_KEY_FILE = "MyClone_ApiKey.txt"

local COLORS = {
    Background = Color3.fromRGB(12, 13, 18),
    Panel = Color3.fromRGB(20, 22, 30),
    Panel2 = Color3.fromRGB(28, 30, 42),
    Panel3 = Color3.fromRGB(36, 39, 54),
    White = Color3.fromRGB(250, 250, 255),
    SoftWhite = Color3.fromRGB(210, 215, 230),
    Gray = Color3.fromRGB(135, 140, 160),
    DarkGray = Color3.fromRGB(75, 80, 95),
    Red = Color3.fromRGB(255, 65, 85),
    RedDark = Color3.fromRGB(180, 35, 55),
    Purple = Color3.fromRGB(140, 80, 255),
    PurpleDark = Color3.fromRGB(90, 45, 180),
    Green = Color3.fromRGB(50, 225, 130),
    Blue = Color3.fromRGB(60, 160, 255),
    Orange = Color3.fromRGB(255, 150, 50),
    Delete = Color3.fromRGB(95, 28, 38),
    DeleteActive = Color3.fromRGB(160, 35, 50),
}

local CloneData = {}
local SelectedClone = nil
local CloneCounter = 0

local EditMode = false
local PositionMode = false
local RotationMode = false
local DanceMode = false
local SyncTargetMode = false
local SyncTargetPlayer = nil

local CurrentAnimatorConnection = nil
local SyncLoop = nil
local GizmoDragging = false
local CameraRestoreType = nil
local CameraRestoreSubject = nil
local DeleteAllArmed = false

local CurrentEmoteTrack = nil
local EmoteSpeed = 1
local EmoteLoop = true

local HistoryList = {}
local FavoritesList = {}

local HideAllNames = false
local AIChatEnabled = false
local AIChatLoop = nil
local AIChatCooldown = 10
local AIChatLastTime = 0

-- Groq API key (user-provided)
local GroqApiKey = nil

-- Models fallback
local GROQ_MODELS = {
    "llama-3.3-70b-versatile",
    "llama-3.1-8b-instant",
    "llama-3.1-70b-versatile",
    "llama3-8b-8192",
    "llama3-70b-8192",
    "mixtral-8x7b-32768",
    "deepseek-r1-distill-llama-70b",
    "qwen-2.5-32b",
    "mistral-saba-24b",
}

-- UI references for active tab
local currentTab = "Clones"
local tabBar = nil
local tabContentFrame = nil
local mainContainer = nil

-- Gizmos
local PositionGizmo = nil
local RotationGizmo = nil

-- ================================================
-- UTILITY FUNCTIONS
-- ================================================
local function GetDisplayName(userId)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.UserId == userId then return player.DisplayName end
    end
    local success, data = pcall(function()
        return game:HttpGet("https://users.roblox.com/v1/users/" .. userId)
    end)
    if success and data then
        local parsed = HttpService:JSONDecode(data)
        if parsed and parsed.displayName then return parsed.displayName end
    end
    return nil
end

local function ResolveUserId(value)
    value = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if value == "" then return LocalPlayer.UserId, true end
    local number = tonumber(value)
    if number then return number, false end
    local success, userId = pcall(function() return Players:GetUserIdFromNameAsync(value) end)
    if success and userId then return userId, false end
    return nil, false
end

local function CreateAvatarFromUserId(userId)
    local success, model = pcall(function() return Players:CreateHumanoidModelFromUserIdAsync(userId) end)
    if success and model then return model end
    local descSuccess, description = pcall(function() return Players:GetHumanoidDescriptionFromUserIdAsync(userId) end)
    if descSuccess and description then
        local modelSuccess, generated = pcall(function()
            return Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15, Enum.AssetTypeVerification.Default)
        end)
        if modelSuccess then return generated end
    end
    return nil
end

local function PrepareCloneModel(model)
    if not model then return end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
    for _, object in ipairs(model:GetDescendants()) do
        if object:IsA("Script") or object:IsA("LocalScript") or object:IsA("ModuleScript") then
            object:Destroy()
        end
    end
    local root = model:FindFirstChild("HumanoidRootPart")
    if root then model.PrimaryPart = root else
        local part = model:FindFirstChildOfClass("BasePart")
        if part then model.PrimaryPart = part end
    end
    pcall(function() model:MakeJoints() end)
end

local function GetNextSpawnCFrame()
    local character = LocalPlayer.Character
    if not character then return CFrame.new(0, 3, -5) end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return CFrame.new(0, 3, -5) end
    return root.CFrame
end

local function IsSyncTrack(track)
    local priority = track.Priority
    if priority == Enum.AnimationPriority.Action or
        priority == Enum.AnimationPriority.Action2 or
        priority == Enum.AnimationPriority.Action3 or
        priority == Enum.AnimationPriority.Action4 then
        return true
    end
    local name = string.lower(track.Name or "")
    if string.find(name, "walk") or string.find(name, "run") or
        string.find(name, "jump") or string.find(name, "fall") or
        string.find(name, "idle") or string.find(name, "climb") or
        string.find(name, "swim") or string.find(name, "sit") or
        string.find(name, "sleep") then
        return false
    end
    if string.find(name, "dance") or string.find(name, "emote") or
        string.find(name, "wave") or string.find(name, "laugh") or
        string.find(name, "cheer") or string.find(name, "point") or
        string.find(name, "salute") or string.find(name, "shrug") or
        string.find(name, "talk") then
        return true
    end
    return false
end

local function GetAnimator(character)
    if not character then return nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return nil end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if animator then return animator end
    animator = Instance.new("Animator")
    animator.Parent = humanoid
    return animator
end

local function StopAllCloneEmotes()
    local folder = Workspace:FindFirstChild(FOLDER_NAME)
    if not folder then return end
    for _, clone in ipairs(folder:GetChildren()) do
        if clone:IsA("Model") then
            local animator = GetAnimator(clone)
            if animator then
                for _, trk in ipairs(animator:GetPlayingAnimationTracks()) do
                    if IsSyncTrack(trk) then trk:Stop() end
                end
            end
        end
    end
end

local function PlayTrackOnClone(clone, sourceTrack)
    if not clone or not sourceTrack or not sourceTrack.Animation then return end
    local animator = GetAnimator(clone)
    if not animator then return end
    local animation = sourceTrack.Animation
    if not animation.AnimationId or animation.AnimationId == "" then return end
    for _, trk in ipairs(animator:GetPlayingAnimationTracks()) do
        if trk.Animation and trk.Animation.AnimationId == animation.AnimationId then
            trk:AdjustSpeed(sourceTrack.Speed)
            return trk
        end
    end
    local success, cloneTrack = pcall(function() return animator:LoadAnimation(animation) end)
    if not success or not cloneTrack then return end
    cloneTrack.Priority = sourceTrack.Priority
    cloneTrack.Looped = sourceTrack.Looped
    cloneTrack:Play(0.1, 1, math.max(sourceTrack.Speed, 0.1))
    return cloneTrack
end

local function ApplyDanceToSelected(callback)
    if SelectedClone and SelectedClone.Parent then callback(SelectedClone) end
end

local function ApplySyncToAll(callback)
    local folder = Workspace:FindFirstChild(FOLDER_NAME)
    if not folder then return end
    for _, clone in ipairs(folder:GetChildren()) do
        if clone:IsA("Model") then callback(clone) end
    end
end

local function StartSyncLoop()
    if SyncLoop then SyncLoop:Disconnect(); SyncLoop = nil end
    if not (DanceMode or SyncTargetMode) then return end

    SyncLoop = RunService.Heartbeat:Connect(function()
        if not (DanceMode or SyncTargetMode) then return end
        local sourcePlayer = SyncTargetMode and SyncTargetPlayer or (DanceMode and LocalPlayer or nil)
        if not sourcePlayer then return end
        local character = sourcePlayer.Character
        if not character then return end
        local sourceAnimator = GetAnimator(character)
        if not sourceAnimator then return end
        local sourceTracks = sourceAnimator:GetPlayingAnimationTracks()
        local currentSyncAnimIds = {}
        for _, track in ipairs(sourceTracks) do
            if track.IsPlaying and IsSyncTrack(track) then
                currentSyncAnimIds[track.Animation.AnimationId] = track
            end
        end

        local applyFunc = DanceMode and ApplyDanceToSelected or ApplySyncToAll
        applyFunc(function(clone)
            local cloneAnimator = GetAnimator(clone)
            if not cloneAnimator then return end
            for _, cloneTrack in ipairs(cloneAnimator:GetPlayingAnimationTracks()) do
                if IsSyncTrack(cloneTrack) and not currentSyncAnimIds[cloneTrack.Animation.AnimationId] then
                    cloneTrack:Stop()
                end
            end
            for _, sourceTrack in pairs(currentSyncAnimIds) do
                PlayTrackOnClone(clone, sourceTrack)
            end
        end)
    end)
end

local function StopSyncSystem()
    if SyncLoop then SyncLoop:Disconnect(); SyncLoop = nil end
    if CurrentAnimatorConnection then CurrentAnimatorConnection:Disconnect(); CurrentAnimatorConnection = nil end
    StopAllCloneEmotes()
end

local function SetupDanceSync()
    StopSyncSystem()
    if not (DanceMode or SyncTargetMode) then return end
    local sourcePlayer = SyncTargetMode and SyncTargetPlayer or (DanceMode and LocalPlayer or nil)
    if not sourcePlayer then return end
    local character = sourcePlayer.Character
    if not character then return end
    local animator = GetAnimator(character)
    if not animator then return end
    CurrentAnimatorConnection = animator.AnimationPlayed:Connect(function(track)
        if not (DanceMode or SyncTargetMode) then return end
        if not IsSyncTrack(track) then return end
        task.wait(0.05)
        if DanceMode then
            ApplyDanceToSelected(function(clone) PlayTrackOnClone(clone, track) end)
        elseif SyncTargetMode then
            ApplySyncToAll(function(clone) PlayTrackOnClone(clone, track) end)
        end
    end)
    StartSyncLoop()
end

local function CreateNameTag(clone, nameText, hide)
    local oldTag = clone:FindFirstChild("NameTag")
    if oldTag then oldTag:Destroy() end
    if hide or HideAllNames then return end

    local head = clone:FindFirstChild("Head") or clone.PrimaryPart
    if not head then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NameTag"
    billboard.Size = UDim2.new(0, 200, 0, 24)
    billboard.StudsOffset = Vector3.new(0, 2.6, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 50
    billboard.Adornee = head
    billboard.Parent = clone

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = nameText
    label.TextColor3 = COLORS.White
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextStrokeTransparency = 0.4
    label.TextStrokeColor3 = Color3.fromRGB(0,0,0)
    label.Parent = billboard

    return billboard
end

local function SetGizmoVisibility()
    if not PositionGizmo or not RotationGizmo then return end
    PositionGizmo.Adornee = nil
    RotationGizmo.Adornee = nil
    if not SelectedClone or not EditMode then return end
    local root = SelectedClone.PrimaryPart
    if not root then return end
    if PositionMode then PositionGizmo.Adornee = root end
    if RotationMode then RotationGizmo.Adornee = root end
end

local function SelectClone(clone)
    if not clone or not clone:IsDescendantOf(Workspace:FindFirstChild(FOLDER_NAME)) then return end
    SelectedClone = clone
    -- Update UI if in Editor tab
    if currentTab == "Editor" and tabContentFrame then
        rebuildEditorTab()
    end
end

local function SaveHistory()
    pcall(function()
        if writefile then writefile(HISTORY_FILE, HttpService:JSONEncode(HistoryList)) end
    end)
end

local function LoadHistory()
    pcall(function()
        if isfile and readfile and isfile(HISTORY_FILE) then
            local data = HttpService:JSONDecode(readfile(HISTORY_FILE))
            if type(data) == "table" then HistoryList = data end
        end
    end)
end

local function SaveFavorites()
    pcall(function()
        if writefile then writefile(FAVORITES_FILE, HttpService:JSONEncode(FavoritesList)) end
    end)
end

local function LoadFavorites()
    pcall(function()
        if isfile and readfile and isfile(FAVORITES_FILE) then
            local data = HttpService:JSONDecode(readfile(FAVORITES_FILE))
            if type(data) == "table" then FavoritesList = data end
        end
    end)
end

local function SaveApiKey()
    pcall(function()
        if writefile and GroqApiKey then writefile(API_KEY_FILE, GroqApiKey) end
    end)
    if Storage and Storage.appSettings then
        Storage.appSettings.groqApiKey = GroqApiKey
        if Storage.persistSettings then pcall(Storage.persistSettings) end
    end
end

local function LoadApiKey()
    pcall(function()
        if isfile and readfile and isfile(API_KEY_FILE) then
            GroqApiKey = readfile(API_KEY_FILE)
        end
    end)
    if not GroqApiKey and Storage and Storage.appSettings and Storage.appSettings.groqApiKey then
        GroqApiKey = Storage.appSettings.groqApiKey
    end
end

-- ================================================
-- CLONE CREATION
-- ================================================
local function CreateCloneFromUserId(userId, displayName, username)
    if not userId then return end

    local model = nil
    local dispName = displayName
    local uname = username or "Unknown"

    for _, player in ipairs(Players:GetPlayers()) do
        if player.UserId == userId then
            if not dispName then dispName = player.DisplayName end
            if not uname or uname == "Unknown" then uname = player.Name end
            if player.Character then
                player.Character.Archivable = true
                local success, result = pcall(function() return player.Character:Clone() end)
                if success and result then model = result end
            end
            break
        end
    end

    if not model then model = CreateAvatarFromUserId(userId) end
    if not dispName then dispName = GetDisplayName(userId) or uname end
    if not model then return end

    CloneCounter += 1
    local cloneName = "Clone_" .. tostring(CloneCounter)
    model.Name = cloneName
    PrepareCloneModel(model)

    local spawnCFrame = GetNextSpawnCFrame()
    model:PivotTo(spawnCFrame)

    local rootPart = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    if rootPart then
        rootPart.Anchored = true
        rootPart.CanCollide = false
        rootPart.Transparency = 1
    end

    local cloneData = {
        Index = CloneCounter,
        UserId = userId,
        Username = uname,
        DisplayName = dispName,
        OriginalCFrame = spawnCFrame,
        OriginalRotation = spawnCFrame - spawnCFrame.Position,
        HideName = false,
    }
    CloneData[model] = cloneData
    model.Parent = Workspace:FindFirstChild(FOLDER_NAME)

    CreateNameTag(model, dispName, false)
    SelectClone(model)

    -- Add to history
    local alreadyInHistory = false
    for _, entry in ipairs(HistoryList) do
        if entry.userId == userId then alreadyInHistory = true break end
    end
    if not alreadyInHistory then
        table.insert(HistoryList, {userId = userId, displayName = dispName, username = uname})
        SaveHistory()
    end

    if DanceMode or SyncTargetMode then SetupDanceSync() end

    -- Refresh UI if in Clones or History tab
    if currentTab == "Clones" then rebuildClonesTab() end
    if currentTab == "History" then rebuildHistoryTab() end
end

local function CreateCloneFromInput(inputText)
    local userId, isSelf = ResolveUserId(inputText)
    if not userId then return end
    local dispName = nil
    local uname = nil
    for _, player in ipairs(Players:GetPlayers()) do
        if player.UserId == userId then
            dispName = player.DisplayName
            uname = player.Name
            break
        end
    end
    if not dispName then dispName = GetDisplayName(userId) or "Unknown" end
    if not uname then uname = "Unknown" end
    CreateCloneFromUserId(userId, dispName, uname)
end

-- ================================================
-- HTTP & AI
-- ================================================
local function performHttpPost(url, headers, body)
    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url = url,
            Method = "POST",
            Headers = headers,
            Body = body,
        })
    end)
    if success and response and response.Success and response.StatusCode >= 200 and response.StatusCode < 300 then
        return response.Body
    end

    if syn and syn.request then
        local success, response = pcall(function()
            return syn.request({Url = url, Method = "POST", Headers = headers, Body = body})
        end)
        if success and response and response.Body then return response.Body end
    end
    if http_request then
        local success, response = pcall(function()
            return http_request({Url = url, Method = "POST", Headers = headers, Body = body})
        end)
        if success and response and response.Body then return response.Body end
    end
    if request then
        local success, response = pcall(function()
            return request({Url = url, Method = "POST", Headers = headers, Body = body})
        end)
        if success and response and response.Body then return response.Body end
    end
    return nil
end

local function SendGroqMessage(prompt, systemPrompt)
    if not GroqApiKey or GroqApiKey == "" then
        return nil, "API key belum diisi"
    end
    local url = "https://api.groq.com/openai/v1/chat/completions"
    local headers = {
        ["Authorization"] = "Bearer " .. GroqApiKey,
        ["Content-Type"] = "application/json",
    }
    local lastError = nil

    for _, model in ipairs(GROQ_MODELS) do
        local body = HttpService:JSONEncode({
            model = model,
            messages = {
                {role = "system", content = systemPrompt or "Kamu adalah asisten yang menjawab singkat dalam bahasa gaul Indonesia, maksimal 10 kata, santai dan natural."},
                {role = "user", content = prompt},
            },
            temperature = 0.9,
            max_tokens = 100,
        })

        local responseBody = performHttpPost(url, headers, body)
        if responseBody then
            local success, decoded = pcall(function() return HttpService:JSONDecode(responseBody) end)
            if success and decoded and not decoded.error then
                if decoded.choices and decoded.choices[1] and decoded.choices[1].message then
                    local content = decoded.choices[1].message.content
                    print("[AI Chat] Berhasil dengan model:", model, "->", content)
                    return content
                end
            elseif decoded and decoded.error then
                lastError = decoded.error.message or "unknown"
                warn("[AI Chat] Model", model, "error:", lastError)
            end
        end
    end
    return nil, lastError
end

local function DisplayCloneBubble(clone, message)
    if not clone or not message then return end
    local head = clone:FindFirstChild("Head") or clone.PrimaryPart
    if not head then return end

    local success = pcall(function()
        TextChatService:DisplayBubble(clone, message)
    end)
    if success then return end

    local bubble = Instance.new("BillboardGui")
    bubble.Name = "ChatBubble"
    bubble.Size = UDim2.new(0, 200, 0, 40)
    bubble.StudsOffset = Vector3.new(0, 3, 0)
    bubble.AlwaysOnTop = true
    bubble.Adornee = head
    bubble.Parent = clone

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(255,255,255)
    bg.BorderSizePixel = 0
    bg.Parent = bubble
    corner(bg, 10)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 1, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = message
    label.TextColor3 = Color3.fromRGB(20,20,30)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Parent = bg

    task.delay(5, function()
        if bubble.Parent then bubble:Destroy() end
    end)
end

local function DoAIChatOnce()
    local folder = Workspace:FindFirstChild(FOLDER_NAME)
    if not folder then return false, "Folder belum ada" end
    local clones = {}
    for _, clone in ipairs(folder:GetChildren()) do
        if clone:IsA("Model") then table.insert(clones, clone) end
    end
    if #clones < 2 then return false, "Butuh minimal 2 clone" end

    local clone1 = clones[math.random(1, #clones)]
    local clone2
    repeat clone2 = clones[math.random(1, #clones)] until clone2 ~= clone1

    local prompt = "Buat percakapan singkat dua orang dalam bahasa gaul Indonesia. Format:\nA: [pesan]\nB: [pesan]\nMaksimal 3 kata per pesan, santai."
    local response, err = SendGroqMessage(prompt, "Kamu adalah AI yang membuat percakapan gaul Indonesia singkat. Output harus dua baris dimulai dengan 'A:' dan 'B:'.")
    if response then
        local lines = {}
        for line in response:gmatch("[^\n]+") do table.insert(lines, line) end
        local msg1, msg2
        if #lines >= 2 then
            msg1 = lines[1]:gsub("^%s*A%s*:%s*", "")
            msg2 = lines[2]:gsub("^%s*B%s*:%s*", "")
            if #msg1 > 0 and #msg2 > 0 then
                DisplayCloneBubble(clone1, msg1)
                task.wait(2)
                DisplayCloneBubble(clone2, msg2)
                return true
            end
        end
    else
        return false, err or "Gagal AI"
    end
end

local function StartAIChat()
    if AIChatLoop then return end
    AIChatLoop = task.spawn(function()
        while AIChatEnabled do
            if os.clock() - AIChatLastTime >= AIChatCooldown then
                AIChatLastTime = os.clock()
                DoAIChatOnce()
            end
            task.wait(2)
        end
    end)
end

local function StopAIChat()
    AIChatEnabled = false
    AIChatLoop = nil
end

-- ================================================
-- UI HELPERS
-- ================================================
local function makeLabel(text, size, color, font, parent)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = color or T.Text or Color3.fromRGB(30,30,30)
    lbl.Font = font or Enum.Font.GothamMedium
    lbl.TextSize = size or 11
    lbl.Parent = parent
    return lbl
end

local function makeButton(text, color, parent, size)
    local btn = Instance.new("TextButton")
    btn.Size = size or UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = color or T.Card or Color3.fromRGB(245,245,245)
    btn.Text = text
    btn.TextColor3 = T.Text or Color3.fromRGB(30,30,30)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.AutoButtonColor = false
    btn.Parent = parent
    corner(btn, 8)
    pressFX(btn)
    return btn
end

local function makeInput(placeholder, parent)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 36)
    frame.BackgroundColor3 = T.Card or Color3.fromRGB(245,245,245)
    frame.Parent = parent
    corner(frame, 8)

    local tb = Instance.new("TextBox")
    tb.Size = UDim2.new(1, -16, 1, 0)
    tb.Position = UDim2.new(0, 8, 0, 0)
    tb.BackgroundTransparency = 1
    tb.PlaceholderText = placeholder or ""
    tb.PlaceholderColor3 = Color3.fromRGB(150,150,150)
    tb.TextColor3 = T.Text or Color3.fromRGB(30,30,30)
    tb.Font = Enum.Font.Gotham
    tb.TextSize = 11
    tb.ClearTextOnFocus = false
    tb.TextXAlignment = Enum.TextXAlignment.Left
    tb.Parent = frame
    return tb, frame
end

-- ================================================
-- TAB BUILDERS (fixed with proper clearing)
-- ================================================
local function clearTabContent()
    for _, child in ipairs(tabContentFrame:GetChildren()) do
        child:Destroy()
    end
    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 6)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = tabContentFrame
end

local function rebuildClonesTab()
    clearTabContent()
    local list = tabContentFrame:FindFirstChildOfClass("UIListLayout")

    local inputLabel = makeLabel("Username / User ID:", 10, COLORS.Gray, Enum.Font.GothamBold, tabContentFrame)
    inputLabel.LayoutOrder = 1
    local inputBox, inputFrame = makeInput("Masukkan target...", tabContentFrame)
    inputFrame.LayoutOrder = 2

    local cloneBtn = makeButton("CLONE", COLORS.Red, tabContentFrame)
    cloneBtn.LayoutOrder = 3
    cloneBtn.MouseButton1Click:Connect(function()
        CreateCloneFromInput(inputBox.Text)
        inputBox.Text = ""
    end)

    local cloneAllBtn = makeButton("CLONE SEMUA PLAYER", COLORS.Green, tabContentFrame)
    cloneAllBtn.LayoutOrder = 4
    cloneAllBtn.MouseButton1Click:Connect(function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                CreateCloneFromUserId(player.UserId, player.DisplayName, player.Name)
            end
        end
    end)

    local clonesLabel = makeLabel("Active Clones:", 10, COLORS.Gray, Enum.Font.GothamBold, tabContentFrame)
    clonesLabel.LayoutOrder = 5

    local folder = Workspace:FindFirstChild(FOLDER_NAME)
    if folder then
        local index = 6
        for _, clone in ipairs(folder:GetChildren()) do
            if clone:IsA("Model") then
                local cloneButton = makeButton(clone.Name, COLORS.Panel, tabContentFrame)
                cloneButton.LayoutOrder = index
                cloneButton.MouseButton1Click:Connect(function()
                    SelectClone(clone)
                end)
                index = index + 1
            end
        end
    end
end

local function rebuildEditorTab()
    clearTabContent()
    local list = tabContentFrame:FindFirstChildOfClass("UIListLayout")

    -- Edit Mode toggle
    local editModeBtn = makeButton(EditMode and "EDIT MODE: ON" or "EDIT MODE: OFF", EditMode and COLORS.Green or COLORS.Panel, tabContentFrame)
    editModeBtn.LayoutOrder = 1
    editModeBtn.MouseButton1Click:Connect(function()
        EditMode = not EditMode
        if not EditMode then
            PositionMode = false
            RotationMode = false
            SetGizmoVisibility()
        end
        rebuildEditorTab()
    end)

    -- Selected clone info
    local selectedFrame = Instance.new("Frame")
    selectedFrame.Size = UDim2.new(1, 0, 0, 80)
    selectedFrame.BackgroundColor3 = COLORS.Panel
    selectedFrame.LayoutOrder = 2
    selectedFrame.Parent = tabContentFrame
    corner(selectedFrame, 10)

    local selName = makeLabel(SelectedClone and SelectedClone.Name or "Tidak ada clone terpilih", 12, COLORS.White, Enum.Font.GothamBold, selectedFrame)
    selName.Position = UDim2.new(0, 10, 0, 5)
    selName.Size = UDim2.new(1, -20, 0, 20)
    selName.TextXAlignment = Enum.TextXAlignment.Left

    local selInfo = makeLabel(SelectedClone and "Clone #"..(CloneData[SelectedClone] and CloneData[SelectedClone].Index or "?") or "Klik clone untuk memilih", 9, COLORS.Gray, nil, selectedFrame)
    selInfo.Position = UDim2.new(0, 10, 0, 28)
    selInfo.Size = UDim2.new(1, -20, 0, 16)
    selInfo.TextXAlignment = Enum.TextXAlignment.Left

    local renameBox = Instance.new("TextBox")
    renameBox.Size = UDim2.new(1, -60, 0, 24)
    renameBox.Position = UDim2.new(0, 10, 0, 48)
    renameBox.BackgroundColor3 = COLORS.Panel2
    renameBox.PlaceholderText = "Rename..."
    renameBox.PlaceholderColor3 = COLORS.DarkGray
    renameBox.TextColor3 = COLORS.White
    renameBox.Font = Enum.Font.Gotham
    renameBox.TextSize = 10
    renameBox.ClearTextOnFocus = false
    renameBox.Parent = selectedFrame
    corner(renameBox, 4)

    local renameBtn = makeButton("SIMPAN", COLORS.Orange, selectedFrame, UDim2.new(0, 50, 0, 24))
    renameBtn.Position = UDim2.new(1, -55, 0, 48)
    renameBtn.TextColor3 = COLORS.Background
    renameBtn.MouseButton1Click:Connect(function()
        if not SelectedClone then return end
        local newName = renameBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
        if newName == "" then return end
        SelectedClone.Name = newName
        if CloneData[SelectedClone] then CloneData[SelectedClone].Name = newName end
        local data = CloneData[SelectedClone]
        if data then CreateNameTag(SelectedClone, data.DisplayName or newName, data.HideName) end
        rebuildEditorTab()
    end)

    -- Hide name button
    local hideBtn = makeButton(SelectedClone and (CloneData[SelectedClone] and CloneData[SelectedClone].HideName and "SHOW NAME" or "HIDE NAME") or "HIDE NAME", COLORS.Panel2, tabContentFrame)
    hideBtn.LayoutOrder = 3
    hideBtn.MouseButton1Click:Connect(function()
        if not SelectedClone or not CloneData[SelectedClone] then return end
        local data = CloneData[SelectedClone]
        data.HideName = not data.HideName
        if data.HideName or HideAllNames then
            local tag = SelectedClone:FindFirstChild("NameTag")
            if tag then tag:Destroy() end
        else
            CreateNameTag(SelectedClone, data.DisplayName or SelectedClone.Name, false)
        end
        rebuildEditorTab()
    end)

    -- Position toggle
    local posBtn = makeButton(PositionMode and "POSISI: ON" or "POSISI: OFF", PositionMode and COLORS.RedDark or COLORS.Panel, tabContentFrame)
    posBtn.LayoutOrder = 4
    posBtn.MouseButton1Click:Connect(function()
        if not EditMode then return end
        PositionMode = not PositionMode
        if PositionMode then RotationMode = false end
        SetGizmoVisibility()
        rebuildEditorTab()
    end)

    -- Rotation toggle
    local rotBtn = makeButton(RotationMode and "ROTASI: ON" or "ROTASI: OFF", RotationMode and COLORS.PurpleDark or COLORS.Panel, tabContentFrame)
    rotBtn.LayoutOrder = 5
    rotBtn.MouseButton1Click:Connect(function()
        if not EditMode then return end
        RotationMode = not RotationMode
        if RotationMode then PositionMode = false end
        SetGizmoVisibility()
        rebuildEditorTab()
    end)

    -- Dance mode
    local danceBtn = makeButton(DanceMode and "DANCE: ON" or "DANCE: OFF", DanceMode and COLORS.PurpleDark or COLORS.Panel, tabContentFrame)
    danceBtn.LayoutOrder = 6
    danceBtn.MouseButton1Click:Connect(function()
        if not EditMode then return end
        DanceMode = not DanceMode
        SyncTargetMode = false
        if DanceMode then
            if not SelectedClone then DanceMode = false else SetupDanceSync() end
        else
            StopSyncSystem()
        end
        rebuildEditorTab()
    end)

    -- Bring to player
    local bringBtn = makeButton("BAWA KE PLAYER", COLORS.Blue, tabContentFrame)
    bringBtn.LayoutOrder = 7
    bringBtn.MouseButton1Click:Connect(function()
        local character = LocalPlayer.Character
        if not character then return end
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local targetCFrame = root.CFrame
        local folder = Workspace:FindFirstChild(FOLDER_NAME)
        if folder then
            for _, clone in ipairs(folder:GetChildren()) do
                if clone:IsA("Model") and clone.PrimaryPart then clone:PivotTo(targetCFrame) end
            end
        end
    end)

    -- Reset position
    local resetPosBtn = makeButton("RESET POSISI", COLORS.Orange, tabContentFrame)
    resetPosBtn.LayoutOrder = 8
    resetPosBtn.MouseButton1Click:Connect(function()
        if not SelectedClone or not CloneData[SelectedClone] then return end
        local data = CloneData[SelectedClone]
        local primary = SelectedClone.PrimaryPart
        if not primary then return end
        local currentRotation = primary.CFrame - primary.CFrame.Position
        SelectedClone:PivotTo(CFrame.new(data.OriginalCFrame.Position) * currentRotation)
    end)

    -- Reset rotation
    local resetRotBtn = makeButton("RESET ROTASI", COLORS.Orange, tabContentFrame)
    resetRotBtn.LayoutOrder = 9
    resetRotBtn.MouseButton1Click:Connect(function()
        if not SelectedClone or not CloneData[SelectedClone] then return end
        local data = CloneData[SelectedClone]
        local primary = SelectedClone.PrimaryPart
        if not primary then return end
        SelectedClone:PivotTo(CFrame.new(primary.CFrame.Position) * data.OriginalRotation)
    end)

    -- Delete selected
    local delBtn = makeButton("HAPUS SELECTED", COLORS.Delete, tabContentFrame)
    delBtn.LayoutOrder = 10
    delBtn.MouseButton1Click:Connect(function()
        if not SelectedClone then return end
        local target = SelectedClone
        CloneData[target] = nil
        SelectedClone = nil
        SetGizmoVisibility()
        target:Destroy()
        rebuildEditorTab()
        if currentTab == "Clones" then rebuildClonesTab() end
    end)

    -- Delete all
    local delAllBtn = makeButton("HAPUS SEMUA", COLORS.Delete, tabContentFrame)
    delAllBtn.LayoutOrder = 11
    delAllBtn.MouseButton1Click:Connect(function()
        if not DeleteAllArmed then
            DeleteAllArmed = true
            delAllBtn.Text = "KONFIRMASI?"
            delAllBtn.BackgroundColor3 = COLORS.DeleteActive
            task.delay(3, function()
                if DeleteAllArmed then
                    DeleteAllArmed = false
                    delAllBtn.Text = "HAPUS SEMUA"
                    delAllBtn.BackgroundColor3 = COLORS.Delete
                end
            end)
            return
        end
        DeleteAllArmed = false
        local folder = Workspace:FindFirstChild(FOLDER_NAME)
        if folder then
            for _, clone in ipairs(folder:GetChildren()) do clone:Destroy() end
        end
        table.clear(CloneData)
        SelectedClone = nil
        SetGizmoVisibility()
        delAllBtn.Text = "HAPUS SEMUA"
        delAllBtn.BackgroundColor3 = COLORS.Delete
        rebuildEditorTab()
        if currentTab == "Clones" then rebuildClonesTab() end
    end)
end

local function rebuildSyncTab()
    clearTabContent()
    local list = tabContentFrame:FindFirstChildOfClass("UIListLayout")

    local targetInput, targetFrame = makeInput("Username target sync...", tabContentFrame)
    targetFrame.LayoutOrder = 1

    local activateBtn = makeButton("AKTIFKAN SYNC", COLORS.PurpleDark, tabContentFrame)
    activateBtn.LayoutOrder = 2
    activateBtn.MouseButton1Click:Connect(function()
        local targetName = targetInput.Text:gsub("^%s+", ""):gsub("%s+$", "")
        if targetName == "" then return end
        local targetPlayer = Players:FindFirstChild(targetName)
        if not targetPlayer then return end
        SyncTargetPlayer = targetPlayer
        SyncTargetMode = true
        DanceMode = false
        SetupDanceSync()
        rebuildSyncTab()
    end)

    local deactivateBtn = makeButton("NONAKTIFKAN SYNC", COLORS.Red, tabContentFrame)
    deactivateBtn.LayoutOrder = 3
    deactivateBtn.MouseButton1Click:Connect(function()
        SyncTargetMode = false
        SyncTargetPlayer = nil
        StopSyncSystem()
        rebuildSyncTab()
    end)

    if SyncTargetMode and SyncTargetPlayer then
        local statusLabel = makeLabel("Sync aktif ke: " .. SyncTargetPlayer.Name, 10, COLORS.Green, Enum.Font.GothamBold, tabContentFrame)
        statusLabel.LayoutOrder = 4
    end
end

local function rebuildAIChatTab()
    clearTabContent()
    local list = tabContentFrame:FindFirstChildOfClass("UIListLayout")

    local apiLabel = makeLabel("Groq API Key:", 10, COLORS.Gray, Enum.Font.GothamBold, tabContentFrame)
    apiLabel.LayoutOrder = 1

    local apiInput, apiFrame = makeInput("Masukkan API key Groq...", tabContentFrame)
    apiFrame.LayoutOrder = 2
    if GroqApiKey then apiInput.Text = GroqApiKey end

    local saveKeyBtn = makeButton("SIMPAN KEY", COLORS.Blue, tabContentFrame)
    saveKeyBtn.LayoutOrder = 3
    saveKeyBtn.MouseButton1Click:Connect(function()
        GroqApiKey = apiInput.Text:gsub("%s+", "")
        SaveApiKey()
        rebuildAIChatTab()
    end)

    local aiToggleBtn = makeButton(AIChatEnabled and "AI CHAT: ON" or "AI CHAT: OFF", AIChatEnabled and COLORS.Green or COLORS.Panel, tabContentFrame)
    aiToggleBtn.LayoutOrder = 4
    aiToggleBtn.MouseButton1Click:Connect(function()
        AIChatEnabled = not AIChatEnabled
        if AIChatEnabled then StartAIChat() else StopAIChat() end
        rebuildAIChatTab()
    end)

    local testBtn = makeButton("TEST SEKALI", COLORS.Orange, tabContentFrame)
    testBtn.LayoutOrder = 5
    testBtn.MouseButton1Click:Connect(function()
        local ok, err = DoAIChatOnce()
        if not ok then
            local errorLabel = makeLabel("Error: " .. (err or "unknown"), 9, COLORS.Red, nil, tabContentFrame)
            errorLabel.LayoutOrder = 6
        end
    end)

    local infoLabel = makeLabel("Cooldown: " .. AIChatCooldown .. " detik", 9, COLORS.Gray, nil, tabContentFrame)
    infoLabel.LayoutOrder = 7
end

local function rebuildConfigTab()
    clearTabContent()
    local list = tabContentFrame:FindFirstChildOfClass("UIListLayout")

    local saveBtn = makeButton("SIMPAN CONFIG", COLORS.Green, tabContentFrame)
    saveBtn.LayoutOrder = 1
    saveBtn.MouseButton1Click:Connect(function()
        local data = {}
        local folder = Workspace:FindFirstChild(FOLDER_NAME)
        if folder then
            for _, clone in ipairs(folder:GetChildren()) do
                if clone:IsA("Model") and CloneData[clone] then
                    local info = CloneData[clone]
                    local primary = clone.PrimaryPart
                    if primary then
                        local pos = primary.Position
                        local rot = primary.CFrame - primary.CFrame.Position
                        local x, y, z, r11, r12, r13, r21, r22, r23, r31, r32, r33 = rot:GetComponents()
                        table.insert(data, {
                            userId = info.UserId,
                            displayName = info.DisplayName or info.Username,
                            username = info.Username,
                            name = clone.Name,
                            hideName = info.HideName,
                            position = {pos.X, pos.Y, pos.Z},
                            rotation = {r11, r12, r13, r21, r22, r23, r31, r32, r33}
                        })
                    end
                end
            end
        end
        pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(data)) end)
        if Storage and Storage.appSettings then
            Storage.appSettings.mycloneConfig = data
            if Storage.persistSettings then pcall(Storage.persistSettings) end
        end
    end)

    local loadBtn = makeButton("MUAT CONFIG", COLORS.Blue, tabContentFrame)
    loadBtn.LayoutOrder = 2
    loadBtn.MouseButton1Click:Connect(function()
        local data = nil
        pcall(function()
            if isfile and readfile and isfile(CONFIG_FILE) then
                data = HttpService:JSONDecode(readfile(CONFIG_FILE))
            end
        end)
        if not data and Storage and Storage.appSettings and Storage.appSettings.mycloneConfig then
            data = Storage.appSettings.mycloneConfig
        end
        if type(data) ~= "table" then return end
        for _, info in ipairs(data) do
            task.spawn(function()
                local userId = info.userId
                local model = CreateAvatarFromUserId(userId)
                if model then
                    CloneCounter += 1
                    local cloneName = info.name or ("Clone_" .. tostring(CloneCounter))
                    model.Name = cloneName
                    PrepareCloneModel(model)
                    local position = info.position
                    local rotData = info.rotation
                    local cf
                    if position and rotData then
                        local pos = Vector3.new(position[1], position[2], position[3])
                        local rot = CFrame.new(0,0,0, rotData[1], rotData[2], rotData[3], rotData[4], rotData[5], rotData[6], rotData[7], rotData[8], rotData[9])
                        cf = CFrame.new(pos) * rot
                    else
                        cf = GetNextSpawnCFrame()
                    end
                    model:PivotTo(cf)
                    local rootPart = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
                    if rootPart then
                        rootPart.Anchored = true
                        rootPart.CanCollide = false
                        rootPart.Transparency = 1
                    end
                    local cloneData = {
                        Index = CloneCounter,
                        UserId = userId,
                        Username = info.username or info.displayName,
                        DisplayName = info.displayName,
                        OriginalCFrame = cf,
                        OriginalRotation = cf - cf.Position,
                        HideName = info.hideName or false,
                    }
                    CloneData[model] = cloneData
                    model.Parent = Workspace:FindFirstChild(FOLDER_NAME)
                    CreateNameTag(model, info.displayName or info.username or cloneName, cloneData.HideName)
                end
            end)
        end
    end)

    local clearAllBtn = makeButton("HAPUS SEMUA CLONE", COLORS.Delete, tabContentFrame)
    clearAllBtn.LayoutOrder = 3
    clearAllBtn.MouseButton1Click:Connect(function()
        local folder = Workspace:FindFirstChild(FOLDER_NAME)
        if folder then
            for _, clone in ipairs(folder:GetChildren()) do clone:Destroy() end
        end
        table.clear(CloneData)
        SelectedClone = nil
        SetGizmoVisibility()
        if currentTab == "Clones" then rebuildClonesTab() end
        if currentTab == "Editor" then rebuildEditorTab() end
    end)
end

local function rebuildHistoryTab()
    clearTabContent()
    local list = tabContentFrame:FindFirstChildOfClass("UIListLayout")

    if #HistoryList == 0 then
        local emptyLbl = makeLabel("Belum ada riwayat clone", 11, COLORS.Gray, nil, tabContentFrame)
        emptyLbl.LayoutOrder = 1
    else
        for i, entry in ipairs(HistoryList) do
            local itemFrame = Instance.new("Frame")
            itemFrame.Size = UDim2.new(1, 0, 0, 40)
            itemFrame.BackgroundColor3 = COLORS.Panel
            itemFrame.LayoutOrder = i
            itemFrame.Parent = tabContentFrame
            corner(itemFrame, 8)

            local nameLabel = makeLabel(entry.displayName or entry.username, 11, COLORS.White, Enum.Font.GothamBold, itemFrame)
            nameLabel.Size = UDim2.new(1, -70, 0, 20)
            nameLabel.Position = UDim2.new(0, 8, 0, 2)
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left

            local cloneBtn = makeButton("CLONE", COLORS.Red, itemFrame, UDim2.new(0, 50, 0, 22))
            cloneBtn.Position = UDim2.new(1, -58, 0, 9)
            cloneBtn.TextColor3 = COLORS.White
            cloneBtn.MouseButton1Click:Connect(function()
                CreateCloneFromUserId(entry.userId, entry.displayName, entry.username)
            end)
        end

        local clearBtn = makeButton("CLEAR HISTORY", COLORS.Delete, tabContentFrame)
        clearBtn.LayoutOrder = #HistoryList + 2
        clearBtn.MouseButton1Click:Connect(function()
            HistoryList = {}
            SaveHistory()
            rebuildHistoryTab()
        end)
    end
end

local function rebuildCurrentTab()
    if currentTab == "Clones" then
        rebuildClonesTab()
    elseif currentTab == "Editor" then
        rebuildEditorTab()
    elseif currentTab == "Sync" then
        rebuildSyncTab()
    elseif currentTab == "AI Chat" then
        rebuildAIChatTab()
    elseif currentTab == "Config" then
        rebuildConfigTab()
    elseif currentTab == "History" then
        rebuildHistoryTab()
    end
end

-- ================================================
-- MAIN APP OPEN FUNCTION
-- ================================================
function _G.openMyCloneApp()
    LoadApiKey()
    LoadHistory()
    LoadFavorites()

    if not Workspace:FindFirstChild(FOLDER_NAME) then
        local folder = Instance.new("Folder")
        folder.Name = FOLDER_NAME
        folder.Parent = Workspace
    end

    local appContent = _G.appContent
    -- Clear any existing children (should already be cleared by _G.openApp, but just in case)
    for _, child in ipairs(appContent:GetChildren()) do
        if not child:IsA("UIListLayout") then child:Destroy() end
    end

    -- Tab bar
    tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, 0, 0, 32)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = appContent

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.Parent = tabBar

    local tabs = {"Clones", "Editor", "Sync", "AI Chat", "Config", "History"}
    for i, tabName in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.16, -4, 0, 28)
        btn.BackgroundColor3 = COLORS.Panel2
        btn.Text = tabName
        btn.TextColor3 = COLORS.White
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 8
        btn.AutoButtonColor = false
        btn.LayoutOrder = i
        btn.Parent = tabBar
        corner(btn, 6)
        pressFX(btn)

        btn.MouseButton1Click:Connect(function()
            currentTab = tabName
            -- Update visual of all tab buttons
            for _, child in ipairs(tabBar:GetChildren()) do
                if child:IsA("TextButton") then
                    child.BackgroundColor3 = COLORS.Panel2
                end
            end
            btn.BackgroundColor3 = COLORS.PurpleDark
            rebuildCurrentTab()
        end)

        if i == 1 then btn.BackgroundColor3 = COLORS.PurpleDark end
    end

    -- Content frame
    tabContentFrame = Instance.new("Frame")
    tabContentFrame.Size = UDim2.new(1, 0, 0, 0)
    tabContentFrame.Position = UDim2.new(0, 0, 0, 36)
    tabContentFrame.BackgroundTransparency = 1
    tabContentFrame.AutomaticSize = Enum.AutomaticSize.Y
    tabContentFrame.Parent = appContent

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 6)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = tabContentFrame

    -- Initialize default tab
    currentTab = "Clones"
    rebuildCurrentTab()

    -- Reset modes
    EditMode = false
    PositionMode = false
    RotationMode = false
    DanceMode = false
    SyncTargetMode = false

    -- Create gizmos if not exist
    if not PositionGizmo then
        PositionGizmo = Instance.new("Handles")
        PositionGizmo.Style = Enum.HandlesStyle.Movement
        PositionGizmo.Color3 = COLORS.Red
        PositionGizmo.Parent = CoreGui
    end
    if not RotationGizmo then
        RotationGizmo = Instance.new("ArcHandles")
        RotationGizmo.Color3 = COLORS.Purple
        RotationGizmo.Parent = CoreGui
    end
    SetGizmoVisibility()

    -- Connect gizmo drag handlers (only once)
    if not PositionGizmo:GetAttribute("DragConnected") then
        PositionGizmo:SetAttribute("DragConnected", true)
        local dragStartCFrame = nil
        PositionGizmo.MouseButton1Down:Connect(function()
            if not SelectedClone or not PositionMode or not SelectedClone.PrimaryPart then return end
            dragStartCFrame = SelectedClone.PrimaryPart.CFrame
            GizmoDragging = true
            local camera = Workspace.CurrentCamera
            if camera then
                CameraRestoreType = camera.CameraType
                CameraRestoreSubject = camera.CameraSubject
                camera.CameraType = Enum.CameraType.Scriptable
            end
            pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition end)
        end)
        PositionGizmo.MouseDrag:Connect(function(face, distance)
            if not SelectedClone or not dragStartCFrame then return end
            local delta = Vector3.FromNormalId(face) * distance
            SelectedClone:PivotTo(dragStartCFrame * CFrame.new(delta))
        end)
        PositionGizmo.MouseButton1Up:Connect(function()
            dragStartCFrame = nil
            GizmoDragging = false
            local camera = Workspace.CurrentCamera
            if camera and CameraRestoreType then
                camera.CameraType = CameraRestoreType
                if CameraRestoreSubject and CameraRestoreSubject.Parent then
                    camera.CameraSubject = CameraRestoreSubject
                end
            end
            pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.Default end)
        end)
    end

    if not RotationGizmo:GetAttribute("DragConnected") then
        RotationGizmo:SetAttribute("DragConnected", true)
        local rotStartCFrame = nil
        RotationGizmo.MouseButton1Down:Connect(function()
            if not SelectedClone or not RotationMode or not SelectedClone.PrimaryPart then return end
            rotStartCFrame = SelectedClone.PrimaryPart.CFrame
            GizmoDragging = true
            local camera = Workspace.CurrentCamera
            if camera then
                CameraRestoreType = camera.CameraType
                CameraRestoreSubject = camera.CameraSubject
                camera.CameraType = Enum.CameraType.Scriptable
            end
            pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition end)
        end)
        RotationGizmo.MouseDrag:Connect(function(axis, relativeAngle)
            if not SelectedClone or not rotStartCFrame then return end
            local axisVector = Vector3.FromAxis(axis)
            SelectedClone:PivotTo(rotStartCFrame * CFrame.fromAxisAngle(axisVector, relativeAngle))
        end)
        RotationGizmo.MouseButton1Up:Connect(function()
            rotStartCFrame = nil
            GizmoDragging = false
            local camera = Workspace.CurrentCamera
            if camera and CameraRestoreType then
                camera.CameraType = CameraRestoreType
                if CameraRestoreSubject and CameraRestoreSubject.Parent then
                    camera.CameraSubject = CameraRestoreSubject
                end
            end
            pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.Default end)
        end)
    end

    -- Mouse selection for Editor
    local inputConn
    inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not EditMode then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local mouse = LocalPlayer:GetMouse()
            local target = mouse.Target
            local folder = Workspace:FindFirstChild(FOLDER_NAME)
            if folder and target and target:IsDescendantOf(folder) then
                local model = target:FindFirstAncestorOfClass("Model")
                if model then SelectClone(model) end
            end
        end
    end)

    -- Cleanup when app closes or another app opens
    appContent.Destroying:Connect(function()
        if inputConn then inputConn:Disconnect() end
        StopSyncSystem()
        StopAIChat()
        if PositionGizmo then PositionGizmo:Destroy(); PositionGizmo = nil end
        if RotationGizmo then RotationGizmo:Destroy(); RotationGizmo = nil end
    end)
end

return _G.openMyCloneApp