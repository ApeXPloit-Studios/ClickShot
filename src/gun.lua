local assets = require("assets")
local scene = require("scene")
local scale_manager = require("scale_manager")
local controller = require("controller")

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

-- Power system
local current_power = 1  -- Default power value

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

function gun.isClicked(mx, my)
    if not sprite then return false end  -- Don't process clicks if no sprite is set

    -- Use controller cursor position if using controller
    local posX, posY
    if not mx or not my then
        if controller.usingController then
            posX, posY = controller.cursorX, controller.cursorY
        else
            posX, posY = scale_manager.getMousePosition()
        end
    else
        posX, posY = mx, my
    end

    -- Get the gun draw position
    local draw_x = x - (gun_width * BASE_SCALE) / 2
    local draw_y = y - (gun_height * BASE_SCALE) / 2
    
    -- Calculate hitbox dimensions based on the full sprite size
    local hitbox_width = gun_width * BASE_SCALE
    local hitbox_height = gun_height * BASE_SCALE
    
    -- Add a generous margin to make clicking easier
    local margin = 20

    -- Check if mouse is within extended hitbox bounds
    return posX >= (draw_x - margin) and posX <= (draw_x + hitbox_width + margin) and 
           posY >= (draw_y - margin) and posY <= (draw_y + hitbox_height + margin)
end

function gun.shoot()
    if not sprite then return false, 0 end  -- Don't shoot if no sprite is set

    local now = love.timer.getTime()
    if now - last_click_time < CLICK_COOLDOWN then
        return false, 0
    end

    last_click_time = now
    table.insert(click_times, now)

    animating = true
    
    -- Play the click sound with the correct volume
    local click = assets.sounds.click
    if click then
        scene.playSound(click)
    end
    
    -- Use the current power value to determine shells earned
    local shells_earned = math.max(1, math.floor(current_power))
    
    return true, shells_earned
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

-- Set the current power value (called from workbench)
function gun.setPower(power)
    current_power = power
end

-- Get the current power value
function gun.getPower()
    return current_power
end

return gun
