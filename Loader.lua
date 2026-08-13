-- ================================================
-- AVATARCLONE LOADER - Full Rewrite with AppRegistry
-- ================================================

-- Duplicate execution guard
if _G.AvatarCloneLoaded then
    warn("[AvatarClone] Already loaded. Cleaning up previous instance...")
    if _G.AvatarCloneCleanup then
        _G.AvatarCloneCleanup()
    end
end

_G.AvatarCloneLoaded = true
_G.AvatarCloneCleanup = function()
    -- Cleanup function will be populated by modules
    for _, cleanup in ipairs(_G.AvatarCloneCleanupTasks or {}) do
        pcall(cleanup)
    end
    _G.AvatarCloneCleanupTasks = {}
    _G.AvatarCloneLoaded = false
end

_G.AvatarCloneCleanupTasks = {}

local BASE_URL = "https://raw.githubusercontent.com/AlfreadRorw/AvatarClone/main/"

local LoadStats = {
    loaded = 0,
    failed = 0,
    skipped = 0,
    errors = {},
}

-- ==================== LOAD FUNCTION ====================
local function Load(path)
    local function logError(stage, err)
        local msg = string.format("[AvatarClone][ERROR] Module: %s | Stage: %s | Error: %s", path, stage, tostring(err))
        warn(msg)
        table.insert(LoadStats.errors, msg)
        LoadStats.failed = LoadStats.failed + 1
    end

    -- Stage 1: HTTP Download
    local httpOk, source = pcall(function()
        return game:HttpGet(BASE_URL .. path, true)
    end)
    
    if not httpOk then
        logError("http", source)
        return nil
    end
    
    -- Stage 2: Loadstring
    local loadOk, loadedFunc = pcall(function()
        return loadstring(source)
    end)
    
    if not loadOk or not loadedFunc then
        logError("loadstring", loadedFunc or "Invalid source")
        return nil
    end
    
    -- Stage 3: Execution
    local execOk, result = pcall(function()
        return loadedFunc()
    end)
    
    if not execOk then
        logError("execute", result)
        return nil
    end
    
    LoadStats.loaded = LoadStats.loaded + 1
    return result
end

-- ==================== SERVICES ====================
local Services = {
    Players = game:GetService("Players"),
    TweenService = game:GetService("TweenService"),
    UserInputService = game:GetService("UserInputService"),
    HttpService = game:GetService("HttpService"),
    Workspace = game:GetService("Workspace"),
    RunService = game:GetService("RunService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    SoundService = game:GetService("SoundService"),
    TeleportService = game:GetService("TeleportService"),
    CoreGui = game:GetService("CoreGui"),
    MarketplaceService = game:GetService("MarketplaceService"),
}
_G.Services = Services

local LocalPlayer = Services.Players.LocalPlayer
_G.LocalPlayer = LocalPlayer

-- ==================== APP REGISTRY ====================
_G.AppRegistry = {}

local function registerApp(name, opener)
    _G.AppRegistry[name] = {
        opener = opener,
        available = type(opener) == "function",
    }
end

-- ==================== LOAD CONFIG ====================
print("[AvatarClone] Loading Config...")
local Config = Load("Config.lua")

if not Config then
    error("[AvatarClone] CRITICAL: Config failed to load. Initialization aborted.")
end

_G.Config = Config

-- ==================== LOAD CORE MODULES ====================
local coreModules = {
    {path = "Core/Theme.lua", name = "Theme"},
    {path = "Core/Helpers.lua", name = "Helpers"},
    {path = "Core/Assets.lua", name = "Assets"},
    {path = "Core/Storage.lua", name = "Storage"},
    {path = "Firebase.lua", name = "Firebase"},
    {path = "Core/Phone.lua", name = "Phone"},
    {path = "Core/Icons.lua", name = "Icons"},
    {path = "Core/LoadingNotif.lua", name = "LoadingNotif"},
}

local totalSteps = #coreModules + 3 + 1 -- core + 3 apps + floating icon
local currentStep = 0

local function updateProgress(name)
    currentStep = currentStep + 1
    if _G.updateLoadingProgress then
        _G.updateLoadingProgress(currentStep, totalSteps, name)
    end
end

-- Show loading notification
if _G.showLoadingNotification then
    _G.showLoadingNotification()
end

-- Load core modules
for _, module in ipairs(coreModules) do
    updateProgress(module.name)
    local result = Load(module.path)
    if result then
        _G[module.name] = result
    end
end

-- ==================== LOAD APPLICATIONS (ONLY AVAILABLE) ====================
local availableApps = {
    {path = "Applications/Players.lua", name = "Players", register = "Players"},
    {path = "Applications/NotifWeb.lua", name = "NotifWeb", register = "NotifWeb"},
    {path = "Applications/Settings.lua", name = "Settings", register = "Settings"},
}

for _, app in ipairs(availableApps) do
    updateProgress(app.name)
    local result = Load(app.path)
    if result then
        registerApp(app.register, _G["open" .. app.register .. "App"])
    end
end

-- ==================== BUILD ICONS (AFTER APPS LOADED) ====================
updateProgress("BuildIcons")
Load("Core/BuildIcons.lua")

-- ==================== FLOATING ICON ====================
updateProgress("FloatingIcon")
Load("Core/FloatingIcon.lua")

-- ==================== FINAL REPORT ====================
if _G.finishLoading then
    _G.finishLoading()
end

print("[AvatarClone] ============ LOAD REPORT ============")
print(string.format("[AvatarClone] Loaded: %d | Failed: %d | Skipped: %d", LoadStats.loaded, LoadStats.failed, LoadStats.skipped))

if LoadStats.failed > 0 then
    print("[AvatarClone] Loaded with errors!")
    for _, err in ipairs(LoadStats.errors) do
        warn(err)
    end
else
    print("[AvatarClone] All modules loaded successfully!")
end
print("[AvatarClone] =====================================")