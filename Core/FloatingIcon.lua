local T           = _G.T
local Helpers     = _G.Helpers
local Storage     = _G.Storage
local phone       = _G.phone
local goHome      = _G.goHome

local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace   = game:GetService("Workspace")
local UIS         = game:GetService("UserInputService")
local TweenService= game:GetService("TweenService")

local PHONE_SIZE_PORTRAIT = UDim2.new(0,320,0,560)
local PHONE_SIZE = PHONE_SIZE_PORTRAIT
local phoneIcon  = nil
local mouseDown  = false
local mouseMoved = false
local dragStart  = nil
local iconStartPos = nil

local function isPortrait()
    local cam = Workspace.CurrentCamera
    if not cam then return true end
    return cam.ViewportSize.Y >= cam.ViewportSize.X
end

local function applyPhoneSize()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    if vp.X > vp.Y then
        local phoneW = math.min(vp.X-10, 520)
        local phoneH = math.min(vp.Y-10, 320)
        PHONE_SIZE = UDim2.new(0,phoneW,0,phoneH)
        phone.Position = UDim2.new(0.5,0,0.5,0)
    else
        PHONE_SIZE = PHONE_SIZE_PORTRAIT
        phone.Position = UDim2.new(0.5,0,0.52,0)
    end
    if phone.Visible then
        Helpers.tween(phone, {Size=PHONE_SIZE, Position=phone.Position}, 0.3, Enum.EasingStyle.Quart)
    end
end

local function getGuiParent()
    local ok, r = pcall(function()
        if gethui then return gethui() end
        return game:GetService("CoreGui")
    end)
    return ok and r or game:GetService("CoreGui")
end

