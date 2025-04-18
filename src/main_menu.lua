local assets = require("assets")
local scene = require("scene")
local background_effect = require("background_effect")
local settings = require("settings")

local main_menu = {
    time = 0,
    title_scale = 1,
    title_rotation = 0
}

local buttons = {
    { text = "Play", x = 0, y = 0, w = 200, h = 50, action = function() scene.set("game") end },
    { text = "Settings", x = 0, y = 0, w = 200, h = 50, action = function() settings.toggle() end }
}

-- Only add exit button if not on iOS
if love.system.getOS() ~= "iOS" then
    table.insert(buttons, { text = "Exit", x = 0, y = 0, w = 200, h = 50, action = function() love.event.quit() end })
end

function main_menu.load()
    background_effect.load()
    settings.load()
    
    local screenW, screenH = love.graphics.getDimensions()
    local spacing = 20
    for i, b in ipairs(buttons) do
        b.x = (screenW - b.w) / 2
        b.y = (screenH / 2 - (#buttons * (b.h + spacing)) / 2) + ((i - 1) * (b.h + spacing))
    end
end

function main_menu.update(dt)
    main_menu.time = main_menu.time + dt
    
    -- Update title animation
    main_menu.title_scale = 1 + 0.1 * math.sin(main_menu.time * 2)
    main_menu.title_rotation = 0.05 * math.sin(main_menu.time)
    
    -- Update background effect
    background_effect.update(dt)
    
    -- Update settings
    settings.update(dt)
    
    -- Update button hover states
    local mx, my = love.mouse.getPosition()
    for _, b in ipairs(buttons) do
        b.hover = mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h
    end
end

function main_menu.draw()
    -- Draw background effect
    background_effect.draw()
    
    -- Draw title with animation
    love.graphics.setFont(assets.fonts.bold)
    local title = "ClickShot"
    local tw = assets.fonts.bold:getWidth(title)
    local th = assets.fonts.bold:getHeight()
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
    
    -- Draw buttons with enhanced hover effects
    for _, b in ipairs(buttons) do
        -- Button background with hover effect
        local hover_scale = b.hover and 1.1 or 1
        local hover_color = b.hover and {0.4, 0.4, 0.4} or {0.2, 0.2, 0.2}
        
        love.graphics.push()
        love.graphics.translate(b.x + b.w/2, b.y + b.h/2)
        love.graphics.scale(hover_scale, hover_scale)
        love.graphics.translate(-b.w/2, -b.h/2)
        
        -- Draw button background with rounded corners
        love.graphics.setColor(hover_color[1], hover_color[2], hover_color[3])
        love.graphics.rectangle("fill", 0, 0, b.w, b.h, 10, 10)
        
        -- Draw button border
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("line", 0, 0, b.w, b.h, 10, 10)
        
        -- Draw button text
        love.graphics.setColor(1, 1, 1)
        local textW = assets.fonts.bold:getWidth(b.text)
        local textH = assets.fonts.bold:getHeight()
        love.graphics.print(b.text, (b.w - textW) / 2, (b.h - textH) / 2)
        
        love.graphics.pop()
    end
    
    -- Draw settings if visible
    settings.draw()
end

function main_menu.mousepressed(x, y, button)
    if button == 1 then
        -- Check settings first
        if settings.visible then
            settings.mousepressed(x, y, button)
            return
        end
        
        -- Then check menu buttons
        for _, b in ipairs(buttons) do
            if b.hover then
                b.action()
                return
            end
        end
    end
end

return main_menu
