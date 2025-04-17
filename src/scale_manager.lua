local scale_manager = {
    -- Base resolution that the game is designed for
    base_width = 800,
    base_height = 600,
    -- Current scale factors
    scale_x = 1,
    scale_y = 1,
    -- Offset for letterboxing/pillarboxing
    offset_x = 0,
    offset_y = 0
}

-- Update scaling factors based on window size
function scale_manager.update()
    local window_width, window_height = love.graphics.getDimensions()
    local scale_x = window_width / scale_manager.base_width
    local scale_y = window_height / scale_manager.base_height
    
    -- Use the smaller scale to maintain aspect ratio
    local scale = math.min(scale_x, scale_y)
    
    scale_manager.scale_x = scale
    scale_manager.scale_y = scale
    
    -- Calculate offsets for centering
    scale_manager.offset_x = (window_width - scale_manager.base_width * scale) / 2
    scale_manager.offset_y = (window_height - scale_manager.base_height * scale) / 2
end

-- Apply scaling transform
function scale_manager.start()
    love.graphics.push()
    love.graphics.translate(scale_manager.offset_x, scale_manager.offset_y)
    love.graphics.scale(scale_manager.scale_x, scale_manager.scale_y)
end

-- Restore previous transform
function scale_manager.finish()
    love.graphics.pop()
end

-- Convert screen coordinates to game coordinates
function scale_manager.toGameCoords(x, y)
    return (x - scale_manager.offset_x) / scale_manager.scale_x,
           (y - scale_manager.offset_y) / scale_manager.scale_y
end

return scale_manager 