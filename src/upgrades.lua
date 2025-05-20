local assets = require("assets")
local ui = require("ui")
local scale_manager = require("scale_manager")
local steam = require("steam")
local upgrades = {
    list = {},
    selected_index = 1,
    navigation_cooldown = 0,
    navigation_cooldown_time = 0.2  -- Time between navigation inputs
}

-- Upgrade prototype for shared methods
local UpgradePrototype = {
        getNextCost = function(self)
            return math.floor(self.base_cost * math.pow(1.15, self.count))
    end
}

-- Create a new upgrade
local function createUpgrade(name, base_cost, cps, effect_fn)
    local upgrade = {
        name = name,
        base_cost = base_cost,
        count = 0,
        cps = cps,
        hover = false
    }
    
    -- Set the default getNextCost method
    upgrade.getNextCost = UpgradePrototype.getNextCost
    
    -- Set the effect function or use a default
    upgrade.effect = effect_fn or function(self, game)
            -- Individual effects are now just for special behaviors
            -- auto_cps is calculated collectively in applyAllEffects
        end
    
    return upgrade
end

-- Initialize upgrades
local function initUpgrades()
    -- Auto-Loader
    table.insert(upgrades.list, createUpgrade(
        "Auto-Loader", 
        15, 
        0.1,
        function(self, game)
            -- This is the first upgrade so it sets the base auto_cps
            game.auto_cps = (self.count * self.cps)
        end
    ))
    
    -- Training Bot
    table.insert(upgrades.list, createUpgrade(
        "Training Bot",
        100,
        1
    ))
    
    -- Shell Factory
    table.insert(upgrades.list, createUpgrade(
        "Shell Factory",
        1100,
        8
    ))
    
    -- Ammo Plant
    table.insert(upgrades.list, createUpgrade(
        "Ammo Plant",
        12000,
        47
    ))
end

-- Initialize upgrades on module load
initUpgrades()

-- Navigate through upgrades
function upgrades.navigate(direction)
    if upgrades.navigation_cooldown > 0 then return end
    
    upgrades.selected_index = upgrades.selected_index + direction
    if upgrades.selected_index < 1 then
        upgrades.selected_index = #upgrades.list
    elseif upgrades.selected_index > #upgrades.list then
        upgrades.selected_index = 1
    end
    
    upgrades.navigation_cooldown = upgrades.navigation_cooldown_time
end

-- Recalculate and apply all upgrade effects at once
function upgrades.applyAllEffects(game)
    -- Reset auto_cps
    game.auto_cps = 0
    
    -- Apply base effect of each upgrade
    for _, upgrade in ipairs(upgrades.list) do
        game.auto_cps = game.auto_cps + (upgrade.count * upgrade.cps)
        
        -- Apply any special effects
        if upgrade.effect then
            upgrade:effect(game)
        end
    end
end

-- Buy an upgrade
function upgrades.buyUpgrade(index, game)
    if index < 1 or index > #upgrades.list then
        return false
    end
    
    local upgrade = upgrades.list[index]
    local cost = upgrade:getNextCost()
    
    if game.shells >= cost then
        game.shells = game.shells - cost
        upgrade.count = upgrade.count + 1
        upgrades.applyAllEffects(game)
        if upgrade.count == 1 then
            steam.setAchievement(steam.achievements.FIRST_UPGRADE)
        end
        return true
    end
    
    return false
end

-- Update function
function upgrades.update(dt, game)
    -- Update navigation cooldown
    if upgrades.navigation_cooldown > 0 then
        upgrades.navigation_cooldown = upgrades.navigation_cooldown - dt
    end
    
    -- Update hover states
    local mx, my = scale_manager.getMousePosition()
    for _, upgrade in ipairs(upgrades.list) do
        if upgrade._bounds then
            ui.updateButtonHover(upgrade, mx, my)
        end
    end

    -- Apply auto-clicking effects
    if game.auto_cps and game.auto_cps > 0 then
        game.shells = game.shells + (game.auto_cps * dt)
    end
end

-- Process mouse clicks
function upgrades.mousepressed(x, y, button, game)
    if button ~= 1 then return end

    for i, upgrade in ipairs(upgrades.list) do
        local b = upgrade._bounds
        if b and ui.pointInRect(x, y, b) then
            upgrades.buyUpgrade(i, game)
            break
        end
    end
end

return upgrades 