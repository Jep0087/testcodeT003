--// Universal LuaRBX - Thai Edition (Adjustable Stats + Removed Fly/Ghost)
--// Keybind เปิด/ปิดเมนู: J

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local ContextActionService = game:GetService("ContextActionService")

local lp = Players.LocalPlayer
local pg = lp:WaitForChild("PlayerGui")

-- Cleanup
if pg:FindFirstChild("UniversalLuaRBX") then pg.UniversalLuaRBX:Destroy() end
if Lighting:FindFirstChild("SeHubBlur") then Lighting.SeHubBlur:Destroy() end
ContextActionService:UnbindAction("SeHubFlyScroll")

--========================
-- CONFIG SYSTEM
--========================
local FileName = "UniversalLuaRBX_Config.json"
local Config = { Theme = 1, Binds = {} }

local function SaveConfig()
    if writefile then
        pcall(function() writefile(FileName, HttpService:JSONEncode(Config)) end)
    end
end

local function LoadConfig()
    if isfile and isfile(FileName) then
        local success, result = pcall(function() return HttpService:JSONDecode(readfile(FileName)) end)
        if success and result then
            if result.Theme then Config.Theme = result.Theme end
            if result.Binds then for k,v in pairs(result.Binds) do Config.Binds[k] = v end end
        end
    end
end
LoadConfig()

--========================
-- SOUND SYSTEM
--========================
local function playClick(pitch)
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://6351629524"
    s.Volume = 0.5
    s.Pitch = pitch or 1
    s.Parent = SoundService
    s:Play()
    s.Ended:Connect(function() s:Destroy() end)
end

local function playToggleSound()
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://87437544236708"
    s.Volume = 1
    s.Pitch = 1
    s.Parent = SoundService
    s:Play()
    s.Ended:Connect(function() s:Destroy() end)
end

--========================
-- THEME SYSTEM
--========================
local PRESETS = {
    {Name = "Dark Purple", Accent = Color3.fromRGB(150, 100, 255), Bg = Color3.fromRGB(20, 15, 25)},
    {Name = "Orange", Accent = Color3.fromRGB(255, 140, 40), Bg = Color3.fromRGB(25, 25, 28)},
    {Name = "Purple", Accent = Color3.fromRGB(160, 100, 255), Bg = Color3.fromRGB(25, 20, 35)},
    {Name = "Red",    Accent = Color3.fromRGB(255, 60, 60),   Bg = Color3.fromRGB(30, 20, 20)},
    {Name = "Green",  Accent = Color3.fromRGB(60, 255, 120),  Bg = Color3.fromRGB(20, 30, 25)},
    {Name = "Blue",   Accent = Color3.fromRGB(60, 150, 255),  Bg = Color3.fromRGB(20, 25, 35)},
    {Name = "White",  Accent = Color3.fromRGB(220, 220, 220), Bg = Color3.fromRGB(35, 35, 35)},
}

local CURRENT = {Accent = PRESETS[Config.Theme].Accent, Bg = PRESETS[Config.Theme].Bg}
local ThemeObjects = {Accents = {}, Backgrounds = {}, Texts = {}}

