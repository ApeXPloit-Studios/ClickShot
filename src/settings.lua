local assets = require("assets")

local settings = {
    visible = false,
    selected_option = 1,
    button_cooldown = 0,
    hover_effect = 0,
    gamepad = nil,
    canvas = nil,
    scale = 1,
    offset = {x = 0, y = 0},
    last_input_method = "mouse"  -- Track last input method
}

-- Resolution presets
local resolutions = {
    { name = "720p", width = 1280, height = 720 },
    { name = "1080p", width = 1920, height = 1080 },
    { name = "2K", width = 2560, height = 1440 },
    { name = "4K", width = 3840, height = 2160 }
}

-- Make options table accessible to action functions
settings.options = {
    { text = "Fullscreen", x = 0, y = 0, w = 200, h = 50, action = function() 
        love.window.setFullscreen(not love.window.getFullscreen())
        settings.updateScaling()
    end },
    { text = "Resolution: 1080p", x = 0, y = 0, w = 200, h = 50, action = function() 
        -- Cycle through resolutions
        local current = settings.options[2].text:match("Resolution: (.+)")
        local currentIndex = 1
        for i, res in ipairs(resolutions) do
            if res.name == current then
                currentIndex = i
                break
            end
        end
        currentIndex = currentIndex % #resolutions + 1
        local newRes = resolutions[currentIndex]
        settings.options[2].text = "Resolution: " .. newRes.name
        love.window.setMode(newRes.width, newRes.height, {
            fullscreen = love.window.getFullscreen(),
            resizable = true
        })
        settings.updateScaling()
    end },
    { text = "Sound: On", x = 0, y = 0, w = 200, h = 50, action = function() 
        -- Toggle sound
        local current = settings.options[3].text == "Sound: On"
        settings.options[3].text = current and "Sound: Off" or "Sound: On"
    end },
    { text = "Music: On", x = 0, y = 0, w = 200, h = 50, action = function() 
        -- Toggle music
        local current = settings.options[4].text == "Music: On"
        settings.options[4].text = current and "Music: Off" or "Music: On"
    end }
}

