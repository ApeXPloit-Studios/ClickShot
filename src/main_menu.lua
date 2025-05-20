local assets = require("assets")
local scene = require("scene")
local background_effect = require("background_effect")
local settings = require("settings")
local ui = require("ui")
local scale_manager = require("scale_manager")
local save_slot_menu = require("save_slot_menu")

local main_menu = {
    time = 0,
    title_scale = 1,
    title_rotation = 0,
    button_sound_played = false,
    discord_button = {
        x = 0,
        y = 0,
        size = 48,  -- Size of the Discord button
        hover = false
    },
    version = "1.1.0-alpha"  -- Current version
}

local buttons = {
    { text = "Play", x = 0, y = 0, w = 200, h = 50, hover = false, action = function() save_slot_menu.show("load") end },
    { text = "Settings", x = 0, y = 0, w = 200, h = 50, hover = false, action = function() settings.toggle() end }
}

-- Only add exit button if not on iOS
if love.system.getOS() ~= "iOS" then
    table.insert(buttons, { text = "Exit", x = 0, y = 0, w = 200, h = 50, hover = false, action = function() love.event.quit() end })
end

-- Function to get OS-specific version string
function main_menu.getVersionString()
    local os = love.system.getOS()
    local prefix = ""
    
    if os == "Windows" then
        prefix = "Win"
    elseif os == "OS X" then
        prefix = "Mac"
    elseif os == "Linux" then
        prefix = "Linux"
    elseif os == "Android" then
        prefix = "Android"
    elseif os == "iOS" then
        prefix = "iOS"
    else
        prefix = os
    end
    
    return prefix .. " v" .. main_menu.version
end

function main_menu.load()
    background_effect.load()
    save_slot_menu.load()
    
    -- Load Discord icon
    main_menu.discord_icon = love.graphics.newImage("assets/images/discord.png")
    
    -- Position main buttons
    local spacing = 20
    
    -- Position main buttons
    for i, b in ipairs(buttons) do
        b.x = (scale_manager.design_width - b.w) / 2
        b.y = (scale_manager.design_height / 2 - (#buttons * (b.h + spacing)) / 2) + ((i - 1) * (b.h + spacing))
    end
    
    -- Position Discord button in bottom right
    main_menu.discord_button.x = scale_manager.design_width - main_menu.discord_button.size - 20
    main_menu.discord_button.y = scale_manager.design_height - main_menu.discord_button.size - 20
end

function main_menu.update(dt)
    main_menu.time = main_menu.time + dt
    
    -- Update title animation
    main_menu.title_scale = 1 + 0.1 * math.sin(main_menu.time * 2)
    main_menu.title_rotation = 0.05 * math.sin(main_menu.time)
    
    -- Update UI hover effect
    ui.update(dt)
    
    -- Update button hover states
    local mx, my = scale_manager.getMousePosition()
    local hover_found = false
    
    -- Update main buttons
    for _, b in ipairs(buttons) do
        -- Set _bounds for each button for UI module to work
        b._bounds = { x = b.x, y = b.y, w = b.w, h = b.h }
        
        local was_hover = b.hover
        ui.updateButtonHover(b, mx, my)
        
        if b.hover and not was_hover then
            hover_found = true
        end
    end
    
    -- Update Discord button hover
    local db = main_menu.discord_button
    db._bounds = { x = db.x, y = db.y, w = db.size, h = db.size }
    
    local was_hover = db.hover
    ui.updateButtonHover(db, mx, my)
    
    if db.hover and not was_hover then
        hover_found = true
    end
    
    -- Update mute button hover
    ui.updateButtonHover(ui.mute_button, mx, my)
    ui.updateMuteButton(scene)
    
    -- Update settings if visible
    if settings.visible then
        settings.update(dt)
    end
    
    -- Update save slot menu if visible
    if save_slot_menu.visible then
        save_slot_menu.update(dt)
    end
    
    -- Reset button sound flag when no buttons are hovered
    if not hover_found then
        main_menu.button_sound_played = false
    end
end

function main_menu.draw()
    -- Draw background effect
    background_effect.draw()
    
    -- Draw settings if visible and return (modal)
    if settings.visible then
        settings.draw()
        return
    end
    
    -- Draw save slot menu if visible and return (modal)
    if save_slot_menu.visible then
        save_slot_menu.draw()
        return
    end
    
    -- Draw title with animation
    love.graphics.setFont(assets.fonts.title)  -- Use title font instead of bold
    love.graphics.setColor(1, 1, 1)
    
    ui.drawAnimatedTitle(
        "ClickShot", 
        scale_manager.design_width / 2, 
        100 + assets.fonts.title:getHeight()/2, 
        main_menu.title_scale, 
        assets.fonts.title,
        {
            centerX = true,
            centerY = true,
            rotation = main_menu.title_rotation,
            glowLayers = 5,
            glowIntensity = 0.2
        }
    )
    
    -- Draw main buttons
    love.graphics.setFont(assets.fonts.bold)  -- Set back to regular bold font for buttons
    for _, b in ipairs(buttons) do
        ui.drawButton(b, b.x, b.y, b.w, b.h)
    end
    
    -- Draw mute button
    love.graphics.setFont(assets.fonts.bold)
    ui.drawMuteButton(assets)
    
    -- Draw Discord button
    local db = main_menu.discord_button
    
    -- Special case for circular Discord button
    love.graphics.push()
    
    local buttonScale = 1 + (db.hover and math.sin(ui.hover_effect) * 0.1 or 0)
    love.graphics.translate(db.x + db.size/2, db.y + db.size/2)
    love.graphics.scale(buttonScale, buttonScale)
    love.graphics.translate(-(db.size/2), -(db.size/2))
    
    -- Draw button glow when hovered
    if db.hover then
        for i = 1, 3 do
            local glow_alpha = 0.1 - (i * 0.03)
            love.graphics.setColor(0.5, 0.5, 1, glow_alpha)
            love.graphics.circle("fill", db.size/2, db.size/2, db.size/2 + i*2)
        end
    end
    
    -- Draw Discord icon
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(main_menu.discord_icon, 0, 0, 0, db.size/main_menu.discord_icon:getWidth(), db.size/main_menu.discord_icon:getHeight())
    
    love.graphics.pop()

    -- Draw version string in bottom left
    love.graphics.setFont(assets.fonts.regular)
    local version_text = main_menu.getVersionString()
    love.graphics.setColor(0.7, 0.7, 0.7, 0.8)  -- Slightly transparent gray
    love.graphics.print(version_text, 20, scale_manager.design_height - 30)
end

function main_menu.mousepressed(x, y, button)
    if button == 1 then
        -- Handle settings menu if visible
        if settings.visible then
            settings.mousepressed(x, y, button)
            return
        end
        
        -- Handle save slot menu if visible
        if save_slot_menu.visible then
            save_slot_menu.mousepressed(x, y, button)
            return
        end
        
        -- Mute button
        if ui.handleMuteButtonClick(x, y, button, scene) then
            return
        end
        
        -- Check Discord button
        local db = main_menu.discord_button
        if db.hover then
            love.system.openURL("https://discord.gg/PpWupysxU8")
            return
        end
        
        -- Check other buttons
        for _, b in ipairs(buttons) do
            if b.hover then
                -- Play click sound
                if assets.sounds.click then
                    scene.playSound(assets.sounds.click)
                end
                
                b.action()
                return
            end
        end
    end
end

function main_menu.mousereleased(x, y, button)
    -- Handle settings menu if visible
    if settings.visible then
        settings.mousereleased(x, y, button)
    end
end

return main_menu
