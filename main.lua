function love.mousepressed(x, y, button)
    if button == 1 then  -- Left mouse button
        if gun.isClicked(x, y) then
            if gun.shoot() then
                -- Handle successful click
                local equipped = workbench.getEquipped()
                if equipped then
                    -- Play animation based on equipped item
                    if equipped.type == "barrel" then
                        -- Barrel-specific animation
                        love.audio.play(assets.sounds.barrel_click)
                    elseif equipped.type == "grip" then
                        -- Grip-specific animation
                        love.audio.play(assets.sounds.grip_click)
                    else
                        -- Default click sound
                        love.audio.play(assets.sounds.click)
                    end
                end
            end
        end
    end
end

function love.draw()
    -- ... existing code ...
    
    -- Draw gun
    gun.draw()
    
    -- Draw workbench
    workbench.draw()
    
    -- Draw UI
    ui.draw()
end 