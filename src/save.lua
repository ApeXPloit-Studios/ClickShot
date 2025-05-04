local save = {}

local SAVE_FILE = "ClickShot.dat"

-- Save game data as a Lua table
function save.save(data)
    local serialized = "return " .. save.serialize(data)
    love.filesystem.write(SAVE_FILE, serialized)
end

-- Load game data from the Lua table
function save.load()
    if not love.filesystem.getInfo(SAVE_FILE) then
        return {
            shells = 0,
            cosmetics = {},
            equipped = {},
            equipped_weapon = "pistol",
            upgrades = {}
        }
    end
    local chunk = love.filesystem.load(SAVE_FILE)
    local ok, loaded = pcall(chunk)
    if ok and type(loaded) == "table" then
        return loaded
    else
        -- fallback to default if corrupted
        return {
            shells = 0,
            cosmetics = {},
            equipped = {},
            equipped_weapon = "pistol",
            upgrades = {}
        }
    end
end

-- Helper: serialize a table to a string (simple, no cycles)
function save.serialize(t, indent)
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
    if upgrades and upgrades.list then
        for i, upgrade in ipairs(upgrades.list) do
            data.upgrades[i] = { count = upgrade.count or 0 }
        end
    end
    save.save(data)
end

return save 