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
local ui = require("ui")
local scale_manager = require("scale_manager")
local save_slot_menu = require("save_slot_menu")
local steam = require("steam")

-- Constants
local GAME_WIDTH = scale_manager.design_width - 280  -- Main game area width (minus upgrades panel)
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
    save_cooldown = 0,  -- Cooldown timer for saves
    save_interval = 2,  -- seconds after every save
    save_pending = false,  -- indicate a save is needed
    buttons = {
        shop = { text = "Shop", hover = false },
        workbench = { text = "Workbench", hover = false }
    },
    _first_shot_given = false,
    _tenk_achieved = false
}
game.shells = 0
game.auto_cps = 0

function game.load()
    assets.load()
    gun.load()
    background.load()
    game_background.load()
    save_slot_menu.load()
    
    -- Load saved data
    local saved = save.load()
    game.shells = saved.shells
    
    -- Update weapons from save data
    local weapons_module = require("weapons")
    if saved.cosmetics then
        -- Update weapon ownership and cosmetics
        for weapon_name, weapon_data in pairs(saved.cosmetics) do
            if weapons_module.data[weapon_name] then
                weapons_module.data[weapon_name].owned = weapon_data.owned or false
                
                -- Update cosmetics ownership
                if weapon_data.cosmetics then
                    for cosmetic_name, cosmetic_data in pairs(weapon_data.cosmetics) do
                        if weapons_module.data[weapon_name].cosmetics[cosmetic_name] then
                            weapons_module.data[weapon_name].cosmetics[cosmetic_name].owned = 
                                cosmetic_data.owned or false
                        end
                    end
                end
            end
        end
    end
    
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
            end
        end
    end
    
    -- Apply all upgrade effects
    upgrades.applyAllEffects(game)

    -- Initialize gamepad
    local joysticks = love.joystick.getJoysticks()
    if #joysticks > 0 then
        game.gamepad = joysticks[1]
    end
end

-- Helper function to save game state
local function saveGameState()
    game.save_pending = true
end

function game.update(dt)
    -- Check if a save was requested from the save slot menu
    if scene.isSavePending() then
    save.update(
        game.shells, 
        shop.cosmetics,
        workbench.equipped,
        workbench.equipped_weapon
    )
        scene.clearSavePending()
    end
    
    -- Check if a data reload was requested
    if scene.isDataReloadPending() then
        game.reloadSaveData()
        scene.clearDataReloadPending()
    end

    if pause_menu.visible then
        pause_menu.update(dt)
        return
    end

    if save_slot_menu.visible then
        save_slot_menu.update(dt)
        return
    end

    -- Update save cooldown and perform save if needed
    if game.save_cooldown > 0 then
        game.save_cooldown = game.save_cooldown - dt
    elseif game.save_pending then
        save.update(
            game.shells, 
            shop.cosmetics,
            workbench.equipped,
            workbench.equipped_weapon
        )
        game.save_pending = false
        game.save_cooldown = game.save_interval
    end

    -- Update button cooldown
    if game.button_cooldown > 0 then
        game.button_cooldown = game.button_cooldown - dt
    end

    -- Update button hover states
    local mx, my = scale_manager.getMousePosition()
    for _, button in pairs(game.buttons) do
        ui.updateButtonHover(button, mx, my)
    end

    -- Check for gamepad input
    if game.gamepad then
        -- A button or right trigger to shoot
        if game.gamepad:isGamepadDown("a") or game.gamepad:getAxis(5) > 0.5 then
            local clicked, shells_earned = gun.shoot()
            if clicked then
                game.shells = game.shells + shells_earned
                saveGameState()
                if not game._first_shot_given then
                    steam.setAchievement(steam.achievements.FIRST_SHOT)
                    game._first_shot_given = true
                end
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

    if game.shells >= 10000 and not game._tenk_achieved then
        steam.setAchievement(steam.achievements.TEN_THOUSAND_SHELLS)
        game._tenk_achieved = true
    end
end

