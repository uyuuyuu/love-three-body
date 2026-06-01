-- trail.lua: Double-layer trail renderer with fixed alpha transparency

local TrailRenderer = {}

function TrailRenderer.new(w, h)
    local self = setmetatable({}, {__index = TrailRenderer})
    self.canvas = love.graphics.newCanvas(w, h)
    self.infinite_canvas = love.graphics.newCanvas(w, h)
    
    -- Initialize clear to fully transparent
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setCanvas(self.infinite_canvas)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setCanvas()
    
    return self
end

function TrailRenderer:resize(w, h)
    self.canvas = love.graphics.newCanvas(w, h)
    self.infinite_canvas = love.graphics.newCanvas(w, h)
end

function TrailRenderer:get_body_color(body, s, v)
    local max_c = math.max(body.color[1], body.color[2], body.color[3], 1e-6)
    local r_h, g_h, b_h = body.color[1]/max_c, body.color[2]/max_c, body.color[3]/max_c
    local gray = (r_h + g_h + b_h) / 3
    local r_s = gray * (1 - s) + r_h * s
    local g_s = gray * (1 - s) + g_h * s
    local b_s = gray * (1 - s) + b_h * s
    return r_s * v, g_s * v, b_s * v
end

function TrailRenderer:draw(bodies)
    -- --- 1. Handle dynamic tail ---
    love.graphics.setCanvas(self.canvas)
    
    -- Fade logic: Reduce existing color and alpha via multiplication
    love.graphics.setBlendMode("multiply", "premultiplied")
    love.graphics.setColor(0.96, 0.96, 0.96, 0.96) -- The 0.96 here determines trail length
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Draw new trail points (must use alpha or screen mode to increase alpha channel)
    love.graphics.setBlendMode("alpha")
    for _, body in ipairs(bodies) do
        local r, g, b = self:get_body_color(body, 1.0, 1.0)
        love.graphics.setColor(r, g, b, 0.4) -- The 0.4 here ensures visibility
        love.graphics.circle("fill", body.pos.x, body.pos.y, body.radius * 0.8)
    end
    love.graphics.setCanvas()

    -- --- 2. Handle permanent trails ---
    love.graphics.setCanvas(self.infinite_canvas)
    love.graphics.setBlendMode("alpha")
    for _, body in ipairs(bodies) do
        -- Set infinite trail opacity to 0.2 with full brightness
        local r, g, b = self:get_body_color(body, 1.0, 1.0) 
        love.graphics.setColor(r, g, b, 0.15) 
        love.graphics.circle("fill", body.pos.x, body.pos.y, 1.5)
    end
    love.graphics.setCanvas()
end

function TrailRenderer:render()
    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Render order: draw infinite trails first, then overlay dynamic tails
    love.graphics.draw(self.infinite_canvas)
    love.graphics.draw(self.canvas)
    
    love.graphics.setBlendMode("alpha")
end

return TrailRenderer
