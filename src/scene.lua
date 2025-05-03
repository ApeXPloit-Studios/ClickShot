local scene = {}
scene.current = "menu"

-- Store music source at scene level to avoid circular dependency
scene.menu_music = nil

function scene.load()
    scene.menu_music = love.audio.newSource("assets/sounds/menu_music.ogg", "stream")
    scene.menu_music:setLooping(true)
    scene.menu_music:setVolume(0.5)
    scene.menu_music:play()
end

function scene.set(name)
    scene.current = name
end

return scene
