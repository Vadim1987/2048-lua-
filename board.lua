local Board = {}
Board.__index = Board

local utils = require "utils"

local MOVE_TIME = 0.14    -- Time for tile slide animation (seconds)
local MERGE_TIME = 0.14   -- Time for merge "pop" animation

function Board.new(rows, cols)
    local self = setmetatable({}, Board)
    self.rows = rows
    self.cols = cols
    self:reset()
    return self
end

-- Resets the board to a new game, initializes history and replay state
function Board:reset()
    self.tiles = {}
    self.grid = {}
    self.merges = {}
    self.isAnimating = false
    self.spawnAfterAnimation = false
    self.history = {}      -- Move history stack for undo and replay
    self.replayMode = false
    self.replayIndex = 1
    self.replayTimer = 0
    for r = 1, self.rows do
        self.grid[r] = {}
        for c = 1, self.cols do
            self.grid[r][c] = 0
        end
    end
    self:addRandomTile()
    self:addRandomTile()
    self:syncTiles()
    self:pushHistory() -- Save initial state
end

-- Deep-copies current grid and adds it to history
function Board:pushHistory()
    local gridCopy = {}
    for r=1,self.rows do
        gridCopy[r] = {}
        for c=1,self.cols do
            gridCopy[r][c] = self.grid[r][c]
        end
    end
    table.insert(self.history, gridCopy)
end

