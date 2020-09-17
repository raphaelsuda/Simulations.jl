module Simulations

using CSV
using DataFrames
using DelimitedFiles
using JSON
using Optim
using Statistics

import Base.show

include("Simulations_lists.jl")

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
        return new(0, name, 0.0, 0.0, (0.0,0.0,0.0), true, (0.0,0.0,0.0), 0, (0.0,0.0,0.0), 0)
    end
end

function show(io::IO, sim::Simulation)
    println(io, "Simulation($(name) --> $(status[sim.status]))")
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
    println(io, "Sampling($(length(samp.simulations)) simulations")
end

end # module
