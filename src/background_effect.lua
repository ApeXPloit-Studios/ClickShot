local scale_manager = require("scale_manager")

local background_effect = {
    particles = {},
    max_particles = 50,
    time = 0
}

function background_effect.load()
    -- Initialize particles
    for i = 1, background_effect.max_particles do
        background_effect.particles[i] = {
            x = love.math.random(0, scale_manager.design_width),
            y = love.math.random(0, scale_manager.design_height),
            size = love.math.random(2, 6),
            speed = love.math.random(20, 50),
            angle = love.math.random(0, math.pi * 2),
            color = {
                r = love.math.random(0.2, 0.4),
                g = love.math.random(0.2, 0.4),
                b = love.math.random(0.2, 0.4)
            }
        }
    end
end

function background_effect.update(dt)
    background_effect.time = background_effect.time + dt
    
    -- Update particles
    for i, p in ipairs(background_effect.particles) do
        -- Move particles
        p.x = p.x + math.cos(p.angle) * p.speed * dt
        p.y = p.y + math.sin(p.angle) * p.speed * dt
        
        -- Wrap around screen
        if p.x < 0 then p.x = scale_manager.design_width end
        if p.x > scale_manager.design_width then p.x = 0 end
        if p.y < 0 then p.y = scale_manager.design_height end
        if p.y > scale_manager.design_height then p.y = 0 end
        
        -- Change color slightly over time
        p.color.r = 0.2 + 0.2 * math.sin(background_effect.time + i)
        p.color.g = 0.2 + 0.2 * math.sin(background_effect.time + i + math.pi/3)
        p.color.b = 0.2 + 0.2 * math.sin(background_effect.time + i + math.pi*2/3)
    end
end

function background_effect.draw()
    -- Draw particles
    for _, p in ipairs(background_effect.particles) do
        love.graphics.setColor(p.color.r, p.color.g, p.color.b, 0.8)
        love.graphics.circle("fill", p.x, p.y, p.size)
    end
    
    -- Draw connecting lines between nearby particles
    for i, p1 in ipairs(background_effect.particles) do
        for j, p2 in ipairs(background_effect.particles) do
            if i < j then
                local dx = p1.x - p2.x
                local dy = p1.y - p2.y
                local dist = math.sqrt(dx*dx + dy*dy)
                
                if dist < 150 then
                    local alpha = 1 - (dist / 150)
                    love.graphics.setColor(0.3, 0.3, 0.3, alpha * 0.3)
                    love.graphics.line(p1.x, p1.y, p2.x, p2.y)
                end
            end
        end
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

return background_effect 