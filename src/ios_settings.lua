local ios_settings = {}

function ios_settings.init()
    if love.system.getOS() == "iOS" then
        -- Set fullscreen mode
        love.window.setMode(0, 0, {
            fullscreen = true,
            resizable = false,
            highdpi = true
        })
    end
end

return ios_settings 