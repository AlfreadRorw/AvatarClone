-- ================================================
-- ASSETS MANAGER - Safe Filesystem Handling
-- ================================================

local Config = _G.Config or {}

local Assets = {}

local ROOT = "PhoneIDViewer/Assets/Icons"
local LOGO_PATH = Config.LogoLocalPath or "PhoneIDViewer/Assets/Logo.png"

local DEBUG = Config.DEBUG or false

local function log(...)
    if DEBUG then
        print("[Assets]", ...)
    end
end

-- Check if filesystem functions are available
local function hasFilesystem()
    return type(isfile) == "function" and type(writefile) == "function"
end

local function hasCustomAsset()
    return type(getcustomasset) == "function"
end

-- Ensure file exists, download if needed
local function ensureFile(localPath, url)
    if not hasFilesystem() then
        return false, "filesystem_unavailable"
    end
    
    if isfile(localPath) then
        return true, nil
    end
    
    local ok, err = pcall(function()
        writefile(localPath, game:HttpGet(url))
    end)
    
    if not ok then
        log("Download failed:", localPath, err)
        return false, tostring(err)
    end
    
    log("Downloaded:", localPath)
    return true, nil
end

-- Get logo
function Assets.GetLogo()
    local logoPath = LOGO_PATH
    local ok, err = ensureFile(logoPath, Config.LogoURL or "")
    
    if ok and hasCustomAsset() then
        local customOk, customResult = pcall(function()
            return getcustomasset(logoPath)
        end)
        if customOk and customResult then
            return customResult
        end
    end
    
    return Config.LogoURL or ""
end

-- Get icon by name
function Assets.GetIcon(iconName)
    local iconURL = Config.IconURLs and Config.IconURLs[iconName]
    
    if not iconURL then
        log("Icon URL not found:", iconName)
        return "" -- Empty string is safer than nil
    end
    
    local localPath = ROOT .. "/" .. iconName .. ".png"
    local ok, err = ensureFile(localPath, iconURL)
    
    if ok and hasCustomAsset() then
        local customOk, customResult = pcall(function()
            return getcustomasset(localPath)
        end)
        if customOk and customResult then
            return customResult
        end
    end
    
    -- Fallback to URL
    return iconURL
end

-- Preload all icons (synchronous to ensure availability)
function Assets.PreloadAll()
    if not hasFilesystem() then
        log("Filesystem not available, using remote URLs")
        return
    end
    
    local count = 0
    if Config.IconURLs then
        for name, url in pairs(Config.IconURLs) do
            local localPath = ROOT .. "/" .. name .. ".png"
            local ok = ensureFile(localPath, url)
            if ok then
                count = count + 1
            end
        end
    end
    
    ensureFile(LOGO_PATH, Config.LogoURL or "")
    
    log("Preloaded", count, "icons")
end

-- Preload synchronously
Assets.PreloadAll()

return Assets