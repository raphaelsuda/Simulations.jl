module Simulations

using CSV
using DataFrames
using DelimitedFiles
using JSON
using Optim
using Statistics

import Base.show
export Sampling,
       filter_simulations

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

        if 1 <= status <= 5
            model_data = JSON.parsefile("simulations/$(name)/model_data.dat")
            α = model_data["α"]
            β = model_data["β"]
            eps_fin = Tuple(model_data["eps_fin"])
            plot_status = model_data["plot_status"]
        end

        if status == 5
            linear_max = Tuple(JSON.parsefile("simulations/$(name)/linear_stresses.dat"))
            nonlinear_max = Tuple(JSON.parsefile("simulations/$(name)/nonlinear_stresses.dat"))
        end
        return new(status, name, α, β, eps_fin, plot_status, linear_max, lin_status, nonlinear_max, fail_status)
    end
end

function show(io::IO, sim::Simulation)
    print(io, "Simulation($(sim.name) --> $(status[sim.status]))")
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
    print(io, "Sampling($(length(samp.simulations)) simulations)")
end

function initiate_sampling(path::AbstractString)
    cd(path)
    @info "Initiating sampling project in $(pwd())"
    for f in folder_structure
        isdir(f) ? nothing : mkdir(f)
    end
    return nothing
end

function filter_simulations(samp::Sampling, st::Int)
    simulations = Dict{String,Simulation}()
    if st in keys(status)
        for s in values(samp.simulations)
            if s.status == st
                simulations[s.name] = s
            end
        end
    else
        @warn "Unknown status code passed"
    end
    return simulations
end
    
function filter_simulations(samp::Sampling, st::String)
    simulations = Dict{String,Simulation}()
    if st in values(status)
        for s in values(samp.simulations)
            if status[s.status] == st
                simulations[s.name] = s
            end
        end
    else
        @warn "Unknown status code passed"
    end
    return simulations
end

function create_job(sim::Simulation, n_cpus::Int64)
    job_lines = ["#!/bin/bash",
                 "#\$ -cwd",
                 "#\$ -N $(sim.name)",
                 "#\$ -V",
                 "#\$ -pe openmpi_fill $(n_cpus)",
                 "#\$ -q nodes.q",
                 "#\$ -l h_rt=48:00:00",
                 "#\$ -M raphael.suda@tuwien.ac.at",
                 "#\$ -m beas",
                 "",
                 "echo `date`",
                 "echo \"running job $JOB_ID on $HOSTNAME\"",
                 "abq2019 job=$(sim.name) scratch=\"/scratch/tmp\" cpus=$(n_cpus) mp_mode=threads input=$(sim.name).inp interactive"]
    open("simulations/$(sim.name)/job.sh","w") do job
        for i in 1:length(job_lines)
            println(job,job_lines[i])
        end
    end
    return nothing
end

    


end # module
