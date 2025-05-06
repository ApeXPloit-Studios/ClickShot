-- Set save directory identity before loading any modules
love.filesystem.setIdentity("ArcShell")

local game = require("game")
local main_menu = require("main_menu")
local scene = require("scene")
local pause_menu = require("pause_menu")
local scale_manager = require("scale_manager")
local settings = require("settings")

function love.load()
    -- Set window mode to 720p
    love.window.setMode(1280, 720, {
        resizable = false,
        vsync = true,
        minwidth = 1280,
        minheight = 720
    })
    
    -- Load settings first (includes volume settings)
    settings.load()
    
    -- Then initialize scene (including music)
    scene.load()  
    scene.current = "menu"
    
    -- Load other modules
    main_menu.load()
    game.load()
end

-- Handle scene-specific callbacks
local function handleSceneCallback(callback, ...)
    local current = scene.current
    
    if current == "game" then
        if game[callback] then
            return game[callback](...)
        end
    elseif current == "menu" then
        if main_menu[callback] then
            return main_menu[callback](...)
        end
    end
end

function love.update(dt)
    handleSceneCallback("update", dt)
end

function love.draw()
    handleSceneCallback("draw")
end

function love.mousepressed(x, y, button, istouch, presses)
    handleSceneCallback("mousepressed", x, y, button)
end

function love.mousereleased(x, y, button, istouch, presses)
    if scene.current == "game" then
        pause_menu.mousereleased(x, y, button)
    elseif scene.current == "menu" then
        main_menu.mousereleased(x, y, button)
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
