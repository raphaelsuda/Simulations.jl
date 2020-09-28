module Simulations

using AbaqusUnitCell
using CSV
using DataFrames
using DelimitedFiles
using Formatting
using JSON
using Optim
using Statistics
using StringArrayEditor
using Plots

import Base.show
export Sampling,
       initiate_sampling,
       filter_simulations,
       extract_reaction_forces,
       compute_stresses,
       run_simulation,
       set_plot_status,
       check_progress,
       collect_failure_data,
       scatter_sampling,
       scatter_sampling!,
       contour_lourenco,
       contour_lourenco!

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
    ID::Int64
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
        ID = parse(Int64, split(name,'-')[end])
        α = 0.0
        β = 0.0
        eps_fin = (0.0,0.0,0.0)
        plot_status = false
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
            linear_max = Tuple(JSON.parsefile("simulations/$(name)/stresses/linear_stresses.dat"))
            nonlinear_max = Tuple(JSON.parsefile("simulations/$(name)/stresses/nonlinear_stresses.dat"))
        end
        return new(status, name, ID, α, β, eps_fin, plot_status, linear_max, lin_status, nonlinear_max, fail_status)
    end
    
    function Simulation(status::Int64, name::String, ID::Int64, α::Number, β::Number, eps_fin::Tuple{Number, Number, Number},
                        plot_status::Bool, linear_max::Tuple{Number, Number, Number}, lin_status::Int64, nonlinear_max::Tuple{Number, Number, Number}, fail_status::Int64)
        return new(status, name, ID, α, β, eps_fin, plot_status, linear_max, lin_status, nonlinear_max, fail_status)
    end
end


function show(io::IO, sim::Simulation)
    print(io, "Simulation($(sim.name) --> $(status[sim.status]), plot_status=$(sim.plot_status))")
end

mutable struct Sampling
    simulations::Dict{String,Simulation}
    path::AbstractString
    dim::Array{Number}
    area::Array{Number}
    max_ID::Int64
    template_path::Abstract
    name_template::String
    
    function Sampling(path::AbstractString, template_path::AbstractString)
        simulations = Dict{String,Simulation}()
        cd(path)
        sampling_path = pwd()
        name_template = join(split(splitpath(template_path)[end], '-')[1:end-1], '-')
        if "dimensions.dat" in readdir(joinpath(path, "model_data"))
            dim = JSON.parsefile(joinpath(path,"model_data","dimensions.dat"))
            if "area.dat" in readdir(joinpath(path,"model_data"))
                area = JSON.parsefile(joinpath(path,"model_data","area.dat"))
            else
                area = zeros(3)
                area[1] = dim[2] * dim[3]
                area[2] = dim[1] * dim[3]
                area[3] = dim[1] * dim[2]
                open(joinpath(path,"model_data","area.dat"), "w") do af
                    JSON.print(af, area)
                end
            end
        else
            inp = AbqModel(template_path)
            area = zeros(3)
            area[1] = inp.dim[2] * inp.dim[3]
            area[2] = inp.dim[1] * inp.dim[3]
            area[3] = inp.dim[1] * inp.dim[2]
            open(joinpath(path,"model_data","dimensions.dat"), "w") do df
                JSON.print(df, inp.dim)
            end
            open(joinpath(path,"model_data","area.dat"), "w") do af
                JSON.print(af, area)
            end
        end
        for f in readdir("simulations")
            simulations[f] = Simulation(f)
        end
        IDs = map(collect(keys(simulations))) do sn
            return parse(Int64, split(sn,'-')[end])
        end
        max_ID = maximum(IDs)
        return new(simulations, sampling_path, dim, area, max_ID, joinpath(sampling_path, template_path), name_template)
    end
end

function show(io::IO, samp::Sampling)
    print(io, "Sampling($(length(samp.simulations)) simulations)")
end

