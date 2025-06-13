-- src/ui.lua
local UI = {}
UI.__index = UI

local Game = require "src/game"
local lg   = love.graphics

local MAX_HAND = 7

UI.discardedThisTurn = false
UI.showEnemyHandDebug = false

function UI:mousepressed(x, y, button)
    local w, h = lg.getWidth(), lg.getHeight()

    if Game.state == "menu" then
        local bw, bh = w*0.3, h*0.1
        local bx = (w-bw)/2
        local playY = h*0.4
        local buildY = h*0.55

        if x > bx and x < bx+bw and y > playY and y < playY+bh then
            Game:startGame() -- Correctly start a new game
        elseif x > bx and x < bx+bw and y > buildY and y < buildY+bh then
            require("src/deckbuilder").init()
            Game.state = "deckbuilder"
        end
        return
    end

    if Game.state == "gameover" then
        local bw, bh = w*0.3, h*0.1; local bx, by = (w-bw)/2, h/2+20
        if x > bx and x < bx + bw and y > by and y < by + bh then Game.state = "menu" end
        return
    end

    if not Game.board then return end
    
    local p = Game.players[1]
    if Game.state == "staging" then
        local laneGap = w * 0.02
        local laneW = (w - 4 * laneGap) / 3
        local CARD_W = (laneW - (Game.board.maxSlots - 1) * laneGap) / Game.board.maxSlots
        local CARD_H = h * 0.2
        local handCount = #p.hand
        local totalW = handCount * CARD_W + (handCount - 1) * laneGap
        local hx = (w - totalW) / 2
        local hy = h * 0.15 + h * 0.55 + laneGap

        for i, card in ipairs(p.hand) do
            local cx = hx + (i - 1) * (CARD_W + laneGap)
            if x > cx and x < cx + CARD_W and y > hy and y < hy + CARD_H then
                self.dragging = { card = card, originIndex = i, fromHand = true }
                table.remove(p.hand, i)
                return
            end
        end

        local nextBw, nextBh = CARD_W*0.8, CARD_H*0.5
        local nextBx = (w - (MAX_HAND*CARD_W + (MAX_HAND-1)*laneGap))/2 + (MAX_HAND*CARD_W + laneGap*(MAX_HAND))
        local nextBy = hy + (CARD_H - nextBh)/2
        if x > nextBx and x < nextBx + nextBw and y > nextBy and y < nextBy + nextBh then
            Game:nextPhase()
        end
    end
end

function UI:mousereleased(x, y, button)
    if not self.dragging then return end
    
    local p = Game.players[1]
    local c = self.dragging.card
    
    if not p:playCard(c, x, y, Game.board) then
        table.insert(p.hand, self.dragging.originIndex, c)
    end
    
    self.dragging = nil
end

