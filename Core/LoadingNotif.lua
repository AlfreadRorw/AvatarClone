-- ================================================
-- LOADING NOTIFICATION - Muncul Sebelum FloatingIcon
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
local LogoURL = Config.LogoURL or "https://files.catbox.moe/io8o2d.png"
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
local isLoadingDone = false

local function createLoadingNotification()
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

    -- Container utama (kanan bawah)
    local container = Instance.new("Frame", notifGui)
    container.Size = UDim2.new(0, 0, 0, 62)
    container.Position = UDim2.new(1, -20, 1, -20)
    container.AnchorPoint = Vector2.new(1, 1)
    container.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    container.BorderSizePixel = 0
    container.ZIndex = 1001
    container.ClipsDescendants = true
    corner(container, 16)
    stroke(container, Color3.fromRGB(255, 255, 255), 2, 0.8)

    -- Gradient background
    local bgGradient = Instance.new("UIGradient", container)
    bgGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 32)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 20))
    })
    bgGradient.Rotation = 135

    -- Glow line
    local glowLine = Instance.new("Frame", container)
    glowLine.Size = UDim2.new(1, 0, 0, 2)
    glowLine.Position = UDim2.new(0, 0, 0, 0)
    glowLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    glowLine.BorderSizePixel = 0
    glowLine.ZIndex = 1002
    corner(glowLine, 1)

    -- Logo container
    local logoFrame = Instance.new("Frame", container)
    logoFrame.Size = UDim2.new(0, 46, 0, 46)
    logoFrame.Position = UDim2.new(0, 8, 0.5, -23)
    logoFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    logoFrame.BackgroundTransparency = 0.9
    logoFrame.ZIndex = 1003
    corner(logoFrame, 10)
    stroke(logoFrame, Color3.fromRGB(255, 255, 255), 1, 0.5)

    local logoImage = Instance.new("ImageLabel", logoFrame)
    logoImage.Size = UDim2.new(1, -6, 1, -6)
    logoImage.Position = UDim2.new(0, 3, 0, 3)
    logoImage.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    logoImage.Image = FinalLogo
    logoImage.ScaleType = Enum.ScaleType.Fit
    logoImage.ZIndex = 1004
    corner(logoImage, 8)

    -- Text area
    local textFrame = Instance.new("Frame", container)
    textFrame.Size = UDim2.new(1, -62, 1, 0)
    textFrame.Position = UDim2.new(0, 58, 0, 0)
    textFrame.BackgroundTransparency = 1
    textFrame.ZIndex = 1003

    -- Title
    local titleLbl = Instance.new("TextLabel", textFrame)
    titleLbl.Size = UDim2.new(1, -10, 0, 20)
    titleLbl.Position = UDim2.new(0, 5, 0, 10)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "PhoneIDViewer"
    titleLbl.TextColor3 = Color3.new(1, 1, 1)
    titleLbl.Font = Enum.Font.GothamBlack
    titleLbl.TextSize = 12
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 1004

    -- Status text (berubah-ubah)
    local statusLbl = Instance.new("TextLabel", textFrame)
    statusLbl.Size = UDim2.new(1, -10, 0, 16)
    statusLbl.Position = UDim2.new(0, 5, 0, 30)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text = "Loading..."
    statusLbl.TextColor3 = Color3.fromRGB(150, 150, 170)
    statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextSize = 9
    statusLbl.TextXAlignment = Enum.TextXAlignment.Left
    statusLbl.ZIndex = 1004

    -- Progress bar
    local progressBg = Instance.new("Frame", container)
    progressBg.Size = UDim2.new(1, -16, 0, 3)
    progressBg.Position = UDim2.new(0, 8, 1, -6)
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
    tween(container, {Size = UDim2.new(0, 240, 0, 62)}, 0.4, Enum.EasingStyle.Back)

    -- ==================== SIMULASI LOADING ====================
    local loadingSteps = {
        {text = "Menghubungkan ke Firebase...", duration = 1.2},
        {text = "Memuat komponen UI...", duration = 1.0},
        {text = "Menyiapkan aplikasi...", duration = 0.8},
        {text = "Selesai!", duration = 0.5},
    }

    task.spawn(function()
        local totalDuration = 0
        for _, step in ipairs(loadingSteps) do
            totalDuration = totalDuration + step.duration
        end

        local elapsed = 0
        for _, step in ipairs(loadingSteps) do
            statusLbl.Text = step.text
            local stepStart = elapsed
            local stepEnd = elapsed + step.duration
            
            -- Update progress bar selama step ini
            while elapsed < stepEnd do
                task.wait(0.05)
                elapsed = elapsed + 0.05
                local progress = math.clamp(elapsed / totalDuration, 0, 1)
                tween(progressFill, {Size = UDim2.new(progress, 0, 1, 0)}, 0.05)
            end
        end

        isLoadingDone = true
        
        -- Animasi keluar
        task.wait(0.3)
        tween(container, {Position = UDim2.new(1, 20, 1, -20)}, 0.3, Enum.EasingStyle.Quart)
        
        task.wait(0.3)
        pcall(function() notifGui:Destroy() end)
        notifGui = nil
        
        -- Trigger event bahwa loading selesai
        _G.OnLoadingComplete()
    end)

    return notifGui
end

-- ==================== GLOBAL FUNCTIONS ====================
function _G.showLoadingNotification()
    isLoadingDone = false
    return createLoadingNotification()
end

function _G.isLoadingDone()
    return isLoadingDone
end

-- ==================== CALLBACK SETUP ====================
-- Fungsi ini akan dipanggil setelah loading selesai
_G.OnLoadingComplete = function()
    print("[LoadingNotif] Loading selesai!")
    -- FloatingIcon akan muncul setelah ini
    -- (FloatingIcon.lua akan menunggu signal ini)
end

print("[LoadingNotif] Module ready!")