function game.draw()
    -- Draw save slot menu if visible
    if save_slot_menu.visible then
        save_slot_menu.draw()
        return
    end

    -- Draw game area (slightly smaller to accommodate upgrades panel)
    local x1, y1 = scale_manager.toWindowCoords(0, 0)
    local x2, y2 = scale_manager.toWindowCoords(GAME_WIDTH, 720)
    local scissor_width = x2 - x1
    local scissor_height = y2 - y1
    
    love.graphics.setScissor(x1, y1, scissor_width, scissor_height)
    
    -- Draw backgrounds
    game_background.draw()
    background.draw()
    
    -- Draw shell count
    love.graphics.setFont(assets.fonts.bold)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Shells: " .. math.floor(game.shells), 20, 20)
    
    -- Draw current weapon power
    local power = gun.getPower() or 1
    love.graphics.print("Power: " .. power, 20, 60)
    
    -- Center the gun
    local oldX = gun.getPosition()
    gun.setPosition(GAME_WIDTH / 2)
    gun.draw()
    gun.setPosition(oldX)
    
    local totalButtonWidth = (BUTTON_WIDTH * 2) + BUTTON_SPACING
    local startX = (GAME_WIDTH - totalButtonWidth) / 2
    local buttonY = scale_manager.design_height - BUTTON_HEIGHT - 20  -- Define buttonY

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
    ui.drawButton(
        game.buttons.shop, 
        startX, 
        buttonY, 
        BUTTON_WIDTH, 
        BUTTON_HEIGHT
    )

    -- Draw workbench button
    ui.drawButton(
        game.buttons.workbench, 
        startX + BUTTON_WIDTH + BUTTON_SPACING, 
        buttonY, 
        BUTTON_WIDTH, 
        BUTTON_HEIGHT
    )
    
    love.graphics.setScissor()
    
    -- Draw upgrades panel (always visible)
    local panelX = scale_manager.design_width - UPGRADES_PANEL_WIDTH
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", panelX, 0, UPGRADES_PANEL_WIDTH, scale_manager.design_height)
    
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
end

function game.mousepressed(x, y, button)
    if save_slot_menu.visible then
        save_slot_menu.mousepressed(x, y, button)
        return
    end

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
                scene.playSound(click)
            end
            
            game.toggle_shop()
            return
        elseif game.buttons.workbench.hover then
            -- Play click sound with correct volume
            local click = assets.sounds.click
            if click then
                scene.playSound(click)
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
        local mx, my = scale_manager.getMousePosition()
        
        -- Position gun in the same place as when drawing it
        local oldX = gun.getPosition()
        gun.setPosition(GAME_WIDTH / 2)
        
        if gun.isClicked(mx, my) then
            local clicked, shells_earned = gun.shoot()
            if clicked then
                game.shells = game.shells + shells_earned
                saveGameState()
                if not game._first_shot_given then
                    steam.setAchievement(steam.achievements.FIRST_SHOT)
                    game._first_shot_given = true
                end
            end
        end
        
        -- Restore original gun position
        gun.setPosition(oldX)
    end
end

-- Handle mouse wheel events
function game.wheelmoved(x, y)
    -- Forward wheel events to appropriate modules
    if game.workbench_visible then
        workbench.wheelmoved(x, y)
    elseif game.shop_visible then
        -- Could add shop scrolling here if needed later
    end
end

-- Load/reload saved data from the active slot
function game.reloadSaveData()
    local active_slot = save.getActiveSlot()
    local saved = save.load(active_slot)
    
    -- Update game state with loaded data
    game.shells = saved.shells
    
    -- Update weapons from save data
    local weapons_module = require("weapons")
    if saved.cosmetics then
        -- Update weapon ownership and cosmetics
        for weapon_name, weapon_data in pairs(saved.cosmetics) do
            if weapons_module.data[weapon_name] then
                weapons_module.data[weapon_name].owned = weapon_data.owned or false
                
                -- Update cosmetics ownership
                if weapon_data.cosmetics then
                    for cosmetic_name, cosmetic_data in pairs(weapon_data.cosmetics) do
                        if weapons_module.data[weapon_name].cosmetics[cosmetic_name] then
                            weapons_module.data[weapon_name].cosmetics[cosmetic_name].owned = 
                                cosmetic_data.owned or false
                        end
                    end
                end
            end
        end
    end
    
    -- Reset upgrades
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
            end
        end
    end
    
    -- Reload workbench equipped items
    -- First initialize default equipment
    workbench.initEquipped()
    
    -- Then load saved equipment data
    if saved.equipped then
        for weapon, attachments in pairs(saved.equipped) do
            if workbench.equipped[weapon] then
                for attachment_type, equipped in pairs(attachments) do
                    if workbench.equipped[weapon][attachment_type] ~= nil then
                        workbench.equipped[weapon][attachment_type] = equipped
                    end
                end
            end
        end
    end
    
    -- Set equipped weapon
    if saved.equipped_weapon then
        workbench.equipped_weapon = saved.equipped_weapon
    else
        workbench.equipped_weapon = "pistol"  -- Default to pistol
    end
    
    -- Update the gun sprite
    if workbench.updateGunSprite then
        workbench.updateGunSprite()
    end
    
    -- Apply all upgrade effects
    upgrades.applyAllEffects(game)
end

-- Handle LÖVE events
function game.handleEvent(name)
    if name == "gameReloadSaveData" then
        game.reloadSaveData()
        return true
    end
    return false
end

return game
