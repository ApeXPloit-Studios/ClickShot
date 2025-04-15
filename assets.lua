local assets = {}

function assets.load()
    assets.images = {
        gun = love.graphics.newImage("assets/images/fire_pistol.png")
    }

    assets.sounds = {
        click = love.audio.newSource("assets/sounds/click.wav", "static")
    }
end

return assets
