-- ================================================
-- LOADING NOTIFICATION - Bottom Corner with Logo
-- ================================================

local Services = _G.Services
local LocalPlayer = _G.LocalPlayer
local TweenService = Services.TweenService
local Helpers = _G.Helpers
local Config = _G.Config

local corner = Helpers.corner
local stroke = Helpers.stroke
local tween = Helpers.tween

-- ==================== ASSETS ====================
local LogoURL = Config.LogoURL or "https://files.catbox.moe/xbvd7n.png"
local LocalPath = Config.LogoLocalPath or "PhoneIDViewer_Logo.png"

-- Download logo ke local jika belum ada
pcall(function()
    if not isfile(LocalPath) then
        writefile(LocalPath, game:HttpGet(LogoURL))
    end
end)

local FinalLogo = (getcustomasset and isfile(LocalPath)) and getcustomasset(LocalPath) or LogoURL

-- ==================== NOTIFICATION GUI ====================
local notifGui = nil

local function createLoadingNotification(title, subtitle, duration)
    if notifGui then
        pcall(function() notifGui:Destroy() end)
        notifGui = nil
    end

    notifGui = Instance.new("ScreenGui")
    notifGui.Name = "LoadingNotif"
    notifGui.ResetOnSpawn = false
    notifGui.IgnoreGuiInset = true
    notifGui.DisplayOrder = 1000
    notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

    pcall(function() notifGui.Parent = game:GetService("CoreGui") end)
    if not notifGui.Parent then
        notifGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    -- Container utama (posisi di kanan bawah)
    local container = Instance.new("Frame", notifGui)
    container.Size = UDim2.new(0, 0, 0, 0) -- Mulai dari 0, akan dianimasikan
    container.Position = UDim2.new(1, -20, 1, -20) -- Kanan bawah
    container.AnchorPoint = Vector2.new(1, 1) -- Anchor ke kanan bawah
    container.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    container.BorderSizePixel = 0
    container.ZIndex = 1001
    container.ClipsDescendants = true

    -- Rounded corners untuk container (lekukan di semua pinggir)
    corner(container, 16)
    stroke(container, Color3.fromRGB(255, 255, 255), 2, 0.8)

    -- Gradient background
    local bgGradient = Instance.new("UIGradient", container)
    bgGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 32)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 20))
    })
    bgGradient.Rotation = 135

    -- Glow line di atas
    local glowLine = Instance.new("Frame", container)
    glowLine.Size = UDim2.new(1, 0, 0, 2)
    glowLine.Position = UDim2.new(0, 0, 0, 0)
    glowLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    glowLine.BorderSizePixel = 0
    glowLine.ZIndex = 1002
    corner(glowLine, 1)

    -- ==================== LOGO ====================
    local logoFrame = Instance.new("Frame", container)
    logoFrame.Size = UDim2.new(0, 50, 0, 50)
    logoFrame.Position = UDim2.new(0, 12, 0.5, -25)
    logoFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    logoFrame.BackgroundTransparency = 0.9
    logoFrame.ZIndex = 1003
    corner(logoFrame, 12) -- Rounded corners untuk logo container
    stroke(logoFrame, Color3.fromRGB(255, 255, 255), 1, 0.5)

    local logoImage = Instance.new("ImageLabel", logoFrame)
    logoImage.Size = UDim2.new(1, -8, 1, -8)
    logoImage.Position = UDim2.new(0, 4, 0, 4)
    logoImage.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    logoImage.Image = FinalLogo
    logoImage.ScaleType = Enum.ScaleType.Fit
    logoImage.ZIndex = 1004
    corner(logoImage, 8) -- Rounded corners untuk gambar

    -- ==================== TEXT AREA ====================
    local textFrame = Instance.new("Frame", container)
    textFrame.Size = UDim2.new(1, -74, 1, 0)
    textFrame.Position = UDim2.new(0, 70, 0, 0)
    textFrame.BackgroundTransparency = 1
    textFrame.ZIndex = 1003

    -- Title
    local titleLbl = Instance.new("TextLabel", textFrame)
    titleLbl.Size = UDim2.new(1, -10, 0, 22)
    titleLbl.Position = UDim2.new(0, 5, 0, 8)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title or "PhoneIDViewer"
    titleLbl.TextColor3 = Color3.new(1, 1, 1)
    titleLbl.Font = Enum.Font.GothamBlack
    titleLbl.TextSize = 13
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
    titleLbl.ZIndex = 1004

    -- Subtitle
    local subtitleLbl = Instance.new("TextLabel", textFrame)
    subtitleLbl.Size = UDim2.new(1, -10, 0, 18)
    subtitleLbl.Position = UDim2.new(0, 5, 0, 28)
    subtitleLbl.BackgroundTransparency = 1
    subtitleLbl.Text = subtitle or "Loading..."
    subtitleLbl.TextColor3 = Color3.fromRGB(150, 150, 170)
    subtitleLbl.Font = Enum.Font.Gotham
    subtitleLbl.TextSize = 10
    subtitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    subtitleLbl.TextTruncate = Enum.TextTruncate.AtEnd
    subtitleLbl.ZIndex = 1004

    -- ==================== PROGRESS BAR ====================
    local progressBg = Instance.new("Frame", container)
    progressBg.Size = UDim2.new(1, -24, 0, 3)
    progressBg.Position = UDim2.new(0, 12, 1, -8)
    progressBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    progressBg.BorderSizePixel = 0
    progressBg.ZIndex = 1003
    corner(progressBg, 2)

    local progressFill = Instance.new("Frame", progressBg)
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    progressFill.BorderSizePixel = 0
    progressFill.ZIndex = 1004
    corner(progressFill, 2)

    -- ==================== ANIMASI MASUK ====================
    -- Ukuran akhir
    local finalWidth = 250
    local finalHeight = 62

    -- Animasikan progress
    task.spawn(function()
        tween(progressFill, {Size = UDim2.new(1, 0, 1, 0)}, duration or 3)
    end)

    -- Animasi masuk (slide dari kanan + expand)
    container.Size = UDim2.new(0, 0, 0, finalHeight)
    container.Position = UDim2.new(1, -20, 1, -20)
    container.AnchorPoint = Vector2.new(1, 1)

    tween(container, {Size = UDim2.new(0, finalWidth, 0, finalHeight)}, 0.4, Enum.EasingStyle.Back)

    -- Tunggu sampai progress selesai
    task.spawn(function()
        task.wait(duration or 3)
        
        -- Animasi keluar (slide ke kanan)
        tween(container, {Position = UDim2.new(1, 20, 1, -20)}, 0.3, Enum.EasingStyle.Quart)
        
        task.wait(0.3)
        pcall(function() notifGui:Destroy() end)
        notifGui = nil
    end)

    return notifGui
end

-- ==================== GLOBAL FUNCTION ====================
function _G.showLoadingNotification(title, subtitle, duration)
    return createLoadingNotification(title, subtitle, duration)
end

-- ==================== TEST (Auto-show saat load) ====================
task.spawn(function()
    task.wait(0.5)
    _G.showLoadingNotification("PhoneIDViewer", "Loading system...", 3)
end)

print("[LoadingNotif] Module ready!")