local function tween(obj, props, time)
    local t = TweenService:Create(obj, TweenInfo.new(time or 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
    t:Play() return t
end

local function mk(class, props)
    local inst = Instance.new(class)
    for k,v in pairs(props or {}) do inst[k] = v end
    return inst
end

local function SetTheme(themeIndex)
    local theme = PRESETS[themeIndex]
    CURRENT.Accent = theme.Accent
    CURRENT.Bg = theme.Bg
    Config.Theme = themeIndex
    SaveConfig()
    for _, obj in pairs(ThemeObjects.Backgrounds) do tween(obj, {BackgroundColor3 = theme.Bg}) end
    for _, obj in pairs(ThemeObjects.Accents) do
        if not obj:GetAttribute("ArrayItem") then
            if obj:IsA("TextLabel") or obj:IsA("TextButton") then tween(obj, {TextColor3 = theme.Accent})
            elseif obj:IsA("UIStroke") then tween(obj, {Color = theme.Accent})
            else tween(obj, {BackgroundColor3 = theme.Accent}) end
        end
    end
end

--========================
-- Logic Variables
--========================
local espEnabled = false
local espSettings = {Box = true, Name = true, Health = true, Dist = true, Tracer = false, Glow = true}
local espConnection = nil

local noclipEnabled, noclipConnection = false, nil
local flySpeed = 50 
local customWalkSpeed = 16
local customJumpPower = 50

local spinEnabled, spinSpeed, spinBav = false, 20, nil
local fakeLagEnabled, fakeLagConnection = false, nil
local airWalkEnabled, airWalkPart, airWalkConnection = false, nil, nil
local flingEnabled, flingConnection = false, nil

local updateFlySpeedUI = nil

-- บังคับค่า WalkSpeed & JumpPower ป้องกันเกมรีเซ็ต
RunService.Stepped:Connect(function()
    if lp.Character and lp.Character:FindFirstChild("Humanoid") then
        local hum = lp.Character.Humanoid
        if customWalkSpeed ~= 16 then
            hum.WalkSpeed = customWalkSpeed
        end
        if customJumpPower ~= 50 then
            hum.UseJumpPower = true
            hum.JumpPower = customJumpPower
        end
    end
end)

--========================
-- GUI Base
--========================
local gui = mk("ScreenGui", {
    Name = "UniversalLuaRBX", ResetOnSpawn = false, IgnoreGuiInset = true, Parent = pg, ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})

--========================
-- VISUALS: PARTICLES
--========================
local function createParticles(parent, count)
    local amount = count or 40
    local container = mk("Frame", {BackgroundTransparency=1, Size=UDim2.fromScale(1,1), Parent=parent, ZIndex=1})
    for i = 1, amount do
        local size = math.random(2, 4)
        if count then size = math.random(1, 2) end
        local dot = mk("Frame", {
            BackgroundColor3 = Color3.fromRGB(255,255,255), Size = UDim2.fromOffset(size, size),
            Position = UDim2.fromScale(math.random(), math.random()),
            BackgroundTransparency = math.random(7, 9)/10, BorderSizePixel = 0, Parent = container
        })
        mk("UICorner", {Parent=dot, CornerRadius=UDim.new(1,0)})
        task.spawn(function()
            while dot.Parent do
                local targetPos = UDim2.fromScale(math.random(), math.random())
                local speed = math.random(10, 25)
                local t1 = TweenService:Create(dot, TweenInfo.new(speed, Enum.EasingStyle.Linear), {Position = targetPos})
                task.spawn(function()
                    while dot.Parent do
                        TweenService:Create(dot, TweenInfo.new(2), {BackgroundTransparency = math.random(5,9)/10}):Play()
                        task.wait(math.random(2,5))
                    end
                end)
                t1:Play() t1.Completed:Wait()
            end
        end)
    end
end

--========================
-- ARRAY LIST
--========================
local arrayList = mk("Frame", {
    Name = "ArrayList", Position = UDim2.new(1, -10, 0, 10), Size = UDim2.new(0, 300, 1, 0),
    AnchorPoint = Vector2.new(1, 0), BackgroundTransparency = 1, Parent = gui
})
mk("UIListLayout", {Parent=arrayList, HorizontalAlignment=Enum.HorizontalAlignment.Right, VerticalAlignment=Enum.VerticalAlignment.Top, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,2)})

local function updateArray(name, state)
    local existing = arrayList:FindFirstChild(name)
    if state then
        if not existing then
            playToggleSound()
            local card = mk("Frame", {
                Name = name, BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 0.1,
                Size = UDim2.new(0, 0, 0, 24), BorderSizePixel = 0, ClipsDescendants = true, Parent = arrayList
            })
            mk("UICorner", {Parent=card, CornerRadius=UDim.new(0,4)})
            createParticles(card, 10)
            local txt = mk("TextLabel", {
                Text = name, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.new(1,1,1),
                BackgroundTransparency = 1, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
                Position = UDim2.new(0, 0, 0, 0), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 2, Parent = card
            })
            txt:SetAttribute("ArrayItem", true)
            local grad = Instance.new("UIGradient", txt) grad.Name = "Shimmer"
            mk("UIPadding", {Parent=card, PaddingLeft=UDim.new(0,5), PaddingRight=UDim.new(0,5)})
            local targetWidth = txt.TextBounds.X + 10
            card.Size = UDim2.new(0, 0, 0, 24)
            tween(card, {Size = UDim2.new(0, targetWidth, 0, 24)}, 0.3)
        end
    else
        if existing then
            local t = tween(existing, {Size = UDim2.new(0, 0, 0, 24)}, 0.25)
            t.Completed:Connect(function() existing:Destroy() end)
        end
    end
end

RunService.RenderStepped:Connect(function()
    local children = {}
    for _, child in pairs(arrayList:GetChildren()) do if child:IsA("Frame") then table.insert(children, child) end end
    table.sort(children, function(a, b)
        local tA = a:FindFirstChild("TextLabel") local tB = b:FindFirstChild("TextLabel")
        if tA and tB then return tA.TextBounds.X > tB.TextBounds.X end return false
    end)
    local mainColor = CURRENT.Accent
    local h, s, v = mainColor:ToHSV()
    local lightColor = Color3.fromHSV(h, math.max(0, s - 0.6), 1)
    local shimmerSeq = ColorSequence.new({
        ColorSequenceKeypoint.new(0, mainColor), ColorSequenceKeypoint.new(0.5, lightColor), ColorSequenceKeypoint.new(1, mainColor)
    })
    local offset = (tick() * 0.8) % 1
    for i, card in ipairs(children) do
        card.LayoutOrder = i
        local txt = card:FindFirstChild("TextLabel")
        if txt then
            local grad = txt:FindFirstChild("Shimmer")
            if grad then grad.Color = shimmerSeq grad.Offset = Vector2.new(-1 + (offset * 2.5), 0) end
        end
    end
end)

--========================
-- ADVANCED ESP LOGIC
--========================
local espContainer = mk("Folder", {Name = "ESP_Container", Parent = gui})

local function DrawESP(plr)
    local success, err = pcall(function()
        if not espEnabled then return end
        if plr == lp then return end
        local char = plr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        local tag = espContainer:FindFirstChild(plr.Name)
        if not char or not root or not hum or hum.Health <= 0 then
            if tag then tag.Visible = false end
            if char and char:FindFirstChild("SeHighlight") then char.SeHighlight:Destroy() end
            return
        end
        local espColor = CURRENT.Accent
        if lp.Team and plr.Team and lp.Team == plr.Team then espColor = Color3.fromRGB(40, 255, 60) end
        if espSettings.Glow then
            if not char:FindFirstChild("SeHighlight") then
                local hl = Instance.new("Highlight", char) hl.Name = "SeHighlight" hl.FillColor = espColor hl.OutlineColor = Color3.new(1,1,1) hl.FillTransparency = 0.5
            else char.SeHighlight.FillColor = espColor end
        else if char:FindFirstChild("SeHighlight") then char.SeHighlight:Destroy() end end
        if not tag then
            tag = mk("Frame", {Name=plr.Name, BackgroundTransparency=1, Size=UDim2.fromScale(1,1), Parent=espContainer, Visible=false})
            local box = mk("Frame", {Name="Box", BackgroundTransparency=1, BorderSizePixel=0, Parent=tag, Visible=false}) mk("UIStroke", {Parent=box, Color=espColor, Thickness=1})
            local hpBarBg = mk("Frame", {Name="HealthBg", BackgroundColor3=Color3.new(0,0,0), BorderSizePixel=0, Parent=tag, Visible=false, ZIndex=2})
            local hpBar = mk("Frame", {Name="Bar", BackgroundColor3=Color3.new(0,1,0), BorderSizePixel=0, Parent=hpBarBg, ZIndex=3})
            local name = mk("TextLabel", {Name="Name", Text=plr.DisplayName, TextSize=11, Font=Enum.Font.GothamBold, TextColor3=Color3.new(1,1,1), BackgroundTransparency=1, Parent=tag, Visible=false, ZIndex=4}) mk("UIStroke", {Parent=name, Thickness=1, TextStrokeTransparency=0})
            local line = mk("Frame", {Name="Tracer", BackgroundColor3=espColor, BorderSizePixel=0, AnchorPoint=Vector2.new(0.5,0.5), Parent=tag, Visible=false})
        end
        tag.Visible = true
        local box = tag:FindFirstChild("Box") local hpBg = tag:FindFirstChild("HealthBg") local hpBar = hpBg and hpBg:FindFirstChild("Bar") local name = tag:FindFirstChild("Name") local line = tag:FindFirstChild("Tracer")
        if not box or not hpBg or not name then return end
        if box then box.UIStroke.Color = espColor end if line then line.BackgroundColor3 = espColor end
        local cam = workspace.CurrentCamera
        local pos, onScreen = cam:WorldToViewportPoint(root.Position)
        if onScreen then
            local dist = (cam.CFrame.Position - root.Position).Magnitude
            local fov = math.tan(math.rad(cam.FieldOfView * 0.5))
            local scale = 1000 / ((dist * fov) + 0.01)
            local h = scale * 2.5
            local w = h * 0.7
            if espSettings.Box then box.Visible = true box.Size = UDim2.fromOffset(w, h) box.Position = UDim2.fromOffset(pos.X - (w/2), pos.Y - (h/2)) else box.Visible = false end
            if espSettings.Health then
                hpBg.Visible = true
                local maxHp = hum.MaxHealth if maxHp <= 0 then maxHp = 100 end
                local healthPct = math.clamp(hum.Health / maxHp, 0, 1)
                local barH = h * healthPct
                hpBg.Size = UDim2.fromOffset(2, h) hpBg.Position = UDim2.fromOffset(pos.X - (w/2) - 5, pos.Y - (h/2))
                hpBar.Size = UDim2.fromOffset(2, barH) hpBar.Position = UDim2.fromScale(0, 1 - healthPct) hpBar.BackgroundColor3 = Color3.fromHSV(healthPct * 0.3, 1, 1)
            else hpBg.Visible = false end

            if espSettings.Name or espSettings.Dist then
                name.Visible = true
                local str = "" if espSettings.Name then str = plr.DisplayName end
                if espSettings.Dist then if espSettings.Name then str = str .. " " end str = str .. string.format("[%dm]", math.floor(dist)) end
                name.Text = str name.Position = UDim2.fromOffset(pos.X - (name.TextBounds.X/2), pos.Y - (h/2) - 16)
            else name.Visible = false end
            if espSettings.Tracer then
                line.Visible = true
                local origin = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y)
                local to = Vector2.new(pos.X, pos.Y + (h/2))
                local center = (origin + to) / 2
                local length = (origin - to).Magnitude
                local angle = math.atan2(to.Y - origin.Y, to.X - origin.X)
                line.Size = UDim2.fromOffset(length, 1) line.Position = UDim2.fromOffset(center.X, center.Y) line.Rotation = math.deg(angle)
            else line.Visible = false end
        else
            box.Visible = false; hpBg.Visible = false; name.Visible = false; line.Visible = false
        end
    end)
    if not success then warn("ESP Fail:", err) end
