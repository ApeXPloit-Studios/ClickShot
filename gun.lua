local assets = require("assets")

local gun = {}
local x, y = 400, 300

-- Sprite sheet
local sprite
local quads = {}
local total_frames = 12
local frame = 1
local timer = 0
local gun_width, gun_height

-- Click tracking
local click_times = {}
local click_cooldown = 0.5 -- Max 2 clicks per second
local min_frame_time = 1 / 24
local max_frame_time = 1 / 6 -- slowest animation (normal click speed)

-- State
local animating = false

function gun.load()
    sprite = assets.images.gun

    local frame_width = sprite:getWidth() / total_frames
    local frame_height = sprite:getHeight()
    gun_width = frame_width
    gun_height = frame_height

    -- Build animation quads
    for i = 0, total_frames - 1 do
        table.insert(quads, love.graphics.newQuad(i * frame_width, 0, frame_width, frame_height, sprite:getDimensions()))
    end
end

function gun.update(dt)
    -- Purge old click times (>1s ago)
    local now = love.timer.getTime()
    for i = #click_times, 1, -1 do
        if now - click_times[i] > 1 then
            table.remove(click_times, i)
        end
    end

    local cps = math.min(#click_times, 2) -- cap at 2 CPS (1 click per 0.5 sec)
    if cps == 0 then
        animating = false
        frame = 1
        return
    end

    local frame_duration = max_frame_time - ((max_frame_time - min_frame_time) * (cps / 2))

    if animating then
        timer = timer + dt
        if timer >= frame_duration then
            timer = 0
            frame = frame + 1
            if frame > total_frames then
                frame = 1
            end
        end
    end
end

function gun.draw()
    love.graphics.draw(sprite, quads[frame], x - gun_width / 2, y - gun_height / 2)
end

function gun.isClicked(mx, my)
    return mx >= x - gun_width / 2 and mx <= x + gun_width / 2 and
           my >= y - gun_height / 2 and my <= y + gun_height / 2
end

function gun.shoot()
    local now = love.timer.getTime()
    local last_click = click_times[#click_times] or 0
    if now - last_click >= click_cooldown then
        return false
    end

    table.insert(click_times, now)
    animating = true
    love.audio.play(assets.sounds.click)
    return true
end

return gun
