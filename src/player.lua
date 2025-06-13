-- src/player.lua
local Player = {}
Player.__index = Player

local Deck = require "src/deck"

function Player.new(id, isAI)
    local self = setmetatable({}, Player)
    self.id    = id
    self.isAI  = isAI or false
    self.deck  = Deck.new(require("src/constants").CARD_DEFS)
    self.hand  = {}
    self.mana  = 0
    self.score = 0
    self.nextTurnMana = 0
    return self
end

function Player:drawStartingHand()
    for i = 1, 3 do
        self:drawTurnCard()
    end
end

function Player:drawTurnCard()
    if #self.hand < 7 and #self.deck.cards > 0 then
        local card = self.deck:drawOne()
        card.ownerId = self.id
        table.insert(self.hand, card)
    end
end

function Player:canPlay(card)
    return card.cost <= self.mana
end

function Player:playCard(card, x, y, board)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local laneGap = w * 0.02
    local laneW = (w - 4 * laneGap) / 3
    local laneY = h * 0.15
    local laneH = h * 0.55
    local rowY = laneY + laneH - (h * 0.2)
    local CARD_W = (laneW - (board.maxSlots - 1) * laneGap) / board.maxSlots

    -- Determine which location the card was dropped in
    for loc = 1, 3 do
        local laneX = laneGap + (loc - 1) * (laneW + laneGap)
        if x > laneX and x < laneX + laneW and y > rowY and y < rowY + (h * 0.2) then
            -- Check if the player can afford the card
            if self:canPlay(card) and #board.slots[self.id][loc] < board.maxSlots then
                self.mana = self.mana - card.cost
                card.ownerId = self.id
                card:flip(true)
                board:placeCard(self.id, loc, card)
                return true
            end
        end
    end
    return false
end

function Player:returnCardToHand(card, board)
    local foundLoc = nil
    local foundIndex = nil
    for loc = 1, 3 do
        for i, c in ipairs(board.slots[self.id][loc]) do
            if c == card then
                foundLoc = loc
                foundIndex = i
                break
            end
        end
        if foundLoc then break end
    end
    
    if foundLoc then
        table.remove(board.slots[self.id][foundLoc], foundIndex)
        table.insert(self.hand, card)
        self.mana = self.mana + card.cost
        return true
    end
    return false
end

function Player:moveCardOnBoard(card, fromLoc, fromSlot, toLoc, toSlot, board)
    if not self:canPlay(card) then
        return false
    end
    
    table.remove(board.slots[self.id][fromLoc], fromSlot)
    table.insert(board.slots[self.id][toLoc], toSlot, card)
    
    return true
end

function Player:stageRandom(board)
    local available = true
    while available do
        available = false
        local choices = {}
        for _, c in ipairs(self.hand) do
            if self:canPlay(c) then
                for loc = 1, 3 do
                    if #board.slots[self.id][loc] < board.maxSlots then
                        table.insert(choices, c)
                        break
                    end
                end
            end
        end
        if #choices > 0 then
            available = true
            local card = choices[math.random(#choices)]
            for i,c in ipairs(self.hand) do
                if c == card then table.remove(self.hand, i); break end
            end
            local locs = {}
            for loc=1,3 do
                if #board.slots[self.id][loc] < board.maxSlots then
                    table.insert(locs, loc)
                end
            end
            local loc = locs[math.random(#locs)]
            card.ownerId = self.id
            card:flip(false)
            board:placeCard(self.id, loc, card)
            self.mana = self.mana - card.cost
        end
    end
end

return Player
