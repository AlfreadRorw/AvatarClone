-- ================================================
-- PHONE ID VIEWER - Modular Loader (FINAL - Premium Sub-Apps)
-- ================================================

-- Duplicate execution guard
if _G.AvatarCloneLoaded then
    warn("[PhoneIDViewer] Already loaded. Cleaning up previous instance...")
    if _G.AvatarCloneCleanup then
        _G.AvatarCloneCleanup()
    end
end

_G.AvatarCloneLoaded = true
_G.AvatarCloneCleanupTasks = {}

_G.AvatarCloneCleanup = function()
    for _, cleanup in ipairs(_G.AvatarCloneCleanupTasks or {}) do
        pcall(cleanup)
    end
    _G.AvatarCloneCleanupTasks = {}
    _G.AvatarCloneLoaded = false
end

local BASE_URL = "https://raw.githubusercontent.com/AlfreadRorw/AvatarClone/main/"

local LoadStats = {
    loaded = 0,
    failed = 0,
    skipped = 0,
    errors = {},
}

local function Load(path)
    local function logError(stage, err)
        local msg = string.format("[PhoneIDViewer][ERROR] Module: %s | Stage: %s | Error: %s", path, stage, tostring(err))
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

-- ==================== LOAD CONFIG ====================
print("[PhoneIDViewer] Loading Config...")
local Config = Load("Config.lua")

if not Config then
    error("[PhoneIDViewer] CRITICAL: Config failed to load. Initialization aborted.")
end

_G.Config = Config

-- ==================== LOAD CORE MODULES ====================
local Theme = Load("Core/Theme.lua")
_G.T = Theme

local Helpers = Load("Core/Helpers.lua")
_G.Helpers = Helpers

local Assets = Load("Core/Assets.lua")
_G.Assets = Assets

-- ==================== LOADING NOTIFICATION ====================
Load("Core/LoadingNotif.lua")

-- ==================== HITUNG TOTAL STEPS ====================
local coreSteps = 7  -- Storage, Firebase, Phone, Icons, BuildIcons, CommandListener
local appSteps = 20  -- AppList (20 apps)
local iconPremSteps = 1  -- IconPrem/Premium.lua
local permanentSteps = 11  -- Permanent sub-apps
local totalSteps = coreSteps + appSteps + iconPremSteps + permanentSteps + 1  -- +1 FloatingIcon

local currentStep = 0

local function updateProgress(stepName)
    currentStep = currentStep + 1
    if _G.updateLoadingProgress then
        _G.updateLoadingProgress(currentStep, totalSteps, stepName)
    end
end

-- Tampilkan loading notification
if _G.showLoadingNotification then
    _G.showLoadingNotification()
end

-- ==================== APP REGISTRY ====================
_G.AppRegistry = {}

local function registerApp(name, opener)
    _G.AppRegistry[name] = {
        opener = opener,
        available = type(opener) == "function",
    }
end

-- Load Storage
updateProgress("Storage")
local Storage = Load("Core/Storage.lua")
_G.Storage = Storage

-- Load Firebase
updateProgress("Firebase")
local Firebase = Load("Firebase.lua")
_G.Firebase = Firebase

-- Load Phone
updateProgress("Phone GUI")
local Phone = Load("Core/Phone.lua")
_G.Phone = Phone

-- Load Icons
updateProgress("Icons")
local Icons = Load("Core/Icons.lua")
_G.Icons = Icons

-- Load CommandListener
updateProgress("Command Listener")
Load("Core/CommandListener.lua")

