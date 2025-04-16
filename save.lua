local keytoken = require("keytoken")
local save = {}

-- Save file path
local SAVE_FILE = "arcshell_data.dat"

-- Simple XOR encryption/decryption using arithmetic
local function xor(data, key)
    local result = {}
    for i = 1, #data do
        local keyIndex = (i - 1) % #key + 1
        local dataByte = string.byte(data, i)
        local keyByte = string.byte(key, keyIndex)
        -- Simple XOR using addition and subtraction
        local xorByte = ((dataByte + keyByte) % 256)
        result[i] = string.char(xorByte)
    end
    return table.concat(result)
end

-- Serialize a table to a string
local function serialize(t)
    local result = {}
    local function serialize_value(v)
        if type(v) == "string" then
            return string.format("%q", v)
        elseif type(v) == "number" then
            return tostring(v)
        elseif type(v) == "boolean" then
            return v and "true" or "false"
        elseif type(v) == "table" then
            return serialize(v)
        else
            return "nil"
        end
    end

    result[#result + 1] = "{"
    for k, v in pairs(t) do
        if type(k) == "string" then
            result[#result + 1] = string.format("[%q]=", k)
        else
            result[#result + 1] = string.format("[%s]=", k)
        end
        result[#result + 1] = serialize_value(v)
        result[#result + 1] = ","
    end
    result[#result + 1] = "}"
    return table.concat(result)
end

-- Deserialize a string to a table
local function deserialize(s)
    local f = load("return " .. s)
    if f then
        return f()
    end
    return nil
end

-- Load game data
function save.load()
    local data = {
        shells = 0,
        cosmetics = {
            pistol = {
                muzzle = { owned = false, cost = 50 },
                sight = { owned = false, cost = 75 },
                laser = { owned = false, cost = 100 }
            }
        }
    }

    -- Debug: Print save directory
    print("Save directory:", love.filesystem.getSaveDirectory())

    if love.filesystem.getInfo(SAVE_FILE) then
        local content = love.filesystem.read(SAVE_FILE)
        if content then
            local decrypted = xor(content, keytoken.encryption_key)
            local success, loaded = pcall(deserialize, decrypted)
            if success and loaded then
                -- Ensure cost fields are preserved
                for k, v in pairs(loaded.cosmetics.pistol) do
                    if not v.cost then
                        v.cost = data.cosmetics.pistol[k].cost
                    end
                end
                data = loaded
                print("Successfully loaded save data")
            else
                print("Failed to load save data")
            end
        end
    else
        print("No save file found, using default data")
    end

    return data
end

-- Save game data
function save.save(data)
    local serialized = serialize(data)
    local encrypted = xor(serialized, keytoken.encryption_key)
    local success = love.filesystem.write(SAVE_FILE, encrypted)
    if success then
        print("Successfully saved data")
    else
        print("Failed to save data")
    end
end

-- Update game data
function save.update(shells, cosmetics)
    local data = save.load()
    data.shells = shells
    data.cosmetics = cosmetics
    save.save(data)
end

return save 