function settings.load()
    -- Create canvas for rendering
    settings.canvas = love.graphics.newCanvas(1920, 1080)  -- Base resolution
    
    local screenW, screenH = love.graphics.getDimensions()
    local spacing = 20
    for i, o in ipairs(settings.options) do
        o.x = (screenW - o.w) / 2
        o.y = (screenH / 2 - (#settings.options * (o.h + spacing)) / 2) + ((i - 1) * (o.h + spacing))
    end

    -- Initialize gamepad
    local joysticks = love.joystick.getJoysticks()
    if #joysticks > 0 then
        settings.gamepad = joysticks[1]
    end

    -- Initial scaling setup
    settings.updateScaling()
end

function settings.updateScaling()
    local screenW, screenH = love.graphics.getDimensions()
    local canvasW, canvasH = settings.canvas:getDimensions()
    
    -- Calculate scale to fit the screen while maintaining aspect ratio
    local scaleX = screenW / canvasW
    local scaleY = screenH / canvasH
    settings.scale = math.min(scaleX, scaleY)
    
    -- Calculate offset to center the canvas
    settings.offset.x = (screenW - canvasW * settings.scale) / 2
    settings.offset.y = (screenH - canvasH * settings.scale) / 2
end

function settings.update(dt)
    if not settings.visible then return end

    -- Update hover effect
    settings.hover_effect = settings.hover_effect + dt * 2
    if settings.hover_effect > math.pi * 2 then
        settings.hover_effect = 0
    end

    -- Update button cooldown
    if settings.button_cooldown > 0 then
        settings.button_cooldown = settings.button_cooldown - dt
    end

    -- Update button hover states for mouse
    local mx, my = love.mouse.getPosition()
    for i, o in ipairs(settings.options) do
        -- Convert mouse coordinates to canvas space
        local canvasX = (mx - settings.offset.x) / settings.scale
        local canvasY = (my - settings.offset.y) / settings.scale
        o.hover = canvasX >= o.x and canvasX <= o.x + o.w and canvasY >= o.y and canvasY <= o.y + o.h
    end

    -- Handle keyboard input
    if love.keyboard.isDown("up") then
        settings.last_input_method = "keyboard"
        if settings.button_cooldown <= 0 then
            settings.selected_option = settings.selected_option - 1
            if settings.selected_option < 1 then settings.selected_option = #settings.options end
            settings.button_cooldown = 0.2
        end
    elseif love.keyboard.isDown("down") then
        settings.last_input_method = "keyboard"
        if settings.button_cooldown <= 0 then
            settings.selected_option = settings.selected_option + 1
            if settings.selected_option > #settings.options then settings.selected_option = 1 end
            settings.button_cooldown = 0.2
        end
    elseif love.keyboard.isDown("return") or love.keyboard.isDown("space") then
        settings.last_input_method = "keyboard"
        settings.options[settings.selected_option].action()
    elseif love.keyboard.isDown("escape") then
        settings.last_input_method = "keyboard"
        settings.toggle()
    end

    -- Handle gamepad input
    if settings.gamepad then
        -- Check for any gamepad input to switch to controller mode
        if settings.gamepad:isGamepadDown("a") or 
           settings.gamepad:isGamepadDown("b") or 
           settings.gamepad:isGamepadDown("start") or 
           settings.gamepad:isGamepadDown("dpup") or 
           settings.gamepad:isGamepadDown("dpdown") then
            settings.last_input_method = "controller"
        end

        -- Only process controller input if it's the last input method
        if settings.last_input_method == "controller" then
            -- D-pad navigation
            if settings.button_cooldown <= 0 then
                if settings.gamepad:isGamepadDown("dpup") then
                    settings.selected_option = settings.selected_option - 1
                    if settings.selected_option < 1 then settings.selected_option = #settings.options end
                    settings.button_cooldown = 0.2
                elseif settings.gamepad:isGamepadDown("dpdown") then
                    settings.selected_option = settings.selected_option + 1
                    if settings.selected_option > #settings.options then settings.selected_option = 1 end
                    settings.button_cooldown = 0.2
                end
            end

            -- A button to select
            if settings.gamepad:isGamepadDown("a") then
                settings.options[settings.selected_option].action()
            end

            -- B button to close settings
            if settings.gamepad:isGamepadDown("b") then
                settings.toggle()
            end
        end
    end
end

function settings.draw()
    if not settings.visible then return end

    -- Draw to canvas first
    love.graphics.setCanvas(settings.canvas)
    love.graphics.clear()

    -- Draw semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, settings.canvas:getDimensions())
    love.graphics.setColor(1, 1, 1)

    -- Draw title
    love.graphics.setFont(assets.fonts.bold)
    local title = "Settings"
    local tw = assets.fonts.bold:getWidth(title)
    local th = assets.fonts.bold:getHeight()
    local titleX = (settings.canvas:getWidth() - tw) / 2
    local titleY = 100
    love.graphics.print(title, titleX, titleY)

    -- Draw options with enhanced hover effects
    for i, o in ipairs(settings.options) do
        -- Option background with hover effect
        local isSelected = i == settings.selected_option
        local hover_scale = 1 + (isSelected and math.sin(settings.hover_effect) * 0.1 or 0)
        local hover_color = isSelected and {0.4, 0.4, 0.4} or {0.2, 0.2, 0.2}
        
        love.graphics.push()
        love.graphics.translate(o.x + o.w/2, o.y + o.h/2)
        love.graphics.scale(hover_scale, hover_scale)
        love.graphics.translate(-o.w/2, -o.h/2)
        
        -- Draw option background with rounded corners
        love.graphics.setColor(hover_color[1], hover_color[2], hover_color[3])
        love.graphics.rectangle("fill", 0, 0, o.w, o.h, 10, 10)
        
        -- Draw option border
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("line", 0, 0, o.w, o.h, 10, 10)
        
        -- Draw option text
        love.graphics.setColor(1, 1, 1)
        local textW = assets.fonts.bold:getWidth(o.text)
        local textH = assets.fonts.bold:getHeight()
        love.graphics.print(o.text, (o.w - textW) / 2, (o.h - textH) / 2)
        
        love.graphics.pop()
    end

    -- Reset canvas and draw to screen with proper scaling
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(settings.canvas, settings.offset.x, settings.offset.y, 0, settings.scale, settings.scale)
end

function settings.mousepressed(x, y, button)
    if not settings.visible then return end
    
    -- Switch to mouse input mode
    settings.last_input_method = "mouse"
    
    -- Convert screen coordinates to canvas coordinates
    local canvasX = (x - settings.offset.x) / settings.scale
    local canvasY = (y - settings.offset.y) / settings.scale
    
    if button == 1 then
        for i, o in ipairs(settings.options) do
            if canvasX >= o.x and canvasX <= o.x + o.w and
               canvasY >= o.y and canvasY <= o.y + o.h then
                settings.selected_option = i
                o.action()
                return
            end
        end
    end
end

function settings.keypressed(key)
    if not settings.visible then return end
    
    if key == "escape" then
        settings.toggle()
    end
end

function settings.toggle()
    settings.visible = not settings.visible
    if settings.visible then
        settings.selected_option = 1
    end
end

return settings 