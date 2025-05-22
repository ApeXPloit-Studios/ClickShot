local assets = require("assets")
local save = require("save")
local scene = require("scene")
local ui = require("ui")
local scale_manager = require("scale_manager")
local controller = require("controller")

local save_slot_menu = {
    visible = false,
    slots = {},
    selected_slot = nil,
    action = "load", -- "load" or "save" mode
    time = 0,        -- For title animation
    title_scale = 1, -- For title animation
    
    -- Button configuration
    left_button = { text = "Play", hover = false, _bounds = nil },
    back_button = { text = "Back", hover = false, _bounds = nil },
    delete_button = { text = "Delete", hover = false, _bounds = nil },
    
    -- Slots grid configuration
    grid = {
        columns = 2,
        rows = 5,
        slot_width = 250,
        slot_height = 50,
        padding = 15
    }
}

function save_slot_menu.load()
    -- Load save slot data
    save_slot_menu.refreshSlots()
end

function save_slot_menu.refreshSlots()
    save_slot_menu.slots = save.getSaveSlots()
    
    -- Update the selected slot to valid one if needed
    if save_slot_menu.selected_slot == nil or 
       save_slot_menu.selected_slot > save.getMaxSlots() then
        save_slot_menu.selected_slot = save.getActiveSlot()
    end
    
    -- Update button text based on selected slot
    save_slot_menu.updateButtonText()
    
    -- Update button bounds to ensure they're properly positioned
    save_slot_menu.updateButtonBounds()
end

function save_slot_menu.updateButtonText()
    if save_slot_menu.selected_slot and save_slot_menu.selected_slot <= #save_slot_menu.slots then
        local slot = save_slot_menu.slots[save_slot_menu.selected_slot]
        if slot.exists then
            -- If slot has a save, show Start Game instead of New Game
            if save_slot_menu.action == "load" then
                save_slot_menu.left_button.text = "Play"
            else
                save_slot_menu.left_button.text = "Save"
            end
        else
            -- If slot is empty, show New Game
            save_slot_menu.left_button.text = "New Game"
        end
    end
end

function save_slot_menu.show(action)
    save_slot_menu.visible = true
    save_slot_menu.action = action or "load"
    
    -- Update play button text based on action
    if save_slot_menu.action == "load" then
        save_slot_menu.left_button.text = "New Game"
    else
        save_slot_menu.left_button.text = "Save"
    end
    
    -- Ensure slots and bounds are properly initialized
    save_slot_menu.refreshSlots()
    
    
    -- Update button bounds after slots are refreshed
    save_slot_menu.updateButtonBounds()
end

function save_slot_menu.hide()
    save_slot_menu.visible = false
end

function save_slot_menu.updateButtonBounds()
    -- Calculate layout based on current window size
    local design_width = scale_manager.design_width
    local design_height = scale_manager.design_height
    
    -- Grid configuration
    local grid = save_slot_menu.grid
    local total_slots = save.getMaxSlots()
    
    -- Calculate the total grid size
    local grid_width = (grid.slot_width * grid.columns) + ((grid.columns + 1) * grid.padding)
    local grid_height = (grid.slot_height * grid.rows) + ((grid.rows + 1) * grid.padding)
    
    -- Calculate the grid position (centered)
    local grid_x = (design_width - grid_width) / 2
    local grid_y = (design_height - grid_height) / 2
    
    -- Set slot bounds
    for i, slot in ipairs(save_slot_menu.slots) do
        -- Calculate row and column for 2x5 grid
        local col = ((i - 1) % grid.columns) + 1
        local row = math.ceil(i / grid.columns)
        
        local x = grid_x + ((col - 1) * (grid.slot_width + grid.padding)) + grid.padding
        local y = grid_y + ((row - 1) * (grid.slot_height + grid.padding)) + grid.padding
        
        slot._bounds = {
            x = x,
            y = y,
            w = grid.slot_width,
            h = grid.slot_height
        }
    end
    
    -- Position action buttons at the bottom
    local button_width = 120
    local button_height = 40
    local button_spacing = 20
    local button_y = grid_y + grid_height + 30
    
    -- Center the back button
    save_slot_menu.back_button._bounds = {
        x = (design_width - button_width) / 2,
        y = button_y,
        w = button_width,
        h = button_height
    }
    
    -- Position left button to the left of back button
    save_slot_menu.left_button._bounds = {
        x = save_slot_menu.back_button._bounds.x - button_width - button_spacing,
        y = button_y,
        w = button_width,
        h = button_height
    }
    
    -- Position delete button to the right of back button
    save_slot_menu.delete_button._bounds = {
        x = save_slot_menu.back_button._bounds.x + button_width + button_spacing,
        y = button_y,
        w = button_width,
        h = button_height
    }
