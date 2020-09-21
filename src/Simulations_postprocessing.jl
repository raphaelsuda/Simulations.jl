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
    cd(simulation_path)
    isdir("reaction_forces") ? nothing : mkdir("reaction_forces")
    @info "$(sim.name): Reading reaction forces from rpt"
    reaction_forces = Dict{String,Array{Number}}()
    for f in abaqus_report_files
        data = readdlm(joinpath("abaqus_reports",f), skipstart=2)
        time = data[:,1]
        rf = data[:,2]
        reaction_force_path = joinpath("reaction_forces","reaction_forces.dat")
        reaction_forces = Dict("time" => time, "$(f[:end-1])" => rf)
    end
    open(reaction_force_path,"w") do rff
        JSON.print(rff, reaction_forces)
    end
    return reaction_forces
end

