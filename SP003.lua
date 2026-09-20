--// Universal LuaRBX - Thai Edition (AIO: V.Max Final - Ultimate UI Nuke & Pet Farm)
--// Keybind เปิด/ปิดเมนู: J

-- ==========================================
-- 📍 ตั้งค่าพิกัดเริ่มต้น และ ตัวแปรหลัก
-- ==========================================
_G.FoodPlaceArgs = {
    [1] = -142.93292236328125, [2] = 3.375349760055542, [3] = 10.6432466506958,
    [4] = 1, [5] = 0, [6] = 0, [7] = 0, [8] = 1, [9] = 0, [10] = 0, [11] = 0, [12] = 1
}

_G.SpinPlaceArgs = nil 
_G.SellPlaceArgs = nil 
_G.HomePlaceArgs = nil 
_G.BotActionLock = false 
_G.IgnoreMyFood = true 
_G.AntiAFK = false
_G.IsBagFull_ServerSignal = false 

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local lp = Players.LocalPlayer
local pg = lp:WaitForChild("PlayerGui")

if pg:FindFirstChild("UniversalLuaRBX") then pg.UniversalLuaRBX:Destroy() end

local CURRENT = {Accent = Color3.fromRGB(85, 255, 127), Bg = Color3.fromRGB(25, 25, 25)}

-- ==========================================
-- 📡 ระบบดักฟัง Server
-- ==========================================
task.spawn(function()
    local bagRemotes = ReplicatedStorage:WaitForChild("BagRemotes", 5)
    if bagRemotes then
        local feedback = bagRemotes:WaitForChild("Feedback", 5)
        if feedback then
            feedback.OnClientEvent:Connect(function(msg)
                if msg == "FULL" then _G.IsBagFull_ServerSignal = true end
            end)
        end
    end
    
    local recycleEvent = ReplicatedStorage:WaitForChild("BGLRecycleEvent", 5)
    if recycleEvent then
        recycleEvent.OnClientEvent:Connect(function(action, data)
            if action == "Error" then
                local txt = tostring(data)
                if txt:find("เต็ม") or txt:find("สุ่มไม่ได้") or txt:find("เคลียร์") then
                    _G.IsBagFull_ServerSignal = true
                end
            end
        end)
    end
end)

local function getLock()
    local t = tick()
    while _G.BotActionLock and (tick() - t < 3) do task.wait(0.05) end
    _G.BotActionLock = true
end
local function releaseLock() _G.BotActionLock = false end

local function tween(obj, props, time)
    local t = TweenService:Create(obj, TweenInfo.new(time or 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
    t:Play() return t
end

local function mk(class, props)
    local inst = Instance.new(class)
    for k,v in pairs(props or {}) do inst[k] = v end
    return inst
end

local function playClick()
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://6351629524"
    s.Volume = 0.5
    s.Parent = SoundService
    s:Play()
    s.Ended:Connect(function() s:Destroy() end)
end

-- ==========================================
-- 🖥️ ระบบ UI
-- ==========================================
local gui = mk("ScreenGui", { Name = "UniversalLuaRBX", ResetOnSpawn = false, IgnoreGuiInset = true, Parent = pg })

local notifyContainer = mk("Frame", {Name = "Notify", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -20, 1, -50), Size = UDim2.new(0, 250, 0, 400), BackgroundTransparency = 1, Parent = gui, ZIndex=10})
mk("UIListLayout", {Parent=notifyContainer, VerticalAlignment=Enum.VerticalAlignment.Bottom, Padding=UDim.new(0,10)})

local function sendNotify(title, msg)
    local f = mk("Frame", {BackgroundColor3 = Color3.fromRGB(20,20,20), Size = UDim2.new(1,0,0,0), ClipsDescendants = true, Parent = notifyContainer})
    mk("UICorner", {Parent=f, CornerRadius=UDim.new(0,8)})
    mk("UIStroke", {Parent=f, Color=CURRENT.Accent, Thickness=1, Transparency=0.5})
    mk("TextLabel", {Text=title, Font=Enum.Font.GothamBold, TextSize=13, TextColor3=CURRENT.Accent, BackgroundTransparency=1, Position=UDim2.new(0,12,0,8), Size=UDim2.new(1,-24,0,16), TextXAlignment=Enum.TextXAlignment.Left, Parent=f})
    mk("TextLabel", {Text=msg, Font=Enum.Font.Gotham, TextSize=12, TextColor3=Color3.fromRGB(220,220,220), BackgroundTransparency=1, Position=UDim2.new(0,12,0,24), Size=UDim2.new(1,-24,0,20), TextXAlignment=Enum.TextXAlignment.Left, Parent=f})
    tween(f, {Size = UDim2.new(1,0,0,55)}, 0.3)
    task.delay(3, function() if f then local out = tween(f, {Size = UDim2.new(1,0,0,0), BackgroundTransparency=1}, 0.3) out.Completed:Connect(function() f:Destroy() end) end end)
end

local window = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(920, 480), BackgroundColor3 = CURRENT.Bg, BackgroundTransparency = 0.02, Active = true, ClipsDescendants = true, Parent = gui })
mk("UICorner", {Parent=window, CornerRadius=UDim.new(0,10)})
mk("UIStroke", {Parent=window, Color=Color3.fromRGB(65,65,65), Thickness=1, Transparency=0.4})