function write_model_data(sim::Simulation)
    model_data = Dict("name" => sim.name,
                      "ID" => sim.ID,
                      "α" => sim.α,
                      "β" => sim.β,
                      "eps_fin" => sim.eps_fin,
                      "plot_status" => sim.plot_status)
    open("simulations/$(sim.name)/model_data.dat","w") do md
        JSON.print(md, model_data)
    end
    return sim.name
end

function set_plot_status(samp::Sampling, sim_name::String, plot_st::Bool)
    if sim_name in keys(samp.simulations)
        samp.simulations[sim_name].plot_status = plot_st
        write_model_data(samp.simulations[sim_name])
        return plot_st
    end
    @warn "Simulation $(sim_name) not found in given Sampling."
end

function set_plot_status(samp::Sampling, sim_names::Array{String,1}, plot_st::Bool)
    for s in sim_names
        set_plot_status(samp, s, plot_st)
    end
    return plot_st
end

function initiate_sampling(path::AbstractString)
    cd(path)
    @info "Initiating sampling project in $(pwd())"
    for f in folder_structure
        isdir(f) ? nothing : mkdir(f)
    end
    return nothing
end

function filter_simulations(simulations::Dict{String,Simulation}, st::Int)
    filtered_simulations = Dict{String,Simulation}()
    if st in keys(status)
        for s in values(simulations)
            if s.status == st
                filtered_simulations[s.name] = s
            end
        end
    else
        @warn "Unknown status code passed"
    end
    return filtered_simulations
end

function filter_simulations(simulations::Dict{String,Simulation}, st::String)
    filtered_simulations = Dict{String,Simulation}()
    if st in values(status)
        for s in values(simulations)
            if status[s.status] == st
                filtered_simulations[s.name] = s
            end
        end
    else
        @warn "Unknown status code passed"
    end
    return filtered_simulations
end

function filter_simulations(simulations::Dict{String,Simulation}, plot_st::Bool)
    filtered_simulations = Dict{String,Simulation}()
    for s in values(simulations)
        if s.plot_status == plot_st
            filtered_simulations[s.name] = s
        end
    end
    return filtered_simulations
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

function filter_simulations(samp::Sampling, plot_st::Bool)
    simulations = Dict{String,Simulation}()
    for s in values(samp.simulations)
        if s.plot_status == plot_st
            simulations[s.name] = s
        end
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
                 "echo \"running job \$JOB_ID on \$HOSTNAME\"",
                 "abq2019 job=$(sim.name) scratch=\"/scratch/tmp\" cpus=$(n_cpus) mp_mode=threads input=$(sim.name).inp interactive"]
    open("simulations/$(sim.name)/job.sh","w") do job
        for i in 1:length(job_lines)
            println(job,job_lines[i])
        end
    end
    return nothing
end

function create_job(sim_name::String, n_cpus::Int64; simulation_folder="simulations")
    job_lines = ["#!/bin/bash",
                 "#\$ -cwd",
                 "#\$ -N $(sim_name)",
                 "#\$ -V",
                 "#\$ -pe openmpi_fill $(n_cpus)",
                 "#\$ -q nodes.q",
                 "#\$ -l h_rt=48:00:00",
                 "#\$ -M raphael.suda@tuwien.ac.at",
                 "#\$ -m beas",
                 "",
                 "echo `date`",
                 "echo \"running job \$JOB_ID on \$HOSTNAME\"",
                 "abq2019 job=$(sim_name) scratch=\"/scratch/tmp\" cpus=$(n_cpus) mp_mode=threads input=$(sim_name).inp interactive"]
    open(joinpath(simulation_folder, sim_name, "job.sh"),"w") do job
        for i in 1:length(job_lines)
            println(job,job_lines[i])
        end
    end
    return nothing
end

