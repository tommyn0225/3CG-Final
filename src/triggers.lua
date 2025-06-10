-- src/triggers.lua
local triggers = {}

-- Helper function to get opponent's ID
local function getOpponentId(playerId)
    return playerId == 1 and 2 or 1
end

-- Helper function to get all cards in a location
local function getCardsInLocation(game, playerId, locationId)
    return game.board.slots[playerId][locationId]
end

-- Helper function to get all cards in opponent's hand
local function getOpponentHand(game, playerId)
    return game.players[getOpponentId(playerId)].hand
end

-- Helper function to add a card to hand
local function addCardToHand(game, playerId, cardDef)
    local Card = require "src/card"
    local newCard = Card.new(cardDef)
    newCard.ownerId = playerId
    table.insert(game.players[playerId].hand, newCard)
end

-- Helper function to discard a card
local function discardCard(game, playerId, locationId, cardIndex)
    local card = table.remove(game.board.slots[playerId][locationId], cardIndex)
    game.players[playerId].deck:discard(card)
    return card
end

-- Zeus: Lower the power of each card in your opponent's hand by 1.
triggers.zeus = function(card, game)
    local opponentId = getOpponentId(card.ownerId)
    for _, handCard in ipairs(getOpponentHand(game, opponentId)) do
        if handCard.addPower then
            handCard:addPower(-1)
        else
            handCard.power = handCard.power - 1
        end
    end
end

-- Hermes: Moves to another location.
triggers.hermes = function(card, game)
    -- Find current location
    local currentLoc = nil
    local currentIndex = nil
    for loc = 1, 3 do
        for i, c in ipairs(game.board.slots[card.ownerId][loc]) do
            if c == card then
                currentLoc = loc
                currentIndex = i
                break
            end
        end
        if currentLoc then break end
    end
    
    if currentLoc then
        -- Find all possible valid locations
        local possible = {}
        for loc = 1, 3 do
            if loc ~= currentLoc and #game.board.slots[card.ownerId][loc] < game.board.maxSlots then
                table.insert(possible, loc)
            end
        end
        
        -- If there are valid locations, move to a random one
        if #possible > 0 then
            local newLoc = possible[math.random(#possible)]
            -- Remove from current location
            table.remove(game.board.slots[card.ownerId][currentLoc], currentIndex)
            -- Add to new location
            table.insert(game.board.slots[card.ownerId][newLoc], card)
            -- Ensure card ownership is maintained
            card.ownerId = card.ownerId
            game.gameLog:addEntry(string.format("%s's Hermes moved from location %d to location %d", 
                card.ownerId == 1 and "Player" or "Enemy", currentLoc, newLoc))
        end
    end
end

-- Hydra: Add two copies to your hand when this card is discarded.
triggers.hydra = function(card, game)
    -- This trigger is handled in the discard phase
end

-- Midas: Set ALL cards in the same location to 3 power.
triggers.midas = function(card, game)
    local currentLoc = nil
    for loc = 1, 3 do
        for _, c in ipairs(game.board.slots[card.ownerId][loc]) do
            if c == card then
                currentLoc = loc
                break
            end
        end
        if currentLoc then break end
    end
    if currentLoc then
        for _, c in ipairs(game.board.slots[card.ownerId][currentLoc]) do
            c:setPower(3)
        end
    end
end

-- Aphrodite: Lower the power of each enemy card here by 1.
triggers.aphrodite = function(card, game)
    local currentLoc = nil
    for loc = 1, 3 do
        for _, c in ipairs(game.board.slots[card.ownerId][loc]) do
            if c == card then
                currentLoc = loc
                break
            end
        end
        if currentLoc then break end
    end
    if currentLoc then
        local opponentId = getOpponentId(card.ownerId)
        for _, c in ipairs(game.board.slots[opponentId][currentLoc]) do
            if c.addPower then
                c:addPower(-1)
            else
                c.power = c.power - 1
            end
        end
    end
end

-- Athena: Gain +1 power when you play another card here. (Handled in play phase, not reveal)
triggers.athena = function(card, game)
    -- This is handled in the play phase
end

-- Apollo: Gain +1 mana next turn.
triggers.apollo = function(card, game)
    game.players[card.ownerId].nextTurnMana = (game.players[card.ownerId].nextTurnMana or 0) + 1
    card.manaChange = (card.manaChange or 0) + 1 -- For UI feedback
end

-- Hades: Gain +2 power for each card in your discard pile.
triggers.hades = function(card, game)
    local discardCount = #game.players[card.ownerId].deck.discardPile
    local gain = 2 * discardCount
    card:addPower(gain)
end

-- Daedalus: Add a Wooden Cow to each other location.
triggers.daedalus = function(card, game)
    local currentLoc = nil
    for loc = 1, 3 do
        for _, c in ipairs(game.board.slots[card.ownerId][loc]) do
            if c == card then
                currentLoc = loc
                break
            end
        end
        if currentLoc then break end
    end
    if currentLoc then
        -- Add Wooden Cow to other locations
        for loc = 1, 3 do
            if loc ~= currentLoc and #game.board.slots[card.ownerId][loc] < game.board.maxSlots then
                local Card = require "src/card"
                local woodenCow = Card.new(require("src/constants").CARD_DEFS[1]) -- Wooden Cow is first in CARD_DEFS
                woodenCow.ownerId = card.ownerId
                table.insert(game.board.slots[card.ownerId][loc], woodenCow)
            end
        end
    end
end

-- Ares: Gain +2 power for each enemy card here.
triggers.ares = function(card, game)
    local currentLoc = nil
    for loc = 1, 3 do
        for _, c in ipairs(game.board.slots[card.ownerId][loc]) do
            if c == card then
                currentLoc = loc
                break
            end
        end
        if currentLoc then break end
    end
    if currentLoc then
        local opponentId = getOpponentId(card.ownerId)
        local enemyCount = #game.board.slots[opponentId][currentLoc]
        local gain = 2 * enemyCount
        card:addPower(gain)
    end
end

return triggers 