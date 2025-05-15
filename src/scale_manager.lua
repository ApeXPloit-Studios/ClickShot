local scale_manager = {
    -- Base resolution that the game is designed for
    design_width = 1280,
    design_height = 720,
    
    -- Current game window dimensions
    window_width = 1280,
    window_height = 720,
    
    -- Scaling factors
    scale_x = 1,
    scale_y = 1,
    
    -- Offset for centering when aspect ratios don't match
    offset_x = 0,
    offset_y = 0,
    
    -- Maintain aspect ratio when scaling
    maintain_aspect_ratio = true
}

function scale_manager.update()
    -- Get current window dimensions
    local window_width, window_height = love.graphics.getDimensions()
    scale_manager.window_width = window_width
    scale_manager.window_height = window_height
    
    if scale_manager.maintain_aspect_ratio then
        -- Calculate scaling factors while maintaining aspect ratio
        local scale_x = window_width / scale_manager.design_width
        local scale_y = window_height / scale_manager.design_height
        
        -- Use the smaller scale to ensure everything fits
        local scale = math.min(scale_x, scale_y)
        scale_manager.scale_x = scale
        scale_manager.scale_y = scale
        
        -- Calculate offsets to center the content
        scale_manager.offset_x = (window_width - scale_manager.design_width * scale) / 2
        scale_manager.offset_y = (window_height - scale_manager.design_height * scale) / 2
    else
        -- Scale to fill the entire window (may cause stretching)
        scale_manager.scale_x = window_width / scale_manager.design_width
        scale_manager.scale_y = window_height / scale_manager.design_height
    scale_manager.offset_x = 0
    scale_manager.offset_y = 0
    end
end

-- Apply scaling transformation before drawing
function scale_manager.start()
    love.graphics.push()
    love.graphics.translate(scale_manager.offset_x, scale_manager.offset_y)
    love.graphics.scale(scale_manager.scale_x, scale_manager.scale_y)
end

-- Restore original transformation after drawing
function scale_manager.finish()
    love.graphics.pop()
end

-- Convert window coordinates to game coordinates
function scale_manager.toGameCoords(x, y)
    -- Adjust for offset
    local adj_x = x - scale_manager.offset_x
    local adj_y = y - scale_manager.offset_y
    
    -- Apply inverse scaling
    local game_x = adj_x / scale_manager.scale_x
    local game_y = adj_y / scale_manager.scale_y
    
    return game_x, game_y
end

-- Convert game coordinates to window coordinates
function scale_manager.toWindowCoords(x, y)
    -- Apply scaling
    local window_x = x * scale_manager.scale_x + scale_manager.offset_x
    local window_y = y * scale_manager.scale_y + scale_manager.offset_y
    
    return window_x, window_y
end

-- Get mouse position in game coordinates
function scale_manager.getMousePosition()
    local x, y = love.mouse.getPosition()
    return scale_manager.toGameCoords(x, y)
end

return scale_manager 