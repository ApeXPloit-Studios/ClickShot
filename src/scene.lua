local scene = {}
scene.current = "menu"

-- Store music source at scene level to avoid circular dependency
scene.menu_music = nil

function scene.load()
    print("Loading menu music...")
    -- Initialize menu music
    scene.menu_music = love.audio.newSource("assets/sounds/menu_music.ogg", "stream")
    if not scene.menu_music then
        print("Failed to load menu music!")
        return
    end
    print("Menu music loaded successfully")
    scene.menu_music:setLooping(true)
    scene.menu_music:setVolume(0.5)  -- Set volume to 50%
    scene.menu_music:play()  -- Start playing immediately since we start in menu
    print("Menu music started playing")
end

function scene.set(name)
    print("Switching to scene: " .. name)
    -- Handle music when switching scenes
    if name == "menu" then
        -- Start menu music if it exists
        if scene.menu_music then
            print("Starting menu music")
            scene.menu_music:play()
        else
            print("Menu music not found when trying to play")
        end
    else
        -- Stop menu music if it exists
        if scene.menu_music then
            print("Stopping menu music")
            scene.menu_music:stop()
        end
    end
    
    scene.current = name
end

return scene
