function love.conf(t)
    t.window.title = "ClickShot N64"
    t.window.width = 640
    t.window.height = 480  -- Classic N64 resolution
    t.window.resizable = false
    t.window.vsync = true
    
    -- N64 specific settings
    t.modules.joystick = true
    t.modules.keyboard = false  -- N64 doesn't have keyboard
    t.modules.mouse = false     -- N64 uses controller
end 