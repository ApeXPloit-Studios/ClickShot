-- Set save directory identity before loading any modules
love.filesystem.setIdentity("ArcShell")

local steam = require("steam")
local game = require("game")
local main_menu = require("main_menu")
local scene = require("scene")
local pause_menu = require("pause_menu")
local scale_manager = require("scale_manager")
local settings = require("settings")
local save_slot_menu = require("save_slot_menu")
local controller = require("controller")

function love.load()
    -- Initialize Steamworks API
    steam.init()
    -- Load settings first (includes volume settings)
    settings.load()
    
    -- Initialize scale manager
    scale_manager.update()
    
    -- Then initialize scene (including music)
    scene.load()  
    scene.current = "menu"
    
    -- Load other modules
    main_menu.load()
    game.load()
    save_slot_menu.load()
    
    -- Initialize controller support
    controller.load()
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
    steam.update()
    controller.update(dt)
    handleSceneCallback("update", dt)
end

function love.draw()
    -- Apply scaling
    scale_manager.start()
    handleSceneCallback("draw")
    controller.draw() -- Draw the controller cursor
    scale_manager.finish()
end

function love.mousepressed(x, y, button, istouch, presses)
    -- Convert window coordinates to game coordinates
    local gameX, gameY = scale_manager.toGameCoords(x, y)
    handleSceneCallback("mousepressed", gameX, gameY, button)
end

function love.mousereleased(x, y, button, istouch, presses)
    -- Convert window coordinates to game coordinates
    local gameX, gameY = scale_manager.toGameCoords(x, y)
    
    if scene.current == "game" then
        pause_menu.mousereleased(gameX, gameY, button)
    elseif scene.current == "menu" then
        main_menu.mousereleased(gameX, gameY, button)
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    -- Convert window coordinates to game coordinates
    local gameX, gameY = scale_manager.toGameCoords(x, y)
    local gameDX = dx / scale_manager.scale_x
    local gameDY = dy / scale_manager.scale_y
    
    -- Notify controller module about mouse movement
    controller.mousemoved(gameX, gameY, gameDX, gameDY)
    
    if handleSceneCallback("mousemoved", gameX, gameY, gameDX, gameDY, istouch) then
        return
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

function love.wheelmoved(x, y)
    -- Forward wheel events to the current scene
    handleSceneCallback("wheelmoved", x, y)
end

function love.resize(width, height)
    scale_manager.update()
    save_slot_menu.handleResize()
end

-- Controller event handlers
function love.joystickadded(joystick)
    controller.joystickadded(joystick)
end

function love.joystickremoved(joystick)
    controller.joystickremoved(joystick)
end

function love.gamepadpressed(joystick, button)
    controller.gamepadpressed(joystick, button)
end

function love.gamepadreleased(joystick, button)
    controller.gamepadreleased(joystick, button)
end

function love.handlers.gameReloadSaveData()
    if scene.current == "game" and game.handleEvent then
        game.handleEvent("gameReloadSaveData")
    end
end

function love.quit()
    steam.shutdown()
end

