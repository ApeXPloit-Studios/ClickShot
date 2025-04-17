local assets = require("assets")
local settings = {}

settings.visible = false
settings.data = {
    sound = { value = true, hover = false },
    fullscreen = { value = false, hover = false },
    music = { value = true, hover = false }
}

function settings.toggle()
    settings.visible = not settings.visible
end

function settings.update(dt)
    if not settings.visible then return end
    local mx, my = love.mouse.getPosition()
    for _, v in pairs(settings.data) do
        local b = v._bounds
        if b then
            v.hover = mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h
        end
    end
end

function settings.draw()
    if not settings.visible then return end

    local w, h = 400, 300
    local x, y = (love.graphics.getWidth() - w) / 2, (love.graphics.getHeight() - h) / 2

    -- Draw background
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", x, y, w, h, 10, 10)

    -- Draw title
    love.graphics.setFont(assets.fonts.bold)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Settings", x, y + 10, w, "center")

    -- Draw settings
    local spacing = 60
    local startY = y + 50
    local i = 0

    for k, v in pairs(settings.data) do
        local label = k:sub(1,1):upper() .. k:sub(2)
        local state = v.value and "On" or "Off"
        local bx, by, bw, bh = x + 50, startY + i * spacing, 300, 40

        love.graphics.setColor(v.hover and {0.3, 0.3, 0.3} or {0.2, 0.2, 0.2})
        love.graphics.rectangle("fill", bx, by, bw, bh, 6, 6)

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(label .. ": " .. state, bx, by + 10, bw, "center")

        v._bounds = { x = bx, y = by, w = bw, h = bh }
        i = i + 1
    end
end

function settings.mousepressed(mx, my, button)
    if not settings.visible or button ~= 1 then return end

    for k, v in pairs(settings.data) do
        local b = v._bounds
        if mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h then
            v.value = not v.value
            -- Apply settings
            if k == "fullscreen" then
                love.window.setFullscreen(v.value)
            elseif k == "sound" then
                love.audio.setVolume(v.value and 1 or 0)
            end
        end
    end
end

return settings 