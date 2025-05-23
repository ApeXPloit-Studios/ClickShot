local steam = {}

local has_steam, luasteam = pcall(require, "luasteam")
local initialized = false

-- Centralized achievement IDs
steam.achievements = {
    FIRST_SHOT = "ACH_FIRST_SHOT", -- These IDs need to be changed when the game is released (for now only using the test game 480)
    FIRST_UPGRADE = "ACH_FIRST_UPGRADE",
    FIRST_WEAPON = "ACH_FIRST_WEAPON",
    FIRST_ATTACHMENT = "ACH_FIRST_ATTACHMENT",
    TEN_THOUSAND_SHELLS = "ACH_TEN_THOUSAND_SHELLS"
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