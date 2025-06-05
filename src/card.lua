-- src/card.lua
local Card = {}
Card.__index = Card

local abilities = require "src/abilities"

function Card.new(def)
    local self = setmetatable({}, Card)
    self.def = def
    self.power = def.power
    self.cost = def.cost
    self.faceUp = false
    self.ownerId = nil
    self.powerChange = 0
    self.manaChange = 0 
    self.powerSetThisReveal = false
    return self
end

function Card:flip(faceUp)
    self.faceUp = faceUp
end

function Card:applyTrigger(trigger, game, context)
    if trigger == "onReveal" and self.def.ability then
        local abilityFn = abilities[self.def.ability]
        if abilityFn then
            local sourcePlayer = game.players[self.ownerId]
            local targetPlayer = game.players[self.ownerId == 1 and 2 or 1]
            abilityFn(game, sourcePlayer, targetPlayer, self, context or {})
        end
    end
end

function Card:addPower(amount)
    self.power = self.power + amount
    self.powerChange = self.powerChange + amount
    
    -- Log power change
    if amount ~= 0 then
        local game = require("src/game")
        local changeText = amount > 0 and "+" .. amount or amount
        game.gameLog:addEntry(string.format("%s's %s power changed by %s (now %d)", 
            self.ownerId == 1 and "Player" or "Enemy",
            self.def.name,
            changeText,
            self.power))
    end
end

function Card:addMana(amount)
    if self.ownerId then
        local player = game.players[self.ownerId]
        if player then
            player.mana = player.mana + amount
            self.manaChange = self.manaChange + amount
            
            -- Log mana change
            if amount ~= 0 then
                local game = require("src/game")
                local changeText = amount > 0 and "+" .. amount or amount
                game.gameLog:addEntry(string.format("%s's mana changed by %s (now %d)", 
                    self.ownerId == 1 and "Player" or "Enemy",
                    changeText,
                    player.mana))
            end
        end
    end
end

function Card:setPower(newPower)
    local oldPower = self.power
    self.power = newPower
    self.powerSetThisReveal = true
    
    -- Log power change
    if oldPower ~= newPower then
        local game = require("src/game")
        game.gameLog:addEntry(string.format("%s's %s power set to %d (was %d)", 
            self.ownerId == 1 and "Player" or "Enemy",
            self.def.name,
            newPower,
            oldPower))
    end
end

return Card
