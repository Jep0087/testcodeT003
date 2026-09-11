--// Universal LuaRBX - Thai Edition (AIO: Food, Recycle, Auto Eat)
--// Keybind เปิด/ปิดเมนู: J

-- ==========================================
-- 📍 ตั้งค่าพิกัดเริ่มต้น และ ระบบคิว (Queue System)
-- ==========================================
_G.FoodPlaceArgs = {
    [1] = -142.93292236328125, [2] = 3.375349760055542, [3] = 10.6432466506958,
    [4] = 1, [5] = 0, [6] = 0, [7] = 0, [8] = 1, [9] = 0, [10] = 0, [11] = 0, [12] = 1
}

_G.SellPlaceArgs = nil -- พิกัดตู้ขายขยะ (ป้องกันเกมซ่อนแมพ)

_G.BotActionLock = false 
_G.IgnoreMyFood = true 
_G.AntiAFK = false

-- 🔥 ตัวแปรเก็บสถานะกระเป๋าที่ดักฟังจากเซิร์ฟเวอร์โดยตรง
_G.IsBagFull_ServerSignal = false 

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")

local lp = Players.LocalPlayer
local pg = lp:WaitForChild("PlayerGui")

if pg:FindFirstChild("UniversalLuaRBX") then pg.UniversalLuaRBX:Destroy() end

local CURRENT = {Accent = Color3.fromRGB(85, 255, 127), Bg = Color3.fromRGB(25, 25, 25)}

-- ==========================================
-- 📡 ระบบดักฟัง Server (Intercept Bag Remotes)
-- ==========================================
task.spawn(function()
    local bagRemotes = ReplicatedStorage:WaitForChild("BagRemotes", 5)
    if bagRemotes then
        local feedback = bagRemotes:WaitForChild("Feedback", 5)
        if feedback then
            feedback.OnClientEvent:Connect(function(msg)
                if msg == "FULL" then
                    _G.IsBagFull_ServerSignal = true
                end
            end)
        end
    end
    
    local recycleEvent = ReplicatedStorage:WaitForChild("BGLRecycleEvent", 5)
    if recycleEvent then
        recycleEvent.OnClientEvent:Connect(function(action, data)
            if action == "Error" then
                local txt = tostring(data)
                -- ตัดคำทักทายร้านค้าออก ป้องกันลูป
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

local function releaseLock()
    _G.BotActionLock = false
end

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

local window = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(580, 360), BackgroundColor3 = CURRENT.Bg, BackgroundTransparency = 0.02, Active = true, ClipsDescendants = true, Parent = gui })
mk("UICorner", {Parent=window, CornerRadius=UDim.new(0,10)})
mk("UIStroke", {Parent=window, Color=Color3.fromRGB(65,65,65), Thickness=1, Transparency=0.4})

local top = mk("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), Parent = window})
mk("TextLabel", {Text = "AIO Farm Hub - V.Max (Speed Demon Edition)", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Color3.fromRGB(240,240,240), BackgroundTransparency = 1, Position = UDim2.new(0, 15, 0, 0), Size = UDim2.new(0, 400, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = top})
local minBtn = mk("TextButton", {Text = "-", Font=Enum.Font.GothamBold, TextSize=22, TextColor3=Color3.fromRGB(150,150,150), BackgroundTransparency=1, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-12,0.5,0), Size=UDim2.fromOffset(30,30), Parent=top})
mk("Frame", {BackgroundColor3 = Color3.fromRGB(65,65,65), BorderSizePixel=0, Position=UDim2.new(0,0,0,40), Size=UDim2.new(1,0,0,1), Parent=window})

local dragging, dragStart, startPos
window.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging=true dragStart=i.Position startPos=window.Position end end)
UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d=i.Position-dragStart window.Position=UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging=false end end)
UserInputService.InputBegan:Connect(function(i, gp) if not gp and i.KeyCode == Enum.KeyCode.J then window.Visible = not window.Visible end end)

