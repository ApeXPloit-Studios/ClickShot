local assets = require("assets")
local gun = require("gun")
local weapons = require("weapons")
local save = require("save")
local ui = require("ui")
local scale_manager = require("scale_manager")
local steam = require("steam")
local controller = require("controller")
local workbench = {}

workbench.equipped_weapon = "pistol"  -- Default weapon
workbench.expanded_weapon = nil  -- Currently expanded weapon dropdown
workbench.scroll_offset = 0      -- Scroll position for attachments
workbench.max_scroll = 0         -- Maximum scroll value
workbench.scroll_speed = 50      -- Scroll speed

-- Initialize equipped data with default values
function workbench.initEquipped()
    workbench.equipped = {
        pistol = { muzzle = false, sight = false, laser = false },
        ak47 = { sight = false, grip = false, stock = false, mag = false },
        smg = {},
        bazooka = {}
    }
end

-- Load saved equipped items
function workbench.load()
    -- Initialize default equipped data
    workbench.initEquipped()
    
    -- Load saved data
    local data = save.load()
    -- Ensure equipped data exists
    if not data.equipped then
        return
    end
        -- Merge saved equipped data with defaults
        for weapon, attachments in pairs(data.equipped) do
            if workbench.equipped[weapon] then
                for type, equipped in pairs(attachments) do
                    if workbench.equipped[weapon][type] ~= nil then
                        workbench.equipped[weapon][type] = equipped
                end
            end
        end
    end
    
    -- Set equipped weapon if specified
    if data.equipped_weapon and workbench.equipped[data.equipped_weapon] then
        workbench.equipped_weapon = data.equipped_weapon
        workbench.updateGunSprite()
    else
        -- Initialize gun power for default weapon (pistol)
        local weapon_power = weapons.getWeaponPower(workbench.equipped_weapon, workbench.equipped)
        gun.setPower(weapon_power)
    end
end

function workbench.update(dt, game)
    if not game.workbench_visible then return end
    
    local mx, my = ui.getCursorPosition()
    
    -- Update weapon button hover states
    for weapon, data in pairs(weapons.getAll()) do
        if data.owned and data._bounds then
            ui.updateButtonHover(data)
        end
    end
    
    -- Update attachment hover states for expanded weapon
    if workbench.expanded_weapon then
        local weapon_data = weapons.getWeapon(workbench.expanded_weapon)
        if weapon_data then
            for type, v in pairs(weapon_data.cosmetics) do
                if v._bounds then
                    ui.updateButtonHover(v)
                end
            end
        end
    end
    
    -- Reset max_scroll at the start of each frame
    workbench.max_scroll = 0
end

