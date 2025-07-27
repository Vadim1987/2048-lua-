local utils = {}

-- Traversal order: important for animation to work right (slide towards edge)
function utils.buildTraversals(rows, cols, direction)
    local order = {}
    if direction == "left" then
        for r=1,rows do for c=1,cols do table.insert(order, {r,c}) end end
    elseif direction == "right" then
        for r=1,rows do for c=cols,1,-1 do table.insert(order, {r,c}) end end
    elseif direction == "up" then
        for c=1,cols do for r=1,rows do table.insert(order, {r,c}) end end
    elseif direction == "down" then
        for c=1,cols do for r=rows,1,-1 do table.insert(order, {r,c}) end end
    end
    return order
end

function utils.delta(direction)
    if direction == "left" then return 0,-1
    elseif direction == "right" then return 0,1
    elseif direction == "up" then return -1,0
    elseif direction == "down" then return 1,0
    end
    return 0,0
end

return utils