-- Restores the previous state from history (undo)
function Board:undo()
    if #self.history > 1 and not self.isAnimating then
        table.remove(self.history) -- Remove current state
        local last = self.history[#self.history]
        for r=1,self.rows do for c=1,self.cols do
            self.grid[r][c] = last[r][c]
        end end
        self:syncTiles()
    end
end

-- Synchronizes tiles for animation from the grid
function Board:syncTiles()
    self.tiles = {}
    for r = 1, self.rows do
        for c = 1, self.cols do
            local val = self.grid[r][c]
            if val ~= 0 then
                table.insert(self.tiles, {
                    value = val,
                    r = r, c = c,
                    screen_r = r, screen_c = c,
                    anim = nil, -- {from_r, from_c, to_r, to_c, t, tmax, merging}
                    scale = 1.0,
                })
            end
        end
    end
end

-- Adds a new random tile (2 or 4) to an empty cell
function Board:addRandomTile()
    local empties = {}
    for r = 1, self.rows do
        for c = 1, self.cols do
            if self.grid[r][c] == 0 then
                table.insert(empties, {r, c})
            end
        end
    end
    if #empties == 0 then return end
    local idx = love.math.random(#empties)
    local rc = empties[idx]
    self.grid[rc[1]][rc[2]] = love.math.random(1,2)*2 -- spawn 2 or 4
    self:syncTiles()
end

-- Main move logic: slides and merges tiles, marks tiles for animation
function Board:move(direction)
    if self.isAnimating then return false end
    local moved = false
    local traversals = utils.buildTraversals(self.rows, self.cols, direction)
    local mergedThisMove = {}
    local newGrid = {}
    for r=1,self.rows do newGrid[r]={} for c=1,self.cols do newGrid[r][c]=self.grid[r][c] end end
    self.merges = {}

    local function positionAvailable(r, c)
        return newGrid[r][c] == 0
    end

    for _, rc in ipairs(traversals) do
        local r, c = rc[1], rc[2]
        local val = self.grid[r][c]
        if val ~= 0 then
            local next_r, next_c = r, c
            local prev_r, prev_c = r, c
            repeat
                prev_r, prev_c = next_r, next_c
                local dr, dc = utils.delta(direction)
                local test_r, test_c = prev_r + dr, prev_c + dc
                if test_r >= 1 and test_r <= self.rows and test_c >= 1 and test_c <= self.cols then
                    if newGrid[test_r][test_c] == 0 then
                        next_r, next_c = test_r, test_c
                    elseif newGrid[test_r][test_c] == val and not mergedThisMove[test_r .. "," .. test_c] then
                        next_r, next_c = test_r, test_c
                        mergedThisMove[next_r .. "," .. next_c] = true
                        self.merges[#self.merges+1] = {r=next_r, c=next_c}
                        break
                    else
                        break
                    end
                else
                    break
                end
            until false

            if (next_r ~= r or next_c ~= c) then
                moved = true
                -- Animate: mark tile for movement
                for _, tile in ipairs(self.tiles) do
                    if tile.r == r and tile.c == c and tile.value == val then
                        tile.anim = {
                            from_r = r, from_c = c,
                            to_r = next_r, to_c = next_c,
                            t = 0, tmax = MOVE_TIME,
                            merging = newGrid[next_r][next_c] == val,
                        }
                        break
                    end
                end
            end

            -- Place in new grid
            if newGrid[next_r][next_c] == val and not mergedThisMove[next_r .. "," .. next_c] then
                newGrid[next_r][next_c] = val
            elseif newGrid[next_r][next_c] == val and mergedThisMove[next_r .. "," .. next_c] then
                newGrid[next_r][next_c] = val * 2
            elseif newGrid[next_r][next_c] == 0 then
                newGrid[next_r][next_c] = val
            end
            if not (next_r == r and next_c == c) then
                newGrid[r][c] = 0
            end
        end
    end

    if moved then
        self.isAnimating = true
        self.animationTimer = 0
        self.animationGrid = newGrid
    else
        self:syncTiles()
    end
    return moved
end

-- Handles tile animation (sliding and merge "pop")
function Board:update(dt)
    if not self.isAnimating then return end
    local still_animating = false

    -- Animate movement
    for _, tile in ipairs(self.tiles) do
        if tile.anim then
            tile.anim.t = math.min(tile.anim.t + dt, tile.anim.tmax)
            local p = tile.anim.t / tile.anim.tmax
            tile.screen_r = tile.anim.from_r + (tile.anim.to_r - tile.anim.from_r) * p
            tile.screen_c = tile.anim.from_c + (tile.anim.to_c - tile.anim.from_c) * p
            if tile.anim.t < tile.anim.tmax then
                still_animating = true
            else
                tile.screen_r = tile.anim.to_r
                tile.screen_c = tile.anim.to_c
                if tile.anim.merging then
                    tile.scale = 1.2 -- merge "pop" effect
                    tile.merging = true
                end
                tile.anim = nil
            end
        end
    end

    -- Animate merge pop (scale)
    for _, tile in ipairs(self.tiles) do
        if tile.merging then
            tile.scale = tile.scale - dt * 1.4
            if tile.scale <= 1.0 then
                tile.scale = 1.0
                tile.merging = false
            else
                still_animating = true
            end
        end
    end

    if not still_animating then
        self.isAnimating = false
        self.grid = self.animationGrid
        self:syncTiles()
    end
end

-- Checks if there are any possible moves left
function Board:isGameOver()
    for r=1,self.rows do for c=1,self.cols do
        if self.grid[r][c] == 0 then return false end
    end end
    for r=1,self.rows do for c=1,self.cols-1 do
        if self.grid[r][c] == self.grid[r][c+1] then return false end
    end end
    for c=1,self.cols do for r=1,self.rows-1 do
        if self.grid[r][c] == self.grid[r+1][c] then return false end
    end end
    return true
end

-- Draws the board and all animated tiles
function Board:draw(x, y, cell)
    love.graphics.setColor(0.8,0.7,0.5)
    love.graphics.rectangle("fill", x-5, y-5, cell*self.cols+10, cell*self.rows+10, 8,8)
    -- Draw tiles
    for _, tile in ipairs(self.tiles) do
        local draw_r = tile.screen_r or tile.r
        local draw_c = tile.screen_c or tile.c
        local val = tile.value
        local scale = tile.scale or 1.0
        if val == 0 then
            love.graphics.setColor(0.9,0.85,0.7)
        else
            love.graphics.setColor(0.9,0.7-(val/2048)*0.6,0.3)
        end
        local w = (cell-4)*scale
        local h = (cell-4)*scale
        love.graphics.rectangle("fill",
            x + (draw_c-1)*cell + (cell-4)/2*(1-scale),
            y + (draw_r-1)*cell + (cell-4)/2*(1-scale),
            w, h, 6, 6)
        if val ~= 0 then
            love.graphics.setColor(0.1,0.1,0.1)
            love.graphics.printf(tostring(val),
                x + (draw_c-1)*cell,
                y + (draw_r-1)*cell + cell/2 - 12,
                cell-4, "center")
        end
    end
end

return Board

                     
        
  
        



 

