local scale_manager = {
    -- Base resolution that the game is designed for
    base_width = 800,
    base_height = 600,
    -- Current scale factors
    scale_x = 1,
    scale_y = 1,
    -- Offset for letterboxing/pillarboxing
    offset_x = 0,
    offset_y = 0,
    -- Common aspect ratios for mobile
    aspect_ratios = {
        { name = "16:9", ratio = 16/9 },
        { name = "18:9", ratio = 18/9 },
        { name = "19.5:9", ratio = 19.5/9 },
        { name = "20:9", ratio = 20/9 }
    }
}

-- Update scaling factors based on window size
function scale_manager.update()
    local window_width, window_height = love.graphics.getDimensions()
    
    -- On iOS, use the full screen dimensions
    if love.system.getOS() == "iOS" then
        -- Get the actual screen dimensions
        local w, h = love.window.getMode()
        window_width, window_height = w, h
        
        -- Calculate current aspect ratio
        local current_ratio = window_width / window_height
        
        -- Find closest matching aspect ratio
        local closest_ratio = scale_manager.aspect_ratios[1]
        local min_diff = math.abs(current_ratio - closest_ratio.ratio)
        
        for _, ratio in ipairs(scale_manager.aspect_ratios) do
            local diff = math.abs(current_ratio - ratio.ratio)
            if diff < min_diff then
                min_diff = diff
                closest_ratio = ratio
            end
        end
        
        -- Adjust base resolution based on closest aspect ratio
        if closest_ratio.name == "16:9" then
            scale_manager.base_width = 720
            scale_manager.base_height = 1280
        elseif closest_ratio.name == "18:9" then
            scale_manager.base_width = 720
            scale_manager.base_height = 1440
        elseif closest_ratio.name == "19.5:9" then
            scale_manager.base_width = 720
            scale_manager.base_height = 1560
        elseif closest_ratio.name == "20:9" then
            scale_manager.base_width = 720
            scale_manager.base_height = 1600
        end
    end
    
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