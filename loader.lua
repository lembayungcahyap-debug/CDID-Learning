--[[
    ╔═══════════════════════════════════════════════════╗
    ║           LunarV2 - Universal Loader              ║
    ║        Car Driving Indonesia Script               ║
    ║              Refactored Edition                   ║
    ╚═══════════════════════════════════════════════════╝
    
    How to use:
    1. Upload LunarV2_Refactored.lua to your GitHub repository
    2. Replace SCRIPT_URL below with your raw GitHub URL
    3. Paste this loader into your executor
    4. Execute and enjoy!
    
    Support: [Your Discord/Support Link]
]]

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

-- 🔧 CHANGE THIS TO YOUR GITHUB RAW URL
local SCRIPT_URL = "https://raw.githubusercontent.com/USERNAME/REPO_NAME/main/LunarV2_Refactored.lua"

-- Script Information
local SCRIPT_INFO = {
    Name = "LunarV2",
    Version = "1.0.0",
    Game = "Car Driving Indonesia",
    LoadTimeout = 30 -- seconds
}

-- ============================================================================
-- LOADER SYSTEM
-- ============================================================================

local Loader = {}
Loader.StartTime = tick()
Loader.Loaded = false

-- Print with styling
function Loader:Print(message, type)
    local prefix = "[" .. SCRIPT_INFO.Name .. "]"
    local color = type == "error" and "[ERROR]" or type == "warn" and "[WARN]" or "[INFO]"
    
    if type == "error" then
        warn(prefix, color, message)
    else
        print(prefix, color, message)
    end
end

-- Check if game is supported
function Loader:CheckGame()
    local success, gameInfo = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    end)
    
    if success then
        self:Print("Game detected: " .. gameInfo.Name, "info")
        
        -- You can add specific game checks here
        local supportedGames = {
            "Car Driving Indonesia",
            "Jawa Tengah",
            "Jawa Barat",
            "An Adventure in the Hidden Temple Event"
        }
        
        local isSupported = false
        for _, gameName in ipairs(supportedGames) do
            if string.find(gameInfo.Name, gameName) then
                isSupported = true
                break
            end
        end
        
        if not isSupported then
            self:Print("Warning: This game might not be fully supported", "warn")
        end
        
        return true
    else
        self:Print("Failed to detect game", "error")
        return false
    end
end

-- Check executor capabilities
function Loader:CheckExecutor()
    self:Print("Checking executor capabilities...", "info")
    
    local capabilities = {
        HttpGet = game.HttpGet ~= nil,
        LoadString = loadstring ~= nil,
        GetObjects = game.GetObjects ~= nil,
        ReadFile = readfile ~= nil,
        WriteFile = writefile ~= nil,
        IsFile = isfile ~= nil,
        MakeFolder = makefolder ~= nil,
        DelFolder = delfolder ~= nil
    }
    
    local essential = {"HttpGet", "LoadString"}
    local allEssentialPresent = true
    
    for feature, isPresent in pairs(capabilities) do
        local status = isPresent and "✅" or "❌"
        self:Print(string.format("%s %s", status, feature), "info")
        
        -- Check essential features
        for _, essentialFeature in ipairs(essential) do
            if feature == essentialFeature and not isPresent then
                allEssentialPresent = false
                self:Print(feature .. " is required but not available!", "error")
            end
        end
    end
    
    if not allEssentialPresent then
        self:Print("Your executor is missing essential features!", "error")
        self:Print("Please use a better executor (Solara, Wave, Synapse, etc.)", "error")
        return false
    end
    
    -- Warnings for optional features
    if not capabilities.WriteFile then
        self:Print("WriteFile not available - Settings will not persist", "warn")
    end
    
    return true
end

-- Download script with retry mechanism
function Loader:DownloadScript(retries)
    retries = retries or 3
    
    for attempt = 1, retries do
        self:Print(string.format("Downloading script... (Attempt %d/%d)", attempt, retries), "info")
        
        local success, result = pcall(function()
            return game:HttpGet(SCRIPT_URL, true)
        end)
        
        if success and result then
            -- Verify it's not an error page
            if string.find(result, "404") or string.find(result, "Not Found") then
                self:Print("Script not found at URL (404 error)", "error")
                return nil
            end
            
            -- Check if it's valid Lua
            if string.find(result, "^%s*%-%-") or string.find(result, "^%s*local") or string.find(result, "^%s*function") then
                self:Print("Script downloaded successfully! (" .. #result .. " bytes)", "info")
                return result
            else
                self:Print("Downloaded content doesn't look like a Lua script", "warn")
            end
        end
        
        if attempt < retries then
            self:Print("Download failed, retrying in 2 seconds...", "warn")
            wait(2)
        end
    end
    
    self:Print("Failed to download script after " .. retries .. " attempts", "error")
    self:Print("Possible issues:", "error")
    self:Print("1. Repository is not public", "error")
    self:Print("2. URL is incorrect", "error")
    self:Print("3. GitHub is down", "error")
    self:Print("4. Executor blocked the request", "error")
    
    return nil
end

-- Execute the script
function Loader:Execute(scriptCode)
    self:Print("Executing script...", "info")
    
    local success, error = pcall(function()
        loadstring(scriptCode)()
    end)
    
    if success then
        self:Loaded = true
        local loadTime = math.floor((tick() - self.StartTime) * 1000) / 1000
        self:Print(string.format("✅ Script loaded successfully in %.2f seconds!", loadTime), "info")
        return true
    else
        self:Print("Execution failed: " .. tostring(error), "error")
        return false
    end
end

-- Main loading function
function Loader:Load()
    -- Print header
    self:Print("=" .. string.rep("=", 50), "info")
    self:Print(SCRIPT_INFO.Name .. " v" .. SCRIPT_INFO.Version, "info")
    self:Print("Game: " .. SCRIPT_INFO.Game, "info")
    self:Print("=" .. string.rep("=", 50), "info")
    
    -- Check game
    if not self:CheckGame() then
        self:Print("Continuing anyway...", "warn")
    end
    
    wait(0.5)
    
    -- Check executor
    if not self:CheckExecutor() then
        return false
    end
    
    wait(0.5)
    
    -- Download script
    local scriptCode = self:DownloadScript(3)
    if not scriptCode then
        return false
    end
    
    wait(0.5)
    
    -- Execute script
    return self:Execute(scriptCode)
end

-- ============================================================================
-- AUTO-UPDATE CHECKER (Optional)
-- ============================================================================

function Loader:CheckForUpdates()
    -- You can implement version checking here
    -- Compare local version with GitHub version
    self:Print("Update checker not implemented yet", "info")
end

-- ============================================================================
-- EXECUTION
-- ============================================================================

-- Check if already loaded
if getgenv and getgenv().LunarV2Loaded then
    Loader:Print("Script is already loaded!", "warn")
    Loader:Print("Please restart if you want to reload", "warn")
    return
end

-- Load the script
local success = Loader:Load()

if success then
    -- Mark as loaded
    if getgenv then
        getgenv().LunarV2Loaded = true
    end
    
    -- Optional: Check for updates
    spawn(function()
        wait(5)
        Loader:CheckForUpdates()
    end)
else
    Loader:Print("Failed to load script", "error")
    Loader:Print("Please check the errors above and try again", "error")
end
