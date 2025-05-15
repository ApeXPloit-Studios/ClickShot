local assets = require("assets")
local scene = require("scene")  -- Import scene module for audio handling
local ui = require("ui")
local scale_manager = require("scale_manager")

local settings = {
    visible = false,
    time = 0,
    title_scale = 1,
    sliders = {
        music = { value = 1.0, dragging = false },
        sfx = { value = 1.0, dragging = false }
    },
    current_tab = "audio", -- Current selected tab: "audio" or "graphics"
    tab_buttons = {
        audio = { text = "Audio", hover = false, _bounds = nil },
        graphics = { text = "Graphics", hover = false, _bounds = nil }
    },
    back_button = { text = "Back", hover = false, _bounds = nil },
    apply_button = { text = "Apply", hover = false, _bounds = nil },
    
    -- Graphics settings
    resolutions = {
        { width = 1280, height = 720, text = "1280x720" },
        { width = 1600, height = 900, text = "1600x900" },
        { width = 1920, height = 1080, text = "1920x1080" }
    },
    current_resolution = 1, -- Index of selected resolution
    fullscreen = false,
    vsync = true,
    fullscreen_button = { text = "Fullscreen: Off", hover = false, _bounds = nil },
    vsync_button = { text = "VSync: On", hover = false, _bounds = nil },
    resolution_chooser = { text = "Resolution: 1280x720", hover = false, _bounds = nil }
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

-- Apply graphics settings
local function applyGraphicsSettings()
    local res = settings.resolutions[settings.current_resolution]
    local fullscreen = settings.fullscreen
    local vsync = settings.vsync
    
    -- Save current settings to restore if needed
    local old_width, old_height, old_flags = love.window.getMode()
    
    -- Try to apply new settings
    local success = love.window.setMode(res.width, res.height, {
        fullscreen = fullscreen,
        vsync = vsync,
        resizable = false,
        minwidth = nil,
        minheight = nil
    })
    
    -- Update UI button text
    settings.fullscreen_button.text = "Fullscreen: " .. (settings.fullscreen and "On" or "Off")
    settings.vsync_button.text = "VSync: " .. (settings.vsync and "On" or "Off")
    settings.resolution_chooser.text = "Resolution: " .. settings.resolutions[settings.current_resolution].text
    
    -- Update scale_manager
    require("scale_manager").update()
    
    if not success then
        -- Revert to old settings if failed
        love.window.setMode(old_width, old_height, {
            fullscreen = old_flags.fullscreen,
            vsync = old_flags.vsync,
            resizable = true
        })
        settings.current_resolution = 1 -- Reset to default
        settings.fullscreen = old_flags.fullscreen
        settings.vsync = old_flags.vsync
    end
    
    return success
end

-- Cycle to the next resolution
local function cycleResolution()
    -- Next resolution
    settings.current_resolution = settings.current_resolution + 1
    if settings.current_resolution > #settings.resolutions then
        settings.current_resolution = 1
    end
    
    -- Update the resolution chooser text
    settings.resolution_chooser.text = "Resolution: " .. settings.resolutions[settings.current_resolution].text
end

function settings.load()
    assets.load()
    
    -- Sync settings with scene module state
    settings.sliders.music.value = scene.audio.music_volume
    settings.sliders.sfx.value = scene.audio.sfx_volume
    
    -- Load graphics settings
    settings.loadGraphicsSettings()
    
    -- Apply initial volume settings
    applyVolumeSettings()
    
    -- Initialize resolution chooser text
    settings.resolution_chooser.text = "Resolution: " .. settings.resolutions[settings.current_resolution].text
end

function settings.loadGraphicsSettings()
    local success, user_settings = pcall(function()
        if love.filesystem.getInfo("graphics_settings.lua") then
            return love.filesystem.load("graphics_settings.lua")()()
        end
        return nil
    end)
    
    if success and user_settings then
        settings.current_resolution = user_settings.resolution_index or 1
        settings.fullscreen = user_settings.fullscreen or false
        settings.vsync = user_settings.vsync or true
        
        -- Update button text
        settings.fullscreen_button.text = "Fullscreen: " .. (settings.fullscreen and "On" or "Off")
        settings.vsync_button.text = "VSync: " .. (settings.vsync and "On" or "Off")
        settings.resolution_chooser.text = "Resolution: " .. settings.resolutions[settings.current_resolution].text
    end
end

function settings.save()
    -- Save volume settings
    love.filesystem.write("user_settings.lua", string.format(
        [[return function() return { music_volume = %f, sfx_volume = %f } end]], 
        settings.sliders.music.value, settings.sliders.sfx.value))
    
    -- Save graphics settings
    love.filesystem.write("graphics_settings.lua", string.format(
        [[return function() return { resolution_index = %d, fullscreen = %s, vsync = %s } end]],
        settings.current_resolution,
        settings.fullscreen and "true" or "false",
        settings.vsync and "true" or "false"))
end

function settings.toggle()
    settings.visible = not settings.visible
    if settings.visible then
        -- Make panel size relative to design dimensions
        local w = math.min(600, scale_manager.design_width * 0.8)
        local h = math.min(400, scale_manager.design_height * 0.8)
        local x = (scale_manager.design_width - w) / 2
        local y = (scale_manager.design_height - h) / 2
        local spacing = h * 0.15
        local startY = y + h * 0.3
        local sliderW = w * 0.75
        local sliderH = 20

        -- Position the mute button in the top-right corner
        local topRightX = scale_manager.design_width - ui.mute_button.w - 20
        ui.mute_button.x = topRightX
        ui.mute_button.y = 20
        ui.mute_button._bounds = {
            x = topRightX,
            y = 20,
            w = ui.mute_button.w,
            h = ui.mute_button.h
        }

        -- Set tab button bounds
        local tabW = w / 2 - 20
        settings.tab_buttons.audio._bounds = {
            x = x + 20,
            y = y + 50,
            w = tabW - 10,
            h = 30
        }
        
        settings.tab_buttons.graphics._bounds = {
            x = x + w/2 + 10,
            y = y + 50,
            w = tabW - 10,
            h = 30
        }
        
        -- Set audio slider bounds
        for name, slider in pairs(settings.sliders) do
            slider._bounds = {
                x = x + (w - sliderW) / 2,
                y = startY + (name == "sfx" and spacing or 0),
                w = sliderW,
                h = sliderH
            }
        end
        
        -- Set graphics option bounds
        local graphicsStartY = startY
        local buttonW = w * 0.6
        local buttonH = 40
        local buttonX = x + (w - buttonW) / 2
        
        -- Resolution chooser
        settings.resolution_chooser._bounds = {
            x = buttonX,
            y = graphicsStartY,
            w = buttonW,
            h = buttonH
        }
        
        -- Fullscreen button
        settings.fullscreen_button._bounds = {
            x = buttonX,
            y = graphicsStartY + 50,
            w = buttonW,
            h = buttonH
        }
        
        -- VSync button
        settings.vsync_button._bounds = {
            x = buttonX,
            y = graphicsStartY + 100,
            w = buttonW,
            h = buttonH
        }
        
        -- Back button bounds
        settings.back_button._bounds = {
            x = x + w * 0.1,
            y = y + h - 60,
            w = 120,
            h = 40
        }
        
        -- Apply button bounds
        settings.apply_button._bounds = {
            x = x + w - 120 - w * 0.1,
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
    
    local mx, my = scale_manager.getMousePosition()
    
    -- Update mute button hover
    ui.updateButtonHover(ui.mute_button, mx, my)
    ui.updateMuteButton(scene)
    
    -- Update tab buttons hover
    for _, button in pairs(settings.tab_buttons) do
        ui.updateButtonHover(button, mx, my)
    end
    
    if settings.current_tab == "audio" then
        -- Update slider dragging
        for name, slider in pairs(settings.sliders) do
            if slider.dragging and slider._bounds then
                local relativeX = mx - slider._bounds.x
                slider.value = math.max(0, math.min(1, relativeX / slider._bounds.w))
                
                -- Apply volume changes in real-time
                applyVolumeSettings()
            end
        end
    else -- Graphics tab
        -- Update resolution chooser hover
        ui.updateButtonHover(settings.resolution_chooser, mx, my)
        
        -- Update fullscreen button hover
        ui.updateButtonHover(settings.fullscreen_button, mx, my)
        
        -- Update vsync button hover
        ui.updateButtonHover(settings.vsync_button, mx, my)
    end
    
    -- Update back and apply button hover states
    ui.updateButtonHover(settings.back_button, mx, my)
    ui.updateButtonHover(settings.apply_button, mx, my)
end

function settings.draw()
    if not settings.visible then return end

    -- Determine panel dimensions based on design dimensions
    local w = math.min(600, scale_manager.design_width * 0.8)
    local h = math.min(400, scale_manager.design_height * 0.8)
    local x = (scale_manager.design_width - w) / 2
    local y = (scale_manager.design_height - h) / 2

    -- Create dimmed background overlay
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, scale_manager.design_width, scale_manager.design_height)

    -- Draw settings panel
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", x, y, w, h, 10, 10)

    -- Draw title with animation
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
    
    -- Draw mute button (now properly positioned in top-right)
    ui.drawMuteButton(assets)
    
    -- Draw tab buttons
    for name, button in pairs(settings.tab_buttons) do
        if button._bounds then
            -- Use static button with highlight for selected tab
            ui.drawStaticButton(
                button, 
                button._bounds.x, 
                button._bounds.y, 
                button._bounds.w, 
                button._bounds.h,
                settings.current_tab == name  -- highlight if selected
            )
        end
    end
    
    -- Draw current tab content
    if settings.current_tab == "audio" then
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
    else -- Graphics tab
        -- Draw resolution section
        love.graphics.setFont(assets.fonts.regular)
        love.graphics.setColor(1, 1, 1)
        local labelX = settings.resolution_chooser._bounds.x
        
        -- Draw resolution chooser (use static button)
        if settings.resolution_chooser._bounds then
            ui.drawStaticButton(
                settings.resolution_chooser,
                settings.resolution_chooser._bounds.x,
                settings.resolution_chooser._bounds.y,
                settings.resolution_chooser._bounds.w,
                settings.resolution_chooser._bounds.h
            )
        end
        
        -- Draw fullscreen button
        if settings.fullscreen_button._bounds then
            ui.drawStaticButton(
                settings.fullscreen_button,
                settings.fullscreen_button._bounds.x,
                settings.fullscreen_button._bounds.y,
                settings.fullscreen_button._bounds.w,
                settings.fullscreen_button._bounds.h
            )
        end
        
        -- Draw vsync button
        if settings.vsync_button._bounds then
            ui.drawStaticButton(
                settings.vsync_button,
                settings.vsync_button._bounds.x,
                settings.vsync_button._bounds.y,
                settings.vsync_button._bounds.w,
                settings.vsync_button._bounds.h
            )
        end
    end
    
    -- Draw Back button
    if settings.back_button._bounds then
        ui.drawStaticButton(
            settings.back_button,
            settings.back_button._bounds.x,
            settings.back_button._bounds.y,
            settings.back_button._bounds.w,
            settings.back_button._bounds.h
        )
    end
    
    -- Draw Apply button
    if settings.apply_button._bounds then
        ui.drawStaticButton(
            settings.apply_button,
            settings.apply_button._bounds.x,
            settings.apply_button._bounds.y,
            settings.apply_button._bounds.w,
            settings.apply_button._bounds.h
        )
    end
end

function settings.mousepressed(x, y, button)
    if not settings.visible or button ~= 1 then return end

    -- Check mute button
    if ui.handleMuteButtonClick(x, y, button, scene) then
        return
    end
    
    -- Check tab buttons
    for name, tab_button in pairs(settings.tab_buttons) do
        if tab_button._bounds and ui.pointInRect(x, y, tab_button._bounds) then
            settings.current_tab = name
            return
        end
    end
    
    -- Check Back button
    if ui.pointInRect(x, y, settings.back_button._bounds) then
        settings.visible = false
        settings.save()
        return
    end
    
    -- Check Apply button
    if ui.pointInRect(x, y, settings.apply_button._bounds) then
        if settings.current_tab == "graphics" then
            applyGraphicsSettings()
        end
        settings.save()
        return
    end
    
    -- Check tab-specific elements
    if settings.current_tab == "audio" then
        -- Check sliders
        for name, slider in pairs(settings.sliders) do
            if slider._bounds and ui.pointInRect(x, y, slider._bounds) then
                slider.dragging = true
                local relativeX = x - slider._bounds.x
                slider.value = math.max(0, math.min(1, relativeX / slider._bounds.w))
                
                -- Apply volume changes in real-time
                applyVolumeSettings()
                return
            end
        end
    else -- Graphics tab
        -- Check resolution chooser
        if ui.pointInRect(x, y, settings.resolution_chooser._bounds) then
            cycleResolution()
            return
        end
        
        -- Check fullscreen button
        if ui.pointInRect(x, y, settings.fullscreen_button._bounds) then
            settings.fullscreen = not settings.fullscreen
            settings.fullscreen_button.text = "Fullscreen: " .. (settings.fullscreen and "On" or "Off")
            return
        end
        
        -- Check vsync button
        if ui.pointInRect(x, y, settings.vsync_button._bounds) then
            settings.vsync = not settings.vsync
            settings.vsync_button.text = "VSync: " .. (settings.vsync and "On" or "Off")
            return
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