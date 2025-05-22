local scale_manager = require("scale_manager")

local controller = {
    -- Controller state
    connected = false,
    joysticks = {},
    activeController = nil,
    
    -- Cursor position (in game coordinates)
    cursorX = scale_manager.design_width / 2,
    cursorY = scale_manager.design_height / 2,
    
    -- Cursor movement settings
    cursorSpeed = 400, -- Pixels per second
    analogDeadzone = 0.2, -- Ignore small stick movements
    
    -- Controller settings
    enabled = true,
    invertY = false,
    
    -- Button mappings
    buttonMappings = {
        action = "a",       -- Primary action (click)
        back = "b",         -- Back/cancel action
        menu = "start",     -- Menu toggle (pause)
        shop = "y",         -- Shop toggle
        workbench = "x",    -- Workbench toggle
    },
    
    -- Visual settings
    cursorImage = nil,
    cursorSize = 32,
    
    -- Input state
    usingController = false, -- Track if player is using controller
    
    -- Mouse movement tracking
    mouseMovementDetected = false,
    mouseMovementTimer = 0
}

-- Initialize controller support
function controller.load()
    -- Try to load controller settings
    local success, controller_settings = pcall(function()
        if love.filesystem.getInfo("controller_settings.lua") then
            return love.filesystem.load("controller_settings.lua")()()
        end
        return nil
    end)
    
    if success and controller_settings then
        controller.cursorSpeed = 200 + (controller_settings.speed or 0.5) * 600
        controller.enabled = controller_settings.enabled ~= false
        controller.invertY = controller_settings.invert_y or false
    end
    
    -- Load cursor image
    local success, defaultCursor = pcall(function()
        return love.graphics.newImage("assets/images/cursor.png")
    end)
    
    if success and defaultCursor then
        controller.cursorImage = defaultCursor
    else
        -- Create a default cursor if image not found
        controller.cursorImage = love.graphics.newCanvas(32, 32)
        local canvas = controller.cursorImage
        love.graphics.setCanvas(canvas)
        love.graphics.clear()
        
        -- Draw a simple cursor
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", 8, 8, 8)
        love.graphics.setColor(0, 0, 0)
        love.graphics.circle("line", 8, 8, 8)
        
        love.graphics.setCanvas()
        love.graphics.setColor(1, 1, 1)
    end
    
    -- Find connected controllers
    controller.scanForControllers()
end

-- Scan for connected controllers
function controller.scanForControllers()
    controller.joysticks = love.joystick.getJoysticks()
    controller.connected = #controller.joysticks > 0
    
    if controller.connected and not controller.activeController then
        controller.activeController = controller.joysticks[1]
        print("Controller connected: " .. controller.activeController:getName())
    elseif not controller.connected then
        controller.activeController = nil
        controller.usingController = false
    end
end

-- Update controller state
function controller.update(dt)
    -- Skip controller handling if disabled
    if not controller.enabled then
        controller.usingController = false
        return
    end

    -- Check for controller connection/disconnection
    if love.joystick.getJoystickCount() ~= #controller.joysticks then
        controller.scanForControllers()
    end
    
    -- Update cursor position if using controller
    if controller.connected and controller.activeController then
        local leftX = controller.activeController:getGamepadAxis("leftx")
        local leftY = controller.activeController:getGamepadAxis("lefty")
        local rightX = controller.activeController:getGamepadAxis("rightx")
        local rightY = controller.activeController:getGamepadAxis("righty")
        
        -- Apply Y-axis inversion if enabled
        if controller.invertY then
            leftY = -leftY
            rightY = -rightY
        end
        
        -- Use right stick for cursor movement, fall back to left stick if no input
        local useX, useY = rightX, rightY
        if math.abs(rightX) < controller.analogDeadzone and math.abs(rightY) < controller.analogDeadzone then
            useX, useY = leftX, leftY
        end
        
        -- Apply deadzone
        if math.abs(useX) < controller.analogDeadzone then useX = 0 end
        if math.abs(useY) < controller.analogDeadzone then useY = 0 end
        
        -- Update cursor position if there's input
        if math.abs(useX) > 0 or math.abs(useY) > 0 then
            controller.usingController = true
            controller.cursorX = controller.cursorX + useX * controller.cursorSpeed * dt
            controller.cursorY = controller.cursorY + useY * controller.cursorSpeed * dt
            
            -- Clamp cursor position to screen bounds
            controller.cursorX = math.max(0, math.min(controller.cursorX, scale_manager.design_width))
            controller.cursorY = math.max(0, math.min(controller.cursorY, scale_manager.design_height))
        end
    end
    
    -- Update mouse movement timer
    if controller.mouseMovementDetected then
        controller.mouseMovementTimer = 0.2 -- Reset to 0.2 seconds when movement is detected
        controller.mouseMovementDetected = false
    elseif controller.mouseMovementTimer > 0 then
        controller.mouseMovementTimer = controller.mouseMovementTimer - dt
    end
    
    -- Check for mouse movement or click to switch back to mouse mode
    if love.mouse.isDown(1) or controller.mouseMovementTimer > 0 then
        controller.usingController = false
    end
