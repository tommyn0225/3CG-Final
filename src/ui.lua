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
        -- Play button
        local bw, bh = w*0.3, h*0.1
        local bx, by = (w-bw)/2, h*0.5
        if x >= bx and x <= bx + bw and y >= by and y <= by + bh then
            Game.state = "deckbuilder"
            return
        end
        return
    end

    -- Only handle game UI interactions if game is initialized
    if Game.state ~= "deckbuilder" and Game.board and Game.players then
        local laneGap = w * 0.02
        local GAP = laneGap
        local laneW = (w - 4 * laneGap) / 3
        local CARD_W = (laneW - (Game.board.maxSlots - 1) * GAP) / Game.board.maxSlots
        local CARD_H = h * 0.2

        -- Game log interaction
        local panelW = 300
        local panelH = Game.gameLog.isCollapsed and 30 or 250
        local panelX = 20
        local panelY = h - panelH - 20
        
        -- Check if clicking on collapse button
        local btnW, btnH = 20, 20
        local btnX = panelX + panelW - btnW - 5
        local btnY = panelY + 5
        if x >= btnX and x <= btnX + btnW and y >= btnY and y <= btnY + btnH then
            Game.gameLog:toggleCollapse()
            return
        end
        
        -- Check if clicking on scroll indicators
        if not Game.gameLog.isCollapsed then
            local scrollBtnW, scrollBtnH = 20, 20
            local scrollBtnX = panelX + panelW - scrollBtnW - 5
            
            -- Up arrow
            local upBtnY = panelY + 30
            if x >= scrollBtnX and x <= scrollBtnX + scrollBtnW and 
               y >= upBtnY and y <= upBtnY + scrollBtnH and 
               Game.gameLog.scrollOffset > 0 then
                Game.gameLog:scroll(1)
                return
            end
            
            -- Down arrow
            local downBtnY = panelY + panelH - scrollBtnH - 5
            if x >= scrollBtnX and x <= scrollBtnX + scrollBtnW and 
               y >= downBtnY and y <= downBtnY + scrollBtnH and 
               Game.gameLog.scrollOffset < Game.gameLog.maxScrollOffset then
                Game.gameLog:scroll(-1)
                return
            end
        end

        local btnW, btnH = 120, 32
        local btnX, btnY = w - btnW - 20, 60
        if x >= btnX and x <= btnX + btnW and y >= btnY and y <= btnY + btnH then
            UI.showEnemyHandDebug = not UI.showEnemyHandDebug
            return
        end

        if Game.state == "gameover" then
            local bw, bh = w*0.3, h*0.1
            local bx, by = (w-bw)/2, h/2+20
            if x >= bx and x <= bx + bw and y >= by and y <= by + bh then
                Game:startGame()
                return
            end
            return
        end

        -- During staging phase, handle card movement
        if Game.state == "staging" then
            -- Check if clicking on a card on the board
            local laneY = h * 0.15
            local laneH = h * 0.55
            local rowY = laneY + laneH - CARD_H
            
            for loc = 1, 3 do
                local laneX = laneGap + (loc - 1) * (laneW + laneGap)
                local totalLaneW = Game.board.maxSlots * CARD_W + (Game.board.maxSlots - 1) * GAP
                local startX = laneX + (laneW - totalLaneW) / 2
                
                for slot = 1, Game.board.maxSlots do
                    local sx = startX + (slot - 1) * (CARD_W + GAP)
                    local card = Game.board.slots[1][loc][slot]
                    if card and x >= sx and x <= sx + CARD_W and y >= rowY and y <= rowY + CARD_H then
                        -- Start dragging the card
                        self.dragging = { card = card, originIndex = slot, originLoc = loc }
                        return
                    end
                end
            end

            -- Check if clicking on a card in hand
            local p = Game.players[1]
            local handCount = #p.hand
            local totalW = handCount * CARD_W + (handCount - 1) * GAP
            local hx = (w - totalW) / 2
            local hy = h * 0.15 + h * 0.55 + laneGap
            
            for i, card in ipairs(p.hand) do
                local cx = hx + (i - 1) * (CARD_W + GAP)
                if x >= cx and x <= cx + CARD_W and y >= hy and y <= hy + CARD_H then
                    self.dragging = { card = card, originIndex = i, fromHand = true }
                    table.remove(p.hand, i)
                    return
                end
            end
        end

        -- Next button click
        do
            local totalW = MAX_HAND * CARD_W + (MAX_HAND - 1) * GAP
            local hx = (w - totalW) / 2
            local hy = h * 0.15 + h * 0.55 + laneGap
            local bw = CARD_W * 0.8
            local bh = CARD_H * 0.5
            local nbx = hx + totalW + GAP
            local nby = hy + (CARD_H - bh) / 2
            if x >= nbx and x <= nbx + bw and y >= nby and y <= nby + bh then
                Game:nextPhase()
            end
        end
    end
