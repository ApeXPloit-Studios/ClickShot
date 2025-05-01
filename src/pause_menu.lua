local assets = require("assets")
local scene = require("scene")
local save = require("save")
local shop = require("shop")
local background_effect = require("background_effect")

local pause_menu = {
    visible = false,
    time = 0,
    title_scale = 1
}

local buttons = {
    { text = "Resume", hover = false, action = function() pause_menu.visible = false end },
    { text = "Main Menu", hover = false, action = function() 
        pause_menu.visible = false
        save.update(require("game").shells, shop.cosmetics)
        scene.set("menu")
    end }
}

-- Only add exit button if not on iOS
if love.system.getOS() ~= "iOS" then
    table.insert(buttons, { text = "Exit", hover = false, action = function() 
        save.update(require("game").shells, shop.cosmetics)
        love.event.quit() 
    end })
end

function pause_menu.toggle()
    pause_menu.visible = not pause_menu.visible
end

function pause_menu.update(dt)
    if not pause_menu.visible then return end
    
    pause_menu.time = pause_menu.time + dt
    pause_menu.title_scale = 1 + 0.05 * math.sin(pause_menu.time * 2)
    
    -- Update background effect
    background_effect.update(dt)
    
    -- Update button hover states
    local mx, my = love.mouse.getPosition()
    for _, b in ipairs(buttons) do
        local was_hover = b.hover
        b.hover = mx >= b._bounds.x and mx <= b._bounds.x + b._bounds.w and 
                 my >= b._bounds.y and my <= b._bounds.y + b._bounds.h
        
        -- Could add hover sound here if we want
        if b.hover and not was_hover then
            -- love.audio.play(assets.sounds.hover)
        end
    end
end

function pause_menu.draw()
    if not pause_menu.visible then return end

    -- Draw background effect with overlay
    background_effect.draw()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Draw menu
    local w, h = 400, 300
    local x, y = (love.graphics.getWidth() - w) / 2, (love.graphics.getHeight() - h) / 2

    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", x, y, w, h, 10, 10)

    -- Draw animated title
    love.graphics.setFont(assets.fonts.bold)
    love.graphics.setColor(1, 1, 1)
    
    local title = "Paused"
    local tw = assets.fonts.bold:getWidth(title)
    local th = assets.fonts.bold:getHeight()
    
    love.graphics.push()
    love.graphics.translate(x + w/2, y + 10 + th/2)
    love.graphics.scale(pause_menu.title_scale, pause_menu.title_scale)
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

    local spacing = 60
    local startY = y + 50
    local buttonH = 50

    for i, b in ipairs(buttons) do
        local by = startY + (i-1) * spacing
        local bx, bw = x + 50, w - 100
        b._bounds = { x = bx, y = by, w = bw, h = buttonH }

        -- Button background with hover effect
        local hover_scale = b.hover and 1.1 or 1
        local hover_color = b.hover and {0.4, 0.4, 0.4} or {0.2, 0.2, 0.2}
        
        love.graphics.push()
        love.graphics.translate(bx + bw/2, by + buttonH/2)
        love.graphics.scale(hover_scale, hover_scale)
        love.graphics.translate(-bw/2, -buttonH/2)
        
        -- Draw button glow when hovered
        if b.hover then
            for i = 1, 3 do
                local glow_alpha = 0.1 - (i * 0.03)
                love.graphics.setColor(0.5, 0.5, 1, glow_alpha)
                love.graphics.rectangle("fill", -i*2, -i*2, bw + i*4, buttonH + i*4, 10 + i, 10 + i)
            end
        end
        
        -- Draw button background with rounded corners
        love.graphics.setColor(hover_color[1], hover_color[2], hover_color[3])
        love.graphics.rectangle("fill", 0, 0, bw, buttonH, 10, 10)
        
        -- Draw button border
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("line", 0, 0, bw, buttonH, 10, 10)
        
        -- Draw button text with shadow when hovered
        if b.hover then
            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.print(b.text, (bw - assets.fonts.bold:getWidth(b.text)) / 2 + 2, 
                              (buttonH - assets.fonts.bold:getHeight()) / 2 + 2)
        end
        
        -- Draw button text
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(b.text, (bw - assets.fonts.bold:getWidth(b.text)) / 2, 
                          (buttonH - assets.fonts.bold:getHeight()) / 2)
        
        love.graphics.pop()
    end
end

function pause_menu.mousepressed(mx, my, button)
    if not pause_menu.visible or button ~= 1 then return end

    for _, b in ipairs(buttons) do
        if b.hover then
            -- Play click sound
            love.audio.play(assets.sounds.click)
            b.action()
            return
        end
    end
end

return pause_menu 