local top = mk("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), Parent = window})
mk("TextLabel", {Text = "AIO Farm Hub - V.Max Final (Ultra Clean)", Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = Color3.fromRGB(240,240,240), BackgroundTransparency = 1, Position = UDim2.new(0, 15, 0, 0), Size = UDim2.new(0, 400, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = top})
local minBtn = mk("TextButton", {Text = "-", Font=Enum.Font.GothamBold, TextSize=22, TextColor3=Color3.fromRGB(150,150,150), BackgroundTransparency=1, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-12,0.5,0), Size=UDim2.fromOffset(30,30), Parent=top})
mk("Frame", {BackgroundColor3 = Color3.fromRGB(65,65,65), BorderSizePixel=0, Position=UDim2.new(0,0,0,40), Size=UDim2.new(1,0,0,1), Parent=window})

local dragging, dragStart, startPos
window.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging=true dragStart=i.Position startPos=window.Position end end)
UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d=i.Position-dragStart window.Position=UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging=false end end)
UserInputService.InputBegan:Connect(function(i, gp) if not gp and i.KeyCode == Enum.KeyCode.J then window.Visible = not window.Visible end end)

minBtn.MouseButton1Click:Connect(function()
    playClick()
    if window.Size.Y.Offset > 40 then tween(window, {Size = UDim2.fromOffset(920, 40)}, 0.3) minBtn.Text = "+"
    else tween(window, {Size = UDim2.fromOffset(920, 480)}, 0.3) minBtn.Text = "-" end
end)

local content = mk("Frame", {BackgroundTransparency = 1, Position=UDim2.new(0,0,0,41), Size=UDim2.new(1,0,1,-41), Parent=window})
mk("UIPadding", {Parent=content, PaddingTop=UDim.new(0,15), PaddingLeft=UDim.new(0,15), PaddingRight=UDim.new(0,15), PaddingBottom=UDim.new(0,15)})
mk("UIListLayout", {Parent=content, FillDirection=Enum.FillDirection.Horizontal, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,15)})

local function createColumn(parent)
    local col = mk("ScrollingFrame", {BackgroundTransparency=1, Size=UDim2.new(0.333, -10, 1, 0), CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y, ScrollBarThickness=2, ScrollBarImageColor3=Color3.fromRGB(100,100,100), BorderSizePixel=0, Parent=parent})
    mk("UIListLayout", {Parent=col, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,8)})
    mk("UIPadding", {Parent=col, PaddingRight=UDim.new(0, 5)})
    return col
end

local col1 = createColumn(content)
local col2 = createColumn(content)
local col3 = createColumn(content)

local function createHeader(parent, text)
    local f = mk("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,25), Parent=parent})
    mk("TextLabel", {Text=text, Font=Enum.Font.GothamBold, TextSize=14, TextColor3=CURRENT.Accent, BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), TextXAlignment=Enum.TextXAlignment.Left, Parent=f})
    mk("Frame", {BackgroundColor3=CURRENT.Accent, BackgroundTransparency=0.7, BorderSizePixel=0, AnchorPoint=Vector2.new(0,1), Position=UDim2.new(0,0,1,-2), Size=UDim2.new(1,0,0,1), Parent=f})
end

