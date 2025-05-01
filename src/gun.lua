local assets = require("assets")

local gun = {}
local x, y = 400, 300

-- Sprite
local sprite
local quads = {}
local total_frames = 12
local frame = 1
local timer = 0
local gun_width, gun_height

-- Scale
local scale = 2.5

-- Click timing
local click_times = {}
local click_cooldown = 0.5
local last_click_time = 0
local animating = false

-- Hitbox adjustment (percentage of sprite size)
local hitbox = {
    width_percent = 0.8,  -- Increased from 0.6 to 0.8 for better clickability
    height_percent = 0.9,  -- Increased from 0.8 to 0.9 for better clickability
    x_offset_percent = 0,  -- Center horizontally
    y_offset_percent = 0   -- Removed vertical offset for more intuitive clicking
}

function gun.load()
    sprite = assets.images.gun

    local frame_width = sprite:getWidth() / total_frames
    local frame_height = sprite:getHeight()
    gun_width = frame_width
    gun_height = frame_height

    for i = 0, total_frames - 1 do
        table.insert(quads, love.graphics.newQuad(i * frame_width, 0, frame_width, frame_height, sprite:getDimensions()))
    end
end

function gun.update(dt)
    local now = love.timer.getTime()

    -- Remove old clicks
    for i = #click_times, 1, -1 do
        if now - click_times[i] > 1 then
            table.remove(click_times, i)
        end
    end

    local cps = math.min(#click_times, 2)
    if cps == 0 then
        animating = false
        frame = 1
        return
    end

    local min_frame_time = 1 / 24
    local max_frame_time = 1 / 6
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
    love.graphics.draw(
        sprite,
        quads[frame],
        x - (gun_width * scale) / 2,
        y - (gun_height * scale) / 2,
        0, -- no rotation
        scale, scale
    )
end

function gun.isClicked(mx, my)
    -- Get current window dimensions
    local gameWidth = love.graphics.getWidth()
    
    -- Calculate actual hitbox dimensions
    local hitbox_width = gun_width * scale * hitbox.width_percent
    local hitbox_height = gun_height * scale * hitbox.height_percent
    
    -- Calculate hitbox position with offset
    -- Note: x is now centered in the game area (gameWidth/2)
    local hitbox_x = x - (hitbox_width / 2) + (gun_width * scale * hitbox.x_offset_percent)
    local hitbox_y = y - (hitbox_height / 2) + (gun_height * scale * hitbox.y_offset_percent)

    -- Debug print for troubleshooting
    if love.keyboard.isDown('f3') then
        print(string.format("Mouse: (%d, %d), Hitbox: (%d, %d, %d, %d)", 
            mx, my, hitbox_x, hitbox_y, hitbox_width, hitbox_height))
    end

    -- Check if mouse is within hitbox bounds
    return mx >= hitbox_x and mx <= hitbox_x + hitbox_width and 
           my >= hitbox_y and my <= hitbox_y + hitbox_height
end

function gun.shoot()
    local now = love.timer.getTime()
    if now - last_click_time < click_cooldown then
        return false
    end

    last_click_time = now
    table.insert(click_times, now)

    animating = true
    love.audio.play(assets.sounds.click)
    return true
end

function gun.setSprite(newSprite)
    sprite = newSprite
    -- rebuild quads
    quads = {}
    local frame_width = sprite:getWidth() / total_frames
    local frame_height = sprite:getHeight()
    gun_width = frame_width
    gun_height = frame_height
    for i = 0, total_frames - 1 do
        table.insert(quads, love.graphics.newQuad(i * frame_width, 0, frame_width, frame_height, sprite:getDimensions()))
    end
end

function gun.getPosition()
    return x
end

function gun.setPosition(newX)
    x = newX
end

-- Debug function to visualize hitbox
function gun.drawHitbox()
    -- Calculate hitbox dimensions
    local hitbox_width = gun_width * scale * hitbox.width_percent
    local hitbox_height = gun_height * scale * hitbox.height_percent
    
    -- Calculate hitbox position with offset
    local hitbox_x = x - (hitbox_width / 2) + (gun_width * scale * hitbox.x_offset_percent)
    local hitbox_y = y - (hitbox_height / 2) + (gun_height * scale * hitbox.y_offset_percent)

    -- Draw the hitbox
    love.graphics.setColor(1, 0, 0, 0.5)
    love.graphics.rectangle("fill", 
        hitbox_x,
        hitbox_y,
        hitbox_width,
        hitbox_height
    )
    
    -- Draw the center point
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.circle("fill", x, y, 3)
    
    love.graphics.setColor(1, 1, 1, 1)
end

return gun
