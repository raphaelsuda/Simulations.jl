# waits the given time and prints a countdown
function countdown(t)
	for i in t:-1:1
		print("$(i) ... ")
		sleep(1)
	end
	print("0\n")
end
# regular expression for finding numbers in input file
const num_re = r"-?\d+\.\d*(e-?\d+)?"
# function for deleting properties in input file
function delete_property!(file::StringArrayEditor.File,keyword::Regex)
	# find lines containing the given keyword
	lines = Lines(file,keyword)
	for l in lines
		# find range containing all data entries of the property
		range = Range(file,from=num_re,until=num_re,after=l)
		# delete data entries
		delete!(range)
		# delete keyword line
		delete!(l)
	end
end

# checks if last line of sta-file says that analysis has been completed
function check_sta(file::String)
	# if there is no sta-file, calculation has not started
	if isempty(readlines(file))
		return false
	# if there is a sta-file, calculation has already started
	# if the last line doesn't contain "THE ANALYSIS HAS COMPLETED SUCCESSFULLY"
	# the calculation is still running
	elseif match(r"THE ANALYSIS HAS COMPLETED SUCCESSFULLY",readlines(file)[end]) == nothing
		return false
	# the remaining case is fulfilled if there is a file and the last line requirement holds
	else
		return true
	end
end

# checks if last line of any sta-file in the directory says that analysis has been completed
function check_sta()
	# list of files
	files = readdir()
	# list of sta-files
	stas = files[match.(r"\.sta",files).!=nothing]
	# if list of sta-files is empty, calculation hase probably not started yet
	# else evaluate the status of all sta-files and return their product
	if isempty(stas)
		return false
	else
		return prod(check_sta.(stas))
	end
end


# reads maximum reaction force from abaqus report
function read_rf(file)
	# read given file
	data = readlines(file)
	# extract fifth line containing the wanted reaction force and split the line
	num = split(data[5])
	# return the reaction force as float number
	return parse(Float64,num[2])
end

function create_elastic_template(samp::Sampling)
    file_elas = joinpath(samp.path, "templates", "$(samp.name_template)-Elastic.inp")
    if isfile(file_elas)
        @info "Elastic template exists"
    else
        # load template input file
        file = load(samp.template_path)
        # delete enrichments from loaded file
        @info "Deleting Enrichments"
        delete!(Lines(file,r"Enrichment"))
        # delete material nonlinearities from input file
        @info "Deleting Material nonlinearities"
        delete_property!(file,r"Damage Initiation")
        delete_property!(file,r"Concrete Damaged Plasticity")
        delete_property!(file,r"Compression Hardening")
        delete_property!(file,r"Tension Stiffening")
        delete_property!(file,r"Fracture Criterion")
        # save elastic template file
        save(file,file_elas)
        @info "Elastic template written"
    end
    return file_elas
end

# function for generating model
function generate_elastic_model(temp_path,save_path,eps_xx,eps_zz,eps_xz)
    # load elastic input template as AbqModel
    inp = AbqModel(temp_path)
    # set unit cell to twodimensional periodicity
    setPBCdim!(inp,2)
    # set equation ecceptions for mortar layers
    setEcceptions!(inp,["M1-1-1","M1-2-1","M1-3-1","M1-4-1","M1-5-1","M1-6-1","M2-1-1","M2-2-1","M2-3-1","M2-4-1","M2-5-1","M2-6-1"])
    # set the reference axis (normal vector of the free surface) to y
    setRefAxis!(inp,"y")
    # define node sets for pbc
    nodeDesignation!(inp)
    # define pbc equations
    pbc!(inp)
    # define output variables
    op = [Output("Node","U")]
    # define loadcase, take value from dictionary eff_strains
	lc = LoadCase("eps33",eps_xx,inp,true)+LoadCase("eps22",eps_zz,inp,true)+LoadCase("eps23",eps_xz,inp,true)
    # add loadcase as step
    addStep!(inp,lc,op)
    # define incrementation settings
    inp.steps[1].iMin = 1.0
    inp.steps[1].iMax = 1.0
    inp.steps[1].iStart = 1.0
    inp.steps[1].iTot = 1.0
    inp.steps[1].stab = 0.0
    inp.steps[1].allsdtol = 0.0	
    # write new properties to input file
    update!(inp)
    # save input file as name
    saveInp(inp,save_path)
end

function compute_stiffness(samp::Sampling)
    elas_path = create_elastic_template(samp)
    # loadcases to be calculated
    loadcases = ["eps33-t","eps22-t","eps23-t","eps33-c","eps22-c","eps23-c"]
    # filename extensions for loadcases
    filenames = Dict("eps33-t"=>"Tension-XX","eps22-t"=>"Tension-ZZ","eps23-t"=>"Tension-XZ","eps33-c"=>"Compression-XX","eps22-c"=>"Compression-ZZ","eps23-c"=>"Compression-XZ")
    # initialize status dictionary for calculation of the loadcases
    calc_stat = Dict("eps33-t"=>false,"eps22-t"=>false,"eps23-t"=>false,"eps33-c"=>false,"eps22-c"=>false,"eps23-c"=>false)
    simulation_names = Dict{String,String}()
    elastic_simulations = Dict{String,Simulation}()
    for lc in loadcases
        simulation_names[lc] = "$(samp.name_template)-Elastic-$(filenames[lc])"
        strains = eff_strains_homo[lc] .* 0.01
        elastic_simulations[simulation_names[lc]] = Simulation(1, simulation_names[lc], 999, 0.0, 0.0, strains, false, (0.0, 0.0, 0.0), 0, (0.0, 0.0, 0.0), 0)
    end
    for lc in loadcases
        simulation_name = simulation_names[lc]
        # path of the directory
        dirname = joinpath(samp.path,"stiffness_simulations",simulation_name)
        # path of the input file
        simulation_path = joinpath("$(dirname)","$(simulation_name).inp")
        # create directory models if it doesn't exist
        isdir(dirname) ? nothing : mkdir(dirname)
        strains = elastic_simulations[simulation_name].eps_fin
        generate_elastic_model(elas_path, simulation_path, strains[1], strains[2], strains[3])
        create_job(simulation_name, 4, simulation_folder="stiffness_simulations")
        @info "Starting evaluation of $(simulation_name)"
        # submit job file            
        cd(dirname)
        run(`qsub job.sh`)
        cd(samp.path)
    end
    # check if results aready existed before file execution
    # 20 second sleep timer for waiting until existing sta files are deleted
    countdown(20)
    # if calculation is requested, check the sta files every 5 seconds
    cd("stiffness_simulations")
    status = false
    # as long as sta files dont say, that the calculation has been completed,
    # wait 5 seconds and check again
    while !status
        sleep(5)
        for d in readdir()
            status = true
            cd(d)
            status *= check_sta()
            cd("..")
        end
    end
    @info "All calculations finished!"
    countdown(20)
    cd("..")

    # read reaction forces from odb files
    cd("stiffness_simulations")
    for d in readdir()
        reaction_forces_template(elastic_simulations[d],simulation_folder="")
        cd(d)
        # create directory reaction_forces if not existing
        isdir("abaqus_reports") ? nothing : mkdir("abaqus_reports")
        # run abaqus and execute python script
        run(`abq2019 cae noGUI=reaction_forces.py`)
        cd("..")
    end
    cd("..")


end