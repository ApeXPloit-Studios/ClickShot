local scale_manager = {
    -- Fixed resolution
    width = 1280,
    height = 720,
    scale = 1,
    offset_x = 0,
    offset_y = 0
}

function scale_manager.update()
    -- No scaling needed since we're enforcing 720p
    scale_manager.scale = 1
    scale_manager.offset_x = 0
    scale_manager.offset_y = 0
end

function scale_manager.start()
    -- No transform needed
end

function scale_manager.finish()
    -- No transform needed
end

function scale_manager.toGameCoords(x, y)
    -- Direct mapping since we're not scaling
    return x, y
end

return scale_manager 