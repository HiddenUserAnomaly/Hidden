-- ✅ Arceus X Neo - Full FPS Boost, Telemetry Block, Explosion & Screen Shake Reducer

if setfpscap then setfpscap(165) end -- Optional FPS cap if supported

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChildOfClass("Terrain")
local HttpService = game:GetService("HttpService")
local AnalyticsService = game:GetService("AnalyticsService")
local LogService = game:GetService("LogService")

-- 🔒 Disable telemetry functions
pcall(function()
    HttpService.HttpEnabled = false
    hookfunction(HttpService.GetAsync, function() return nil end)
    hookfunction(HttpService.PostAsync, function() return nil end)
    hookfunction(HttpService.RequestAsync, function() return nil end)

    for _, service in ipairs({HttpService, AnalyticsService, LogService}) do
        for key, func in pairs(getmetatable(service)) do
            if typeof(func) == "function" then
                hookfunction(func, function() return nil end)
            end
        end
    end
end)

-- 🚀 FPS Boost Function
local function fpsBoost()
    -- Lighting Cleanup
    Lighting.GlobalShadows = false
    Lighting.FogEnd = math.huge
    Lighting.Brightness = 1
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0
    Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
    Lighting.Ambient = Color3.new(0.5, 0.5, 0.5)
    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("BlurEffect") or effect:IsA("SunRaysEffect") or effect:IsA("BloomEffect") or effect:IsA("ColorCorrectionEffect") then
            effect.Enabled = false
        end
    end

    -- Terrain Optimization
    if Terrain then
        Terrain.WaterWaveSize = 0
        Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 1
    end

    -- Workspace Visual Cleanup
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance = 0
            obj.CastShadow = false
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Transparency = 1
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") then
            obj.Enabled = false
            if obj:IsA("ParticleEmitter") then
                obj.Lifetime = NumberRange.new(0)
                obj.Rate = 0
                obj.Size = NumberSequence.new(0)
                obj.Transparency = NumberSequence.new(1)
                obj.Speed = NumberRange.new(0)
            end
        elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
            obj.Enabled = false
        elseif obj:IsA("MeshPart") then
            obj.TextureID = ""
        elseif obj:IsA("SpecialMesh") then
            obj.TextureId = ""
        end
    end

    -- Character Cleanup
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            for _, obj in pairs(player.Character:GetDescendants()) do
                if obj:IsA("Accessory") or obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Decal") then
                    obj:Destroy()
                end
            end
        end
    end

    -- ViewportFrames in UI
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("ViewportFrame") then
            obj:Destroy()
        end
    end

    -- Lower graphics quality (optional)
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
end

-- 💥 Explosion Reducer
local function reduceExplosions()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Explosion") then
            pcall(function()
                obj.BlastPressure = 0
                obj.BlastRadius = 1
                obj.DestroyJointRadiusPercent = 0
            end)
        end
    end
end

-- 📉 Screen Shake Blocker (Camera manipulation prevention)
local function blockCameraShake()
    local cam = workspace:FindFirstChildOfClass("Camera")
    if cam then
        cam.CameraSubject = Players.LocalPlayer.Character or cam.CameraSubject
        cam.CameraType = Enum.CameraType.Custom
    end
end

-- Live hook for future explosions
workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Explosion") then
        pcall(function()
            obj.BlastPressure = 0
            obj.BlastRadius = 1
            obj.DestroyJointRadiusPercent = 0
        end)
    end
end)

-- 🚀 Initial Boost
fpsBoost()
reduceExplosions()
blockCameraShake()

-- 🔁 Loop every 10 seconds to maintain performance
task.spawn(function()
    while true do
        fpsBoost()
        reduceExplosions()
        blockCameraShake()
        task.wait(10)
    end
end)

print("[+] Full FPS Boost, Telemetry Block, and Explosion Reduction Active ✅")