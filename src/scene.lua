local scene = {
    current = "menu",
    previous = nil,
    scenes = {"menu", "game", "save_select"},
    menu_music = nil,
    game_music = nil,
    audio = {
        muted = false,
        music_volume = 0.5,
        sfx_volume = 1.0
    },
    save_pending = false,  -- Flag to indicate a save is needed
    data_reload_pending = false  -- Flag to indicate data reload is needed
}

-- Centralized audio system:
-- This module handles all audio-related functionality, including:
-- - Music playback for different scenes
-- - Volume control for both music and sound effects
-- - Mute/unmute functionality
-- - Applying volume settings to individual sound effects

-- Safely load audio source
local function loadAudio(path, errorMsg)
    local success, source = pcall(function()
        return love.audio.newSource(path, "stream")
    end)
    
    if success then
        source:setLooping(true)
        return source
    else
        print(errorMsg .. ": " .. tostring(source))
        return nil
    end
end

-- Initialize scene system
function scene.load()
    -- Load mute state first
    scene.loadAudioState()
    
    -- Load menu music
    scene.menu_music = loadAudio(
        "assets/sounds/menu_music.ogg", 
        "Failed to load menu music"
    )
    
    -- Load game music (using same file if no separate game music exists)
    -- You can replace this with a different music file for the game
    scene.game_music = loadAudio(
        "assets/sounds/menu_music.ogg", 
        "Failed to load game music"
    )
    
    -- Set initial volume
    if scene.menu_music then
        scene.menu_music:setVolume(scene.audio.muted and 0 or scene.audio.music_volume)
    scene.menu_music:play()
end

    if scene.game_music then
        scene.game_music:setVolume(scene.audio.muted and 0 or scene.audio.music_volume)
    end
end

-- Load audio state from settings file
function scene.loadAudioState()
    -- Load volume and mute settings from user_settings.lua
    if love.filesystem.getInfo("user_settings.lua") then
        local user_settings = love.filesystem.load("user_settings.lua")()()
        if user_settings then
            scene.audio.music_volume = user_settings.music_volume or scene.audio.music_volume
            scene.audio.sfx_volume = user_settings.sfx_volume or scene.audio.sfx_volume
            
            -- Load mute state if it exists in the settings
            if user_settings.muted ~= nil then
                scene.audio.muted = user_settings.muted
            end
        end
    end
end

-- Save audio state to file
function scene.saveAudioState()
    -- Create settings string with volume and mute state
    local settings_str = string.format(
        [[return function() return { music_volume = %f, sfx_volume = %f, muted = %s } end]], 
        scene.audio.music_volume, 
        scene.audio.sfx_volume,
        scene.audio.muted and "true" or "false"
    )
    
    -- Write settings to file
    love.filesystem.write("user_settings.lua", settings_str)
end

-- Trigger a save game operation
function scene.triggerSaveGame()
    scene.save_pending = true
end

-- Check if a save is pending
function scene.isSavePending()
    return scene.save_pending
end

-- Clear the save pending flag
function scene.clearSavePending()
    scene.save_pending = false
end

-- Trigger a data reload operation
function scene.triggerDataReload()
    scene.data_reload_pending = true
end

-- Check if a data reload is pending
function scene.isDataReloadPending()
    return scene.data_reload_pending
end

-- Clear the data reload pending flag
function scene.clearDataReloadPending()
    scene.data_reload_pending = false
end

-- Change to a different scene
function scene.set(name)
    if not scene.isValidScene(name) then
        print("Warning: Attempted to set invalid scene: " .. tostring(name))
        return false
    end
    
    scene.previous = scene.current
    scene.current = name
    
    -- Handle music transitions between scenes
    scene.updateMusic()
    
    return true
end

-- Go back to the previous scene
function scene.goBack()
    if scene.previous then
        local temp = scene.current
        scene.current = scene.previous
        scene.previous = temp
        
        -- Handle music transitions
        scene.updateMusic()
        
        return true
    end
    return false
end

-- Check if a scene name is valid
function scene.isValidScene(name)
    for _, validScene in ipairs(scene.scenes) do
        if validScene == name then
            return true
        end
    end
    return false
end

-- Update music based on current scene
function scene.updateMusic()
    if scene.current == "menu" then
        -- Stop game music if playing
        if scene.game_music and scene.game_music:isPlaying() then
            scene.game_music:stop()
        end
        
        -- Start menu music if not playing
        if scene.menu_music and not scene.menu_music:isPlaying() then
            -- Reset the music to the beginning before playing
            scene.menu_music:seek(0)
            scene.menu_music:play()
        end
    elseif scene.current == "game" then
        -- Stop menu music if playing
        if scene.menu_music and scene.menu_music:isPlaying() then
            scene.menu_music:stop()
        end
        
        -- Start game music if not playing
        if scene.game_music and not scene.game_music:isPlaying() then
            -- Reset the music to the beginning before playing
            scene.game_music:seek(0)
            scene.game_music:play()
        end
    end
    
    -- Apply current volume settings
    scene.applyAudioState()
end

-- Set music volume
function scene.setMusicVolume(volume)
    scene.audio.music_volume = volume
    scene.applyAudioState()
    scene.saveAudioState()
end

-- Set sound effects volume
function scene.setSfxVolume(volume)
    scene.audio.sfx_volume = volume
    scene.applyAudioState()
    scene.saveAudioState()
end

-- Toggle mute state
function scene.toggleMute()
    scene.audio.muted = not scene.audio.muted
    scene.applyAudioState()
    scene.saveAudioState()
end

-- Function to check if audio is muted
function scene.isMuted()
    return scene.audio.muted
end

-- Apply current audio state (volumes and mute)
function scene.applyAudioState()
    -- Apply music volume
    local music_volume = scene.audio.muted and 0 or scene.audio.music_volume
    
    if scene.menu_music then
        scene.menu_music:setVolume(music_volume)
    end
    
    if scene.game_music then
        scene.game_music:setVolume(music_volume)
    end
end

-- Apply sound effect volume to a sound
function scene.applySfxVolume(sound)
    if not sound then return end
    
    local volume = scene.audio.muted and 0 or scene.audio.sfx_volume
    sound:setVolume(volume)
    return sound
end

-- Play a sound effect with proper volume
function scene.playSound(sound)
    if not sound then return end
    
    local sound_instance = sound:clone()
    scene.applySfxVolume(sound_instance)
    sound_instance:play()
    
    return sound_instance
end

return scene
