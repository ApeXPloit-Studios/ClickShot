local assets = {}

function assets.load()
    -- Gun (default sprite)
    local gun_img = love.graphics.newImage("assets/images/pistol/fire_pistol.png")
    gun_img:setFilter("nearest", "nearest")

    assets.images = {
        gun = gun_img
    }

    assets.sounds = {
        click = love.audio.newSource("assets/sounds/click.wav", "static")
    }

    assets.fonts = {
        regular = love.graphics.newFont("assets/fonts/PixelifySans-Regular.ttf", 24),
        bold    = love.graphics.newFont("assets/fonts/PixelifySans-Bold.ttf", 24),
        semi    = love.graphics.newFont("assets/fonts/PixelifySans-SemiBold.ttf", 24),
        medium  = love.graphics.newFont("assets/fonts/PixelifySans-Medium.ttf", 24)
    }
end

return assets
