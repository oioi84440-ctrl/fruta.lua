--[[ Anime Piece | Fruit ESP v5 - filtro por DroppedTools
  Escuta Workspace.World.Playability.DroppedTools. Marca toda fruta, global.
  F = teleportar na mais próxima | T = tracer on/off | K = limpar
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local W = workspace
local LP = Players.LocalPlayer
local cam = W.CurrentCamera

if getgenv().__APF5 then pcall(getgenv().__APF5.destroy) end

local CFG = { Enabled = true, Tracer = true, MaxDist = 8000 }
local tracked = {}

---------------------------------------------------------------------
-- UI
---------------------------------------------------------------------
local pg = LP:WaitForChild("PlayerGui")
local gui = Instance.new("ScreenGui")
gui.Name = "APF5"
gui.ResetOnSpawn = false
gui.Parent = pg

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(250, 108)
frame.Position = UDim2.new(0, 20, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(13, 13, 17)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 26)
title.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
title.BorderSizePixel = 0
title.Font = Enum.Font.GothamBold
title.TextSize = 11
title.TextColor3 = Color3.fromRGB(0, 255, 150)
title.Text = "FRUIT ESP v5 | F: TP  T: tracer"
title.Parent = frame
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -12, 0, 18)
status.Position = UDim2.fromOffset(6, 30)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Code
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextColor3 = Color3.fromRGB(200, 200, 200)
status.Text = "aguardando DroppedTools..."
status.Parent = frame

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, -12, 0, 44)
hint.Position = UDim2.fromOffset(6, 50)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.Gotham
hint.TextSize = 10
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.TextYAlignment = Enum.TextYAlignment.Top
hint.TextColor3 = Color3.fromRGB(120, 120, 120)
hint.Text = "Marca toda fruta no mapa, inclusive as dropadas.\nVermelho = perto | verde = longe"
hint.Parent = frame

---------------------------------------------------------------------
-- MARCAÇÃO
---------------------------------------------------------------------
local GREEN = Color3.fromRGB(0, 255, 150)
local RED = Color3.fromRGB(255, 70, 70)

local function untrack(inst)
    local d = tracked[inst]
    if not d then return end
    tracked[inst] = nil
    for _, c in ipairs(d.conns) do pcall(function() c:Disconnect() end) end
    if d.hl then pcall(function() d.hl:Destroy() end) end
    if d.box then pcall(function() d.box:Destroy() end) end
    if d.gui then pcall(function() d.gui:Destroy() end) end
    if d.line then pcall(function() d.line:Remove() end) end
end

local function clearAll()
    for i in pairs(tracked) do untrack(i) end
end

local function track(part)
    if tracked[part] or not part:IsA("BasePart") then return end
    local d = { conns = {} }

    local ok, hl = pcall(Instance.new, "Highlight")
    if ok then
        hl.Adornee = part
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillColor = GREEN
        hl.FillTransparency = 0.55
        hl.OutlineColor = GREEN
        hl.Parent = part
        d.hl = hl
    end

    local ok2, box = pcall(Instance.new, "BoxHandleAdornment")
    if ok2 then
        box.Adornee = part
        box.AlwaysOnTop = true
        box.Size = Vector3.new(
            math.clamp(part.Size.X, 0.4, 20),
            math.clamp(part.Size.Y, 0.4, 20),
            math.clamp(part.Size.Z, 0.4, 20))
        box.Color3 = GREEN
        box.Transparency = 0.2
        box.Parent = part
        d.box = box
    end

    local g = Instance.new("BillboardGui")
    g.Adornee = part
    g.AlwaysOnTop = true
    g.Size = UDim2.fromOffset(170, 36)
    g.StudsOffsetWorldSpace = Vector3.new(0, 1.5, 0)
    g.Parent = part
    local l = Instance.new("TextLabel")
    l.Size = UDim2.fromScale(1, 1)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamBold
    l.TextSize = 14
    l.TextColor3 = GREEN
    l.TextStrokeTransparency = 0.25
    l.Parent = g
    d.gui, d.label = g, l

    if Drawing and Drawing.new then
        local ok3, line = pcall(Drawing.new, "Line")
        if ok3 and line then
            line.Thickness = 1.6
            line.Transparency = 0.7
            line.Color = GREEN
            line.Visible = false
            d.line = line
        end
    end

    table.insert(d.conns, part.AncestryChanged:Connect(function(_, p)
        if not p then untrack(part) end
    end))
    table.insert(d.conns, part.Destroying:Connect(function() untrack(part) end))

    tracked[part] = d
