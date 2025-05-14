local assets = require("assets")
local scene = require("scene")
local save = require("save")
local shop = require("shop")
local background_effect = require("background_effect")
local settings = require("settings")
local ui = require("ui")

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
        local x, y = (love.graphics.getWidth() - w) / 2, (love.graphics.getHeight() - h) / 2
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
    
    -- Update UI hover effect
    ui.update(dt)
    
    -- Update button hover states
    local mx, my = love.mouse.getPosition()
    for _, b in ipairs(pause_menu.buttons) do
        ui.updateButtonHover(b, mx, my)
    end
end

function pause_menu.draw()
    if not pause_menu.visible then return end

    -- Draw background effect with overlay
    background_effect.draw()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Draw settings if visible and return (modal)
    if settings.visible then
    settings.draw()
        return
    end

    -- Draw menu
    local w, h = 400, 300
    local x, y = (love.graphics.getWidth() - w) / 2, (love.graphics.getHeight() - h) / 2

    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", x, y, w, h, 10, 10)

    -- Draw animated title
    love.graphics.setFont(assets.fonts.bold)
    love.graphics.setColor(1, 1, 1)
    
    local title = "Paused"
    local tw = assets.fonts.bold:getWidth(title)
    local th = assets.fonts.bold:getHeight()
    
    love.graphics.push()
    love.graphics.translate(x + w/2, y + 10 + th/2)
    love.graphics.scale(pause_menu.title_scale, pause_menu.title_scale)
    love.graphics.translate(-tw/2, -th/2)
    
    -- Draw title with glow effect
    for i = 1, 5 do
        local alpha = 1 - (i * 0.2)
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.print(title, i, i)
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(title, 0, 0)
    
    love.graphics.pop()

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