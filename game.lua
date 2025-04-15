local assets = require("assets")
local gun = require("gun")

local game = {}
game.shells = 0

function game.load()
    assets.load()
    gun.load()
end

function game.update(dt)
    gun.update(dt)
end

function game.draw()
    love.graphics.print("Shells: " .. game.shells, 20, 20)
    gun.draw()
end

function game.mousepressed(x, y, button)
    if button == 1 and gun.isClicked(x, y) then
        local clicked = gun.shoot()
        if clicked then
            game.shells = game.shells + 1
        end
    end
end

return game