end

local function toggleESP(state)
    espEnabled = state
    if state then
        if espConnection then espConnection:Disconnect() end
        espContainer:ClearAllChildren()
        espConnection = RunService.RenderStepped:Connect(function() for _, p in pairs(Players:GetPlayers()) do DrawESP(p) end end)
    else
        if espConnection then espConnection:Disconnect() end
        espContainer:ClearAllChildren()
        for _, p in pairs(Players:GetPlayers()) do if p.Character and p.Character:FindFirstChild("SeHighlight") then p.Character.SeHighlight:Destroy() end end
    end
end

--========================
-- Other Logic
--========================
local function toggleNoclip(state)
    noclipEnabled = state
    if state then
        noclipConnection = RunService.Stepped:Connect(function()
            if lp.Character then for _, part in pairs(lp.Character:GetDescendants()) do if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end end end
        end)
    else if noclipConnection then noclipConnection:Disconnect() end end
end

local function handleFlyScroll(actionName, inputState, inputObject)
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        if inputObject.Position.Z ~= 0 then
            local change = (inputObject.Position.Z > 0) and 3 or -3
            flySpeed = math.clamp(flySpeed + change, 10, 1000)
            if updateFlySpeedUI then updateFlySpeedUI(flySpeed) end
        end
        return Enum.ContextActionResult.Sink
    end
    return Enum.ContextActionResult.Pass
end
ContextActionService:BindActionAtPriority("SeHubFlyScroll", handleFlyScroll, false, 3000, Enum.UserInputType.MouseWheel)

local function toggleAirWalk(state)
    airWalkEnabled = state
    if state then
        local char = lp.Character local root = char and char:FindFirstChild("HumanoidRootPart") local hum = char and char:FindFirstChild("Humanoid")
        if not root or not hum then return end
        local startY = root.Position.Y - (hum.HipHeight + (root.Size.Y / 2)) - 1.0
        airWalkPart = Instance.new("Part") airWalkPart.Name = "SeAirWalk" airWalkPart.Anchored = true airWalkPart.CanCollide = true airWalkPart.Transparency = 1 airWalkPart.Size = Vector3.new(100, 1, 100) airWalkPart.Position = Vector3.new(root.Position.X, startY, root.Position.Z) airWalkPart.Parent = workspace
        airWalkConnection = RunService.Heartbeat:Connect(function()
            if airWalkPart and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                local pp = lp.Character.HumanoidRootPart.Position airWalkPart.Position = Vector3.new(pp.X, startY, pp.Z)
            end
        end)
    else if airWalkConnection then airWalkConnection:Disconnect() end if airWalkPart then airWalkPart:Destroy() end end
end

local function toggleFling(state)
    flingEnabled = state
    if state then
        flingConnection = RunService.Stepped:Connect(function()
            local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") if not root then return end
            local target = nil
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = (p.Character.HumanoidRootPart.Position - root.Position).Magnitude
                    if dist < 5 then target = p.Character.HumanoidRootPart break end
                end
            end
            if target then
                root.AssemblyAngularVelocity = Vector3.new(10000, 25000, 10000)
                root.CFrame = CFrame.new(target.Position) * root.CFrame.Rotation * CFrame.new(math.random(-1,1)/10, 0, math.random(-1,1)/10)
                root.AssemblyLinearVelocity = Vector3.zero
            else root.AssemblyAngularVelocity = Vector3.zero end
        end)
    else
        if flingConnection then flingConnection:Disconnect() end
        if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then lp.Character.HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero end
    end
end

local function toggleSpin(state)
    spinEnabled = state
    local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if state and root then
        if root:FindFirstChild("SeSpin") then root.SeSpin:Destroy() end
        spinBav = Instance.new("BodyAngularVelocity", root) spinBav.Name = "SeSpin" spinBav.MaxTorque = Vector3.new(0, math.huge, 0) spinBav.AngularVelocity = Vector3.new(0, spinSpeed, 0)
    else if spinBav then spinBav:Destroy() end end
end

local function toggleFakeLag(state)
    fakeLagEnabled = state
    if state then
        local tick = 0
        fakeLagConnection = RunService.Heartbeat:Connect(function()
            tick = tick + 1
            local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if root and tick % 12 == 0 then
                root.Anchored = true task.delay(0.1, function() if root then root.Anchored = false end end)
            end
        end)
    else if fakeLagConnection then fakeLagConnection:Disconnect() end if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then lp.Character.HumanoidRootPart.Anchored = false end end
end

lp.CharacterAdded:Connect(function()
    spinEnabled, fakeLagEnabled, airWalkEnabled, flingEnabled = false, false, false, false
    if airWalkPart then airWalkPart:Destroy() end 
end)

--========================
-- MAIN GUI
--========================
local notifyContainer = mk("Frame", {Name = "Notify", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -20, 1, -50), Size = UDim2.new(0, 250, 0, 400), BackgroundTransparency = 1, Parent = gui, ZIndex=10})
mk("UIListLayout", {Parent=notifyContainer, VerticalAlignment=Enum.VerticalAlignment.Bottom, Padding=UDim.new(0,10)})

local function sendNotify(title, msg)
    local f = mk("Frame", {BackgroundColor3 = Color3.fromRGB(20,20,23), Size = UDim2.new(1,0,0,0), ClipsDescendants = true, Parent = notifyContainer})
    mk("UICorner", {Parent=f, CornerRadius=UDim.new(0,8)})
    local str = mk("UIStroke", {Parent=f, Color=CURRENT.Accent, Thickness=1, Transparency=0.5})
    table.insert(ThemeObjects.Accents, str)
    mk("TextLabel", {Text=title, Font=Enum.Font.GothamBold, TextSize=13, TextColor3=CURRENT.Accent, BackgroundTransparency=1, Position=UDim2.new(0,12,0,8), Size=UDim2.new(1,-24,0,16), TextXAlignment=Enum.TextXAlignment.Left, Parent=f})
    mk("TextLabel", {Text=msg, Font=Enum.Font.Gotham, TextSize=12, TextColor3=Color3.fromRGB(240,240,240), BackgroundTransparency=1, Position=UDim2.new(0,12,0,24), Size=UDim2.new(1,-24,0,20), TextXAlignment=Enum.TextXAlignment.Left, Parent=f})
    tween(f, {Size = UDim2.new(1,0,0,55)}, 0.3)
    task.delay(3, function() if f then local out = tween(f, {Size = UDim2.new(1,0,0,0), BackgroundTransparency=1}, 0.3) out.Completed:Connect(function() f:Destroy() end) end end)
end

