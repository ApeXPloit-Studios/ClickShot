local assets = require("assets")
local shop = {}

shop.visible = false

shop.cosmetics = {
    pistol = {
        muzzle = { owned = false, cost = 50, hover = false },
        sight  = { owned = false, cost = 75, hover = false },
        laser  = { owned = false, cost = 100, hover = false }
    }
}

function shop.toggle()
    shop.visible = not shop.visible
end

function shop.update(dt, game)
    if not game.shop_visible then return end
    
    local mx, my = love.mouse.getPosition()
    for _, cat in pairs(shop.cosmetics) do
        for _, v in pairs(cat) do
            local b = v._bounds
            if b then
                v.hover = mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h
            end
        end
    end
end

function shop.draw(game)
    if not game.shop_visible then return end

    local w, h = 400, 250
    local x, y = (love.graphics.getWidth() - w) / 2, (love.graphics.getHeight() - h) / 2

    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", x, y, w, h, 10, 10)

    love.graphics.setFont(assets.fonts.bold)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Shop - Pistol Cosmetics", x, y + 10, w, "center")

    local spacing = 60
    local startY = y + 50
    local i = 0

    for type, v in pairs(shop.cosmetics.pistol) do
        local label = type:sub(1,1):upper() .. type:sub(2)
        local state = v.owned and "Owned" or ("Buy ($" .. v.cost .. ")")
        local bx, by, bw, bh = x + 50, startY + i * spacing, 300, 40

        love.graphics.setColor(v.hover and {0.3, 0.3, 0.3} or {0.2, 0.2, 0.2})
        love.graphics.rectangle("fill", bx, by, bw, bh, 6, 6)

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(label .. ": " .. state, bx, by + 10, bw, "center")

        v._bounds = { x = bx, y = by, w = bw, h = bh }
        i = i + 1
    end
end

function shop.mousepressed(x, y, button, game)
    if not game.shop_visible then return end
    
    for _, v in pairs(shop.cosmetics.pistol) do
        local b = v._bounds
        if x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h then
            if not v.owned and game.shells >= v.cost then
                game.shells = game.shells - v.cost
                v.owned = true
            end
        end
    end
end

return shop
