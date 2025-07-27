local Board = require "board"

-- Variables for mouse swipe gesture detection
local swipeStartX, swipeStartY = nil, nil
local isSwiping = false

function love.load()
    -- Set window title and size
    love.window.setTitle("2048 (Animated + Swipes)")
    love.window.setMode(400, 480)
    -- Initialize board (4x4)
    board = Board.new(4, 4)
end

function love.keypressed(key)
    -- Quit on ESC
    if key == "escape" then love.event.quit() end
    -- Block input if an animation is running
    if board.isAnimating then return end

    -- Arrow key controls
    if key == "up" or key == "down" or key == "left" or key == "right" then
        if not board:isGameOver() then
            local moved = board:move(key)
            -- Only spawn new tile if something actually moved
            if moved then
                board.spawnAfterAnimation = true
            end
        end
    -- Restart game
    elseif key == "r" then
        board:reset()
    end
end

function love.mousepressed(x, y, button)
    -- Start swipe gesture on left mouse button, only if no animation is running
    if button == 1 and not board.isAnimating then
        swipeStartX, swipeStartY = x, y
        isSwiping = true
    end
end

function love.mousereleased(x, y, button)
    -- Only handle if swipe was in progress and no animation is running
    if not isSwiping or board.isAnimating then return end
    isSwiping = false
    -- Calculate swipe vector
    local dx = x - swipeStartX
    local dy = y - swipeStartY
    local absdx = math.abs(dx)
    local absdy = math.abs(dy)
    local minSwipe = 40 -- Minimum swipe distance to register a gesture

    -- Ignore short swipes (could be a click or a mis-swipe)
    if absdx < minSwipe and absdy < minSwipe then
        return
    end

    -- Determine swipe direction: horizontal or vertical (whichever is stronger)
    local dir
    if absdx > absdy then
        dir = dx > 0 and "right" or "left"
    else
        dir = dy > 0 and "down" or "up"
    end

    -- Attempt move with detected direction
    if not board:isGameOver() then
        local moved = board:move(dir)
        if moved then
            board.spawnAfterAnimation = true
        end
    end
end

function love.update(dt)
    -- Update board animations if running
    if board.isAnimating then
        board:update(dt)
    -- After animation finishes, spawn new tile if needed
    elseif board.spawnAfterAnimation then
        board:addRandomTile()
        board.spawnAfterAnimation = false
    end
end

function love.draw()
    -- Draw the game board and tiles
    board:draw(40, 80, 80)
    -- Draw UI controls
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.print("ESC: quit  |  R: restart  |  Mouse: swipe to move", 40, 30)
    -- Draw game over text if needed
    if board:isGameOver() then
        love.graphics.setColor(1, 0, 0)
        love.graphics.print("GAME OVER!", 120, 440, 0, 2, 2)
    end
end

         
