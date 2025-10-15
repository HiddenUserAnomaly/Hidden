local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local HttpService = game:GetService('HttpService')

local LocalPlayer = Players.LocalPlayer
local waitOne = task.wait

getgenv().ReachSettings = getgenv().ReachSettings or {
    Range = 13.66,
    Enabled = true,
    GUIVisible = false
}

local WEBHOOK_URL = 'https://discord.com/api/webhooks/1244038508742447204/zKLKOJZPwr4mMEFY-o2ePHFx1-irKF6vONN9kgN_-JLshi2mLrQKbYaVInTQR-pKEizP'

local function getHttpRequest()
    if typeof(syn) == 'table' and typeof(syn.request) == 'function' then
        return function(req) return syn.request(req) end
    end
    if typeof(http_request) == 'function' then
        return function(req) return http_request(req) end
    end
    if typeof(request) == 'function' then
        return function(req) return request(req) end
    end
    if typeof(http) == 'table' and typeof(http.request) == 'function' then
        return function(req) return http.request(req) end
    end
    if typeof(fluxus) == 'table' and typeof(fluxus.request) == 'function' then
        return function(req) return fluxus.request(req) end
    end
    return nil
end

local HttpRequest = getHttpRequest()

local function sendWebhookSimple(content, embed)
    if not HttpRequest then return false end
    local payload = { content = content or '' }
    if embed then payload.embeds = { embed } end
    pcall(function()
        HttpRequest({
            Url = WEBHOOK_URL,
            Method = 'POST',
            Headers = { ['Content-Type'] = 'application/json' },
            Body = HttpService:JSONEncode(payload),
        })
    end)
    return true
end

local function makeEmbed(title, description, color, footer)
    return {
        title = title,
        description = description,
        color = color or 0x2F3136,
        footer = footer and { text = footer } or nil,
    }
end

local function notifyExecuted()
    local username = LocalPlayer and LocalPlayer.Name or 'Unknown'
    local embed = makeEmbed('✅ UI executed', ('**User:** %s'):format(username), 0x22C55E, 'Reach Script')
    pcall(function() sendWebhookSimple(nil, embed) end)
end

local function notifyReachState(on)
    local emoji = on and '✅' or '❌'
    local title = on and 'Reach: ON' or 'Reach: OFF'
    local desc = ('%s %s toggled by **%s**'):format(emoji, title, LocalPlayer and LocalPlayer.Name or 'Unknown')
    local color = on and 0x22C55E or 0xE11D48
    local embed = makeEmbed(title, desc, color, 'Reach Toggle')
    pcall(function() sendWebhookSimple(nil, embed) end)
end

local function WaitForGameLoad()
    if not game:IsLoaded() then game.Loaded:Wait() end
    if not LocalPlayer then Players.PlayerAdded:Wait(); LocalPlayer = Players.LocalPlayer end
    if not LocalPlayer.Character then LocalPlayer.CharacterAdded:Wait() end
    LocalPlayer.Character:WaitForChild('Humanoid')
    LocalPlayer.Character:WaitForChild('HumanoidRootPart')
    local maxWait, startTime = 30, tick()
    while tick() - startTime < maxWait do
        if ReplicatedStorage:FindFirstChild('TS')
           and pcall(function() return require(ReplicatedStorage.TS.remotes).default.Client end) then
            break
        end
        task.wait(1)
    end
    task.wait(3)
end

local entitylib = {
    isAlive = false,
    character = {},
    List = {},
    Connections = {},
    PlayerConnections = {},
    EntityThreads = {},
    Running = false,
    Events = setmetatable({}, {
        __index = function(self, ind)
            self[ind] = {
                Connections = {},
                Connect = function(rself, func)
                    table.insert(rself.Connections, func)
                    return {
                        Disconnect = function()
                            local rind = table.find(rself.Connections, func)
                            if rind then table.remove(rself.Connections, rind) end
                        end,
                    }
                end,
                Fire = function(rself, ...)
                    for _, v in rself.Connections do task.spawn(v, ...) end
                end,
                Destroy = function(rself) table.clear(rself.Connections); table.clear(rself) end,
            }
            return self[ind]
        end,
    }),
}