end

function save_slot_menu.update(dt)
    if not save_slot_menu.visible then return end
    
    -- Update title animation
    save_slot_menu.time = save_slot_menu.time + dt
    save_slot_menu.title_scale = 1 + 0.05 * math.sin(save_slot_menu.time * 2)
    
    -- Get mouse position in game coordinates
    local mx, my = ui.getCursorPosition()
    
    -- Update button hover states
    ui.updateButtonHover(save_slot_menu.left_button)
    ui.updateButtonHover(save_slot_menu.back_button)
    ui.updateButtonHover(save_slot_menu.delete_button)
    
    -- Update slot hover states
    for _, slot in ipairs(save_slot_menu.slots) do
        slot.hover = false
        if slot._bounds then
            slot.hover = ui.pointInRect(mx, my, slot._bounds)
        end
    end
end

function save_slot_menu.draw()
    if not save_slot_menu.visible then return end
    
    -- Draw semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, scale_manager.design_width, scale_manager.design_height)
    
    -- Draw title with animation
    love.graphics.setFont(assets.fonts.bold)
    love.graphics.setColor(1, 1, 1)
    local title = save_slot_menu.action == "load" and "Select Save Slot" or "Save"
    ui.drawAnimatedTitle(
        title, 
        scale_manager.design_width / 2, 
        150,
        save_slot_menu.title_scale,
        assets.fonts.bold,
        {centerX = true}
    )
    
    -- Draw slot grid
    love.graphics.setFont(assets.fonts.regular)
    
    for i, slot in ipairs(save_slot_menu.slots) do
        if slot._bounds then
            -- Highlight selected slot
            local is_selected = (i == save_slot_menu.selected_slot)
            
            -- Draw slot background
            if is_selected then
                love.graphics.setColor(0.4, 0.4, 0.7)
            elseif slot.hover then
                love.graphics.setColor(0.3, 0.3, 0.3)
            else
                love.graphics.setColor(0.2, 0.2, 0.2)
            end
            
            love.graphics.rectangle("fill", slot._bounds.x, slot._bounds.y, 
                                  slot._bounds.w, slot._bounds.h, 6, 6)
            
            -- Draw slot border
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.rectangle("line", slot._bounds.x, slot._bounds.y, 
                                  slot._bounds.w, slot._bounds.h, 6, 6)
            
            -- Draw slot text
            love.graphics.setColor(1, 1, 1)
            
            local slot_text = "Slot " .. i
            if not slot.exists then
                slot_text = slot_text .. " (Empty)"
            end
            
            -- Center text vertically
            local font = love.graphics.getFont()
            local text_height = font:getHeight()
            local text_y = slot._bounds.y + (slot._bounds.h - text_height) / 2
            
            love.graphics.print(slot_text, slot._bounds.x + 15, text_y)
        end
    end
    
    -- Draw action buttons based on context
    local showDeleteButton = false
    
    -- Only show delete button if selected slot has a save
    if save_slot_menu.selected_slot and save_slot_menu.slots[save_slot_menu.selected_slot] then
        showDeleteButton = save_slot_menu.slots[save_slot_menu.selected_slot].exists
    end
    
    -- Always draw left button (New Game or Start Game)
    ui.drawStaticButton(save_slot_menu.left_button, 
                     save_slot_menu.left_button._bounds.x, 
                     save_slot_menu.left_button._bounds.y, 
                     save_slot_menu.left_button._bounds.w, 
                     save_slot_menu.left_button._bounds.h)
    
    -- Always draw back button
    ui.drawStaticButton(save_slot_menu.back_button, 
                     save_slot_menu.back_button._bounds.x, 
                     save_slot_menu.back_button._bounds.y, 
                     save_slot_menu.back_button._bounds.w, 
                     save_slot_menu.back_button._bounds.h)
    
    -- Only draw delete button if selected slot has a save
    if showDeleteButton then
        ui.drawStaticButton(save_slot_menu.delete_button, 
                         save_slot_menu.delete_button._bounds.x, 
                         save_slot_menu.delete_button._bounds.y, 
                         save_slot_menu.delete_button._bounds.w, 
                         save_slot_menu.delete_button._bounds.h)
    end
