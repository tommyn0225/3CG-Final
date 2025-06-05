-- src/game.lua
local Game = {}
Game.__index = Game

local constants = require "src/constants"
local Player    = require "src/player"
local Board     = require "src/board"
local AI        = require "src/ai"
local GameLog   = require "src/game_log"

function Game:init()
    self.players     = { Player.new(1, false), Player.new(2, true) }
    self.board       = Board.new()
    self.turn        = 1
    self.state       = "staging"
    self.targetScore = constants.TARGET_SCORE
    self.gameLog     = GameLog.new()

    -- Preload all card images
    for _, def in ipairs(constants.CARD_DEFS) do
        def.image = love.graphics.newImage("src/assets/images/" .. def.id .. ".png")
    end

    -- Deal starting hands, set initial mana
    for _, p in ipairs(self.players) do
        p:drawStartingHand()
        p.mana = self.turn
    end
    
    self.gameLog:addEntry("Game started!")
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
                    c:flip(false)
                end
            end
        end
        
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
            
            -- Flip all cards face up for both players
            for pid = 1, 2 do
                for _, c in ipairs(self.board.slots[pid][loc]) do
                    c:flip(true)
                    self.gameLog:addEntry(string.format("%s reveals %s", 
                        pid == 1 and "Player" or "Enemy", c.def.name))
                    
                    -- Immediately trigger abilities for winner's cards
                    if pid == winner and c.def.ability then
                        self.gameLog:addEntry(string.format("%s's %s ability triggers", 
                            pid == 1 and "Player" or "Enemy", c.def.name))
                        c:applyTrigger("onReveal", self, {location=loc})
                    end
                end
            end
            
            -- Then trigger abilities for loser's cards
            for _, c in ipairs(self.board.slots[loser][loc]) do
                if c.def.ability then
                    self.gameLog:addEntry(string.format("%s's %s ability triggers", 
                        loser == 1 and "Player" or "Enemy", c.def.name))
                    c:applyTrigger("onReveal", self, {location=loc})
                end
            end
        end

        -- Scoring
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
                    if card.def.id == "helios" then
                        -- Discard Helios
                        self.players[pid].deck:discard(card)
                        table.remove(self.board.slots[pid][loc], i)
                        self.gameLog:addEntry(string.format("%s's Helios is discarded", 
                            pid == 1 and "Player" or "Enemy"))
                    end
                end
            end
        end

        -- Discard all cards, prepare next turn
        for _, p in ipairs(self.players) do
            for loc = 1, 3 do
                for _, c in ipairs(self.board.slots[p.id][loc]) do
                    p.deck:discard(c)
                    self.gameLog:addEntry(string.format("%s's %s is discarded", 
                        p.id == 1 and "Player" or "Enemy", c.def.name))
                end
                self.board.slots[p.id][loc] = {}
            end
            p:drawTurnCard()
            self.gameLog:addEntry(string.format("%s draws a card", 
                p.id == 1 and "Player" or "Enemy"))
        end

        self.turn = self.turn + 1
        for _, p in ipairs(self.players) do
            -- Apply Apollo's mana bonus
            p.mana = self.turn + (p.nextTurnMana or 0)
            if p.nextTurnMana and p.nextTurnMana > 0 then
                self.gameLog:addEntry(string.format("%s gains +%d mana from Apollo", 
                    p.id == 1 and "Player" or "Enemy", p.nextTurnMana))
            end
            p.nextTurnMana = 0
        end

        -- Check win
        for _, p in ipairs(self.players) do
            if p.score >= self.targetScore then
                self.state = "gameover"
                self.gameLog:addEntry(string.format("%s wins the game!", 
                    p.id == 1 and "Player" or "Enemy"))
                return
            end
        end

        self.state = "staging"
        require("src/ui").discardedThisTurn = false
        self.gameLog:addEntry(string.format("Turn %d begins", self.turn))
    end
end

function Game:update(dt)
end

function Game:draw()
    require("src/ui"):draw()
    self.gameLog:draw()
end

return Game