end

-- Draw the cursor (only when using controller)
function controller.draw()
    if controller.usingController and controller.enabled then
        -- Hide system cursor when using controller
        love.mouse.setVisible(false)
        
        -- Draw the controller cursor
        love.graphics.setColor(1, 1, 1)
        local size = controller.cursorSize
        love.graphics.draw(controller.cursorImage, controller.cursorX - size/2, controller.cursorY - size/2, 0, size/controller.cursorImage:getWidth(), size/controller.cursorImage:getHeight())
    else
        -- Show system cursor when using mouse
        love.mouse.setVisible(true)
    end
end

-- Check if a controller button was pressed
function controller.wasPressed(button)
    if not (controller.connected and controller.activeController and controller.enabled) then
        return false
    end
    
    return controller.activeController:isGamepadDown(button)
end

-- Get the current cursor position
function controller.getCursorPosition()
    if controller.usingController and controller.enabled then
        return controller.cursorX, controller.cursorY
    else
        -- Return actual mouse position in game coordinates
        return scale_manager.getMousePosition()
    end
end

-- Simulate a mouse press at the cursor position
function controller.simulateMousePress(x, y, button)
    -- Skip if controller is disabled
    if not controller.enabled then return end
    
    -- Use provided coordinates or current cursor position
    local posX, posY = x, y
    if not (posX and posY) then
        posX, posY = controller.cursorX, controller.cursorY
    end
    
    -- Convert from game coords to screen coords
    local screenX, screenY = scale_manager.toWindowCoords(posX, posY)
    
    -- Store current position
    local currentX, currentY = love.mouse.getPosition()
    
    -- Temporarily move mouse to target position
    love.mouse.setPosition(screenX, screenY)
    
    -- Trigger mouse press event
    love.mousepressed(screenX, screenY, button or 1, false, 1)
    
    -- Move mouse back to original position
    love.mouse.setPosition(currentX, currentY)
end

-- Simulate a mouse release at the cursor position
function controller.simulateMouseRelease(x, y, button)
    -- Skip if controller is disabled
    if not controller.enabled then return end
    
    -- Use provided coordinates or current cursor position
    local posX, posY = x, y
    if not (posX and posY) then
        posX, posY = controller.cursorX, controller.cursorY
    end
    
    -- Convert from game coords to screen coords
    local screenX, screenY = scale_manager.toWindowCoords(posX, posY)
    
    -- Store current position
    local currentX, currentY = love.mouse.getPosition()
    
    -- Temporarily move mouse to target position
    love.mouse.setPosition(screenX, screenY)
    
    -- Trigger mouse release event
    love.mousereleased(screenX, screenY, button or 1, false, 1)
    
    -- Move mouse back to original position
    love.mouse.setPosition(currentX, currentY)
end

-- Handle joystick added event
function controller.joystickadded(joystick)
    controller.scanForControllers()
end

-- Handle joystick removed event
function controller.joystickremoved(joystick)
    controller.scanForControllers()
end

-- Handle gamepad button press
function controller.gamepadpressed(joystick, button)
    -- Skip if controller is disabled
    if not controller.enabled then return end
    
    if joystick == controller.activeController then
        controller.usingController = true
        
        -- Map buttons to actions
        if button == controller.buttonMappings.action then
            -- Simulate mouse press at current controller cursor position
            controller.simulateMousePress(controller.cursorX, controller.cursorY, 1)
        elseif button == controller.buttonMappings.back then
            -- B button can be used to go back or escape
            love.keypressed("escape")
        elseif button == controller.buttonMappings.menu then
            love.keypressed("escape")
        elseif button == controller.buttonMappings.shop then
            love.keypressed("e")
        elseif button == controller.buttonMappings.workbench then
            love.keypressed("q")
        end
    end
end

-- Handle gamepad button release
function controller.gamepadreleased(joystick, button)
    -- Skip if controller is disabled
    if not controller.enabled then return end
    
    if joystick == controller.activeController then
        -- Map buttons to actions
        if button == controller.buttonMappings.action then
            controller.simulateMouseRelease(controller.cursorX, controller.cursorY, 1)
        end
    end
end

-- Track mouse movement (called from main.lua)
function controller.mousemoved(x, y, dx, dy)
    -- If mouse has moved significantly, mark movement as detected
    if math.abs(dx) > 0 or math.abs(dy) > 0 then
        controller.mouseMovementDetected = true
    end
end

return controller 