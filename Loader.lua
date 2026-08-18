-- ================================================
-- PHONE ID VIEWER - Modular Loader (FIXED + Premium Sub-Apps)
-- ================================================

local BASE_URL = "https://raw.githubusercontent.com/AlfreadRorw/AvatarClone/main/"

local function Load(path)
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(BASE_URL .. path, true))()
    end)
    if not ok then
        warn("[PhoneIDViewer] Failed: " .. path .. " | " .. tostring(result))
    end
    return ok and result or nil
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

-- ==================== LOAD CORE MODULES ====================
local Config = Load("Config.lua")
_G.Config = Config

local Theme = Load("Core/Theme.lua")
_G.T = Theme

local Helpers = Load("Core/Helpers.lua")
_G.Helpers = Helpers

-- ==================== LOADING NOTIFICATION ====================
Load("Core/LoadingNotif.lua")

-- ==================== LOAD MODULES WITH PROGRESS ====================
-- Hitung langkah: Core (7) + Apps (20) + Permanent Apps (11) + FloatingIcon (1) = 39
local coreSteps = 7  -- Storage, Firebase, Phone, Icons, BuildIcons, CommandListener
local appSteps = 20  -- AppList
local permanentSteps = 11  -- Permanent sub-apps
local totalSteps = coreSteps + appSteps + permanentSteps + 1  -- +1 FloatingIcon

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

-- Load BuildIcons
updateProgress("Build Icons")
Load("Core/BuildIcons.lua")

-- Load CommandListener
updateProgress("Command Listener")
Load("Core/CommandListener.lua")

-- ==================== LOAD APPLICATIONS ====================
local AppList = {
    {path = "Applications/Players.lua", name = "Players"},
    {path = "Applications/Clone.lua", name = "Clone"},
    {path = "Applications/Preset.lua", name = "Preset"},
    {path = "Applications/Favorites.lua", name = "Favorites"},
    {path = "Applications/Items.lua", name = "Items"},
    {path = "Applications/Teleport.lua", name = "Teleport"},
    {path = "Applications/Size.lua", name = "Size"},
    {path = "Applications/Volume.lua", name = "Volume"},
    {path = "Applications/Friends.lua", name = "Friends"},
    {path = "Applications/Server.lua", name = "Server"},
    {path = "Applications/Bundle.lua", name = "Bundle"},
    {path = "Applications/AvatarItems.lua", name = "AvatarItems"},
    {path = "Applications/WhoOnline.lua", name = "WhoOnline"},
    {path = "Applications/Messages.lua", name = "Messages"},
    {path = "Applications/Command.lua", name = "Command"},
    {path = "Applications/Settings.lua", name = "Settings"},
    {path = "Applications/Premium.lua", name = "Premium"},
    {path = "Applications/AlfreadAI.lua", name = "AlfreadAI"},
    {path = "Applications/Shader.lua", name = "Shader"},
    {path = "Applications/Games.lua", name = "Games"},
}

for _, app in ipairs(AppList) do
    updateProgress(app.name)
    Load(app.path)
end

-- ==================== LOAD PREMIUM PERMANENT SUB-APPS ====================
-- Ini adalah sub-app yang di-load oleh Premium.lua sebagai loader
-- Semua file di folder Applications/Permanent/
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

-- Load FloatingIcon
updateProgress("Floating Icon")
Load("Core/FloatingIcon.lua")

-- Selesai
if _G.finishLoading then
    _G.finishLoading()
end

print("[PhoneIDViewer] All modules loaded successfully!")
print("[PhoneIDViewer] Phone:", _G.Phone and "OK" or "FAILED")
print("[PhoneIDViewer] Firebase:", _G.Firebase and "OK" or "FAILED")
print("[PhoneIDViewer] Storage:", _G.Storage and "OK" or "FAILED")
print("[PhoneIDViewer] Premium Sub-Apps:", #PermanentAppList .. " loaded")