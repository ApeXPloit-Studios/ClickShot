-- Set save directory identity before loading any modules
love.filesystem.setIdentity("ArcShell")

local game = require("game")
local menu = require("main_menu")
local scene = require("scene")
local pause_menu = require("pause_menu")

function love.load()
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

function love.keypressed(key)
    if scene.current == "game" then
        if key == "escape" then pause_menu.toggle() end
        if key == "s" then require("shop").toggle() end
        if key == "w" then require("workbench").toggle() end
        if key == "f3" then game.debug = not game.debug end
    end
end
