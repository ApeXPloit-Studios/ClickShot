-- Set save directory identity before loading any modules
love.filesystem.setIdentity("ArcShell")

local game = require("game")
local main_menu = require("main_menu")
local scene = require("scene")
local pause_menu = require("pause_menu")
local scale_manager = require("scale_manager")

function love.load()
    -- Set window mode to 720p
    love.window.setMode(1280, 720, {
        resizable = false,
        vsync = true,
        minwidth = 1280,
        minheight = 720
    })
    
    scene.current = "menu"
    main_menu.load()
    game.load()
end

function love.update(dt)
    if scene.current == "game" then
        game.update(dt)
    elseif scene.current == "menu" then
        main_menu.update(dt)
    end
end

function love.draw()
    if scene.current == "game" then
        game.draw()
    elseif scene.current == "menu" then
        main_menu.draw()
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if scene.current == "game" then
        game.mousepressed(x, y, button)
    elseif scene.current == "menu" then
        main_menu.mousepressed(x, y, button)
    end
end

function love.keypressed(key)
    if scene.current == "game" then
        if key == "escape" then
            pause_menu.toggle()
        elseif key == "e" then
            game.toggle_shop()
        elseif key == "q" then
            game.toggle_workbench()
        end
    end
end

function love.resize(width, height)
    scale_manager.update()
end
