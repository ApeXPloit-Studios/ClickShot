local assets = require("assets")
local gun = require("gun")
local shop = require("shop")
local workbench = require("workbench")

local game = {}
game.shells = 0

function game.load()
    assets.load()
    gun.load()
end

function game.update(dt)
    gun.update(dt)
    shop.update(dt)
    workbench.update(dt)
end

function game.draw()
    love.graphics.clear(0.1, 0.2, 0.9)
    love.graphics.setFont(assets.fonts.bold)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Shells: " .. game.shells, 20, 20)
    gun.draw()
    shop.draw()
    workbench.draw()
end

function game.mousepressed(x, y, button)
    if shop.visible then
        shop.mousepressed(x, y, button, game)
    elseif workbench.visible then
        workbench.mousepressed(x, y, button)
    else
        if button == 1 and gun.isClicked(x, y) then
            local clicked = gun.shoot()
            if clicked then
                game.shells = game.shells + 1
            end
        end
    end
end

function love.keypressed(key)
    if key == "s" then shop.toggle() end
    if key == "w" then workbench.toggle() end
end

return game
