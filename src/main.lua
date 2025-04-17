-- Set save directory identity before loading any modules
love.filesystem.setIdentity("ArcShell")

local game = require("game")
local main_menu = require("main_menu")
local scene = require("scene")
local pause_menu = require("pause_menu")
local scale_manager = require("scale_manager")

function love.load()
    -- Set default window mode with resizable flag
    love.window.setMode(800, 600, {
        resizable = true,
        minwidth = 400,
        minheight = 300
    })
    
    -- Initialize scale manager
    scale_manager.update()
    
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
    scale_manager.start()
    
    if scene.current == "game" then
        game.draw()
    elseif scene.current == "menu" then
        main_menu.draw()
    end
    
    scale_manager.finish()
end

function love.mousepressed(x, y, button, istouch, presses)
    -- Convert screen coordinates to game coordinates
    local game_x, game_y = scale_manager.toGameCoords(x, y)
    
    if scene.current == "game" then
        game.mousepressed(game_x, game_y, button)
    elseif scene.current == "menu" then
        main_menu.mousepressed(game_x, game_y, button)
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