local function createSwitch(parent, text, subText, callback, isDefaultOn)
    local c = mk("Frame", {BackgroundColor3 = Color3.fromRGB(40,40,40), Size=UDim2.new(1,0,0,48), Parent=parent})
    mk("UICorner", {Parent=c, CornerRadius=UDim.new(0,8)})
    mk("TextLabel", {Text = text, Font=Enum.Font.GothamMedium, TextSize=12, TextColor3=Color3.fromRGB(240,240,240), BackgroundTransparency=1, Position=UDim2.new(0,12,0,8), Size=UDim2.new(0.7,0,0,15), TextXAlignment=Enum.TextXAlignment.Left, Parent=c})
    if subText then mk("TextLabel", {Text = subText, Font=Enum.Font.Gotham, TextSize=10, TextColor3=Color3.fromRGB(150,150,150), BackgroundTransparency=1, Position=UDim2.new(0,12,0,25), Size=UDim2.new(0.7,0,0,15), TextXAlignment=Enum.TextXAlignment.Left, Parent=c}) end
    local on = isDefaultOn or false
    local bgCol = on and CURRENT.Accent or Color3.fromRGB(60,60,60)
    local circPos = on and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
    local sw = mk("TextButton", {Text = "", AutoButtonColor=false, BackgroundColor3=bgCol, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-12,0.5,0), Size=UDim2.fromOffset(36, 20), Parent=c})
    mk("UICorner", {Parent=sw, CornerRadius=UDim.new(1,0)})
    local circ = mk("Frame", {BackgroundColor3 = Color3.new(1,1,1), Size=UDim2.fromOffset(14,14), AnchorPoint=Vector2.new(0,0.5), Position=circPos, Parent=sw})
    mk("UICorner", {Parent=circ, CornerRadius=UDim.new(1,0)})
    sw.MouseButton1Click:Connect(function()
        playClick() on = not on
        if on then tween(sw, {BackgroundColor3 = CURRENT.Accent}) tween(circ, {Position = UDim2.new(1, -17, 0.5, 0)})
        else tween(sw, {BackgroundColor3 = Color3.fromRGB(60,60,60)}) tween(circ, {Position = UDim2.new(0, 3, 0.5, 0)}) end
        if callback then callback(on) end
    end)
end

local function createInput(parent, text, defaultVal, callback)
    local c = mk("Frame", {BackgroundColor3 = Color3.fromRGB(40,40,40), Size=UDim2.new(1,0,0,40), Parent=parent})
    mk("UICorner", {Parent=c, CornerRadius=UDim.new(0,8)})
    mk("TextLabel", {Text=text, Font=Enum.Font.GothamMedium, TextSize=12, TextColor3=Color3.fromRGB(240,240,240), BackgroundTransparency=1, Position=UDim2.new(0,12,0,0), Size=UDim2.new(0.4,0,1,0), TextXAlignment=Enum.TextXAlignment.Left, Parent=c})
    local box = mk("TextBox", {Text=defaultVal, Font=Enum.Font.GothamBold, TextSize=11, TextColor3=Color3.fromRGB(20,20,20), BackgroundColor3=CURRENT.Accent, Size=UDim2.new(0,130,0,24), AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-12,0.5,0), Parent=c})
    mk("UICorner", {Parent=box, CornerRadius=UDim.new(0,6)})
    box.FocusLost:Connect(function() callback(box.Text) end)
end

local function createButton(parent, text, callback)
    local c = mk("Frame", {BackgroundColor3 = Color3.fromRGB(40,40,40), Size=UDim2.new(1,0,0,36), Parent=parent})
    mk("UICorner", {Parent=c, CornerRadius=UDim.new(0,8)})
    local btn = mk("TextButton", {Text=text, Font=Enum.Font.GothamBold, TextSize=12, TextColor3=Color3.fromRGB(20,20,20), BackgroundColor3=CURRENT.Accent, Size=UDim2.new(1,-12,1,-10), AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.5,0), Parent=c})
    mk("UICorner", {Parent=btn, CornerRadius=UDim.new(0,6)})
    btn.MouseButton1Click:Connect(function() playClick() if callback then callback() end end)
end

local function fireTargetPrompt(prompt)
    if prompt and prompt:IsA("ProximityPrompt") then
        local oldLOS = prompt.RequiresLineOfSight
        local oldDist = prompt.MaxActivationDistance
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = 99999
        prompt.Enabled = true
        if fireproximityprompt then fireproximityprompt(prompt, 1, true) end
        pcall(function()
            prompt:InputHoldBegin()
            task.delay(prompt.HoldDuration > 0 and prompt.HoldDuration or 0.1, function()
                prompt:InputHoldEnd()
            end)
        end)
        task.wait(0.1)
        prompt.RequiresLineOfSight = oldLOS
        prompt.MaxActivationDistance = oldDist
    end
end

local function getPromptPos(prompt)
    local p = prompt.Parent
    if not p then return nil end
    if p:IsA("Attachment") then return p.WorldPosition end
    if p:IsA("BasePart") then return p.Position end
    if p:IsA("Model") then return p:GetPivot().Position end
    return nil
end

-- ==========================================
-- 🛠️ ระบบกวาดล้าง UI นิวเคลียร์ล้างบาง (อัปเดต 2 ภาษา + เตะนอกจอ)
-- ==========================================
local function forceClick(guiObject)
    if getconnections then
        for _, conn in pairs(getconnections(guiObject.MouseButton1Click)) do pcall(function() conn:Fire() end) end
        for _, conn in pairs(getconnections(guiObject.Activated)) do pcall(function() conn:Fire() end) end
    elseif firesignal then
        pcall(function() firesignal(guiObject.MouseButton1Click) end)
        pcall(function() firesignal(guiObject.Activated) end)
    end
