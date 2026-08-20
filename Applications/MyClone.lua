-- ============================================================
-- Applications/MyClone.lua
-- MyClone App untuk PhoneIDViewer / AvatarClone
-- Fitur: Clone, Editor, Sync, AI Chat, Config, History
-- Pola: _G.Services, _G.LocalPlayer, _G.Helpers, _G.appContent
-- ============================================================

local Services    = _G.Services or {}
local LocalPlayer = _G.LocalPlayer or game:GetService("Players").LocalPlayer
local Helpers     = _G.Helpers or {}
local Storage     = _G.Storage or {}
local appContent  = _G.appContent

local HttpService      = Services.HttpService or game:GetService("HttpService")
local TweenService     = Services.TweenService or game:GetService("TweenService")
local UserInputService = Services.UserInputService or game:GetService("UserInputService")
local Workspace        = Services.Workspace or game:GetService("Workspace")
local RunService       = Services.RunService or game:GetService("RunService")
local TextChatService  = game:GetService("TextChatService")
local ChatService      = game:GetService("Chat")

if not LocalPlayer or not appContent then return end

local corner  = Helpers.corner or function(o,r) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r or 10) c.Parent=o return c end
local stroke  = Helpers.stroke or function(o,c,t,tr) local s=Instance.new("UIStroke") s.Color=c s.Thickness=t or 1 s.Transparency=tr or 0 s.Parent=o return s end
local tween   = Helpers.tween or function(o,props,tm,style) TweenService:Create(o,TweenInfo.new(tm or 0.25, style or Enum.EasingStyle.Quart, Enum.EasingDirection.Out),props):Play() end
local pressFX = Helpers.pressFX or function(b) end

-- ===================== PALETTE =====================
local C = {
    bg      = Color3.fromRGB(12, 13, 18),
    card    = Color3.fromRGB(20, 22, 30),
    card2   = Color3.fromRGB(28, 30, 42),
    panel   = Color3.fromRGB(16, 18, 26),
    white   = Color3.fromRGB(250, 250, 255),
    soft    = Color3.fromRGB(210, 215, 230),
    gray    = Color3.fromRGB(135, 140, 160),
    darkgray= Color3.fromRGB(75, 80, 95),
    red     = Color3.fromRGB(255, 65, 85),
    redDark = Color3.fromRGB(180, 35, 55),
    purple  = Color3.fromRGB(140, 80, 255),
    purpleDark=Color3.fromRGB(90, 45, 180),
    green   = Color3.fromRGB(50, 225, 130),
    blue    = Color3.fromRGB(60, 160, 255),
    orange  = Color3.fromRGB(255, 150, 50),
}

-- ===================== STATE =====================
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
local GroqApiKey = ""

-- UI refs
local MainPanel = nil
local TabBar = nil
local TabContent = nil

local PositionGizmo = nil
local RotationGizmo = nil

-- ===================== UTILITY =====================
local function IsSyncTrack(track)
    if not track then return false end
    local p = track.Priority
    if p == Enum.AnimationPriority.Action or p == Enum.AnimationPriority.Action2 or
       p == Enum.AnimationPriority.Action3 or p == Enum.AnimationPriority.Action4 then
        return true
    end
    local name = string.lower(track.Name or "")
    if string.find(name, "walk") or string.find(name, "run") or string.find(name, "jump") or
       string.find(name, "fall") or string.find(name, "idle") or string.find(name, "climb") or
       string.find(name, "swim") or string.find(name, "sit") or string.find(name, "sleep") then
        return false
    end
    if string.find(name, "dance") or string.find(name, "emote") or string.find(name, "wave") or
       string.find(name, "laugh") or string.find(name, "cheer") or string.find(name, "point") or
       string.find(name, "salute") or string.find(name, "shrug") or string.find(name, "talk") then
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
    for _, clone in ipairs(CloneFolder:GetChildren()) do
        if clone:IsA("Model") then callback(clone) end
    end
end

local function StopAllCloneEmotes()
    for _, clone in ipairs(CloneFolder:GetChildren()) do
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

local function StopSyncSystem()
    if SyncLoop then SyncLoop:Disconnect(); SyncLoop = nil end
    if CurrentAnimatorConnection then CurrentAnimatorConnection:Disconnect(); CurrentAnimatorConnection = nil end
    StopAllCloneEmotes()
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
    label.TextColor3 = C.white
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextStrokeTransparency = 0.4
    label.TextStrokeColor3 = Color3.fromRGB(0,0,0)
    label.Parent = billboard
    return billboard
end

local function GetDisplayName(userId)
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player.UserId == userId then return player.DisplayName end
    end
    local success, data = pcall(function() return game:HttpGet("https://users.roblox.com/v1/users/"..userId) end)
    if success and data then
        local parsed = HttpService:JSONDecode(data)
        if parsed and parsed.displayName then return parsed.displayName end
    end
    return nil