minBtn.MouseButton1Click:Connect(function()
    playClick()
    if window.Size.Y.Offset > 40 then
        tween(window, {Size = UDim2.fromOffset(580, 40)}, 0.3) minBtn.Text = "+"
    else
        tween(window, {Size = UDim2.fromOffset(580, 360)}, 0.3) minBtn.Text = "-"
    end
end)

local content = mk("Frame", {BackgroundTransparency = 1, Position=UDim2.new(0,0,0,41), Size=UDim2.new(1,0,1,-41), Parent=window})
local sidebar = mk("Frame", {BackgroundTransparency=1, Size=UDim2.new(0,140,1,0), Parent=content})
local pagesHost = mk("Frame", {BackgroundTransparency=1, Position=UDim2.new(0,140,0,0), Size=UDim2.new(1,-140,1,0), Parent=content})
local tabContainer = mk("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), Parent=sidebar})
mk("UIListLayout", {Parent=tabContainer, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,6)})
mk("UIPadding", {Parent=tabContainer, PaddingTop=UDim.new(0,10), PaddingLeft=UDim.new(0,10)})

local tabs = {}
local function createTab(name)
    local btn = mk("TextButton", {Text = name, Font=Enum.Font.GothamMedium, TextSize=13, TextColor3=Color3.fromRGB(150,150,150), BackgroundTransparency=1, Size=UDim2.new(1,0,0,32), TextXAlignment=Enum.TextXAlignment.Left, Parent=tabContainer})
    mk("UIPadding", {Parent=btn, PaddingLeft=UDim.new(0, 15)})
    local indicator = mk("Frame", {BackgroundColor3 = CURRENT.Accent, Size = UDim2.new(0, 3, 0, 0), Position = UDim2.new(0, -10, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BorderSizePixel = 0, BackgroundTransparency = 1, Parent = btn})
    mk("UICorner", {Parent=indicator, CornerRadius=UDim.new(1,0)})
    local page = mk("ScrollingFrame", {Visible=false, BackgroundTransparency=1, Size=UDim2.fromScale(1,1), CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y, ScrollBarThickness=2, ScrollBarImageColor3=Color3.fromRGB(150,150,150), BorderSizePixel=0, Parent=pagesHost})
    mk("UIListLayout", {Parent=page, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,10)})
    mk("UIPadding", {Parent=page, PaddingTop=UDim.new(0,10), PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,10), PaddingBottom=UDim.new(0,10)})
    btn.MouseButton1Click:Connect(function()
        playClick() for _,t in pairs(tabs) do tween(t.Btn, {TextColor3=Color3.fromRGB(150,150,150)}) tween(t.Ind, {Size=UDim2.new(0,3,0,0), BackgroundTransparency=1}) t.Page.Visible = false end
        tween(btn, {TextColor3=CURRENT.Accent}) tween(indicator, {Size=UDim2.new(0,3,0,20), BackgroundTransparency=0}) page.Visible = true
    end)
    table.insert(tabs, {Btn=btn, Page=page, Ind=indicator}) return page
end