-- In src/ui.lua
function UI:draw()
    local w, h = lg.getWidth(), lg.getHeight()

    -- Draw Menu
    if Game.state == "menu" then
        lg.setColor(0,0,0); lg.rectangle('fill',0,0,w,h)
        lg.setColor(1,1,1); lg.printf("Mythic Clash",0,h*0.25,w,'center')
        
        local bw, bh = w*0.3, h*0.1
        local bx, playY, buildY = (w-bw)/2, h*0.4, h*0.55
        
        -- "Start Game" Button
        lg.setColor(0.8,0.8,0.8); lg.rectangle('fill',bx,playY,bw,bh,10,10)
        lg.setColor(0,0,0); lg.printf("Start Game",bx,playY+(bh-24)/2,bw,'center')
        
        -- "Build Deck" Button
        lg.setColor(0.8,0.8,0.8); lg.rectangle('fill',bx,buildY,bw,bh,10,10)
        lg.setColor(0,0,0); lg.printf("Build Deck",bx,buildY+(bh-24)/2,bw,'center')
        return
    end

    if not Game.board then return end
    
    -- Draw In-Game UI
    local p1 = Game.players[1]
    local laneGap = w * 0.02
    local laneW = (w - 4 * laneGap) / 3
    local CARD_W = (laneW - (Game.board.maxSlots - 1) * laneGap) / Game.board.maxSlots
    local CARD_H = h * 0.2
    local laneY = h * 0.15
    local laneH = h * 0.55

    -- Phase Text and Scores
    lg.setColor(1,1,1)
    lg.print("Turn "..Game.turn..": "..(Game:getPhaseText() or ""), 20, 20)
    lg.print("Mana: "..p1.mana,20,50)
    lg.print("Your Score: "..p1.score,20,80)
    lg.print("Enemy Score: "..Game.players[2].score,20,110)

    -- Draw Board Lanes
    for loc=1,3 do
        local laneX=laneGap+(loc-1)*(laneW+laneGap)
        lg.setColor(0.2,0.2,0.3,0.5); lg.rectangle('fill',laneX,laneY,laneW,laneH)
    end

    -- Draw Cards on Board
    for pid=1,2 do
        local rowY=(pid==1) and(laneY+laneH-CARD_H) or laneY
        for loc=1,3 do
            local laneX=laneGap+(loc-1)*(laneW+laneGap)
            local totalSlotW=Game.board.maxSlots*CARD_W+(Game.board.maxSlots-1)*laneGap
            local startX=laneX+(laneW-totalSlotW)/2
            for slot=1,Game.board.maxSlots do
                local sx=startX+(slot-1)*(CARD_W+laneGap)
                lg.setColor(1,1,1,0.2);lg.rectangle('line',sx,rowY,CARD_W,CARD_H)
                local c=Game.board.slots[pid][loc][slot]
                if c then
                    if c.faceUp then
                        lg.setColor(0.1,0.1,0.1); lg.rectangle('fill',sx+2,rowY+2,CARD_W-4,CARD_H-4)
                        lg.setColor(1,1,1)
                        lg.printf(c.def.name,sx,rowY+8,CARD_W,'center')
                        local img = c.def.image
                        if img then
                            local iw,ih = img:getDimensions()
                            local scale = math.min((CARD_W*0.6)/iw,(CARD_H*0.45)/ih)
                            lg.draw(img,sx+(CARD_W-iw*scale)/2,rowY+40,0,scale,scale)
                        end
                        lg.print("C:"..c.cost,sx+10,rowY+CARD_H-90)
                        lg.print("P:"..c.power,sx+CARD_W-40,rowY+CARD_H-90)
                        lg.printf(c.def.text,sx+10,rowY+CARD_H-70,CARD_W-20,'center')
                    else
                        lg.setColor(0.4,0.4,0.4); lg.rectangle('fill',sx+2,rowY+2,CARD_W-4,CARD_H-4)
                    end
                end
            end
        end
    end
    
    -- Draw Player Hand
    local totalHandW = #p1.hand*CARD_W+(#p1.hand-1)*laneGap
    local hx=(w-totalHandW)/2
    local hy=laneY+laneH+laneGap
    for i,c in ipairs(p1.hand) do
        local sx=hx+(i-1)*(CARD_W+laneGap)
        lg.setColor(1,1,1);lg.rectangle('line',sx,hy,CARD_W,CARD_H)
        lg.setColor(0.1,0.1,0.1); lg.rectangle('fill',sx+2,hy+2,CARD_W-4,CARD_H-4)
        lg.setColor(1,1,1)
        lg.printf(c.def.name,sx,hy+8,CARD_W,'center')
        local img = c.def.image
        if img then
            local iw,ih = img:getDimensions()
            local scale = math.min((CARD_W*0.6)/iw,(CARD_H*0.45)/ih)
            lg.draw(img,sx+(CARD_W-iw*scale)/2,hy+40,0,scale,scale)
        end
        lg.print("C:"..c.cost,sx+10,hy+CARD_H-90)
        lg.print("P:"..c.power,sx+CARD_W-40,hy+CARD_H-90)
        lg.printf(c.def.text,sx+10,hy+CARD_H-70,CARD_W-20,'center')
    end
    
    -- Draw Dragging Card Preview
    if self.dragging then
        local mx,my = love.mouse.getPosition()
        local card = self.dragging.card
        lg.setColor(1,1,1,0.8);
        lg.rectangle('fill', mx-CARD_W/2, my-CARD_H/2, CARD_W, CARD_H)
        lg.setColor(0,0,0); lg.printf(card.def.name, mx-CARD_W/2, my-CARD_H/2+10, CARD_W, 'center')
    end

    -- Draw "Next" button ONLY during staging phase
    if Game.state == "staging" then
        local nextBw, nextBh = CARD_W*0.8, CARD_H*0.5
        local nextBx = (w - (MAX_HAND*CARD_W + (MAX_HAND-1)*laneGap))/2 + (MAX_HAND*CARD_W + laneGap*(MAX_HAND))
        local nextBy = hy + (CARD_H - nextBh)/2
        lg.setColor(0.85,0.85,0.85); lg.rectangle('fill',nextBx,nextBy,nextBw,nextBh,6,6)
        lg.setColor(0,0,0); lg.printf("Next",nextBx,nextBy+(nextBh-18)/2,nextBw,'center')
    end

    -- Draw Game Over Screen
    if Game.state=="gameover" then
        lg.setColor(0,0,0,0.8); lg.rectangle('fill',0,0,w,h)
        local p1Score, p2Score = Game.players[1].score, Game.players[2].score
        local winnerText = (p1Score > p2Score) and "You Win!" or "You Lose."
        if p1Score == p2Score then winnerText = "It's a Tie!" end
        lg.setColor(1,1,1); lg.printf(winnerText,0,h/2-60,w,'center')
        
        local bw, bh = w*0.3, h*0.1
        local bx, by = (w-bw)/2, h/2+20
        lg.setColor(0.8,0.8,0.8); lg.rectangle('fill',bx,by,bw,bh,10,10)
        lg.setColor(0,0,0); lg.printf("Main Menu",bx,by+(bh-24)/2,bw,'center')
    end
end

return UI