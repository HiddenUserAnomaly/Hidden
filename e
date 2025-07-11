local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Terrain = Workspace:FindFirstChildOfClass("Terrain")

-- Flatten lighting
Lighting.GlobalShadows = false
Lighting.EnvironmentDiffuseScale = 0
Lighting.EnvironmentSpecularScale = 0
Lighting.Brightness = Lighting.Brightness * 0.5
Lighting.Outlines = false
Lighting.Technology = Enum.Technology.Compatibility

-- Disable post-processing effects
for _, effect in ipairs(Lighting:GetChildren()) do
	if effect:IsA("BlurEffect")
	or effect:IsA("BloomEffect")
	or effect:IsA("ColorCorrectionEffect")
	or effect:IsA("SunRaysEffect")
	or effect:IsA("DepthOfFieldEffect") then
		effect.Enabled = false
	end
end

-- Remove atmosphere
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
if atmosphere then
	atmosphere.Density = 0
	atmosphere.Haze = 0
end

-- Force render distance long
Lighting.FogEnd = 100000
Lighting.FogStart = 0

-- Disable terrain decoration
if Terrain then
	Terrain.Decoration = false
end

-- Process all workspace items once
for _, obj in ipairs(Workspace:GetDescendants()) do
	if Players:GetPlayerFromCharacter(obj.Parent) then
		continue
	end

	-- Mesh simplification
	if obj:IsA("MeshPart") then
		obj.Material = Enum.Material.Plastic
		obj.TextureID = ""
	end

	-- Remove decals
	if obj:IsA("Decal") then
		obj.Texture = ""
	end

	-- Disable particles and trails
	if obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
		obj.Enabled = false
	end

	-- Disable beams
	if obj:IsA("Beam") then
		obj.Enabled = false
	end

	-- Dim and stop sounds
	if obj:IsA("Sound") then
		obj.Volume = obj.Volume * 0.5
		obj.Looped = false
		obj.RollOffMode = Enum.RollOffMode.Linear
		obj.Playing = false
	end

	-- Anchor loose parts (reduces physics overhead)
	if obj:IsA("BasePart") and not obj.Anchored then
		obj.Anchored = true
	end

	-- Remove local lights
	if obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
		obj.Enabled = false
	end

	-- Optional: Disable Humanoid scaling (commented out to avoid breaking characters)
	-- if obj:IsA("Humanoid") then
	--     obj.AutomaticScalingEnabled = false
	-- end
end

print("✅ Ultimate Ultra-Low Graphics applied. UI retained. One-time application only.")