local function createSwitch(parent, text, subText, callback, isDefaultOn)
    local c = mk("Frame", {BackgroundColor3 = Color3.fromRGB(40,40,40), Size=UDim2.new(1,0,0,48), Parent=parent})
    mk("UICorner", {Parent=c, CornerRadius=UDim.new(0,8)})
    mk("TextLabel", {Text = text, Font=Enum.Font.GothamMedium, TextSize=13, TextColor3=Color3.fromRGB(240,240,240), BackgroundTransparency=1, Position=UDim2.new(0,15,0,8), Size=UDim2.new(0.7,0,0,15), TextXAlignment=Enum.TextXAlignment.Left, Parent=c})
    if subText then mk("TextLabel", {Text = subText, Font=Enum.Font.Gotham, TextSize=11, TextColor3=Color3.fromRGB(150,150,150), BackgroundTransparency=1, Position=UDim2.new(0,15,0,25), Size=UDim2.new(0.7,0,0,15), TextXAlignment=Enum.TextXAlignment.Left, Parent=c}) end
    
    local on = isDefaultOn or false
    local bgCol = on and CURRENT.Accent or Color3.fromRGB(60,60,60)
    local circPos = on and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
    
    local sw = mk("TextButton", {Text = "", AutoButtonColor=false, BackgroundColor3=bgCol, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-15,0.5,0), Size=UDim2.fromOffset(40, 20), Parent=c})
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
    local c = mk("Frame", {BackgroundColor3 = Color3.fromRGB(40,40,40), Size=UDim2.new(1,0,0,44), Parent=parent})
    mk("UICorner", {Parent=c, CornerRadius=UDim.new(0,8)})
    mk("TextLabel", {Text=text, Font=Enum.Font.GothamMedium, TextSize=13, TextColor3=Color3.fromRGB(240,240,240), BackgroundTransparency=1, Position=UDim2.new(0,15,0,0), Size=UDim2.new(0.4,0,1,0), TextXAlignment=Enum.TextXAlignment.Left, Parent=c})
    local box = mk("TextBox", {Text=defaultVal, Font=Enum.Font.GothamBold, TextSize=11, TextColor3=Color3.fromRGB(20,20,20), BackgroundColor3=CURRENT.Accent, Size=UDim2.new(0,160,0,26), AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-15,0.5,0), Parent=c})
    mk("UICorner", {Parent=box, CornerRadius=UDim.new(0,6)})
    box.FocusLost:Connect(function() callback(box.Text) end)
end

local function createButton(parent, text, callback)
    local c = mk("Frame", {BackgroundColor3 = Color3.fromRGB(40,40,40), Size=UDim2.new(1,0,0,38), Parent=parent})
    mk("UICorner", {Parent=c, CornerRadius=UDim.new(0,8)})
    local btn = mk("TextButton", {Text=text, Font=Enum.Font.GothamBold, TextSize=13, TextColor3=Color3.fromRGB(20,20,20), BackgroundColor3=CURRENT.Accent, Size=UDim2.new(1,-16,1,-12), AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.5,0), Parent=c})
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
        
        prompt:InputHoldBegin()
        task.delay(prompt.HoldDuration > 0 and prompt.HoldDuration or 0.1, function()
            prompt:InputHoldEnd()
        end)
        
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
-- 🛠️ ระบบกวาดล้าง UI รบกวนขั้นเด็ดขาด
-- ==========================================
task.spawn(function()
    while task.wait(0.2) do
        pcall(function()
            for _, gui in pairs(lp.PlayerGui:GetChildren()) do
                if gui:IsA("ScreenGui") and gui.Enabled and gui.Name ~= "UniversalLuaRBX" then
                    local hideGui = false
                    
                    for _, desc in pairs(gui:GetDescendants()) do
                        if (desc:IsA("TextButton") or desc:IsA("TextLabel") or desc:IsA("ImageButton")) and desc.Visible then
                            local txt = desc:IsA("TextLabel") and tostring(desc.Text) or (desc:IsA("TextButton") and tostring(desc.Text) or "")
                            if txt == "ปิด" or txt == "Close" then
                                hideGui = true
                                if desc:IsA("TextButton") then
                                    if getconnections then
                                        for _, conn in pairs(getconnections(desc.MouseButton1Click)) do pcall(function() conn:Fire() end) end
                                        for _, conn in pairs(getconnections(desc.Activated)) do pcall(function() conn:Fire() end) end
                                    elseif firesignal then
                                        pcall(function() firesignal(desc.MouseButton1Click) end)
                                        pcall(function() firesignal(desc.Activated) end)
                                    end
                                end
                            end
                            
                            if txt:find("ITEM COLLECTED") or txt:find("คลิกที่ใดก็ได้เพื่อปิด") then
                                hideGui = true
                                local clickTarget = desc
                                if not clickTarget:IsA("TextButton") and not clickTarget:IsA("ImageButton") then clickTarget = desc.Parent end
                                if clickTarget and (clickTarget:IsA("TextButton") or clickTarget:IsA("ImageButton")) then
                                    if getconnections then
                                        for _, conn in pairs(getconnections(clickTarget.MouseButton1Click)) do pcall(function() conn:Fire() end) end
                                        for _, conn in pairs(getconnections(clickTarget.Activated)) do pcall(function() conn:Fire() end) end
                                    end
                                end
                            end
                        end
                    end
                    
                    local n = string.lower(gui.Name)
                    if n:find("placement") or n:find("preview") or n:find("confirm") or n:find("build") or n:find("craft") or n:find("item") or n:find("reward") or n:find("collected") then
                        hideGui = true
                    end
                    if hideGui then gui.Enabled = false end
                end
            end
        end)
    end
end)


