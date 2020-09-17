module Simulations

using CSV
using DataFrames
using DelimitedFiles
using JSON
using Optim
using Statistics

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

mutable struct Sampling
    simulations::Dict{String,Simulation}
    path::AbstractString

    function Sampling(path::AbstractString)
        simulations = Dict{String,Simulation}()
        for f in readdir("simulations")
            simulations[f] = Simulation(f)
        end
    end
end

end # module
