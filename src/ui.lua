local scale_manager = require("scale_manager")

local ui = {
    hover_effect = 0
}

-- Mute button configuration
ui.mute_button = {
    x = 20,
    y = 20,
    w = 100,
    h = 32,
    text = "Mute",
    hover = false,
    _bounds = { x = 20, y = 20, w = 100, h = 32 }
}

-- Update hover effect animation
function ui.update(dt)
    ui.hover_effect = ui.hover_effect + dt * 2
    if ui.hover_effect > math.pi * 2 then
        ui.hover_effect = 0
    end
    
    -- Update mute button position to ensure it stays in the top-right corner
    ui.mute_button.x = 20
    ui.mute_button.y = 20
    ui.mute_button._bounds = { 
        x = ui.mute_button.x, 
        y = ui.mute_button.y, 
        w = ui.mute_button.w, 
        h = ui.mute_button.h 
    }
end

-- Draw a button with hover effects
function ui.drawButton(button, x, y, width, height)
    local buttonScale = 1 + (button.hover and math.sin(ui.hover_effect) * 0.1 or 0)
    
    love.graphics.push()
    love.graphics.translate(x + width/2, y + height/2)
    love.graphics.scale(buttonScale, buttonScale)
    love.graphics.translate(-width/2, -height/2)
    
    -- Draw button glow when hovered
    if button.hover then
        for i = 1, 3 do
            local glow_alpha = 0.1 - (i * 0.03)
            love.graphics.setColor(0.5, 0.5, 1, glow_alpha)
            love.graphics.rectangle("fill", -i*2, -i*2, width + i*4, height + i*4, 10 + i, 10 + i)
        end
    end
    
    love.graphics.setColor(button.hover and {0.4, 0.4, 0.4} or {0.2, 0.2, 0.2})
    love.graphics.rectangle("fill", 0, 0, width, height, 6, 6)
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("line", 0, 0, width, height, 6, 6)
    
    -- Calculate vertical center based on font height
    local font = love.graphics.getFont()
    local textHeight = font:getHeight()
    local textY = (height - textHeight) / 2
    
    -- Draw text with shadow when hovered
    if button.hover then
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.printf(button.text, 2, textY + 2, width, "center")
    end
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(button.text, 0, textY, width, "center")
    love.graphics.pop()
end

-- Draw a static button without hover animations
function ui.drawStaticButton(button, x, y, width, height, highlight)
    love.graphics.push()
    
    -- Draw highlight if specified
    if highlight then
        love.graphics.setColor(0.4, 0.4, 0.7)
        love.graphics.rectangle("fill", x, y, width, height, 6, 6)
    end
    
    -- Draw button background
    love.graphics.setColor(button.hover and {0.4, 0.4, 0.4} or {0.2, 0.2, 0.2})
    love.graphics.rectangle("fill", x, y, width, height, 6, 6)
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("line", x, y, width, height, 6, 6)
    
    -- Draw text centered both horizontally and vertically
    love.graphics.setColor(1, 1, 1)
    
    -- Calculate vertical center based on font height
    local font = love.graphics.getFont()
    local textHeight = font:getHeight()
    local textY = y + (height - textHeight) / 2
    
    love.graphics.printf(button.text, x, textY, width, "center")
    
    love.graphics.pop()
end

-- Check if point is inside a rectangle
function ui.pointInRect(x, y, rect)
    return x >= rect.x and x <= rect.x + rect.w and
           y >= rect.y and y <= rect.y + rect.h
end

-- Update hover state for a button based on mouse position
function ui.updateButtonHover(button, mx, my)
    if button._bounds then
        button.hover = ui.pointInRect(mx, my, button._bounds)
        return button.hover
    end
    return false
end

-- Update the mute button state based on scene mute status
function ui.updateMuteButton(scene)
    ui.mute_button.text = scene.isMuted() and "Unmute" or "Mute"
end

-- Draw the mute button
function ui.drawMuteButton(assets)
    ui.drawStaticButton(ui.mute_button, ui.mute_button.x, ui.mute_button.y, 
                  ui.mute_button.w, ui.mute_button.h)
end

-- Handle mute button click, returns true if the button was clicked
function ui.handleMuteButtonClick(x, y, button, scene)
    if button == 1 and ui.mute_button.hover then
        scene.toggleMute()
        return true
    end
    return false
end

-- Draw an animated title with scaling and glow effect
function ui.drawAnimatedTitle(title, x, y, scale, font, options)
    options = options or {}
    
    -- Get title dimensions
    local tw = font:getWidth(title)
    local th = font:getHeight()
    
    -- Auto-center horizontally if requested (x is screen center)
    if options.centerX then
        x = x - tw/2
    end
    
    -- Auto-adjust vertical position if requested
    if options.centerY then
        y = y - th/2
    end
    
    -- Save current transform
    love.graphics.push()
    
    -- Apply title animation
    love.graphics.translate(x + tw/2, y + th/2)
    
    -- Apply rotation if provided
    if options.rotation then
        love.graphics.rotate(options.rotation)
    end
    
    love.graphics.scale(scale, scale)
    love.graphics.translate(-tw/2, -th/2)
    
    -- Adjust glow intensity and spread
    local glowLayers = options.glowLayers or 5
    local glowIntensity = options.glowIntensity or 0.2
    
    -- Draw title with glow effect
    for i = 1, glowLayers do
        local alpha = 1 - (i * glowIntensity)
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.print(title, i, i)
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(title, 0, 0)
    
    -- Restore transform
    love.graphics.pop()
    
    return tw, th -- Return width and height for convenience
end

return ui 