-- ==========================================
-- ♻️ ระบบออโต้รีไซเคิล (Speed Demon - เร็วทะลุจอ)
-- ==========================================
local pRecycle = createTab("ออโต้รีไซเคิล")
_G.AutoRecycle = false

createButton(pRecycle, "📍 1. ตั้งพิกัดตู้ขายขยะ (ยืนหน้าตู้แล้วกด)", function()
    local char = lp.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        local pos = hrp.Position
        _G.SellPlaceArgs = {pos.X, pos.Y, pos.Z}
        sendNotify("สำเร็จ!", "บันทึกพิกัดตู้ขายขยะเรียบร้อย บอทจำตู้ได้แล้ว!")
    else
        sendNotify("ข้อผิดพลาด", "ไม่พบตัวละครของคุณ")
    end
end)

createSwitch(pRecycle, "♻️ 2. เริ่มออโต้รีไซเคิล", "โหมดสปีดหั่นดีเลย์ทิ้ง ขายไวข้ามมิติ!", function(state)
    _G.AutoRecycle = state
    if not state then releaseLock() end 
    
    if state then
        sendNotify("Auto Recycle", "เริ่มโหมด Speed Demon ฟาร์มเร็วจัด!")
        task.spawn(function()
            while _G.AutoRecycle do
                local shouldSell = _G.IsBagFull_ServerSignal 
                local hasFullText = false
                
                -- เช็คข้อความเตือนกระเป๋า
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
                
                -- นับไอคอนกระเป๋า
                local uiBagCount = 0
                pcall(function()
                    for _, gui in pairs(lp.PlayerGui:GetDescendants()) do
                        if gui:IsA("ImageButton") and gui.Name:match("^BagSlot_") and gui.Visible then
                            uiBagCount = uiBagCount + 1
                        end
                    end
                end)

                -- Double Guard
                if uiBagCount == 0 then
                    _G.IsBagFull_ServerSignal = false
                    hasFullText = false
                end

                if uiBagCount >= 12 or (_G.IsBagFull_ServerSignal and uiBagCount > 0) or (hasFullText and uiBagCount > 0) then
                    shouldSell = true
                end
                
                -- ==========================================
                -- ตัดสินใจ: ไปขาย หรือ ไปขุด
                -- ==========================================
                if shouldSell then
                    
                    if not _G.SellPlaceArgs then
                        sendNotify("หาตู้ไม่เจอ!", "โปรดตั้งพิกัดก่อน")
                        _G.AutoRecycle = false
                        releaseLock()
                        break
                    end
                    
                    getLock()
                    
                    -- วาร์ปไปตู้
                    if lp.Character and lp.Character.PrimaryPart then
                        local sPos = Vector3.new(_G.SellPlaceArgs[1], _G.SellPlaceArgs[2], _G.SellPlaceArgs[3])
                        lp.Character:PivotTo(CFrame.new(sPos + Vector3.new(0, 3, 0)))
                        lp.Character.PrimaryPart.Velocity = Vector3.new(0,0,0)
                    end
                    
                    task.wait(0.2) -- ⚡ หั่นดีเลย์ลงจาก 0.6 เหลือ 0.2 วิ (รอโหลดแมพ)
                    
                    local sold = false
                    local closestShopPrompt = nil
                    local minDist = 30 
                    
                    if lp.Character and lp.Character.PrimaryPart then
                        for _, prompt in pairs(workspace:GetDescendants()) do
                            if prompt:IsA("ProximityPrompt") then
                                local pName = string.upper(prompt.Name)
                                local actText = string.upper(prompt.ActionText or "")
                                local objText = string.upper(prompt.ObjectText or "")
                                
                                if not pName:find("BIN") and (prompt:GetAttribute("RecycleSellShop") == true or pName:find("SELL") or actText:find("SELL") or actText:find("ขาย") or objText:find("SELL") or objText:find("ขาย")) then
                                    local pPos = getPromptPos(prompt)
                                    if pPos then
                                        local dist = (pPos - lp.Character.PrimaryPart.Position).Magnitude
                                        if dist < minDist then
                                            minDist = dist
                                            closestShopPrompt = prompt
                                        end
                                    end
                                end
                            end
                        end
                    end
                    
                    if closestShopPrompt then
                        local sellRemote = closestShopPrompt:FindFirstChild("RecycleSellRemote") or closestShopPrompt.Parent:FindFirstChild("RecycleSellRemote", true)
                        if sellRemote then
                            if lp.Character and lp.Character.PrimaryPart then
                                lp.Character.PrimaryPart.Velocity = Vector3.new(0,0,0)
                            end
                            
                            -- กดเปิดตู้ (แค่ให้ระบบเปิดรับคำสั่ง)
                            fireTargetPrompt(closestShopPrompt)
                            task.wait(0.2) -- ⚡ หั่นดีเลย์เมนูเด้งจาก 0.6 เหลือ 0.2
                            
                            -- สาดคอมโบยิงขาย + กดคีย์บอร์ดพร้อมกัน
                            pcall(function() sellRemote:FireServer("SellAll") end)
                            pcall(function()
                                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
                                task.wait(0.01)
                                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
                            end)
                            
                            task.wait(0.1) -- ⚡ หั่นดีเลย์รอขายจาก 0.3 เหลือ 0.1
                            
                            -- รีเฟรชและปิด
                            pcall(function() ReplicatedStorage:WaitForChild("BagRemotes", 2):WaitForChild("GetState", 2):InvokeServer() end)
                            pcall(function()
                                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Four, false, game)
                                task.wait(0.01)
                                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Four, false, game)
                            end)
                            
                            sold = true
                            _G.IsBagFull_ServerSignal = false
                            sendNotify("Recycle Sold", "ขายของความเร็วแสง สำเร็จ!")
                            task.wait(0.1) -- ⚡ หั่นดีเลย์กลับไปขุดจาก 0.5 เหลือ 0.1
                        end
                    end
                    
                    releaseLock()
                    if not sold then task.wait(0.2) end
                    
                else
                    -- หาถังขยะมาขุด
                    local foundBin = false
                    for _, obj in pairs(workspace:GetDescendants()) do
                        if obj.Name == "BIN-RECYCLE" and obj:IsA("Model") then
                            local p = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if p then
                                local pText = tostring(p.ActionText) .. tostring(p.ObjectText) .. tostring(p.Name)
                                if not (pText:find("คูลดาวน์") or pText:find("Cooldown")) then
                                    local pPos = getPromptPos(p)
                                    if pPos then
                                        getLock()
                                        
                                        if lp.Character and lp.Character.PrimaryPart then
                                            local charPos = pPos + Vector3.new(2, 3, 2)
                                            local lookPos = Vector3.new(pPos.X, charPos.Y, pPos.Z)
                                            lp.Character:PivotTo(CFrame.new(charPos, lookPos))
                                            task.wait(0.05)
                                            lp.Character.PrimaryPart.Velocity = Vector3.new(0,0,0)
                                        end
                                        
                                        fireTargetPrompt(p)
                                        
                                        local holdTime = (p.HoldDuration and p.HoldDuration > 0) and p.HoldDuration or 1.5
                                        task.wait(holdTime + 0.1)
                                        
                                        releaseLock()
                                        foundBin = true
                                        break
                                    end
                                end
                            end
                        end
                    end
                    if not foundBin then task.wait(0.2) end
                end
                
                task.wait(0.03) -- ⚡ หั่นลูปทั่วไปให้เช็คไวขึ้น
            end
        end)
    else
        sendNotify("Auto Recycle", "หยุดทำงานแล้ว")
    end
