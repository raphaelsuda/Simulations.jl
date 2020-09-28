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
    @info "Generating $(simulation_name)"
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
    for lc in loadcases
        simulation_name = "$(samp.name_template)-Elastic-$(filenames[lc])"
        # path of the directory
        dirname = joinpath(samp.path,"stiffness_simulations",simulation_name)
        # path of the input file
        simulation_path = joinpath("$(dirname)","$(simulation_name).inp")
        # create directory models if it doesn't exist
        isdir(dirname) ? nothing : mkdir(dirname)
        # check if input file exists
        if isfile(simulation_path)
            @info "File $(simulation_name) exists"
        else
            strains = eff_strains_homo[lc]
            generate_elastic_model(elas_path, simulation_path, strains[1], strains[2], strains[3])
        end
        # check if odb file exists (calculation already done
        if isfile(joinpath(dirname,"$(simulation_name).odb"))
            @info "Results for $(simulation_name) exist"
            calc_stat[lc] = true
        else
            # check if bash file for submitting job is existing
            if isfile(joinpath(dirname,"job.sh"))
                @info "Job file exists"
            else
                @info "Generating job file"
                create_job(simulation_name, 4, simulation_folder="stiffness_simulations")
            end
        end
    end
end