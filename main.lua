-- main.lua: Main entry point

local Physics = require("physics")
local Renderer = require("renderer")

function love.load()
    local w, h = love.graphics.getDimensions()
    Renderer.init(w, h)
    Physics.create_bodies(w, h)
end

function love.update(dt)
    Physics.update(dt)
    Renderer.update(Physics.bodies)
end

function love.draw()
    Renderer.render(Physics.bodies, Physics.get_total_energy(), Physics.paused, Physics.get_symplecticity_report())
end

function love.keypressed(key)
    if key == "r" then 
        local w, h = love.graphics.getDimensions()
        Physics.randomize_bodies(w, h)
        Renderer.clear_infinite_trails()
    end
    if key == "c" then Renderer.clear_infinite_trails() end
    if key == "h" then Renderer.toggle_ui() end
    if key == "space" then Physics.toggle_pause() end
end