-- ================= PLAYERS APP (COMPATIBLE) =================
local function openPlayersApp()
    local searchBox = Instance.new("Frame", appContent)
    searchBox.Size = UDim2.new(1, 0, 0, 36)
    searchBox.BackgroundColor3 = T.Card2
    searchBox.LayoutOrder = 0
    corner(searchBox, 9)
    stroke(searchBox, T.Border, 1, 0.3)

    local searchInput = Instance.new("TextBox", searchBox)
    searchInput.Size = UDim2.new(1, -16, 1, 0)
    searchInput.Position = UDim2.new(0, 8, 0, 0)
    searchInput.BackgroundTransparency = 1
    searchInput.PlaceholderText = "Search player..."
    searchInput.Text = ""
    searchInput.TextColor3 = T.Text
    searchInput.Font = Enum.Font.Gotham
    searchInput.TextSize = 13
    searchInput.ClearTextOnFocus = false

    local listHolder = Instance.new("Frame", appContent)
    listHolder.Size = UDim2.new(1, 0, 0, 0)
    listHolder.AutomaticSize = Enum.AutomaticSize.Y
    listHolder.BackgroundTransparency = 1
    listHolder.LayoutOrder = 1

    local listLayout = Instance.new("UIListLayout", listHolder)
    listLayout.Padding = UDim.new(0, 8)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local function renderList(filter)
        for _, c in ipairs(listHolder:GetChildren()) do
            if not c:IsA("UIListLayout") then c:Destroy() end
        end
        filter = (filter or ""):lower()
        local list = Players:GetPlayers()

        table.sort(list, function(a, b)
            if a == LocalPlayer then return true end
            if b == LocalPlayer then return false end
            local af = favSet[tostring(a.UserId)] and 1 or 0
            local bf = favSet[tostring(b.UserId)] and 1 or 0
            if af ~= bf then return af > bf end
            return a.DisplayName < b.DisplayName
        end)

        for i, p in ipairs(list) do
            if filter == "" or p.Name:lower():find(filter, 1, true) or p.DisplayName:lower():find(filter, 1, true) then
                local isMe = p == LocalPlayer
                local isFav = favSet[tostring(p.UserId)] == true
                local isSel = selectedPlayer == p

                local row = Instance.new("Frame", listHolder)
                row.Size = UDim2.new(1, 0, 0, 60)
                row.BackgroundColor3 = isSel and Color3.fromRGB(220, 220, 220) or T.Card2
                row.LayoutOrder = i
                corner(row, 10)
                stroke(row, isSel and T.Accent or T.Border, isSel and 2 or 1, isSel and 0 or 0.3)

                local av = Instance.new("ImageLabel", row)
                av.Size = UDim2.new(0, 44, 0, 44)
                av.Position = UDim2.new(0, 8, 0.5, -22)
                av.BackgroundColor3 = T.BG
                av.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. p.UserId .. "&width=100&height=100&format=png"
                corner(av, 100)

                local nameLbl = Instance.new("TextLabel", row)
                nameLbl.Size = UDim2.new(1, -170, 0, 20)
                nameLbl.Position = UDim2.new(0, 60, 0, 10)
                nameLbl.BackgroundTransparency = 1
                nameLbl.Text = (isMe and "(You) " or "") .. p.DisplayName
                nameLbl.TextColor3 = isMe and T.Accent or T.Text
                nameLbl.Font = Enum.Font.GothamBold
                nameLbl.TextSize = 13
                nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

                local userLbl = Instance.new("TextLabel", row)
                userLbl.Size = UDim2.new(1, -170, 0, 16)
                userLbl.Position = UDim2.new(0, 60, 0, 32)
                userLbl.BackgroundTransparency = 1
                userLbl.Text = "@" .. p.Name
                userLbl.TextColor3 = T.Text2
                userLbl.Font = Enum.Font.Gotham
                userLbl.TextSize = 10
                userLbl.TextXAlignment = Enum.TextXAlignment.Left

                if not isMe then
                    local starBtn = Instance.new("TextButton", row)
                    starBtn.Size = UDim2.new(0, 34, 0, 30)
                    starBtn.Position = UDim2.new(1, -108, 0.5, -15)
                    starBtn.BackgroundColor3 = isFav and T.Gold or T.Card
                    starBtn.Text = "Fav"
                    starBtn.TextColor3 = isFav and T.OnAccent or T.Text2
                    starBtn.Font = Enum.Font.GothamBold
                    starBtn.TextSize = 10
                    starBtn.AutoButtonColor = false
                    corner(starBtn, 7)
                    stroke(starBtn, T.Border, 1, 0.3)
                    pressFX(starBtn)
                    starBtn.MouseButton1Click:Connect(function()
                        local k = tostring(p.UserId)
                        if favSet[k] then
                            favSet[k] = nil
                            showDynamicNotification("Removed from fav", T.Text2)
                        else
                            favSet[k] = true
                            showDynamicNotification("Added to fav", T.Gold)
                        end
                        persistFav()
                        renderList(searchInput.Text)
                    end)
                end

                local selBtn = Instance.new("TextButton", row)
                selBtn.Size = UDim2.new(0, 66, 0, 30)
                selBtn.Position = UDim2.new(1, -72, 0.5, -15)
                selBtn.BackgroundColor3 = T.Accent
                selBtn.Text = isSel and "Selected" or "Select"
                selBtn.TextColor3 = T.OnAccent
                selBtn.Font = Enum.Font.GothamBold
                selBtn.TextSize = 10
                selBtn.AutoButtonColor = false
                corner(selBtn, 7)
                pressFX(selBtn)
                selBtn.MouseButton1Click:Connect(function()
                    selectedPlayer = p
                    showDynamicNotification("Target: " .. p.DisplayName, T.Green)
                    renderList(searchInput.Text)
                end)
            end
        end
    end

    renderList("")
    searchInput:GetPropertyChangedSignal("Text"):Connect(function()
        renderList(searchInput.Text)
    end)
end