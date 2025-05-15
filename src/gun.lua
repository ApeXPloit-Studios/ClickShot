local assets = require("assets")
local scene = require("scene")
local scale_manager = require("scale_manager")

local gun = {}

-- Constants
local DEFAULT_X = scale_manager.design_width / 2
local DEFAULT_Y = scale_manager.design_height / 2.4
local TOTAL_FRAMES = 12
local BASE_SCALE = 4.0  -- Increased from 2.5 to 4.0 for larger gun
local MIN_FRAME_TIME = 1 / 30  -- Increased from 24 to 30 for smoother animation
local MAX_FRAME_TIME = 1 / 8   -- Increased from 6 to 8 for better timing
local CLICK_COOLDOWN = 0.5
local CLICK_HISTORY_DURATION = 1

-- Sprite position
local x, y = DEFAULT_X, DEFAULT_Y

-- Sprite
local sprite
local quads = {}
local frame = 1
local timer = 0
local gun_width, gun_height

-- Click timing
local click_times = {}
local last_click_time = 0
local animating = false

-- Hitbox adjustment (percentage of sprite size)
local hitbox = {
    width_percent = 0.9,  -- Increased from 0.8 to 0.9 for better clickability
    height_percent = 0.95,  -- Increased from 0.9 to 0.95 for better clickability
    x_offset_percent = 0,  -- Center horizontally
    y_offset_percent = 0   -- Center vertically
}

function gun.load()
    -- Load default pistol sprite
    local default_sprite = love.graphics.newImage("assets/images/pistol/fire_pistol.png")
    default_sprite:setFilter("nearest", "nearest")
    gun.setSprite(default_sprite)
end

function gun.update(dt)
    if not sprite then return end  -- Don't update if no sprite is set

    local now = love.timer.getTime()

    -- Remove old clicks
    for i = #click_times, 1, -1 do
        if now - click_times[i] > CLICK_HISTORY_DURATION then
            table.remove(click_times, i)
        end
    end

    local cps = math.min(#click_times, 2)
    if cps == 0 then
        animating = false
        frame = 1
        return
    end

    -- Faster animation based on click speed
    local frame_duration = MAX_FRAME_TIME - ((MAX_FRAME_TIME - MIN_FRAME_TIME) * (cps / 2))

    if animating then
        timer = timer + dt
        if timer >= frame_duration then
            timer = 0
            frame = frame + 1
            if frame > TOTAL_FRAMES then
                frame = 1
            end
        end
    end
end

function gun.draw()
    if not sprite then return end  -- Don't draw if no sprite is set

    -- Draw gun sprite
    love.graphics.draw(
        sprite,
        quads[frame],
        x - (gun_width * BASE_SCALE) / 2,
        y - (gun_height * BASE_SCALE) / 2,
        0, -- no rotation
        BASE_SCALE, BASE_SCALE
    )
end

-- Draw hitbox for debugging
function gun.drawHitbox()
    if not sprite then return end
    
    local hitbox_width = gun_width * BASE_SCALE * hitbox.width_percent
    local hitbox_height = gun_height * BASE_SCALE * hitbox.height_percent
    local hitbox_x = x - (hitbox_width / 2) + (gun_width * BASE_SCALE * hitbox.x_offset_percent)
    local hitbox_y = y - (hitbox_height / 2) + (gun_height * BASE_SCALE * hitbox.y_offset_percent)
    
    love.graphics.setColor(1, 0, 0, 0.5)
    love.graphics.rectangle("fill", hitbox_x, hitbox_y, hitbox_width, hitbox_height)
    love.graphics.setColor(1, 1, 1, 1)
end

function gun.isClicked(mx, my)
    if not sprite then return false end  -- Don't process clicks if no sprite is set

    -- Calculate actual hitbox dimensions
    local hitbox_width = gun_width * BASE_SCALE * hitbox.width_percent
    local hitbox_height = gun_height * BASE_SCALE * hitbox.height_percent
    
    -- Calculate hitbox position with offset
    local hitbox_x = x - (hitbox_width / 2) + (gun_width * BASE_SCALE * hitbox.x_offset_percent)
    local hitbox_y = y - (hitbox_height / 2) + (gun_height * BASE_SCALE * hitbox.y_offset_percent)

    -- Check if mouse is within hitbox bounds
    return mx >= hitbox_x and mx <= hitbox_x + hitbox_width and 
           my >= hitbox_y and my <= hitbox_y + hitbox_height
end

function gun.shoot()
    if not sprite then return false end  -- Don't shoot if no sprite is set

    local now = love.timer.getTime()
    if now - last_click_time < CLICK_COOLDOWN then
        return false
    end

    last_click_time = now
    table.insert(click_times, now)

    animating = true
    
    -- Play the click sound with the correct volume
    local click = assets.sounds.click
    if click then
        scene.playSound(click)
    end
    
    return true
end

function gun.setSprite(newSprite)
    if not newSprite then return end  -- Don't set if no sprite provided
    
    sprite = newSprite
    -- rebuild quads
    quads = {}
    local frame_width = sprite:getWidth() / TOTAL_FRAMES
    local frame_height = sprite:getHeight()
    gun_width = frame_width
    gun_height = frame_height
    for i = 0, TOTAL_FRAMES - 1 do
        table.insert(quads, love.graphics.newQuad(i * frame_width, 0, frame_width, frame_height, sprite:getDimensions()))
    end
end

function gun.getPosition()
    return x
end

function gun.setPosition(newX)
    x = newX
end

return gun