local function createFloatingIcon()
    if phoneIcon then pcall(function() phoneIcon:Destroy() end) phoneIcon = nil end

    local iconGui = Instance.new("ScreenGui")
    iconGui.Name = "PhoneIcon"
    iconGui.ResetOnSpawn = false
    iconGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    iconGui.DisplayOrder = 999
    iconGui.IgnoreGuiInset = true
    pcall(function() iconGui.Parent = game:GetService("CoreGui") end)
    if not iconGui.Parent then iconGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local iconContainer = Instance.new("Frame", iconGui)
    iconContainer.Size = UDim2.new(0,65,0,105)
    iconContainer.Position = UDim2.new(0,15,0.5,-52)
    iconContainer.BackgroundTransparency = 1
    iconContainer.ZIndex = 1000

    -- Phone body
    local phoneBody = Instance.new("Frame", iconContainer)
    phoneBody.Size = UDim2.new(0,50,0,88)
    phoneBody.Position = UDim2.new(0.5,-25,0.5,-44)
    phoneBody.BackgroundColor3 = Color3.fromRGB(15,15,18)
    phoneBody.ZIndex = 1001
    Helpers.corner(phoneBody, 12)
    Helpers.stroke(phoneBody, Color3.fromRGB(45,45,50), 2, 0)

    local bodyGrad = Instance.new("UIGradient", phoneBody)
    bodyGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(28,28,32)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(12,12,16))
    })
    bodyGrad.Rotation = 135

    -- Screen
    local screen = Instance.new("Frame", phoneBody)
    screen.Size = UDim2.new(1,-6,1,-30)
    screen.Position = UDim2.new(0,3,0,20)
    screen.BackgroundColor3 = Color3.fromRGB(0,0,0)
    screen.ZIndex = 1002
    Helpers.corner(screen, 8)

    -- Wallpaper
    local wallpaper = Instance.new("Frame", screen)
    wallpaper.Size = UDim2.new(1,-4,1,-14)
    wallpaper.Position = UDim2.new(0.5,0,0,13)
    wallpaper.AnchorPoint = Vector2.new(0.5,0)
    wallpaper.BackgroundColor3 = Color3.fromRGB(10,10,15)
    wallpaper.ZIndex = 1003
    Helpers.corner(wallpaper, 6)

    -- App icons on wallpaper
    local iconPositions = {
        {x=3,y=6},{x=14,y=6},{x=25,y=6},
        {x=3,y=17},{x=14,y=17},{x=25,y=17},
    }
    local iconColors = {
        Color3.fromRGB(100,160,255), Color3.fromRGB(255,120,120),
        Color3.fromRGB(80,210,80),   Color3.fromRGB(255,200,50),
        Color3.fromRGB(180,100,255), Color3.fromRGB(255,160,60),
    }
    for i, pos in ipairs(iconPositions) do
        local ic = Instance.new("Frame", wallpaper)
        ic.Size = UDim2.new(0,8,0,8)
        ic.Position = UDim2.new(0,pos.x,0,pos.y)
        ic.BackgroundColor3 = iconColors[i]
        ic.BorderSizePixel = 0
        ic.ZIndex = 1004
        Helpers.corner(ic, 2.5)
    end

    -- Dynamic Island
    local di2 = Instance.new("Frame", phoneBody)
    di2.Size = UDim2.new(0,24,0,5)
    di2.Position = UDim2.new(0.5,-12,0,6)
    di2.BackgroundColor3 = Color3.fromRGB(0,0,0)
    di2.ZIndex = 1020
    Helpers.corner(di2, 3)

    -- Home bar
    local hb = Instance.new("Frame", phoneBody)
    hb.Size = UDim2.new(0,22,0,3)
    hb.Position = UDim2.new(0.5,-11,1,-5)
    hb.BackgroundColor3 = Color3.fromRGB(255,255,255)
    hb.BackgroundTransparency = 0.6
    hb.BorderSizePixel = 0
    hb.ZIndex = 1020
    Helpers.corner(hb, 2)

    -- Click button
    local clickBtn = Instance.new("TextButton", iconContainer)
    clickBtn.Size = UDim2.new(0,55,0,95)
    clickBtn.Position = UDim2.new(0.5,-27,0.5,-47)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.ZIndex = 1030
    clickBtn.AutoButtonColor = false

    clickBtn.MouseEnter:Connect(function()
        Helpers.tween(phoneBody, {Size=UDim2.new(0,54,0,94)}, 0.15)
    end)
    clickBtn.MouseLeave:Connect(function()
        if not mouseDown then
            Helpers.tween(phoneBody, {Size=UDim2.new(0,50,0,88)}, 0.15)
        end
    end)

    -- Toggle phone
    clickBtn.MouseButton1Click:Connect(function()
        if mouseMoved then return end
        if phone.Visible then
            Helpers.tween(phone, {Size=UDim2.new(0,0,0,0)}, 0.25)
            task.delay(0.25, function()
                phone.Visible = false
            end)
        else
            applyPhoneSize()
            phone.Visible = true
            phone.Size = UDim2.new(0,0,0,0)
            Helpers.tween(phone, {Size=PHONE_SIZE}, 0.3, Enum.EasingStyle.Back)
            local state = _G.PhoneState
            local lock  = _G.PhoneLock
            if state.isLocked and lock then
                lock.Visible = true
            else
                goHome()
            end
        end
    end)

    -- Drag
    clickBtn.MouseButton1Down:Connect(function()
        mouseDown   = true
        mouseMoved  = false
        dragStart   = UIS:GetMouseLocation()
        iconStartPos = iconContainer.Position
    end)

    clickBtn.MouseButton1Up:Connect(function()
        mouseDown = false
        task.wait(0.1)
        mouseMoved = false
    end)

    UIS.InputChanged:Connect(function(input)
        if not mouseDown then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local pos = UIS:GetMouseLocation()
            if not dragStart then return end
            local delta = pos - dragStart
            if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then
                mouseMoved = true
            end
            if mouseMoved then
                local newX = iconStartPos.X.Offset + delta.X
                local newY = iconStartPos.Y.Offset + delta.Y
                local sv   = Workspace.CurrentCamera.ViewportSize
                newX = math.clamp(newX, 5, sv.X-70)
                newY = math.clamp(newY, 5, sv.Y-110)
                iconContainer.Position = UDim2.new(0,newX,0,newY)
            end
        end
    end)

    phoneIcon = iconGui
    return iconGui
end

-- Init
task.spawn(function()
    task.wait(1)
    createFloatingIcon()
    task.wait(0.5)
    -- Auto open
    applyPhoneSize()
    phone.Visible = true
    phone.Size = UDim2.new(0,0,0,0)
    Helpers.tween(phone, {Size=PHONE_SIZE}, 0.3, Enum.EasingStyle.Back)
    local lock = _G.PhoneLock
    if lock then lock.Visible = true end
end)

-- Respawn monitor
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if not phoneIcon or not phoneIcon.Parent then
        createFloatingIcon()
    end
end)

-- Orientation monitor
task.spawn(function()
    local lastLandscape = nil
    while true do
        task.wait(0.3)
        local cam = Workspace.CurrentCamera
        if not cam then continue end
        local isLand = cam.ViewportSize.X > cam.ViewportSize.Y
        if isLand ~= lastLandscape then
            lastLandscape = isLand
            applyPhoneSize()
        end
    end
end)