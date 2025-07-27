local Board = {}
Board.__index = Board

local utils = require "utils"

function Board.new(rows, cols)
    local self = setmetatable({}, Board)
    self.rows = rows
    self.cols = cols
    self:reset()
    return self
end

function Board:reset()
    self.grid = {}
    for r = 1, self.rows do
        self.grid[r] = {}
        for c = 1, self.cols do
            self.grid[r][c] = 0
        end
    end
    self:addRandomTile()
    self:addRandomTile()
end

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
    self.grid[rc[1]][rc[2]] = love.math.random(1,2) * 2 -- spawn 2 or 4
end

function Board:move(direction)
    local moved = false
    local moved_grid = {}
    for r = 1, self.rows do
        moved_grid[r] = {}
        for c = 1, self.cols do
            moved_grid[r][c] = self.grid[r][c]
        end
    end

    local function slideLine(line)
        local merged = {}
        local result = {}
        local last = nil
        for i, v in ipairs(line) do
            if v ~= 0 then
                if last and last == v and not merged[#result] then
                    result[#result] = v*2
                    merged[#result] = true
                    last = nil
                else
                    table.insert(result, v)
                    merged[#result] = false
                    last = v
                end
            end
        end
        while #result < #line do
            table.insert(result, 0)
        end
        return result
    end

    local function reverse(t)
        local tt = {}
        for i = #t,1,-1 do table.insert(tt, t[i]) end
        return tt
    end

    if direction == "left" then
        for r=1,self.rows do
            local line = {}
            for c=1,self.cols do table.insert(line, self.grid[r][c]) end
            local sl = slideLine(line)
            for c=1,self.cols do
                if self.grid[r][c] ~= sl[c] then moved = true end
                self.grid[r][c] = sl[c]
            end
        end
    elseif direction == "right" then
        for r=1,self.rows do
            local line = {}
            for c=1,self.cols do table.insert(line, self.grid[r][c]) end
            local sl = reverse(slideLine(reverse(line)))
            for c=1,self.cols do
                if self.grid[r][c] ~= sl[c] then moved = true end
                self.grid[r][c] = sl[c]
            end
        end
    elseif direction == "up" then
        for c=1,self.cols do
            local line = {}
            for r=1,self.rows do table.insert(line, self.grid[r][c]) end
            local sl = slideLine(line)
            for r=1,self.rows do
                if self.grid[r][c] ~= sl[r] then moved = true end
                self.grid[r][c] = sl[r]
            end
        end
    elseif direction == "down" then
        for c=1,self.cols do
            local line = {}
            for r=1,self.rows do table.insert(line, self.grid[r][c]) end
            local sl = reverse(slideLine(reverse(line)))
            for r=1,self.rows do
                if self.grid[r][c] ~= sl[r] then moved = true end
                self.grid[r][c] = sl[r]
            end
        end
    end

    return moved
end

function Board:isGameOver()
    -- Any zero?
    for r=1,self.rows do for c=1,self.cols do
        if self.grid[r][c] == 0 then return false end
    end end
    -- Any move possible?
    for r=1,self.rows do for c=1,self.cols-1 do
        if self.grid[r][c] == self.grid[r][c+1] then return false end
    end end
    for c=1,self.cols do for r=1,self.rows-1 do
        if self.grid[r][c] == self.grid[r+1][c] then return false end
    end end
    return true
end

function Board:draw(x, y, cell)
    local font = love.graphics.getFont()
    love.graphics.setColor(0.8,0.7,0.5)
    love.graphics.rectangle("fill", x-5, y-5, cell*self.cols+10, cell*self.rows+10, 8,8)
    for r=1,self.rows do
        for c=1,self.cols do
            local val = self.grid[r][c]
            if val == 0 then
                love.graphics.setColor(0.9,0.85,0.7)
            else
                love.graphics.setColor(0.9,0.7-(val/2048)*0.6,0.3)
            end
            love.graphics.rectangle("fill", x + (c-1)*cell, y + (r-1)*cell, cell-4, cell-4, 6,6)
            if val ~= 0 then
                love.graphics.setColor(0.1,0.1,0.1)
                love.graphics.printf(tostring(val), x + (c-1)*cell, y + (r-1)*cell + cell/2 - 12, cell-4, "center")
            end
        end
    end
end

return Board
