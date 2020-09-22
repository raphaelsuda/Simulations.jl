function reaction_forces_template(sim::Simulation)
    lines = ["from abaqus import *",
    "from abaqusConstants import *",
    "session.Viewport(name='Viewport: 1', origin=(0.0, 0.0), width=268.952117919922,",
    "height=154.15299987793)",
    "session.viewports['Viewport: 1'].makeCurrent()",
    "session.viewports['Viewport: 1'].maximize()",
    "from caeModules import *",
    "from driverUtils import executeOnCaeStartup",
    "executeOnCaeStartup()",
    "name='$(sim.name).odb'",
    "o1 = session.openOdb(name)",
    "session.viewports['Viewport: 1'].setValues(displayedObject=o1)",
    "session.xyDataListFromField(odb=o1, outputPosition=NODAL, variable=(('RF', NODAL, ((COMPONENT, 'RF1'), (COMPONENT, 'RF3'))), ), nodeSets=('SEB', 'SET', 'NWB', 'NWT', ))",
    "nodeSEB = session.odbs[name].rootAssembly.nodeSets[\"SEB\"].nodes[0][0].label",
    "nodeSET = session.odbs[name].rootAssembly.nodeSets[\"SET\"].nodes[0][0].label",
    "nodeNWB = session.odbs[name].rootAssembly.nodeSets[\"NWB\"].nodes[0][0].label",
    "nodeNWT = session.odbs[name].rootAssembly.nodeSets[\"NWT\"].nodes[0][0].label",
    "instanceSEB = session.odbs[name].rootAssembly.nodeSets[\"SEB\"].instanceNames[0]",
    "instanceSET = session.odbs[name].rootAssembly.nodeSets[\"SET\"].instanceNames[0]",
    "instanceNWB = session.odbs[name].rootAssembly.nodeSets[\"NWB\"].instanceNames[0]",
    "instanceNWT = session.odbs[name].rootAssembly.nodeSets[\"NWT\"].instanceNames[0]",
    "rf1_SEB = session.xyDataObjects['RF:RF1 PI: '+instanceSEB+' N: '+str(nodeSEB)]",
    "rf1_SET = session.xyDataObjects['RF:RF1 PI: '+instanceSET+' N: '+str(nodeSET)]",
    "rf1_NWB = session.xyDataObjects['RF:RF1 PI: '+instanceNWB+' N: '+str(nodeNWB)]",
    "rf1_NWT = session.xyDataObjects['RF:RF1 PI: '+instanceNWT+' N: '+str(nodeNWT)]",
    "rf3_SEB = session.xyDataObjects['RF:RF3 PI: '+instanceSEB+' N: '+str(nodeSEB)]",
    "rf3_SET = session.xyDataObjects['RF:RF3 PI: '+instanceSET+' N: '+str(nodeSET)]",
    "rf3_NWB = session.xyDataObjects['RF:RF3 PI: '+instanceNWB+' N: '+str(nodeNWB)]",
    "rf3_NWT = session.xyDataObjects['RF:RF3 PI: '+instanceNWT+' N: '+str(nodeNWT)]",
    "rf11 = sum((rf1_SEB, rf1_SET))",
    "rf11.setValues(",
    "    sourceDescription='sum ( ( \"RF:RF1 PI: '+instanceSEB+' N: +str(nodeSEB)\", \"RF:RF1 PI: '+instanceSET+' N: +str(nodeSET)\" ) )')",
    "tmpName = rf11.name",
    "session.xyDataObjects.changeKey(tmpName, 'RF11')",
    "x0 = session.xyDataObjects['RF11']",
    "session.writeXYReport(fileName='abaqus_reports/RF11.rpt', appendMode=OFF, xyData=(x0, ",
    "    ))",
    "rf33 = sum((rf3_NWB, rf3_NWT))",
    "rf33.setValues(",
    "    sourceDescription='sum ( ( \"RF:RF3 PI: '+instanceNWB+' N: +str(nodeNWB)\", \"RF:RF1 PI: '+instanceNWT+' N: +str(nodeNWT)\" ) )')",
    "tmpName = rf33.name",
    "session.xyDataObjects.changeKey(tmpName, 'RF33')",
    "x0 = session.xyDataObjects['RF33']",
    "session.writeXYReport(fileName='abaqus_reports/RF33.rpt', appendMode=OFF, xyData=(x0, ",
    "    ))",
    "rf13 = sum((rf3_SEB, rf3_SET))",
    "rf13.setValues(",
    "    sourceDescription='sum ( ( \"RF:RF3 PI: '+instanceSEB+' N: +str(nodeSEB)\", \"RF:RF3 PI: '+instanceSET+' N: +str(nodeSET)\" ) )')",
    "tmpName = rf13.name",
    "session.xyDataObjects.changeKey(tmpName, 'RF13')",
    "x0 = session.xyDataObjects['RF13']",
    "session.writeXYReport(fileName='abaqus_reports/RF13.rpt', appendMode=OFF, xyData=(x0, ",
    "    ))",
    "rf31 = sum((rf1_NWB, rf1_NWT))",
    "rf31.setValues(",
    "    sourceDescription='sum ( ( \"RF:RF1 PI: '+instanceNWB+' N: +str(nodeNWB)\", \"RF:RF1 PI: '+instanceNWT+' N: +str(nodeNWT)\" ) )')",
    "tmpName = rf31.name",
    "session.xyDataObjects.changeKey(tmpName, 'RF31')",
    "x0 = session.xyDataObjects['RF31']",
    "session.writeXYReport(fileName='abaqus_reports/RF31.rpt', appendMode=OFF, xyData=(x0, ",
    "    ))"]
    python_file_path = joinpath("simulations",sim.name,"reaction_forces.py")
    open(python_file_path,"w") do pf
        for l in lines
            println(pf,l)
        end
    end
