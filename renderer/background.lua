-- background.lua: Deep space and grid renderer

local Background = {}

function Background.new(w, h)
    local self = setmetatable({}, {__index = Background})
    self.width = w
    self.height = h
    
    -- Generate random starfield
    self.stars = {}
    for i = 1, 200 do
        table.insert(self.stars, {
            x = math.random() * w,
            y = math.random() * h,
            size = math.random() * 2,
            brightness = math.random() * 0.5 + 0.2
        })
    end
    
    return self
end

function Background:draw()
    -- 1. Draw very dark background color
    love.graphics.clear(0.02, 0.02, 0.05)
    
    -- 2. Draw static starfield
    for _, star in ipairs(self.stars) do
        love.graphics.setColor(1, 1, 1, star.brightness)
        love.graphics.circle("fill", star.x, star.y, star.size / 2)
    end
    
    -- 3. Draw coordinate grid (Torus topology aware)
    local gridSize = 100
    love.graphics.setLineWidth(1)
    
    -- Vertical lines
    for x = 0, self.width, gridSize do
        love.graphics.setColor(0.2, 0.4, 1.0, 0.1) -- Light blue grid lines
        love.graphics.line(x, 0, x, self.height)
    end
    
    -- Horizontal lines
    for y = 0, self.height, gridSize do
        love.graphics.setColor(0.2, 0.4, 1.0, 0.1)
        love.graphics.line(0, y, self.width, y)
    end
    
    -- Draw center cross reference lines
    love.graphics.setColor(0.2, 0.4, 1.0, 0.2)
    love.graphics.line(self.width/2, 0, self.width/2, self.height)
    love.graphics.line(0, self.height/2, self.width, self.height/2)
end

return Background
