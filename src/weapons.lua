local weapons = {}

-- Initialize weapons data
weapons.data = {
    pistol = { 
        owned = true,
        power = 1,  -- Base shells per click
        cosmetics = {
            muzzle = { owned = false, cost = 50, power = 0.5 },
            sight  = { owned = false, cost = 75, power = 0.75 },
            laser  = { owned = false, cost = 100, power = 1 }
        }
    },
    ak47 = { 
        owned = false,
        cost = 500,
        power = 3,  -- More powerful than pistol
        cosmetics = {
            sight  = { owned = false, cost = 150, power = 1.5 },
            grip   = { owned = false, cost = 175, power = 1.5 },
            stock  = { owned = false, cost = 150, power = 1.25 },
            mag    = { owned = false, cost = 125, power = 1 }
        }
    },
    smg = {
        owned = false,
        cost = 1200,
        power = 5,  -- More powerful than AK47
        cosmetics = {}
    },
    bazooka = {
        owned = false,
        cost = 5000,
        power = 15,  -- Most powerful
        cosmetics = {}
    }
}

-- Get weapon data
function weapons.getWeapon(weapon)
    return weapons.data[weapon]
end

-- Get all weapons
function weapons.getAll()
    return weapons.data
end

-- Check if weapon is owned
function weapons.isOwned(weapon)
    return weapons.data[weapon] and weapons.data[weapon].owned
end

-- Check if cosmetic is owned
function weapons.isCosmeticOwned(weapon, cosmetic)
    return weapons.data[weapon] and 
           weapons.data[weapon].cosmetics[cosmetic] and 
           weapons.data[weapon].cosmetics[cosmetic].owned
end

-- Set weapon ownership
function weapons.setOwned(weapon, owned)
    if weapons.data[weapon] then
        weapons.data[weapon].owned = owned
    end
end

-- Set cosmetic ownership
function weapons.setCosmeticOwned(weapon, cosmetic, owned)
    if weapons.data[weapon] and weapons.data[weapon].cosmetics[cosmetic] then
        weapons.data[weapon].cosmetics[cosmetic].owned = owned
    end
end

-- Get total power for a weapon with equipped attachments
function weapons.getWeaponPower(weapon, equipped)
    local total_power = 0
    
    -- Base weapon power
    if weapons.data[weapon] and weapons.data[weapon].owned then
        total_power = weapons.data[weapon].power
    else
        return 0  -- Weapon not owned
    end
    
    -- Add power from equipped attachments
    if equipped and equipped[weapon] then
        for attachment, is_equipped in pairs(equipped[weapon]) do
            if is_equipped and weapons.data[weapon].cosmetics[attachment] and 
               weapons.data[weapon].cosmetics[attachment].owned then
                total_power = total_power + weapons.data[weapon].cosmetics[attachment].power
            end
        end
    end
    
    return total_power
end

return weapons 