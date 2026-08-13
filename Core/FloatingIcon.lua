-- Core/FloatingIcon.lua (FIXED V2)
local Services = _G.Services
local LocalPlayer = _G.LocalPlayer
local UserInputService = Services.UserInputService

local phoneIcon = nil
local isDragging = false
local dragStart = nil
local iconStartPos = nil
local clickMoved = false

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
    local container = Instance.new("Frame", gui)
    container.Size = UDim2.new(0, 55, 0, 85)
    container.Position = UDim2.new(0, 15, 0.5, -42)
    container.BackgroundTransparency = 1
    
    -- Tombol HP
    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(0, 50, 0, 80)
    btn.Position = UDim2.new(0.5, -25, 0.5, -40)
    btn.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    btn.Text = ""
    btn.AutoButtonColor = false
    
    local phoneBodyCorner = Instance.new("UICorner", btn)
    phoneBodyCorner.CornerRadius = UDim.new(0, 10)
    
    local phoneBodyStroke = Instance.new("UIStroke", btn)
    phoneBodyStroke.Color = Color3.fromRGB(60, 60, 65)
    phoneBodyStroke.Thickness = 2
    
    -- Screen di dalam tombol
    local screen = Instance.new("Frame", btn)
    screen.Size = UDim2.new(1, -4, 1, -26)
    screen.Position = UDim2.new(0, 2, 0, 16)
    screen.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    
    local screenCorner = Instance.new("UICorner", screen)
    screenCorner.CornerRadius = UDim.new(0, 5)
    
    -- Dynamic Island
    local island = Instance.new("Frame", btn)
    island.Size = UDim2.new(0, 18, 0, 3)
    island.Position = UDim2.new(0.5, -9, 0, 5)
    island.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    
    local islandCorner = Instance.new("UICorner", island)
    islandCorner.CornerRadius = UDim.new(0, 2)
    
    -- ==================== DRAG SYSTEM (FIXED) ====================
    -- Posisi awal container pakai scale (UDim2.new(0, 15, 0.5, -42)), tapi kalau
    -- kita cuma baca komponen .Offset dan abaikan .Scale, hasil hitungnya salah
    -- begitu drag dimulai (icon "melompat"). Fix: konversi ke posisi pixel absolut
    -- dulu pakai AbsolutePosition, baru drag dihitung dari situ.
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            clickMoved = false
            dragStart = input.Position
            -- AbsolutePosition = posisi pixel nyata di layar saat ini, sudah
            -- memperhitungkan scale + offset sekaligus. Ini yang benar dipakai
            -- sebagai titik awal, bukan container.Position mentah.
            iconStartPos = container.AbsolutePosition
        end
    end)
    
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
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
                    newX = math.clamp(newX, 5, vp.X - 60)
                    newY = math.clamp(newY, 5, vp.Y - 90)
                end
                
                -- Selalu tulis ulang dengan scale 0 secara konsisten, supaya drag
                -- berikutnya (yang juga baca AbsolutePosition) tetap akurat.
                container.Position = UDim2.new(0, newX, 0, newY)
            end
        end
    end)
    
    -- ==================== KLIK (BUKA/TUTUP) ====================
    -- Pakai referensi langsung ke _G.Phone.phone (di-export dari Core/Phone.lua)
    -- alih-alih menebak child mana yang "phone" lewat GetChildren(). Jauh lebih
    -- aman karena _G.openPhone()/_G.closePhone() sudah tahu persis cara animasi
    -- buka/tutup yang benar (termasuk hormati status lock screen).
    btn.MouseButton1Click:Connect(function()
        if clickMoved then return end -- Abaikan kalau ini akhir dari drag, bukan tap

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