local assets = require("assets")
local gun = require("gun")
local shop = require("shop")
local workbench = require("workbench")
local save = require("save")
local upgrades = require("upgrades")
local pause_menu = require("pause_menu")
local background = require("background")
local game_background = require("game_background")

local game = {
    debug = false,
    shop_visible = false,
    workbench_visible = false,
    gamepad = nil,
    selected_button = 1,  -- 1 = gun, 2 = shop, 3 = workbench
    button_cooldown = 0,
    hover_effect = 0
}
game.shells = 0
game.auto_cps = 0

function game.load()
    assets.load()
    gun.load()
    background.load()
    game_background.load()
    
    -- Load saved data
    local saved = save.load()
    game.shells = saved.shells
    shop.cosmetics = saved.cosmetics
    
    -- Load upgrades if they exist in save data
    if saved.upgrades then
        for i, upgrade in ipairs(upgrades.list) do
            if saved.upgrades[i] then
                upgrade.count = saved.upgrades[i].count
                upgrade:effect(game)  -- Apply the upgrade effect
            end
        end
    end

    -- Initialize gamepad
    local joysticks = love.joystick.getJoysticks()
    if #joysticks > 0 then
        game.gamepad = joysticks[1]
    end
end

function game.update(dt)
    if pause_menu.visible then
        pause_menu.update(dt)
        return
    end

    -- Update button cooldown
    if game.button_cooldown > 0 then
        game.button_cooldown = game.button_cooldown - dt
    end

    -- Update hover effect
    game.hover_effect = game.hover_effect + dt * 2
    if game.hover_effect > math.pi * 2 then
        game.hover_effect = 0
    end

    -- Check for gamepad input
    if game.gamepad then
        -- A button or right trigger to shoot
        if game.gamepad:isGamepadDown("a") or game.gamepad:getAxis(5) > 0.5 then
            local clicked = gun.shoot()
            if clicked then
                game.shells = game.shells + 1
                save.update(game.shells, shop.cosmetics)
            end
        end

        -- D-pad navigation
        if game.button_cooldown <= 0 then
            if game.gamepad:isGamepadDown("dpleft") then
                game.selected_button = game.selected_button - 1
                if game.selected_button < 1 then game.selected_button = 3 end
                game.button_cooldown = 0.2
            elseif game.gamepad:isGamepadDown("dpright") then
                game.selected_button = game.selected_button + 1
                if game.selected_button > 3 then game.selected_button = 1 end
                game.button_cooldown = 0.2
            end
        end

        -- Start button to toggle pause menu
        if game.gamepad:isGamepadDown("start") then
            pause_menu.toggle()
            save.update(game.shells, shop.cosmetics)
        end

        -- A button to select current option
        if game.gamepad:isGamepadDown("a") then
            if game.selected_button == 2 then
                game.toggle_shop()
                save.update(game.shells, shop.cosmetics)
            elseif game.selected_button == 3 then
                game.toggle_workbench()
                save.update(game.shells, shop.cosmetics)
            end
        end
    end

    gun.update(dt)
    shop.update(dt, game)
    workbench.update(dt, game)
    upgrades.update(dt, game)
    background.update(dt)
    game_background.update(dt, game.shells)
end

function game.draw()
    -- Draw game area (slightly smaller to accommodate upgrades panel)
    local gameWidth = love.graphics.getWidth() - 200  -- 200 is panel width
    love.graphics.setScissor(0, 0, gameWidth, love.graphics.getHeight())
    
    -- Draw backgrounds
    game_background.draw()
    background.draw()
    
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
    
    -- Draw menu buttons with selection indicator
    local buttonSpacing = 100
    local buttonY = love.graphics.getHeight() - 50
    local buttonX = (gameWidth - (buttonSpacing * 2)) / 2

    -- Draw shop button
    local shopHover = game.selected_button == 2
    local shopScale = 1 + (shopHover and math.sin(game.hover_effect) * 0.1 or 0)
    love.graphics.push()
    love.graphics.translate(buttonX + buttonSpacing/2, buttonY + 20)
    love.graphics.scale(shopScale, shopScale)
    love.graphics.translate(-buttonSpacing/2, -20)
    love.graphics.setColor(shopHover and {0.4, 0.4, 0.4} or {0.2, 0.2, 0.2})
    love.graphics.rectangle("fill", 0, 0, buttonSpacing, 40, 6, 6)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Shop", 0, 10, buttonSpacing, "center")
    love.graphics.pop()

    -- Draw workbench button
    local workbenchHover = game.selected_button == 3
    local workbenchScale = 1 + (workbenchHover and math.sin(game.hover_effect) * 0.1 or 0)
    love.graphics.push()
    love.graphics.translate(buttonX + buttonSpacing + buttonSpacing/2, buttonY + 20)
    love.graphics.scale(workbenchScale, workbenchScale)
    love.graphics.translate(-buttonSpacing/2, -20)
    love.graphics.setColor(workbenchHover and {0.4, 0.4, 0.4} or {0.2, 0.2, 0.2})
    love.graphics.rectangle("fill", 0, 0, buttonSpacing, 40, 6, 6)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Workbench", 0, 10, buttonSpacing, "center")
    love.graphics.pop()
    
    shop.draw(game)
    workbench.draw(game)
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

    if game.shop_visible then
        shop.mousepressed(x, y, button, game)
        save.update(game.shells, shop.cosmetics)
    elseif game.workbench_visible then
        workbench.mousepressed(x, y, button, game)
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
        game.toggle_shop()
        save.update(game.shells, shop.cosmetics)
    end
    if key == "w" then 
        game.toggle_workbench()
        save.update(game.shells, shop.cosmetics)
    end
    if key == "f3" then game.debug = not game.debug end
end

function game.toggle_shop()
    game.shop_visible = not game.shop_visible
    if game.shop_visible then
        game.workbench_visible = false
    end
end

function game.toggle_workbench()
    game.workbench_visible = not game.workbench_visible
    if game.workbench_visible then
        game.shop_visible = false
    end
end

return game