end

local function ResolveUserId(value)
    value = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if value == "" then return LocalPlayer.UserId, true end
    local num = tonumber(value)
    if num then return num, false end
    local ok, id = pcall(function() return Services.Players:GetUserIdFromNameAsync(value) end)
    if ok and id then return id, false end
    return nil, false
end

local function CreateAvatarFromUserId(userId)
    local ok, model = pcall(function() return Services.Players:CreateHumanoidModelFromUserIdAsync(userId) end)
    if ok and model then return model end
    local descOk, desc = pcall(function() return Services.Players:GetHumanoidDescriptionFromUserIdAsync(userId) end)
    if descOk and desc then
        local modelOk, gen = pcall(function()
            return Services.Players:CreateHumanoidModelFromDescriptionAsync(desc, Enum.HumanoidRigType.R15, Enum.AssetTypeVerification.Default)
        end)
        if modelOk then return gen end
    end
    return nil
end

local function PrepareCloneModel(model)
    if not model then return end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then obj:Destroy() end
    end
    local root = model:FindFirstChild("HumanoidRootPart")
    if root then model.PrimaryPart = root else
        local part = model:FindFirstChildOfClass("BasePart")
        if part then model.PrimaryPart = part end
    end
    pcall(function() model:MakeJoints() end)
end

local function GetNextSpawnCFrame()
    local char = LocalPlayer.Character
    if not char then return CFrame.new(0, 3, -5) end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return CFrame.new(0, 3, -5) end
    return root.CFrame
end

local function CreateCloneFromUserId(userId, displayName, username)
    if not userId then
        if _G.showDynamicNotification then _G.showDynamicNotification("UserID tidak valid", C.red) end
        return
    end
    if _G.showDynamicNotification then _G.showDynamicNotification("Loading avatar...", C.orange) end
    local model = nil
    local dispName = displayName
    local uname = username or "Unknown"
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player.UserId == userId then
            if not dispName then dispName = player.DisplayName end
            if not uname or uname == "Unknown" then uname = player.Name end
            if player.Character then
                player.Character.Archivable = true
                local ok, result = pcall(function() return player.Character:Clone() end)
                if ok and result then model = result end
            end
            break
        end
    end
    if not model then model = CreateAvatarFromUserId(userId) end
    if not dispName then dispName = GetDisplayName(userId) or uname end
    if not model then
        if _G.showDynamicNotification then _G.showDynamicNotification("Gagal memuat avatar", C.red) end
        return
    end
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
    model.Parent = CloneFolder
    CreateNameTag(model, dispName, false)
    SelectClone(model)
    -- save history
    local exists = false
    for _, e in ipairs(HistoryList) do if e.userId == userId then exists = true break end end
    if not exists then
        table.insert(HistoryList, {userId=userId, displayName=dispName, username=uname})
        saveHistory()
    end
    if DanceMode or SyncTargetMode then SetupDanceSync() end
    if _G.showDynamicNotification then _G.showDynamicNotification("Clone created • "..dispName, C.green) end
end

local function CreateCloneFromInput()
    local input = currentInputField and currentInputField.Text or ""
    local userId, isSelf = ResolveUserId(input)
    if not userId then
        if _G.showDynamicNotification then _G.showDynamicNotification("User tidak ditemukan", C.red) end
        return
    end
    local dispName, uname
    for _, p in ipairs(Services.Players:GetPlayers()) do
        if p.UserId == userId then dispName = p.DisplayName; uname = p.Name; break end
    end
    if not dispName then dispName = GetDisplayName(userId) or "Unknown" end
    if not uname then uname = "Unknown" end
    CreateCloneFromUserId(userId, dispName, uname)
end

-- ===================== FILE PERSISTENCE =====================
local function saveHistory()
    if Storage.appSettings then
        Storage.appSettings.myCloneHistory = HistoryList
        pcall(function() if Storage.persistSettings then Storage.persistSettings() end end)
    end
end

local function loadHistory()
    if Storage.appSettings and Storage.appSettings.myCloneHistory then
        HistoryList = Storage.appSettings.myCloneHistory
    end
end

local function saveFavorites()
    if Storage.appSettings then
        Storage.appSettings.myCloneFavorites = FavoritesList
        pcall(function() if Storage.persistSettings then Storage.persistSettings() end end)
    end
end

local function loadFavorites()
    if Storage.appSettings and Storage.appSettings.myCloneFavorites then
        FavoritesList = Storage.appSettings.myCloneFavorites
    end
end