function collect_failure_data(samp::Sampling)
    plot_simulations = filter_simulations(samp,true)
    sim_names = String[]
    sig_xx_lin = Float64[]
    sig_zz_lin = Float64[]
    sig_xz_lin = Float64[]
    sig_xx_nonlin = Float64[]
    sig_zz_nonlin = Float64[]
    sig_xz_nonlin = Float64[]
    for s in values(plot_simulations)
        push!(sim_names,s.name)
        lin_max = s.linear_max
        nonlin_max = s.nonlinear_max
        push!(sig_xx_lin,lin_max[1])
        push!(sig_zz_lin,lin_max[2])
        push!(sig_xz_lin,lin_max[3])
        push!(sig_xx_nonlin,nonlin_max[1])
        push!(sig_zz_nonlin,nonlin_max[2])
        push!(sig_xz_nonlin,nonlin_max[3])
    end
    plot_df = DataFrame(:simulation => sim_names,
                     :sig_xx_lin => sig_xx_lin,
                     :sig_zz_lin => sig_zz_lin,
                     :sig_xz_lin => sig_xz_lin,
                     :sig_xx_nonlin => sig_xx_nonlin,
                     :sig_zz_nonlin => sig_zz_nonlin,
                     :sig_xz_nonlin => sig_xz_nonlin)
    sort!(plot_df, :simulation)
    CSV.write("plot_failure_data.dat", plot_df)
    return plot_df
end

function run_simulation(sim::Simulation; n_cpus=4)
    create_job(sim, n_cpus)
    cd(joinpath("simulations",sim.name))
    run(`qsub job.sh`)
    cd("..")
    cd("..")
    return nothing
end

function run_simulation(samp::Sampling, n::Int64; random=true, n_cpus=4)
    simulations = filter_simulations(samp, 1)
    rand_pool = filter_simulations(samp, 1)
    if random
        simulations_to_run = String[]
        for i in 1:n
            new_sim = rand(collect(keys(rand_pool)))
            push!(simulations_to_run, new_sim)
            delete!(rand_pool, new_sim)
        end
        for s in simulations_to_run
            run_simulation(simulations[s]; n_cpus=n_cpus)
            samp.simulations[s].status = 2
        end
    end
    return simulations_to_run
end

function check_progress(sim::Simulation)
    if "$(sim.name).sta" in readdir(joinpath("simulations",sim.name))
        @info "$(sim.name):"
        run(`tail -n 1 $(joinpath("simulations",sim.name,"$(sim.name).sta"))`)
    else
        @info "$(sim.name):"
        println("   sta-file not written yet")
    end
    return nothing
end

function check_progress(samp::Sampling)
    simulations = filter_simulations(samp, 2)
    for s in values(simulations)
        check_progress(s)
    end
    return collect(keys(simulations))
end

function rename_simulation(samp::Sampling, sim_name::String, new_name::String)
    samp.simulations[sim_name].name = new_name
    cd(joinpath(samp.path, "simulations", sim_name))
    for f in readdir()
        if length(f) >= length(sim_name) && f[1:length(sim_name)] == sim_name
            ending = split(f,'.')[end]
            mv(f,"$(new_name).$(ending)")
        end
    end
    run(`sed -i -e 's/$(sim_name)/$(new_name)/g' job.sh`)
    run(`sed -i -e 's/$(sim_name)/$(new_name)/g' model_data.dat`)
    cd("..")
    mv(sim_name, new_name)
    cd(samp.path)
    return new_name
end

function rm_model(samp::Sampling, sim_name::String)
    delete!(samp.simulations, sim_name)
    sim_path = joinpath(samp.path, "simulations", sim_name)
    for f in readdir(sim_path)
        if isdir(joinpath(sim_path, f))
            for g in readdir(joinpath(sim_path, f))
                rm(joinpath(sim_path, f, g))
            end
        end
        rm(joinpath(sim_path, f))
    end
    rm(sim_path)
    return nothing
end

include("Simulations_newsimulation.jl")
include("Simulations_stiffness.jl")
include("Simulations_lourenco.jl")
include("Simulations_plotting.jl")
include("Simulations_convert.jl")
include("Simulations_postprocessing.jl")

end # module
