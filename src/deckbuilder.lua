-- src/deckbuilder.lua
local DeckBuilder = {}
local constants = require "src/constants"
local Game = require "src/game"

-- UI Constants
local PANEL_WIDTH = 400
local SLOT_HEIGHT = 50
local PADDING = 20
local BUTTON_HEIGHT = 40
local BUTTON_WIDTH = 120

-- State
local availableCards = {}
local customDeckCounts = {}
local scrollY = 0
local maxScrollY = 0
local onComplete = nil

function DeckBuilder.init()
    -- Initialize available cards from constants
    availableCards = {}
    for _, def in ipairs(constants.CARD_DEFS) do
        availableCards[def.id] = def
    end
    
    -- Initialize empty deck
    customDeckCounts = {}
    for _, def in ipairs(constants.CARD_DEFS) do
        customDeckCounts[def.id] = 0
    end
    
    -- Load saved deck if exists
    DeckBuilder.load()
    
    -- Calculate initial max scroll
    maxScrollY = math.max(0, (#constants.CARD_DEFS * SLOT_HEIGHT) - (love.graphics.getHeight() - 2 * PADDING))
end

function DeckBuilder.addCard(cardId)
    if customDeckCounts[cardId] < 2 then
        customDeckCounts[cardId] = customDeckCounts[cardId] + 1
    end
end

function DeckBuilder.removeCard(cardId)
    if customDeckCounts[cardId] > 0 then
        customDeckCounts[cardId] = customDeckCounts[cardId] - 1
    end
end

function DeckBuilder.totalCards()
    local total = 0
    for _, count in pairs(customDeckCounts) do
        total = total + count
    end
    return total
end

function DeckBuilder.validate()
    return DeckBuilder.totalCards() == 20
end

function DeckBuilder.save()
    local file = love.filesystem.newFile("custom_deck.txt")
    file:open("w")
    for id, count in pairs(customDeckCounts) do
        if count > 0 then
            file:write(string.format("%s:%d\n", id, count))
        end
    end
    file:close()
end

function DeckBuilder.load()
    if love.filesystem.getInfo("custom_deck.txt") then
        local file = love.filesystem.newFile("custom_deck.txt")
        file:open("r")
        for line in file:lines() do
            local id, count = line:match("([^:]+):(%d+)")
            if id and count then
                customDeckCounts[id] = tonumber(count)
            end
        end
        file:close()
    end
end

function DeckBuilder.update(dt)
    -- Clamp scroll position
    scrollY = math.max(0, math.min(scrollY, maxScrollY))
end

function DeckBuilder.draw()
    local windowWidth = love.graphics.getWidth()
    local windowHeight = love.graphics.getHeight()
    
    -- Draw title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Build Your Deck", 0, 20, windowWidth, "center")
    
    -- Draw left panel (Available Cards)
    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", PADDING, PADDING + 40, PANEL_WIDTH, windowHeight - 2 * PADDING - 40)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Available Cards", PADDING + 10, PADDING + 50)
    
    -- Draw available cards list in 2 columns
    local y = PADDING + 80
    local columnWidth = (PANEL_WIDTH - 30) / 2  -- 30 for padding between columns
    local cardsPerColumn = math.ceil(#constants.CARD_DEFS / 2)
    
    for i, def in ipairs(constants.CARD_DEFS) do
        local column = math.floor((i - 1) / cardsPerColumn)
        local row = (i - 1) % cardsPerColumn
        local cardY = PADDING + 80 + (row * SLOT_HEIGHT)
        
        if cardY - scrollY + SLOT_HEIGHT > PADDING + 40 and cardY - scrollY < windowHeight - PADDING then
            local cardX = PADDING + 10 + (column * (columnWidth + 10))
            
            love.graphics.setColor(0.3, 0.3, 0.3, 1)
            love.graphics.rectangle("fill", cardX, cardY - scrollY, columnWidth, SLOT_HEIGHT - 5)
            
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(def.name, cardX + 10, cardY - scrollY + 10)
            love.graphics.print(string.format("Cost: %d  Power: %d", def.cost, def.power), 
                cardX + 10, cardY - scrollY + 30)
        end
    end
    
    -- Draw right panel (Your Deck)
    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", windowWidth - PANEL_WIDTH - PADDING, PADDING + 40, 
        PANEL_WIDTH, windowHeight - 2 * PADDING - 40)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(string.format("Your Deck: %d/20", DeckBuilder.totalCards()), 
        windowWidth - PANEL_WIDTH - PADDING + 10, PADDING + 50)
    
    -- Draw deck list
    y = PADDING + 80
    for id, count in pairs(customDeckCounts) do
        if count > 0 then
            local def = availableCards[id]
            love.graphics.setColor(0.3, 0.3, 0.3, 1)
            love.graphics.rectangle("fill", windowWidth - PANEL_WIDTH - PADDING + 10, y, 
                PANEL_WIDTH - 20, SLOT_HEIGHT - 5)
            
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(string.format("%s × %d", def.name, count), 
                windowWidth - PANEL_WIDTH - PADDING + 20, y + 10)
            love.graphics.print(string.format("Cost: %d  Power: %d", def.cost, def.power), 
                windowWidth - PANEL_WIDTH - PADDING + 20, y + 30)
            y = y + SLOT_HEIGHT
        end
    end
    
    -- Draw buttons
    local buttonY = windowHeight - BUTTON_HEIGHT - PADDING
    love.graphics.setColor(0.4, 0.4, 0.4, 1)
    love.graphics.rectangle("fill", PADDING, buttonY, BUTTON_WIDTH, BUTTON_HEIGHT)
    love.graphics.rectangle("fill", windowWidth - BUTTON_WIDTH - PADDING, buttonY, 
        BUTTON_WIDTH, BUTTON_HEIGHT)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Back", PADDING + 20, buttonY + 10)
    love.graphics.print("Start Game", windowWidth - BUTTON_WIDTH - PADDING + 20, buttonY + 10)
    
    -- Draw validation message
    if not DeckBuilder.validate() then
        love.graphics.setColor(1, 0.3, 0.3, 1)
        love.graphics.print("Deck must contain exactly 20 cards", 
            windowWidth/2 - 150, buttonY - 30)
    end
end

function DeckBuilder.mousepressed(x, y, button)
    local windowWidth = love.graphics.getWidth()
    local windowHeight = love.graphics.getHeight()
    
    -- Check left panel clicks (add cards)
    if x > PADDING and x < PADDING + PANEL_WIDTH and 
       y > PADDING + 80 and y < windowHeight - PADDING - BUTTON_HEIGHT then
        local columnWidth = (PANEL_WIDTH - 30) / 2
        local cardsPerColumn = math.ceil(#constants.CARD_DEFS / 2)
        local column = math.floor((x - PADDING - 10) / (columnWidth + 10))
        local row = math.floor((y - PADDING - 80 + scrollY) / SLOT_HEIGHT)
        local index = column * cardsPerColumn + row + 1
        
        if index > 0 and index <= #constants.CARD_DEFS then
            DeckBuilder.addCard(constants.CARD_DEFS[index].id)
        end
    end
    
    -- Check right panel clicks (remove cards)
    if x > windowWidth - PANEL_WIDTH - PADDING and x < windowWidth - PADDING and 
       y > PADDING + 80 and y < windowHeight - PADDING - BUTTON_HEIGHT then
        local index = math.floor((y - PADDING - 80) / SLOT_HEIGHT) + 1
        local count = 0
        for id, cardCount in pairs(customDeckCounts) do
            if cardCount > 0 then
                count = count + 1
                if count == index then
                    DeckBuilder.removeCard(id)
                    break
                end
            end
        end
    end
    
    -- Check button clicks
    local buttonY = windowHeight - BUTTON_HEIGHT - PADDING
    
    -- Back button
    if x > PADDING and x < PADDING + BUTTON_WIDTH and 
       y > buttonY and y < buttonY + BUTTON_HEIGHT then
        Game.state = "menu"
        return
    end
    
    -- Start Game button
    if x > windowWidth - BUTTON_WIDTH - PADDING and x < windowWidth - PADDING and 
       y > buttonY and y < buttonY + BUTTON_HEIGHT then
        if DeckBuilder.validate() then
            DeckBuilder.save()
            Game:initWithCustomDeck(customDeckCounts)
            return
        end
    end
end

function DeckBuilder.wheelmoved(x, y)
    scrollY = scrollY - y * 50
    maxScrollY = math.max(0, (#constants.CARD_DEFS * SLOT_HEIGHT) - (love.graphics.getHeight() - 2 * PADDING))
    scrollY = math.max(0, math.min(scrollY, maxScrollY))
end

function DeckBuilder.setOnComplete(callback)
    onComplete = callback
end

return DeckBuilder 