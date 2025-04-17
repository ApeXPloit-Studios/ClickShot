local assets = require("assets")
local upgrades = {}

upgrades.list = {
    {
        name = "Auto-Loader",
        description = "Automatically loads shells every few seconds",
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
        description = "A robot that helps with shooting",
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
        description = "Produces shells automatically",
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
        description = "Large-scale shell production facility",
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

function upgrades.update(dt, game)
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
    local spacing = 80
    local startY = y + 50
    local buttonH = 70

    for i, upgrade in ipairs(upgrades.list) do
        local bx, by, bw, bh = x + 10, startY + (i-1) * spacing, panelW - 20, buttonH
        upgrade._bounds = { x = bx, y = by, w = bw, h = bh }

        -- Draw upgrade background
        love.graphics.setColor(upgrade.hover and {0.3, 0.3, 0.3} or {0.2, 0.2, 0.2})
        love.graphics.rectangle("fill", bx, by, bw, bh, 6, 6)

        -- Draw upgrade info
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(assets.fonts.bold)
        love.graphics.print(upgrade.name, bx + 10, by + 5)
        love.graphics.print(upgrade.count, bx + bw - 30, by + 5)
        
        love.graphics.setFont(assets.fonts.regular)
        love.graphics.print(upgrade.description, bx + 10, by + 25)
        
        -- Draw cost
        love.graphics.setColor(1, 1, 0)
        love.graphics.print(upgrade:getNextCost() .. " shells", bx + 10, by + 45)
    end
end

function upgrades.mousepressed(x, y, button, game)
    if button ~= 1 then return end

    for _, upgrade in ipairs(upgrades.list) do
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