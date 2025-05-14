local assets = require("assets")
local scene = require("scene")  -- Import scene module for audio handling
local ui = require("ui")

local settings = {
    visible = false,
    time = 0,
    title_scale = 1,
    sliders = {
        music = { value = 1.0, dragging = false },
        sfx = { value = 1.0, dragging = false }
    },
    back_button = { text = "Back", hover = false, _bounds = nil }
}

-- Apply volume settings
local function applyVolumeSettings()
    -- Set music volume in scene module
    scene.setMusicVolume(settings.sliders.music.value)
    
    -- Set sound effects volume
    scene.setSfxVolume(settings.sliders.sfx.value)
    
    -- Apply to individual sound effects
    for _, sound in pairs(assets.sounds) do
        if type(sound) == "userdata" and sound.setVolume then
            scene.applySfxVolume(sound)
        end
    end
end

function settings.load()
    assets.load()
    
    -- Sync settings with scene module state
    settings.sliders.music.value = scene.audio.music_volume
    settings.sliders.sfx.value = scene.audio.sfx_volume
    
    -- Apply initial volume settings
    applyVolumeSettings()
end

function settings.save()
    -- Save volume settings
    love.filesystem.write("user_settings.lua", string.format(
        [[return function() return { music_volume = %f, sfx_volume = %f } end]], 
        settings.sliders.music.value, settings.sliders.sfx.value))
end

function settings.toggle()
    settings.visible = not settings.visible
    if settings.visible then
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
        
        -- Back button bounds
        settings.back_button._bounds = {
            x = x + w/2 - 60,
            y = y + h - 60,
            w = 120,
            h = 40
        }
    end
end

function settings.update(dt)
    if not settings.visible then return end
    
    settings.time = settings.time + dt
    settings.title_scale = 1 + 0.05 * math.sin(settings.time * 2)
    
    -- Update UI hover effect
    ui.update(dt)
    
    local mx, my = love.mouse.getPosition()
    
    -- Update mute button hover
    ui.updateButtonHover(ui.mute_button, mx, my)
    ui.updateMuteButton(scene)
    
    -- Update slider dragging
    for name, slider in pairs(settings.sliders) do
        if slider.dragging and slider._bounds then
            local relativeX = mx - slider._bounds.x
            slider.value = math.max(0, math.min(1, relativeX / slider._bounds.w))
            
            -- Apply volume changes in real-time
            applyVolumeSettings()
        end
    end
    
    -- Update back button hover state
    ui.updateButtonHover(settings.back_button, mx, my)
end

function settings.draw()
    if not settings.visible then return end

    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

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
    
    for i = 1, 5 do
        local alpha = 1 - (i * 0.2)
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.print(title, i, i)
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(title, 0, 0)
    love.graphics.pop()
    
    -- Draw mute button with UI module
    ui.drawMuteButton(assets)

    -- Draw sliders
    love.graphics.setFont(assets.fonts.regular)
    for name, slider in pairs(settings.sliders) do
        if slider._bounds then
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(name == "music" and "Music Volume" or "Sound Effects Volume",
                              slider._bounds.x, slider._bounds.y - 25)

            -- Draw slider background
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.rectangle("fill", slider._bounds.x, slider._bounds.y,
                                  slider._bounds.w, slider._bounds.h, 5, 5)

            -- Draw slider fill (dimmed if muted)
            if scene.isMuted() then
                love.graphics.setColor(0.3, 0.3, 0.5)
            else
            love.graphics.setColor(0.5, 0.5, 1)
            end
            
            love.graphics.rectangle("fill", slider._bounds.x, slider._bounds.y,
                                  slider._bounds.w * slider.value, slider._bounds.h, 5, 5)

            -- Draw slider handle
            love.graphics.setColor(scene.isMuted() and {0.6, 0.6, 0.6} or {1, 1, 1})
            local handleX = slider._bounds.x + (slider._bounds.w * slider.value)
            love.graphics.circle("fill", handleX, slider._bounds.y + slider._bounds.h/2, 10)
        end
    end
    
    -- Draw Back button with UI module
    if settings.back_button._bounds then
        ui.drawButton(settings.back_button, 
                     settings.back_button._bounds.x, 
                     settings.back_button._bounds.y, 
                     settings.back_button._bounds.w, 
                     settings.back_button._bounds.h)
    end
end

function settings.mousepressed(x, y, button)
    if not settings.visible or button ~= 1 then return end

    -- Check mute button
    if ui.handleMuteButtonClick(x, y, button, scene) then
        return
    end
    
    -- Check Back button
    local b = settings.back_button._bounds
    if b and x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h then
        settings.visible = false
        settings.save()
        return
    end
    
    -- Check sliders
    for name, slider in pairs(settings.sliders) do
        if slider._bounds then
            if x >= slider._bounds.x and x <= slider._bounds.x + slider._bounds.w and
               y >= slider._bounds.y and y <= slider._bounds.y + slider._bounds.h then
                slider.dragging = true
                local relativeX = x - slider._bounds.x
                slider.value = math.max(0, math.min(1, relativeX / slider._bounds.w))
                
                -- Apply volume changes in real-time
                applyVolumeSettings()
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
                settings.save()
            end
        end
    end
end

return settings 