-- Window
local window = mk("Frame", {
    Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(500, 340),
    BackgroundColor3 = CURRENT.Bg, BackgroundTransparency = 0.02,
    Active = true, ClipsDescendants = true, Parent = gui
})
mk("UICorner", {Parent=window, CornerRadius=UDim.new(0,10)})
local wStroke = mk("UIStroke", {Parent=window, Color=Color3.fromRGB(60,60,65), Thickness=1, Transparency=0.4})
table.insert(ThemeObjects.Backgrounds, window)

createParticles(window)

-- Topbar
local top = mk("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), Parent = window})

mk("TextLabel", {Text = "LuaRBX (TH)", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Color3.fromRGB(240,240,240), BackgroundTransparency = 1, Position = UDim2.new(0, 15, 0, 0), Size = UDim2.new(0, 100, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = top})

local profileContainer = mk("Frame", {Name = "Profile", BackgroundColor3 = Color3.fromRGB(25,25,28), BackgroundTransparency = 1, Size = UDim2.fromOffset(30, 30), Position = UDim2.new(0, 115, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), ClipsDescendants = true, Parent = top})
local iconId = "rbxassetid://0" pcall(function() iconId = Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48) end)
local userAvatar = mk("ImageLabel", {Name = "Avatar", Image = iconId, BackgroundTransparency = 1, Size = UDim2.fromOffset(26, 26), Position = UDim2.new(0, 2, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Parent = profileContainer})
mk("UICorner", {Parent = userAvatar, CornerRadius = UDim.new(0, 6)})
local avaStroke = mk("UIStroke", {Parent = userAvatar, Thickness = 1.5, Color = CURRENT.Accent, Transparency = 0})
table.insert(ThemeObjects.Accents, avaStroke)
local userName = mk("TextLabel", {Text = lp.DisplayName, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.fromRGB(220,220,220), BackgroundTransparency = 1, Position = UDim2.new(0, 34, 0, 0), Size = UDim2.new(0, 100, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, Parent = profileContainer})

profileContainer.MouseEnter:Connect(function() tween(profileContainer, {Size = UDim2.fromOffset(34 + userName.TextBounds.X + 10, 30)}, 0.3) tween(userName, {TextTransparency = 0}, 0.3) end)
profileContainer.MouseLeave:Connect(function() tween(profileContainer, {Size = UDim2.fromOffset(30, 30)}, 0.3) tween(userName, {TextTransparency = 1}, 0.2) end)

local minBtn = mk("TextButton", {Text = "-", Font=Enum.Font.GothamBold, TextSize=22, TextColor3=Color3.fromRGB(150,150,150), BackgroundTransparency=1, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-12,0.5,0), Size=UDim2.fromOffset(30,30), Parent=top})
local headerStatus = mk("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(0, 200, 1, 0), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -50, 0, 0), Font = Enum.Font.Code, TextSize = 11, TextColor3 = Color3.fromRGB(150,150,150), TextXAlignment = Enum.TextXAlignment.Right, Visible = false, Text = "...", Parent = top})
local topSep = mk("Frame", {BackgroundColor3 = Color3.fromRGB(60,60,65), BorderSizePixel=0, Position=UDim2.new(0,0,0,40), Size=UDim2.new(1,0,0,1), Parent=window})

-- Footer
local footer = mk("Frame", {BackgroundTransparency = 1, Position = UDim2.new(0, 0, 1, -25), Size = UDim2.new(1, 0, 0, 25), Parent = window})
mk("Frame", {BackgroundColor3 = Color3.fromRGB(60,60,65), BorderSizePixel=0, Position=UDim2.new(0,0,0,0), Size=UDim2.new(1,0,0,1), Parent=footer})

})

tgLink.MouseButton1Click:Connect(function()
    pcall(function()
        if setclipboard then setclipboard("https://t.me/LuaRobloxScripts")
        elseif ClipboardService then ClipboardService:SetAsync("https://t.me/LuaRobloxScripts")
        else game:GetService("Clipboard"):SetAsync("https://t.me/LuaRobloxScripts") end
        sendNotify("คัดลอกแล้ว!", "คัดลอกลิงก์ลงคลิปบอร์ดแล้ว")
    end)
end)

local footerStatus = mk("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -140, 1, 0),
    Position = UDim2.new(0, 135, 0, 0),
    Font = Enum.Font.Code,
    TextSize = 11,
    TextColor3 = Color3.fromRGB(150,150,150),
    TextXAlignment = Enum.TextXAlignment.Right,
    Text = "กำลังโหลด...",
    Parent = footer
})

local startTime = os.time()
task.spawn(function()
    while window.Parent do
        local fps = math.floor(workspace:GetRealPhysicsFPS())
        local ping = 0
        pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValueString():match("%d+")) end)
        local currentTime = os.time()
        local elapsed = currentTime - startTime
        local minutes = math.floor(elapsed / 60)
        local text = string.format("FPS: %d | Ping: %dms | Session: %dm", fps, ping, minutes)
        footerStatus.Text = text
        headerStatus.Text = text
        task.wait(1)
    end
end)

-- Layout Structure
local content = mk("Frame", {BackgroundTransparency = 1, Position=UDim2.new(0,0,0,41), Size=UDim2.new(1,0,1,-66), Parent=window, ZIndex=2})
local sidebar = mk("Frame", {BackgroundTransparency=1, Size=UDim2.new(0,140,1,0), Parent=content})
local pagesHost = mk("Frame", {BackgroundTransparency=1, Position=UDim2.new(0,140,0,0), Size=UDim2.new(1,-140,1,0), Parent=content})
local tabContainer = mk("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,1,-45), Parent=sidebar})
mk("UIListLayout", {Parent=tabContainer, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,6)})
mk("UIPadding", {Parent=tabContainer, PaddingTop=UDim.new(0,10), PaddingLeft=UDim.new(0,10)})
local setContainer = mk("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,45), Position=UDim2.new(0,0,1,-45), Parent=sidebar})
mk("Frame", {BackgroundColor3=Color3.fromRGB(60,60,65), BorderSizePixel=0, Size=UDim2.new(1,0,0,1), Parent=setContainer})

--========================
-- Components
--========================
local tabs = {}
local function createTab(name, parent)
    local btn = mk("TextButton", {
        Text = name, Font=Enum.Font.GothamMedium, TextSize=13, TextColor3=Color3.fromRGB(150,150,150),
        BackgroundTransparency=1, Size=UDim2.new(1,0,0,32), TextXAlignment=Enum.TextXAlignment.Left, Parent=parent or tabContainer
    })
    mk("UIPadding", {Parent=btn, PaddingLeft=UDim.new(0, 15)})
    local indicator = mk("Frame", {BackgroundColor3 = CURRENT.Accent, Size = UDim2.new(0, 3, 0, 0), Position = UDim2.new(0, -10, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BorderSizePixel = 0, BackgroundTransparency = 1, Parent = btn})
    mk("UICorner", {Parent=indicator, CornerRadius=UDim.new(1,0)}) table.insert(ThemeObjects.Accents, indicator)
    local page = mk("ScrollingFrame", {Visible=false, BackgroundTransparency=1, Size=UDim2.fromScale(1,1), CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y, ScrollBarThickness=2, ScrollBarImageColor3=Color3.fromRGB(150,150,150), BorderSizePixel=0, Parent=pagesHost})
    mk("UIListLayout", {Parent=page, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,10)})
    mk("UIPadding", {Parent=page, PaddingTop=UDim.new(0,10), PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,5)})
    btn.MouseButton1Click:Connect(function()
        playClick(1) for _,t in pairs(tabs) do tween(t.Btn, {TextColor3=Color3.fromRGB(150,150,150)}) tween(t.Ind, {Size=UDim2.new(0,3,0,0), BackgroundTransparency=1}) t.Page.Visible = false end
        tween(btn, {TextColor3=CURRENT.Accent}) tween(indicator, {Size=UDim2.new(0,3,0,20), BackgroundTransparency=0}) page.Visible = true
    end)
    table.insert(tabs, {Btn=btn, Page=page, Ind=indicator}) return page
