if _G.ReachScriptLoaded then return end
_G.ReachScriptLoaded = true

if not (syn or protect_gui or get_hidden_ui or is_sirhurt_closure or crypt) then
    return
end

if type(queue_on_teleport) == "function" then
    queue_on_teleport([[
        if not (syn or protect_gui) then return end
        loadstring(game:HttpGet("https://raw.githubusercontent.com/HiddenUserAnomaly/Hidden/main/Reach.lua"))()
    ]])
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

-- Pre-calculate constants for faster access
local math_random = math.random
local math_floor = math.floor
local Vector3_new = Vector3.new

local function WaitForGameLoad()
    repeat task.wait() until game:IsLoaded() and Players.LocalPlayer
    
    local LocalPlayer = Players.LocalPlayer
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    
    -- Wait for character to be fully loaded
    local startTime = tick()
    while tick() - startTime < 5 do
        if char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart") then
            break
        end
        task.wait(0.05)
    end
end

local LocalPlayer = Players.LocalPlayer

-- ========== OPTIMIZED ENTITY LIBRARY ==========
local entitylib = {
    isAlive = false,
    character = {},
    List = {},
    Connections = {},
    PlayerConnections = {},
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
    for i, v in pairs(entitylib.List) do
        if v.Player == char or v.Character == char then 
            return v, i 
        end
    end
end

-- Simplified entity addition
entitylib.addEntity = function(char, plr, teamfunc)
    if not char then return end
    
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    
    if hum and hrp then
        local head = char:FindFirstChild("Head") or hrp
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
            entitylib.List[#entitylib.List + 1] = entity
        end
    end
end

entitylib.removeEntity = function(char, localcheck)
    if localcheck then
        if entitylib.isAlive then
            entitylib.isAlive = false
            for _, v in pairs(entitylib.character.Connections) do v:Disconnect() end
            entitylib.character.Connections = {}
        end
        return
    end
    
    if char then
        local entity, ind = entitylib.getEntity(char)
        if ind then
            for _, v in pairs(entity.Connections) do v:Disconnect() end
            entity.Connections = {}
            table.remove(entitylib.List, ind)
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
    
    table.insert(entitylib.Connections, Players.PlayerAdded:Connect(entitylib.addPlayer))
    table.insert(entitylib.Connections, Players.PlayerRemoving:Connect(function(v)
        if entitylib.PlayerConnections[v] then
            for _, c in pairs(entitylib.PlayerConnections[v]) do c:Disconnect() end
            entitylib.PlayerConnections[v] = nil
        end
        entitylib.removeEntity(v.Character)
    end))
    
    for _, v in Players:GetPlayers() do entitylib.addPlayer(v) end
    entitylib.Running = true
end
-- ========== END ENTITY LIBRARY ==========

local Reach = {
    Enabled = true,
    BaseDistance = 14.4,
    MinExtension = 0.7,   -- Minimum reach extension
    MaxExtension = 0.9,   -- Maximum reach extension
    CachedConstants = nil,
    CachedClient = nil
}

-- Fast random reach calculation with pre-computation
local lastRandomExtension = 0
local lastExtensionTime = 0
local EXTENSION_COOLDOWN = 0.5 

local function GetDynamicReach()
    local currentTime = tick()
    if currentTime - lastExtensionTime > EXTENSION_COOLDOWN then
        lastRandomExtension = math_random(70, 90) / 100 -- 0.7 to 0.9
        lastExtensionTime = currentTime
    end
    return Reach.BaseDistance + lastRandomExtension
end

-- FIXED reach calculation - properly extends reach
local function calculateReachExtension(selfpos, targetpos, currentDistance)
    if currentDistance <= Reach.BaseDistance then 
        return selfpos, false
    end
    
    local dynamicReach = GetDynamicReach()
    
    -- Always extend, but cap at maximum reach
    local extensionAmount = math.min(currentDistance - Reach.BaseDistance, dynamicReach - Reach.BaseDistance)
    
    local dx, dy, dz = targetpos.X - selfpos.X, targetpos.Y - selfpos.Y, targetpos.Z - selfpos.Z
    local invMagnitude = 1 / currentDistance
    
    -- CORRECT: Normalize direction first, then apply extension
    return Vector3_new(
        selfpos.X + (dx * invMagnitude) * extensionAmount,
        selfpos.Y + (dy * invMagnitude) * extensionAmount,
        selfpos.Z + (dz * invMagnitude) * extensionAmount
    ), false
end

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
                    
                    local validate = attackTable.validate
                    
                    local selfpos = validate.selfPosition.value
                    local targetpos = validate.targetPosition.value
                    
                    -- Fast distance calculation
                    local delta = targetpos - selfpos
                    local distance = delta.Magnitude
                    
                    local newSelfPos, shouldBlock = calculateReachExtension(selfpos, targetpos, distance)
                    
                    if shouldBlock then
                        return nil
                    end
                    
                    -- Apply reach extension immediately
                    validate.selfPosition.value = newSelfPos
                    
                    return originalSend(call, attackTable, ...)
                end
            }
        end
        
        return call
    end
    
    Reach.CachedClient = Client
    return true
end

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
    
    Reach.CachedConstants.RAYCAST_SWORD_CHARACTER_DISTANCE = Reach.Enabled and GetDynamicReach() or Reach.BaseDistance
    return true
end

-- Webhook functions (optimized)
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
    
    coroutine.wrap(function()
        pcall(function()
            HttpRequest({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(payload)
            })
        end)
    end)()
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

local function ToggleReach()
    Reach.Enabled = not Reach.Enabled
    ApplyReach()
    
    coroutine.wrap(function()
        if ScreenGui then
            local ToggleButton = ScreenGui:FindFirstChild("ToggleButton", true)
            if ToggleButton then
                ToggleButton.Text = Reach.Enabled and "Reach: ON" or "Reach: OFF"
                ToggleButton.BackgroundColor3 = Reach.Enabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(60,60,60)
            end
        end
        notifyReachState(Reach.Enabled)
    end)()
end

-- Optimized GUI creation
local ScreenGui = nil

local function CreateGUI()
    local uiParent = game:GetService("CoreGui")
    
    local existingGui = uiParent:FindFirstChild("ReachGUI")
    if existingGui then
        ScreenGui = existingGui
        ScreenGui.Enabled = false
        return ScreenGui
    end

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ReachGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Enabled = false
    ScreenGui.Parent = uiParent

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 200, 0, 120)
    MainFrame.Position = UDim2.new(0, 10, 0, 10)
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "ToggleButton"
    ToggleButton.Size = UDim2.new(0.8, 0, 0, 30)
    ToggleButton.Position = UDim2.new(0.1, 0, 0, 40)
    ToggleButton.BackgroundColor3 = Reach.Enabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.Text = Reach.Enabled and "Reach: ON" or "Reach: OFF"
    ToggleButton.TextSize = 12
    ToggleButton.Parent = MainFrame

    local KeybindInfo = Instance.new("TextLabel")
    KeybindInfo.Size = UDim2.new(0.8, 0, 0, 40)
    KeybindInfo.Position = UDim2.new(0.1, 0, 0, 80)
    KeybindInfo.BackgroundTransparency = 1
    KeybindInfo.TextColor3 = Color3.fromRGB(150, 150, 150)
    KeybindInfo.Text = "Keybinds:\n= Toggle Reach | F5 Show/Hide GUI"
    KeybindInfo.TextSize = 10
    KeybindInfo.TextXAlignment = Enum.TextXAlignment.Left
    KeybindInfo.TextYAlignment = Enum.TextYAlignment.Top
    KeybindInfo.Parent = MainFrame

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
    local success = pcall(WaitForGameLoad)
    if not success then return end
    
    notifyExecuted()
    entitylib.start() -- Start entity tracking
    
    if SetupReach() then
        ApplyReach()
    end
    
    ScreenGui = CreateGUI()
    SetupKeybinds()
end

Initialize()
