-- integrator.lua: Numerical integrator

local G = 500000
local SOFTENING_SQ = 100

local Integrator = {}

-- Core logic: Minimum image explicit distance
local function get_periodic_delta(a_pos, b_pos, width, height)
    local dx = b_pos.x - a_pos.x
    local dy = b_pos.y - a_pos.y

    if dx > width / 2 then dx = dx - width
    elseif dx < -width / 2 then dx = dx + width end

    if dy > height / 2 then dy = dy - height
    elseif dy < -height / 2 then dy = dy + height end

    return dx, dy
end

function Integrator.compute_accelerations(bodies, width, height)
    local accs = {}
    for i = 1, #bodies do
        accs[i] = {x = 0, y = 0}
    end

    for i = 1, #bodies do
        for j = i + 1, #bodies do
            local a, b = bodies[i], bodies[j]
            local dx, dy = get_periodic_delta(a.pos, b.pos, width, height)
            local distSq = dx * dx + dy * dy

            local distSqSoftened = distSq + SOFTENING_SQ
            local forceMag = G / (distSqSoftened * math.sqrt(distSqSoftened))

            accs[i].x = accs[i].x + dx * forceMag * b.mass
            accs[i].y = accs[i].y + dy * forceMag * b.mass
            accs[j].x = accs[j].x - dx * forceMag * a.mass
            accs[j].y = accs[j].y - dy * forceMag * a.mass
        end
    end
    return accs
end

function Integrator.update(bodies, dt, width, height, substeps, on_substep)
    substeps = substeps or 10
    local sdt = dt / substeps

    for _ = 1, substeps do
        for _, body in ipairs(bodies) do
            body.pos.x = (body.pos.x + body.vel.x * sdt + 0.5 * body.acc.x * sdt * sdt) % width
            body.pos.y = (body.pos.y + body.vel.y * sdt + 0.5 * body.acc.y * sdt * sdt) % height
        end

        local new_accs = Integrator.compute_accelerations(bodies, width, height)

        for i, body in ipairs(bodies) do
            body.vel.x = body.vel.x + 0.5 * (body.acc.x + new_accs[i].x) * sdt
            body.vel.y = body.vel.y + 0.5 * (body.acc.y + new_accs[i].y) * sdt
            body.acc = new_accs[i]
        end

        if on_substep then
            on_substep()
        end
    end
end

function Integrator.get_total_energy(bodies, width, height)
    local kinetic = 0
    local potential = 0
    for i, a in ipairs(bodies) do
        kinetic = kinetic + a:get_kinetic_energy()
        for j = i + 1, #bodies do
            local b = bodies[j]
            local dx, dy = get_periodic_delta(a.pos, b.pos, width, height)
            local distSq = dx * dx + dy * dy
            potential = potential - G * a.mass * b.mass / math.sqrt(distSq + SOFTENING_SQ)
        end
    end
    return kinetic + potential
end

return Integrator
