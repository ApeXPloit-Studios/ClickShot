local scene = {}
scene.current = "menu"

-- Store music source at scene level to avoid circular dependency
-- scene.menu_music = nil

function scene.load()
    -- Temporarily disabled menu music due to build issues
    -- scene.menu_music = love.audio.newSource("assets/sounds/menu_music.ogg", "stream")
    -- scene.menu_music:setLooping(true)
    -- scene.menu_music:setVolume(0.5)
    -- scene.menu_music:play()
end

function scene.set(name)
    -- Temporarily disabled menu music due to build issues
    -- if name == "menu" then
    --     if scene.menu_music then
    --         scene.menu_music:play()
    --     end
    -- else
    --     if scene.menu_music then
    --         scene.menu_music:stop()
    --     end
    -- end
    scene.current = name
end

return scene
