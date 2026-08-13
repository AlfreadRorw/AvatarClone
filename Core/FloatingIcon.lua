-- Core/FloatingIcon.lua (FIXED)
local T = _G.T
local Helpers = _G.Helpers
local Services = _G.Services
local LocalPlayer = _G.LocalPlayer

local phoneIcon = nil
local mouseDown = false
local mouseMoved = false
local dragStart = nil
local iconStartPos = nil

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
    
    -- Tombol BESAR yang pasti keliatan
    local btn = Instance.new("TextButton", gui)
    btn.Size = UDim2.new(0, 55, 0, 85)
    btn.Position = UDim2.new(0, 15, 0.5, -42)
    btn.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    btn.Text = ""
    btn.AutoButtonColor = false
    Helpers.corner(btn, 12)
    Helpers.stroke(btn, Color3.fromRGB(60, 60, 65), 2, 0)
    
    -- Body HP di dalam tombol
    local phoneBody = Instance.new("Frame", btn)
    phoneBody.Size = UDim2.new(0, 45, 0, 75)
    phoneBody.Position = UDim2.new(0.5, -22, 0.5, -37)
    phoneBody.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    Helpers.corner(phoneBody, 10)
    Helpers.stroke(phoneBody, Color3.fromRGB(45, 45, 50), 1.5, 0)
    
    -- Screen
    local screen = Instance.new("Frame", phoneBody)
    screen.Size = UDim2.new(1, -6, 1, -28)
    screen.Position = UDim2.new(0, 3, 0, 18)
    screen.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Helpers.corner(screen, 6)
    
    -- Dynamic Island
    local island = Instance.new("Frame", phoneBody)
    island.Size = UDim2.new(0, 20, 0, 4)
    island.Position = UDim2.new(0.5, -10, 0, 6)
    island.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Helpers.corner(island, 2)
    
    -- Home bar
    local homeBar = Instance.new("Frame", phoneBody)
    homeBar.Size = UDim2.new(0, 18, 0, 2)
    homeBar.Position = UDim2.new(0.5, -9, 1, -4)
    homeBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    homeBar.BackgroundTransparency = 0.5
    Helpers.corner(homeBar, 1)
    
    -- Klik handler
    btn.MouseButton1Click:Connect(function()
        if mouseMoved then return end
        
        local phoneFrame = _G.Phone and _G.Phone.phone or nil
        
        if phoneFrame then
            if phoneFrame.Visible then
                if _G.closePhone then _G.closePhone() end
            else
                if _G.openPhone then _G.openPhone() end
            end
        else
            -- Fallback: cari phone langsung
            local foundPhone = nil
            pcall(function()
                local parent = game:GetService("CoreGui")
                local phoneGui = parent:FindFirstChild("PhoneGUI")
                if phoneGui then
                    foundPhone = phoneGui:FindFirstChild("Phone") or phoneGui:FindFirstChildOfClass("Frame")
                end
            end)
            
            if foundPhone then
                if foundPhone.Visible then
                    foundPhone.Visible = false
                else
                    foundPhone.Visible = true
                    foundPhone.Size = UDim2.new(0, 0, 0, 0)
                    Helpers.tween(foundPhone, {Size = UDim2.new(0, 320, 0, 560)}, 0.3)
                end
            else
                print("[FloatingIcon] Phone not found!")
            end
        end
    end)
    
    -- Drag
    btn.MouseButton1Down:Connect(function()
        mouseDown = true
        mouseMoved = false
        dragStart = Services.UserInputService:GetMouseLocation()
        iconStartPos = btn.Position
    end)
    
    btn.MouseButton1Up:Connect(function()
        mouseDown = false
    end)
    
    Services.UserInputService.InputChanged:Connect(function(input)
        if not mouseDown then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = Services.UserInputService:GetMouseLocation()
            if not dragStart then return end
            local delta = mousePos - dragStart
            if math.abs(delta.X) > 3 or math.abs(delta.Y) > 3 then mouseMoved = true end
            if mouseMoved then
                local newX = iconStartPos.X.Offset + delta.X
                local newY = iconStartPos.Y.Offset + delta.Y
                local cam = Services.Workspace.CurrentCamera
                if cam then
                    local screenSize = cam.ViewportSize
                    newX = math.clamp(newX, 0, screenSize.X - 55)
                    newY = math.clamp(newY, 0, screenSize.Y - 85)
                end
                btn.Position = UDim2.new(0, newX, 0, newY)
            end
        end
    end)
    
    phoneIcon = gui
    print("[FloatingIcon] Created successfully!")
end

-- Init dengan retry
task.spawn(function()
    task.wait(1)
    createFloatingIcon()
    
    -- Cek kalau belum muncul
    task.wait(2)
    if not phoneIcon or not phoneIcon.Parent then
        print("[FloatingIcon] Retry create...")
        createFloatingIcon()
    end
end)

-- Monitor
task.spawn(function()
    while true do
        task.wait(5)
        if not phoneIcon or not phoneIcon.Parent then
            print("[FloatingIcon] Icon missing! Recreating...")
            createFloatingIcon()
        end
    end
end)

-- Respawn handler
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if not phoneIcon or not phoneIcon.Parent then
        createFloatingIcon()
    end
end)

print("[FloatingIcon] Module loaded!")