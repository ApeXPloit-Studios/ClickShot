local assets = require("assets")
local gun = require("gun")
local shop = require("shop")
local workbench = require("workbench")
local save = require("save")
local upgrades = require("upgrades")
local pause_menu = require("pause_menu")
local background = require("background")
local game_background = require("game_background")
local scene = require("scene")
local settings = require("settings")

-- Constants
local GAME_WIDTH = 1000
local UPGRADES_PANEL_WIDTH = 280
local BUTTON_WIDTH = 150
local BUTTON_HEIGHT = 40
local BUTTON_SPACING = 20
local UPGRADE_HEIGHT = 80
local UPGRADE_SPACING = 20

local game = {
    debug = false,
    shop_visible = false,
    workbench_visible = false,
    gamepad = nil,
    selected_button = 1,  -- 1 = gun, 2 = shop, 3 = workbench
    button_cooldown = 0,
    hover_effect = 0,
    buttons = {
        shop = { text = "Shop", hover = false },
        workbench = { text = "Workbench", hover = false }
    }
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
    
    -- Load workbench data
    workbench.load()
    
    -- Initialize all upgrades to 0 first
    for _, upgrade in ipairs(upgrades.list) do
        upgrade.count = 0
    end
    
    -- Load upgrades if they exist in save data
    if saved.upgrades then
        for i, upgrade in ipairs(upgrades.list) do
            if saved.upgrades[i] and saved.upgrades[i].count then
                local count = tonumber(saved.upgrades[i].count) or 0
                -- Clamp to [0, 100000] to prevent corruption
                count = math.max(0, math.min(100000, math.floor(count)))
                upgrade.count = count
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

-- Helper function to save game state
local function saveGameState()
    save.update(
        game.shells, 
        shop.cosmetics,
        workbench.equipped,
        workbench.equipped_weapon
    )
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

    -- Update button hover states
    local mx, my = love.mouse.getPosition()
    for _, button in pairs(game.buttons) do
        if button._bounds then
            local was_hover = button.hover
            button.hover = mx >= button._bounds.x and mx <= button._bounds.x + button._bounds.w and
                          my >= button._bounds.y and my <= button._bounds.y + button._bounds.h
            
            -- Could add hover sound here
            if button.hover and not was_hover then
                -- love.audio.play(assets.sounds.hover)
            end
        end
    end

    -- Check for gamepad input
    if game.gamepad then
        -- A button or right trigger to shoot
        if game.gamepad:isGamepadDown("a") or game.gamepad:getAxis(5) > 0.5 then
            local clicked = gun.shoot()
            if clicked then
                game.shells = game.shells + 1
                saveGameState()
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
            saveGameState()
        end

        -- A button to select current option
        if game.gamepad:isGamepadDown("a") then
            if game.selected_button == 2 then
                game.toggle_shop()
                saveGameState()
            elseif game.selected_button == 3 then
                game.toggle_workbench()
                saveGameState()
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

-- Helper function to draw a button
local function drawButton(button, x, y, width, height)
    local buttonScale = 1 + (button.hover and math.sin(game.hover_effect) * 0.1 or 0)
    
    love.graphics.push()
    love.graphics.translate(x + width/2, y + height/2)
    love.graphics.scale(buttonScale, buttonScale)
    love.graphics.translate(-width/2, -height/2)
    
    -- Draw button glow when hovered
    if button.hover then
        for i = 1, 3 do
            local glow_alpha = 0.1 - (i * 0.03)
            love.graphics.setColor(0.5, 0.5, 1, glow_alpha)
            love.graphics.rectangle("fill", -i*2, -i*2, width + i*4, height + i*4, 10 + i, 10 + i)
        end
    end
    
    love.graphics.setColor(button.hover and {0.4, 0.4, 0.4} or {0.2, 0.2, 0.2})
    love.graphics.rectangle("fill", 0, 0, width, height, 6, 6)
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("line", 0, 0, width, height, 6, 6)
    
    -- Draw text with shadow when hovered
    if button.hover then
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.printf(button.text, 2, 12, width, "center")
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(button.text, 0, 10, width, "center")
    love.graphics.pop()
end

function game.draw()
    -- Draw game area (slightly smaller to accommodate upgrades panel)
    love.graphics.setScissor(0, 0, GAME_WIDTH, 720)
    
    -- Draw backgrounds
    game_background.draw()
    background.draw()
    
    -- Draw shell count
    love.graphics.setFont(assets.fonts.bold)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Shells: " .. math.floor(game.shells), 20, 20)
    
    -- Center the gun
    local oldX = gun.getPosition()
    gun.setPosition(GAME_WIDTH / 2)
    gun.draw()
    if game.debug then
        gun.drawHitbox()
    end
    gun.setPosition(oldX)
    
    -- Draw menu buttons at bottom
    local buttonY = 720 - BUTTON_HEIGHT - 20  -- 20px padding from bottom
    local totalButtonWidth = (BUTTON_WIDTH * 2) + BUTTON_SPACING
    local startX = (GAME_WIDTH - totalButtonWidth) / 2

    -- Store button bounds for click detection
    game.buttons.shop._bounds = {
        x = startX,
        y = buttonY,
        w = BUTTON_WIDTH,
        h = BUTTON_HEIGHT
    }
    game.buttons.workbench._bounds = {
        x = startX + BUTTON_WIDTH + BUTTON_SPACING,
        y = buttonY,
        w = BUTTON_WIDTH,
        h = BUTTON_HEIGHT
    }

    -- Draw shop button
    drawButton(
        game.buttons.shop, 
        startX, 
        buttonY, 
        BUTTON_WIDTH, 
        BUTTON_HEIGHT
    )

    -- Draw workbench button
    drawButton(
        game.buttons.workbench, 
        startX + BUTTON_WIDTH + BUTTON_SPACING, 
        buttonY, 
        BUTTON_WIDTH, 
        BUTTON_HEIGHT
    )
    
    love.graphics.setScissor()
    
    -- Draw upgrades panel (always visible)
    local panelX = 1280 - UPGRADES_PANEL_WIDTH
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", panelX, 0, UPGRADES_PANEL_WIDTH, 720)
    
    -- Draw upgrades title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(assets.fonts.bold)
    love.graphics.printf("Upgrades", panelX, 20, UPGRADES_PANEL_WIDTH, "center")
    
    -- Draw upgrades
    local startY = 80
    
    for i, upgrade in ipairs(upgrades.list) do
        local y = startY + (i-1) * (UPGRADE_HEIGHT + UPGRADE_SPACING)
        local x = panelX + 10
        local width = UPGRADES_PANEL_WIDTH - 20
        
        -- Draw upgrade background
        local isSelected = i == upgrades.selected_index
        love.graphics.setColor(isSelected and {0.4, 0.4, 0.4} or {0.2, 0.2, 0.2})
        love.graphics.rectangle("fill", x, y, width, UPGRADE_HEIGHT, 6, 6)
        
        -- Draw upgrade name
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(upgrade.name, x + 10, y + 10)
        
        -- Draw count
        local countStr = tostring(upgrade.count)
        local countW = assets.fonts.bold:getWidth(countStr)
        love.graphics.print(countStr, x + width - countW - 10, y + 10)
        
        -- Draw cost
        love.graphics.setColor(1, 1, 0)
        love.graphics.print(upgrade:getNextCost() .. " shells", x + 10, y + 45)
        
        -- Store bounds for click detection
        upgrade._bounds = { x = x, y = y, w = width, h = UPGRADE_HEIGHT }
    end
    
    shop.draw(game)
    workbench.draw(game)
    pause_menu.draw()
end

function game.toggle_shop()
    if game.shop_visible then
        game.shop_visible = false
    else
        game.shop_visible = true
        game.workbench_visible = false
    end
end

function game.toggle_workbench()
    if game.workbench_visible then
        game.workbench_visible = false
    else
        game.workbench_visible = true
        game.shop_visible = false
    end
end

function game.keypressed(key)
    if key == "escape" then 
        pause_menu.toggle()
        saveGameState()
    end
    if key == "q" then 
        game.toggle_shop()
        saveGameState()
    end
    if key == "e" then 
        game.toggle_workbench()
        saveGameState()
    end
    if key == "f3" then game.debug = not game.debug end
end

function game.mousepressed(x, y, button)
    if pause_menu.visible then
        pause_menu.mousepressed(x, y, button)
        return
    end

    -- Check upgrades panel clicks first
    if x >= love.graphics.getWidth() - UPGRADES_PANEL_WIDTH then
        upgrades.mousepressed(x, y, button, game)
        saveGameState()
        return
    end

    -- Check button clicks
    if button == 1 then
        if game.buttons.shop.hover then
            -- Play click sound with correct volume
            local click = assets.sounds.click
            if click then
                local sound_instance = click:clone()
                scene.applySfxVolume(sound_instance)
                sound_instance:play()
            end
            
            game.toggle_shop()
            return
        elseif game.buttons.workbench.hover then
            -- Play click sound with correct volume
            local click = assets.sounds.click
            if click then
                local sound_instance = click:clone()
                scene.applySfxVolume(sound_instance)
                sound_instance:play()
            end
            
            game.toggle_workbench()
            return
        end
    end

    -- If a menu is open, still allow its mousepressed handler
    if game.shop_visible then
        shop.mousepressed(x, y, button, game)
        saveGameState()
        return
    elseif game.workbench_visible then
        workbench.mousepressed(x, y, button, game)
        saveGameState()
        return
    end

    -- Check gun clicks last, and only if we're in the game area
    if button == 1 and x < love.graphics.getWidth() - UPGRADES_PANEL_WIDTH then
        if gun.isClicked(x, y) then
            local clicked = gun.shoot()
            if clicked then
                game.shells = game.shells + 1
                saveGameState()
            end
        end
    end
end

return game