-- ==================== LOAD APPLICATIONS ====================
local AppList = {
    {path = "Applications/Players.lua", name = "Players", register = "Players"},
    {path = "Applications/Clone.lua", name = "Clone", register = "Clone"},
    {path = "Applications/Preset.lua", name = "Preset", register = "Preset"},
    {path = "Applications/Favorites.lua", name = "Favorites", register = "Favorites"},
    {path = "Applications/Items.lua", name = "Items", register = "Items"},
    {path = "Applications/Teleport.lua", name = "Teleport", register = "Teleport"},
    {path = "Applications/Size.lua", name = "Size", register = "Size"},
    {path = "Applications/Volume.lua", name = "Volume", register = "Volume"},
    {path = "Applications/Friends.lua", name = "Friends", register = "Friends"},
    {path = "Applications/Server.lua", name = "Server", register = "Server"},
    {path = "Applications/Bundle.lua", name = "Bundle", register = "Bundle"},
    {path = "Applications/AvatarItems.lua", name = "AvatarItems", register = "AvatarItems"},
    {path = "Applications/WhoOnline.lua", name = "WhoOnline", register = "WhoOnline"},
    {path = "Applications/Messages.lua", name = "Messages", register = "Messages"},
    {path = "Applications/Command.lua", name = "Command", register = "Command"},
    {path = "Applications/Settings.lua", name = "Settings", register = "Settings"},
    {path = "Applications/Premium.lua", name = "Premium", register = "Premium"},
    {path = "Applications/AlfreadAI.lua", name = "AlfreadAI", register = "AlfreadAI"},
    {path = "Applications/Shader.lua", name = "Shader", register = "Shader"},
    {path = "Applications/Games.lua", name = "Games", register = "Games"},
    {path = "Applications/Emote.lua", name = "Emote", register = "Emote"},
}

for _, app in ipairs(AppList) do
    updateProgress(app.name)
    local result = Load(app.path)
    if result then
        registerApp(app.register, _G["open" .. app.register .. "App"])
    end
end

-- ==================== LOAD PREMIUM ICONS ====================
updateProgress("Premium Icons")
Load("Applications/IconPrem/Premium.lua")

-- ==================== LOAD PREMIUM PERMANENT SUB-APPS ====================
local PermanentAppList = {
    {path = "Applications/Permanent/Target.lua", name = "Premium/Target"},
    {path = "Applications/Permanent/Chat.lua", name = "Premium/Chat"},
    {path = "Applications/Permanent/Jail.lua", name = "Premium/Jail"},
    {path = "Applications/Permanent/Teleport.lua", name = "Premium/Teleport"},
    {path = "Applications/Permanent/Bling.lua", name = "Premium/Bling"},
    {path = "Applications/Permanent/Fly.lua", name = "Premium/Fly"},
    {path = "Applications/Permanent/Movement.lua", name = "Premium/Movement"},
    {path = "Applications/Permanent/Jumpscare.lua", name = "Premium/Jumpscare"},
    {path = "Applications/Permanent/Aura.lua", name = "Premium/Aura"},
    {path = "Applications/Permanent/Sky.lua", name = "Premium/Sky"},
    {path = "Applications/Permanent/Dex.lua", name = "Premium/Dex"},
}

for _, app in ipairs(PermanentAppList) do
    updateProgress(app.name)
    Load(app.path)
end

-- ==================== LOAD BUILD ICONS (SETELAH SEMUA APP) ====================
updateProgress("Build Icons")
Load("Core/BuildIcons.lua")

-- ==================== LOAD FLOATING ICON ====================
updateProgress("Floating Icon")
Load("Core/FloatingIcon.lua")

-- ==================== FINISH ====================
if _G.finishLoading then
    _G.finishLoading()
end

-- ==================== FINAL REPORT ====================
print("[PhoneIDViewer] ============ LOAD REPORT ============")
print(string.format("[PhoneIDViewer] Loaded: %d | Failed: %d", LoadStats.loaded, LoadStats.failed))

if LoadStats.failed > 0 then
    print("[PhoneIDViewer] Loaded with errors!")
    for _, err in ipairs(LoadStats.errors) do
        warn(err)
    end
else
    print("[PhoneIDViewer] All modules loaded successfully!")
end

print("[PhoneIDViewer] Phone:", _G.Phone and "OK" or "FAILED")
print("[PhoneIDViewer] Firebase:", _G.Firebase and "OK" or "FAILED")
print("[PhoneIDViewer] Storage:", _G.Storage and "OK" or "FAILED")
print("[PhoneIDViewer] Assets:", _G.Assets and "OK" or "FAILED")
print("[PhoneIDViewer] Premium Sub-Apps:", #PermanentAppList .. " loaded")
print("[PhoneIDViewer] =====================================")