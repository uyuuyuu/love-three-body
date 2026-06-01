-- physics/init.lua: Physics module entry point

local Body = require("physics.body")
local Integrator = require("physics.integrator")
local EnergyAnalyzer = require("physics.energy_analyzer")

local Physics = {
    bodies = {},
    paused = false,
    energy_analyzer = nil,
    sim_time = 0,
    total_time = 0,
    log_interval = 1.0,
    width = 800,
    height = 600
}

function Physics.init_system(w, h)
    Physics.width = w
    Physics.height = h
    
    local init_accs = Integrator.compute_accelerations(Physics.bodies, Physics.width, Physics.height)
    for i, body in ipairs(Physics.bodies) do
        body.acc = init_accs[i]
    end
    Physics.energy_analyzer = EnergyAnalyzer.new()
    Physics.energy_analyzer:record(Integrator.get_total_energy(Physics.bodies, Physics.width, Physics.height))
    Physics.sim_time = 0
    Physics.total_time = 0
end

function Physics.create_bodies(w, h)
    local cx, cy = w/2, h/2
    local r = 120
    local speed = 180
    local m = 15
    
    Physics.bodies = {}
    local colors = {{1, 0.4, 0.4}, {0.4, 1, 0.4}, {0.4, 0.4, 1}}
    
    for i = 1, 3 do
        local angle = (i-1) * (2 * math.pi / 3) - math.pi/2
        local px = cx + r * math.cos(angle)
        local py = cy + r * math.sin(angle)
        -- Tangential velocity: (-sin, cos)
        local vx = -speed * math.sin(angle)
        local vy = speed * math.cos(angle)
        
        table.insert(Physics.bodies, Body.new(px, py, vx, vy, m, colors[i]))
    end
    
    Physics.init_system(w, h)
end

function Physics.randomize_bodies(w, h)
    math.randomseed(os.time())
    Physics.bodies = {}
    local colors = {{1, 0.4, 0.4}, {0.4, 1, 0.4}, {0.4, 0.4, 1}}

    for i = 1, 3 do
        local x = math.random(w * 0.2, w * 0.8)
        local y = math.random(h * 0.2, h * 0.8)
        local vx = (math.random() - 0.5) * 500
        local vy = (math.random() - 0.5) * 500
        local mass = math.random(5, 25)
        table.insert(Physics.bodies, Body.new(x, y, vx, vy, mass, colors[i]))
    end
    
    Physics.init_system(w, h)
end

function Physics.update(dt)
    if Physics.paused then return end
    Integrator.update(Physics.bodies, dt, Physics.width, Physics.height, 10, function()
        if Physics.energy_analyzer then
            Physics.energy_analyzer:record(Integrator.get_total_energy(Physics.bodies, Physics.width, Physics.height))
        end
    end)

    Physics.sim_time = Physics.sim_time + dt
    Physics.total_time = Physics.total_time + dt
    if Physics.sim_time >= Physics.log_interval then
        Physics.sim_time = Physics.sim_time - Physics.log_interval
        Physics.log_status()
    end
end
function Physics.log_status()
    local report = Physics.get_symplecticity_report()
    local current_energy = Integrator.get_total_energy(Physics.bodies, Physics.width, Physics.height)
    if report then
        print(string.format("[%.1fs] E_avg: %.2f | Err: %.2f | Bias(Mag): %+.2f | Drift: %.4f | Sym: %.2f%%",
            Physics.total_time,
            report.average_energy,
            report.current_error,
            report.mag_bias,
            report.drift_rate,
            (report.symplecticity or 0) * 100))
    end
end
function Physics.get_total_energy()
    return Integrator.get_total_energy(Physics.bodies, Physics.width, Physics.height)
end

function Physics.toggle_pause()
    Physics.paused = not Physics.paused
end

function Physics.get_symplecticity_report()
    if Physics.energy_analyzer then
        return Physics.energy_analyzer:get_report()
    end
    return nil
end

function Physics.reset_energy_analyzer()
    if Physics.energy_analyzer then
        Physics.energy_analyzer:reset()
        Physics.energy_analyzer:record(Integrator.get_total_energy(Physics.bodies))
    end
end

return Physics
