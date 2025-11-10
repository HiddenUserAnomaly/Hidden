if _G.ReachScriptLoaded then return end
_G.ReachScriptLoaded = true

-- Quick executor check (basic protection)
if not (syn or protect_gui or get_hidden_ui or is_sirhurt_closure or crypt) then
    return
end

if type(queue_on_teleport) == "function" then
    queue_on_teleport([[
        if not (syn or protect_gui) then return end
        loadstring(game:HttpGet("https://raw.githubusercontent.com/HiddenUserAnomaly/Hidden/main/Reach.lua"))()
    ]])
end

-- Cache frequently used functions and services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local task_wait = task.wait
local task_spawn = task.spawn
local task_defer = task.defer
local table_insert = table.insert
local table_remove = table.remove
local table_find = table.find
local table_clear = table.clear
local math_max = math.max
local math_min = math.min
local math_clamp = math.clamp
local math_floor = math.floor
local Vector3_new = Vector3.new
local CFrame_new = CFrame.new
local CFrame_lookAt = CFrame.lookAt
local Color3_fromRGB = Color3.fromRGB
local UDim2_new = UDim2.new
local Instance_new = Instance.new

-- Fast game load with minimal waiting
local function WaitForGameLoad()
    repeat task_wait() until game:IsLoaded()
    
    local LocalPlayer = Players.LocalPlayer
    if not LocalPlayer then
        LocalPlayer = Players.PlayerAdded:Wait()
    end
    
    local char = LocalPlayer.Character
    if not char then
        char = LocalPlayer.CharacterAdded:Wait()
    end
    
    -- Quick character validation
    local startTime = tick()
    while tick() - startTime < 5 do
        if char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart") then
            break
        end
        task_wait(0.05)
    end
    
    -- Fast module detection
    local maxWait, startTime = 10, tick()
    while tick() - startTime < maxWait do
        local success = pcall(function()
            local TS = ReplicatedStorage:FindFirstChild("TS")
            return TS and require(TS.remotes).default.Client
        end)
        if success then break end
        task_wait(0.1)
    end
    
    task_wait(0.2)
end

local LocalPlayer = Players.LocalPlayer

-- Webhook (keep existing)
local WEBHOOK_URL = "https://discord.com/api/webhooks/1244038508742447204/zKLKOJZPwr4mMEFY-o2ePHFx1-irKF6vONN9kgN_-JLshi2mLrQKbYaVInTQR-pKEizP"

local HttpRequest
do
    local httpMethods = {
        syn = "request",
        http_request = "",
        request = "",
        http = "request", 
        fluxus = "request"
    }
    
    for obj, method in pairs(httpMethods) do
        local lib = _G[obj] or (type(obj) == "string" and loadstring("return "..obj)())
        if lib and (method == "" or type(lib[method]) == "function") then
            HttpRequest = method == "" and lib or lib[method]
            break
        end
    end
end

local function sendWebhook(content, embed)
    if not HttpRequest then return end
    
    local payload = {content = content or ""}
    if embed then payload.embeds = {embed} end
    
    task_spawn(function()
        pcall(function()
            HttpRequest({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(payload)
            })
        end)
    end)
end

local function makeEmbed(title, desc, color, footer)
    return {
        title = title,
        description = desc,
        color = color or 0x2F3136,
        footer = footer and {text = footer} or nil,
    }
end

local function notifyExecuted()
    local username = LocalPlayer and LocalPlayer.Name or "Unknown"
    sendWebhook(nil, makeEmbed("✅ UI executed", "**User:** "..username, 0x22C55E, "Reach Script"))
end

local function notifyReachState(on)
    local emoji = on and "✅" or "❌"
    local title = on and "Reach: ON" or "Reach: OFF"
    local desc = emoji.." "..title.." toggled by **"..(LocalPlayer and LocalPlayer.Name or "Unknown").."**"
    sendWebhook(nil, makeEmbed(title, desc, on and 0x22C55E or 0xE11D48, "Reach Toggle"))
end

-- Optimized Entity Library
local entitylib = {
    isAlive = false,
    character = {},
    List = {},
    Connections = {},
    PlayerConnections = {},
    EntityThreads = {},
    Running = false
}

local lplr = LocalPlayer

entitylib.targetCheck = function(ent)
    if ent.TeamCheck then return ent:TeamCheck() end
    if ent.NPC then return true end
    local myTeam, theirTeam = lplr.Team, ent.Player and ent.Player.Team
    if not myTeam or not theirTeam then return true end
    return myTeam ~= theirTeam
end

entitylib.getEntity = function(char)
    for i, v in entitylib.List do
        if v.Player == char or v.Character == char then 
            return v, i 
        end
    end
end

