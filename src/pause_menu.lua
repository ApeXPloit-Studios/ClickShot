local assets = require("assets")
local scene = require("scene")
local settings = require("settings")
local save = require("save")
local shop = require("shop")
local background_effect = require("background_effect")

local pause_menu = {
    visible = false,
    time = 0,
    title_scale = 1
}

local buttons = {
    { text = "Resume", action = function() pause_menu.visible = false end },
    { text = "Settings", action = function() settings.toggle() end },
    { text = "Main Menu", action = function() 
        pause_menu.visible = false
        save.update(require("game").shells, shop.cosmetics)
        scene.set("menu")
    end }
}

-- Only add exit button if not on iOS
if love.system.getOS() ~= "iOS" then
    table.insert(buttons, { text = "Exit", action = function() 
        save.update(require("game").shells, shop.cosmetics)
        love.event.quit() 
    end })
end

function pause_menu.toggle()
    pause_menu.visible = not pause_menu.visible
    if not pause_menu.visible then
        settings.visible = false
    end
end

function pause_menu.update(dt)
    if not pause_menu.visible then return end
    
    pause_menu.time = pause_menu.time + dt
    pause_menu.title_scale = 1 + 0.05 * math.sin(pause_menu.time * 2)
    
    -- Update background effect
    background_effect.update(dt)
    
    local mx, my = love.mouse.getPosition()
    for _, b in ipairs(buttons) do
        local b = b._bounds
        if b then
            b.hover = mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h
        end
    end
    
    settings.update(dt)
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

    -- Adjust button sizes for touch on iOS
    if love.system.getOS() == "iOS" then
        buttonH = 70
        spacing = 80
    end

    for i, b in ipairs(buttons) do
        local by = startY + (i-1) * spacing
        local bx, bw = x + 50, w - 100
        b._bounds = { x = bx, y = by, w = bw, h = buttonH }

        -- Button background with hover effect
        local hover_scale = b._bounds.hover and 1.1 or 1
        local hover_color = b._bounds.hover and {0.4, 0.4, 0.4} or {0.2, 0.2, 0.2}
        
        love.graphics.push()
        love.graphics.translate(bx + bw/2, by + buttonH/2)
        love.graphics.scale(hover_scale, hover_scale)
        love.graphics.translate(-bw/2, -buttonH/2)
        
        -- Draw button background with rounded corners
        love.graphics.setColor(hover_color[1], hover_color[2], hover_color[3])
        love.graphics.rectangle("fill", 0, 0, bw, buttonH, 10, 10)
        
        -- Draw button border
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("line", 0, 0, bw, buttonH, 10, 10)
        
        -- Draw button text
        love.graphics.setColor(1, 1, 1)
        local textW = assets.fonts.bold:getWidth(b.text)
        local textH = assets.fonts.bold:getHeight()
        love.graphics.print(b.text, (bw - textW) / 2, (buttonH - textH) / 2)
        
        love.graphics.pop()
    end

    -- Draw settings if visible
    settings.draw()
end

function pause_menu.mousepressed(mx, my, button)
    if not pause_menu.visible or button ~= 1 then return end

    if settings.visible then
        settings.mousepressed(mx, my, button)
        return
    end

    for _, b in ipairs(buttons) do
        local bounds = b._bounds
        if mx >= bounds.x and mx <= bounds.x + bounds.w and my >= bounds.y and my <= bounds.y + bounds.h then
            b.action()
            return
        end
    end
end

return pause_menu 