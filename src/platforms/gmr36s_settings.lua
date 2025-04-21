local assets = require("assets")
local settings = {}

settings.visible = false
settings.data = {
    sound = { value = true },
    music = { value = true }
}

-- No menu music for Game Master version
local menu_music = nil

function settings.load()
    -- Simplified settings for Game Master
    menu_music = love.audio.newSource("assets/sounds/menu_music.ogg", "stream")
    menu_music:setLooping(true)
    if settings.data.music.value then
        menu_music:play()
    end
end

function settings.toggle()
    -- Settings disabled for Game Master version
end

function settings.update(dt)
    -- No settings updates needed
end

function settings.draw()
    -- No settings menu to draw
end

function settings.mousepressed(x, y, button)
    -- No settings interactions
end

return settings 