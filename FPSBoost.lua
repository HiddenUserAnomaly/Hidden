-- ✅ Arceus X Neo Optimized FPS Boost (No Avatar Removal, No Lag Spike)

if setfpscap then setfpscap(165) end

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChildOfClass("Terrain")
local HttpService = game:GetService("HttpService")
local AnalyticsService = game:GetService("AnalyticsService")
local LogService = game:GetService("LogService")

-- 🔒 Disable telemetry
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

-- 🚀 FPS Boost Core
local function fpsBoost()
    -- Lighting
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

    -- Terrain
    if Terrain then
        Terrain.WaterWaveSize = 0
        Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 1
    end

    -- Workspace cleanup
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

    -- ViewportFrames (UI 3D rendering)
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("ViewportFrame") then
            obj:Destroy()
        end
    end

    -- Lower quality setting
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

-- 🔇 Disable camera shake
local function blockCameraShake()
    local cam = workspace:FindFirstChildOfClass("Camera")
    if cam then
        cam.CameraType = Enum.CameraType.Custom
        cam.CameraSubject = Players.LocalPlayer.Character or cam.CameraSubject
    end
end

-- 🧠 Hook for future explosions
workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Explosion") then
        pcall(function()
            obj.BlastPressure = 0
            obj.BlastRadius = 1
            obj.DestroyJointRadiusPercent = 0
        end)
    end
end)

-- 🚀 Initial optimization
fpsBoost()
reduceExplosions()
blockCameraShake()

-- 🔁 Lightweight loop every 10s using task.defer (minimizes lag)
task.spawn(function()
    while true do
        task.defer(fpsBoost)
        task.defer(reduceExplosions)
        task.defer(blockCameraShake)
        wait(10)
    end
end)

print("[+] Optimized FPS Boost Enabled ✅ | Hats & Clothing KEPT | No Lag Spikes")
