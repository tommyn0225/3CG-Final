-- src/game.lua
local Game = {}
Game.__index = Game

local constants = require "src/constants"
local Player    = require "src/player"
local Board     = require "src/board"
local AI        = require "src/ai"
local GameLog   = require "src/game_log"
local Deck      = require "src/deck"

function Game:init()
    -- Initialize basic game state
    self.state = "menu"
    self.gameLog = GameLog.new()
    self.discardedThisTurn = false
    
    -- Preload all card images
    for _, def in ipairs(constants.CARD_DEFS) do
        def.image = love.graphics.newImage("src/assets/images/" .. def.id .. ".png")
    end
end

function Game:startGame()
    self.players = { Player.new(1, false), Player.new(2, true) }
    self.board = Board.new()
    self.turn = 1
    self.state = "staging"
    self.targetScore = constants.TARGET_SCORE
    self.discardedThisTurn = false

    -- Deal starting hands, set initial mana
    for _, p in ipairs(self.players) do
        p:drawStartingHand()
        p.mana = self.turn
    end
    
    self.gameLog:addEntry("Game started!")
end

function Game:initWithCustomDeck(deckCounts)
    self.players = { Player.new(1, false), Player.new(2, true) }
    self.board = Board.new()
    self.turn = 1
    self.state = "staging"
    self.targetScore = constants.TARGET_SCORE
    self.discardedThisTurn = false

    -- Build custom deck for player 1
    local customDeck = {}
    for id, count in pairs(deckCounts) do
        for i = 1, count do
            -- Find the card definition
            for _, def in ipairs(constants.CARD_DEFS) do
                if def.id == id then
                    table.insert(customDeck, def)
                    break
                end
            end
        end
    end
    self.players[1].deck = Deck.new(customDeck)

    -- Deal starting hands, set initial mana
    for _, p in ipairs(self.players) do
        p:drawStartingHand()
        p.mana = self.turn
    end
    
    self.gameLog:addEntry("Game started with custom deck!")
end

function Game:getPhaseText()
    local texts = {
        staging  = "Your Turn",
        enemy    = "Enemy Turn",
        reveal   = "Reveal Cards",
        scoring  = "Scoring",
        gameover = "Game Over"
    }
    return texts[self.state] or ""
end

