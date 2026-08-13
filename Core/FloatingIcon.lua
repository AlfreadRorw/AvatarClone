-- ================================================
-- FLOATING ICON - Fully Built (No Emoji)
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

    -- Container
    container = Instance.new("Frame", gui)
    container.Size = UDim2.new(0, 65, 0, 95)
    container.Position = UDim2.new(0, 15, 0.5, -47)
    container.BackgroundTransparency = 1
    container.ZIndex = 10

    -- Shadow
    local shadow = Instance.new("Frame", container)
    shadow.Size = UDim2.new(0, 56, 0, 88)
    shadow.Position = UDim2.new(0.5, -25, 0.5, -40)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.75
    shadow.ZIndex = 1
    Helpers.corner(shadow, 14)

    -- Phone Body
    btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(0, 52, 0, 84)
    btn.Position = UDim2.new(0.5, -26, 0.5, -42)
    btn.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.ZIndex = 2

    -- Gradient untuk body
    local bodyGradient = Instance.new("UIGradient", btn)
    bodyGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 40)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(20, 20, 30)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 15))
    })
    bodyGradient.Rotation = 45

    -- Corner
    Helpers.corner(btn, 14)

    -- Stroke dengan glow
    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Color = Color3.fromRGB(0, 200, 255)
    btnStroke.Thickness = 2
    btnStroke.Transparency = 0.6
    btnStroke.ZIndex = 3

    -- Screen (layar)
    local screen = Instance.new("Frame", btn)
    screen.Size = UDim2.new(1, -8, 1, -30)
    screen.Position = UDim2.new(0, 4, 0, 20)
    screen.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    screen.ZIndex = 4
    Helpers.corner(screen, 6)

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
    Helpers.corner(island, 3)

    -- Icon telepon (build dari Frame)
    local phoneIconContainer = Instance.new("Frame", screen)
    phoneIconContainer.Size = UDim2.new(0, 20, 0, 34)
    phoneIconContainer.Position = UDim2.new(0.5, -10, 0.5, -17)
    phoneIconContainer.BackgroundTransparency = 1
    phoneIconContainer.ZIndex = 6
    phoneIconContainer.Rotation = 45

    -- Body telepon
    local phoneBody = Instance.new("Frame", phoneIconContainer)
    phoneBody.Size = UDim2.new(0, 10, 0, 18)
    phoneBody.Position = UDim2.new(0.5, -5, 0.5, -9)
    phoneBody.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    phoneBody.ZIndex = 7
    Helpers.corner(phoneBody, 3)

    -- Speaker (titik di atas)
    local speaker = Instance.new("Frame", phoneBody)
    speaker.Size = UDim2.new(0, 4, 0, 2)
    speaker.Position = UDim2.new(0.5, -2, 0, 2)
    speaker.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    speaker.ZIndex = 8
    Helpers.corner(speaker, 1)

    -- Home button (titik di bawah)
    local homeBtn = Instance.new("Frame", phoneBody)
    homeBtn.Size = UDim2.new(0, 3, 0, 3)
    homeBtn.Position = UDim2.new(0.5, -1.5, 1, -5)
    homeBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    homeBtn.ZIndex = 8
    Helpers.corner(homeBtn, 100)

    -- LED indicator
    local ledDot = Instance.new("Frame", btn)
    ledDot.Size = UDim2.new(0, 6, 0, 6)
    ledDot.Position = UDim2.new(0.5, -3, 0, 73)
    ledDot.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    ledDot.ZIndex = 7
    Helpers.corner(ledDot, 3)

    -- ==================== DRAG SYSTEM ====================
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            clickMoved = false
            dragStart = input.Position
            iconStartPos = container.AbsolutePosition
            
            TweenService:Create(btn, TweenInfo.new(0.15), {
                Size = UDim2.new(0, 48, 0, 78)
            }):Play()
        end
    end)

    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
            
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
        TweenService:Create(btnStroke, TweenInfo.new(0.3), {
            Transparency = 0.3,
            Thickness = 3,
            Color = Color3.fromRGB(0, 255, 255)
        }):Play()
        
        TweenService:Create(btn, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 55, 0, 88)
        }):Play()
        
        TweenService:Create(ledDot, TweenInfo.new(0.3), {
            BackgroundColor3 = Color3.fromRGB(0, 255, 200)
        }):Play()
    end)

    btn.MouseLeave:Connect(function()
        isHovering = false
        TweenService:Create(btnStroke, TweenInfo.new(0.3), {
            Transparency = 0.6,
            Thickness = 2,
            Color = Color3.fromRGB(0, 200, 255)
        }):Play()
        
        if not isDragging then
            TweenService:Create(btn, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 52, 0, 84)
            }):Play()
        end
        
        TweenService:Create(ledDot, TweenInfo.new(0.3), {
            BackgroundColor3 = Color3.fromRGB(0, 255, 100)
        }):Play()
    end)

    -- ==================== CLICK HANDLER ====================
    btn.MouseButton1Click:Connect(function()
        if clickMoved then return end
        
        local phoneFrame = _G.Phone and _G.Phone.phone
        
        if phoneFrame and phoneFrame.Visible then
            if _G.closePhone then _G.closePhone() end
        else
            if _G.openPhone then _G.openPhone() end
        end
        
        -- Bounce animation
        TweenService:Create(btn, TweenInfo.new(0.1), {
            Size = UDim2.new(0, 50, 0, 82)
        }):Play()
        task.wait(0.1)
        TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
            Size = isHovering and UDim2.new(0, 55, 0, 88) or UDim2.new(0, 52, 0, 84)
        }):Play()
    end)

    phoneIcon = gui
    print("[FloatingIcon] Created!")
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

print("[FloatingIcon] Module ready!")