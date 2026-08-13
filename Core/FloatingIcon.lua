-- ================================================
-- FLOATING ICON - Upgraded Version
-- ================================================

local Services = _G.Services
local LocalPlayer = _G.LocalPlayer
local UserInputService = Services.UserInputService
local TweenService = Services.TweenService

local phoneIcon = nil
local isDragging = false
local dragStart = nil
local iconStartPos = nil
local clickMoved = false
local btn, container

-- Variabel untuk animasi
local isHovering = false

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

    -- Container utama
    container = Instance.new("Frame", gui)
    container.Size = UDim2.new(0, 65, 0, 95)
    container.Position = UDim2.new(0, 15, 0.5, -47)
    container.BackgroundTransparency = 1
    container.ZIndex = 10

    -- Shadow (bayangan)
    local shadow = Instance.new("Frame", container)
    shadow.Size = UDim2.new(0, 56, 0, 88)
    shadow.Position = UDim2.new(0.5, -25, 0.5, -40)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.7
    shadow.ZIndex = 1
    local shadowCorner = Instance.new("UICorner", shadow)
    shadowCorner.CornerRadius = UDim.new(0, 14)

    -- Tombol utama (phone body)
    btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(0, 52, 0, 84)
    btn.Position = UDim2.new(0.5, -26, 0.5, -42)
    btn.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.ZIndex = 2

    -- Gradient untuk body
    local btnGradient = Instance.new("UIGradient", btn)
    btnGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 40)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(20, 20, 30)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 15))
    })
    btnGradient.Rotation = 45

    -- Corner untuk body
    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 14)

    -- Stroke dengan glow effect
    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Color = Color3.fromRGB(0, 200, 255)
    btnStroke.Thickness = 2
    btnStroke.Transparency = 0.6
    btnStroke.ZIndex = 3

    -- Screen (layar dalam)
    local screen = Instance.new("Frame", btn)
    screen.Size = UDim2.new(1, -8, 1, -30)
    screen.Position = UDim2.new(0, 4, 0, 20)
    screen.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    screen.ZIndex = 4
    
    local screenCorner = Instance.new("UICorner", screen)
    screenCorner.CornerRadius = UDim.new(0, 6)

    -- Gradient untuk screen
    local screenGradient = Instance.new("UIGradient", screen)
    screenGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 15, 30)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 5))
    })
    screenGradient.Rotation = 90

    -- Dynamic Island (notch)
    local island = Instance.new("Frame", btn)
    island.Size = UDim2.new(0, 22, 0, 5)
    island.Position = UDim2.new(0.5, -11, 0, 8)
    island.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    island.ZIndex = 5
    local islandCorner = Instance.new("UICorner", island)
    islandCorner.CornerRadius = UDim.new(0, 3)

    -- Ikon telepon
    local phoneIconSymbol = Instance.new("TextLabel", screen)
    phoneIconSymbol.Size = UDim2.new(1, 0, 1, 0)
    phoneIconSymbol.BackgroundTransparency = 1
    phoneIconSymbol.Text = "📱"
    phoneIconSymbol.TextColor3 = Color3.new(1, 1, 1)
    phoneIconSymbol.Font = Enum.Font.GothamBold
    phoneIconSymbol.TextSize = 24
    phoneIconSymbol.ZIndex = 6

    -- Indicator LED (titik hijau)
    local ledDot = Instance.new("Frame", btn)
    ledDot.Size = UDim2.new(0, 6, 0, 6)
    ledDot.Position = UDim2.new(0.5, -3, 0, 73)
    ledDot.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    ledDot.ZIndex = 7
    local ledCorner = Instance.new("UICorner", ledDot)
    ledCorner.CornerRadius = UDim.new(0, 3)

    -- ==================== DRAG SYSTEM ====================
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            clickMoved = false
            dragStart = input.Position
            iconStartPos = container.AbsolutePosition
            
            -- Shrink effect saat drag dimulai
            TweenService:Create(btn, TweenInfo.new(0.15), {
                Size = UDim2.new(0, 48, 0, 78)
            }):Play()
        end
    end)

    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
            
            -- Kembalikan ukuran
            local targetSize = isHovering and UDim2.new(0, 55, 0, 88) or UDim2.new(0, 52, 0, 84)
            TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
                Size = targetSize
            }):Play()
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
                    newX = math.clamp(newX, 5, vp.X - 70)
                    newY = math.clamp(newY, 5, vp.Y - 100)
                end
                
                container.Position = UDim2.new(0, newX, 0, newY)
            end
        end
    end)

    -- ==================== HOVER EFFECTS ====================
    btn.MouseEnter:Connect(function()
        isHovering = true
        -- Glow lebih terang
        TweenService:Create(btnStroke, TweenInfo.new(0.3), {
            Transparency = 0.3,
            Thickness = 3,
            Color = Color3.fromRGB(0, 255, 255)
        }):Play()
        
        -- Sedikit membesar
        TweenService:Create(btn, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 55, 0, 88)
        }):Play()
        
        -- LED berkedip
        TweenService:Create(ledDot, TweenInfo.new(0.3), {
            BackgroundColor3 = Color3.fromRGB(0, 255, 200)
        }):Play()
    end)

    btn.MouseLeave:Connect(function()
        isHovering = false
        -- Kembalikan glow
        TweenService:Create(btnStroke, TweenInfo.new(0.3), {
            Transparency = 0.6,
            Thickness = 2,
            Color = Color3.fromRGB(0, 200, 255)
        }):Play()
        
        -- Kembalikan ukuran
        if not isDragging then
            TweenService:Create(btn, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 52, 0, 84)
            }):Play()
        end
        
        -- LED kembali
        TweenService:Create(ledDot, TweenInfo.new(0.3), {
            BackgroundColor3 = Color3.fromRGB(0, 255, 100)
        }):Play()
    end)

    -- ==================== CLICK HANDLER ====================
    btn.MouseButton1Click:Connect(function()
        if clickMoved then return end
        
        local phoneFrame = _G.Phone and _G.Phone.phone
        
        if phoneFrame and phoneFrame.Visible then
            -- Tutup phone
            if _G.closePhone then 
                _G.closePhone() 
            end
        else
            -- Buka phone
            if _G.openPhone then 
                _G.openPhone() 
            end
            
            -- Langsung tampilkan key entry jika masih locked
            task.wait(0.6)
            if _G.PhoneState and _G.PhoneState.isLocked and _G.showPass then
                _G.showPass()
            end
        end
        
        -- Animasi bounce saat diklik
        TweenService:Create(btn, TweenInfo.new(0.1), {
            Size = UDim2.new(0, 50, 0, 82)
        }):Play()
        task.wait(0.1)
        TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
            Size = isHovering and UDim2.new(0, 55, 0, 88) or UDim2.new(0, 52, 0, 84)
        }):Play()
    end)

    phoneIcon = gui
    print("[FloatingIcon] Created! Click to toggle, drag to move.")
