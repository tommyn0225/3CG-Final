-- src/board.lua
local Board = {}
Board.__index = Board

function Board.new()
    local self = setmetatable({}, Board)
    self.maxSlots = 4
    -- slots[playerId][locationIdx] = list of Cards
    self.slots = {
        [1] = { {}, {}, {} },
        [2] = { {}, {}, {} },
    }
    return self
end

function Board:placeCard(pid, locIdx, card)
    if #self.slots[pid][locIdx] < self.maxSlots then
        table.insert(self.slots[pid][locIdx], card)
        return true
    end
    return false
end

function Board:totalPower(pid, locIdx)
    local sum = 0
    for _, c in ipairs(self.slots[pid][locIdx]) do
        sum = sum + c.power
    end
    return sum
end

return Board