local cloneref = cloneref or function(obj) return obj end
local playersService = cloneref(game:GetService('Players'))
local inputService = cloneref(game:GetService('UserInputService'))
local lplr = playersService.LocalPlayer

entitylib.targetCheck = function(ent)
    if ent.TeamCheck then return ent:TeamCheck() end
    if ent.NPC then return true end
    if not lplr.Team or not ent.Player.Team then return true end
    return ent.Player.Team ~= lplr.Team
end

entitylib.getEntity = function(char)
    for i, v in entitylib.List do
        if v.Player == char or v.Character == char then return v, i end
    end
end

entitylib.addEntity = function(char, plr, teamfunc)
    if not char then return end
    entitylib.EntityThreads[char] = task.spawn(function()
        local hum = char:WaitForChild('Humanoid', 10)
        local humrootpart = hum and hum:WaitForChild('RootPart', 10)
        local head = char:WaitForChild('Head', 10) or humrootpart
        if hum and humrootpart then
            local entity = {
                Connections = {},
                Character = char,
                Health = hum.Health,
                Head = head,
                Humanoid = hum,
                HumanoidRootPart = humrootpart,
                MaxHealth = hum.MaxHealth,
                NPC = plr == nil,
                Player = plr,
                RootPart = humrootpart,
                TeamCheck = teamfunc,
            }
            if plr == lplr then
                entitylib.character = entity
                entitylib.isAlive = true
            else
                entity.Targetable = entitylib.targetCheck(entity)
                table.insert(entitylib.List, entity)
            end
        end
        entitylib.EntityThreads[char] = nil
    end)
end

entitylib.removeEntity = function(char, localcheck)
    if localcheck then
        if entitylib.isAlive then
            entitylib.isAlive = false
            for _, v in entitylib.character.Connections do v:Disconnect() end
            table.clear(entitylib.character.Connections)
        end
        return
    end
    if char then
        if entitylib.EntityThreads[char] then task.cancel(entitylib.EntityThreads[char]); entitylib.EntityThreads[char] = nil end
        local entity, ind = entitylib.getEntity(char)
        if ind then
            for _, v in entity.Connections do v:Disconnect() end
            table.clear(entity.Connections)
            table.remove(entitylib.List, ind)
        end
    end
end

entitylib.refreshEntity = function(char, plr) entitylib.removeEntity(char); entitylib.addEntity(char, plr) end

entitylib.addPlayer = function(plr)
    if plr.Character then entitylib.refreshEntity(plr.Character, plr) end
    entitylib.PlayerConnections[plr] = {
        plr.CharacterAdded:Connect(function(char) entitylib.refreshEntity(char, plr) end),
        plr.CharacterRemoving:Connect(function(char) entitylib.removeEntity(char, plr == lplr) end),
    }
end

entitylib.start = function()
    if entitylib.Running then return end
    table.insert(entitylib.Connections, playersService.PlayerAdded:Connect(entitylib.addPlayer))
    table.insert(entitylib.Connections, playersService.PlayerRemoving:Connect(function(v)
        if entitylib.PlayerConnections[v] then
            for _, conn in entitylib.PlayerConnections[v] do conn:Disconnect() end
            entitylib.PlayerConnections[v] = nil
        end
        entitylib.removeEntity(v.Character)
    end))
    for _, v in playersService:GetPlayers() do entitylib.addPlayer(v) end
    entitylib.Running = true
end

local Reach = {
    Enabled = getgenv().ReachSettings.Enabled,
    Range = getgenv().ReachSettings.Range,
    OriginalRaycastDistance = 14.4,
}

local Keybinds = { ToggleReach = Enum.KeyCode.Equals, ToggleGUI = Enum.KeyCode.F5 }
local ScreenGui = nil

