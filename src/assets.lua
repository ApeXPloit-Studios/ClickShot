local assets = {}

-- Helper to safely load assets
local function safeLoad(loadFn, errorMsg)
    local ok, result = pcall(loadFn)
    if not ok then
        print(errorMsg .. ': ' .. tostring(result))
        return nil
    end
    return result
end

function assets.load()
    -- Sound Efects
    assets.sounds = {
        click = safeLoad(function()
            return love.audio.newSource("assets/sounds/click.wav", "static")
        end, "Failed to load click sound")
    }

    -- Fonts
    assets.fonts = {
        regular = safeLoad(function()
            return love.graphics.newFont("assets/fonts/PixelifySans-Regular.ttf", 24)
        end, "Failed to load regular font"),
        bold    = safeLoad(function()
            return love.graphics.newFont("assets/fonts/PixelifySans-Bold.ttf", 24)
        end, "Failed to load bold font"),
        semi    = safeLoad(function()
            return love.graphics.newFont("assets/fonts/PixelifySans-SemiBold.ttf", 24)
        end, "Failed to load semi font"),
        medium  = safeLoad(function()
            return love.graphics.newFont("assets/fonts/PixelifySans-Medium.ttf", 24)
        end, "Failed to load medium font"),
        title   = safeLoad(function()
            return love.graphics.newFont("assets/fonts/PixelifySans-Bold.ttf", 48)
        end, "Failed to load title font")
    }
end

return assets