function Game:nextPhase()
    if self.state == "staging" then
        -- Flip all cards face down before AI turn
        for pid = 1, 2 do
            for loc = 1, 3 do
                for _, c in ipairs(self.board.slots[pid][loc]) do
                    if c then
                        c:flip(false)  -- Flip all cards face down
                    end
                end
            end
        end
        
        -- Reset discard flag for next turn
        self.discardedThisTurn = false
        
        -- AI stages its play
        self.state = "enemy"
        AI.stageRandom(self.players[2], self.board)
        self.gameLog:addEntry("Enemy is staging their cards...")

    elseif self.state == "enemy" then
        -- Reveal all cards, winner first per location
        self.state = "reveal"
        for loc = 1, 3 do
            local p1Power = self.board:totalPower(1, loc)
            local p2Power = self.board:totalPower(2, loc)
            local winner, loser
            if p1Power > p2Power then
                winner, loser = 1, 2
            elseif p2Power > p1Power then
                winner, loser = 2, 1
            else
                if math.random() < 0.5 then
                    winner, loser = 1, 2
                else
                    winner, loser = 2, 1
                end
            end
            
            self.gameLog:addEntry(string.format("Location %d: %s reveals first (Power: %d vs %d)", 
                loc, winner == 1 and "Player" or "Enemy", p1Power, p2Power))
            
            -- First, flip all cards face up
            for pid = 1, 2 do
                for _, c in ipairs(self.board.slots[pid][loc]) do
                    if c then
                        c:flip(true)  -- Flip all cards face up
                        self.gameLog:addEntry(string.format("%s reveals %s", 
                            pid == 1 and "Player" or "Enemy", c.def.name))
                    end
                end
            end
            
            -- Then trigger abilities in order:
            -- 1. Winner's cards first
            for _, c in ipairs(self.board.slots[winner][loc]) do
                if c and c.def.ability then
                    self.gameLog:addEntry(string.format("%s's %s ability triggers", 
                        winner == 1 and "Player" or "Enemy", c.def.name))
                    c:applyTrigger("onReveal", self, {location=loc})
                end
            end
            
            -- 2. Loser's cards second
            for _, c in ipairs(self.board.slots[loser][loc]) do
                if c and c.def.ability then
                    self.gameLog:addEntry(string.format("%s's %s ability triggers", 
                        loser == 1 and "Player" or "Enemy", c.def.name))
                    c:applyTrigger("onReveal", self, {location=loc})
                end
            end
        end

        -- Move to scoring phase
        self.state = "scoring"
        for loc = 1, 3 do
            local p1 = self.board:totalPower(1, loc)
            local p2 = self.board:totalPower(2, loc)
            local diff = math.abs(p1 - p2)
            if p1 > p2 then 
                self.players[1].score = self.players[1].score + diff
                self.gameLog:addEntry(string.format("Player wins location %d (+%d points)", loc, diff))
            elseif p2 > p1 then 
                self.players[2].score = self.players[2].score + diff
                self.gameLog:addEntry(string.format("Enemy wins location %d (+%d points)", loc, diff))
            else  -- tie, coin flip
                if math.random() < 0.5 then
                    self.players[1].score = self.players[1].score + diff
                    self.gameLog:addEntry(string.format("Tie at location %d: Player wins coin flip (+%d points)", loc, diff))
                else
                    self.players[2].score = self.players[2].score + diff
                    self.gameLog:addEntry(string.format("Tie at location %d: Enemy wins coin flip (+%d points)", loc, diff))
                end
            end
        end

    elseif self.state == "scoring" then
        -- Handle end of turn effects
        for pid = 1, 2 do
            for loc = 1, 3 do
                for i = #self.board.slots[pid][loc], 1, -1 do
                    local card = self.board.slots[pid][loc][i]
                    if card and card.def then
                        if card.def.id == "helios" then
                            -- Discard Helios
                            self.players[pid].deck:discard(card)
                            table.remove(self.board.slots[pid][loc], i)
                            self.gameLog:addEntry(string.format("%s's Helios is discarded", 
                                pid == 1 and "Player" or "Enemy"))
                        elseif card.def.id == "sword_of_damocles" then
                            -- Check if Sword of Damocles is not winning its location
                            local sourcePower = self.board:totalPower(pid, loc)
                            local targetPower = self.board:totalPower(pid == 1 and 2 or 1, loc)
                            if sourcePower <= targetPower then
                                card:addPower(-1)
                                self.gameLog:addEntry(string.format("%s's Sword of Damocles loses 1 power (now %d)", 
                                    pid == 1 and "Player" or "Enemy", card.power))
                            end
                        end
                    end
                end
            end
        end

        -- Discard all cards, prepare next turn
        for _, p in ipairs(self.players) do
            for loc = 1, 3 do
                for _, c in ipairs(self.board.slots[p.id][loc]) do
                    if c then
                        p.deck:discard(c)
                        self.gameLog:addEntry(string.format("%s's %s is discarded", 
                            p.id == 1 and "Player" or "Enemy", c.def.name))
                    end
                end
                self.board.slots[p.id][loc] = {}
            end
            p:drawTurnCard()
            self.gameLog:addEntry(string.format("%s draws a card", 
                p.id == 1 and "Player" or "Enemy"))
        end

        -- Check for game over
        if self.players[1].score >= self.targetScore or self.players[2].score >= self.targetScore then
            self.state = "gameover"
            if self.players[1].score > self.players[2].score then
                self.gameLog:addEntry("Player wins the game!")
            elseif self.players[2].score > self.players[1].score then
                self.gameLog:addEntry("Enemy wins the game!")
            else
                self.gameLog:addEntry("The game ends in a tie!")
            end
        else
            -- Start next turn
            self.turn = self.turn + 1
            for _, p in ipairs(self.players) do
                p.mana = self.turn
            end
            self.state = "staging"
            self.gameLog:addEntry(string.format("Turn %d begins", self.turn))
        end
    end
end

function Game:update(dt)
end

function Game:draw()
    if self.state ~= "deckbuilder" then
        require("src/ui"):draw()
        self.gameLog:draw()
    end
end

return Game