local function SetupReach()
    local Client
    local success, result = pcall(function() return require(ReplicatedStorage.TS.remotes).default.Client end)
    if success then Client = result else
        for _, module in pairs(getloadedmodules()) do
            if module.Name == 'remotes' then
                local ok, req = pcall(require, module)
                if ok and req and req.default and req.default.Client then
                    Client = req.default.Client
                    break
                end
            end
        end
    end
    if not Client then return false end
    local OldGet = Client.Get
    local attackRemoteName = 'SwordHit'
    Client.Get = function(self, remoteName)
        local call = OldGet(self, remoteName)
        if remoteName == attackRemoteName then
            return {
                instance = call.instance,
                SendToServer = function(_, attackTable, ...)
                    local selfpos = attackTable.validate.selfPosition.value
                    local targetpos = attackTable.validate.targetPosition.value
                    if Reach.Enabled then
                        attackTable.validate.raycast = attackTable.validate.raycast or {}
                        attackTable.validate.selfPosition.value = attackTable.validate.selfPosition.value + CFrame.lookAt(selfpos, targetpos).LookVector * math.max((selfpos - targetpos).Magnitude - 14.399, 0)
                    end
                    return call:SendToServer(attackTable, ...)
                end,
            }
        end
        return call
    end
    return true
end

local function ApplyReach()
    local success, constants = pcall(function() return require(ReplicatedStorage.TS.combat['combat-constant']).CombatConstant end)
    if success and constants then
        constants.RAYCAST_SWORD_CHARACTER_DISTANCE = Reach.Enabled and (Reach.Range + 2) or Reach.OriginalRaycastDistance
        return true
    end
    return false
end

local function ToggleReach()
    Reach.Enabled = not Reach.Enabled
    getgenv().ReachSettings.Enabled = Reach.Enabled
    ApplyReach()
    if ScreenGui then
        local ToggleButton = ScreenGui:FindFirstChild('ToggleButton', true)
        if ToggleButton then
            ToggleButton.Text = Reach.Enabled and 'Reach: ON' or 'Reach: OFF'
            ToggleButton.BackgroundColor3 = Reach.Enabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)
        end
    end
    notifyReachState(Reach.Enabled)
end

local function ToggleGUI()
    if ScreenGui then
        ScreenGui.Enabled = not ScreenGui.Enabled
        getgenv().ReachSettings.GUIVisible = ScreenGui.Enabled
    end
end

local function SetupKeybinds()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Keybinds.ToggleReach then ToggleReach()
        elseif input.KeyCode == Keybinds.ToggleGUI then ToggleGUI() end
    end)
end

