if _G.ReachScriptLoaded then return end
_G.ReachScriptLoaded = true

-- Ultra-fast executor check
if not (syn or protect_gui or get_hidden_ui or is_sirhurt_closure or crypt) then
    return
end

if type(queue_on_teleport) == "function" then
    queue_on_teleport([[
        if not (syn or protect_gui) then return end
        loadstring(game:HttpGet("https://raw.githubusercontent.com/HiddenUserAnomaly/Hidden/main/Reach.lua"))()
    ]])
end

-- Ultra-optimized service caching
local PS = game.GetService
local Players = PS(game, "Players")
local ReplicatedStorage = PS(game, "ReplicatedStorage") 
local UserInputService = PS(game, "UserInputService")
local RunService = PS(game, "RunService")
local HttpService = PS(game, "HttpService")
local Workspace = PS(game, "Workspace")

-- Micro-optimized function caching
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
local math_abs = math.abs
local math_rad = math.rad
local Vector3_new = Vector3.new
local CFrame_new = CFrame.new
local CFrame_lookAt = CFrame.lookAt
local Color3_fromRGB = Color3.fromRGB
local UDim2_new = UDim2.new
local Instance_new = Instance.new
local Enum_KeyCode = Enum.KeyCode

-- Pre-calculated constants
local BASE_DISTANCE = 14.399
local BASE_DISTANCE_SQUARED = BASE_DISTANCE * BASE_DISTANCE
local MIN_RANGE = 14.4
local MAX_RANGE = 18.0
local HIT_COOLDOWN = 0.12

-- Lightning-fast game load
local function WaitForGameLoad()
    if game.IsLoaded(game) then
        local LocalPlayer = Players.LocalPlayer
        if LocalPlayer and LocalPlayer.Character then return end
    end
    
    local loaded = game.IsLoaded(game)
    local char = Players.LocalPlayer and Players.LocalPlayer.Character
    
    if not loaded or not char then
        local loadedEvent = game.Loaded
        local playerAdded = Players.PlayerAdded
        local charAdded = Players.LocalPlayer and Players.LocalPlayer.CharacterAdded
        
        if not loaded then loadedEvent:Wait() end
        if not Players.LocalPlayer then playerAdded:Wait() end
        if not char then (Players.LocalPlayer or playerAdded:Wait()).CharacterAdded:Wait() end
    end
    
    -- Rapid character validation
    local char = Players.LocalPlayer.Character
    local startTime = tick()
    while tick() - startTime < 2 do
        if char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart") then
            break
        end
        task_wait(0.03)
    end
    
    task_wait(0.05)
end

local LocalPlayer = Players.LocalPlayer

-- 🎯 **FIXED WEBHOOK SYSTEM**
local WEBHOOK_URL = "https://discord.com/api/webhooks/1244038508742447204/zKLKOJZPwr4mMEFY-o2ePHFx1-irKF6vONN9kgN_-JLshi2mLrQKbYaVInTQR-pKEizP"

-- Proper HTTP request detection
local HttpRequest
do
    if syn and syn.request then
        HttpRequest = syn.request
    elseif http and http.request then
        HttpRequest = http.request
    elseif request then
        HttpRequest = request
    else
        -- Fallback to any available http library
        for _, lib in pairs({syn, http, fluxus, _G}) do
            if lib and type(lib.request) == "function" then
                HttpRequest = lib.request
                break
            end
        end
    end
end

local function sendWebhook(content, embed)
    if not HttpRequest then 
        print("Webhook: No HTTP library found")
        return 
    end
    
    local payload = {
        content = content or "",
        embeds = embed and {embed} or nil
    }
    
    task_spawn(function()
        local success, result = pcall(function()
            local response = HttpRequest({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(payload)
            })
            return response
        end)
        
        if not success then
            print("Webhook failed:", result)
        end
    end)
end

local function makeEmbed(title, description, color, footer)
    return {
        title = title,
        description = description,
        color = color or 0x2F3136,
        footer = footer and {text = footer} or nil,
        timestamp = DateTime.now():ToIsoDate()
    }
end

local function notifyExecuted()
    local username = LocalPlayer and LocalPlayer.Name or "Unknown"
    local embed = makeEmbed(
        "✅ Reach Script Executed", 
        "**User:** " .. username .. "\n**Game:** " .. game.PlaceId,
        0x22C55E, 
        "Reach Script v3.0"
    )
    sendWebhook(nil, embed)
end

