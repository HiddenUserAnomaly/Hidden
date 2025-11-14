_G.ReachScriptLoaded = true

-- Quick executor check
if not (syn or protect_gui or get_hidden_ui or is_sirhurt_closure or crypt) then
    return
end

if type(queue_on_teleport) == "function" then
    queue_on_teleport([[
        if not (syn or protect_gui) then return end
        loadstring(game:HttpGet("https://raw.githubusercontent.com/HiddenUserAnomaly/Hidden/main/Reach.lua"))()
    ]])
end

-- Cache frequently used functions
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local math_clamp = math.clamp
local math_floor = math.floor
local Vector3_new = Vector3.new
local Color3_fromRGB = Color3.fromRGB
local UDim2_new = UDim2.new
local Instance_new = Instance.new

-- Fast game load
local function WaitForGameLoad()
    repeat task.wait() until game:IsLoaded()
    
    local LocalPlayer = Players.LocalPlayer
    if not LocalPlayer then
        LocalPlayer = Players.PlayerAdded:Wait()
    end
    
    local char = LocalPlayer.Character
    if not char then
        char = LocalPlayer.CharacterAdded:Wait()
    end
    
    local startTime = tick()
    while tick() - startTime < 5 do
        if char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart") then
            break
        end
        task.wait(0.05)
    end
    
    local maxWait, startTime = 10, tick()
    while tick() - startTime < maxWait do
        local success = pcall(function()
            local TS = ReplicatedStorage:FindFirstChild("TS")
            return TS and require(TS.remotes).default.Client
        end)
        if success then break end
        task.wait(0.1)
    end
    
    task.wait(0.2)
end

local LocalPlayer = Players.LocalPlayer

-- Reach Configuration
local Reach = {
    Enabled = true,
    BaseDistance = 14.4,
    TargetRange = 15.15,  -- Consistent 15.15 studs
    CachedConstants = nil,
    CachedClient = nil
}

-- Simple reach calculation
local function calculateReachExtension(selfpos, targetpos, currentDistance)
    if currentDistance <= Reach.BaseDistance then 
        return selfpos, false
    end
    
    if currentDistance > Reach.TargetRange then
        return selfpos, true
    end
    
    local direction = (targetpos - selfpos).Unit
    local extensionAmount = currentDistance - Reach.BaseDistance
    
    return selfpos + (direction * extensionAmount), false
end

-- FIXED reach setup - matches your working script structure
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
                    local distance = (selfpos - targetpos).Magnitude
                    
                    -- Calculate extension and check if we should block
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

-- Fast reach application
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
    
    -- Apply reach
    Reach.CachedConstants.RAYCAST_SWORD_CHARACTER_DISTANCE = Reach.Enabled and Reach.TargetRange or Reach.BaseDistance
    return true
end

-- Webhook functions
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
    
    spawn(function()
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

local function ToggleReach()
    Reach.Enabled = not Reach.Enabled
    
    if Reach.CachedConstants then
        Reach.CachedConstants.RAYCAST_SWORD_CHARACTER_DISTANCE = Reach.Enabled and Reach.TargetRange or Reach.BaseDistance
    end
    
    coroutine.wrap(function()
        if ScreenGui then
            local ToggleButton = ScreenGui:FindFirstChild("ToggleButton", true)
            if ToggleButton then
                ToggleButton.Text = Reach.Enabled and "Reach: ON" or "Reach: OFF"
                ToggleButton.BackgroundColor3 = Reach.Enabled and Color3_fromRGB(0,170,0) or Color3_fromRGB(60,60,60)
            end
        end
        notifyReachState(Reach.Enabled)
    end)()
end

local function updateReach(value)
    local numValue = tonumber(value)
    if numValue then
        Reach.TargetRange = math_clamp(math_floor(numValue * 100) / 100, 14.5, 16)
        
        if ScreenGui then
            local RangeTextbox = ScreenGui:FindFirstChild("TextBox", true)
            if RangeTextbox then
                RangeTextbox.Text = tostring(Reach.TargetRange)
            end
        end
        
        if Reach.Enabled then ApplyReach() end
    elseif ScreenGui then
        local RangeTextbox = ScreenGui:FindFirstChild("TextBox", true)
        if RangeTextbox then
            RangeTextbox.Text = tostring(Reach.TargetRange)
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
    RangeTextbox.Text = tostring(Reach.TargetRange)
    RangeTextbox.Font = Enum.Font.Gotham
    RangeTextbox.TextSize = 12
    RangeTextbox.PlaceholderText = "15.15"
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
    
    -- Setup reach with multiple attempts
    for attempt = 1, 5 do
        if SetupReach() then
            ApplyReach()
            break
        end
        if attempt < 5 then task.wait(0.3) end
    end
    
    ScreenGui = CreateGUI()
    SetupKeybinds()
end

Initialize()
