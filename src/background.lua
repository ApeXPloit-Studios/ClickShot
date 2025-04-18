local background = {}

-- Configuration
local particles = {}
local max_particles = 50
local particle_size = 4
local mouse_radius = 150
local base_color = {0.1, 0.2, 0.9}  -- Your current background color
local highlight_color = {0.2, 0.3, 1.0}

-- Initialize particles
function background.load()
    for i = 1, max_particles do
        particles[i] = {
            x = love.math.random(0, love.graphics.getWidth()),
            y = love.math.random(0, love.graphics.getHeight()),
            vx = love.math.random(-20, 20) / 10,
            vy = love.math.random(-20, 20) / 10,
            size = love.math.random(2, 6),
            alpha = love.math.random(0.3, 0.7)
        }
    end
end

function background.update(dt)
    local mx, my = love.mouse.getPosition()
    
    for i, p in ipairs(particles) do
        -- Update position
        p.x = p.x + p.vx
        p.y = p.y + p.vy
        
        -- Bounce off edges
        if p.x < 0 or p.x > love.graphics.getWidth() then
            p.vx = -p.vx
        end
        if p.y < 0 or p.y > love.graphics.getHeight() then
            p.vy = -p.vy
        end
        
        -- Mouse interaction
        local dx = mx - p.x
        local dy = my - p.y
        local dist = math.sqrt(dx * dx + dy * dy)
        
        if dist < mouse_radius then
            -- Push particles away from mouse
            local angle = math.atan2(dy, dx)
            local force = (mouse_radius - dist) / mouse_radius
            p.vx = p.vx - math.cos(angle) * force * 2
            p.vy = p.vy - math.sin(angle) * force * 2
        end
        
        -- Dampen velocity
        p.vx = p.vx * 0.98
        p.vy = p.vy * 0.98
    end
end

function background.draw()
    local mx, my = love.mouse.getPosition()
    
    -- Draw gradient background
    local gradient = love.graphics.newMesh(2, "strip", "static")
    gradient:setVertex(1, 0, 0, base_color[1], base_color[2], base_color[3], 1)
    gradient:setVertex(2, love.graphics.getWidth(), love.graphics.getHeight(), 
        highlight_color[1], highlight_color[2], highlight_color[3], 1)
    love.graphics.draw(gradient)
    
    -- Draw particles
    for _, p in ipairs(particles) do
        local dx = mx - p.x
        local dy = my - p.y
        local dist = math.sqrt(dx * dx + dy * dy)
        
        -- Calculate color based on distance from mouse
        local r, g, b
        if dist < mouse_radius then
            local t = dist / mouse_radius
            r = base_color[1] + (highlight_color[1] - base_color[1]) * (1 - t)
            g = base_color[2] + (highlight_color[2] - base_color[2]) * (1 - t)
            b = base_color[3] + (highlight_color[3] - base_color[3]) * (1 - t)
        else
            r, g, b = base_color[1], base_color[2], base_color[3]
        end
        
        love.graphics.setColor(r, g, b, p.alpha)
        love.graphics.circle("fill", p.x, p.y, p.size)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

return background 