end

function UI:mousereleased(x, y, button)
    if not self.dragging then return end
    local p = Game.players[1]
    local c = self.dragging.card
    local w, h = lg.getWidth(), lg.getHeight()

    -- Only allow card movement during staging phase
    if Game.state ~= "staging" then
        if self.dragging.fromHand then
            table.insert(p.hand, self.dragging.originIndex, c)
        end
        self.dragging = nil
        return
    end

    local laneGap = w * 0.02
    local GAP = laneGap
    local laneW = (w - 4 * laneGap) / 3
    local CARD_W = (laneW - (Game.board.maxSlots - 1) * GAP) / Game.board.maxSlots
    local CARD_H = h * 0.2
    local laneY = h * 0.15
    local laneH = h * 0.55

    -- Check if dropping in hand
    local handCount = #p.hand
    local totalW = handCount * CARD_W + (handCount - 1) * GAP
    local hx = (w - totalW) / 2
    local hy = laneY + laneH + laneGap
    
    -- Discard pile area
    local pileW, pileH = CARD_W * 0.8, CARD_H * 0.8
    local dx = w - laneGap - pileW
    local dy = hy

    -- If dropped in discard pile
    if x >= dx and x <= dx + pileW and y >= dy and y <= dy + pileH then
        if self.dragging.fromHand and not Game.discardedThisTurn then
            -- Trigger Hydra ability if needed
            if c.def.ability == "hydra" then
                local abilities = require "src/abilities"
                local sourcePlayer = p
                local targetPlayer = Game.players[p.id == 1 and 2 or 1]
                abilities.hydra(Game, sourcePlayer, targetPlayer, c, {discarded=true})
            end
            -- Add to discard pile
            table.insert(p.deck.discardPile, c)
            -- Set discarded flag for this turn
            Game.discardedThisTurn = true
            -- Log the discard
            Game.gameLog:addEntry(string.format("Player discarded %s", c.def.name))
            self.dragging = nil
            return
        else
            -- Either not from hand or already discarded this turn
            if self.dragging.fromHand then
                table.insert(p.hand, self.dragging.originIndex, c)
            end
            self.dragging = nil
            return
        end
    end

    -- Check if dropping in hand
    if y >= hy and y <= hy + CARD_H then
        -- Calculate new position in hand
        local newIndex = math.floor((x - hx) / (CARD_W + GAP)) + 1
        newIndex = math.max(1, math.min(newIndex, handCount + 1))
        
        if self.dragging.fromHand then
            -- Reordering cards in hand
            table.insert(p.hand, newIndex, c)
        else
            -- Moving card from board back to hand
            -- Clear the board position
            Game.board.slots[1][self.dragging.originLoc][self.dragging.originIndex] = nil
            -- Add to hand
            table.insert(p.hand, newIndex, c)
            -- Refund mana cost
            p.mana = p.mana + c.cost
            -- Log mana refund
            Game.gameLog:addEntry(string.format("Player refunded %d mana (now %d)", c.cost, p.mana))
        end
        self.dragging = nil
        return
    end

    -- Check if dropping on board
    local rowY = laneY + laneH - CARD_H
    if y >= rowY and y <= rowY + CARD_H then
        for loc = 1, 3 do
            local laneX = laneGap + (loc - 1) * (laneW + laneGap)
            local totalLaneW = Game.board.maxSlots * CARD_W + (Game.board.maxSlots - 1) * GAP
            local startX = laneX + (laneW - totalLaneW) / 2
            
            if x >= laneX and x <= laneX + laneW then
                -- Find the target slot
                local slot = math.floor((x - startX) / (CARD_W + GAP)) + 1
                slot = math.max(1, math.min(slot, Game.board.maxSlots))
                
                -- Check if slot is empty
                if not Game.board.slots[1][loc][slot] then
                    -- If playing from hand, check mana cost
                    if self.dragging.fromHand then
                        if p.mana >= c.cost then
                            -- Place card in new position
                            Game.board.slots[1][loc][slot] = c
                            -- Deduct mana cost
                            p.mana = p.mana - c.cost
                            -- Flip card face up when played
                            c:flip(true)
                        else
                            -- Not enough mana, return to hand
                            table.insert(p.hand, self.dragging.originIndex, c)
                        end
                    else
                        -- Moving card on board (no mana cost)
                        -- Place card in new position
                        Game.board.slots[1][loc][slot] = c
                        -- Clear old position
                        Game.board.slots[1][self.dragging.originLoc][self.dragging.originIndex] = nil
                    end
                    self.dragging = nil
                    return
                end
            end
        end
    end

    -- If we get here, return card to original position
    if self.dragging.fromHand then
        table.insert(p.hand, self.dragging.originIndex, c)
    else
        local loc = self.dragging.originLoc
        local slot = self.dragging.originIndex
        Game.board.slots[1][loc][slot] = c
    end
    self.dragging = nil
