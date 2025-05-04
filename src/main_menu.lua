local assets = require("assets")
local scene = require("scene")
local background_effect = require("background_effect")

local main_menu = {
    time = 0,
    title_scale = 1,
    title_rotation = 0,
    hover_effect = 0,
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
    { text = "Play", x = 0, y = 0, w = 200, h = 50, hover = false, action = function() scene.set("game") end }
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
    
    -- Load Discord icon
    main_menu.discord_icon = love.graphics.newImage("assets/images/discord.png")
    
    local screenW, screenH = love.graphics.getDimensions()
    local spacing = 20
    
    -- Position main buttons
    for i, b in ipairs(buttons) do
        b.x = (screenW - b.w) / 2
        b.y = (screenH / 2 - (#buttons * (b.h + spacing)) / 2) + ((i - 1) * (b.h + spacing))
    end
    
    -- Position Discord button in bottom right
    main_menu.discord_button.x = screenW - main_menu.discord_button.size - 20
    main_menu.discord_button.y = screenH - main_menu.discord_button.size - 20
end

function main_menu.update(dt)
    main_menu.time = main_menu.time + dt
    
    -- Update title animation
    main_menu.title_scale = 1 + 0.1 * math.sin(main_menu.time * 2)
    main_menu.title_rotation = 0.05 * math.sin(main_menu.time)
    
    -- Update hover effect
    main_menu.hover_effect = main_menu.hover_effect + dt * 2
    if main_menu.hover_effect > math.pi * 2 then
        main_menu.hover_effect = 0
    end
    
    -- Update button hover states
    local mx, my = love.mouse.getPosition()
    local hover_found = false
    
    -- Update main buttons
    for _, b in ipairs(buttons) do
        local was_hover = b.hover
        b.hover = mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h
        
        if b.hover and not was_hover then
            hover_found = true
        end
    end
    
    -- Update Discord button hover
    local db = main_menu.discord_button
    local was_hover = db.hover
    db.hover = mx >= db.x and mx <= db.x + db.size and my >= db.y and my <= db.y + db.size
    
    if db.hover and not was_hover then
        hover_found = true
    end
    
    -- Reset button sound flag when no buttons are hovered
    if not hover_found then
        main_menu.button_sound_played = false
    end
end

function main_menu.draw()
    -- Draw background effect
    background_effect.draw()
    
    -- Draw title with animation
    love.graphics.setFont(assets.fonts.title)  -- Use title font instead of bold
    local title = "ClickShot"
    local tw = assets.fonts.title:getWidth(title)
    local th = assets.fonts.title:getHeight()
    local titleX = (love.graphics.getWidth() - tw) / 2
    local titleY = 100
    
    -- Save current transform
    love.graphics.push()
    
    -- Apply title animation
    love.graphics.translate(titleX + tw/2, titleY + th/2)
    love.graphics.rotate(main_menu.title_rotation)
    love.graphics.scale(main_menu.title_scale, main_menu.title_scale)
    love.graphics.translate(-tw/2, -th/2)
    
    -- Draw title with glow effect
    for i = 1, 5 do
        local alpha = 1 - (i * 0.2)
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.print(title, i, i)
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(title, 0, 0)
    
    -- Restore transform
    love.graphics.pop()
    
    -- Draw main buttons
    love.graphics.setFont(assets.fonts.bold)  -- Set back to regular bold font for buttons
    for _, b in ipairs(buttons) do
        -- Button background with hover effect
        local hover_scale = 1 + (b.hover and math.sin(main_menu.hover_effect) * 0.1 or 0)
        local hover_color = b.hover and {0.4, 0.4, 0.4} or {0.2, 0.2, 0.2}
        
        love.graphics.push()
        love.graphics.translate(b.x + b.w/2, b.y + b.h/2)
        love.graphics.scale(hover_scale, hover_scale)
        love.graphics.translate(-b.w/2, -b.h/2)
        
        -- Draw button glow when hovered
        if b.hover then
            for i = 1, 3 do
                local glow_alpha = 0.1 - (i * 0.03)
                love.graphics.setColor(0.5, 0.5, 1, glow_alpha)
                love.graphics.rectangle("fill", -i*2, -i*2, b.w + i*4, b.h + i*4, 10 + i, 10 + i)
            end
        end
        
        -- Draw button background
        love.graphics.setColor(hover_color[1], hover_color[2], hover_color[3])
        love.graphics.rectangle("fill", 0, 0, b.w, b.h, 10, 10)
        
        -- Draw button border
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("line", 0, 0, b.w, b.h, 10, 10)
        
        -- Draw button text with shadow
        if b.hover then
            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.print(b.text, (b.w - assets.fonts.bold:getWidth(b.text)) / 2 + 2, 
                              (b.h - assets.fonts.bold:getHeight()) / 2 + 2)
        end
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(b.text, (b.w - assets.fonts.bold:getWidth(b.text)) / 2, 
                          (b.h - assets.fonts.bold:getHeight()) / 2)
        
        love.graphics.pop()
    end
    
    -- Draw Discord button
    local db = main_menu.discord_button
    local hover_scale = 1 + (db.hover and math.sin(main_menu.hover_effect) * 0.1 or 0)
    
    love.graphics.push()
    love.graphics.translate(db.x + db.size/2, db.y + db.size/2)
    love.graphics.scale(hover_scale, hover_scale)
    love.graphics.translate(-db.size/2, -db.size/2)
    
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
    love.graphics.print(version_text, 20, love.graphics.getHeight() - 30)
end

function main_menu.mousepressed(x, y, button)
    if button == 1 then
        -- Check Discord button first
        local db = main_menu.discord_button
        if x >= db.x and x <= db.x + db.size and y >= db.y and y <= db.y + db.size then
            love.system.openURL("https://discord.gg/PpWupysxU8")
            return
        end
        
        -- Check other buttons
        for _, b in ipairs(buttons) do
            if b.hover then
                -- Play click sound
                love.audio.play(assets.sounds.click)
                b.action()
                return
            end
        end
    end
end

return main_menu
