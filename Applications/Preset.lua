local T           = _G.T
local Helpers     = _G.Helpers
local Storage     = _G.Storage
local Config      = _G.Config
local HttpService = game:GetService("HttpService")

local function openPresetApp()
    local appContent  = _G.appContent
    local state       = _G.PhoneState
    local getItems    = _G.getItems
    local fireHat     = _G.fireHat
    local refreshCurr = _G.refreshCurr
    local presets     = Storage.presets

    -- Save section
    local saveCard = Instance.new("Frame", appContent)
    saveCard.Size = UDim2.new(1,0,0,130)
    saveCard.BackgroundColor3 = Color3.fromRGB(255,255,255)
    saveCard.LayoutOrder = 0
    Helpers.corner(saveCard, 14)
    Helpers.stroke(saveCard, Color3.fromRGB(225,225,230), 1, 0.3)

    local saveTitle = Instance.new("TextLabel", saveCard)
    saveTitle.Size = UDim2.new(1,-24,0,22)
    saveTitle.Position = UDim2.new(0,12,0,10)
    saveTitle.BackgroundTransparency = 1
    saveTitle.Text = "Save Current Player as Preset"
    saveTitle.TextColor3 = T.Text
    saveTitle.Font = Enum.Font.GothamBlack
    saveTitle.TextSize = 13
    saveTitle.TextXAlignment = Enum.TextXAlignment.Left

    local nameInput = Instance.new("TextBox", saveCard)
    nameInput.Size = UDim2.new(1,-24,0,32)
    nameInput.Position = UDim2.new(0,12,0,40)
    nameInput.PlaceholderText = "Enter preset name..."
    nameInput.Text = state.selectedPlayer
        and (state.selectedPlayer.DisplayName.." - "..os.date("%d/%m %H:%M"))
        or ""
    nameInput.BackgroundColor3 = Color3.fromRGB(245,245,248)
    nameInput.TextColor3 = T.Text
    nameInput.Font = Enum.Font.Gotham
    nameInput.TextSize = 12
    nameInput.ClearTextOnFocus = false
    Helpers.corner(nameInput, 8)
    Helpers.stroke(nameInput, Color3.fromRGB(220,220,225), 1, 0.3)

    local saveBtn = Instance.new("TextButton", saveCard)
    saveBtn.Size = UDim2.new(1,-24,0,34)
    saveBtn.Position = UDim2.new(0,12,0,86)
    saveBtn.BackgroundColor3 = T.Accent
    saveBtn.Text = "Save Preset"
    saveBtn.TextColor3 = T.OnAccent
    saveBtn.Font = Enum.Font.GothamBlack
    saveBtn.TextSize = 12
    saveBtn.AutoButtonColor = false
    Helpers.corner(saveBtn, 8)
    Helpers.pressFX(saveBtn)

    saveBtn.MouseButton1Click:Connect(function()
        if not state.selectedPlayer then
            Helpers.showDynamicNotification("Select a player first!", T.Red)
            return
        end
        local items = getItems(state.selectedPlayer)
        if #items == 0 then
            Helpers.showDynamicNotification("Player has no items!", T.Red)
            return
        end
        local presetName = nameInput.Text
        if presetName == "" or presetName:match("^%s*$") then
            presetName = state.selectedPlayer.DisplayName.." - "..os.date("%d/%m %H:%M")
        end
        local ids = {}
        for _, it in ipairs(items) do table.insert(ids, it.Value) end
        table.insert(presets, {
            name        = presetName,
            ids         = ids,
            date        = os.date("%d/%m/%Y %H:%M"),
            favorite    = false,
            playerName  = state.selectedPlayer.DisplayName,
            playerId    = state.selectedPlayer.UserId,
            itemCount   = #ids,
        })
        Storage.persistPresets()
        Helpers.showDynamicNotification("Preset saved! ("..#ids.." items)", T.Green)
        nameInput.Text = ""
        refreshCurr()
    end)

    if #presets == 0 then
        local emptyFrame = Instance.new("Frame", appContent)
        emptyFrame.Size = UDim2.new(1,0,0,80)
        emptyFrame.BackgroundColor3 = Color3.fromRGB(248,248,250)
        emptyFrame.LayoutOrder = 1
        Helpers.corner(emptyFrame, 14)
        Helpers.stroke(emptyFrame, Color3.fromRGB(220,220,225), 1, 0.4)

        local emptyText = Instance.new("TextLabel", emptyFrame)
        emptyText.Size = UDim2.new(1,0,1,0)
        emptyText.BackgroundTransparency = 1
        emptyText.Text = "No presets saved yet"
        emptyText.TextColor3 = Color3.fromRGB(140,140,150)
        emptyText.Font = Enum.Font.GothamBold
        emptyText.TextSize = 13
        emptyText.TextXAlignment = Enum.TextXAlignment.Center
        return
    end

    -- Sort favorites first
    local sorted = {}
    for _, p in ipairs(presets) do table.insert(sorted, p) end
    table.sort(sorted, function(a, b)
        if a.favorite ~= b.favorite then return a.favorite end
        return (a.date or "") > (b.date or "")
    end)

    local counterFrame = Instance.new("Frame", appContent)
    counterFrame.Size = UDim2.new(1,0,0,22)
    counterFrame.BackgroundTransparency = 1
    counterFrame.LayoutOrder = 1

    local counterText = Instance.new("TextLabel", counterFrame)
    counterText.Size = UDim2.new(1,0,1,0)
    counterText.BackgroundTransparency = 1
    counterText.Text = #sorted.." preset"..(#sorted ~= 1 and "s" or "")
    counterText.TextColor3 = T.Text2
    counterText.Font = Enum.Font.GothamBold
    counterText.TextSize = 10
    counterText.TextXAlignment = Enum.TextXAlignment.Left

    for i, p in ipairs(sorted) do
        local row = Instance.new("Frame", appContent)
        row.Size = UDim2.new(1,0,0,108)
        row.BackgroundColor3 = Color3.fromRGB(255,255,255)
        row.LayoutOrder = i+1
        Helpers.corner(row, 12)
        Helpers.stroke(row,
            p.favorite and Color3.fromRGB(255,200,50) or Color3.fromRGB(225,225,230),
            p.favorite and 1.5 or 1,
            p.favorite and 0.2 or 0.3
        )

        local nameLbl = Instance.new("TextLabel", row)
        nameLbl.Size = UDim2.new(1,-24,0,22)
        nameLbl.Position = UDim2.new(0,12,0,8)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = p.name
        nameLbl.TextColor3 = T.Text
        nameLbl.Font = Enum.Font.GothamBlack
        nameLbl.TextSize = 13
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

        local infoLbl = Instance.new("TextLabel", row)
        infoLbl.Size = UDim2.new(1,-24,0,14)
        infoLbl.Position = UDim2.new(0,12,0,30)
        infoLbl.BackgroundTransparency = 1
        infoLbl.Text = (p.itemCount or #p.ids).." items | "..(p.date or "")
            ..(p.playerName and (" | "..p.playerName) or "")
        infoLbl.TextColor3 = T.Text2
        infoLbl.Font = Enum.Font.Gotham
        infoLbl.TextSize = 9
        infoLbl.TextXAlignment = Enum.TextXAlignment.Left
        infoLbl.TextTruncate = Enum.TextTruncate.AtEnd

        -- Row 1 buttons
        local btnRow1 = Instance.new("Frame", row)
        btnRow1.Size = UDim2.new(1,-24,0,26)
        btnRow1.Position = UDim2.new(0,12,0,50)
        btnRow1.BackgroundTransparency = 1

        -- Clone
        local cloneBtn = Instance.new("TextButton", btnRow1)
        cloneBtn.Size = UDim2.new(0,75,1,0)
        cloneBtn.BackgroundColor3 = T.Green
        cloneBtn.Text = "Clone"
        cloneBtn.TextColor3 = T.OnAccent
        cloneBtn.Font = Enum.Font.GothamBold
        cloneBtn.TextSize = 9
        cloneBtn.AutoButtonColor = false
        Helpers.corner(cloneBtn, 6)
        Helpers.pressFX(cloneBtn)
        cloneBtn.MouseButton1Click:Connect(function()
            if #p.ids == 0 then
                Helpers.showDynamicNotification("Preset has no items!", T.Red)
                return
            end
            cloneBtn.Text = "Cloning..."
            cloneBtn.BackgroundColor3 = T.Gold
            local batchSize = Config.CLONE_BATCH_SIZE
            local delayTime = Config.CLONE_DELAY
            local totalBatches = math.ceil(#p.ids / batchSize)
            local curBatch = 0
            local function nextBatch()
                curBatch = curBatch + 1
                if curBatch > totalBatches then
                    cloneBtn.Text = "Done!"
                    cloneBtn.BackgroundColor3 = T.Green
                    Helpers.showDynamicNotification("Clone complete! ("..#p.ids.." items)", T.Green)
                    task.wait(1.5)
                    cloneBtn.Text = "Clone"
                    return
                end
                local s = (curBatch-1)*batchSize+1
                local e = math.min(curBatch*batchSize, #p.ids)
                local b = {}
                for j = s, e do table.insert(b, p.ids[j]) end
                fireHat(b)
                cloneBtn.Text = "Clone "..curBatch.."/"..totalBatches
                task.delay(delayTime, nextBatch)
            end
            nextBatch()
        end)

        -- Wear All
        local wearBtn = Instance.new("TextButton", btnRow1)
        wearBtn.Size = UDim2.new(0,75,1,0)
        wearBtn.Position = UDim2.new(0,80,0,0)
        wearBtn.BackgroundColor3 = T.Accent
        wearBtn.Text = "Wear All"
        wearBtn.TextColor3 = T.OnAccent
        wearBtn.Font = Enum.Font.GothamBold
        wearBtn.TextSize = 9
        wearBtn.AutoButtonColor = false
        Helpers.corner(wearBtn, 6)
        Helpers.pressFX(wearBtn)
        wearBtn.MouseButton1Click:Connect(function()
            if #p.ids == 0 then
                Helpers.showDynamicNotification("Preset has no items!", T.Red)
                return
            end
            fireHat(p.ids)
            Helpers.showDynamicNotification("Wearing "..#p.ids.." items!", T.Green)
        end)

        -- Row 2 buttons
        local btnRow2 = Instance.new("Frame", row)
        btnRow2.Size = UDim2.new(1,-24,0,24)
        btnRow2.Position = UDim2.new(0,12,0,80)
        btnRow2.BackgroundTransparency = 1

        -- Fav
        local favBtn = Instance.new("TextButton", btnRow2)
        favBtn.Size = UDim2.new(0,50,1,0)
        favBtn.BackgroundColor3 = p.favorite and T.Gold or Color3.fromRGB(245,245,248)
        favBtn.Text = p.favorite and "Unfav" or "Fav"
        favBtn.TextColor3 = p.favorite and T.OnAccent or T.Text2
        favBtn.Font = Enum.Font.GothamBold
        favBtn.TextSize = 8
        favBtn.AutoButtonColor = false
        Helpers.corner(favBtn, 5)
        Helpers.stroke(favBtn, T.Border, 1, 0.3)
        Helpers.pressFX(favBtn)
        favBtn.MouseButton1Click:Connect(function()
            p.favorite = not p.favorite
            Storage.persistPresets()
            refreshCurr()
        end)

        -- Rename
        local editBtn = Instance.new("TextButton", btnRow2)
        editBtn.Size = UDim2.new(0,55,1,0)
        editBtn.Position = UDim2.new(0,55,0,0)
        editBtn.BackgroundColor3 = Color3.fromRGB(240,240,245)
        editBtn.Text = "Rename"
        editBtn.TextColor3 = T.Text
        editBtn.Font = Enum.Font.GothamBold
        editBtn.TextSize = 8
        editBtn.AutoButtonColor = false
        Helpers.corner(editBtn, 5)
        Helpers.stroke(editBtn, T.Border, 1, 0.3)
        Helpers.pressFX(editBtn)
        editBtn.MouseButton1Click:Connect(function()
            nameLbl.Visible = false
            local editInput = Instance.new("TextBox", row)
            editInput.Size = UDim2.new(1,-24,0,22)
            editInput.Position = UDim2.new(0,12,0,8)
            editInput.Text = p.name
            editInput.BackgroundColor3 = Color3.fromRGB(245,245,248)
            editInput.TextColor3 = T.Text
            editInput.Font = Enum.Font.GothamBold
            editInput.TextSize = 12
            editInput.ZIndex = 10
            Helpers.corner(editInput, 6)
            Helpers.stroke(editInput, T.Accent, 1.5, 0)
            editInput.FocusLost:Connect(function()
                local newName = editInput.Text
                if newName ~= "" and newName:match("%S") then
                    p.name = newName
                    Storage.persistPresets()
                    Helpers.showDynamicNotification("Preset renamed!", T.Green)
                end
                editInput:Destroy()
                nameLbl.Visible = true
                nameLbl.Text = p.name
            end)
            editInput:CaptureFocus()
        end)

        -- Copy IDs
        local copyBtn = Instance.new("TextButton", btnRow2)
        copyBtn.Size = UDim2.new(0,55,1,0)
        copyBtn.Position = UDim2.new(0,115,0,0)
        copyBtn.BackgroundColor3 = Color3.fromRGB(240,240,245)
        copyBtn.Text = "Copy IDs"
        copyBtn.TextColor3 = T.Text
        copyBtn.Font = Enum.Font.GothamBold
        copyBtn.TextSize = 8
        copyBtn.AutoButtonColor = false
        Helpers.corner(copyBtn, 5)
        Helpers.stroke(copyBtn, T.Border, 1, 0.3)
        Helpers.pressFX(copyBtn)
        copyBtn.MouseButton1Click:Connect(function()
            Helpers.copyToClipboard(table.concat(p.ids, " "))
            Helpers.showDynamicNotification("Copied "..#p.ids.." IDs!", T.Green)
        end)

        -- Delete
        local delBtn = Instance.new("TextButton", btnRow2)
        delBtn.Size = UDim2.new(0,50,1,0)
        delBtn.Position = UDim2.new(0,175,0,0)
        delBtn.BackgroundColor3 = Color3.fromRGB(255,230,230)
        delBtn.Text = "Delete"
        delBtn.TextColor3 = T.Red
        delBtn.Font = Enum.Font.GothamBold
        delBtn.TextSize = 8
        delBtn.AutoButtonColor = false
        Helpers.corner(delBtn, 5)
        Helpers.stroke(delBtn, Color3.fromRGB(255,200,200), 1, 0.3)
        Helpers.pressFX(delBtn)
        delBtn.MouseButton1Click:Connect(function()
            delBtn.Text = "Sure?"
            task.wait(1)
            if delBtn.Text == "Sure?" then
                local idx = table.find(presets, p)
                if idx then table.remove(presets, idx) end
                Storage.persistPresets()
                Helpers.showDynamicNotification("Preset deleted!", T.Red)
                refreshCurr()
            end
        end)
    end
end

_G.openPresetApp = openPresetApp
return openPresetApp