end)

-- ==========================================
-- 🍔 ระบบออโต้แดก (Force Activate + Remote)
-- ==========================================
local pEat = createTab("ออโต้แดก")
_G.AutoBuyEat = false

createSwitch(pEat, "🍔 เริ่มออโต้แดก (ซื้อ+กิน)", "ผสานคำสั่งคลิกกับรีโมท กินชัวร์ 100%", function(state)
    _G.AutoBuyEat = state
    if not state then releaseLock() end 

    if state then
        sendNotify("Auto Eat", "เริ่มโหมดนักล่า! (ถือ -> คลิก -> ยิงรีโมท)")
        task.spawn(function()
            local eatRemote = nil
            pcall(function()
                eatRemote = ReplicatedStorage:WaitForChild("FoodCookingSystem", 5)
                            :WaitForChild("Remotes")
                            :WaitForChild("FoodCooking_EatHeldFood_V1")
            end)

            while _G.AutoBuyEat do
                task.wait(0.03) 
                
                local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then continue end
                
                local holdingFood = false
                local foodToEquip = nil
                
                local function isFoodTool(t)
                    if not t:IsA("Tool") then return false end
                    local n = string.lower(t.Name)
                    if n:find("food") or n:find("soup") or n:find("rice") or n:find("อาหาร") or n:find("ต้มยำ") or n:find("ข้าว") or n:find("prawn") then
                        return true
                    end
                    return false
                end

                pcall(function()
                    -- ถ้าถือของอยู่ สั่ง Activate (จำลองคลิก) เลย
                    for _, v in pairs(lp.Character:GetChildren()) do
                        if isFoodTool(v) then
                            holdingFood = true
                            v:Activate() -- 🔥 คำสั่งหัวใจหลักที่สั่งคลิกให้เข้าปาก
                        end
                    end
                    
                    -- ถ้าไม่ได้ถือ ให้หาในกระเป๋า
                    if not holdingFood then
                        for _, v in pairs(lp.Backpack:GetChildren()) do
                            if isFoodTool(v) then
                                foodToEquip = v
                                break
                            end
                        end
                    end
                end)

                -- สั่งหยิบ
                if foodToEquip then
                    pcall(function() lp.Character.Humanoid:EquipTool(foodToEquip) end)
                    task.wait(0.05)
                    continue
                end

                -- สั่งยิงรีโมทซ้ำเพื่อให้เซิร์ฟเวอร์นับว่ากินแล้ว
                if holdingFood then
                    pcall(function() if eatRemote then eatRemote:InvokeServer() end end)
                    task.wait(0.1) 
                    continue
                end

                -- วิ่งไปซื้อ
                local myFoodPos = Vector3.new(_G.FoodPlaceArgs[1], 0, _G.FoodPlaceArgs[3])
                for _, prompt in pairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                        local actText = string.lower(tostring(prompt.ActionText or ""))
                        local objText = string.lower(tostring(prompt.ObjectText or ""))
                        local pName = string.lower(tostring(prompt.Name or ""))
                        local pModel = prompt:FindFirstAncestorWhichIsA("Model")
                        local mName = pModel and string.lower(pModel.Name) or ""
                        
                        local fullText = actText .. "|" .. objText .. "|" .. pName .. "|" .. mName
                        
                        local isBuy = fullText:find("buy") or fullText:find("ซื้อ") or fullText:find("bkc") or fullText:find("ราคา")
                        local isFood = fullText:find("food") or fullText:find("อาหาร") or fullText:find("soup") 
                            or fullText:find("rice") or fullText:find("dish") or fullText:find("meal")
                            or fullText:find("prawn") or fullText:find("กุ้ง") or fullText:find("ต้มยำ")
                        
                        if isBuy and isFood then
                            local pPos = getPromptPos(prompt)
                            if pPos then
                                local distFromMyStall = (Vector3.new(pPos.X, 0, pPos.Z) - myFoodPos).Magnitude
                                if not _G.IgnoreMyFood or distFromMyStall > 15 then
                                    getLock()
                                    if lp.Character and lp.Character.PrimaryPart then
                                        local charPos = pPos + Vector3.new(2, 3, 2)
                                        local lookPos = Vector3.new(pPos.X, charPos.Y, pPos.Z)
                                        lp.Character:PivotTo(CFrame.new(charPos, lookPos))
                                        lp.Character.PrimaryPart.Velocity = Vector3.new(0,0,0)
                                        task.wait(0.03)
                                    end
                                    fireTargetPrompt(prompt)
                                    task.wait(0.1)
                                    releaseLock()
                                    break 
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

createSwitch(pEat, "🚫 ไม่กินอาหารจากเตาตัวเอง", "ถ้าปิด บอทจะกินทุกจานที่เห็น", function(state)
    _G.IgnoreMyFood = state
end, true)


-- ==========================================
-- 🍳 ระบบทำอาหารอัตโนมัติ
-- ==========================================
local pFood = createTab("ทำอาหาร")
local uiFoodName = "Food-spicy-prawn-soup" 
local uiSaleMode = "Online"
_G.AutoFood = false

createButton(pFood, "📍 ตั้งจุดวางจานตรงที่ยืนอยู่", function()
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

createInput(pFood, "รหัสเมนู", uiFoodName, function(val) uiFoodName = val end)
createSwitch(pFood, "โหมดขาย (เปิด=Online)", "ค่าเริ่มต้นคือ Online อัตโนมัติ", function(state)
    if state then uiSaleMode = "Online" else uiSaleMode = "Villagers" end
end)

createSwitch(pFood, "🍳 เริ่มฟาร์มอาหารออโต้", "ความเร็วแสง (Zero Delay)", function(state)
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


-- ==========================================
-- 🏃 ผู้เล่น (Player Options)
-- ==========================================
local pPlayer = createTab("ตั้งค่าผู้เล่น")
local walkSpeed = 16

createInput(pPlayer, "ความเร็วเดิน (WalkSpeed)", "16", function(val) walkSpeed = tonumber(val) or 16 end)
createSwitch(pPlayer, "ล็อคความเร็วเดิน", "ป้องกันเกมรีเซ็ตความเร็ว", function(state)
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

createSwitch(pPlayer, "ป้องกัน AFK (Anti-AFK)", "ป้องกันโดนเตะเมื่อยืนนิ่งเกิน 20 นาที", function(state)
    _G.AntiAFK = state
    if state then
        sendNotify("Anti-AFK", "เปิดระบบป้องกันโดนเตะออกจากเซิร์ฟเวอร์แล้ว!")
    else
        sendNotify("Anti-AFK", "ปิดระบบป้องกัน AFK")
    end
end)

lp.Idled:Connect(function()
    if _G.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

tabs[1].Btn.TextColor3 = CURRENT.Accent
tabs[1].Page.Visible = true
tabs[1].Ind.Size = UDim2.new(0,3,0,20)
tabs[1].Ind.BackgroundTransparency = 0