function workbench.draw(game)
    if not game.workbench_visible then return end

    -- Calculate panel size as percentage of screen
    local panel_width = scale_manager.design_width * 0.4  -- 40% of screen width
    local panel_height = scale_manager.design_height * 0.7 -- 70% of screen height
    local panel_x = (scale_manager.design_width - panel_width) / 2
    local panel_y = (scale_manager.design_height - panel_height) / 2

    -- Panel background
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", panel_x, panel_y, panel_width, panel_height, 10, 10)

    -- Title
    love.graphics.setFont(assets.fonts.bold)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Workbench", panel_x, panel_y + panel_height * 0.03, panel_width, "center")

    -- Button dimensions
    local button_width = panel_width * 0.85  -- 85% of panel width
    local button_height = panel_height * 0.08
    local button_x = panel_x + (panel_width - button_width) / 2
    local indent_width = button_width * 0.9  -- Slightly narrower for attachments
    local indent_x = button_x + (button_width - indent_width) / 2
    local spacing = button_height * 1.3
    local startY = panel_y + panel_height * 0.12
    local i = 0
    
    -- Define scrollable content area
    local content_top = startY
    local content_height = panel_height * 0.85
    local content_bottom = panel_y + content_height

    -- Convert content area to window coordinates for scissor
    local scissor_x, scissor_y = scale_manager.toWindowCoords(panel_x, content_top)
    local scissor_w = panel_width * scale_manager.scale_x
    local scissor_h = (content_bottom - content_top) * scale_manager.scale_y
    
    -- Create scissor rectangle for content area
    love.graphics.setScissor(scissor_x, scissor_y, scissor_w, scissor_h)

    -- Draw weapon buttons
    for weapon, data in pairs(weapons.getAll()) do
        if data.owned then
            local label = weapon:upper()
            local state = workbench.equipped_weapon == weapon and "Equipped" or "Equip"
            local by = startY + i * spacing - workbench.scroll_offset
            
            -- Only draw if in visible area (with buffer for partially visible buttons)
            if by + button_height >= content_top - button_height and by <= content_bottom + button_height then
                -- Display weapon power
                local power_text = ""
                if workbench.equipped_weapon == weapon then
                    local power = weapons.getWeaponPower(weapon, workbench.equipped)
                    power_text = " (Power: " .. power .. ")"
                end

            love.graphics.setColor(data.hover and {0.3, 0.3, 0.3} or {0.2, 0.2, 0.2})
                love.graphics.rectangle("fill", button_x, by, button_width, button_height, 6, 6)

            love.graphics.setColor(1, 1, 1)
                love.graphics.printf(label .. ": " .. state .. power_text, 
                    button_x, by + button_height/2 - assets.fonts.medium:getHeight()/2, 
                    button_width, "center")

                data._bounds = { x = button_x, y = by, w = button_width, h = button_height }
            else
                -- Keep track of bounds for hit detection even if not visible
                data._bounds = { x = button_x, y = by, w = button_width, h = button_height }
            end
            
            i = i + 1

            -- Draw attachments if this weapon is expanded
            if workbench.expanded_weapon == weapon then
                -- Sort attachments alphabetically
                local sorted_types = {}
                for type, _ in pairs(data.cosmetics) do
                    table.insert(sorted_types, type)
                end
                table.sort(sorted_types)
                
                for _, type in ipairs(sorted_types) do
                    local v = data.cosmetics[type]
                    local label = type:sub(1,1):upper() .. type:sub(2)
                    local state = v.owned and (workbench.equipped[weapon][type] and "Unequip" or "Equip") or "Locked"
                    local by = startY + i * spacing - workbench.scroll_offset
                    
                    -- Only draw if in visible area
                    if by + button_height >= content_top - button_height and by <= content_bottom + button_height then
                        -- Add power information for owned attachments
                        local power_text = ""
                        if v.owned and v.power then
                            power_text = " (+" .. v.power .. ")"
                        end

                    love.graphics.setColor(v.hover and {0.3, 0.3, 0.3} or {0.2, 0.2, 0.2})
                        love.graphics.rectangle("fill", indent_x, by, indent_width, button_height, 6, 6)

                    love.graphics.setColor(1, 1, 1)
                        love.graphics.printf(label .. power_text .. ": " .. state, 
                            indent_x, by + button_height/2 - assets.fonts.medium:getHeight()/2, 
                            indent_width, "center")

                        v._bounds = { x = indent_x, y = by, w = indent_width, h = button_height }
                    else
                        -- Keep track of bounds for hit detection even if not visible
                        v._bounds = { x = indent_x, y = by, w = indent_width, h = button_height }
                    end
                    i = i + 1
                end
            end
        end
    end
    
    -- Calculate max scroll value
    local total_height = i * spacing
    local visible_height = content_bottom - content_top
    workbench.max_scroll = math.max(0, total_height - visible_height)
    
    -- Reset scissor
    love.graphics.setScissor()
    
    -- Draw scroll indicators if content is scrollable
    if workbench.max_scroll > 0 then
        -- Draw scroll up indicator if not at top
        if workbench.scroll_offset > 0 then
            love.graphics.setColor(1, 1, 1, 0.7)
            local arrow_width = 20
            local arrow_x = panel_x + panel_width / 2
            local arrow_y = content_top + 15
            love.graphics.polygon("fill", 
                arrow_x - arrow_width/2, arrow_y + arrow_width/2,
                arrow_x, arrow_y,
                arrow_x + arrow_width/2, arrow_y + arrow_width/2
            )
        end
        
        -- Draw scroll down indicator if not at bottom
        if workbench.scroll_offset < workbench.max_scroll then
            love.graphics.setColor(1, 1, 1, 0.7)
            local arrow_width = 20
            local arrow_x = panel_x + panel_width / 2
            local arrow_y = content_bottom - 15
            love.graphics.polygon("fill", 
                arrow_x - arrow_width/2, arrow_y - arrow_width/2,
                arrow_x, arrow_y,
                arrow_x + arrow_width/2, arrow_y - arrow_width/2
            )
        end
    end
end

