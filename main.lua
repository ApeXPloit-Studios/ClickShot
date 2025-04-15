local game = require("game")
local menu = require("main_menu")
local scene = require("scene")

function love.load()
    -- Load everything needed
    game.load()
    menu.load()
end

function love.update(dt)
    if scene.current == "game" then
        game.update(dt)
    elseif scene.current == "menu" then
        menu.update(dt)
    end
end

function love.draw()
    if scene.current == "game" then
        game.draw()
    elseif scene.current == "menu" then
        menu.draw()
    end
end

function love.mousepressed(x, y, button)
    if scene.current == "game" then
        game.mousepressed(x, y, button)
    elseif scene.current == "menu" then
        menu.mousepressed(x, y, button)
    end
end