end

local function createSwitch(parent, text, callback)
    local c = mk("Frame", {BackgroundColor3 = Color3.fromRGB(35,35,38), Size=UDim2.new(1,-10,0,44), Parent=parent})
    mk("UICorner", {Parent=c, CornerRadius=UDim.new(0,8)})
    mk("TextLabel", {Text = text, Font=Enum.Font.GothamMedium, TextSize=13, TextColor3=Color3.fromRGB(240,240,240), BackgroundTransparency=1, Position=UDim2.new(0,15,0,0), Size=UDim2.new(0.6,0,1,0), TextXAlignment=Enum.TextXAlignment.Left, Parent=c})
    
    local savedKey = Config.Binds[text] local displayKey = savedKey and "["..savedKey.."]" or ""
    local bindLabel = mk("TextLabel", {Text=displayKey, Font=Enum.Font.GothamBold, TextSize=11, TextColor3=Color3.fromRGB(150,150,150), BackgroundTransparency=1, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-65,0.5,0), Size=UDim2.new(0,40,1,0), TextXAlignment=Enum.TextXAlignment.Right, Parent=c})
    local sw = mk("TextButton", {Text = "", AutoButtonColor=false, BackgroundColor3=Color3.fromRGB(50,50,55), AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-15,0.5,0), Size=UDim2.fromOffset(40, 20), Parent=c})
    mk("UICorner", {Parent=sw, CornerRadius=UDim.new(1,0)})
    local circ = mk("Frame", {BackgroundColor3 = Color3.new(1,1,1), Size=UDim2.fromOffset(14,14), AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,3,0.5,0), Parent=sw})
    mk("UICorner", {Parent=circ, CornerRadius=UDim.new(1,0)})
    local on = false local bind = savedKey and Enum.KeyCode[savedKey] or nil
    local function doToggle()
        on = not on
        if on then playClick(1.1) tween(sw, {BackgroundColor3 = CURRENT.Accent}) tween(circ, {Position = UDim2.new(1, -17, 0.5, 0)}) sendNotify("เปิดใช้งาน", text)
        else playClick(0.9) tween(sw, {BackgroundColor3 = Color3.fromRGB(50,50,55)}) tween(circ, {Position = UDim2.new(0, 3, 0.5, 0)}) sendNotify("ปิดใช้งาน", text) end
        updateArray(text, on) if callback then callback(on) end
    end
    sw.MouseButton1Click:Connect(doToggle)
    sw.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            bindLabel.Text = "[...]" bindLabel.TextColor3 = CURRENT.Accent local conn conn = UserInputService.InputBegan:Connect(function(key) if key.UserInputType == Enum.UserInputType.Keyboard then if key.KeyCode == Enum.KeyCode.Backspace then bind = nil bindLabel.Text = "" Config.Binds[text] = nil else bind = key.KeyCode bindLabel.Text = "["..key.KeyCode.Name.."]" Config.Binds[text] = key.KeyCode.Name end SaveConfig() bindLabel.TextColor3 = Color3.fromRGB(150,150,150) conn:Disconnect() elseif key.UserInputType == Enum.UserInputType.MouseButton1 then bindLabel.Text = bind and ("["..bind.Name.."]") or "" bindLabel.TextColor3 = Color3.fromRGB(150,150,150) conn:Disconnect() end end)
        end
    end)
    UserInputService.InputBegan:Connect(function(input, gp) if not gp and bind and input.KeyCode == bind then doToggle() end end)
end

local function createEspControl(parent, callback)
    local text = "ESP ผู้เล่น" local c = mk("Frame", {BackgroundColor3 = Color3.fromRGB(35,35,38), Size = UDim2.new(1, -10, 0, 44), ClipsDescendants = true, Parent = parent})
    mk("UICorner", {Parent=c, CornerRadius=UDim.new(0,8)})
    mk("TextLabel", {Text = text, Font=Enum.Font.GothamMedium, TextSize=13, TextColor3=Color3.fromRGB(240,240,240), BackgroundTransparency=1, Position=UDim2.new(0,15,0,0), Size=UDim2.new(0.6,0,0,44), TextXAlignment=Enum.TextXAlignment.Left, Parent=c})
    local savedKey = Config.Binds[text] local displayKey = savedKey and "["..savedKey.."]" or ""
    local bindLabel = mk("TextLabel", {Text=displayKey, Font=Enum.Font.GothamBold, TextSize=11, TextColor3=Color3.fromRGB(150,150,150), BackgroundTransparency=1, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-65,0,22), Size=UDim2.new(0,40,0,44), TextXAlignment=Enum.TextXAlignment.Right, Parent=c})

    local sw = mk("TextButton", {Text = "", AutoButtonColor=false, BackgroundColor3=Color3.fromRGB(50,50,55), AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-15,0,12), Size=UDim2.fromOffset(40, 20), Parent=c})
    mk("UICorner", {Parent=sw, CornerRadius=UDim.new(1,0)})
    local circ = mk("Frame", {BackgroundColor3 = Color3.new(1,1,1), Size=UDim2.fromOffset(14,14), AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,3,0.5,0), Parent=sw})
    mk("UICorner", {Parent=circ, CornerRadius=UDim.new(1,0)})

    local subRow = mk("Frame", {BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 46), Size = UDim2.new(1, 0, 0, 30), Parent = c})
    mk("UIListLayout", {Parent = subRow, FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8)})

    local function createChip(text, settingKey)
        local btn = mk("TextButton", {Text = text, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = espSettings[settingKey] and Color3.new(1,1,1) or Color3.fromRGB(120,120,120), BackgroundColor3 = espSettings[settingKey] and CURRENT.Accent or Color3.fromRGB(45,45,48), Size = UDim2.fromOffset(55, 24), AutoButtonColor = false, Parent = subRow})
        mk("UICorner", {Parent=btn, CornerRadius=UDim.new(0, 6)}) if espSettings[settingKey] then table.insert(ThemeObjects.Accents, btn) end
        btn.MouseButton1Click:Connect(function()
            playClick(1) espSettings[settingKey] = not espSettings[settingKey]
            if espSettings[settingKey] then tween(btn, {BackgroundColor3 = CURRENT.Accent, TextColor3 = Color3.new(1,1,1)}) table.insert(ThemeObjects.Accents, btn) else tween(btn, {BackgroundColor3 = Color3.fromRGB(45,45,48), TextColor3 = Color3.fromRGB(120,120,120)}) end
        end)
    end
    createChip("กล่อง", "Box") createChip("ชื่อ", "Name") createChip("เลือด", "Health") createChip("ระยะ", "Dist")

    local on = false local bind = savedKey and Enum.KeyCode[savedKey] or nil
    local function doToggle()
        on = not on
        if on then playClick(1.1) tween(sw, {BackgroundColor3 = CURRENT.Accent}) tween(circ, {Position = UDim2.new(1, -17, 0.5, 0)}) tween(c, {Size = UDim2.new(1, -10, 0, 84)}, 0.4) sendNotify("เปิดใช้งาน", text)
        else playClick(0.9) tween(sw, {BackgroundColor3 = Color3.fromRGB(50,50,55)}) tween(circ, {Position = UDim2.new(0, 3, 0.5, 0)}) tween(c, {Size = UDim2.new(1, -10, 0, 44)}, 0.4) sendNotify("ปิดใช้งาน", text) end
        updateArray(text, on) callback(on)
    end
    sw.MouseButton1Click:Connect(doToggle)
    sw.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            bindLabel.Text = "[...]" bindLabel.TextColor3 = CURRENT.Accent local conn conn = UserInputService.InputBegan:Connect(function(key) if key.UserInputType == Enum.UserInputType.Keyboard then if key.KeyCode == Enum.KeyCode.Backspace then bind = nil bindLabel.Text = "" Config.Binds[text] = nil else bind = key.KeyCode bindLabel.Text = "["..key.KeyCode.Name.."]" Config.Binds[text] = key.KeyCode.Name end SaveConfig() bindLabel.TextColor3 = Color3.fromRGB(150,150,150) conn:Disconnect() elseif key.UserInputType == Enum.UserInputType.MouseButton1 then bindLabel.Text = bind and ("["..bind.Name.."]") or "" bindLabel.TextColor3 = Color3.fromRGB(150,150,150) conn:Disconnect() end end)
        end
    end)
    UserInputService.InputBegan:Connect(function(input, gp) if not gp and bind and input.KeyCode == bind then doToggle() end end)