end

-- ==================== INIT ====================
task.spawn(function()
    task.wait(1)
    createFloatingIcon()
end)

-- ==================== MONITOR ====================
task.spawn(function()
    while true do
        task.wait(5)
        if not phoneIcon or not phoneIcon.Parent then
            print("[FloatingIcon] Recreating...")
            createFloatingIcon()
        end
    end
end)

-- ==================== AUTO-LOCK MONITOR ====================
task.spawn(function()
    while true do
        task.wait(1)
        local appSettings = _G.Storage and _G.Storage.appSettings
        if appSettings and appSettings.autoLockSeconds and appSettings.autoLockSeconds > 0 then
            if _G.PhoneState and not _G.PhoneState.isLocked then
                -- Check if phone is open
                local phoneFrame = _G.Phone and _G.Phone.phone
                if phoneFrame and phoneFrame.Visible then
                    -- Reset timer if phone is open
                    _G.lastActivity = os.time()
                elseif _G.lastActivity and (os.time() - _G.lastActivity) > appSettings.autoLockSeconds then
                    -- Auto lock
                    _G.PhoneState.isLocked = true
                    _G.lastActivity = nil
                    print("[FloatingIcon] Phone auto-locked")
                end
            end
        end
    end
end)

print("[FloatingIcon] Module ready!")