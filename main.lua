local Board = require "board"

function love.load()
    love.window.setTitle("2048 (Animated)")
    love.window.setMode(400, 480)
    board = Board.new(4, 4)
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
    if board.isAnimating then return end

    if key == "up" or key == "down" or key == "left" or key == "right" then
        if not board:isGameOver() then
            local moved = board:move(key)
            if moved then
                board:spawnAfterAnimation = true
            end
        end
    elseif key == "r" then
        board:reset()
    end
end

function love.update(dt)
    if board.isAnimating then
        board:update(dt)
    elseif board.spawnAfterAnimation then
        board:addRandomTile()
        board.spawnAfterAnimation = false
    end
end

function love.draw()
    board:draw(40, 80, 80)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.print("ESC: quit  |  R: restart", 80, 30)
    if board:isGameOver() then
        love.graphics.setColor(1, 0, 0)
        love.graphics.print("GAME OVER!", 120, 440, 0, 2, 2)
    end
end