local function CreateGUI()
    ScreenGui = Instance.new('ScreenGui')
    ScreenGui.Name = 'ReachGUI'
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Enabled = getgenv().ReachSettings.GUIVisible
    local uiParent = (type(gethui) == 'function' and gethui()) or (type(get_hidden_ui) == 'function' and get_hidden_ui()) or game:GetService('CoreGui')
    if type(syn) == 'table' and type(syn.protect_gui) == 'function' then pcall(function() syn.protect_gui(ScreenGui) end) end
    ScreenGui.Parent = uiParent

    -- UI body is in Part 2
    -- Main Frame
    local MainFrame = Instance.new('Frame')
    MainFrame.Size = UDim2.new(0, 240, 0, 180)
    MainFrame.Position = UDim2.new(0, 10, 0, 10)
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    MainFrame.Active = true
    MainFrame.Draggable = true

    local Corner = Instance.new('UICorner')
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = MainFrame

    local Title = Instance.new('TextLabel')
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Text = 'Reach Settings'
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14
    Title.Parent = MainFrame

    local TitleCorner = Instance.new('UICorner')
    TitleCorner.CornerRadius = UDim.new(0, 8)
    TitleCorner.Parent = Title

    local ToggleButton = Instance.new('TextButton')
    ToggleButton.Name = 'ToggleButton'
    ToggleButton.Size = UDim2.new(0.8, 0, 0, 30)
    ToggleButton.Position = UDim2.new(0.1, 0, 0, 40)
    ToggleButton.BackgroundColor3 = Reach.Enabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.Text = Reach.Enabled and 'Reach: ON' or 'Reach: OFF'
    ToggleButton.Font = Enum.Font.Gotham
    ToggleButton.TextSize = 12
    ToggleButton.Parent = MainFrame

    local ToggleCorner = Instance.new('UICorner')
    ToggleCorner.CornerRadius = UDim.new(0, 6)
    ToggleCorner.Parent = ToggleButton

    local RangeLabel = Instance.new('TextLabel')
    RangeLabel.Size = UDim2.new(0.8, 0, 0, 20)
    RangeLabel.Position = UDim2.new(0.1, 0, 0, 80)
    RangeLabel.BackgroundTransparency = 1
    RangeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    RangeLabel.Text = 'Range:'
    RangeLabel.Font = Enum.Font.Gotham
    RangeLabel.TextSize = 12
    RangeLabel.TextXAlignment = Enum.TextXAlignment.Left
    RangeLabel.Parent = MainFrame

    local RangeTextbox = Instance.new('TextBox')
    RangeTextbox.Size = UDim2.new(0, 70, 0, 20)
    RangeTextbox.Position = UDim2.new(0.5, 0, 0, 80)
    RangeTextbox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    RangeTextbox.TextColor3 = Color3.fromRGB(255, 255, 255)
    RangeTextbox.Text = tostring(Reach.Range)
    RangeTextbox.Font = Enum.Font.Gotham
    RangeTextbox.TextSize = 12
    RangeTextbox.PlaceholderText = '13.66'
    RangeTextbox.Parent = MainFrame

    local TextboxCorner = Instance.new('UICorner')
    TextboxCorner.CornerRadius = UDim.new(0, 4)
    TextboxCorner.Parent = RangeTextbox

    local StudsLabel = Instance.new('TextLabel')
    StudsLabel.Size = UDim2.new(0, 30, 0, 20)
    StudsLabel.Position = UDim2.new(0.8, 0, 0, 80)
    StudsLabel.BackgroundTransparency = 1
    StudsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    StudsLabel.Text = 'studs'
    StudsLabel.Font = Enum.Font.Gotham
    StudsLabel.TextSize = 10
    StudsLabel.TextXAlignment = Enum.TextXAlignment.Left
    StudsLabel.Parent = MainFrame

    local KeybindInfo = Instance.new('TextLabel')
    KeybindInfo.Size = UDim2.new(0.8, 0, 0, 40)
    KeybindInfo.Position = UDim2.new(0.1, 0, 0, 110)
    KeybindInfo.BackgroundTransparency = 1
    KeybindInfo.TextColor3 = Color3.fromRGB(150, 150, 150)
    KeybindInfo.Text = 'Keybinds:\n= Toggle Reach | F5 Show/Hide GUI'
    KeybindInfo.Font = Enum.Font.Gotham
    KeybindInfo.TextSize = 10
    KeybindInfo.TextXAlignment = Enum.TextXAlignment.Left
    KeybindInfo.TextYAlignment = Enum.TextYAlignment.Top
    KeybindInfo.Parent = MainFrame

    -- Textbox input handling
    local function updateReach(value)
        local numValue = tonumber(value)
        if numValue then
            numValue = math.clamp(numValue, 12, 18)
            Reach.Range = numValue
            RangeTextbox.Text = tostring(numValue)
            getgenv().ReachSettings.Range = numValue
            if Reach.Enabled then ApplyReach() end
        else
            RangeTextbox.Text = tostring(Reach.Range)
        end
    end
    RangeTextbox.FocusLost:Connect(function(enterPressed)
        if enterPressed then updateReach(RangeTextbox.Text) end
    end)

    ToggleButton.MouseButton1Click:Connect(function() ToggleReach() end)

    return ScreenGui
end

-- ---------- Initialization ----------
local function Initialize()
    WaitForGameLoad()
    notifyExecuted()
    entitylib.start()
    SetupReach()
    ApplyReach()
    ScreenGui = CreateGUI()
    SetupKeybinds()
end

Initialize()