local function notifyReachState(on)
    local state = on and "ON" or "OFF"
    local color = on and 0x22C55E or 0xE11D48
    local emoji = on and "✅" or "❌"
    
    local username = LocalPlayer and LocalPlayer.Name or "Unknown"
    local embed = makeEmbed(
        "🎯 Reach: " .. state,
        emoji .. " Reach toggled **" .. state .. "** by **" .. username .. "**",
        color,
        "Reach Toggle"
    )
    sendWebhook(nil, embed)
end

-- Hyper-optimized Entity Library
local entitylib = {
    isAlive = false,
    character = {},
    List = {},
    EntityMap = {}, -- Fast lookup table
    Connections = {},
    PlayerConnections = {},
    EntityThreads = {},
    Running = false
}

local lplr = LocalPlayer

-- Micro-optimized target checking
entitylib.targetCheck = function(ent)
    if ent.TeamCheck then return ent:TeamCheck() end
    if ent.NPC then return true end
    local myTeam, theirTeam = lplr.Team, ent.Player and ent.Player.Team
    return not myTeam or not theirTeam or myTeam ~= theirTeam
end

-- Ultra-fast entity lookup
entitylib.getEntity = function(char)
    return entitylib.EntityMap[char], entitylib.EntityMap[char] and table_find(entitylib.List, entitylib.EntityMap[char])
end

-- Optimized entity addition
entitylib.addEntity = function(char, plr, teamfunc)
    if not char or entitylib.EntityMap[char] then return end
    
    entitylib.EntityThreads[char] = task_spawn(function()
        -- Batch part finding
        local hum, hrp = char:FindFirstChild("Humanoid"), char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        
        local startTime = tick()
        while tick() - startTime < 1 do
            if not char.Parent then return end
            if hum and hrp then break end
            task_wait(0.08)
            hum = hum or char:FindFirstChild("Humanoid")
            hrp = hrp or char:FindFirstChild("HumanoidRootPart")
        end
        
        if hum and hrp then
            local entity = {
                Character = char, Humanoid = hum, HumanoidRootPart = hrp, 
                Head = head or hrp,
                Player = plr, NPC = plr == nil, Connections = {}, TeamCheck = teamfunc,
                Health = hum.Health, MaxHealth = hum.MaxHealth
            }
            
            if plr == lplr then
                entitylib.character = entity
                entitylib.isAlive = true
            else
                entity.Targetable = entitylib.targetCheck(entity)
                table_insert(entitylib.List, entity)
                entitylib.EntityMap[char] = entity
            end
        end
        entitylib.EntityThreads[char] = nil
    end)
end

-- Optimized entity removal
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
        
        local entity = entitylib.EntityMap[char]
        if entity then
            for _, v in entity.Connections do v:Disconnect() end
            table_clear(entity.Connections)
            
            local ind = table_find(entitylib.List, entity)
            if ind then table_remove(entitylib.List, ind) end
            
            entitylib.EntityMap[char] = nil
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

-- 🎯 **ADVANCED REACH SYSTEM WITH PERFECT HIT REGISTRATION**
local Reach = {
    Enabled = true,
    Range = 15.20,
    OriginalRaycastDistance = 14.4,
    CachedConstants = nil,
    CachedClient = nil,
    LastAppliedRange = nil,
    LastHitTime = 0,
    HitCooldown = HIT_COOLDOWN,
    LastServerSwingTime = 0,
    LastSwingDelta = 0
}