function workbench.mousepressed(mx, my, button, game)
    if not game.workbench_visible then return end
    
    -- Use controller-aware cursor position
    local posX, posY
    if controller.usingController then
        posX, posY = controller.cursorX, controller.cursorY
    else
        posX, posY = mx, my
    end
    
    -- Check weapon selection
    for weapon, data in pairs(weapons.getAll()) do
        if data.owned and data._bounds then
            if ui.pointInRect(posX, posY, data._bounds) then
                if workbench.expanded_weapon == weapon then
                    workbench.expanded_weapon = nil
                else
                    workbench.expanded_weapon = weapon
                    workbench.equipped_weapon = weapon
                    -- Reset scroll position when changing weapons
                    workbench.scroll_offset = 0
                    workbench.updateGunSprite()
                    save.update(game.shells, weapons.getAll(), workbench.equipped, workbench.equipped_weapon)
                    
                    -- Set first weapon achievement if this is the first equip
                    steam.setAchievement(steam.achievements.FIRST_WEAPON)
                    
                    -- Set weapon-specific achievement
                    local achievement_map = {
                        ak47 = steam.achievements.AK47_EQUIPPED,
                        smg = steam.achievements.SMG_EQUIPPED,
                        bazooka = steam.achievements.BAZOOKA_EQUIPPED
                    }
                    if achievement_map[weapon] then
                        steam.setAchievement(achievement_map[weapon])
                    end
                end
                return
            end
        end
    end
    
    -- Check attachment selection for expanded weapon
    if workbench.expanded_weapon then
        local weapon_data = weapons.getWeapon(workbench.expanded_weapon)
        if weapon_data then
            for type, v in pairs(weapon_data.cosmetics) do
                if v._bounds and ui.pointInRect(posX, posY, v._bounds) then
                    if v.owned then
                        local was_equipped = workbench.equipped[workbench.expanded_weapon][type]
                        workbench.equipped[workbench.expanded_weapon][type] = not was_equipped
                        workbench.updateGunSprite()
                        save.update(game.shells, weapons.getAll(), workbench.equipped, workbench.equipped_weapon)
                        
                        if not was_equipped then  -- Only when equipping, not unequipping
                            -- Set first attachment achievement
                            steam.setAchievement(steam.achievements.FIRST_ATTACHMENT)
                            
                            -- Set attachment-specific achievement
                            local achievement_key = string.upper(workbench.expanded_weapon .. "_" .. type .. "_EQUIPPED")
                            if steam.achievements[achievement_key] then
                                steam.setAchievement(steam.achievements[achievement_key])
                            end
                        end
                    end
                    return
                end
            end
        end
    end
end

-- Handle mouse wheel for scrolling
function workbench.wheelmoved(x, y)
    -- We don't have a workbench.visible property, this is always checked in game.lua
    -- So no need for a visibility check here
    
    -- Scroll content
    local scroll_amount = -y * workbench.scroll_speed
    workbench.scroll_offset = math.max(0, math.min(workbench.max_scroll, workbench.scroll_offset + scroll_amount))
end

function workbench.updateGunSprite()
    local weapon = workbench.equipped_weapon
    
    -- Ensure equipped data exists for this weapon
    if not workbench.equipped then
        workbench.initEquipped()
    end
    
    -- Ensure the weapon exists in equipped data
    if not workbench.equipped[weapon] then
        workbench.equipped[weapon] = {}
        for type, _ in pairs(weapons.getWeapon(weapon).cosmetics) do
            workbench.equipped[weapon][type] = false
        end
    end
    
    -- Update gun power based on current weapon and attachments
    local weapon_power = weapons.getWeaponPower(weapon, workbench.equipped)
    gun.setPower(weapon_power)
    
    local combo = {}
    -- Special case for AK-47
    if weapon == "ak47" then
        if workbench.equipped[weapon].sight then 
            table.insert(combo, "scope")  -- AK-47 uses "scope" in filenames
        end
        if workbench.equipped[weapon].grip then table.insert(combo, "grip") end
        if workbench.equipped[weapon].stock then table.insert(combo, "stock") end
        if workbench.equipped[weapon].mag then table.insert(combo, "mag") end
        
        -- Handle special case for all attachments
        local all_equipped = workbench.equipped[weapon].sight and 
                            workbench.equipped[weapon].grip and 
                            workbench.equipped[weapon].stock and 
                            workbench.equipped[weapon].mag
        
        if all_equipped then
            local path = "assets/images/ak47/fire_ak-47_all_attachments.png"
            local success, image = pcall(love.graphics.newImage, path)
            if success then
                image:setFilter("nearest", "nearest")
                gun.setSprite(image)
                return
            end
        end
    else
        -- Standard processing for other weapons
    if workbench.equipped[weapon].muzzle then table.insert(combo, "muzzle") end
    if workbench.equipped[weapon].sight  then table.insert(combo, "sight") end
    if workbench.equipped[weapon].laser  then table.insert(combo, "laser") end
    end

    -- Fix filename issue with ak-47 vs ak47
    local filename_weapon = weapon
    if weapon == "ak47" then
        filename_weapon = "ak-47"
    end

    local path = "assets/images/" .. weapon .. "/fire_" .. filename_weapon
    if #combo > 0 then
        path = path .. "_" .. table.concat(combo, "_")
    end
    path = path .. ".png"

    local success, image = pcall(love.graphics.newImage, path)
    if success then
        image:setFilter("nearest", "nearest")
        gun.setSprite(image)
    else
        print("Failed to load sprite:", path)
        -- Fallback to base weapon sprite
        path = "assets/images/" .. weapon .. "/fire_" .. filename_weapon .. ".png"
        success, image = pcall(love.graphics.newImage, path)
        if success then
            image:setFilter("nearest", "nearest")
            gun.setSprite(image)
        else
            print("Failed to load fallback sprite:", path)
        end
    end
end

-- Get the power value of the currently equipped weapon with attachments
function workbench.getCurrentWeaponPower()
    return weapons.getWeaponPower(workbench.equipped_weapon, workbench.equipped)
end

return workbench