end

task.spawn(function()
    while task.wait(0.1) do
        pcall(function()
            for _, gui in pairs(lp.PlayerGui:GetChildren()) do
                if gui:IsA("ScreenGui") and gui.Enabled and gui.Name ~= "UniversalLuaRBX" then
                    for _, desc in pairs(gui:GetDescendants()) do
                        if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                            local txtUpper = string.upper(tostring(desc.Text))
                            
                            -- เจาะจงหาข้อความรกๆ ไม่ว่าจะภาษาอะไร
                            if txtUpper:find("ITEM COLLECTED") or txtUpper:find("CLICK ANYWHERE") or txtUpper:find("คลิกที่ใดก็ได้") or txtUpper == "ปิด" or txtUpper == "CLOSE" then
                                local highestFrame = desc
                                -- ไล่หา Frame กรอบใหญ่สุดของมัน
                                while highestFrame.Parent and highestFrame.Parent:IsA("GuiObject") do
                                    highestFrame = highestFrame.Parent
                                end
                                
                                if highestFrame then
                                    -- 1. รัวปุ่มจำลองคลิกทุกอันที่ขวางหน้า เพื่อให้เกมรู้ว่ากดปิดแล้ว
                                    for _, btn in pairs(highestFrame:GetDescendants()) do
                                        if btn:IsA("GuiButton") then
                                            forceClick(btn)
                                        end
                                    end
                                    -- 2. เตะกระเด็นออกนอกจอ พร้อมล่องหน
                                    highestFrame.Position = UDim2.new(9999, 0, 9999, 0)
                                    highestFrame.Visible = false
                                end
                            end
                            
                            -- ซ่อนหน้าต่าง NPC ซื้อขาย
                            if txtUpper:find("มีของเก่ามาขายไหม") or txtUpper:find("ขายทั้งหมด") then
                                gui.Enabled = false
                            end
                        end
                    end
                    
                    local n = string.lower(gui.Name)
                    -- กวาดล้างพวกหน้าต่าง Reward โง่ๆ ทิ้งไปเลย
                    if n:find("reward") or n:find("collected") then
                        gui.Enabled = false
                    end
                end
            end
        end)
    end
end)


-- ==========================================
-- 🎰 สุ่มกาชา (คอลัมน์ 1 - ระบบ 3 พิกัด สุ่ม->ขาย->บ้าน)
-- ==========================================
createHeader(col1, "🎰 สุ่มกาชา (ฟาร์มสัตว์เลี้ยง)")
_G.AutoSpinGacha = false

createButton(col1, "📍 1. ตั้งพิกัดจุดสุ่ม (ยืนชิดตู้สุ่มแล้วกด)", function()
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        local pos = lp.Character.HumanoidRootPart.Position
        _G.SpinPlaceArgs = {pos.X, pos.Y, pos.Z}
        sendNotify("สำเร็จ!", "บันทึกพิกัด 'จุดสุ่มขยะ' เรียบร้อย!")
    end
end)

createButton(col1, "💰 2. ตั้งพิกัดจุดขาย (ยืนหน้าจอคอมขาย)", function()
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        local pos = lp.Character.HumanoidRootPart.Position
        _G.SellPlaceArgs = {pos.X, pos.Y, pos.Z}
        sendNotify("สำเร็จ!", "บันทึกพิกัด 'จุดขาย' เรียบร้อย!")
    end
end)

createButton(col1, "🏠 3. ตั้งพิกัดบ้าน (ยืนข้างสัตว์เลี้ยง)", function()
    if lp.Character and lp.Character.PrimaryPart then
        _G.HomePlaceArgs = lp.Character.PrimaryPart.CFrame
        sendNotify("สำเร็จ!", "บันทึกพิกัด 'บ้าน' เรียบร้อย!")
    end
end)

