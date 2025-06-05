-- main.lua
local constants = require "src/constants"
local utils     = require "src/utils"
local Card      = require "src/card"
local Deck      = require "src/deck"
local Player    = require "src/player"
local Board     = require "src/board"
local UI        = require "src/ui"
local Game      = require "src/game"

function love.load()
    -- lock window size to 1920x1080
    love.window.setMode(1680, 1050, {resizable = false, fullscreen = false})
    love.window.setTitle("Mythic Clash")

    -- initialize game
    math.randomseed(os.time())
    Game:init()
    Game.state = "menu"
end

function love.update(dt)
    Game:update(dt)
end

function love.draw()
    Game:draw()
end

function love.mousepressed(x, y, button)
    UI:mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    UI:mousereleased(x, y, button)
end
