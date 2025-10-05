-- WhitelistLibrary.lua
-- Simple whitelist system for any script

local WhitelistLibrary = {
    WhitelistURL = "https://raw.githubusercontent.com/HiddenUserAnomaly/Hidden/refs/heads/main/Whitelist"
}

-- Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- Get local player
local localPlayer = Players.LocalPlayer
local username = localPlayer.Name

-- Fetch whitelist from GitHub
function WhitelistLibrary:FetchWhitelist()
    local success, response = pcall(function()
        return HttpService:GetAsync(self.WhitelistURL)
    end)
    
    if success and response then
        local whitelist = {}
        for line in response:gmatch("[^\r\n]+") do
            local cleanUsername = line:gsub("%s+", "") -- Remove whitespace
            if cleanUsername ~= "" then
                table.insert(whitelist, cleanUsername:lower())
            end
        end
        return whitelist
    end
    
    return nil
end

-- Check if user is whitelisted
function WhitelistLibrary:IsWhitelisted()
    local whitelist = self:FetchWhitelist()
    
    if not whitelist then
        warn("[WhitelistLibrary] Failed to fetch whitelist from GitHub")
        return false
    end
    
    -- Check if username is in whitelist (case-insensitive)
    local lowerUsername = username:lower()
    for _, whitelistedUser in ipairs(whitelist) do
        if whitelistedUser == lowerUsername then
            return true
        end
    end
    
    return false
end

-- Initialize script with whitelist check
function WhitelistLibrary:InitializeScript(scriptName)
    -- Check whitelist
    if not self:IsWhitelisted() then
        warn("[" .. username .. "] is not whitelisted to use " .. scriptName)
        return false
    end
    
    print("Welcome, " .. username .. "! " .. scriptName .. " execution authorized.")
    return true
end

return WhitelistLibrary
