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
    self.state = "menu"
    self.gameLog = GameLog.new()

    -- Preload all card images
    for _, def in ipairs(constants.CARD_DEFS) do
        def.image = love.graphics.newImage("src/assets/images/" .. def.id .. ".png")
    end
end

function Game:startGame()
    -- Starts a new game with default decks
    self.players = { Player.new(1, false), Player.new(2, true) }
    self.board = Board.new()
    self.turn = 1
    self.state = "staging"
    self.targetScore = constants.TARGET_SCORE

    -- Timer for automated turns
    self.phaseTimer = 0
    self.phaseDelay = 1.5 -- Seconds to wait between phases

    for _, p in ipairs(self.players) do
        p:drawStartingHand()
        p.mana = self.turn
    end
    
    self.gameLog:addEntry("Game started!")
end

function Game:initWithCustomDeck(deckCounts)
    -- Starts a new game with the player's custom deck
    self.players = { Player.new(1, false), Player.new(2, true) }
    self.board = Board.new()
    self.turn = 1
    self.state = "staging"
    self.targetScore = constants.TARGET_SCORE

    -- Timer for automated turns
    self.phaseTimer = 0
    self.phaseDelay = 1.5

    -- Build custom deck for player 1
    local customDeckDefs = {}
    for id, count in pairs(deckCounts) do
        if count > 0 then
            for _, def in ipairs(constants.CARD_DEFS) do
                if def.id == id then
                    for i = 1, count do
                        table.insert(customDeckDefs, def)
                    end
                    break
                end
            end
        end
    end
    self.players[1].deck = Deck.new(customDeckDefs)

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
        reveal   = "Revealing Cards",
        scoring  = "Scoring Turn",
        gameover = "Game Over"
    }
    return texts[self.state] or ""
end

function Game:update(dt)
    -- This logic drives the automated turn progression
    if self.state == "staging" or self.state == "menu" or self.state == "gameover" then
        return -- Only run timer logic during automated phases
    end

    if self.phaseTimer > 0 then
        self.phaseTimer = self.phaseTimer - dt
    else
        self:nextPhase()
    end
end

function Game:nextPhase()
    -- This is the automated state machine for turn progression
    if self.state == "staging" then
        self.state = "enemy"
        AI.stageRandom(self.players[2], self.board)
        self.gameLog:addEntry("Enemy is staging their cards...")
        self.phaseTimer = self.phaseDelay

    elseif self.state == "enemy" then
        -- After a delay, reveal cards and trigger abilities
        self.state = "reveal"
        self.gameLog:addEntry("--- REVEAL PHASE ---")
        
        for loc = 1, 3 do
            local p1Power = self.board:totalPower(1, loc)
            local p2Power = self.board:totalPower(2, loc)
            local winner, loser
            if p1Power > p2Power then
                winner, loser = 1, 2
            elseif p2Power > p1Power then
                winner, loser = 2, 1
            else -- Tie logic corrected
                if math.random() < 0.5 then
                    winner, loser = 1, 2
                else
                    winner, loser = 2, 1
                end
            end
            
            self.gameLog:addEntry(string.format("Location %d: %s reveals first.", loc, winner == 1 and "Player" or "Enemy"))

            -- Reveal and trigger winner's cards
            for _, c in ipairs(self.board.slots[winner][loc]) do c:flip(true); c:applyTrigger("onReveal", self, {location=loc}) end
            -- Reveal and trigger loser's cards
            for _, c in ipairs(self.board.slots[loser][loc]) do c:flip(true); c:applyTrigger("onReveal", self, {location=loc}) end
        end
        self.phaseTimer = self.phaseDelay

    elseif self.state == "reveal" then
        -- After another delay, calculate scores
        self.state = "scoring"
        self.gameLog:addEntry("--- SCORING PHASE ---")
        for loc = 1, 3 do
            local p1 = self.board:totalPower(1, loc)
            local p2 = self.board:totalPower(2, loc)
            if p1 > p2 then self.players[1].score = self.players[1].score + (p1-p2) end
            if p2 > p1 then self.players[2].score = self.players[2].score + (p2-p1) end
        end
        self.phaseTimer = self.phaseDelay

    elseif self.state == "scoring" then
        -- Final phase: clean up and prepare the next turn
        self.gameLog:addEntry("--- END OF TURN ---")
        -- Discard all cards from the board
        for _, p in ipairs(self.players) do
            for loc = 1, 3 do
                for _, c in ipairs(self.board.slots[p.id][loc]) do p.deck:discard(c) end
                self.board.slots[p.id][loc] = {}
            end
            p:drawTurnCard()
        end

        self.turn = self.turn + 1
        for _, p in ipairs(self.players) do p.mana = self.turn + (p.nextTurnMana or 0); p.nextTurnMana = 0 end

        -- Check for win condition
        if self.players[1].score >= self.targetScore or self.players[2].score >= self.targetScore then
            self.state = "gameover"
        else
            self.state = "staging"
            require("src/ui").discardedThisTurn = false
            self.gameLog:addEntry(string.format("Turn %d begins", self.turn))
        end
    end
end

function Game:draw()
    -- The main draw function, now simpler
    if self.state ~= "menu" then
        require("src/ui"):draw()
        self.gameLog:draw()
    else
        -- Draw the main menu from the UI module
        require("src/ui"):draw()
    end
end

return Game