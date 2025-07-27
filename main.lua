local Board = require "board"

function love.load()
    love.window.setTitle("2048 (minimal, classic)")
    love.window.setMode(400, 480)
    board = Board.new(4, 4)
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end

    if key == "up" or key == "down" or key == "left" or key == "right" then
        if not board:isGameOver() then
            local moved = board:move(key)
            if moved then
                board:addRandomTile()
            end
        end
    elseif key == "r" then
        board:reset()
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
