module Simulations

using CSV
using DataFrames
using DelimitedFiles
using JSON
using Optim
using Statistics

import Base.show

include("Simulations_lists.jl")

function check_status(sim_name::String)
    files = readdir("simulations/$(sim_name)")
    if isempty(files)
        return 0
    elseif ("$(sim_name).inp" in files) && ("model_data.dat" in files)
        if "stresses_done" in files
            return 5
        elseif "rf_done" in files
            return 4
        elseif ("$(sim_name).lck" in files)
            return 2
        elseif ("$(sim_name).sta" in files)
            return 3
        else
            return 1
        end
    else
        return 99
    end
end

mutable struct Simulation
    status::Int
    name::String
    α::Number
    β::Number
    eps_fin::Tuple{Number, Number, Number}
    plot_status::Bool
    linear_max::Tuple{Number, Number, Number}
    lin_status::Int
    nonlinear_max::Tuple{Number, Number, Number}
    fail_status::Int

    function Simulation(name::String)
        status = check_status(name)
        α = 0.0
        β = 0.0
        eps_fin = (0.0,0.0,0.0)
        plot_status = true
        linear_max = (0.0,0.0,0.0)
        lin_status = 0
        nonlinear_max = (0.0,0.0,0.0)
        fail_status = 0

        if status == 5
            linear_max = Tuple(JSON.parsefile("simulations/$(name)/linear_stresses.dat"))
            nonlinear_max = Tuple(JSON.parsefile("simulations/$(name)/nonlinear_stresses.dat"))
        end
        return new(status, name, α, β, eps_fin, plot_status, linear_max, lin_status, nonlinear_max, fail_status)
    end
end

function show(io::IO, sim::Simulation)
    println(io, "Simulation($(sim.name) --> $(status[sim.status]))")
end

mutable struct Sampling
    simulations::Dict{String,Simulation}
    path::AbstractString

    function Sampling(path::AbstractString)
        simulations = Dict{String,Simulation}()
        cd(path)
        sampling_path = pwd()
        for f in readdir("simulations")
            simulations[f] = Simulation(f)
        end
        return new(simulations, sampling_path)
    end
end

function show(io::IO, samp::Sampling)
    println(io, "Sampling($(length(samp.simulations)) simulations)")
end

end # module
