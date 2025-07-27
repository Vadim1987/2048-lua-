local Board = require "board"

-- For swipe gestures
local swipeStartX, swipeStartY = nil, nil
local isSwiping = false

-- For replay mode
local isReplaying = false

function love.load()
    love.window.setTitle("2048 (Animated + Swipes + Undo + Replay)")
    love.window.setMode(400, 480)
    board = Board.new(4, 4)
end

function love.keypressed(key)
    -- Quit on ESC
    if key == "escape" then love.event.quit() end

    -- Block input during animation or replay
    if board.isAnimating or isReplaying then return end

    -- Move tiles with arrow keys
    if key == "up" or key == "down" or key == "left" or key == "right" then
        if not board:isGameOver() then
            board:pushHistory() -- Save state for undo/replay
            local moved = board:move(key)
            if moved then
                board.spawnAfterAnimation = true
            else
                table.remove(board.history) -- Don't save if no move
            end
        end

    -- Undo last move (U or Z)
    elseif key == "u" or key == "z" then
        board:undo()

    -- Replay whole game (R)
    elseif key == "r" then
        if #board.history > 1 then
            isReplaying = true
            board.replayMode = true
            board.replayIndex = 1
            board.replayTimer = 0
        else
            board:reset()
        end
    end
end

function love.mousepressed(x, y, button)
    -- Start swipe gesture on left mouse button (if not animating/replaying)
    if button == 1 and not board.isAnimating and not isReplaying then
        swipeStartX, swipeStartY = x, y
        isSwiping = true
    end
end

function love.mousereleased(x, y, button)
    -- Ignore if not swiping or in animation/replay
    if not isSwiping or board.isAnimating or isReplaying then return end
    isSwiping = false
    -- Calculate swipe distance
    local dx = x - swipeStartX
    local dy = y - swipeStartY
    local absdx = math.abs(dx)
    local absdy = math.abs(dy)
    local minSwipe = 40 -- Minimum swipe distance

    -- Ignore short swipes
    if absdx < minSwipe and absdy < minSwipe then
        return
    end

    -- Determine direction (horizontal/vertical)
    local dir
    if absdx > absdy then
        dir = dx > 0 and "right" or "left"
    else
        dir = dy > 0 and "down" or "up"
    end

    -- Attempt move in detected direction
    if not board:isGameOver() then
        board:pushHistory()
        local moved = board:move(dir)
        if moved then
            board.spawnAfterAnimation = true
        else
            table.remove(board.history)
        end
    end
end

function love.update(dt)
    -- Handle replay mode: advance board through history with animation delay
    if isReplaying then
        board.replayTimer = board.replayTimer + dt
        if board.replayTimer > 0.18 then
            board.replayTimer = 0
            board.replayIndex = board.replayIndex + 1
            if board.replayIndex > #board.history then
                isReplaying = false
                board.replayMode = false
                return
            end
            -- Set board state to next history step
            local state = board.history[board.replayIndex]
            for r=1,board.rows do for c=1,board.cols do
                board.grid[r][c] = state[r][c]
            end end
            board:syncTiles()
        end

    -- Handle ongoing animation
    elseif board.isAnimating then
        board:update(dt)

    -- After animation, spawn new tile if needed
    elseif board.spawnAfterAnimation then
        board:addRandomTile()
        board.spawnAfterAnimation = false
    end
end

function love.draw()
    -- Draw the board and tiles
    board:draw(40, 80, 80)
    -- Draw UI instructions
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.print("ESC: quit  |  R: replay  |  U/Z: undo  |  Mouse: swipe", 30, 30)
    -- Show REPLAY or GAME OVER messages
    if isReplaying then
        love.graphics.setColor(0.2, 0.2, 1)
        love.graphics.print("REPLAYING...", 130, 440, 0, 2, 2)
    elseif board:isGameOver() then
        love.graphics.setColor(1, 0, 0)
        love.graphics.print("GAME OVER!", 120, 440, 0, 2, 2)
    end
end


 
   






         
