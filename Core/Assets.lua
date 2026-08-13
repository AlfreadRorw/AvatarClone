-- ================================================
-- ASSETS MANAGER - Download & Cache Local Icons
-- ================================================

local Services = _G.Services
local HttpService = Services.HttpService
local Config = _G.Config

local Assets = {}

local ROOT = "PhoneIDViewer/Assets/Icons"
local LOGO_PATH = "PhoneIDViewer/Assets/Logo.png"

-- Helper untuk download file jika belum ada
local function ensureFile(localPath, url)
    if not isfile(localPath) then
        pcall(function()
            writefile(localPath, game:HttpGet(url))
            print("[Assets] Downloaded:", localPath)
        end)
    end
    return isfile(localPath)
end

-- Muat logo notifikasi
function Assets.GetLogo()
    local logoPath = Config.LogoLocalPath or LOGO_PATH
    if ensureFile(logoPath, Config.LogoURL) then
        if getcustomasset then
            local ok, result = pcall(function()
                return getcustomasset(logoPath)
            end)
            if ok and result then
                return result
            end
        end
        return Config.LogoURL
    end
    return Config.LogoURL
end

-- Muat icon berdasarkan nama
function Assets.GetIcon(iconName)
    local iconURL = Config.IconURLs and Config.IconURLs[iconName]
    if not iconURL then
        return ""
    end

    local localPath = ROOT .. "/" .. iconName .. ".png"
    if ensureFile(localPath, iconURL) then
        if getcustomasset then
            local ok, result = pcall(function()
                return getcustomasset(localPath)
            end)
            if ok and result then
                return result
            end
        end
        return iconURL
    end
    return iconURL
end

-- Cek apakah icon sudah terdownload
function Assets.IsIconCached(iconName)
    local localPath = ROOT .. "/" .. iconName .. ".png"
    return isfile(localPath)
end

-- Preload semua icon
function Assets.PreloadAll()
    task.spawn(function()
        if Config.IconURLs then
            for name, url in pairs(Config.IconURLs) do
                local localPath = ROOT .. "/" .. name .. ".png"
                ensureFile(localPath, url)
            end
        end
        ensureFile(Config.LogoLocalPath or LOGO_PATH, Config.LogoURL)
        print("[Assets] All assets loaded!")
    end)
end

-- Preload otomatis
Assets.PreloadAll()

return Assets