local function saveConfig()
    local data = {}
    for _, clone in ipairs(CloneFolder:GetChildren()) do
        if clone:IsA("Model") and CloneData[clone] then
            local info = CloneData[clone]
            local primary = clone.PrimaryPart
            if primary then
                local pos = primary.Position
                local rot = primary.CFrame - primary.CFrame.Position
                local x, y, z, r11, r12, r13, r21, r22, r23, r31, r32, r33 = rot:GetComponents()
                table.insert(data, {
                    userId = info.UserId,
                    displayName = info.DisplayName,
                    username = info.Username,
                    name = clone.Name,
                    hideName = info.HideName,
                    position = {pos.X, pos.Y, pos.Z},
                    rotation = {r11, r12, r13, r21, r22, r23, r31, r32, r33}
                })
            end
        end
    end
    if Storage.appSettings then
        Storage.appSettings.myCloneConfig = data
        pcall(function() if Storage.persistSettings then Storage.persistSettings() end end)
    end
end

local function loadConfig()
    if Storage.appSettings and Storage.appSettings.myCloneConfig then
        for _, info in ipairs(Storage.appSettings.myCloneConfig) do
            task.spawn(function()
                local model = CreateAvatarFromUserId(info.userId)
                if model then
                    CloneCounter += 1
                    model.Name = info.name or ("Clone_"..tostring(CloneCounter))
                    PrepareCloneModel(model)
                    local cf
                    if info.position and info.rotation then
                        local pos = Vector3.new(info.position[1], info.position[2], info.position[3])
                        local rot = CFrame.new(0,0,0, info.rotation[1], info.rotation[2], info.rotation[3], info.rotation[4], info.rotation[5], info.rotation[6], info.rotation[7], info.rotation[8], info.rotation[9])
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
                        UserId = info.userId,
                        Username = info.username,
                        DisplayName = info.displayName,
                        OriginalCFrame = cf,
                        OriginalRotation = cf - cf.Position,
                        HideName = info.hideName or false,
                    }
                    CloneData[model] = cloneData
                    model.Parent = CloneFolder
                    CreateNameTag(model, info.displayName or info.username, cloneData.HideName)
                end
            end)
        end
    end
end

