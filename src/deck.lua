-- src/deck.lua
local Deck = {}
Deck.__index = Deck

local Card = require "src/card"
local utils = require "src/utils"

function Deck.new(cardDefs)
    local self = setmetatable({}, Deck)
    self.cards       = {}
    self.discardPile = {}
    for _, def in ipairs(cardDefs) do
        -- one copy per definition; extend as needed
        table.insert(self.cards, Card.new(def))
    end
    utils.shuffle(self.cards)
    return self
end

function Deck:drawOne()
    return table.remove(self.cards)
end

function Deck:discard(card)
    table.insert(self.discardPile, card)
end

return Deck
