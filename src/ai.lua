-- src/ai.lua
local AI = {}

-- Stage random plays for AI player
function AI.stageRandom(player, board)
    local available = true
    while available do
        available = false
        local choices = {}
        -- Gather all cards the AI can afford and has space for
        for _, c in ipairs(player.hand) do
            if player:canPlay(c) then
                for loc = 1, 3 do
                    if #board.slots[player.id][loc] < board.maxSlots then
                        table.insert(choices, c)
                        break
                    end
                end
            end
        end
        if #choices > 0 then
            available = true
            -- Pick one at random
            local card = choices[math.random(#choices)]
            -- Remove it from hand
            for i, hc in ipairs(player.hand) do
                if hc == card then
                    table.remove(player.hand, i)
                    break
                end
            end
            -- Choose a random valid lane
            local valid = {}
            for loc = 1, 3 do
                if #board.slots[player.id][loc] < board.maxSlots then
                    table.insert(valid, loc)
                end
            end
            local loc = valid[math.random(#valid)]
            board:placeCard(player.id, loc, card)
            player.mana = player.mana - card.cost
        end
    end
end

return AI
