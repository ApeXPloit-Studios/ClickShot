local assets = require("assets")
local weapons = require("weapons")
local shop = {}

shop.visible = false

function shop.toggle()
    shop.visible = not shop.visible
end

function shop.update(dt, game)
    if not game.shop_visible then return end
    
    local mx, my = love.mouse.getPosition()
    
    -- Update weapon hover states
    for weapon, data in pairs(weapons.getAll()) do
        if data._bounds then
            data.hover = mx >= data._bounds.x and mx <= data._bounds.x + data._bounds.w and 
                        my >= data._bounds.y and my <= data._bounds.y + data._bounds.h
        end
    end
    
    -- Update cosmetics hover states
    for weapon, data in pairs(weapons.getAll()) do
        for type, v in pairs(data.cosmetics) do
            if v._bounds then
                v.hover = mx >= v._bounds.x and mx <= v._bounds.x + v._bounds.w and 
                         my >= v._bounds.y and my <= v._bounds.y + v._bounds.h
            end
        end
    end
end

function shop.draw(game)
    if not game.shop_visible then return end

    local w, h = 400, 400  -- Increased height for more items
    local x, y = (love.graphics.getWidth() - w) / 2, (love.graphics.getHeight() - h) / 2

    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", x, y, w, h, 10, 10)

    love.graphics.setFont(assets.fonts.bold)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Shop", x, y + 10, w, "center")

    -- Draw weapons section
    love.graphics.setFont(assets.fonts.medium)
    love.graphics.printf("Weapons", x, y + 40, w, "center")
    
    local spacing = 60
    local startY = y + 70
    local i = 0

    -- Draw weapons
    for weapon, data in pairs(weapons.getAll()) do
        local label = weapon:upper()
        local state = data.owned and "Owned" or ("Buy ($" .. data.cost .. ")")
        local bx, by, bw, bh = x + 50, startY + i * spacing, 300, 40

        love.graphics.setColor(data.hover and {0.3, 0.3, 0.3} or {0.2, 0.2, 0.2})
        love.graphics.rectangle("fill", bx, by, bw, bh, 6, 6)

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(label .. ": " .. state, bx, by + 10, bw, "center")

        data._bounds = { x = bx, y = by, w = bw, h = bh }
        i = i + 1
    end

    -- Draw cosmetics section
    love.graphics.setFont(assets.fonts.medium)
    love.graphics.printf("Cosmetics", x, y + 200, w, "center")
    
    startY = y + 230
    i = 0

    -- Draw cosmetics for each weapon
    for weapon, data in pairs(weapons.getAll()) do
        if data.owned then
            for type, v in pairs(data.cosmetics) do
                local label = type:sub(1,1):upper() .. type:sub(2)
                local state = v.owned and "Owned" or ("Buy ($" .. v.cost .. ")")
                local bx, by, bw, bh = x + 50, startY + i * spacing, 300, 40

                love.graphics.setColor(v.hover and {0.3, 0.3, 0.3} or {0.2, 0.2, 0.2})
                love.graphics.rectangle("fill", bx, by, bw, bh, 6, 6)

                love.graphics.setColor(1, 1, 1)
                love.graphics.printf(weapon:upper() .. " " .. label .. ": " .. state, bx, by + 10, bw, "center")

                v._bounds = { x = bx, y = by, w = bw, h = bh }
                i = i + 1
            end
        end
    end
end

function shop.mousepressed(x, y, button, game)
    if not game.shop_visible then return end
    
    -- Check weapon purchases
    for weapon, data in pairs(weapons.getAll()) do
        local b = data._bounds
        if b and x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h then
            if not data.owned and game.shells >= data.cost then
                game.shells = game.shells - data.cost
                weapons.setOwned(weapon, true)
            end
            return
        end
    end
    
    -- Check cosmetic purchases
    for weapon, data in pairs(weapons.getAll()) do
        if data.owned then
            for type, v in pairs(data.cosmetics) do
                local b = v._bounds
                if b and x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h then
                    if not v.owned and game.shells >= v.cost then
                        game.shells = game.shells - v.cost
                        weapons.setCosmeticOwned(weapon, type, true)
                    end
                    return
                end
            end
        end
    end
end

return shop
