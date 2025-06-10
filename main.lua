-- main.lua
local constants = require "src/constants"
local utils     = require "src/utils"
local Card      = require "src/card"
local Deck      = require "src/deck"
local Player    = require "src/player"
local Board     = require "src/board"
local UI        = require "src/ui"
local Game      = require "src/game"
local DeckBuilder = require "src/deckbuilder"

function love.load()
    -- lock window size to 1920x1080
    love.window.setMode(1680, 1050, {resizable = false, fullscreen = false})
    love.window.setTitle("Mythic Clash")

    -- initialize game
    math.randomseed(os.time())
    Game:init()
    
    -- initialize deckbuilder
    DeckBuilder.init()
    DeckBuilder.setOnComplete(function(deckCounts)
        Game:initWithCustomDeck(deckCounts)
    end)
end

function love.update(dt)
    if Game.state == "deckbuilder" then
        DeckBuilder.update(dt)
    else
        Game:update(dt)
    end
end

function love.draw()
    if Game.state == "deckbuilder" then
        DeckBuilder.draw()
    else
        Game:draw()
    end
end

function love.mousepressed(x, y, button)
    if Game.state == "deckbuilder" then
        local newState = DeckBuilder.mousepressed(x, y, button)
        if newState then
            Game.state = newState
        end
    else
        UI:mousepressed(x, y, button)
    end
end

function love.mousereleased(x, y, button)
    UI:mousereleased(x, y, button)
end

function love.wheelmoved(x, y)
    if Game.state == "deckbuilder" then
        DeckBuilder.wheelmoved(x, y)
    end
end
