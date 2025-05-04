local weapons = {}

-- Initialize weapons data
weapons.data = {
    pistol = { 
        owned = true,
        cosmetics = {
            muzzle = { owned = false, cost = 50 },
            sight  = { owned = false, cost = 75 },
            laser  = { owned = false, cost = 100 }
        }
    },
    ak47 = { 
        owned = false,
        cost = 500,
        cosmetics = {
            muzzle = { owned = false, cost = 100 },
            sight  = { owned = false, cost = 150 },
            laser  = { owned = false, cost = 200 }
        }
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

return weapons 