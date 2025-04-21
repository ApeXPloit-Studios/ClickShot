function love.conf(t)
    t.window.title = "ClickShot R36S"
    t.window.width = 640
    t.window.height = 480  -- R36S resolution
    t.window.resizable = false
    t.window.vsync = true
    t.window.fullscreen = true  -- Always fullscreen for R36S
    
    -- Normal controls for R36S
    t.modules.joystick = true
    t.modules.keyboard = true   -- Enable keyboard
    t.modules.mouse = true      -- Enable mouse
end 