end

-- ระบบปรับค่าแบบใหม่ (มีปุ่ม + / - เพื่อให้กดบนมือถือง่ายขึ้น)
local function createDragValue(parent, text, min, max, def, callback)
    local c = mk("Frame", {BackgroundColor3=Color3.fromRGB(35,35,38), Size=UDim2.new(1,-10,0,44), Parent=parent})
    mk("UICorner", {Parent=c, CornerRadius=UDim.new(0,8)})
    mk("TextLabel", {Text=text, Font=Enum.Font.GothamMedium, TextSize=13, TextColor3=Color3.fromRGB(240,240,240), BackgroundTransparency=1, Position=UDim2.new(0,15,0,0), Size=UDim2.new(0.4,0,1,0), TextXAlignment=Enum.TextXAlignment.Left, Parent=c})
    
    -- ปุ่มแสดงตัวเลขตรงกลาง
    local btn = mk("TextButton", {Text=tostring(def), Font=Enum.Font.GothamBold, TextSize=14, TextColor3=CURRENT.Accent, BackgroundColor3=Color3.fromRGB(25,25,28), Size=UDim2.new(0,50,0,24), AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-45,0.5,0), AutoButtonColor=false, Parent=c})
    mk("UICorner", {Parent=btn, CornerRadius=UDim.new(0,6)})
    mk("UIStroke", {Parent=btn, Color=Color3.fromRGB(60,60,65), Thickness=1, Transparency=0.5}) table.insert(ThemeObjects.Accents, btn)
    
    -- ปุ่มลบ (-)
    local minusBtn = mk("TextButton", {Text="-", Font=Enum.Font.GothamBold, TextSize=22, TextColor3=Color3.fromRGB(255,80,80), BackgroundTransparency=1, Size=UDim2.new(0,30,0,30), AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-100,0.5,0), Parent=c})
    -- ปุ่มบวก (+)
    local plusBtn = mk("TextButton", {Text="+", Font=Enum.Font.GothamBold, TextSize=22, TextColor3=Color3.fromRGB(80,255,120), BackgroundTransparency=1, Size=UDim2.new(0,30,0,30), AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-10,0.5,0), Parent=c})
    
    if text == "ความเร็วบิน" then
        updateFlySpeedUI = function(v) btn.Text = tostring(v) end
    end
    
    local val = def
    
    local function updateVal(newVal)
        val = math.clamp(newVal, min, max)
        btn.Text = tostring(val)
        callback(val)
    end
    
    minusBtn.MouseButton1Click:Connect(function() playClick(1) updateVal(val - 1) end)
    plusBtn.MouseButton1Click:Connect(function() playClick(1) updateVal(val + 1) end)
    
    -- หากต้องการพิมพ์ตัวเลข ก็ยังสามารถกดที่ตัวเลขตรงกลางได้
    btn.MouseButton1Click:Connect(function()
        playClick(1)
        local box = mk("TextBox", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="", PlaceholderText="#", TextColor3=CURRENT.Accent, Font=Enum.Font.GothamBold, TextSize=14, Parent=btn}) 
        box:CaptureFocus() 
        box.FocusLost:Connect(function(e) 
            if tonumber(box.Text) then updateVal(tonumber(box.Text)) end 
            box:Destroy() 
        end)
    end)
end

