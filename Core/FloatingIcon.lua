local Services = _G.Services
local LocalPlayer = _G.LocalPlayer
local UserInputService = Services.UserInputService
local TweenService = Services.TweenService

local phoneIcon = nil
local isDragging = false
local dragStart = nil
local iconStartPos = nil
local clickMoved = false
local btn, container -- referensi untuk animasi

local function createFloatingIcon()
    if phoneIcon then pcall(function() phoneIcon:Destroy() end) end

    local gui = Instance.new("ScreenGui")
    gui.Name = "PhoneIcon"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    -- Container
    container = Instance.new("Frame", gui)
    container.Size = UDim2.new(0, 60, 0, 90)
    container.Position = UDim2.new(0, 15, 0.5, -45)
    container.BackgroundTransparency = 1

    -- Tombol HP dengan efek glow
    btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(0, 52, 0, 84)
    btn.Position = UDim2.new(0.5, -26, 0.5, -42)
    btn.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    btn.Text = ""
    btn.AutoButtonColor = false

    -- Gradient background
    local btnGradient = Instance.new("UIGradient", btn)
    btnGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 35)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 15))
    })
    btnGradient.Rotation = 45

    -- Corner & stroke (glow)
    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 12)

    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Color = Color3.fromRGB(0, 200, 255)  -- cyan glow
    btnStroke.Thickness = 2
    btnStroke.Transparency = 0.7

    -- Shadow (menggunakan frame blur sederhana)
    local shadow = Instance.new("Frame", container)
    shadow.Size = UDim2.new(0, 56, 0, 88)
    shadow.Position = UDim2.new(0.5, -28, 0.5, -42)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.8
    shadow.ZIndex = 0
    shadow.Visible = true
    local shadowCorner = Instance.new("UICorner", shadow)
    shadowCorner.CornerRadius = UDim.new(0, 12)

    -- Screen di dalam tombol
    local screen = Instance.new("Frame", btn)
    screen.Size = UDim2.new(1, -8, 1, -30)
    screen.Position = UDim2.new(0, 4, 0, 20)
    screen.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    screen.ZIndex = 2
    local screenCorner = Instance.new("UICorner", screen)
    screenCorner.CornerRadius = UDim.new(0, 6)

    -- Gradient pada screen
    local screenGradient = Instance.new("UIGradient", screen)
    screenGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 10, 25)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 5))
    })
    screenGradient.Rotation = 90

    -- Dynamic Island
    local island = Instance.new("Frame", btn)
    island.Size = UDim2.new(0, 20, 0, 4)
    island.Position = UDim2.new(0.5, -10, 0, 7)
    island.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    island.ZIndex = 3
    local islandCorner = Instance.new("UICorner", island)
    islandCorner.CornerRadius = UDim.new(0, 3)

    -- Ikon telepon di dalam screen
    local phoneIconSymbol = Instance.new("TextLabel", screen)
    phoneIconSymbol.Size = UDim2.new(1, 0, 1, 0)
    phoneIconSymbol.BackgroundTransparency = 1
    phoneIconSymbol.Text = "📱"
    phoneIconSymbol.TextColor3 = Color3.new(1, 1, 1)
    phoneIconSymbol.Font = Enum.Font.GothamBold
    phoneIconSymbol.TextSize = 24
    phoneIconSymbol.ZIndex = 4

    -- ==================== DRAG SYSTEM (FIXED) ====================
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            clickMoved = false
            dragStart = input.Position
            iconStartPos = container.AbsolutePosition
            -- Shrink effect saat drag dimulai
            TweenService:Create(btn, TweenInfo.new(0.15), {Size = UDim2.new(0, 46, 0, 76)}):Play()
        end
    end)

    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
            -- Kembalikan ukuran
            TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Size = UDim2.new(0, 52, 0, 84)}):Play()
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not isDragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then
                clickMoved = true
            end
            if clickMoved then
                local newX = iconStartPos.X + delta.X
                local newY = iconStartPos.Y + delta.Y
                local cam = Services.Workspace.CurrentCamera
                if cam then
                    local vp = cam.ViewportSize
                    newX = math.clamp(newX, 5, vp.X - 65)
                    newY = math.clamp(newY, 5, vp.Y - 95)
                end
                container.Position = UDim2.new(0, newX, 0, newY)
            end
        end
    end)

    -- Hover effect (saat mouse masuk, glow lebih terang)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btnStroke, TweenInfo.new(0.3), {Transparency = 0.3, Thickness = 3}):Play()
        TweenService:Create(btn, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, 54, 0, 86)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btnStroke, TweenInfo.new(0.3), {Transparency = 0.7, Thickness = 2}):Play()
        TweenService:Create(btn, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, 52, 0, 84)}):Play()
    end)

    -- Klik (buka/tutup)
    btn.MouseButton1Click:Connect(function()
        if clickMoved then return end
        local phoneFrame = _G.Phone and _G.Phone.phone
        if phoneFrame and phoneFrame.Visible then
            if _G.closePhone then _G.closePhone() end
        else
            if _G.openPhone then _G.openPhone() end
        end
    end)

    phoneIcon = gui
    print("[FloatingIcon] Created! Click to toggle, drag to move.")
end

-- Init
task.spawn(function()
    task.wait(1)
    createFloatingIcon()
end)

-- Monitor
task.spawn(function()
    while true do
        task.wait(5)
        if not phoneIcon or not phoneIcon.Parent then
            print("[FloatingIcon] Recreating...")
            createFloatingIcon()
        end
    end
end)

print("[FloatingIcon] Module ready!")