createSwitch(col1, "🎰 4. เริ่มออโต้สุ่มขยะ", "วาร์ป 3 จุด (สุ่ม->ขาย->ฟาร์มสัตว์ 60 วิ)", function(state)
    _G.AutoSpinGacha = state
    
    if not state then releaseLock() end 
    
    if state then
        sendNotify("Ghost Spin Ultimate", "ทำงาน! เตรียมวาร์ปข้ามมิติ")
        task.spawn(function()
            local bglEvent = ReplicatedStorage:WaitForChild("BGLRecycleEvent", 5)
            
            while _G.AutoSpinGacha do
                local shouldSell = _G.IsBagFull_ServerSignal 
                local hasFullText = false
                
                local safeZoneCFrame = _G.HomePlaceArgs or (lp.Character and lp.Character.PrimaryPart and lp.Character.PrimaryPart.CFrame)
                
                -- ซ่อนหน้าต่างสุ่มขยะ (Random-items) ออกนอกจอแบบโหดๆ
                pcall(function()
                    local ui = lp.PlayerGui:FindFirstChild("Random-items")
                    if ui and ui:FindFirstChild("RecycleUI") then
                        ui.RecycleUI.Position = UDim2.new(9999, 0, 9999, 0)
                        ui.RecycleUI.Visible = false
                    end
                end)
                
                pcall(function()
                    for _, gui in pairs(lp.PlayerGui:GetDescendants()) do
                        if gui:IsA("TextLabel") and gui.Visible and gui.Text ~= "" then
                            local txt = tostring(gui.Text)
                            if txt:find("BAG เต็ม") or txt:find("เคลียร์กระเป๋า") or txt:find("สุ่มไม่ได้") then
                                hasFullText = true
                                gui.Text = "" 
                                gui.Visible = false 
                            end
                        end
                    end
                end)
                
                local uiBagCount = 0
                pcall(function()
                    for _, gui in pairs(lp.PlayerGui:GetDescendants()) do
                        if gui:IsA("ImageButton") and gui.Name:match("^BagSlot_") and gui.Visible then
                            uiBagCount = uiBagCount + 1
                        end
                    end
                end)

                if uiBagCount == 0 then
                    _G.IsBagFull_ServerSignal = false
                    hasFullText = false
                end

                if uiBagCount >= 12 or (_G.IsBagFull_ServerSignal and uiBagCount > 0) or (hasFullText and uiBagCount > 0) then
                    shouldSell = true
                end
                
                getLock()
                
                if shouldSell then
                    -- ==========================
                    -- 💰 โหมดขายของ (เมื่อกระเป๋าเต็ม)
                    -- ==========================
                    if not _G.SellPlaceArgs then
                        sendNotify("หาจุดขายไม่เจอ!", "โปรดตั้งพิกัดจุดขาย (ปุ่ม 2) ก่อนเริ่ม")
                        _G.AutoSpinGacha = false
                        break
                    end
                    
                    local sPos = Vector3.new(_G.SellPlaceArgs[1], _G.SellPlaceArgs[2], _G.SellPlaceArgs[3])
                    if lp.Character and lp.Character.PrimaryPart then
                        lp.Character:PivotTo(CFrame.new(sPos + Vector3.new(0, 3, 0)))
                        lp.Character.PrimaryPart.Velocity = Vector3.new(0,0,0)
                        task.wait(0.3)
                    end

                    local sellPrompt = nil
                    local minDist = 30
                    for _, prompt in pairs(workspace:GetDescendants()) do
                        if prompt:IsA("ProximityPrompt") then
                            local pStr = string.upper(prompt.Name .. "|" .. (prompt.ActionText or "") .. "|" .. (prompt.ObjectText or ""))
                            if prompt:GetAttribute("RecycleSellShop") == true or pStr:find("SELL") or pStr:find("ขาย") then
                                local pPos = getPromptPos(prompt)
                                if pPos then
                                    local dist = (pPos - sPos).Magnitude
                                    if dist < minDist then
                                        minDist = dist
                                        sellPrompt = prompt
                                    end
                                end
                            end
                        end
                    end

                    if sellPrompt then
                        local pPos = getPromptPos(sellPrompt)
                        if pPos and lp.Character and lp.Character.PrimaryPart then
                            lp.Character:PivotTo(CFrame.new(pPos + Vector3.new(0, 2, 0)))
                            lp.Character.PrimaryPart.Velocity = Vector3.new(0,0,0)
                            task.wait(0.15)
                        end
                        
                        local sellRemote = sellPrompt:FindFirstChild("RecycleSellRemote") or sellPrompt.Parent:FindFirstChild("RecycleSellRemote", true)
                        if sellRemote then
                            fireTargetPrompt(sellPrompt)
                            task.wait(0.2)
                            pcall(function() sellRemote:FireServer("SellAll") end)
                        else
                            for _, obj in pairs(workspace:GetDescendants()) do
                                if obj.Name == "RecycleSellRemote" and obj:IsA("RemoteEvent") then
                                    pcall(function() obj:FireServer("SellAll") end)
                                end
                            end
                        end
                        task.wait(0.2) 
                        pcall(function() ReplicatedStorage:WaitForChild("BagRemotes", 2):WaitForChild("GetState", 2):InvokeServer() end)
                        _G.IsBagFull_ServerSignal = false
                        sendNotify("Recycle Sold", "ขายของสำเร็จ! วาร์ปกลับบ้าน")
                    else
                        sendNotify("หาจุดขายไม่เจอ!", "ไม่พบปุ่ม SELL บริเวณพิกัดที่ตั้งไว้")
                    end
                    
                    if safeZoneCFrame and lp.Character and lp.Character.PrimaryPart then
                        lp.Character:PivotTo(safeZoneCFrame)
                        lp.Character.PrimaryPart.Velocity = Vector3.new(0,0,0)
                    end
                    
                    releaseLock()
                    task.wait(0.5)
                else
                    -- ==========================
                    -- 🎰 โหมดสุ่มสปิน (กระเป๋ายังไม่เต็ม)
                    -- ==========================
                    if not _G.SpinPlaceArgs then
                        sendNotify("หาจุดสุ่มไม่เจอ!", "โปรดตั้งพิกัดจุดสุ่ม (ปุ่ม 1) ก่อนเริ่ม")
                        _G.AutoSpinGacha = false
                        break
                    end
                    
                    local spinPos = Vector3.new(_G.SpinPlaceArgs[1], _G.SpinPlaceArgs[2], _G.SpinPlaceArgs[3])
                    if lp.Character and lp.Character.PrimaryPart then
                        lp.Character:PivotTo(CFrame.new(spinPos + Vector3.new(0, 3, 0)))
                        lp.Character.PrimaryPart.Velocity = Vector3.new(0,0,0)
                        task.wait(0.3)
                    end
                    
                    local spinPrompt = nil
                    local minDist = 30
                    for _, prompt in pairs(workspace:GetDescendants()) do
                        if prompt:IsA("ProximityPrompt") then
                            local pStr = string.upper(prompt.Name .. "|" .. (prompt.ActionText or "") .. "|" .. (prompt.ObjectText or ""))
                            if pStr:find("SEARCH") or pStr:find("สุ่ม") or pStr:find("SPIN") or pStr:find("RECYCLEBINRATES") then
                                local pPos = getPromptPos(prompt)
                                if pPos then
                                    local dist = (pPos - spinPos).Magnitude
                                    if dist < minDist then
                                        minDist = dist
                                        spinPrompt = prompt
                                    end
                                end
                            end
                        end
                    end
                    
                    if spinPrompt then
                        fireTargetPrompt(spinPrompt)
                        task.wait(0.15)
                    end

                    if bglEvent then
                        pcall(function() bglEvent:FireServer("Spin", {}) end)
                        pcall(function() bglEvent:FireServer("Spin") end)
                    end
                    
                    if safeZoneCFrame and lp.Character and lp.Character.PrimaryPart then
                        lp.Character:PivotTo(safeZoneCFrame)
                        lp.Character.PrimaryPart.Velocity = Vector3.new(0,0,0)
                    end
                    
                    releaseLock()
                    sendNotify("Cooldown Started", "สุ่มเสร็จแล้ว! รอคูลดาวน์ 62 วินาที")
                    task.wait(62) 
                end
            end
        end)
    else
        sendNotify("Auto Spin", "หยุดทำงานแล้ว")
    end
end)


