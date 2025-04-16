local assets = require("assets")
local gun = require("gun")
local shop = require("shop")
local workbench = require("workbench")
local save = require("save")
local upgrades = require("upgrades")
local pause_menu = require("pause_menu")

local game = {}
game.shells = 0
game.auto_cps = 0
game.debug = false  -- Debug mode flag

function game.load()
    assets.load()
    gun.load()
    
    -- Load saved data
    local saved = save.load()
    game.shells = saved.shells
    shop.cosmetics = saved.cosmetics
end

function game.update(dt)
    if pause_menu.visible then
        pause_menu.update(dt)
        return
    end

    gun.update(dt)
    shop.update(dt)
    workbench.update(dt)
    upgrades.update(dt, game)
end

function game.draw()
    -- Draw game area (slightly smaller to accommodate upgrades panel)
    local gameWidth = love.graphics.getWidth() - 200  -- 200 is panel width
    love.graphics.setScissor(0, 0, gameWidth, love.graphics.getHeight())
    
    love.graphics.clear(0.1, 0.2, 0.9)
    love.graphics.setFont(assets.fonts.bold)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Shells: " .. math.floor(game.shells), 20, 20)
    
    -- Center the gun in the remaining space
    local oldX = gun.getPosition()
    gun.setPosition(gameWidth / 2)
    gun.draw()
    if game.debug then
        gun.drawHitbox()
    end
    gun.setPosition(oldX)
    
    shop.draw()
    workbench.draw()
    pause_menu.draw()
    
    love.graphics.setScissor()
    
    -- Draw upgrades panel (always visible)
    upgrades.draw()
end

function game.mousepressed(x, y, button)
    if pause_menu.visible then
        pause_menu.mousepressed(x, y, button)
        return
    end

    if shop.visible then
        shop.mousepressed(x, y, button, game)
        save.update(game.shells, shop.cosmetics)
    elseif workbench.visible then
        workbench.mousepressed(x, y, button)
        save.update(game.shells, shop.cosmetics)
    else
        -- Check upgrades panel clicks first
        upgrades.mousepressed(x, y, button, game)
        save.update(game.shells, shop.cosmetics)
        
        -- Then check gun clicks if not clicking on upgrades panel
        if x < love.graphics.getWidth() - 200 then  -- 200 is panel width
            if button == 1 and gun.isClicked(x, y) then
                local clicked = gun.shoot()
                if clicked then
                    game.shells = game.shells + 1
                    save.update(game.shells, shop.cosmetics)
                end
            end
        end
    end
end

function game.keypressed(key)
    if key == "escape" then 
        pause_menu.toggle()
        save.update(game.shells, shop.cosmetics)
    end
    if key == "s" then 
        shop.toggle()
        save.update(game.shells, shop.cosmetics)
    end
    if key == "w" then 
        workbench.toggle()
        save.update(game.shells, shop.cosmetics)
    end
    if key == "f3" then game.debug = not game.debug end
end

return game
