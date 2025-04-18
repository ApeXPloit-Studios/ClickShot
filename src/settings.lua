local assets = require("assets")
local settings = {}

settings.visible = false
settings.data = {
    sound = { value = true, hover = false },
    music = { value = true, hover = false },
    fullscreen = { value = false, hover = false },
    resolution = { 
        value = "720p", 
        options = { "720p", "1080p", "2K", "4K" },
        hover = false,
        dropdown = {
            visible = false,
            hover = false,
            selected = 1
        }
    }
}

-- Resolution presets
local resolutions = {
    ["720p"] = { width = 1280, height = 720 },
    ["1080p"] = { width = 1920, height = 1080 },
    ["2K"] = { width = 2560, height = 1440 },
    ["4K"] = { width = 3840, height = 2160 }
}

-- Menu music
local menu_music = nil

function settings.load()
    -- Load menu music
    menu_music = love.audio.newSource("assets/sounds/menu_music.ogg", "stream")
    menu_music:setLooping(true)
    if settings.data.music.value then
        menu_music:play()
    end
end

function settings.toggle()
    settings.visible = not settings.visible
    if not settings.visible then
        settings.data.resolution.dropdown.visible = false
    end
end

function settings.update(dt)
    if not settings.visible then return end
    local mx, my = love.mouse.getPosition()
    
    -- Update hover states for all settings
    for _, v in pairs(settings.data) do
        local b = v._bounds
        if b then
            v.hover = mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h
        end
    end
    
    -- Update dropdown hover state if visible
    if settings.data.resolution.dropdown.visible then
        local dropdown = settings.data.resolution.dropdown
        local b = dropdown._bounds
        if b then
            dropdown.hover = mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h
        end
    end
end

function settings.draw()
    if not settings.visible then return end

    local w, h = 400, 300
    local x, y = (love.graphics.getWidth() - w) / 2, (love.graphics.getHeight() - h) / 2

    -- Draw background
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", x, y, w, h, 10, 10)

    -- Draw title
    love.graphics.setFont(assets.fonts.bold)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Settings", x, y + 10, w, "center")

    -- Draw settings
    local spacing = 60
    local startY = y + 50
    local i = 0

    for k, v in pairs(settings.data) do
        local label = k:sub(1,1):upper() .. k:sub(2)
        local state = ""
        
        if k == "resolution" then
            state = v.value
        else
            state = v.value and "On" or "Off"
        end
        
        local bx, by, bw, bh = x + 50, startY + i * spacing, 300, 40

        love.graphics.setColor(v.hover and {0.3, 0.3, 0.3} or {0.2, 0.2, 0.2})
        love.graphics.rectangle("fill", bx, by, bw, bh, 6, 6)

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(label .. ": " .. state, bx, by + 10, bw, "center")

        v._bounds = { x = bx, y = by, w = bw, h = bh }
        i = i + 1
    end
    
    -- Draw resolution dropdown if visible
    if settings.data.resolution.dropdown.visible then
        local dropdown = settings.data.resolution.dropdown
        local res = settings.data.resolution
        local b = res._bounds
        
        -- Draw dropdown background
        love.graphics.setColor(0.1, 0.1, 0.1, 0.95)
        love.graphics.rectangle("fill", b.x, b.y + b.h, b.w, #res.options * 30, 6, 6)
        
        -- Draw dropdown options
        for i, option in ipairs(res.options) do
            local optionY = b.y + b.h + (i-1) * 30
            local isSelected = option == res.value
            
            love.graphics.setColor(isSelected and {0.3, 0.3, 0.3} or {0.2, 0.2, 0.2})
            love.graphics.rectangle("fill", b.x, optionY, b.w, 30, 4, 4)
            
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(option, b.x, optionY + 5, b.w, "center")
        end
        
        dropdown._bounds = {
            x = b.x,
            y = b.y + b.h,
            w = b.w,
            h = #res.options * 30
        }
    end
end

function settings.mousepressed(mx, my, button)
    if not settings.visible or button ~= 1 then return end

    local res = settings.data.resolution
    local dropdown = res.dropdown
    
    -- Check if clicking on resolution dropdown
    if dropdown.visible then
        local b = dropdown._bounds
        if mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h then
            local optionIndex = math.floor((my - b.y) / 30) + 1
            if optionIndex >= 1 and optionIndex <= #res.options then
                res.value = res.options[optionIndex]
                dropdown.visible = false
                
                -- Apply new resolution
                local res = resolutions[res.value]
                love.window.setMode(res.width, res.height, {
                    fullscreen = settings.data.fullscreen.value,
                    resizable = true
                })
            end
            return
        end
    end

    -- Check other settings
    for k, v in pairs(settings.data) do
        local b = v._bounds
        if mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h then
            if k == "resolution" then
                dropdown.visible = not dropdown.visible
            else
                v.value = not v.value
                
                -- Apply settings
                if k == "fullscreen" then
                    local current_res = resolutions[settings.data.resolution.value]
                    love.window.setMode(current_res.width, current_res.height, {
                        fullscreen = v.value,
                        resizable = true
                    })
                elseif k == "sound" then
                    love.audio.setVolume(v.value and 1 or 0)
                elseif k == "music" then
                    if v.value then
                        menu_music:play()
                    else
                        menu_music:pause()
                    end
                end
            end
            return
        end
    end
    
    -- If clicking outside dropdown, close it
    if dropdown.visible then
        dropdown.visible = false
    end
end

return settings 