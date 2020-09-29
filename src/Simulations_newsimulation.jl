# function for calculating strains
function strains(stiffness_t,stiffness_c,stresses,factor)
	stiffness = zeros(3,3)
	for i in 1:3
		if stresses[i] < 0
			stiffness[i,i] = stiffness_c[i,i]
		else
			stiffness[i,i] = stiffness_t[i,i]
		end
	end
	return stiffness\stresses * factor
end
# function for calculating stresses out of angles
function calc_stresses(r,α,β)
	τ_xz = r * sin(β)
	σ_xx = sqrt((r*cos(β))^2/(tan(α)^2 + 1))
	σ_zz = sqrt((r*cos(β))^2 - σ_xx^2)
	if α > 3π/2
		σ_zz = -σ_zz
	elseif α > π
		σ_xx = -σ_xx
		σ_zz = -σ_zz
	elseif α > π/2
		σ_xx = -σ_xx
	end
	return [σ_xx, σ_zz, τ_xz]
end
# function for generating model
function generate_model(temp_path,save_path,eps_xx,eps_zz,eps_xz;ecc=[])
	## load AbqModel
	# load file as AbqModel
	inp = AbqModel(temp_path)
	# set ecceptions for the mortar layer
	setEcceptions!(inp,ecc)
	# set reference axis to y-direction
	setRefAxis!(inp,"y")
	# set twodimensional periodicity
	setPBCdim!(inp,2)
	# designate the nodes
	nodeDesignation!(inp)
	# define the periodic boundary conditions
	pbc!(inp)
	# define the loadcase for vertical and horizontal in-plane loading
	lc = LoadCase("eps33",eps_xx,inp,true)+LoadCase("eps22",eps_zz,inp,true)+LoadCase("eps23",eps_xz,inp,true)
	# define output for new step
	op = [Output("Node", "CF"),
		  Output("Node", "VF"),
		  Output("Node", "U"),
		  Output("Node", "PHILSM"),
		  Output("Node", "PSILSM"),
		  Output("Element", "E"),
		  Output("Element", "S"),
		  Output("Element", "DAMAGEC"),
		  Output("Element", "DAMAGET"),
		  Output("Element", "PEEQ"),
		  Output("Element", "PEEQT"),
		  Output("Element", "SDEG")]
	# add the loadcase to the model
	addStep!(inp,lc,op)
	# define incrementation settings
	inp.steps[1].iMin = 1.0e-35
	inp.steps[1].iMax = 0.1
	inp.steps[1].iStart = 0.01
	inp.steps[1].iTot = 1.0
	inp.steps[1].stab = 0.0
	inp.steps[1].allsdtol = 0.0	
	# update the loaded input file
	update!(inp)
	# write the input-file to new path
	saveInp(inp,save_path)
end

function new_simulation(samp::Sampling, α::Number, β::Number; r=20.0)
    ID = samp.max_ID + 1
    samp.max_ID = ID
    sim_name = string(samp.name_template,"-",format("{1:03d}", ID))
    mkdir(joinpath(samp.path, "simulations", sim_name))
    stiffness_t = readdlm(joinpath(samp.path, "model_data", "stiffness_tension.dat"), ';')
    stiffness_c = readdlm(joinpath(samp.path, "model_data", "stiffness_compression.dat"), ';')
    loading_stress = calc_stresses(r, α, β)
    loading_strain = strains(stiffness_t, stiffness_c, loading_stress, 1.0)
    load_path = joinpath(samp.path, "templates", "$(samp.name_template)-Template.inp")
    save_path = joinpath(samp.path, "simulations", sim_name, "$(sim_name).inp")
    generate_model(load_path, save_path, loading_strain[1], loading_strain[2], loading_strain[3])
    run(`sed -i -e "s/Output, field/Output, field, frequency=5/g" $(save_path)`)
    run(`sed -i -e "s/\*Node Output, nset=SWB/\*Output, field\n\*Node Output, nset=SWB/" $(save_path)`)
    simulation = Simulation(1, sim_name,ID, α, β,
                            (loading_strain[1], loading_strain[2], loading_strain[3]),
                            false, (0,0,0), 0, (0,0,0), 0)
    samp.simulations[sim_name] = simulation
    write_model_data(simulation)
    return nothing  
end