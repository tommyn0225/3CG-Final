-- src/game_log.lua
local GameLog = {}
GameLog.__index = GameLog

function GameLog.new()
    local self = setmetatable({}, GameLog)
    self.entries = {}
    self.maxEntries = 50  -- Maximum number of entries to keep
    self.isCollapsed = false
    self.scrollOffset = 0
    self.maxScrollOffset = 0
    return self
end

function GameLog:addEntry(text)
    table.insert(self.entries, 1, text)  -- Add to front
    if #self.entries > self.maxEntries then
        table.remove(self.entries)  -- Remove oldest entry
    end
    self.maxScrollOffset = math.max(0, #self.entries - 10)  -- Show 10 entries at a time
end

function GameLog:toggleCollapse()
    self.isCollapsed = not self.isCollapsed
end

function GameLog:scroll(direction)
    if direction > 0 then  -- Scroll up
        self.scrollOffset = math.max(0, self.scrollOffset - 1)
    else  -- Scroll down
        self.scrollOffset = math.min(self.maxScrollOffset, self.scrollOffset + 1)
    end
end

function GameLog:draw()
    local lg = love.graphics
    local w, h = lg.getWidth(), lg.getHeight()
    
    -- Draw log panel background
    local panelW = 300
    local panelH = self.isCollapsed and 30 or 250
    local panelX = 20
    local panelY = h - panelH - 20  -- Position at bottom left
    
    -- Draw panel background
    lg.setColor(0, 0, 0, 0.8)
    lg.rectangle('fill', panelX, panelY, panelW, panelH, 10, 10)
    
    -- Draw panel border
    lg.setColor(1, 1, 1, 0.5)
    lg.rectangle('line', panelX, panelY, panelW, panelH, 10, 10)
    
    -- Draw title
    lg.setColor(1, 1, 1)
    lg.printf("Game Log", panelX, panelY + 5, panelW, 'center')
    
    -- Draw collapse/expand button
    local btnW, btnH = 20, 20
    local btnX = panelX + panelW - btnW - 5
    local btnY = panelY + 5
    lg.setColor(0.7, 0.7, 0.7)
    lg.rectangle('fill', btnX, btnY, btnW, btnH, 5, 5)
    lg.setColor(0, 0, 0)
    lg.printf(self.isCollapsed and "+" or "-", btnX, btnY + 2, btnW, 'center')
    
    if not self.isCollapsed then
        -- Draw entries
        local entryY = panelY + 30
        local entryH = 20
        local visibleEntries = math.min(10, #self.entries - self.scrollOffset)
        
        for i = 1, visibleEntries do
            local entry = self.entries[i + self.scrollOffset]
            if entry then
                lg.setColor(1, 1, 1, 0.9)
                lg.printf(entry, panelX + 10, entryY + (i-1) * entryH, panelW - 20, 'left')
            end
        end
        
        -- Draw scroll indicators if needed
        if self.maxScrollOffset > 0 then
            lg.setColor(1, 1, 1, 0.5)
            if self.scrollOffset > 0 then
                lg.printf("↑", panelX + panelW - 20, panelY + 30, 20, 'center')
            end
            if self.scrollOffset < self.maxScrollOffset then
                lg.printf("↓", panelX + panelW - 20, panelY + panelH - 20, 20, 'center')
            end
        end
    end
end

return GameLog 