--========================
-- Build Content
--========================
local pCombat = createTab("ต่อสู้")
local pTeleport = createTab("เทเลพอร์ต")
local pWaypoints = createTab("จุดวาร์ป")
local pFunny = createTab("พิเศษ")
local pSettings = createTab("ตั้งค่า", setContainer)
local setBtn = tabs[#tabs].Btn
setBtn.Size = UDim2.new(1,0,1,0) setBtn.Position = UDim2.new(0,0,0,0)

-- > COMBAT TAB (หน้าต่อสู้ลบ Ghost และ Fly ออกไปตามคำสั่ง)
createEspControl(pCombat, function(v) toggleESP(v) end)

-- เลื่อนแถบปรับความเร็วขึ้นมาแทนที่
createDragValue(pCombat, "ความเร็วบิน", 10, 1000, 50, function(v) flySpeed = v end)
createDragValue(pCombat, "ความเร็วเดิน (ล็อค)", 16, 250, 16, function(v) customWalkSpeed = v end)
createDragValue(pCombat, "พลังกระโดด (ล็อค)", 50, 350, 50, function(v) customJumpPower = v end)

createSwitch(pCombat, "ทะลุกำแพง (Noclip)", function(v) toggleNoclip(v) end)
createSwitch(pCombat, "เดินบนอากาศ (Air Walk)", function(v) toggleAirWalk(v) end)
createSwitch(pCombat, "ป่วนผู้เล่น (TP Fling)", function(v) toggleFling(v) end)

-- > FUNNY TAB
createSwitch(pFunny, "หมุนตัว (SpinBot)", function(v) toggleSpin(v) end)
createDragValue(pFunny, "ความเร็วหมุน", 10, 100, 20, function(v) spinSpeed = v if spinEnabled and spinBav then spinBav.AngularVelocity = Vector3.new(0,v,0) end end)
createSwitch(pFunny, "จำลองปิงกาก (Fake Lag)", function(v) toggleFakeLag(v) end)

-- > SETTINGS TAB
mk("TextLabel", {Text = "เลือกธีมสี", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.fromRGB(150,150,150), BackgroundTransparency = 1, Size = UDim2.new(1,0,0,20), TextXAlignment=Enum.TextXAlignment.Left, Parent = pSettings})
mk("UIPadding", {Parent=pSettings, PaddingLeft=UDim.new(0,10)})
local palette = mk("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,-10,0,40), Parent=pSettings})
mk("UIListLayout", {Parent=palette, FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,10)})
for i, theme in ipairs(PRESETS) do
    local colorBtn = mk("TextButton", {
        Text = "", BackgroundColor3 = theme.Accent, Size = UDim2.new(0, 30, 0, 30), AutoButtonColor = false, Parent = palette
    })
    mk("UICorner", {Parent=colorBtn, CornerRadius=UDim.new(1,0)})
    colorBtn.MouseButton1Click:Connect(function()
        SetTheme(i)
        for _, t in pairs(tabs) do
            if t.Page.Visible then tween(t.Btn, {TextColor3 = theme.Accent}) else t.Btn.TextColor3 = Color3.fromRGB(150,150,150) end
        end
    end)
end

-- > TELEPORT TAB
pTeleport.CanvasSize = UDim2.new(0,0,0,0)
local topBarTP = mk("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 35), Parent = pTeleport})
local searchBox = mk("TextBox", {BackgroundColor3 = Color3.fromRGB(35,35,38), Size = UDim2.new(1, -45, 1, 0), Position = UDim2.new(0, 0, 0, 0), Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = Color3.fromRGB(240,240,240), PlaceholderText = "ค้นหาผู้เล่น...", PlaceholderColor3 = Color3.fromRGB(150,150,150), TextXAlignment = Enum.TextXAlignment.Left, Parent = topBarTP})
mk("UICorner", {Parent=searchBox, CornerRadius=UDim.new(0, 8)}) mk("UIPadding", {Parent=searchBox, PaddingLeft=UDim.new(0, 12)})
local resetCamBtn = mk("TextButton", {Text="📷", BackgroundColor3 = Color3.fromRGB(45,45,48), Size=UDim2.new(0,35,1,0), AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,0,0,0), Font=Enum.Font.Gotham, TextSize=18, TextColor3=Color3.new(1,1,1), AutoButtonColor=false, Parent=topBarTP})
mk("UICorner", {Parent=resetCamBtn, CornerRadius=UDim.new(0,8)})

resetCamBtn.MouseButton1Click:Connect(function()
    playClick(1)
    if lp.Character and lp.Character:FindFirstChild("Humanoid") then 
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        workspace.CurrentCamera.CameraSubject = lp.Character:FindFirstChild("Humanoid") 
    end
    sendNotify("กล้อง", "รีเซ็ตมุมกล้องกลับมาที่ตัวเรา")
end)

local playerScroll = mk("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,1,-45), Parent=pTeleport})
local pList = mk("ScrollingFrame", {BackgroundTransparency=1, Size=UDim2.fromScale(1,1), CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y, ScrollBarThickness=2, ScrollBarImageColor3=Color3.fromRGB(150,150,150), BorderSizePixel=0, Parent=playerScroll})
mk("UIListLayout", {Parent=pList, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0, 6)}) mk("UIPadding", {Parent=pList, PaddingLeft=UDim.new(0, 5), PaddingRight=UDim.new(0, 5), PaddingBottom=UDim.new(0, 5)})

local function updatePlayerList(filter)
    for _, v in pairs(pList:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
    filter = filter and filter:lower() or ""
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lp and (filter == "" or p.Name:lower():find(filter) or p.DisplayName:lower():find(filter)) then
            local card = mk("Frame", {BackgroundColor3 = Color3.fromRGB(35,35,38), Size = UDim2.new(1, 0, 0, 42), Parent = pList})
            mk("UICorner", {Parent=card, CornerRadius=UDim.new(0, 8)})
            local tpBtn = mk("TextButton", {BackgroundTransparency=1, Size=UDim2.new(1,-60,1,0), Text="", Parent=card})
            local av = mk("ImageLabel", {BackgroundTransparency=1, Size=UDim2.new(0, 30, 0, 30), Position=UDim2.new(0, 6, 0.5, -15), Image = Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48), Parent=tpBtn})
            mk("UICorner", {Parent=av, CornerRadius=UDim.new(1,0)})
            mk("TextLabel", {BackgroundTransparency=1, Size=UDim2.new(1, -50, 0, 16), Position=UDim2.new(0, 45, 0, 6), Font=Enum.Font.GothamBold, Text=p.DisplayName, TextSize=13, TextColor3=Color3.fromRGB(240,240,240), TextXAlignment=Enum.TextXAlignment.Left, Parent=tpBtn})
            mk("TextLabel", {BackgroundTransparency=1, Size=UDim2.new(1, -50, 0, 14), Position=UDim2.new(0, 45, 0, 22), Font=Enum.Font.Gotham, Text="@"..p.Name, TextSize=11, TextColor3=Color3.fromRGB(150,150,150), TextXAlignment=Enum.TextXAlignment.Left, Parent=tpBtn})
            
            local viewBtn = mk("TextButton", {Text="👁️", BackgroundTransparency=1, Size=UDim2.new(0,40,1,0), Position=UDim2.new(1,-40,0,0), Font=Enum.Font.Gotham, TextSize=18, TextColor3=Color3.fromRGB(200,200,200), ZIndex=5, Parent=card})
            
            tpBtn.MouseButton1Click:Connect(function() playClick(1) if lp.Character and p.Character then lp.Character:PivotTo(p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)) sendNotify("เทเลพอร์ตแล้ว", "ไปยัง " .. p.DisplayName) end end)
            
            viewBtn.MouseButton1Click:Connect(function() 
                playClick(1) 
                if p.Character and p.Character:FindFirstChild("Humanoid") then 
                    workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
                    workspace.CurrentCamera.CameraSubject = p.Character:FindFirstChild("Humanoid") 
                    sendNotify("ส่องผู้เล่น", "กำลังดู: " .. p.DisplayName)
                else
                    sendNotify("ผิดพลาด", "ผู้เล่นยังโหลดตัวละครไม่เสร็จ")
                end 
            end)
        end
    end
end
searchBox:GetPropertyChangedSignal("Text"):Connect(function() updatePlayerList(searchBox.Text) end)
Players.PlayerAdded:Connect(function() updatePlayerList(searchBox.Text) end)
Players.PlayerRemoving:Connect(function() updatePlayerList(searchBox.Text) end)