end

function UI:draw()
    local w, h = lg.getWidth(), lg.getHeight()
    
    if Game.state == "menu" then
        lg.setColor(0,0,0); lg.rectangle('fill',0,0,w,h)
        lg.setColor(1,1,1); lg.printf("Mythic Clash",0,h*0.3,w,'center')
        
        -- Play button
        local bw, bh = w*0.3, h*0.1
        local bx, by = (w-bw)/2, h*0.5
        lg.setColor(0.8,0.8,0.8); lg.rectangle('fill',bx,by,bw,bh,10,10)
        lg.setColor(0,0,0); lg.printf("Play",bx,by+(bh-24)/2,bw,'center')
        return
    end
    
    -- Only draw game UI if game is initialized and not in deckbuilder state
    if Game.state ~= "deckbuilder" and Game.board and Game.players then
        -- Draw board
        local laneGap = w * 0.02
        local GAP = laneGap
        local laneW = (w - 4 * laneGap) / 3
        local CARD_W = (laneW - (Game.board.maxSlots - 1) * GAP) / Game.board.maxSlots
        local CARD_H = h * 0.2
        local laneY = h * 0.15
        local laneH = h * 0.55

        -- Title
        lg.setColor(1,1,1)
        local phase = "Round "..Game.turn..": "..(Game:getPhaseText() or "")
        local fw = lg.getFont():getWidth(phase)
        lg.print(phase, w-fw-20,20)

        -- Draw toggle button
        local btnW, btnH = 120, 32
        local btnX, btnY = w - btnW - 20, 60
        lg.setColor(0.7,0.7,0.7)
        lg.rectangle('fill', btnX, btnY, btnW, btnH, 8, 8)
        lg.setColor(0,0,0)
        local label = UI.showEnemyHandDebug and "Hide Enemy Hand" or "Show Enemy Hand"
        lg.printf(label, btnX, btnY + 8, btnW, 'center')

        -- Draw board lanes & cards
        local laneColors={{0.6,0.2,0.2,0.35},{0.2,0.6,0.2,0.35},{0.2,0.2,0.6,0.35}}
        for loc=1,3 do
            local x=laneGap+(loc-1)*(laneW+laneGap)
            lg.setColor(unpack(laneColors[loc]))
            lg.rectangle('fill',x,laneY,laneW,laneH)
            
            -- Calculate and display location power difference only during scoring phase
            if Game.state == "scoring" then
                local p1Power = Game.board:totalPower(1, loc)
                local p2Power = Game.board:totalPower(2, loc)
                local powerDiff = p1Power - p2Power
                if powerDiff ~= 0 then
                    local diffText = tostring(powerDiff)
                    if powerDiff > 0 then
                        diffText = "+" .. diffText
                        lg.setColor(0,1,0) -- Green
                    else
                        lg.setColor(1,0,0)  -- Red
                    end
                    local fontSize = 16
                    local oldFont = lg.getFont()
                    local tempFont = love.graphics.newFont(fontSize)
                    lg.setFont(tempFont)
                    local fw = tempFont:getWidth(diffText)
                    lg.printf(diffText or "", x + (laneW - fw)/2, laneY + laneH/2 - fontSize/2, fw, 'center')
                    lg.setFont(oldFont)
                end
            end
        end
        lg.setColor(1,1,1)
        for pid=1,2 do
            local rowY=(pid==1) and(laneY+laneH-CARD_H) or laneY
            for loc=1,3 do
                local laneX=laneGap+(loc-1)*(laneW+laneGap)
                local totalLaneW=Game.board.maxSlots*CARD_W+(Game.board.maxSlots-1)*GAP
                local startX=laneX+(laneW-totalLaneW)/2
                for slot=1,Game.board.maxSlots do
                    local sx=startX+(slot-1)*(CARD_W+GAP)
                    lg.setColor(1,1,1);lg.rectangle('line',sx,rowY,CARD_W,CARD_H)
                    local c=Game.board.slots[pid][loc][slot]
                    if c then
                        if c.faceUp then
                            lg.setColor(0.1,0.1,0.1)
                            lg.rectangle('fill',sx+2,rowY+2,CARD_W-4,CARD_H-4)
                            lg.setColor(1,1,1)
                            lg.printf(c.def.name or "",sx,rowY+8,CARD_W,'center')
                            local img = c.def.image
                            if img then
                                local iw,ih = img:getDimensions()
                                local scale = math.min((CARD_W*0.6)/iw,(CARD_H*0.45)/ih)
                                lg.draw(img,sx+(CARD_W-iw*scale)/2,rowY+40,0,scale,scale)
                            end
                            lg.print("C:"..(c.cost or 0),sx+10,rowY+CARD_H-90)
                            -- Draw power, blue if set by ability this reveal
                            if Game.state == "reveal" and c.powerSetThisReveal then
                                lg.setColor(0.2,0.6,1) -- Blue
                            else
                                lg.setColor(1,1,1)
                            end
                            lg.print("P:"..(c.power or 0),sx+CARD_W-40,rowY+CARD_H-90)
                            lg.setColor(1,1,1)
                            lg.printf(c.def.text or "",sx+10,rowY+CARD_H-70,CARD_W-20,'center')
                            
                            -- Show power changes during reveal phase
                            if Game.state == "reveal" and c.powerChange then
                                local changeText = ""
                                if c.powerChange > 0 then
                                    changeText = "+" .. c.powerChange .. "P"
                                    lg.setColor(0,1,0)  -- Green
                                elseif c.powerChange < 0 then
                                    changeText = c.powerChange .. "P"
                                    lg.setColor(1,0,0)  -- Red
                                end
                                if changeText ~= "" then
                                    lg.printf(changeText, sx, rowY+CARD_H-110, CARD_W, 'center')
                                end
                            end
                            
                            -- Show mana changes during reveal phase
                            if Game.state == "reveal" and c.manaChange then
                                local changeText = ""
                                if c.manaChange > 0 then
                                    changeText = "+" .. c.manaChange .. "M"
                                    lg.setColor(0,1,0)  -- Green
                                elseif c.manaChange < 0 then
                                    changeText = c.manaChange .. "M"
                                    lg.setColor(1,0,0)  -- Red
                                end
                                if changeText ~= "" then
                                    lg.printf(changeText, sx, rowY+CARD_H-130, CARD_W, 'center')
                                end
                            end
                        else
                            -- Draw face down card
                            lg.setColor(0.2,0.2,0.2)
                            lg.rectangle('fill',sx+2,rowY+2,CARD_W-4,CARD_H-4)
                            lg.setColor(0.4,0.4,0.4)
                            -- Draw card back pattern
                            for i=1,3 do
                                for j=1,2 do
                                    local patternX = sx + (CARD_W-4)/4 * i
                                    local patternY = rowY + (CARD_H-4)/3 * j
                                    lg.circle('fill', patternX, patternY, 5)
                                end
                            end
                        end
                    end
                end
            end
        end

        -- Draw player hand & piles
        local p1=Game.players[1]
        local totalW=#p1.hand*CARD_W+(#p1.hand-1)*GAP
        local hx=(w-totalW)/2
        local hy=laneY+laneH+laneGap
        for i,c in ipairs(p1.hand) do
            local sx=hx+(i-1)*(CARD_W+GAP)
            lg.setColor(1,1,1);lg.rectangle('line',sx,hy,CARD_W,CARD_H)
            lg.printf(c.def.name or "",sx,hy+8,CARD_W,'center')
            local img = c.def.image
            if img then
                local iw,ih = img:getDimensions()
                local scale = math.min((CARD_W*0.6)/iw,(CARD_H*0.45)/ih)
                lg.draw(img,sx+(CARD_W-iw*scale)/2,hy+40,0,scale,scale)
            end
            lg.print("C:"..(c.cost or 0),sx+10,hy+CARD_H-90)
            -- Draw power, blue if set by ability this reveal
            if Game.state == "reveal" and c.powerSetThisReveal then
                lg.setColor(0.2,0.6,1) -- Blue
            else
                lg.setColor(1,1,1)
            end
            lg.print("P:"..(c.power or 0),sx+CARD_W-40,hy+CARD_H-90)
            lg.setColor(1,1,1)
            lg.printf(c.def.text or "",sx+10,hy+CARD_H-70,CARD_W-20,'center')
        end

        local pileW,pileH=CARD_W*0.8,CARD_H*0.8
        lg.setColor(0.3,0.3,0.3)
        lg.rectangle('line',laneGap,hy,pileW,pileH)
        lg.printf(tostring(#p1.deck.cards),laneGap,hy+pileH+5,pileW,'center')
        lg.printf('Deck',laneGap,hy-20,pileW,'center')
        local dx=w-laneGap-pileW
        lg.rectangle('line',dx,hy,pileW,pileH)
        lg.printf(tostring(#p1.deck.discardPile),dx,hy+pileH+5,pileW,'center')
        lg.printf('Discard',dx,hy-20,pileW,'center')

        -- Next button
        local bw, bh = CARD_W*0.8, CARD_H*0.5
        local sbx = (w - (MAX_HAND*CARD_W + (MAX_HAND-1)*GAP))/2 + (MAX_HAND*CARD_W + GAP*(MAX_HAND))
        local sby = hy + (CARD_H - bh)/2
        lg.setColor(0.85,0.85,0.85)
        lg.rectangle('fill',sbx,sby,bw,bh,6,6)
        lg.setColor(0,0,0);lg.printf("Next",sbx,sby+(bh-18)/2,bw,'center')

        -- Mana & Scores
        lg.setColor(1,1,1)
        lg.print("Mana: "..p1.mana,20,20)
        lg.print("Score: "..p1.score,20,60)
        lg.print("Enemy Score: "..Game.players[2].score,20,100)

        -- Drag preview scaled
        if self.dragging then
            local mx,my = love.mouse.getPosition()
            local img = self.dragging.card.def.image
            if img then
                local iw,ih = img:getDimensions()
                local scale = math.min((CARD_W*1.2)/iw,(CARD_H*1.2)/ih)
                lg.draw(img,mx-(iw*scale)/2,my-(ih*scale)/2,0,scale,scale)
            end
        end

        -- Game Over
        if Game.state=="gameover" then
            lg.setColor(0,0,0,0.7)
            lg.rectangle('fill',0,0,w,h)
            lg.setColor(1,0,0)
            lg.printf("Game Over",0,h/2-30,w,'center')
            
            -- New Game button
            local bw, bh = w*0.3, h*0.1
            local bx, by = (w-bw)/2, h/2+20
            lg.setColor(0.8,0.8,0.8)
            lg.rectangle('fill',bx,by,bw,bh,10,10)
            lg.setColor(0,0,0)
            lg.printf("New Game",bx,by+(bh-24)/2,bw,'center')
        end

        -- Only show enemy hand details if debug flag is true
        if UI.showEnemyHandDebug then
            -- Show enemy hand (for debugging)
            local p2=#Game.players[2].hand>0 and Game.players[2] or nil
            if p2 then
                local smallW, smallH = CARD_W*0.4, CARD_H*0.4
                local eh=#p2.hand
                local totalEW=eh*smallW+(eh-1)*(GAP*0.5)
                local ex=(w-totalEW)/2
                for i,c in ipairs(p2.hand) do
                    local sx=ex+(i-1)*(smallW+GAP*0.5)
                    lg.setColor(0.2,0.2,0.2); lg.rectangle('fill',sx,GAP,smallW,smallH)
                    lg.setColor(1,1,1); lg.printf(c.def.name or "",sx,GAP+4,smallW,'center')
                    lg.print("C:"..(c.cost or 0),sx+2,GAP+smallH-32)
                    lg.print("P:"..(c.power or 0),sx+2,GAP+smallH-16)
                end
            end
        end
    end
end

return UI
