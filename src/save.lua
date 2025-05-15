local save = {}

-- Constants
local SAVE_FILE = "ClickShot"
local BACKUP_FILE = "ClickShot"
local MAX_SLOTS = 10
local SETTINGS_FILE = "save_settings.lua"
local active_slot = 1 -- Default active slot

-- Default save data structure
local DEFAULT_SAVE = {
            shells = 0,
            cosmetics = {},
            equipped = {},
            equipped_weapon = "pistol",
            upgrades = {}
        }

-- Get file names for a specific slot
local function getFileNames(slot)
    local slot_num = tostring(slot or active_slot)
    return SAVE_FILE .. slot_num .. ".dat", BACKUP_FILE .. slot_num .. ".bak"
end

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

-- Save active slot to settings file
local function saveSettings()
    -- Save active slot to settings file
    love.filesystem.write(SETTINGS_FILE, string.format(
        [[return function() return { active_slot = %d } end]], 
        active_slot))
end

-- Load active slot from settings file
local function loadSettings()
    -- Load slot settings if available
    local success, settings = pcall(function()
        if love.filesystem.getInfo(SETTINGS_FILE) then
            return love.filesystem.load(SETTINGS_FILE)()()
        end
        return nil
    end)
    
    if success and settings and settings.active_slot then
        active_slot = settings.active_slot
    end
end

-- Called on module load to initialize settings
local function init()
    loadSettings()
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

-- Set active save slot
function save.setActiveSlot(slot)
    if slot >= 1 and slot <= MAX_SLOTS then
        active_slot = slot
        saveSettings()
        return true
    end
    return false
end

-- Initialize a new game in the specified slot
function save.initNewGame(slot)
    slot = slot or active_slot
    if slot >= 1 and slot <= MAX_SLOTS then
        -- Create a new save with default values
        local fresh_data = deepCopy(DEFAULT_SAVE)
        
        -- Initialize default weapons and cosmetics
        local weapons = require("weapons")
        fresh_data.cosmetics = deepCopy(weapons.getAll())
        
        -- Only pistol is owned by default
        for weapon_name, weapon_data in pairs(fresh_data.cosmetics) do
            weapon_data.owned = (weapon_name == "pistol")
            
            -- No cosmetics owned by default
            for _, cosmetic_data in pairs(weapon_data.cosmetics) do
                cosmetic_data.owned = false
            end
        end
        
        -- Initialize equipped data for each weapon
        fresh_data.equipped = {
            pistol = { muzzle = false, sight = false, laser = false },
            ak47 = { muzzle = false, sight = false, laser = false }
        }
        
        -- Pistol is the default equipped weapon
        fresh_data.equipped_weapon = "pistol"
        
        -- Force immediate save to create both .dat and backup files
        local save_file, backup_file = getFileNames(slot)
        
        -- First write the main save file
        local serialized = "return " .. save.serialize(fresh_data)
        love.filesystem.write(save_file, serialized)
        
        -- Then create a backup
        love.filesystem.write(backup_file, serialized)
        
        -- Update active slot to this one
        active_slot = slot
        saveSettings()
        
        return true
    end
    return false
end

-- Get active save slot
function save.getActiveSlot()
    return active_slot
end

-- Get maximum number of save slots
function save.getMaxSlots()
    return MAX_SLOTS
end

-- Check if a save slot exists
function save.slotExists(slot)
    local save_file, _ = getFileNames(slot)
    return love.filesystem.getInfo(save_file) ~= nil
end

-- Get list of existing save slots with basic info
function save.getSaveSlots()
    local slots = {}
    for i = 1, MAX_SLOTS do
        local slot_info = {
            slot = i,
            exists = save.slotExists(i),
            data = nil
        }
        
        if slot_info.exists then
            -- Try to load basic info without loading entire save
            local save_file, _ = getFileNames(i)
            local success, chunk = pcall(love.filesystem.load, save_file)
            if success then
                local success2, loaded = pcall(chunk)
                if success2 and type(loaded) == "table" then
                    slot_info.data = {
                        shells = loaded.shells or 0,
                        equipped_weapon = loaded.equipped_weapon or "pistol"
                    }
                end
            end
        end
        
        table.insert(slots, slot_info)
    end
    return slots
end

-- Delete a save slot
function save.deleteSlot(slot)
    if slot >= 1 and slot <= MAX_SLOTS then
        local save_file, backup_file = getFileNames(slot)
        if love.filesystem.getInfo(save_file) then
            love.filesystem.remove(save_file)
        end
        if love.filesystem.getInfo(backup_file) then
            love.filesystem.remove(backup_file)
        end
        return true
    end
    return false
end

-- Save game data with backup
function save.save(data, slot)
    if type(data) ~= "table" then
        print("Error: Cannot save non-table data")
        return false
    end
    
    local save_file, backup_file = getFileNames(slot)
    
    -- First create a backup of the existing save if it exists
    if love.filesystem.getInfo(save_file) then
        love.filesystem.write(backup_file, love.filesystem.read(save_file))
    end
    
    -- Now save the new data
    local success, err = pcall(function()
        local serialized = "return " .. save.serialize(data)
        love.filesystem.write(save_file, serialized)
    end)
    
    if not success then
        print("Error saving game: " .. tostring(err))
        return false
    end
    
    return true
end

-- Load game data with fallback to backup if main save is corrupted
function save.load(slot)
    local data = deepCopy(DEFAULT_SAVE)
    slot = slot or active_slot
    
    local save_file, backup_file = getFileNames(slot)
    
    -- Helper function to load save data
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
    local loaded = loadFile(save_file)
    
    -- If main save fails, try backup
    if not loaded then
        print("Main save corrupted, attempting to load backup...")
        loaded = loadFile(backup_file)
    end
    
    -- If we got valid data, use it
    if loaded then
        return loaded
    end
    
    -- Return default save data if no valid file found
    return data
end

-- Save current game state
function save.update(shells, cosmetics, equipped, equipped_weapon)
    local upgrades = require("upgrades")
    local weapons = require("weapons")
    
    local data = {
        shells = shells or 0,
        cosmetics = cosmetics or weapons.getAll(),
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
    
    -- Always use the current active slot when saving
    local current_slot = active_slot
    save.save(data, current_slot)
end

-- Initialize the save system
init()

return save 