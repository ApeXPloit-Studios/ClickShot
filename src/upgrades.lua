local assets = require("assets")
local upgrades = {}

upgrades.list = {
    {
        name = "Auto-Loader",
        base_cost = 15,
        count = 0,
        cps = 0.1, -- clicks per second
        getNextCost = function(self)
            return math.floor(self.base_cost * math.pow(1.15, self.count))
        end,
        effect = function(self, game)
            game.auto_cps = (self.count * self.cps)
        end
    },
    {
        name = "Training Bot",
        base_cost = 100,
        count = 0,
        cps = 1,
        getNextCost = function(self)
            return math.floor(self.base_cost * math.pow(1.15, self.count))
        end,
        effect = function(self, game)
            game.auto_cps = game.auto_cps + (self.count * self.cps)
        end
    },
    {
        name = "Shell Factory",
        base_cost = 1100,
        count = 0,
        cps = 8,
        getNextCost = function(self)
            return math.floor(self.base_cost * math.pow(1.15, self.count))
        end,
        effect = function(self, game)
            game.auto_cps = game.auto_cps + (self.count * self.cps)
        end
    },
    {
        name = "Ammo Plant",
        base_cost = 12000,
        count = 0,
        cps = 47,
        getNextCost = function(self)
            return math.floor(self.base_cost * math.pow(1.15, self.count))
        end,
        effect = function(self, game)
            game.auto_cps = game.auto_cps + (self.count * self.cps)
        end
    }
}

-- Navigation state
upgrades.selected_index = 1
upgrades.navigation_cooldown = 0
upgrades.navigation_cooldown_time = 0.2  -- Time between navigation inputs

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

function upgrades.draw()
    local screenW = love.graphics.getWidth()
    local panelW = 200
    local x = screenW - panelW
    local y = 0
    local h = love.graphics.getHeight()

    -- Draw panel background
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", x, y, panelW, h)

    -- Draw title
    love.graphics.setFont(assets.fonts.bold)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Upgrades", x, y + 10, panelW, "center")

    -- Draw upgrades
    local spacing = 90  -- Significantly increased spacing
    local startY = y + 50
    local buttonH = 80  -- Significantly increased height

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

function upgrades.mousepressed(x, y, button, game)
    if button ~= 1 then return end

    for i, upgrade in ipairs(upgrades.list) do
        local b = upgrade._bounds
        if b and x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h then
            local cost = upgrade:getNextCost()
            if game.shells >= cost then
                game.shells = game.shells - cost
                upgrade.count = upgrade.count + 1
                upgrade:effect(game)
            end
        end
    end
end

return upgrades 