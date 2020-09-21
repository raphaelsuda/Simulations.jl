function extract_reaction_forces(sim::Simulation)
    #TODO exception if simulation not ready yet
    # python files have to be executed in the simulation path
    simulation_path = joinpath("simulations", sim.name)
    python_template_path = joinpath("python","reaction_forces.py")
    cp(python_template_path,simulation_path)
    cd(simulation_path)
    run(`sed -i -e "s/XXXX/$(sim.name)/g" reaction_forces.py`)
    run(`abq2019 cae noGUI=reaction_forces.py`)
    rm("reaction_forces.py")
    open("rf_done","w") do f
    end
    cd("..")
    cd("..")
    return nothing
end
    