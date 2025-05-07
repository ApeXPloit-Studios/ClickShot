local assets = require("assets")
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
            game.auto_cps = game.auto_cps + (self.count * self.cps)
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
        upgrade:effect(game)
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
    local mx, my = love.mouse.getPosition()
    for _, upgrade in ipairs(upgrades.list) do
        local b = upgrade._bounds
        if b then
            upgrade.hover = mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h
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
        if b and x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h then
            upgrades.buyUpgrade(i, game)
            break
        end
    end
end

-- Draw function (not used in the game.lua implementation, kept for reference)
function upgrades.draw()
    local screenW = love.graphics.getWidth()
    local panelW = 200
    local x = screenW - panelW
    local y = 0
    local h = love.graphics.getHeight()
    local spacing = 90
    local startY = y + 50
    local buttonH = 80

    -- Draw panel background
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", x, y, panelW, h)

    -- Draw title
    love.graphics.setFont(assets.fonts.bold)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Upgrades", x, y + 10, panelW, "center")

    -- Draw upgrades
    for i, upgrade in ipairs(upgrades.list) do
        local bx, by, bw, bh = x + 10, startY + (i-1) * spacing, panelW - 20, buttonH
        upgrade._bounds = { x = bx, y = by, w = bw, h = bh }

        -- Draw upgrade background
        local isSelected = i == upgrades.selected_index
        love.graphics.setColor(isSelected and {0.4, 0.4, 0.4} or {0.2, 0.2, 0.2})
        love.graphics.rectangle("fill", bx, by, bw, bh, 6, 6)

        -- Draw upgrade name
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(assets.fonts.bold)
        love.graphics.print(upgrade.name, bx + 10, by + 15)
        
        -- Draw count on the right side
        local countStr = tostring(upgrade.count)
        local countW = assets.fonts.bold:getWidth(countStr)
        love.graphics.print(countStr, bx + bw - countW - 10, by + 15)
        
        -- Draw cost on a new line
        love.graphics.setColor(1, 1, 0)
        love.graphics.print(upgrade:getNextCost() .. " shells", bx + 10, by + 45)
    end
end

return upgrades 