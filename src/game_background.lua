local scale_manager = require("scale_manager")

local game_background = {
    particles = {},
    max_particles = 30,
    time = 0,
    shells = 0
}

function game_background.load()
    -- Initialize particles
    for i = 1, game_background.max_particles do
        game_background.particles[i] = {
            x = love.math.random(0, scale_manager.design_width),
            y = love.math.random(0, scale_manager.design_height),
            size = love.math.random(3, 8),
            speed = love.math.random(10, 30),
            angle = love.math.random(0, math.pi * 2),
            color = {
                r = love.math.random(0.1, 0.3),
                g = love.math.random(0.1, 0.3),
                b = love.math.random(0.1, 0.3)
            },
            shell = love.math.random(1, 3) == 1, -- Some particles are shell-shaped
            rotation = love.math.random(0, math.pi * 2),
            rotation_speed = love.math.random(-2, 2)
        }
    end
end

function game_background.update(dt, shells)
    game_background.time = game_background.time + dt
    game_background.shells = shells
    
    -- Update particles
    for i, p in ipairs(game_background.particles) do
        -- Move particles
        p.x = p.x + math.cos(p.angle) * p.speed * dt
        p.y = p.y + math.sin(p.angle) * p.speed * dt
        
        -- Wrap around screen
        if p.x < 0 then p.x = scale_manager.design_width end
        if p.x > scale_manager.design_width then p.x = 0 end
        if p.y < 0 then p.y = scale_manager.design_height end
        if p.y > scale_manager.design_height then p.y = 0 end
        
        -- Rotate shell particles
        if p.shell then
            p.rotation = p.rotation + p.rotation_speed * dt
        end
        
        -- Change color based on shell count
        local shell_factor = math.min(shells / 1000, 1)
        p.color.r = 0.1 + 0.2 * shell_factor
        p.color.g = 0.1 + 0.2 * shell_factor
        p.color.b = 0.1 + 0.2 * shell_factor
    end
end

function game_background.draw()
    -- Draw gradient background
    local gradient = love.graphics.newMesh(2, "strip", "static")
    local shell_factor = math.min(game_background.shells / 1000, 1)
    local base_color = {0.1, 0.1, 0.2}
    local highlight_color = {
        0.1 + 0.1 * shell_factor,
        0.1 + 0.1 * shell_factor,
        0.2 + 0.1 * shell_factor
    }
    
    gradient:setVertex(1, 0, 0, base_color[1], base_color[2], base_color[3], 1)
    gradient:setVertex(2, scale_manager.design_width, scale_manager.design_height, 
        highlight_color[1], highlight_color[2], highlight_color[3], 1)
    love.graphics.draw(gradient)
    
    -- Draw particles
    for _, p in ipairs(game_background.particles) do
        love.graphics.setColor(p.color.r, p.color.g, p.color.b, 0.6)
        
        if p.shell then
            -- Draw shell-shaped particle
            love.graphics.push()
            love.graphics.translate(p.x, p.y)
            love.graphics.rotate(p.rotation)
            love.graphics.scale(p.size / 10, p.size / 10)
            
            -- Draw shell shape
            love.graphics.circle("fill", 0, 0, 5)
            love.graphics.circle("line", 0, 0, 5)
            love.graphics.circle("line", 0, 0, 3)
            
            love.graphics.pop()
        else
            -- Draw regular particle
            love.graphics.circle("fill", p.x, p.y, p.size)
        end
    end
    
    -- Draw connecting lines between nearby particles
    for i, p1 in ipairs(game_background.particles) do
        for j, p2 in ipairs(game_background.particles) do
            if i < j then
                local dx = p1.x - p2.x
                local dy = p1.y - p2.y
                local dist = math.sqrt(dx*dx + dy*dy)
                
                if dist < 200 then
                    local alpha = (1 - (dist / 200)) * 0.2
                    love.graphics.setColor(0.3, 0.3, 0.3, alpha)
                    love.graphics.line(p1.x, p1.y, p2.x, p2.y)
                end
            end
        end
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

return game_background 