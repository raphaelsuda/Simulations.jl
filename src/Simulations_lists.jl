``` status

constant assigns model status message to status code integer
```
const status = Dict(    0 => "empty folder",
                        1 => "model created",
                        2 => "simulation running",
                        3 => "simulation finished",
                        4 => "reaction forces written",
                        5 => "failure stresses evaluated",
                        99=> "incomplete data")

``` lin_status

constant assigns linear status message to status code integer
```
const lin_status = Dict(    0 => "not evalueated",
                            1 => "totally linear",
                            2 => "nonlinear")

``` fail_status

constant assigns failure status message to status code integer
```
const fail_status = Dict(   0 => "not evaluated",
                            1 => "no significant decrease",
                            2 => "significant decrease",
                            3 => "increase after decrease")

``` folder_structure

folders which should be existing or created when initiating a Sampling
```
const folder_structure = ["figures",
                          "model_data",
                          "simulations",
                          "templates",
                          "stiffness_simulations"]

const abaqus_report_files = ["RF11.rpt",
                             "RF33.rpt",
                             "RF13.rpt",
                             "RF31.rpt"]

const stress_areas = Dict("RF11" => 1,
                          "RF33" => 3,
                          "RF13" => 1,
                          "RF31" => 3)

const stress_strain = Dict("sig_11" => 1,
                           "sig_33" => 2,
                           "sig_13" => 3)


const stress_indices = ["sig_11", "sig_33", "sig_13"]

const eff_strains_homo = Dict("eps33-t"=>(1.0,0.0,0.0),
				              "eps22-t"=>(0.0, 1.0, 0.0),
				              "eps23-t"=>(0.0, 0.0, 1.0),
				              "eps33-c"=>(-1.0, 0.0, 0.0),
				              "eps22-c"=>(0.0, -1.0, 0.0),
				              "eps23-c"=>(0.0, 0.0, -1.0))