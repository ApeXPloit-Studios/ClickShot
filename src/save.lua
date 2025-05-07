local save = {}

-- Constants
local SAVE_FILE = "ClickShot.dat"
local BACKUP_FILE = "ClickShot.bak"

-- Default save data structure
local DEFAULT_SAVE = {
            shells = 0,
            cosmetics = {},
            equipped = {},
            equipped_weapon = "pistol",
            upgrades = {}
        }

-- Create a deep copy of a table
local function deepCopy(original)
    local copy
    if type(original) == "table" then
        copy = {}
        for k, v in pairs(original) do
            copy[k] = deepCopy(v)
        end
    else
        copy = original
    end
    return copy
end

-- Safely serialize a table to a string (no cycles)
function save.serialize(t, indent)
    if type(t) ~= "table" then
        return tostring(t)
    end
    
    indent = indent or ""
    local nextIndent = indent .. "  "
    local s = "{\n"
    
    for k, v in pairs(t) do
        local key = type(k) == "string" and string.format("[%q]", k) or "["..tostring(k).."]"
        s = s .. nextIndent .. key .. " = "
        
        if type(v) == "table" then
            s = s .. save.serialize(v, nextIndent)
        elseif type(v) == "string" then
            s = s .. string.format("%q", v)
        else
            s = s .. tostring(v)
        end
        
        s = s .. ",\n"
    end
    
    s = s .. indent .. "}"
    return s
end

-- Save game data with backup
function save.save(data)
    if type(data) ~= "table" then
        print("Error: Cannot save non-table data")
        return false
    end
    
    -- First create a backup of the existing save if it exists
    if love.filesystem.getInfo(SAVE_FILE) then
        love.filesystem.write(BACKUP_FILE, love.filesystem.read(SAVE_FILE))
    end
    
    -- Now save the new data
    local success, err = pcall(function()
        local serialized = "return " .. save.serialize(data)
        love.filesystem.write(SAVE_FILE, serialized)
    end)
    
    if not success then
        print("Error saving game: " .. tostring(err))
        return false
    end
    
    return true
end

-- Load game data with fallback to backup if main save is corrupted
function save.load()
    local data = DEFAULT_SAVE
    
    -- Helper function to load and validate save data
    local function loadFile(filename)
        if not love.filesystem.getInfo(filename) then
            return nil
        end
        
        local success, chunk = pcall(love.filesystem.load, filename)
        if not success then
            print("Error loading save file: " .. tostring(chunk))
            return nil
        end
        
        local success, loaded = pcall(chunk)
        if not success or type(loaded) ~= "table" then
            print("Error executing save chunk: " .. tostring(loaded))
            return nil
        end
        
        return loaded
    end
    
    -- Try main save first
    local loaded = loadFile(SAVE_FILE)
    
    -- If main save fails, try backup
    if not loaded then
        print("Main save corrupted, attempting to load backup...")
        loaded = loadFile(BACKUP_FILE)
    end
    
    -- If we got valid data, use it
    if loaded then
        -- Basic validation and data repair
        data = deepCopy(DEFAULT_SAVE) -- Start with defaults
        
        -- Copy only valid fields from loaded data
        for k, v in pairs(loaded) do
            if data[k] ~= nil then
                data[k] = v
            end
        end
        
        -- Ensure shells is a number
        if type(data.shells) ~= "number" then
            data.shells = 0
        end
    end
    
    return data
end

-- Update game data (for compatibility with old calls)
function save.update(shells, cosmetics, equipped, equipped_weapon)
    local upgrades = require("upgrades")
    
    local data = {
        shells = shells or 0,
        cosmetics = cosmetics or {},
        equipped = equipped or {},
        equipped_weapon = equipped_weapon or "pistol",
        upgrades = {}
    }
    
    -- Make sure shells is within reasonable bounds to prevent corruption
    data.shells = math.max(0, math.min(1e12, math.floor(data.shells or 0)))
    
    -- Save upgrade data
    if upgrades and upgrades.list then
        for i, upgrade in ipairs(upgrades.list) do
            data.upgrades[i] = { 
                count = math.max(0, math.min(100000, math.floor(upgrade.count or 0))) 
            }
        end
    end
    
    save.save(data)
end

return save 