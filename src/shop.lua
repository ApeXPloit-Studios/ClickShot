local assets = require("assets")
local weapons = require("weapons")
local ui = require("ui")
local scale_manager = require("scale_manager")
local shop = {}

-- Track which weapon's cosmetics are currently being shown
shop.selected_weapon = nil

function shop.update(dt, game)
    if not game.shop_visible then return end
    
    local mx, my = scale_manager.getMousePosition()
    
    -- Update weapon hover states
    for weapon, data in pairs(weapons.getAll()) do
        if data._bounds then
            ui.updateButtonHover(data, mx, my)
        end
    end
    
    -- Update cosmetics hover states only for selected weapon
    if shop.selected_weapon then
        local data = weapons.getWeapon(shop.selected_weapon)
        if data and data.owned then
        for type, v in pairs(data.cosmetics) do
            if v._bounds then
                    ui.updateButtonHover(v, mx, my)
                end
            end
        end
    end
    
    -- Update back button hover state
    if shop.back_button and shop.selected_weapon then
        ui.updateButtonHover(shop.back_button, mx, my)
    end
end

function shop.draw(game)
    if not game.shop_visible then return end

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
    love.graphics.printf("Shop", panel_x, panel_y + panel_height * 0.03, panel_width, "center")

    -- Button dimensions
    local button_width = panel_width * 0.85  -- 85% of panel width
    local button_height = panel_height * 0.08
    local button_x = panel_x + (panel_width - button_width) / 2
    local spacing = button_height * 1.3
    
    -- If viewing a specific weapon's cosmetics
    if shop.selected_weapon then
        local weapon_data = weapons.getWeapon(shop.selected_weapon)
        
        -- Draw weapon name as header
        love.graphics.setFont(assets.fonts.medium)
        love.graphics.printf(shop.selected_weapon:upper() .. " ATTACHMENTS", 
            panel_x, panel_y + panel_height * 0.08, panel_width, "center")
        
        -- Draw back button
        local back_button = shop.back_button or {}
        back_button.text = "Back to Weapons"
        shop.back_button = back_button
        
        local by = panel_y + panel_height * 0.15
        love.graphics.setColor(back_button.hover and {0.3, 0.3, 0.3} or {0.2, 0.2, 0.2})
        love.graphics.rectangle("fill", button_x, by, button_width, button_height, 6, 6)

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(back_button.text, button_x, by + button_height/2 - assets.fonts.medium:getHeight()/2, 
            button_width, "center")
        
        back_button._bounds = { x = button_x, y = by, w = button_width, h = button_height }
        
        -- Draw cosmetics for the selected weapon
        local startY = panel_y + panel_height * 0.25
        local i = 0
        
        if weapon_data and weapon_data.owned then
            -- Sort attachments alphabetically for consistent display
            local sorted_types = {}
            for type, _ in pairs(weapon_data.cosmetics) do
                table.insert(sorted_types, type)
            end
            table.sort(sorted_types)
            
            for _, type in ipairs(sorted_types) do
                local v = weapon_data.cosmetics[type]
                local label = type:sub(1,1):upper() .. type:sub(2)
                local state = v.owned and "Owned" or ("Buy ($" .. v.cost .. ")")
                local power_text = ""
                
                -- Display power boost information
                if v.power then
                    power_text = " (+" .. v.power .. " power)"
                end
                
                local by = startY + i * spacing

                love.graphics.setColor(v.hover and {0.3, 0.3, 0.3} or {0.2, 0.2, 0.2})
                love.graphics.rectangle("fill", button_x, by, button_width, button_height, 6, 6)

                love.graphics.setColor(1, 1, 1)
                love.graphics.printf(label .. power_text .. ": " .. state, 
                    button_x, by + button_height/2 - assets.fonts.medium:getHeight()/2, 
                    button_width, "center")

                v._bounds = { x = button_x, y = by, w = button_width, h = button_height }
                i = i + 1
            end
        end
    else
        -- Draw weapons section (main shop view)
        love.graphics.setFont(assets.fonts.medium)
        love.graphics.printf("Weapons", panel_x, panel_y + panel_height * 0.08, panel_width, "center")
        
        local startY = panel_y + panel_height * 0.15
        local i = 0
        
        -- Sort weapons by price for better organization
        local sorted_weapons = {}
        for weapon, data in pairs(weapons.getAll()) do
            table.insert(sorted_weapons, {name = weapon, data = data})
        end
        
        table.sort(sorted_weapons, function(a, b)
            if a.data.owned and not b.data.owned then return true end
            if not a.data.owned and b.data.owned then return false end
            return (a.data.cost or 0) < (b.data.cost or 0)
        end)
        
        -- Draw weapons
        for _, item in ipairs(sorted_weapons) do
            local weapon, data = item.name, item.data
            local label = weapon:upper()
            local state = data.owned and "Owned" or ("Buy ($" .. data.cost .. ")")
            local power_text = " (Power: " .. data.power .. ")"
            local by = startY + i * spacing
            
            love.graphics.setColor(data.hover and {0.3, 0.3, 0.3} or {0.2, 0.2, 0.2})
            love.graphics.rectangle("fill", button_x, by, button_width, button_height, 6, 6)
            
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(label .. power_text .. ": " .. state, 
                button_x, by + button_height/2 - assets.fonts.medium:getHeight()/2, 
                button_width, "center")
            
            -- If owned, show "View Attachments" button
            if data.owned then
                -- Use consistent spacing above and below
                local vertical_gap = spacing - button_height
                local attach_by = by + button_height + vertical_gap/2
                local attach_height = button_height * 0.75
                
                -- Draw connecting elements to show relationship
                love.graphics.setColor(0.4, 0.6, 0.4, 0.5)
                -- Left vertical line
                love.graphics.rectangle("fill", button_x + button_width * 0.15, 
                    by + button_height, 2, attach_by - by)
                -- Right vertical line
                love.graphics.rectangle("fill", button_x + button_width * 0.85, 
                    by + button_height, 2, attach_by - by)
                -- Middle vertical line
                love.graphics.rectangle("fill", button_x + button_width * 0.5,
                    by + button_height, 2, vertical_gap/2)
                    
                -- Draw button with more specific weapon name
                love.graphics.setColor(0.3, 0.5, 0.3)
                love.graphics.rectangle("fill", button_x, attach_by, button_width, attach_height, 6, 6)
                
                -- Add slight 3D effect
                love.graphics.setColor(0.4, 0.6, 0.4)
                love.graphics.rectangle("line", button_x, attach_by, button_width, attach_height, 6, 6)
                
                love.graphics.setColor(1, 1, 1)
                -- Use more specific button text that references the weapon
                love.graphics.printf(label .. " Attachments", 
                    button_x, attach_by + attach_height/2 - assets.fonts.medium:getHeight()/2, 
                    button_width, "center")
                
                data._attach_bounds = { x = button_x, y = attach_by, w = button_width, h = attach_height }
                
                -- Account for extra button in spacing, and add the same gap below
                i = i + 1 + (attach_height + vertical_gap/2)/spacing
            else
                i = i + 1
            end
            
            data._bounds = { x = button_x, y = by, w = button_width, h = button_height }
        end
    end
