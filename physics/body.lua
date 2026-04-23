-- body.lua: Celestial body class definition

local Body = {}
Body.__index = Body

function Body.new(x, y, vx, vy, mass, color)
    local self = setmetatable({}, Body)
    self.pos = {x = x, y = y}
    self.vel = {x = vx, y = vy}
    self.acc = {x = 0, y = 0}
    self.mass = mass
    self.color = color or {1, 1, 1}
    self.radius = math.log(mass + 1) * 5
    return self
end

function Body:get_kinetic_energy()
    return 0.5 * self.mass * (self.vel.x^2 + self.vel.y^2)
end

return Body