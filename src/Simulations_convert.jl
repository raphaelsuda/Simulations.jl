function convert_model_data(df::DataFrame)
    for i in nrow(df)
        sim = Simulation(0, df[i,:names], df[i,:alpha], df[i,:beta], (df[i,:eps_xx], df[i,:eps_zz], df[i,:eps_xz]), true, (0.0,0.0,0.0), 0, (0.0,0.0,0.0), 0)
        write_model_data(sim)
    end
    return nothing
end

function convert_model_data(path::AbstractString)
    df = CSV.read(path)
    convert_model_data(df)
    return nothing
end