-- ==========================================
-- 🍔 ออโต้แดก & ตั้งค่าผู้เล่น (คอลัมน์ 2)
-- ==========================================
createHeader(col2, "🍔 ออโต้แดก (Auto Eat)")
_G.AutoBuyEat = false

local function checkIsRealFood(prompt)
    local actText = string.upper(tostring(prompt.ActionText or ""))
    local objText = string.upper(tostring(prompt.ObjectText or ""))
    local pName = string.upper(tostring(prompt.Name or ""))
    
    local fullText = actText .. "|" .. objText .. "|" .. pName
    
    if not (fullText:find("BUY") or fullText:find("ซื้อ")) then return false end
    
    local badWords = {"UGC", "PET", "SEED", "PLANT", "เมล็ด", "พืช", "ต้น", "ดอก", "AVATAR", "HAIR", "CLOTH", "ITEM", "SHOP", "ANIMAL"}
    for _, w in ipairs(badWords) do
        if fullText:find(w) then return false end
    end
    
    local isFood = false
    local p = prompt.Parent
    for i = 1, 4 do
        if p and p ~= workspace then
            local n = string.upper(p.Name)
            if n:find("FOOD") or n:find("MEAL") or n:find("DISH") then
                isFood = true
                break
            end
            p = p.Parent
        end
    end
    
    if fullText:find("FOOD") or fullText:find("ข้าว") or fullText:find("แกง") or fullText:find("ต้ม") or fullText:find("ผัด") or fullText:find("ไก่") or fullText:find("หมู") then
        isFood = true
    end

    return isFood
