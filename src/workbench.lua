local assets = require("assets")
local gun = require("gun")
local weapons = require("weapons")
local save = require("save")
local ui = require("ui")
local scale_manager = require("scale_manager")
local workbench = {}

workbench.equipped_weapon = "pistol"  -- Default weapon
workbench.expanded_weapon = nil  -- Currently expanded weapon dropdown

-- Initialize equipped data with default values
function workbench.initEquipped()
    workbench.equipped = {
        pistol = { muzzle = false, sight = false, laser = false },
        ak47 = { muzzle = false, sight = false, laser = false }
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
    end
end

function workbench.update(dt, game)
    if not game.workbench_visible then return end
    
    local mx, my = scale_manager.getMousePosition()
    
    -- Update weapon button hover states
    for weapon, data in pairs(weapons.getAll()) do
        if data.owned and data._bounds then
            ui.updateButtonHover(data, mx, my)
        end
    end
    
    -- Update attachment hover states for expanded weapon
    if workbench.expanded_weapon then
        local weapon_data = weapons.getWeapon(workbench.expanded_weapon)
        if weapon_data then
            for type, v in pairs(weapon_data.cosmetics) do
                if v._bounds then
                    ui.updateButtonHover(v, mx, my)
                end
            end
        end
    end
end

function workbench.draw(game)
    if not game.workbench_visible then return end

    local w, h = 400, 400
    local x, y = (scale_manager.design_width - w) / 2, (scale_manager.design_height - h) / 2

    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", x, y, w, h, 10, 10)

    love.graphics.setFont(assets.fonts.bold)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Workbench", x, y + 10, w, "center")

    local spacing = 60
    local startY = y + 50
    local i = 0

    -- Draw weapon buttons
    for weapon, data in pairs(weapons.getAll()) do
        if data.owned then
            local label = weapon:upper()
            local state = workbench.equipped_weapon == weapon and "Equipped" or "Equip"
            local bx, by, bw, bh = x + 50, startY + i * spacing, 300, 40

            love.graphics.setColor(data.hover and {0.3, 0.3, 0.3} or {0.2, 0.2, 0.2})
            love.graphics.rectangle("fill", bx, by, bw, bh, 6, 6)

            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(label .. ": " .. state, bx, by + 10, bw, "center")

            data._bounds = { x = bx, y = by, w = bw, h = bh }
            i = i + 1

            -- Draw attachments if this weapon is expanded
            if workbench.expanded_weapon == weapon then
                for type, v in pairs(data.cosmetics) do
                    local label = type:sub(1,1):upper() .. type:sub(2)
                    local state = v.owned and (workbench.equipped[weapon][type] and "Unequip" or "Equip") or "Locked"
                    local bx, by, bw, bh = x + 70, startY + i * spacing, 260, 40

                    love.graphics.setColor(v.hover and {0.3, 0.3, 0.3} or {0.2, 0.2, 0.2})
                    love.graphics.rectangle("fill", bx, by, bw, bh, 6, 6)

                    love.graphics.setColor(1, 1, 1)
                    love.graphics.printf(label .. ": " .. state, bx, by + 10, bw, "center")

                    v._bounds = { x = bx, y = by, w = bw, h = bh }
                    i = i + 1
                end
            end
        end
    end
end

function workbench.mousepressed(x, y, button, game)
    if not game.workbench_visible then return end
    
    -- Check weapon selection
    for weapon, data in pairs(weapons.getAll()) do
        if data.owned and data._bounds then
            if ui.pointInRect(x, y, data._bounds) then
                if workbench.expanded_weapon == weapon then
                    workbench.expanded_weapon = nil
                else
                    workbench.expanded_weapon = weapon
                    workbench.equipped_weapon = weapon
                    workbench.updateGunSprite()
                    save.update(game.shells, weapons.getAll(), workbench.equipped, workbench.equipped_weapon)
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
                if v._bounds and ui.pointInRect(x, y, v._bounds) then
                    if v.owned then
                        workbench.equipped[workbench.expanded_weapon][type] = not workbench.equipped[workbench.expanded_weapon][type]
                        workbench.updateGunSprite()
                        save.update(game.shells, weapons.getAll(), workbench.equipped, workbench.equipped_weapon)
                    end
                    return
                end
            end
        end
    end
end

function workbench.updateGunSprite()
    local weapon = workbench.equipped_weapon
    
    -- Ensure equipped data exists for this weapon
    if not workbench.equipped then
        workbench.initEquipped()
    end
    
    -- Ensure the weapon exists in equipped data
    if not workbench.equipped[weapon] then
        workbench.equipped[weapon] = { muzzle = false, sight = false, laser = false }
    end
    
    local combo = {}
    if workbench.equipped[weapon].muzzle then table.insert(combo, "muzzle") end
    if workbench.equipped[weapon].sight  then table.insert(combo, "sight") end
    if workbench.equipped[weapon].laser  then table.insert(combo, "laser") end

    local path = "assets/images/" .. weapon .. "/fire_" .. weapon
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
    end
end

return workbench
