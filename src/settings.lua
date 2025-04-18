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
        hover = false 
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
end

function settings.update(dt)
    if not settings.visible then return end
    local mx, my = love.mouse.getPosition()
    for _, v in pairs(settings.data) do
        local b = v._bounds
        if b then
            v.hover = mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h
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
end

function settings.mousepressed(mx, my, button)
    if not settings.visible or button ~= 1 then return end

    for k, v in pairs(settings.data) do
        local b = v._bounds
        if mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h then
            if k == "resolution" then
                -- Cycle through resolution options
                local current_index = 1
                for i, option in ipairs(v.options) do
                    if option == v.value then
                        current_index = i
                        break
                    end
                end
                current_index = current_index % #v.options + 1
                v.value = v.options[current_index]
                
                -- Apply new resolution
                local res = resolutions[v.value]
                love.window.setMode(res.width, res.height, {
                    fullscreen = settings.data.fullscreen.value,
                    resizable = true
                })
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
        end
    end
end

return settings 