end

---------------------------------------------------------------------
-- LOCALIZA A PASTA
---------------------------------------------------------------------
local function findFolder()
    for _, path in ipairs({ { "World", "Playability", "DroppedTools" }, { "DroppedTools" } }) do
        local node = W
        local ok = true
        for _, name in ipairs(path) do
            node = node and node:FindFirstChild(name)
            if not node then ok = false break end
        end
        if ok and node then return node end
    end
    for _, d in ipairs(W:GetDescendants()) do
        if d.Name == "DroppedTools" and d:IsA("Folder") then return d end
    end
end

local folder
task.spawn(function()
    while not folder do
        folder = findFolder()
        if not folder then task.wait(1) end
    end
    status.Text = "pasta ligada: " .. folder:GetFullName()

    local function sync()
        for _, c in ipairs(folder:GetChildren()) do track(c) end
    end

    folder.ChildAdded:Connect(function(c) track(c) end)
    folder.ChildRemoved:Connect(function(c) untrack(c) end)
    sync()

    while true do
        task.wait(5)
        sync()
    end
end)

---------------------------------------------------------------------
-- UPDATE
---------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.1)
        local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local origin = root and root.Position or (cam and cam.CFrame.Position)
        if not origin then continue end
        local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
        local n = 0

        for part, d in pairs(tracked) do
            n += 1
            local ok = part and part.Parent
            local dist = ok and (origin - part.Position).Magnitude or math.huge
            local vis = ok and CFG.Enabled and dist <= CFG.MaxDist

            if d.hl then
                d.hl.Enabled = vis
                if vis then
                    local t = math.clamp(dist / CFG.MaxDist, 0, 1)
                    local c = RED:Lerp(GREEN, t)
                    d.hl.FillColor = c
                    d.hl.OutlineColor = c
                    if d.box then d.box.Color3 = c end
                    if d.label then d.label.TextColor3 = c end
                    if d.line then d.line.Color = c end
                end
            end
            if d.box then d.box.Visible = vis end
            if d.gui then
                d.gui.Enabled = vis
                if vis then d.label.Text = ("FRUTA  %dm"):format(math.floor(dist)) end
            end

            if d.line then
                if vis and CFG.Tracer and root and cam then
                    local sp, on = cam:WorldToViewportPoint(part.Position)
                    if on then
                        d.line.Visible = true
                        d.line.From = Vector2.new(vp.X / 2, vp.Y - 8)
                        d.line.To = Vector2.new(sp.X, sp.Y)
                    else
                        d.line.Visible = false
                    end
                else
                    d.line.Visible = false
                end
            end
        end

        status.Text = ("frutas no mapa: %d"):format(n)
    end
end)

---------------------------------------------------------------------
-- AÇÕES
---------------------------------------------------------------------
local function nearest()
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local best, bd
    for part in pairs(tracked) do
        if part.Parent then
            local dist = (root.Position - part.Position).Magnitude
            if not bd or dist < bd then best, bd = part, dist end
        end
    end
    if best then
        root.CFrame = CFrame.new(best.Position + Vector3.new(0, 4, 0))
        status.Text = ("TP -> %dm"):format(math.floor(bd))
    end
end

UIS.InputBegan:Connect(function(k, gp)
    if gp then return end
    if k.KeyCode == Enum.KeyCode.F then nearest() end
    if k.KeyCode == Enum.KeyCode.T then
        CFG.Tracer = not CFG.Tracer
        title.Text = ("FRUIT ESP v5 | F: TP  T: tracer %s"):format(CFG.Tracer and "ON" or "OFF")
    end
    if k.KeyCode == Enum.KeyCode.K then clearAll() end
end)

getgenv().__APF5 = {
    cfg = CFG, tracked = tracked, tp = nearest,
    destroy = function() clearAll(); gui:Destroy() end,
}
