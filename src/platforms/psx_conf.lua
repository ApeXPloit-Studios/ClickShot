function love.conf(t)
    t.window.title = "ClickShot PSX"
    t.window.width = 640
    t.window.height = 480  -- Standard PSX resolution
    t.window.resizable = false
    t.window.vsync = true
    
    -- PSX specific settings
    t.modules.joystick = true
    t.modules.keyboard = false  -- PSX doesn't have keyboard
    t.modules.mouse = false     -- PSX uses controller
end 