end

function shop.mousepressed(x, y, button, game)
    if not game.shop_visible then return end
    
    -- Handle back button when viewing cosmetics
    if shop.selected_weapon then
        if shop.back_button and ui.pointInRect(x, y, shop.back_button._bounds) then
            shop.selected_weapon = nil
            return
        end
        
        -- Check cosmetic purchases for selected weapon
        local weapon = shop.selected_weapon
        local data = weapons.getWeapon(weapon)
    
        if data and data.owned then
            for type, v in pairs(data.cosmetics) do
                if v._bounds and ui.pointInRect(x, y, v._bounds) then
                    if not v.owned and game.shells >= v.cost then
                        game.shells = game.shells - v.cost
                        weapons.setCosmeticOwned(weapon, type, true)
                    end
                    return
                end
            end
        end
    else
        -- Main shop view
        
        -- Check weapon purchases
        for weapon, data in pairs(weapons.getAll()) do
            -- Buy weapon
            if data._bounds and ui.pointInRect(x, y, data._bounds) then
                if not data.owned and game.shells >= data.cost then
                    game.shells = game.shells - data.cost
                    weapons.setOwned(weapon, true)
                end
                return
            end
            
            -- View attachments button
            if data._attach_bounds and ui.pointInRect(x, y, data._attach_bounds) then
                shop.selected_weapon = weapon
                return
            end
        end
    end
end

return shop
