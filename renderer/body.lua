-- body.lua: Constant hue celestial renderer (revised)

local BodyRenderer = {}

-- More balanced color application function
local function apply_sv(base_color, s, v)
    -- Extract hue base (normalized)
    local max_c = math.max(base_color[1], base_color[2], base_color[3], 1e-6)
    local r_h, g_h, b_h = base_color[1]/max_c, base_color[2]/max_c, base_color[3]/max_c
    
    -- Compute gray baseline (for desaturation)
    local gray = (r_h + g_h + b_h) / 3
    
    -- S (saturation): Interpolate between pure hue and gray
    local r_s = gray * (1 - s) + r_h * s
    local g_s = gray * (1 - s) + g_h * s
    local b_s = gray * (1 - s) + b_h * s
    
    -- V (value/brightness): Direct scaling
    return {r_s * v, g_s * v, b_s * v}
end

function BodyRenderer.draw(body)
    local speed = math.sqrt(body.vel.x^2 + body.vel.y^2)
    local acc_mag = math.sqrt(body.acc.x^2 + body.acc.y^2)
    
    -- V: Faster = brighter (0.3 -> 1.0)
    local v = 0.3 + 0.7 * math.min(speed / 400, 1.0)
    
    -- S: More acceleration = more vivid (0.6 -> 1.0) - Raise base saturation to prevent washing out
    local s = 0.6 + 0.4 * math.min(acc_mag / 2000, 1.0)
    
    local c = apply_sv(body.color, s, v)

    -- Draw outer glow
    love.graphics.setColor(c[1], c[2], c[3], 0.3 * v)
    love.graphics.circle("fill", body.pos.x, body.pos.y, body.radius * 3)
    
    -- Draw core
    love.graphics.setColor(c[1], c[2], c[3], 1.0)
    love.graphics.circle("fill", body.pos.x, body.pos.y, body.radius)
end

return BodyRenderer
