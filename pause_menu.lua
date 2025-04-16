local assets = require("assets")
local scene = require("scene")
local settings = require("settings")
local save = require("save")
local shop = require("shop")

local pause_menu = {}
pause_menu.visible = false

local buttons = {
    { text = "Resume", action = function() pause_menu.visible = false end },
    { text = "Settings", action = function() settings.toggle() end },
    { text = "Main Menu", action = function() 
        pause_menu.visible = false
        save.update(require("game").shells, shop.cosmetics)
        scene.set("menu")
    end },
    { text = "Exit", action = function() 
        save.update(require("game").shells, shop.cosmetics)
        love.event.quit() 
    end }
}

function pause_menu.toggle()
    pause_menu.visible = not pause_menu.visible
    if not pause_menu.visible then
        settings.visible = false
    end
end

function pause_menu.update(dt)
    if not pause_menu.visible then return end
    
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

    -- Draw semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Draw menu
    local w, h = 400, 300
    local x, y = (love.graphics.getWidth() - w) / 2, (love.graphics.getHeight() - h) / 2

    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", x, y, w, h, 10, 10)

    love.graphics.setFont(assets.fonts.bold)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Paused", x, y + 10, w, "center")

    local spacing = 60
    local startY = y + 50
    local buttonH = 50

    for i, b in ipairs(buttons) do
        local by = startY + (i-1) * spacing
        local bx, bw = x + 50, w - 100
        b._bounds = { x = bx, y = by, w = bw, h = buttonH }

        love.graphics.setColor(b._bounds.hover and {0.3, 0.3, 0.3} or {0.2, 0.2, 0.2})
        love.graphics.rectangle("fill", bx, by, bw, buttonH, 6, 6)

        love.graphics.setColor(1, 1, 1)
        local textW = assets.fonts.bold:getWidth(b.text)
        local textH = assets.fonts.bold:getHeight()
        love.graphics.print(b.text, bx + (bw - textW) / 2, by + (buttonH - textH) / 2)
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