end

function extract_reaction_forces(sim::Simulation)
    #TODO exception if simulation not ready yet
    # python files have to be executed in the simulation path
    simulation_path = joinpath("simulations", sim.name)
    reaction_forces_template(sim)
    cd(simulation_path)
    isdir("abaqus_reports") ? nothing : mkdir("abaqus_reports")
    @info "$(sim.name): Extracting reaction forces from odb"
    run(`abq2019 cae noGUI=reaction_forces.py`)
    rm("reaction_forces.py")
    open("rf_done","w") do f
    end
    cd("..")
    cd("..")
    return nothing
end
    
function extract_reaction_forces(samp::Sampling)
    simulations = filter_simulations(samp, 3)
    for s in values(simulations)
        extract_reaction_forces(s)
    end
    return nothing
end

function read_reaction_forces(sim::Simulation)
    #TODO exception if reaction forces not written yet
    simulation_path = joinpath("simulations", sim.name)
    isdir(joinpath(simulation_path,"reaction_forces")) ? nothing : mkdir(joinpath(simulation_path,"reaction_forces"))
    @info "$(sim.name): Reading reaction forces from rpt"
    reaction_forces = Dict{String,Array{Number}}()
    for f in abaqus_report_files
        data = readdlm(joinpath(simulation_path,"abaqus_reports",f), skipstart=2)
        time = data[:,1]
        rf = data[:,2]
        "time" ∈ keys(reaction_forces) ? nothing : reaction_forces["time"] = time
        reaction_forces["$(f[1:end-4])"] = rf
    end
    reaction_force_path = joinpath(simulation_path,"reaction_forces","reaction_forces.dat")
    open(reaction_force_path,"w") do rff
        JSON.print(rff, reaction_forces)
    end
    return reaction_forces
end

