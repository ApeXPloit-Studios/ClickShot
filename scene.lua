local scene = {}

scene.current = "menu" -- "game" or "menu"

function scene.set(name)
    scene.current = name
end

return scene