end

createSwitch(col2, "เริ่มออโต้แดก (ซื้อ+กิน)", "สแกนของกิน 100% บล็อกทุกสิ่งที่ไม่ใช่อาหาร", function(state)
    _G.AutoBuyEat = state
    if not state then releaseLock() end 

    if state then
        sendNotify("Auto Eat", "โหมดกินดุเริ่มทำงาน! (บล็อกสัตว์เลี้ยงและ UGC แล้ว)")
        task.spawn(function()
            local eatRemote = nil
            pcall(function()
                eatRemote = ReplicatedStorage:WaitForChild("FoodCookingSystem", 5)
                            :WaitForChild("Remotes")
                            :WaitForChild("FoodCooking_EatHeldFood_V1")
            end)

            while _G.AutoBuyEat do
                if eatRemote then
                    pcall(function()
                        eatRemote:InvokeServer()
                        task.wait(0.02)
                        eatRemote:InvokeServer()
                    end)
                end
                task.wait(0.03) 
                
                local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local myFoodPos = Vector3.new(_G.FoodPlaceArgs[1], 0, _G.FoodPlaceArgs[3])
                    for _, prompt in pairs(workspace:GetDescendants()) do
                        if prompt:IsA("ProximityPrompt") then
                            
                            if checkIsRealFood(prompt) then
                                local pPos = getPromptPos(prompt)
                                if pPos then
                                    local distFromMyStall = (Vector3.new(pPos.X, 0, pPos.Z) - myFoodPos).Magnitude
                                    
                                    if not _G.IgnoreMyFood or distFromMyStall > 15 then
                                        if (pPos - hrp.Position).Magnitude < 500 then
                                            getLock()
                                            lp.Character:PivotTo(CFrame.new(pPos + Vector3.new(0, 3, 0)))
                                            if lp.Character.PrimaryPart then lp.Character.PrimaryPart.Velocity = Vector3.new(0,0,0) end
                                            task.wait(0.05) 
                                            fireTargetPrompt(prompt)
                                            task.wait(0.1) 
                                            
                                            if eatRemote then
                                                pcall(function()
                                                    eatRemote:InvokeServer()
                                                    eatRemote:InvokeServer()
                                                end)
                                            end
                                            
                                            releaseLock()
                                            break 
                                        end
                                    end
                                end
                            end
                            
                        end
                    end
                end
            end
        end)
    else
        sendNotify("Auto Eat", "หยุดทำงานแล้ว")
    end
end)

createSwitch(col2, "🚫 ไม่กินอาหารจากเตาตัวเอง", "ปิดไว้ถ้าจะฉกจานของตัวเอง", function(state) _G.IgnoreMyFood = state end, true)

createHeader(col2, "🏃 ตั้งค่าผู้เล่น (Player)")
local walkSpeed = 100

createInput(col2, "ความเร็วเดิน (WalkSpeed)", "100", function(val) walkSpeed = tonumber(val) or 100 end)
createSwitch(col2, "ล็อคความเร็วเดิน", "ป้องกันเกมรีเซ็ตความเร็ว", function(state)
    _G.LockSpeed = state
    task.spawn(function()
        while _G.LockSpeed do
            if lp.Character and lp.Character:FindFirstChild("Humanoid") then
                lp.Character.Humanoid.WalkSpeed = walkSpeed
            end
            RunService.Stepped:Wait()
        end
    end)
end)

createSwitch(col2, "ป้องกัน AFK (Anti-AFK)", "กันโดนเตะเมื่อยืนนิ่งเกิน 20 นาที", function(state)
    _G.AntiAFK = state
    if state then sendNotify("Anti-AFK", "เปิดระบบป้องกันโดนเตะแล้ว!")
    else sendNotify("Anti-AFK", "ปิดระบบป้องกัน AFK") end
end)

lp.Idled:Connect(function()
    if _G.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)


-- ==========================================
-- 🍳 ออโต้ทำอาหาร (คอลัมน์ 3)
-- ==========================================
createHeader(col3, "🍳 ออโต้ทำอาหาร (Auto Cook)")
local uiFoodName = "Food-spicy-prawn-soup" 
local uiSaleMode = "Online"
_G.AutoFood = false