entitylib.addEntity = function(char, plr, teamfunc)
    if not char then return end
    
    entitylib.EntityThreads[char] = task_spawn(function()
        local hum, hrp, head
        
        for _ = 1, 15 do
            if not char.Parent then break end
            
            hum = char:FindFirstChild("Humanoid")
            hrp = char:FindFirstChild("HumanoidRootPart")
            if hum and hrp then
                head = char:FindFirstChild("Head") or hrp
                break
            end
            task_wait(0.05)
        end
        
        if hum and hrp then
            local entity = {
                Character = char, Humanoid = hum, HumanoidRootPart = hrp, Head = head,
                Player = plr, NPC = plr == nil, Connections = {}, TeamCheck = teamfunc,
                Health = hum.Health, MaxHealth = hum.MaxHealth
            }
            
            if plr == lplr then
                entitylib.character = entity
                entitylib.isAlive = true
            else
                entity.Targetable = entitylib.targetCheck(entity)
                table_insert(entitylib.List, entity)
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
            table_clear(entitylib.character.Connections)
        end
        return
    end
    
    if char then
        if entitylib.EntityThreads[char] then 
            task.cancel(entitylib.EntityThreads[char])
            entitylib.EntityThreads[char] = nil 
        end
        
        local entity, ind = entitylib.getEntity(char)
        if ind then
            for _, v in entity.Connections do v:Disconnect() end
            table_clear(entity.Connections)
            table_remove(entitylib.List, ind)
        end
    end
end

entitylib.refreshEntity = function(char, plr)
    entitylib.removeEntity(char)
    entitylib.addEntity(char, plr)
end

entitylib.addPlayer = function(plr)
    if plr.Character then entitylib.refreshEntity(plr.Character, plr) end
    
    entitylib.PlayerConnections[plr] = {
        plr.CharacterAdded:Connect(function(c) entitylib.refreshEntity(c, plr) end),
        plr.CharacterRemoving:Connect(function(c) entitylib.removeEntity(c, plr == lplr) end)
    }
end

entitylib.start = function()
    if entitylib.Running then return end
    
    table_insert(entitylib.Connections, Players.PlayerAdded:Connect(entitylib.addPlayer))
    table_insert(entitylib.Connections, Players.PlayerRemoving:Connect(function(v)
        if entitylib.PlayerConnections[v] then
            for _, c in entitylib.PlayerConnections[v] do c:Disconnect() end
            entitylib.PlayerConnections[v] = nil
        end
        entitylib.removeEntity(v.Character)
    end))
    
    for _, v in Players:GetPlayers() do entitylib.addPlayer(v) end
    entitylib.Running = true
end

-- FIXED Reach Configuration - No hidden +2 studs
local Reach = {
    Enabled = true,
    Range = 14.90, -- Default set to 15.90
    OriginalRaycastDistance = 14.4,
    CachedConstants = nil,
    CachedClient = nil,
    LastAppliedRange = nil,
    LastHitTime = 0,
    HitCooldown = 0.15
}

local BASE_DISTANCE = 14.399
local MIN_RANGE = 14.4  -- Minimum is now normal reach
local MAX_RANGE = 18.0

-- FIXED: Clean reach extension calculation
local function calculateReachExtension(selfpos, targetpos, currentDistance, maxRange)
    if currentDistance <= BASE_DISTANCE then 
        return selfpos -- No extension needed
    end
    
    -- Calculate how much we need to extend
    local direction = (targetpos - selfpos).Unit
    local extensionAmount = math_max(currentDistance - BASE_DISTANCE, 0)
    
    -- Apply extension for hit registration
    return selfpos + (direction * extensionAmount)
end

-- FIXED: Simplified reach setup
local function SetupReach()
    if Reach.CachedClient then return true end
    
    local Client
    local success = pcall(function() 
        Client = require(ReplicatedStorage.TS.remotes).default.Client
    end)
    
    if not success then
        for _, module in pairs(getloadedmodules()) do
            if module.Name == "remotes" then
                local ok, req = pcall(require, module)
                if ok and type(req) == "table" and req.default and req.default.Client then
                    Client = req.default.Client
                    break
                end
            end
        end
    end
    
    if not Client then return false end
    
    local oldGet = Client.Get
    Client.Get = function(self, remoteName)
        local call = oldGet(self, remoteName)
        
        if remoteName == "SwordHit" then
            local originalSend = call.SendToServer
            
            return {
                instance = call.instance,
                SendToServer = function(_, attackTable, ...)
                    if not Reach.Enabled then
                        return originalSend(call, attackTable, ...)
                    end
                    
                    local currentTime = tick()
                    
                    -- Basic cooldown to prevent spam
                    if currentTime - Reach.LastHitTime < Reach.HitCooldown then
                        return originalSend(call, attackTable, ...)
                    end
                    
                    local validate = attackTable.validate
                    local selfpos = validate.selfPosition.value
                    local targetpos = validate.targetPosition.value
                    local distance = (selfpos - targetpos).Magnitude
                    
                    -- FIXED: Simple range validation - GUI value is actual reach
                    if distance > Reach.Range then
                        -- Block hits beyond our configured range
                        return nil
                    end
                    
                    -- Only extend if beyond normal range but within our reach
                    if distance > BASE_DISTANCE then
                        validate.selfPosition.value = calculateReachExtension(selfpos, targetpos, distance, Reach.Range)
                    end
                    
                    Reach.LastHitTime = currentTime
                    return originalSend(call, attackTable, ...)
                end
            }
        end
        
        return call
    end
    
    Reach.CachedClient = Client
    return true
end

-- FIXED: No more +2 studs added
local function ApplyReach()
    if not Reach.CachedConstants then
        local success, constants = pcall(function() 
            return require(ReplicatedStorage.TS.combat["combat-constant"]).CombatConstant 
        end)
        if success then
            Reach.CachedConstants = constants
        else
            return false
        end
    end
    
    -- FIXED: GUI value is now the actual reach distance
    local newDistance = Reach.Enabled and Reach.Range or Reach.OriginalRaycastDistance
    
    if not Reach.LastAppliedRange or math.abs(Reach.LastAppliedRange - newDistance) > 0.01 then
        Reach.CachedConstants.RAYCAST_SWORD_CHARACTER_DISTANCE = newDistance
        Reach.LastAppliedRange = newDistance
    end
    
    return true
end

local function ToggleReach()
    Reach.Enabled = not Reach.Enabled
    
    if Reach.CachedConstants then
        -- FIXED: No more +2 studs
        Reach.CachedConstants.RAYCAST_SWORD_CHARACTER_DISTANCE = Reach.Enabled and Reach.Range or Reach.OriginalRaycastDistance
        Reach.LastAppliedRange = nil
    end
    
    -- Reset cooldowns on toggle
    Reach.LastHitTime = 0
    
    task_defer(function()
        if ScreenGui then
            local ToggleButton = ScreenGui:FindFirstChild("ToggleButton", true)
            if ToggleButton then
                ToggleButton.Text = Reach.Enabled and "Reach: ON" or "Reach: OFF"
                ToggleButton.BackgroundColor3 = Reach.Enabled and Color3_fromRGB(0,170,0) or Color3_fromRGB(60,60,60)
            end
        end
        notifyReachState(Reach.Enabled)
    end)
end

local function updateReach(value)
    local numValue = tonumber(value)
    if numValue then
        local clampedValue = math_clamp(math_floor(numValue * 100) / 100, MIN_RANGE, MAX_RANGE)
        if math.abs(Reach.Range - clampedValue) > 0.01 then
            Reach.Range = clampedValue
            
            if ScreenGui then
                local RangeTextbox = ScreenGui:FindFirstChild("TextBox", true)
                if RangeTextbox then
                    RangeTextbox.Text = tostring(Reach.Range)
                end
            end
            
            if Reach.Enabled then ApplyReach() end
        end
    elseif ScreenGui then
        local RangeTextbox = ScreenGui:FindFirstChild("TextBox", true)
        if RangeTextbox then
            RangeTextbox.Text = tostring(Reach.Range)
        end
    end
end

-- Optimized GUI
local ScreenGui = nil

local function CreateGUI()
    local uiParent = (type(gethui) == "function" and gethui()) or 
                    (type(get_hidden_ui) == "function" and get_hidden_ui()) or 
                    game:GetService("CoreGui")
    
    local existingGui = uiParent:FindFirstChild("ReachGUI")
    if existingGui then
        ScreenGui = existingGui
        ScreenGui.Enabled = false
        return ScreenGui
    end

    ScreenGui = Instance_new("ScreenGui")
    ScreenGui.Name = "ReachGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Enabled = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    if type(syn) == "table" and type(syn.protect_gui) == "function" then
        pcall(syn.protect_gui, ScreenGui)
    end
    ScreenGui.Parent = uiParent

    local MainFrame = Instance_new("Frame")
    MainFrame.Size = UDim2_new(0, 240, 0, 180)
    MainFrame.Position = UDim2_new(0, 10, 0, 10)
    MainFrame.BackgroundColor3 = Color3_fromRGB(30, 30, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local Corner = Instance_new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = MainFrame

    local Title = Instance_new("TextLabel")
    Title.Size = UDim2_new(1, 0, 0, 30)
    Title.BackgroundColor3 = Color3_fromRGB(45, 45, 45)
    Title.TextColor3 = Color3_fromRGB(255, 255, 255)
    Title.Text = "Reach Settings"
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14
    Title.Parent = MainFrame

    local TitleCorner = Instance_new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 8)
    TitleCorner.Parent = Title

    local ToggleButton = Instance_new("TextButton")
    ToggleButton.Name = "ToggleButton"
    ToggleButton.Size = UDim2_new(0.8, 0, 0, 30)
    ToggleButton.Position = UDim2_new(0.1, 0, 0, 40)
    ToggleButton.BackgroundColor3 = Reach.Enabled and Color3_fromRGB(0, 170, 0) or Color3_fromRGB(60, 60, 60)
    ToggleButton.TextColor3 = Color3_fromRGB(255, 255, 255)
    ToggleButton.Text = Reach.Enabled and "Reach: ON" or "Reach: OFF"
    ToggleButton.Font = Enum.Font.Gotham
    ToggleButton.TextSize = 12
    ToggleButton.Parent = MainFrame

    local ToggleCorner = Instance_new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 6)
    ToggleCorner.Parent = ToggleButton

    local RangeLabel = Instance_new("TextLabel")
    RangeLabel.Size = UDim2_new(0.8, 0, 0, 20)
    RangeLabel.Position = UDim2_new(0.1, 0, 0, 80)
    RangeLabel.BackgroundTransparency = 1
    RangeLabel.TextColor3 = Color3_fromRGB(255, 255, 255)
    RangeLabel.Text = "Range:"
    RangeLabel.Font = Enum.Font.Gotham
    RangeLabel.TextSize = 12
    RangeLabel.TextXAlignment = Enum.TextXAlignment.Left
    RangeLabel.Parent = MainFrame

    local RangeTextbox = Instance_new("TextBox")
    RangeTextbox.Size = UDim2_new(0, 70, 0, 20)
    RangeTextbox.Position = UDim2_new(0.5, 0, 0, 80)
    RangeTextbox.BackgroundColor3 = Color3_fromRGB(50, 50, 50)
    RangeTextbox.TextColor3 = Color3_fromRGB(255, 255, 255)
    RangeTextbox.Text = tostring(Reach.Range)
    RangeTextbox.Font = Enum.Font.Gotham
    RangeTextbox.TextSize = 12
    RangeTextbox.PlaceholderText = "14.90"
    RangeTextbox.Parent = MainFrame

    local TextboxCorner = Instance_new("UICorner")
    TextboxCorner.CornerRadius = UDim.new(0, 4)
    TextboxCorner.Parent = RangeTextbox

    local StudsLabel = Instance_new("TextLabel")
    StudsLabel.Size = UDim2_new(0, 30, 0, 20)
    StudsLabel.Position = UDim2_new(0.8, 0, 0, 80)
    StudsLabel.BackgroundTransparency = 1
    StudsLabel.TextColor3 = Color3_fromRGB(200, 200, 200)
    StudsLabel.Text = "studs"
    StudsLabel.Font = Enum.Font.Gotham
    StudsLabel.TextSize = 10
    StudsLabel.TextXAlignment = Enum.TextXAlignment.Left
    StudsLabel.Parent = MainFrame

    local KeybindInfo = Instance_new("TextLabel")
    KeybindInfo.Size = UDim2_new(0.8, 0, 0, 40)
    KeybindInfo.Position = UDim2_new(0.1, 0, 0, 110)
    KeybindInfo.BackgroundTransparency = 1
    KeybindInfo.TextColor3 = Color3_fromRGB(150, 150, 150)
    KeybindInfo.Text = "Keybinds:\n= Toggle Reach | F5 Show/Hide GUI"
    KeybindInfo.Font = Enum.Font.Gotham
    KeybindInfo.TextSize = 10
    KeybindInfo.TextXAlignment = Enum.TextXAlignment.Left
    KeybindInfo.TextYAlignment = Enum.TextYAlignment.Top
    KeybindInfo.Parent = MainFrame

    RangeTextbox.FocusLost:Connect(function(enterPressed)
        if enterPressed then updateReach(RangeTextbox.Text) end
    end)

    ToggleButton.MouseButton1Click:Connect(ToggleReach)

    return ScreenGui
end

local function ToggleGUI()
    if ScreenGui then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
end

local Keybinds = {ToggleReach = Enum.KeyCode.Equals, ToggleGUI = Enum.KeyCode.F5}

local function SetupKeybinds()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Keybinds.ToggleReach then
            ToggleReach()
        elseif input.KeyCode == Keybinds.ToggleGUI then
            ToggleGUI()
        end
    end)
end

local function Initialize()
    local success, err = pcall(WaitForGameLoad)
    if not success then return end
    
    notifyExecuted()
    entitylib.start()
    
    for attempt = 1, 3 do
        if SetupReach() then
            ApplyReach()
            break
        end
        if attempt < 3 then task_wait(0.5) end
    end
    
    ScreenGui = CreateGUI()
    SetupKeybinds()
end

Initialize()