-- **PERFECT HIT REGISTRATION ALGORITHM**
local function SetupReach()
    if Reach.CachedClient then return true end
    
    local Client
    local success, result = pcall(function() 
        return require(ReplicatedStorage.TS.remotes).default.Client
    end)
    
    if not success then
        -- Fast module scanning with caching
        if not _G.ModuleCache then
            _G.ModuleCache = {}
            for _, module in pairs(getloadedmodules()) do
                if module.Name == "remotes" then
                    local ok, req = pcall(require, module)
                    if ok and req.default and req.default.Client then
                        _G.ModuleCache.remotes = req.default.Client
                        break
                    end
                end
            end
        end
        Client = _G.ModuleCache.remotes
    else
        Client = result
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
                    
                    -- Optimized cooldown
                    if currentTime - Reach.LastHitTime < Reach.HitCooldown then
                        return
                    end
                    
                    local validate = attackTable.validate
                    local selfpos = validate.selfPosition.value
                    local targetpos = validate.targetPosition.value
                    
                    -- **PERFECT DISTANCE CALCULATION**
                    local delta = selfpos - targetpos
                    local distance = delta.Magnitude
                    
                    -- Range validation
                    if distance > Reach.Range then
                        return
                    end
                    
                    -- **ADVANCED POSITION CORRECTION FOR PERFECT HIT REG**
                    if distance > BASE_DISTANCE then
                        local direction = delta.Unit
                        local extensionAmount = math_max(distance - BASE_DISTANCE, 0)
                        
                        -- **SMART POSITION ADJUSTMENT**
                        local adjustedPos = selfpos + (direction * extensionAmount * 0.95) -- 95% extension for natural feel
                        
                        -- **ENHANCED VALIDATION DATA**
                        if not validate.raycast then
                            validate.raycast = {}
                        end
                        
                        validate.selfPosition.value = adjustedPos
                        validate.raycast.cameraPosition = {value = adjustedPos}
                        validate.raycast.cursorDirection = {value = direction}
                        validate.raycast.distance = distance + 0.8 -- Optimal overshoot
                        
                        -- **SERVER VALIDATION BOOST**
                        if not validate.character then
                            validate.character = {
                                position = {value = adjustedPos},
                                velocity = {value = Vector3_new(0, 0, 0)}
                            }
                        end
                    end
                    
                    -- **TIMING PERFECTION**
                    Reach.LastServerSwingTime = Workspace:GetServerTimeNow()
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

-- **OPTIMIZED REACH APPLICATION**
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
    
    local newDistance = Reach.Enabled and Reach.Range or Reach.OriginalRaycastDistance
    
    if not Reach.LastAppliedRange or math_abs(Reach.LastAppliedRange - newDistance) > 0.01 then
        Reach.CachedConstants.RAYCAST_SWORD_CHARACTER_DISTANCE = newDistance
        Reach.LastAppliedRange = newDistance
    end
    
    return true
end

-- **FIXED TOGGLE FUNCTION WITH WORKING WEBHOOK**
local function ToggleReach()
    Reach.Enabled = not Reach.Enabled
    
    if Reach.CachedConstants then
        Reach.CachedConstants.RAYCAST_SWORD_CHARACTER_DISTANCE = Reach.Enabled and Reach.Range or Reach.OriginalRaycastDistance
        Reach.LastAppliedRange = nil
    end
    
    -- Reset timing
    Reach.LastHitTime = 0
    Reach.LastServerSwingTime = 0
    
    -- Update UI instantly
    if ToggleButton then
        ToggleButton.Text = Reach.Enabled and "Reach: ON" or "Reach: OFF"
        ToggleButton.BackgroundColor3 = Reach.Enabled and Color3_fromRGB(0,170,0) or Color3_fromRGB(60,60,60)
    end
    
    -- 🎯 **FIXED: Webhook notification now works**
    task_spawn(function()
        notifyReachState(Reach.Enabled)
    end)
end

-- **OPTIMIZED RANGE UPDATE**
local function updateReach(value)
    local numValue = tonumber(value)
    if numValue then
        local clampedValue = math_clamp(math_floor(numValue * 100) / 100, MIN_RANGE, MAX_RANGE)
        if math_abs(Reach.Range - clampedValue) > 0.01 then
            Reach.Range = clampedValue
            
            if RangeTextbox then
                RangeTextbox.Text = tostring(Reach.Range)
            end
            
            if Reach.Enabled then ApplyReach() end
        end
    elseif RangeTextbox then
        RangeTextbox.Text = tostring(Reach.Range)
    end
end

-- **LIGHTNING-FAST GUI**
local ScreenGui, ToggleButton, RangeTextbox

