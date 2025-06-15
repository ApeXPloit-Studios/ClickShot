local steam = {}

local has_steam, luasteam = pcall(require, "luasteam")
local initialized = false

-- Centralized achievement IDs
steam.achievements = {
    FIRST_SHOT = "ACH_FIRST_SHOT", -- These IDs need to be changed when the game is released (for now only using the test game 480)
    FIRST_UPGRADE = "ACH_FIRST_UPGRADE",
    FIRST_WEAPON = "ACH_FIRST_WEAPON",
    FIRST_ATTACHMENT = "ACH_FIRST_ATTACHMENT",
    TEN_THOUSAND_SHELLS = "ACH_TEN_THOUSAND_SHELLS",
    KEVIN_ALLEN = "ACH_KEVIN_ALLEN",  -- Konami code achievement
    
    -- Weapon-specific achievements (excluding pistol since it's the starting weapon)
    AK47_EQUIPPED = "ACH_AK47_EQUIPPED",
    SMG_EQUIPPED = "ACH_SMG_EQUIPPED",
    BAZOOKA_EQUIPPED = "ACH_BAZOOKA_EQUIPPED",
    
    -- Pistol attachment achievements
    PISTOL_MUZZLE_EQUIPPED = "ACH_PISTOL_MUZZLE",
    PISTOL_SIGHT_EQUIPPED = "ACH_PISTOL_SIGHT",
    PISTOL_LASER_EQUIPPED = "ACH_PISTOL_LASER",
    
    -- AK47 attachment achievements
    AK47_SIGHT_EQUIPPED = "ACH_AK47_SIGHT",
    AK47_GRIP_EQUIPPED = "ACH_AK47_GRIP",
    AK47_STOCK_EQUIPPED = "ACH_AK47_STOCK",
    AK47_MAG_EQUIPPED = "ACH_AK47_MAG"
}

function steam.init()
    if has_steam and not initialized then
        initialized = luasteam.init()
    end
end

function steam.shutdown()
    if steam.isAvailable() then
        luasteam.shutdown()
        initialized = false
    end
end

function steam.isAvailable()
    return has_steam and initialized
end

function steam.setAchievement(id)
    if steam.isAvailable() then
        luasteam.userStats.setAchievement(id)
        luasteam.userStats.storeStats()
    end
end

function steam.clearAchievement(id)
    if steam.isAvailable() then
        luasteam.userStats.clearAchievement(id)
        luasteam.userStats.storeStats()
    end
end

function steam.update()
    if steam.isAvailable() then
        luasteam.runCallbacks()
    end
end

return steam 