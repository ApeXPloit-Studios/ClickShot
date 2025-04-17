local assets = require("assets")
local gun = require("gun")
local shop = require("shop") -- use same owned data
local workbench = {}

workbench.equipped = { muzzle = false, sight = false, laser = false }

function workbench.update(dt, game)
    if not game.workbench_visible then return end
    
    local mx, my = love.mouse.getPosition()
    for k, v in pairs(shop.cosmetics.pistol) do
        local b = v._bounds
        if b then
            v.hover = mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h
        end
    end
end

function workbench.draw(game)
    if not game.workbench_visible then return end

    local w, h = 400, 250
    local x, y = (love.graphics.getWidth() - w) / 2, (love.graphics.getHeight() - h) / 2

    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", x, y, w, h, 10, 10)

    love.graphics.setFont(assets.fonts.bold)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Workbench - Pistol", x, y + 10, w, "center")

    local spacing = 60
    local startY = y + 50
    local i = 0

    for k, v in pairs(shop.cosmetics.pistol) do
        local label = k:sub(1,1):upper() .. k:sub(2)
        local state = v.owned and (workbench.equipped[k] and "Unequip" or "Equip") or "Locked"
        local bx, by, bw, bh = x + 50, startY + i * spacing, 300, 40

        love.graphics.setColor(v.hover and {0.3, 0.3, 0.3} or {0.2, 0.2, 0.2})
        love.graphics.rectangle("fill", bx, by, bw, bh, 6, 6)

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(label .. ": " .. state, bx, by + 10, bw, "center")

        v._bounds = { x = bx, y = by, w = bw, h = bh }
        i = i + 1
    end
end

function workbench.mousepressed(x, y, button, game)
    if not game.workbench_visible then return end
    
    for k, v in pairs(shop.cosmetics.pistol) do
        local b = v._bounds
        if b and x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h then
            if v.owned then
                workbench.equipped[k] = not workbench.equipped[k]
                workbench.updateGunSprite()
            end
            break
        end
    end
end

function workbench.updateGunSprite()
    local combo = {}
    if workbench.equipped.muzzle then table.insert(combo, "muzzle") end
    if workbench.equipped.sight  then table.insert(combo, "sight") end
    if workbench.equipped.laser  then table.insert(combo, "laser") end

    local path = "assets/images/pistol/fire_pistol"
    if #combo > 0 then
        path = path .. "_" .. table.concat(combo, "_")
    end
    path = path .. ".png"

    local success, image = pcall(love.graphics.newImage, path)
    if success then
        image:setFilter("nearest", "nearest")
        gun.setSprite(image)
    else
        print("Failed to load sprite:", path)
    end
end

return workbench
