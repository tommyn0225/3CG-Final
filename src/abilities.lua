-- src/abilities.lua
local abilities = {}

-- Zeus: Lower the power of each card in the opponent's hand by 1
function abilities.zeus(game, sourcePlayer, targetPlayer, sourceCard, context)
    for _, card in ipairs(targetPlayer.hand) do
        if card.addPower then
            card:addPower(-1)
        else
            card.power = card.power - 1
        end
    end
end

-- Midas: Set ALL cards in the same location to 3 power
function abilities.midas(game, sourcePlayer, targetPlayer, sourceCard, context)
    local loc = context.location
    for _, card in ipairs(game.board.slots[sourcePlayer.id][loc]) do
        if card.setPower then
            card:setPower(3)
        else
            card.power = 3
        end
    end
end

-- Hermes: Moves to another location (random valid location)
function abilities.hermes(game, sourcePlayer, targetPlayer, sourceCard, context)
    local currentLoc = context.location
    local possible = {}
    for loc = 1, 3 do
        if loc ~= currentLoc and #game.board.slots[sourcePlayer.id][loc] < game.board.maxSlots then
            table.insert(possible, loc)
        end
    end
    if #possible > 0 then
        -- Remove from current location
        for i, c in ipairs(game.board.slots[sourcePlayer.id][currentLoc]) do
            if c == sourceCard then
                table.remove(game.board.slots[sourcePlayer.id][currentLoc], i)
                break
            end
        end
        -- Add to new location
        local newLoc = possible[math.random(#possible)]
        table.insert(game.board.slots[sourcePlayer.id][newLoc], sourceCard)
    end
end

-- Hydra: Add two copies to your hand when this card is discarded (handled on discard)
function abilities.hydra(game, sourcePlayer, targetPlayer, sourceCard, context)
    -- Only trigger if context.discarded is true
    if not context or not context.discarded then return end
    local hydraDef = nil
    for _, def in ipairs(require("src/constants").CARD_DEFS) do
        if def.id == "hydra" then hydraDef = def break end
    end
    if not hydraDef then return end
    local Card = require "src/card"
    local toAdd = math.min(2, 7 - #sourcePlayer.hand)
    for i = 1, toAdd do
        local newHydra = Card.new(hydraDef)
        newHydra.ownerId = sourcePlayer.id
        table.insert(sourcePlayer.hand, newHydra)
    end
end

-- Aphrodite: Lower the power of each enemy card here by 1
function abilities.aphrodite(game, sourcePlayer, targetPlayer, sourceCard, context)
    local loc = context.location
    for _, card in ipairs(game.board.slots[targetPlayer.id][loc]) do
        if card.addPower then
            card:addPower(-1)
        else
            card.power = card.power - 1
        end
    end
end

-- Athena: Gain +1 power when you play another card here (not a reveal ability)
function abilities.athena(game, sourcePlayer, targetPlayer, sourceCard, context)
    -- No-op for reveal
end

-- Apollo: Gain +1 mana next turn
function abilities.apollo(game, sourcePlayer, targetPlayer, sourceCard, context)
    sourcePlayer.nextTurnMana = (sourcePlayer.nextTurnMana or 0) + 1
    sourceCard.manaChange = (sourceCard.manaChange or 0) + 1 -- For UI feedback
end

-- Hades: Gain +2 power for each card in your discard pile
function abilities.hades(game, sourcePlayer, targetPlayer, sourceCard, context)
    local discardCount = #sourcePlayer.deck.discardPile
    local gain = 2 * discardCount
    if sourceCard.addPower then
        sourceCard:addPower(gain)
    else
        sourceCard.power = sourceCard.power + gain
    end
end

-- Daedalus: Add a Wooden Cow to each other location
function abilities.daedalus(game, sourcePlayer, targetPlayer, sourceCard, context)
    local currentLoc = context.location
    local Card = require "src/card"
    local cowDef = nil
    for _, def in ipairs(require("src/constants").CARD_DEFS) do
        if def.id == "wooden_cow" then cowDef = def break end
    end
    for loc = 1, 3 do
        if loc ~= currentLoc and #game.board.slots[sourcePlayer.id][loc] < game.board.maxSlots then
            local newCow = Card.new(cowDef)
            newCow.ownerId = sourcePlayer.id
            newCow:flip(true)
            table.insert(game.board.slots[sourcePlayer.id][loc], newCow)
        end
    end
end

-- Ares: Gain +2 power for each enemy card here
function abilities.ares(game, sourcePlayer, targetPlayer, sourceCard, context)
    local loc = context.location
    local enemyCount = #game.board.slots[targetPlayer.id][loc]
    local gain = 2 * enemyCount
    if sourceCard.addPower then
        sourceCard:addPower(gain)
    else
        sourceCard.power = sourceCard.power + gain
    end
end

-- Demeter: Both players draw a card
function abilities.demeter(game, sourcePlayer, targetPlayer, sourceCard, context)
    -- Draw for source player
    if #sourcePlayer.hand < 7 and #sourcePlayer.deck.cards > 0 then
        local card = sourcePlayer.deck:drawOne()
        card.ownerId = sourcePlayer.id
        table.insert(sourcePlayer.hand, card)
    end
    -- Draw for target player
    if #targetPlayer.hand < 7 and #targetPlayer.deck.cards > 0 then
        local card = targetPlayer.deck:drawOne()
        card.ownerId = targetPlayer.id
        table.insert(targetPlayer.hand, card)
    end
end

-- Ship of Theseus: Add a copy with +1 power to your hand
function abilities.ship_of_theseus(game, sourcePlayer, targetPlayer, sourceCard, context)
    if #sourcePlayer.hand < 7 then
        local Card = require "src/card"
        local newCard = Card.new(sourceCard.def)
        newCard.ownerId = sourcePlayer.id
        newCard:addPower(1)  -- Add +1 power to the copy
        table.insert(sourcePlayer.hand, newCard)
    end
end

-- Sword of Damocles: Loses 1 power if not winning this location
function abilities.sword_of_damocles(game, sourcePlayer, targetPlayer, sourceCard, context)
    local loc = context.location
    local sourcePower = game.board:totalPower(sourcePlayer.id, loc)
    local targetPower = game.board:totalPower(targetPlayer.id, loc)
    
    if sourcePower <= targetPower then
        if sourceCard.addPower then
            sourceCard:addPower(-1)
        else
            sourceCard.power = sourceCard.power - 1
        end
    end
end

-- Persephone: Discard the lowest power card in your hand
function abilities.persephone(game, sourcePlayer, targetPlayer, sourceCard, context)
    if #sourcePlayer.hand > 0 then
        local lowestCard = nil
        local lowestPower = math.huge
        local lowestIndex = nil
        
        -- Find the lowest power card
        for i, card in ipairs(sourcePlayer.hand) do
            if card.power < lowestPower then
                lowestPower = card.power
                lowestCard = card
                lowestIndex = i
            end
        end
        
        -- Discard the lowest power card
        if lowestCard then
            table.remove(sourcePlayer.hand, lowestIndex)
            sourcePlayer.deck:discard(lowestCard)
        end
    end
end

-- Dionysus: Gain +2 power for each of your other cards here
function abilities.dionysus(game, sourcePlayer, targetPlayer, sourceCard, context)
    local loc = context.location
    local otherCards = 0
    
    -- Count other cards at the same location
    for _, card in ipairs(game.board.slots[sourcePlayer.id][loc]) do
        if card ~= sourceCard then
            otherCards = otherCards + 1
        end
    end
    
    local gain = 2 * otherCards
    if sourceCard.addPower then
        sourceCard:addPower(gain)
    else
        sourceCard.power = sourceCard.power + gain
    end
end

return abilities 