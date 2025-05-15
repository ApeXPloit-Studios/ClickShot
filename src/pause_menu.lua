local assets = require("assets")
local scene = require("scene")
local save = require("save")
local shop = require("shop")
local background_effect = require("background_effect")
local settings = require("settings")
local ui = require("ui")
local scale_manager = require("scale_manager")
local save_slot_menu = require("save_slot_menu")

local pause_menu = {
    visible = false,
    time = 0,
    title_scale = 1,
    buttons = {}
}

-- Define button actions separately
local function resumeAction()
    pause_menu.visible = false
end

local function saveGameAction()
    save_slot_menu.show("save")
    pause_menu.visible = false
end

local function mainMenuAction()
    pause_menu.visible = false
    save.update(require("game").shells, shop.cosmetics)
    scene.set("menu")
end

local function exitAction()
    save.update(require("game").shells, shop.cosmetics)
    love.event.quit()
end

-- Initialize buttons
pause_menu.buttons = {
    { text = "Resume", hover = false, action = resumeAction },
    { text = "Save Game", hover = false, action = saveGameAction },
    { text = "Settings", hover = false, action = function() settings.toggle() end },
    { text = "Main Menu", hover = false, action = mainMenuAction }
}

-- Only add exit button if not on iOS
if love.system.getOS() ~= "iOS" then
    table.insert(pause_menu.buttons, { text = "Exit", hover = false, action = exitAction })
end

function pause_menu.toggle()
    pause_menu.visible = not pause_menu.visible
    if pause_menu.visible then
        -- Initialize button bounds when menu becomes visible
        local w, h = 400, 300
        local x, y = (scale_manager.design_width - w) / 2, (scale_manager.design_height - h) / 2
        local spacing = 60
        local startY = y + 50
        local buttonH = 50

        for i, b in ipairs(pause_menu.buttons) do
            local by = startY + (i-1) * spacing
            local bx, bw = x + 50, w - 100
            b._bounds = { x = bx, y = by, w = bw, h = buttonH }
        end
    end
end

function pause_menu.update(dt)
    if not pause_menu.visible then return end
    
    pause_menu.time = pause_menu.time + dt
    pause_menu.title_scale = 1 + 0.05 * math.sin(pause_menu.time * 2)
    
    -- Update background effect
    background_effect.update(dt)
    
    -- Update settings
    settings.update(dt)
    
    -- Update save slot menu
    if save_slot_menu.visible then
        save_slot_menu.update(dt)
    end
    
    -- Update UI hover effect
    ui.update(dt)
    
    -- Update button hover states
    local mx, my = scale_manager.getMousePosition()
    for _, b in ipairs(pause_menu.buttons) do
        ui.updateButtonHover(b, mx, my)
    end
end

function pause_menu.draw()
    if not pause_menu.visible then return end

    -- Draw background effect with overlay
    background_effect.draw()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, scale_manager.design_width, scale_manager.design_height)

    -- Draw settings if visible and return (modal)
    if settings.visible then
    settings.draw()
        return
    end

    -- Draw save slot menu if visible and return 
    if save_slot_menu.visible then
        save_slot_menu.draw()
        return
    end

    -- Draw menu
    local w, h = 400, 300
    local x, y = (scale_manager.design_width - w) / 2, (scale_manager.design_height - h) / 2

    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", x, y, w, h, 10, 10)

    -- Draw animated title
    love.graphics.setFont(assets.fonts.bold)
    love.graphics.setColor(1, 1, 1)
    
    ui.drawAnimatedTitle(
        "Paused",
        x + w/2,
        y + 10 + assets.fonts.bold:getHeight()/2,
        pause_menu.title_scale,
        assets.fonts.bold,
        {centerX = true, centerY = true}
    )

    -- Draw buttons
    for _, b in ipairs(pause_menu.buttons) do
        ui.drawButton(b, b._bounds.x, b._bounds.y, b._bounds.w, b._bounds.h)
    end
end

function pause_menu.mousepressed(mx, my, button)
    if not pause_menu.visible or button ~= 1 then return end

    -- Check settings first
    if settings.visible then
        settings.mousepressed(mx, my, button)
        return
    end

    -- Check save slot menu
    if save_slot_menu.visible then
        save_slot_menu.mousepressed(mx, my, button)
        return
    end

    for _, b in ipairs(pause_menu.buttons) do
        if b._bounds and b.hover then
            -- Play click sound with correct volume
            if assets.sounds.click then
                scene.playSound(assets.sounds.click)
            end
            
            b.action()
            return
        end
    end
end

function pause_menu.mousereleased(mx, my, button)
    if settings.visible then
        settings.mousereleased(mx, my, button)
    end
end

return pause_menu 