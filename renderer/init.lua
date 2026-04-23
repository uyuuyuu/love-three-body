-- renderer/init.lua: Renderer module entry point

local TrailRenderer = require("renderer.trail")
local BodyRenderer = require("renderer.body")
local BackgroundRenderer = require("renderer.background")

local Renderer = {
    shake = 0,
    show_ui = true
}

function Renderer.init(w, h)
    Renderer.trail = TrailRenderer.new(w, h)
    Renderer.background = BackgroundRenderer.new(w, h)
    Renderer.w = w
    Renderer.h = h
    Renderer.shake = 0
    Renderer.show_ui = true
end

function Renderer.resize(w, h)
    Renderer.w = w
    Renderer.h = h
    Renderer.trail:resize(w, h)
    Renderer.background = BackgroundRenderer.new(w, h)
end

function Renderer.clear_infinite_trails()
    if Renderer.trail then
        love.graphics.setCanvas(Renderer.trail.infinite_canvas)
        love.graphics.clear(0, 0, 0, 0)
        love.graphics.setCanvas()
    end
end

function Renderer.toggle_ui()
    Renderer.show_ui = not Renderer.show_ui
end

function Renderer.update(bodies)
    Renderer.trail:draw(bodies)
    
    -- Compute screen shake
    local max_acc = 0
    for _, b in ipairs(bodies) do
        local a = math.sqrt(b.acc.x^2 + b.acc.y^2)
        if a > max_acc then max_acc = a end
    end
    
    if max_acc > 500 then
        Renderer.shake = math.min(max_acc / 500, 10)
    end
    
    Renderer.shake = Renderer.shake * 0.9
end

function Renderer.render(bodies, total_energy, paused, symplecticity_report)
    -- First draw background
    Renderer.background:draw()

    love.graphics.push()
    if Renderer.shake > 0.1 then
        love.graphics.translate(math.random(-Renderer.shake, Renderer.shake), math.random(-Renderer.shake, Renderer.shake))
    end
    
    Renderer.trail:render()

    for _, body in ipairs(bodies) do
        BodyRenderer.draw(body)
    end
    love.graphics.pop()

    -- Draw UI
    if Renderer.show_ui then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Total Energy: " .. math.floor(total_energy), 10, 10)
        if symplecticity_report then
            love.graphics.print("Avg Energy: " .. math.floor(symplecticity_report.average_energy or 0), 10, 30)
        end
        love.graphics.print("Space: Pause | R: Reset | C: Clear Trails | H: Toggle UI", 10, 50)
        if paused then
            love.graphics.print("PAUSED", 10, 70)
        end

        if symplecticity_report then
            local y = 90
            love.graphics.print("=== Symplecticity ===", 10, y)
            love.graphics.print(string.format("Energy Error: %.2f", symplecticity_report.current_error or 0), 10, y + 20)
            love.graphics.print(string.format("Freq Bias: %d/%d (%+.2f)", 
                symplecticity_report.pos_count or 0, 
                symplecticity_report.neg_count or 0,
                symplecticity_report.freq_bias or 0), 10, y + 40)
            love.graphics.print(string.format("Mag Bias: %+.2f", 
                symplecticity_report.mag_bias or 0), 10, y + 60)
            love.graphics.print(string.format("Deviation: %.4f%%", (symplecticity_report.deviation or 0) * 100), 10, y + 80)
            love.graphics.print(string.format("Std Dev: %.2f", symplecticity_report.std_dev or 0), 10, y + 100)
            love.graphics.print(string.format("Drift Rate: %.4f", symplecticity_report.drift_rate or 0), 10, y + 120)
            love.graphics.print(string.format("Sym Metric: %.2f%%", (symplecticity_report.symplecticity or 0) * 100), 10, y + 140)
            love.graphics.print(string.format("Max Error: %.2f", symplecticity_report.max_error or 0), 10, y + 160)
            love.graphics.print(string.format("Min Error: %.2f", symplecticity_report.min_error or 0), 10, y + 180)
        end
    end
end

return Renderer