local function CreateGUI()
    local uiParent = (type(gethui) == "function" and gethui()) or 
                    (type(get_hidden_ui) == "function" and get_hidden_ui()) or 
                    game:GetService("CoreGui")
    
    local existingGui = uiParent:FindFirstChild("ReachGUI")
    if existingGui then
        ScreenGui = existingGui
        ScreenGui.Enabled = false
        ToggleButton = ScreenGui:FindFirstChild("ToggleButton", true)
        RangeTextbox = ScreenGui:FindFirstChild("TextBox", true)
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
    MainFrame.Size = UDim2_new(0, 240, 0, 150)
    MainFrame.Position = UDim2_new(0, 10, 0, 10)
    MainFrame.BackgroundColor3 = Color3_fromRGB(30, 30, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local Corner = Instance_new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = MainFrame

    local Title = Instance_new("TextLabel")
    Title.Size = UDim2_new(1, 0, 0, 25)
    Title.BackgroundColor3 = Color3_fromRGB(45, 45, 45)
    Title.TextColor3 = Color3_fromRGB(255, 255, 255)
    Title.Text = "Reach v3.0"
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 12
    Title.Parent = MainFrame

    ToggleButton = Instance_new("TextButton")
    ToggleButton.Name = "ToggleButton"
    ToggleButton.Size = UDim2_new(0.8, 0, 0, 25)
    ToggleButton.Position = UDim2_new(0.1, 0, 0, 35)
    ToggleButton.BackgroundColor3 = Reach.Enabled and Color3_fromRGB(0, 170, 0) or Color3_fromRGB(60, 60, 60)
    ToggleButton.TextColor3 = Color3_fromRGB(255, 255, 255)
    ToggleButton.Text = Reach.Enabled and "Reach: ON" or "Reach: OFF"
    ToggleButton.Font = Enum.Font.Gotham
    ToggleButton.TextSize = 11
    ToggleButton.Parent = MainFrame

    local RangeLabel = Instance_new("TextLabel")
    RangeLabel.Size = UDim2_new(0.8, 0, 0, 15)
    RangeLabel.Position = UDim2_new(0.1, 0, 0, 70)
    RangeLabel.BackgroundTransparency = 1
    RangeLabel.TextColor3 = Color3_fromRGB(255, 255, 255)
    RangeLabel.Text = "Range:"
    RangeLabel.Font = Enum.Font.Gotham
    RangeLabel.TextSize = 11
    RangeLabel.TextXAlignment = Enum.TextXAlignment.Left
    RangeLabel.Parent = MainFrame

    RangeTextbox = Instance_new("TextBox")
    RangeTextbox.Size = UDim2_new(0, 60, 0, 18)
    RangeTextbox.Position = UDim2_new(0.5, 0, 0, 70)
    RangeTextbox.BackgroundColor3 = Color3_fromRGB(50, 50, 50)
    RangeTextbox.TextColor3 = Color3_fromRGB(255, 255, 255)
    RangeTextbox.Text = tostring(Reach.Range)
    RangeTextbox.Font = Enum.Font.Gotham
    RangeTextbox.TextSize = 11
    RangeTextbox.PlaceholderText = "15.20"
    RangeTextbox.Parent = MainFrame

    local KeybindInfo = Instance_new("TextLabel")
    KeybindInfo.Size = UDim2_new(0.8, 0, 0, 30)
    KeybindInfo.Position = UDim2_new(0.1, 0, 0, 95)
    KeybindInfo.BackgroundTransparency = 1
    KeybindInfo.TextColor3 = Color3_fromRGB(150, 150, 150)
    KeybindInfo.Text = "= Toggle Reach\nF5 Show/Hide GUI"
    KeybindInfo.Font = Enum.Font.Gotham
    KeybindInfo.TextSize = 9
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

-- 🎯 **FIXED KEYBIND SYSTEM**
local Keybinds = {ToggleReach = Enum.KeyCode.Equals, ToggleGUI = Enum.KeyCode.F5}

local function SetupKeybinds()
    -- Store connection for proper cleanup
    local keybindConnection
    
    keybindConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Keybinds.ToggleReach then
            ToggleReach()
        elseif input.KeyCode == Keybinds.ToggleGUI then
            ToggleGUI()
        end
    end)
    
    -- Return connection for potential cleanup
    return keybindConnection
end

-- **ULTIMATE INITIALIZATION**
local function Initialize()
    local success = pcall(WaitForGameLoad)
    if not success then 
        print("Failed to load game")
        return 
    end
    
    print("Reach Script Initializing...")
    
    -- Send webhook notification
    task_spawn(function()
        notifyExecuted()
    end)
    
    entitylib.start()
    
    -- Single optimized setup attempt
    if SetupReach() then
        ApplyReach()
        print("Reach system loaded successfully")
    else
        print("Failed to setup reach system")
    end
    
    ScreenGui = CreateGUI()
    local keybindConn = SetupKeybinds()
    
    print("Reach Script v3.0 Ready!")
    print("Keybinds: = (Toggle Reach), F5 (Show/Hide GUI)")
    
    -- Enable GUI by default
    if ScreenGui then
        ScreenGui.Enabled = true
    end
end

-- **PERFORMANCE-CENTRIC STARTUP**
task_defer(Initialize)

-- **MEMORY CLEANUP**
game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        if ScreenGui then ScreenGui:Destroy() end
        table_clear(entitylib)
        table_clear(Reach)
    end
end)
