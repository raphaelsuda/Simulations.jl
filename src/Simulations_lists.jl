const status = Dict(    0 => "empty folder",
                        1 => "model created",
                        2 => "simulation running",
                        3 => "simulation finished",
                        4 => "reaction forces written",
                        5 => "failure stresses evaluated",
                        99=> "incomplete data")

const lin_status = Dict(    0 => "not evalueated",
                            1 => "totally linear",
                            2 => "nonlinear")

const fail_status = Dict(   0 => "not evaluated",
                            1 => "no significant decrease",
                            2 => "significant decrease",
                            3 => "increase after decrease")