createButton(col3, "📍 ตั้งจุดวางจานตรงที่ยืนอยู่", function()
    local char = lp.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {char}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        
        local result = workspace:Raycast(hrp.Position, Vector3.new(0, -15, 0), raycastParams)
        local placePos = result and result.Position or (hrp.Position - Vector3.new(0, 3, 0))
        local _, ry, _ = hrp.CFrame:ToOrientation()
        local finalCFrame = CFrame.new(placePos) * CFrame.Angles(0, ry, 0)
        
        local comps = {finalCFrame:GetComponents()}
        _G.FoodPlaceArgs = comps
        pcall(function() setclipboard(string.format("{%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f}", unpack(comps))) end)
        sendNotify("สำเร็จ!", "ตั้งพิกัดทำอาหารเรียบร้อยแล้ว")
    else
        sendNotify("ข้อผิดพลาด", "ไม่พบตัวละคร")
    end
end)

createInput(col3, "รหัสเมนู", uiFoodName, function(val) uiFoodName = val end)
createSwitch(col3, "โหมดขาย (เปิด=Online)", "ค่าเริ่มต้นคือ Online อัตโนมัติ", function(state)
    if state then uiSaleMode = "Online" else uiSaleMode = "Villagers" end
end, true)

createSwitch(col3, "🍳 เริ่มฟาร์มอาหารออโต้", "ความเร็วแสง (Zero Delay)", function(state)
    _G.AutoFood = state
    if not state then releaseLock() end 
    local craftPosCFrame = state and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and lp.Character.HumanoidRootPart.CFrame

    if state then
        sendNotify("Food Farm", "เริ่มฟาร์มระบบความเร็วแสง!")
        task.spawn(function()
            local remotes = ReplicatedStorage:WaitForChild("FoodCookingSystem"):WaitForChild("Remotes")
            local startRemote = remotes:WaitForChild("FoodCooking_StartCraft_V1")
            local getStateRemote = remotes:WaitForChild("FoodCooking_GetState_V1")
            local placeRemote = remotes:WaitForChild("FoodCooking_PlaceFood_V1")

            while _G.AutoFood do
                local px, py, pz = _G.FoodPlaceArgs[1], _G.FoodPlaceArgs[2], _G.FoodPlaceArgs[3]
                local flatPlacePos = Vector3.new(px, 0, pz)
                
                local succ, st = pcall(function() return getStateRemote:InvokeServer(uiFoodName) end)
                local isCooking = false
                if succ and st and type(st) == "table" then
                    if st.Job then isCooking = not (st.Job.Ready or st.Job.IsFinished) end
                end
                
                if not isCooking then
                    getLock()
                    
                    if lp.Character and lp.Character.PrimaryPart then
                        local charPos = Vector3.new(px, py + 3, pz)
                        local lookPos = Vector3.new(px + 2, charPos.Y, pz)
                        lp.Character:PivotTo(CFrame.new(charPos, lookPos))
                        lp.Character.PrimaryPart.Velocity = Vector3.new(0,0,0)
                        task.wait(0.01)
                    end
                    
                    local safetyNet = 0
                    while _G.AutoFood and safetyNet < 20 do
                        safetyNet = safetyNet + 1
                        pcall(function() placeRemote:InvokeServer(uiFoodName, _G.FoodPlaceArgs, "Inventory") end)
                        task.wait(0.03) 
                        
                        local foundPlate = false
                        for _, prompt in pairs(workspace:GetDescendants()) do
                            if prompt:IsA("ProximityPrompt") then
                                local aText = tostring(prompt.ActionText or "")
                                local pName = tostring(prompt.Name or "")
                                if aText:find("ขาย") or aText:find("ส่ง") or pName:find("Sell") then
                                    local rawPos = getPromptPos(prompt)
                                    if rawPos and (Vector3.new(rawPos.X, 0, rawPos.Z) - flatPlacePos).Magnitude < 15 then
                                        foundPlate = true
                                        if lp.Character and lp.Character.PrimaryPart then
                                            local charPos = rawPos + Vector3.new(2, 3, 2)
                                            local lookPos = Vector3.new(rawPos.X, charPos.Y, rawPos.Z)
                                            lp.Character:PivotTo(CFrame.new(charPos, lookPos))
                                            task.wait(0.01)
                                        end
                                        fireTargetPrompt(prompt)
                                        task.wait(0.03)
                                    end
                                end
                            end
                        end
                        if not foundPlate then break end
                    end
                    
                    if craftPosCFrame and lp.Character and lp.Character.PrimaryPart then
                        lp.Character:PivotTo(craftPosCFrame)
                        lp.Character.PrimaryPart.Velocity = Vector3.new(0,0,0)
                        task.wait(0.03)
                    end
                    
                    local priceArg = nil
                    if uiSaleMode == "Villagers" then priceArg = 99999 end
                    pcall(function() startRemote:InvokeServer(uiFoodName, priceArg, uiSaleMode, 1) end)
                    
                    releaseLock()
                end
                task.wait(0.05)
            end
        end)
    else
        sendNotify("Food Farm", "หยุดทำงานแล้ว")
    end
end)
