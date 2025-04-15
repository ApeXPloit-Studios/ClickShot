local assets = require("assets")
local scene = require("scene")

local main_menu = {}

local buttons = {
    { text = "Play",    x = 0, y = 0, w = 200, h = 50, hover = false, action = function() scene.set("game") end },
    { text = "Exit",    x = 0, y = 0, w = 200, h = 50, hover = false, action = function() love.event.quit() end }
}

function main_menu.load()
    local screenW, screenH = love.graphics.getDimensions()
    local spacing = 20
    for i, b in ipairs(buttons) do
        b.x = (screenW - b.w) / 2
        b.y = (screenH / 2 - (#buttons * (b.h + spacing)) / 2) + ((i - 1) * (b.h + spacing))
    end
end

function main_menu.update(dt)
    local mx, my = love.mouse.getPosition()
    for _, b in ipairs(buttons) do
        b.hover = mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h
    end
end

function main_menu.draw()
    love.graphics.clear(0.2, 0.2, 0.2)
    love.graphics.setFont(assets.fonts.bold)

    -- Title
    local title = "ClickShot"
    local tw = assets.fonts.bold:getWidth(title)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(title, (love.graphics.getWidth() - tw) / 2, 100)

    -- Buttons
    for _, b in ipairs(buttons) do
        if b.hover then
            love.graphics.setColor(0.3, 0.3, 0.3) -- hover color
        else
            love.graphics.setColor(0.1, 0.1, 0.1)
        end

        love.graphics.rectangle("fill", b.x, b.y, b.w, b.h, 8, 8)
        love.graphics.setColor(1, 1, 1)
        local textW = assets.fonts.bold:getWidth(b.text)
        local textH = assets.fonts.bold:getHeight()
        love.graphics.print(b.text, b.x + (b.w - textW) / 2, b.y + (b.h - textH) / 2)
    end
end

function main_menu.mousepressed(x, y, button)
    if button == 1 then
        for _, b in ipairs(buttons) do
            if b.hover then
                b.action()
                return
            end
        end
    end
end

return main_menu