function compute_stresses(sim::Simulation, area::Array{Number})
    read_reaction_forces(sim)
    simulation_path = joinpath("simulations", sim.name)
    isdir(joinpath(simulation_path,"stresses")) ? nothing : mkdir(joinpath(simulation_path,"stresses"))
    @info "$(sim.name): Computing stresses"
    stresses = Dict{String,Array{Number}}()
    reaction_forces = JSON.parsefile(joinpath(simulation_path,"reaction_forces","reaction_forces.dat"))
    stresses["time"] = reaction_forces["time"]
    stresses["sig_11"] = reaction_forces["RF11"]./area[1]
    stresses["sig_33"] = reaction_forces["RF33"]./area[3]
    stresses["sig_13"] = 1/2 * (reaction_forces["RF13"]./area[1] + reaction_forces["RF31"]./area[3])
    stress_path = joinpath(simulation_path,"stresses", "stresses.dat")
    open(stress_path,"w") do sf
        JSON.print(sf, stresses)
    end
    open(joinpath(simulation_path,"stresses_done"), "w") do f
    end
    return stresses
end

function check_nonlin(time::Array{Number},rf::Array{Number},tol::Number,loading::Number)
    n_data = length(rf)

	if loading >-0.0001 && loading < 0.0001
		return n_data
	end
    drf_dt = zeros(n_data-1)

    for i in 1:n_data-1
        drf_dt[i] = (rf[i+1]-rf[i])/(time[i+1]-time[i])
    end

    stiff_ini = drf_dt[1]

    if (stiff_ini - rf[end]/time[end])/stiff_ini <= 0.1
        return n_data
    end

    for i in 2:n_data-1
        if (stiff_ini-drf_dt[i])/stiff_ini > tol
            return i
            break
        end
    end
    return n_data-1
end


function check_nonlin(stresses::Dict{String,Array{Number}},tol::Number,loading::Dict{String,Float64})
    linlim_ind = Dict{String,Int}()
    time = stresses["time"]

    for p in stress_indices
        linlim_ind[p] = check_nonlin(time,stresses[p],tol,loading[p])
    end

    linlim = Dict{String,Float64}()
    min_linlim_ind = minimum(values(linlim_ind))

    for p in stress_indices
        linlim[p] = stresses[p][min_linlim_ind]
    end
    return linlim
end

function check_max(rf::Array{Number}, tol::Number, loading::Number)
    n_data = length(rf)

	drf = zeros(n_data-1)
	
	if loading >-0.0001 && loading < 0.0001
		return n_data
	end

    for i in 1:n_data-1
        drf[i] = (rf[i+1]-rf[i])
    end

    for i in 2:n_data-1
        if drf[i]/rf[i] < -tol
            return i
        end
    end
    return n_data
end


function check_max(stresses::Dict{String,Array{Number}},tol::Number,loading::Dict{String,Float64})
    maxlim_ind = Dict{String,Int}()

    for p in stress_indices
        maxlim_ind[p] = check_max(stresses[p],tol,loading[p])
    end

    maxlim = Dict{String,Float64}()
    min_maxlim_ind = minimum(values(maxlim_ind))

    for p in stress_indices
        maxlim[p] = stresses[p][min_maxlim_ind]
    end
    return maxlim
end

function compute_stresses(samp::Sampling)
    simulations = filter_simulations(samp, 4)
    for s in values(simulations)
        stresses = compute_stresses(s, samp.area)
        loading = Dict("sig_11" => s.eps_fin[1], "sig_33" => s.eps_fin[2], "sig_13" => s.eps_fin[3])
        linlim = check_nonlin(stresses, 0.025, loading)
        maxlim = check_max(stresses, 0.05, loading)
        s.linear_max = (linlim["sig_11"], linlim["sig_33"], linlim["sig_13"])
        s.nonlinear_max = (maxlim["sig_11"], maxlim["sig_33"], maxlim["sig_13"])
        open(joinpath("simulations",s.name,"stresses","linear_stresses.dat"),"w") do lsf
            JSON.print(lsf,s.linear_max)
        end
        open(joinpath("simulations",s.name,"stresses","nonlinear_stresses.dat"),"w") do nlsf
            JSON.print(nlsf,s.nonlinear_max)
        end
    end
    return nothing
end