-- > WAYPOINTS TAB
local savedWaypoints = {}
local wpInputContainer = mk("Frame", {BackgroundColor3=Color3.fromRGB(35,35,38), Size=UDim2.new(1,-10,0,44), Parent=pWaypoints})
mk("UICorner", {Parent=wpInputContainer, CornerRadius=UDim.new(0,8)})
local wpInput = mk("TextBox", {BackgroundTransparency=1, Size=UDim2.new(1,-50,1,0), Position=UDim2.new(0,10,0,0), Font=Enum.Font.GothamMedium, TextSize=13, TextColor3=Color3.fromRGB(240,240,240), PlaceholderText="ชื่อจุดวาร์ป...", PlaceholderColor3=Color3.fromRGB(150,150,150), TextXAlignment=Enum.TextXAlignment.Left, Parent=wpInputContainer})
local wpAddBtn = mk("TextButton", {Text="+", BackgroundColor3=Color3.fromRGB(40,200,100), Size=UDim2.new(0,34,0,34), AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-5,0.5,0), Font=Enum.Font.GothamBold, TextSize=22, TextColor3=Color3.new(1,1,1), AutoButtonColor=false, Parent=wpInputContainer})
mk("UICorner", {Parent=wpAddBtn, CornerRadius=UDim.new(0,6)})
local wpListTitle = mk("TextLabel", {Text = "ตำแหน่งที่บันทึกไว้", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.fromRGB(150,150,150), BackgroundTransparency = 1, Size = UDim2.new(1,0,0,30), TextXAlignment=Enum.TextXAlignment.Left, Parent = pWaypoints})
mk("UIPadding", {Parent=wpListTitle, PaddingLeft=UDim.new(0,5), PaddingTop=UDim.new(0,10)})
local wpScrollContainer = mk("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,1,-80), Parent=pWaypoints})
local wpScroll = mk("ScrollingFrame", {BackgroundTransparency=1, Size=UDim2.fromScale(1,1), CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y, ScrollBarThickness=2, ScrollBarImageColor3=Color3.fromRGB(150,150,150), BorderSizePixel=0, Parent=wpScrollContainer})
mk("UIListLayout", {Parent=wpScroll, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0, 6)})

local function refreshWaypoints()
    for _, v in pairs(wpScroll:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
    for i, wp in ipairs(savedWaypoints) do
        local card = mk("Frame", {BackgroundColor3 = Color3.fromRGB(35,35,38), Size = UDim2.new(1, -10, 0, 40), Parent = wpScroll})
        mk("UICorner", {Parent=card, CornerRadius=UDim.new(0, 8)})
        mk("TextLabel", {BackgroundTransparency=1, Size=UDim2.new(1, -90, 1, 0), Position=UDim2.new(0, 12, 0, 0), Font=Enum.Font.GothamBold, Text=wp.Name, TextSize=13, TextColor3=Color3.fromRGB(240,240,240), TextXAlignment=Enum.TextXAlignment.Left, Parent=card})
        local bindBtn = mk("TextButton", {
            Text = Config.Binds["WP_"..wp.Name] and "["..Config.Binds["WP_"..wp.Name].."]" or "[...]",
            BackgroundColor3 = Color3.fromRGB(45,45,48), Size = UDim2.new(0,30,0,24), Position = UDim2.new(1,-105,0.5,-12),
            Font=Enum.Font.GothamBold, TextSize=10, TextColor3=Color3.fromRGB(150,150,150), AutoButtonColor=false, Parent=card
        })
        mk("UICorner", {Parent=bindBtn, CornerRadius=UDim.new(0,4)})
        local btnTP = mk("TextButton", {Text="TP", BackgroundColor3=CURRENT.Accent, Size=UDim2.new(0,30,0,24), Position=UDim2.new(1,-70,0.5,-12), Font=Enum.Font.GothamBold, TextSize=11, TextColor3=Color3.new(1,1,1), AutoButtonColor=false, Parent=card})
        mk("UICorner", {Parent=btnTP, CornerRadius=UDim.new(0,4)})
        local btnDel = mk("TextButton", {Text="X", BackgroundColor3=Color3.fromRGB(200,60,60), Size=UDim2.new(0,24,0,24), Position=UDim2.new(1,-32,0.5,-12), Font=Enum.Font.GothamBold, TextSize=12, TextColor3=Color3.new(1,1,1), AutoButtonColor=false, Parent=card})
        mk("UICorner", {Parent=btnDel, CornerRadius=UDim.new(0,4)})
        btnTP.MouseButton1Click:Connect(function() playClick(1) if lp.Character then lp.Character:PivotTo(wp.CFrame) sendNotify("เทเลพอร์ตแล้ว", wp.Name) end end)
        btnDel.MouseButton1Click:Connect(function() playClick(1) table.remove(savedWaypoints, i) refreshWaypoints() end)
        bindBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                bindBtn.Text = "..."
                bindBtn.TextColor3 = CURRENT.Accent
                local conn
                conn = UserInputService.InputBegan:Connect(function(key)
                    if key.UserInputType == Enum.UserInputType.Keyboard then
                        if key.KeyCode == Enum.KeyCode.Backspace then
                            Config.Binds["WP_"..wp.Name] = nil
                            bindBtn.Text = "[...]"
                        else
                            Config.Binds["WP_"..wp.Name] = key.KeyCode.Name
                            bindBtn.Text = "["..key.KeyCode.Name.."]"
                        end
                        SaveConfig()
                        bindBtn.TextColor3 = Color3.fromRGB(150,150,150)
                        conn:Disconnect()
                    end
                end)
            end
        end)
    end
end

UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.UserInputType == Enum.UserInputType.Keyboard then
        for _, wp in ipairs(savedWaypoints) do
            local bind = Config.Binds["WP_"..wp.Name]
            if bind and input.KeyCode.Name == bind then
                if lp.Character then
                    lp.Character:PivotTo(wp.CFrame)
                    sendNotify("เทเลพอร์ตแล้ว", wp.Name)
                end
            end
        end
    end
end)

wpAddBtn.MouseButton1Click:Connect(function()
    playClick(1)
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        local name = wpInput.Text ~= "" and wpInput.Text or "จุดที่ "..(#savedWaypoints+1)
        table.insert(savedWaypoints, {Name = name, CFrame = lp.Character.HumanoidRootPart.CFrame})
        wpInput.Text = "" refreshWaypoints() sendNotify("บันทึกแล้ว", name)
    end
end)

-- Init
task.delay(0.1, function()
    tabs[1].Btn.TextColor3 = CURRENT.Accent
    tabs[1].Page.Visible = true
    tabs[1].Ind.Size = UDim2.new(0,3,0,20)
    tabs[1].Ind.BackgroundTransparency = 0
    updatePlayerList("")
end)

-- Minimize & Drag
local minimized, normalSize, miniSize, centerPos, topPos = false, UDim2.fromOffset(500, 340), UDim2.fromOffset(500, 40), UDim2.fromScale(0.5, 0.5), UDim2.new(0.5, 0, 0, 30)
minBtn.MouseButton1Click:Connect(function()
    playClick(1)
    minimized = not minimized
    if minimized then
        tween(window, {Size = miniSize, Position = topPos}, 0.5) tween(wStroke, {Transparency = 1}, 0.3)
        topSep.BackgroundTransparency = 1 footer.Visible = false content.Visible = false headerStatus.Visible = true minBtn.Text = "+" minBtn.TextColor3 = CURRENT.Accent
    else
        tween(window, {Size = normalSize, Position = centerPos}, 0.5) tween(wStroke, {Transparency = 0.4}, 0.3)
        headerStatus.Visible = false task.delay(0.3, function() topSep.BackgroundTransparency = 0 footer.Visible = true content.Visible = true end) minBtn.Text = "-" minBtn.TextColor3 = Color3.fromRGB(150,150,150)
    end
end)

local dragging, dragStart, startPos
window.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging=true dragStart=i.Position startPos=window.Position end end)
UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then local d=i.Position-dragStart window.Position=UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end end)

local vis = true
UserInputService.InputBegan:Connect(function(i, gp) if not gp and i.KeyCode == Enum.KeyCode.J then vis = not vis window.Visible = vis end end)