-- ===================== UI BUILD =====================
function _G.openMyCloneApp()
    -- Clear existing content
    if appContent then
        for _, child in ipairs(appContent:GetChildren()) do
            if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then child:Destroy() end
        end
    end

    -- Create main container
    local main = Instance.new("Frame")
    main.Size = UDim2.new(1, 0, 1, 0)
    main.BackgroundTransparency = 1
    main.Parent = appContent

    local mainList = Instance.new("UIListLayout", main)
    mainList.Padding = UDim.new(0, 8)
    mainList.SortOrder = Enum.SortOrder.LayoutOrder

    -- Tab bar
    local tabBar = Instance.new("Frame", main)
    tabBar.Size = UDim2.new(1, 0, 0, 36)
    tabBar.BackgroundColor3 = C.card
    tabBar.LayoutOrder = 0
    corner(tabBar, 12)
    stroke(tabBar, C.card2, 1, 0.3)

    local tabLayout = Instance.new("UIListLayout", tabBar)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 2)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local tabButtons = {}

    -- Tab content container
    local contentFrame = Instance.new("Frame", main)
    contentFrame.Size = UDim2.new(1, 0, 0, 500)
    contentFrame.BackgroundTransparency = 1
    contentFrame.LayoutOrder = 1

    -- Panels
    local panelClones = Instance.new("ScrollingFrame", contentFrame)
    panelClones.Size = UDim2.new(1, 0, 1, 0)
    panelClones.BackgroundTransparency = 1
    panelClones.BorderSizePixel = 0
    panelClones.ScrollBarThickness = 2
    panelClones.ScrollBarImageColor3 = C.purple
    panelClones.CanvasSize = UDim2.new(0,0,0,0)
    panelClones.AutomaticCanvasSize = Enum.AutomaticSize.Y
    panelClones.Visible = true

    local panelEditor = Instance.new("ScrollingFrame", contentFrame)
    panelEditor.Size = UDim2.new(1, 0, 1, 0)
    panelEditor.BackgroundTransparency = 1
    panelEditor.BorderSizePixel = 0
    panelEditor.ScrollBarThickness = 2
    panelEditor.ScrollBarImageColor3 = C.purple
    panelEditor.CanvasSize = UDim2.new(0,0,0,0)
    panelEditor.AutomaticCanvasSize = Enum.AutomaticSize.Y
    panelEditor.Visible = false

    local panelSync = Instance.new("ScrollingFrame", contentFrame)
    panelSync.Size = UDim2.new(1, 0, 1, 0)
    panelSync.BackgroundTransparency = 1
    panelSync.BorderSizePixel = 0
    panelSync.ScrollBarThickness = 2
    panelSync.ScrollBarImageColor3 = C.purple
    panelSync.CanvasSize = UDim2.new(0,0,0,0)
    panelSync.AutomaticCanvasSize = Enum.AutomaticSize.Y
    panelSync.Visible = false

    local panelAIChat = Instance.new("ScrollingFrame", contentFrame)
    panelAIChat.Size = UDim2.new(1, 0, 1, 0)
    panelAIChat.BackgroundTransparency = 1
    panelAIChat.BorderSizePixel = 0
    panelAIChat.ScrollBarThickness = 2
    panelAIChat.ScrollBarImageColor3 = C.purple
    panelAIChat.CanvasSize = UDim2.new(0,0,0,0)
    panelAIChat.AutomaticCanvasSize = Enum.AutomaticSize.Y
    panelAIChat.Visible = false

    local panelConfig = Instance.new("ScrollingFrame", contentFrame)
    panelConfig.Size = UDim2.new(1, 0, 1, 0)
    panelConfig.BackgroundTransparency = 1
    panelConfig.BorderSizePixel = 0
    panelConfig.ScrollBarThickness = 2
    panelConfig.ScrollBarImageColor3 = C.purple
    panelConfig.CanvasSize = UDim2.new(0,0,0,0)
    panelConfig.AutomaticCanvasSize = Enum.AutomaticSize.Y
    panelConfig.Visible = false

    local panelHistory = Instance.new("ScrollingFrame", contentFrame)
    panelHistory.Size = UDim2.new(1, 0, 1, 0)
    panelHistory.BackgroundTransparency = 1
    panelHistory.BorderSizePixel = 0
    panelHistory.ScrollBarThickness = 2
    panelHistory.ScrollBarImageColor3 = C.purple
    panelHistory.CanvasSize = UDim2.new(0,0,0,0)
    panelHistory.AutomaticCanvasSize = Enum.AutomaticSize.Y
    panelHistory.Visible = false

    local panels = {
        Clones = panelClones,
        Editor = panelEditor,
        Sync = panelSync,
        ["AI Chat"] = panelAIChat,
        Config = panelConfig,
        History = panelHistory,
    }

    local function switchTab(name)
        for n, panel in pairs(panels) do
            panel.Visible = (n == name)
        end
        for _, btn in ipairs(tabButtons) do
            if btn.Name == name then
                btn.BackgroundColor3 = C.purpleDark
            else
                btn.BackgroundColor3 = C.card2
            end
        end
    end

    local tabNames = {"Clones", "Editor", "Sync", "AI Chat", "Config", "History"}
    for i, name in ipairs(tabNames) do
        local btn = Instance.new("TextButton", tabBar)
        btn.Name = name
        btn.Size = UDim2.new(0, 100, 1, -6)
        btn.Position = UDim2.new(0, 0, 0, 3)
        btn.BackgroundColor3 = (i == 1) and C.purpleDark or C.card2
        btn.Text = name
        btn.TextColor3 = C.white
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.AutoButtonColor = false
        corner(btn, 8)
        pressFX(btn)
        btn.MouseButton1Click:Connect(function() switchTab(name) end)
        table.insert(tabButtons, btn)
    end

    switchTab("Clones")

    -- ===== CLONES PANEL =====
    local clonesLayout = Instance.new("UIListLayout", panelClones)
    clonesLayout.Padding = UDim.new(0, 8)
    clonesLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local inputFrame = Instance.new("Frame", panelClones)
    inputFrame.Size = UDim2.new(1, 0, 0, 40)
    inputFrame.BackgroundColor3 = C.card
    corner(inputFrame, 10)
    stroke(inputFrame, C.card2, 1, 0.3)

    local inputBox = Instance.new("TextBox", inputFrame)
    inputBox.Size = UDim2.new(1, -12, 1, 0)
    inputBox.Position = UDim2.new(0, 8, 0, 0)
    inputBox.BackgroundTransparency = 1
    inputBox.PlaceholderText = "Username/User ID target..."
    inputBox.PlaceholderColor3 = C.darkgray
    inputBox.TextColor3 = C.white
    inputBox.Font = Enum.Font.Gotham
    inputBox.TextSize = 11
    inputBox.ClearTextOnFocus = false
    inputBox.TextXAlignment = Enum.TextXAlignment.Left
    currentInputField = inputBox

    local cloneBtn = Instance.new("TextButton", panelClones)
    cloneBtn.Size = UDim2.new(1, 0, 0, 46)
    cloneBtn.BackgroundColor3 = C.red
    cloneBtn.Text = "Clone Avatar"
    cloneBtn.TextColor3 = C.white
    cloneBtn.Font = Enum.Font.GothamBlack
    cloneBtn.TextSize = 14
    cloneBtn.AutoButtonColor = false
    corner(cloneBtn, 10)
    pressFX(cloneBtn)
    cloneBtn.MouseButton1Click:Connect(CreateCloneFromInput)

    local cloneAllBtn = Instance.new("TextButton", panelClones)
    cloneAllBtn.Size = UDim2.new(1, 0, 0, 40)
    cloneAllBtn.BackgroundColor3 = C.green
    cloneAllBtn.Text = "Clone Semua Player"
    cloneAllBtn.TextColor3 = C.bg
    cloneAllBtn.Font = Enum.Font.GothamBold
    cloneAllBtn.TextSize = 11
    cloneAllBtn.AutoButtonColor = false
    corner(cloneAllBtn, 10)
    pressFX(cloneAllBtn)
    cloneAllBtn.MouseButton1Click:Connect(function()
        for _, player in ipairs(Services.Players:GetPlayers()) do
            if player ~= LocalPlayer then
                CreateCloneFromUserId(player.UserId, player.DisplayName, player.Name)
            end
        end
    end)

    local hideAllBtn = Instance.new("TextButton", panelClones)
    hideAllBtn.Size = UDim2.new(1, 0, 0, 40)
    hideAllBtn.BackgroundColor3 = C.orange
    hideAllBtn.Text = "Hide All Names"
    hideAllBtn.TextColor3 = C.bg
    hideAllBtn.Font = Enum.Font.GothamBold
    hideAllBtn.TextSize = 11
    hideAllBtn.AutoButtonColor = false
    corner(hideAllBtn, 10)
    pressFX(hideAllBtn)
    hideAllBtn.MouseButton1Click:Connect(function()
        HideAllNames = not HideAllNames
        for _, clone in ipairs(CloneFolder:GetChildren()) do
            if clone:IsA("Model") then
                local data = CloneData[clone]
                local tag = clone:FindFirstChild("NameTag")
                if HideAllNames then
                    if tag then tag:Destroy() end
                else
                    if data and not data.HideName then
                        CreateNameTag(clone, data.DisplayName or clone.Name, false)
                    end
                end
            end
        end
        hideAllBtn.Text = HideAllNames and "Show All Names" or "Hide All Names"
        hideAllBtn.BackgroundColor3 = HideAllNames and C.redDark or C.orange
    end)

    -- ===== EDITOR PANEL =====
    local editorLayout = Instance.new("UIListLayout", panelEditor)
    editorLayout.Padding = UDim.new(0, 8)
    editorLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local editToggleBtn = Instance.new("TextButton", panelEditor)
    editToggleBtn.Size = UDim2.new(1, 0, 0, 44)
    editToggleBtn.BackgroundColor3 = C.card
    editToggleBtn.Text = "Aktifkan Editor"
    editToggleBtn.TextColor3 = C.white
    editToggleBtn.Font = Enum.Font.GothamBold
    editToggleBtn.TextSize = 12
    editToggleBtn.AutoButtonColor = false
    corner(editToggleBtn, 10)
    pressFX(editToggleBtn)
    editToggleBtn.MouseButton1Click:Connect(function()
        EditMode = not EditMode
        editToggleBtn.Text = EditMode and "Nonaktifkan Editor" or "Aktifkan Editor"
        editToggleBtn.BackgroundColor3 = EditMode and C.redDark or C.card
        -- Show/hide additional buttons? (simplified)
    end)

    local posBtn = Instance.new("TextButton", panelEditor)
    posBtn.Size = UDim2.new(1, 0, 0, 40)
    posBtn.BackgroundColor3 = C.card
    posBtn.Text = "Posisi: OFF"
    posBtn.TextColor3 = C.white
    posBtn.Font = Enum.Font.GothamBold
    posBtn.TextSize = 11
    posBtn.AutoButtonColor = false
    corner(posBtn, 10)
    pressFX(posBtn)
    posBtn.MouseButton1Click:Connect(function()
        if not EditMode then return end
        PositionMode = not PositionMode
        posBtn.Text = "Posisi: " .. (PositionMode and "ON" or "OFF")
        posBtn.BackgroundColor3 = PositionMode and C.redDark or C.card
    end)

    local rotBtn = Instance.new("TextButton", panelEditor)
    rotBtn.Size = UDim2.new(1, 0, 0, 40)
    rotBtn.BackgroundColor3 = C.card
    rotBtn.Text = "Rotasi: OFF"
    rotBtn.TextColor3 = C.white
    rotBtn.Font = Enum.Font.GothamBold
    rotBtn.TextSize = 11
    rotBtn.AutoButtonColor = false
    corner(rotBtn, 10)
    pressFX(rotBtn)
    rotBtn.MouseButton1Click:Connect(function()
        if not EditMode then return end
        RotationMode = not RotationMode
        rotBtn.Text = "Rotasi: " .. (RotationMode and "ON" or "OFF")
        rotBtn.BackgroundColor3 = RotationMode and C.purpleDark or C.card
    end)

    local resetPosBtn = Instance.new("TextButton", panelEditor)
    resetPosBtn.Size = UDim2.new(1, 0, 0, 38)
    resetPosBtn.BackgroundColor3 = C.card
    resetPosBtn.Text = "Reset Posisi"
    resetPosBtn.TextColor3 = C.white
    resetPosBtn.Font = Enum.Font.GothamBold
    resetPosBtn.TextSize = 10
    resetPosBtn.AutoButtonColor = false
    corner(resetPosBtn, 10)
    pressFX(resetPosBtn)

    local resetRotBtn = Instance.new("TextButton", panelEditor)
    resetRotBtn.Size = UDim2.new(1, 0, 0, 38)
    resetRotBtn.BackgroundColor3 = C.card
    resetRotBtn.Text = "Reset Rotasi"
    resetRotBtn.TextColor3 = C.white
    resetRotBtn.Font = Enum.Font.GothamBold
    resetRotBtn.TextSize = 10
    resetRotBtn.AutoButtonColor = false
    corner(resetRotBtn, 10)
    pressFX(resetRotBtn)

    -- ===== SYNC PANEL =====
    local syncLayout = Instance.new("UIListLayout", panelSync)
    syncLayout.Padding = UDim.new(0, 8)
    syncLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local danceBtn = Instance.new("TextButton", panelSync)
    danceBtn.Size = UDim2.new(1, 0, 0, 46)
    danceBtn.BackgroundColor3 = C.card
    danceBtn.Text = "Mode Tari (Local) OFF"
    danceBtn.TextColor3 = C.white
    danceBtn.Font = Enum.Font.GothamBold
    danceBtn.TextSize = 12
    danceBtn.AutoButtonColor = false
    corner(danceBtn, 10)
    pressFX(danceBtn)
    danceBtn.MouseButton1Click:Connect(function()
        DanceMode = not DanceMode
        SyncTargetMode = false
        danceBtn.Text = "Mode Tari (Local) " .. (DanceMode and "ON" or "OFF")
        danceBtn.BackgroundColor3 = DanceMode and C.purpleDark or C.card
        if DanceMode then
            if not SelectedClone then
                DanceMode = false
                if _G.showDynamicNotification then _G.showDynamicNotification("Pilih clone dulu", C.red) end
                return
            end
            SetupDanceSync()
        else
            StopSyncSystem()
        end
    end)

    local syncTargetFrame = Instance.new("Frame", panelSync)
    syncTargetFrame.Size = UDim2.new(1, 0, 0, 40)
    syncTargetFrame.BackgroundColor3 = C.card
    corner(syncTargetFrame, 10)
    stroke(syncTargetFrame, C.card2, 1, 0.3)

    local syncInput = Instance.new("TextBox", syncTargetFrame)
    syncInput.Size = UDim2.new(1, -12, 1, 0)
    syncInput.Position = UDim2.new(0, 8, 0, 0)
    syncInput.BackgroundTransparency = 1
    syncInput.PlaceholderText = "Username target sync"
    syncInput.PlaceholderColor3 = C.darkgray
    syncInput.TextColor3 = C.white
    syncInput.Font = Enum.Font.Gotham
    syncInput.TextSize = 11
    syncInput.ClearTextOnFocus = false
    syncInput.TextXAlignment = Enum.TextXAlignment.Left

    local syncTargetBtn = Instance.new("TextButton", panelSync)
    syncTargetBtn.Size = UDim2.new(1, 0, 0, 40)
    syncTargetBtn.BackgroundColor3 = C.purpleDark
    syncTargetBtn.Text = "Aktifkan Sync Target"
    syncTargetBtn.TextColor3 = C.white
    syncTargetBtn.Font = Enum.Font.GothamBold
    syncTargetBtn.TextSize = 11
    syncTargetBtn.AutoButtonColor = false
    corner(syncTargetBtn, 10)
    pressFX(syncTargetBtn)
    syncTargetBtn.MouseButton1Click:Connect(function()
        local name = syncInput.Text:gsub("^%s+", ""):gsub("%s+$", "")
        if name == "" then return end
        local target = Services.Players:FindFirstChild(name)
        if not target then
            if _G.showDynamicNotification then _G.showDynamicNotification("Player tidak ditemukan", C.red) end
            return
        end
        SyncTargetPlayer = target
        SyncTargetMode = true
        DanceMode = false
        SetupDanceSync()
        syncTargetBtn.BackgroundColor3 = C.redDark
        if _G.showDynamicNotification then _G.showDynamicNotification("Sync target: "..target.Name, C.green) end
    end)

    local clearSyncBtn = Instance.new("TextButton", panelSync)
    clearSyncBtn.Size = UDim2.new(1, 0, 0, 38)
    clearSyncBtn.BackgroundColor3 = C.card
    clearSyncBtn.Text = "Nonaktifkan Sync"
    clearSyncBtn.TextColor3 = C.white
    clearSyncBtn.Font = Enum.Font.GothamBold
    clearSyncBtn.TextSize = 10
    clearSyncBtn.AutoButtonColor = false
    corner(clearSyncBtn, 10)
    pressFX(clearSyncBtn)
    clearSyncBtn.MouseButton1Click:Connect(function()
        SyncTargetMode = false
        SyncTargetPlayer = nil
        StopSyncSystem()
        syncTargetBtn.BackgroundColor3 = C.purpleDark
    end)

    -- ===== AI CHAT PANEL =====
    local aiLayout = Instance.new("UIListLayout", panelAIChat)
    aiLayout.Padding = UDim.new(0, 8)
    aiLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local apiKeyFrame = Instance.new("Frame", panelAIChat)
    apiKeyFrame.Size = UDim2.new(1, 0, 0, 40)
    apiKeyFrame.BackgroundColor3 = C.card
    corner(apiKeyFrame, 10)
    stroke(apiKeyFrame, C.card2, 1, 0.3)

    local apiKeyInput = Instance.new("TextBox", apiKeyFrame)
    apiKeyInput.Size = UDim2.new(1, -12, 1, 0)
    apiKeyInput.Position = UDim2.new(0, 8, 0, 0)
    apiKeyInput.BackgroundTransparency = 1
    apiKeyInput.PlaceholderText = "Masukkan Groq API Key..."
    apiKeyInput.PlaceholderColor3 = C.darkgray
    apiKeyInput.Text = GroqApiKey
    apiKeyInput.TextColor3 = C.white
    apiKeyInput.Font = Enum.Font.Gotham
    apiKeyInput.TextSize = 11
    apiKeyInput.ClearTextOnFocus = false
    apiKeyInput.TextXAlignment = Enum.TextXAlignment.Left
    apiKeyInput.FocusLost:Connect(function() GroqApiKey = apiKeyInput.Text end)

    local aiToggleBtn = Instance.new("TextButton", panelAIChat)
    aiToggleBtn.Size = UDim2.new(1, 0, 0, 46)
    aiToggleBtn.BackgroundColor3 = C.card
    aiToggleBtn.Text = "AI Chat (Groq) OFF"
    aiToggleBtn.TextColor3 = C.white
    aiToggleBtn.Font = Enum.Font.GothamBold
    aiToggleBtn.TextSize = 12
    aiToggleBtn.AutoButtonColor = false
    corner(aiToggleBtn, 10)
    pressFX(aiToggleBtn)
    aiToggleBtn.MouseButton1Click:Connect(function()
        AIChatEnabled = not AIChatEnabled
        aiToggleBtn.Text = "AI Chat (Groq) " .. (AIChatEnabled and "ON" or "OFF")
        aiToggleBtn.BackgroundColor3 = AIChatEnabled and C.green or C.card
        if AIChatEnabled then
            if GroqApiKey == "" then
                AIChatEnabled = false
                if _G.showDynamicNotification then _G.showDynamicNotification("API key kosong", C.red) end
                aiToggleBtn.Text = "AI Chat (Groq) OFF"
                aiToggleBtn.BackgroundColor3 = C.card
                return
            end
            StartAIChat()
        else
            StopAIChat()
        end
    end)

    local testAIBtn = Instance.new("TextButton", panelAIChat)
    testAIBtn.Size = UDim2.new(1, 0, 0, 40)
    testAIBtn.BackgroundColor3 = C.blue
    testAIBtn.Text = "Test AI Chat Sekali"
    testAIBtn.TextColor3 = C.white
    testAIBtn.Font = Enum.Font.GothamBold
    testAIBtn.TextSize = 11
    testAIBtn.AutoButtonColor = false
    corner(testAIBtn, 10)
    pressFX(testAIBtn)
    testAIBtn.MouseButton1Click:Connect(function()
        if GroqApiKey == "" then
            if _G.showDynamicNotification then _G.showDynamicNotification("API key kosong", C.red) end
            return
        end
        DoAIChatOnce()
    end)

    -- ===== CONFIG PANEL =====
    local configLayout = Instance.new("UIListLayout", panelConfig)
    configLayout.Padding = UDim.new(0, 8)
    configLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local saveCfgBtn = Instance.new("TextButton", panelConfig)
    saveCfgBtn.Size = UDim2.new(1, 0, 0, 44)
    saveCfgBtn.BackgroundColor3 = C.green
    saveCfgBtn.Text = "Simpan Config"
    saveCfgBtn.TextColor3 = C.bg
    saveCfgBtn.Font = Enum.Font.GothamBold
    saveCfgBtn.TextSize = 12
    saveCfgBtn.AutoButtonColor = false
    corner(saveCfgBtn, 10)
    pressFX(saveCfgBtn)
    saveCfgBtn.MouseButton1Click:Connect(function() saveConfig(); if _G.showDynamicNotification then _G.showDynamicNotification("Config disimpan", C.green) end end)

    local loadCfgBtn = Instance.new("TextButton", panelConfig)
    loadCfgBtn.Size = UDim2.new(1, 0, 0, 44)
    loadCfgBtn.BackgroundColor3 = C.blue
    loadCfgBtn.Text = "Muat Config"
    loadCfgBtn.TextColor3 = C.white
    loadCfgBtn.Font = Enum.Font.GothamBold
    loadCfgBtn.TextSize = 12
    loadCfgBtn.AutoButtonColor = false
    corner(loadCfgBtn, 10)
    pressFX(loadCfgBtn)
    loadCfgBtn.MouseButton1Click:Connect(function() loadConfig(); if _G.showDynamicNotification then _G.showDynamicNotification("Config dimuat", C.blue) end end)

    -- ===== HISTORY PANEL =====
    local histLayout = Instance.new("UIListLayout", panelHistory)
    histLayout.Padding = UDim.new(0, 6)
    histLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local function renderHistory()
        for _, child in ipairs(panelHistory:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextButton") then child:Destroy() end
        end
        if #HistoryList == 0 then
            local empty = Instance.new("TextLabel", panelHistory)
            empty.Size = UDim2.new(1, 0, 0, 30)
            empty.BackgroundTransparency = 1
            empty.Text = "Belum ada riwayat clone"
            empty.TextColor3 = C.gray
            empty.Font = Enum.Font.GothamBold
            empty.TextSize = 11
            empty.Parent = panelHistory
            return
        end
        for _, entry in ipairs(HistoryList) do
            local card = Instance.new("Frame", panelHistory)
            card.Size = UDim2.new(1, 0, 0, 60)
            card.BackgroundColor3 = C.card2
            card.Parent = panelHistory
            corner(card, 10)
            stroke(card, C.card2, 1, 0.3)

            local nameLbl = Instance.new("TextLabel", card)
            nameLbl.Size = UDim2.new(1, -80, 0, 20)
            nameLbl.Position = UDim2.fromOffset(10, 6)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text = entry.displayName
            nameLbl.TextColor3 = C.white
            nameLbl.Font = Enum.Font.GothamBold
            nameLbl.TextSize = 11
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.Parent = card

            local userLbl = Instance.new("TextLabel", card)
            userLbl.Size = UDim2.new(1, -80, 0, 16)
            userLbl.Position = UDim2.fromOffset(10, 28)
            userLbl.BackgroundTransparency = 1
            userLbl.Text = "@"..entry.username
            userLbl.TextColor3 = C.gray
            userLbl.Font = Enum.Font.Gotham
            userLbl.TextSize = 9
            userLbl.TextXAlignment = Enum.TextXAlignment.Left
            userLbl.Parent = card

            local cloneBtn = Instance.new("TextButton", card)
            cloneBtn.Size = UDim2.fromOffset(50, 28)
            cloneBtn.Position = UDim2.new(1, -60, 0.5, -14)
            cloneBtn.BackgroundColor3 = C.red
            cloneBtn.Text = "Clone"
            cloneBtn.TextColor3 = C.white
            cloneBtn.Font = Enum.Font.GothamBold
            cloneBtn.TextSize = 8
            cloneBtn.AutoButtonColor = false
            cloneBtn.Parent = card
            corner(cloneBtn, 6)
            pressFX(cloneBtn)
            cloneBtn.MouseButton1Click:Connect(function()
                CreateCloneFromUserId(entry.userId, entry.displayName, entry.username)
            end)
        end
    end

    renderHistory()
end

-- ===================== INITIALIZATION =====================
-- Load persistence
loadHistory()
loadFavorites()
loadConfig()

-- Gizmo setup (created on demand)
PositionGizmo = Instance.new("Handles")
PositionGizmo.Style = Enum.HandlesStyle.Movement
PositionGizmo.Color3 = C.red
PositionGizmo.Parent = TargetGui

RotationGizmo = Instance.new("ArcHandles")
RotationGizmo.Color3 = C.purple
RotationGizmo.Parent = TargetGui

-- Clean up on app close? Not handled here.

print("[MyClone] App loaded. Call _G.openMyCloneApp() to open.")