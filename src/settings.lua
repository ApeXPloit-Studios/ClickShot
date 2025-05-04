local assets = require("assets")
local settings = {
    music_volume = 1.0,
    sfx_volume = 1.0,
    visible = false,
    time = 0,
    title_scale = 1,
    sliders = {
        music = { value = 1.0, dragging = false },
        sfx = { value = 1.0, dragging = false }
    }
}

function settings.load()
    -- Ensure assets are loaded
    assets.load()
    
    -- Load saved settings if they exist
    local saved = love.filesystem.load("user_settings.lua")
    if saved then
        local saved_settings = saved()
        settings.music_volume = saved_settings.music_volume or 1.0
        settings.sfx_volume = saved_settings.sfx_volume or 1.0
        settings.sliders.music.value = settings.music_volume
        settings.sliders.sfx.value = settings.sfx_volume
    end
end

function settings.save()
    love.filesystem.write("user_settings.lua", string.format([[return function() return { music_volume = %f, sfx_volume = %f } end]], settings.music_volume, settings.sfx_volume))
end

function settings.toggle()
    settings.visible = not settings.visible
    if settings.visible then
        -- Initialize slider bounds
        local w, h = 400, 300
        local x, y = (love.graphics.getWidth() - w) / 2, (love.graphics.getHeight() - h) / 2
        local spacing = 60
        local startY = y + 100
        local sliderW = w - 100
        local sliderH = 20

        for name, slider in pairs(settings.sliders) do
            slider._bounds = {
                x = x + 50,
                y = startY + (name == "sfx" and spacing or 0),
                w = sliderW,
                h = sliderH
            }
        end
    end
end

function settings.update(dt)
    if not settings.visible then return end
    
    settings.time = settings.time + dt
    settings.title_scale = 1 + 0.05 * math.sin(settings.time * 2)
    
    -- Update slider values based on mouse position
    local mx, my = love.mouse.getPosition()
    for _, slider in pairs(settings.sliders) do
        if slider.dragging and slider._bounds then
            local relativeX = mx - slider._bounds.x
            slider.value = math.max(0, math.min(1, relativeX / slider._bounds.w))
            
            -- Update corresponding volume
            if slider == settings.sliders.music then
                settings.music_volume = slider.value
            else
                settings.sfx_volume = slider.value
            end
        end
    end
end

function settings.draw()
    if not settings.visible then return end

    -- Draw background overlay
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Draw menu
    local w, h = 400, 300
    local x, y = (love.graphics.getWidth() - w) / 2, (love.graphics.getHeight() - h) / 2

    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", x, y, w, h, 10, 10)

    -- Draw title
    love.graphics.setFont(assets.fonts.bold)
    love.graphics.setColor(1, 1, 1)
    
    local title = "Settings"
    local tw = assets.fonts.bold:getWidth(title)
    local th = assets.fonts.bold:getHeight()
    
    love.graphics.push()
    love.graphics.translate(x + w/2, y + 10 + th/2)
    love.graphics.scale(settings.title_scale, settings.title_scale)
    love.graphics.translate(-tw/2, -th/2)
    
    -- Draw title with glow effect
    for i = 1, 5 do
        local alpha = 1 - (i * 0.2)
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.print(title, i, i)
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(title, 0, 0)
    
    love.graphics.pop()

    -- Draw sliders
    love.graphics.setFont(assets.fonts.regular)
    for name, slider in pairs(settings.sliders) do
        if slider._bounds then
            -- Draw label
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(name == "music" and "Music Volume" or "Sound Effects Volume",
                              slider._bounds.x, slider._bounds.y - 25)

            -- Draw slider background
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.rectangle("fill", slider._bounds.x, slider._bounds.y,
                                  slider._bounds.w, slider._bounds.h, 5, 5)

            -- Draw slider fill
            love.graphics.setColor(0.5, 0.5, 1)
            love.graphics.rectangle("fill", slider._bounds.x, slider._bounds.y,
                                  slider._bounds.w * slider.value, slider._bounds.h, 5, 5)

            -- Draw slider handle
            love.graphics.setColor(1, 1, 1)
            local handleX = slider._bounds.x + (slider._bounds.w * slider.value)
            love.graphics.circle("fill", handleX, slider._bounds.y + slider._bounds.h/2, 10)
        end
    end
end

function settings.mousepressed(x, y, button)
    if not settings.visible or button ~= 1 then return end

    -- Check if clicking on any slider
    for _, slider in pairs(settings.sliders) do
        if slider._bounds then
            if x >= slider._bounds.x and x <= slider._bounds.x + slider._bounds.w and
               y >= slider._bounds.y and y <= slider._bounds.y + slider._bounds.h then
                slider.dragging = true
                -- Update value immediately
                local relativeX = x - slider._bounds.x
                slider.value = math.max(0, math.min(1, relativeX / slider._bounds.w))
                
                -- Update corresponding volume
                if slider == settings.sliders.music then
                    settings.music_volume = slider.value
                else
                    settings.sfx_volume = slider.value
                end
                return
            end
        end
    end
end

function settings.mousereleased(x, y, button)
    if button == 1 then
        for _, slider in pairs(settings.sliders) do
            if slider.dragging then
                slider.dragging = false
                settings.save()  -- Save settings when slider is released
            end
        end
    end
end

return settings 