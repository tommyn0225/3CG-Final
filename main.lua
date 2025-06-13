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
    love.window.setMode(1680, 1050, {resizable = false, fullscreen = false})
    love.window.setTitle("Mythic Clash")
    math.randomseed(os.time())
    Game:init()
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
    elseif Game.state == "menu" then
        UI:draw()
    elseif Game.board then
        UI:draw()
        Game.gameLog:draw()
    end
end

function love.mousepressed(x, y, button)
    if Game.state == "deckbuilder" then
        DeckBuilder.mousepressed(x, y, button)
    else
        UI:mousepressed(x, y, button)
    end
end

function love.mousereleased(x, y, button)
    UI:mousereleased(x, y, button)
end

function love.wheelmoved(x, y)
    if Game.state == "deckbuilder" then
        DeckBuilder.wheelmoved(x,y)
    end
end