end

function save_slot_menu.mousepressed(x, y, button)
    if not save_slot_menu.visible then return end
    
    -- Get controller-aware cursor position
    local mx, my
    if controller.usingController then
        mx, my = controller.cursorX, controller.cursorY
    else
        mx, my = x, y
    end
    
    -- Check if a slot was clicked
    for i, slot in ipairs(save_slot_menu.slots) do
        if slot.hover and slot._bounds then
            save_slot_menu.selected_slot = i
            save_slot_menu.updateButtonText()
            return
        end
    end
    
    -- Check if left button was clicked (New Game or Start Game)
    if save_slot_menu.left_button.hover then
        if save_slot_menu.selected_slot then
            -- Set the active slot - this affects which save file is used
            save.setActiveSlot(save_slot_menu.selected_slot)
            
            -- If slot doesn't have a save and we're in load mode, initialize a new game
            local slot = save_slot_menu.slots[save_slot_menu.selected_slot]
            if slot and not slot.exists and save_slot_menu.action == "load" then
                -- Create a new game with default values
                save.initNewGame(save_slot_menu.selected_slot)
            end
            
            -- If in save mode, save the game data to the selected slot
            if save_slot_menu.action == "save" then
                -- Notify the game module to save to this slot
                scene.triggerSaveGame()
            end
            
            -- Start/resume game
            save_slot_menu.hide()
            scene.current = "game"
            
            -- Reload game data if the game is already running
            scene.triggerDataReload()
            
            -- Play click sound
            if assets.sounds.click then
                scene.playSound(assets.sounds.click)
            end
        end
        return
    end
    
    -- Check if delete button was clicked (only if slot has save)
    if save_slot_menu.delete_button.hover then
        local slot_to_delete = save_slot_menu.selected_slot
        if slot_to_delete and slot_to_delete >= 1 and slot_to_delete <= save.getMaxSlots() then
            -- Delete the slot data
            save.deleteSlot(slot_to_delete)
            
            -- Refresh slot display
            save_slot_menu.slots = save.getSaveSlots()
            save_slot_menu.updateButtonText()
            save_slot_menu.updateButtonBounds()
            
            -- Play click sound
            if assets.sounds.click then
                scene.playSound(assets.sounds.click)
            end
        end
        return
    end
    
    -- Check if back button was clicked
    if save_slot_menu.back_button.hover then
        save_slot_menu.hide()
        
        -- Go back to main menu if in load mode
        if save_slot_menu.action == "load" then
            scene.current = "menu"
        end
        
        -- Play click sound
        if assets.sounds.click then
            scene.playSound(assets.sounds.click)
        end
        return
    end
end

-- Helper function to handle resize
function save_slot_menu.handleResize()
    save_slot_menu.updateButtonBounds()
end

return save_slot_menu 