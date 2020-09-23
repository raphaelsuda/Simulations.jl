function scatter_sampling(samp::Sampling; show_text=true, show_linear=true, title="", xlims=:none, ylims=:none, save_plot=false, file="scatter_sampling.pdf") 
    plot_simulations_data = CSV.read("plot_failure_data.dat")
    n_simulations = nrow(plot_simulations_data)
    p = plot(legend = :bottomleft, title=title, xlims=xlims, ylims=ylims)
    if show_linear
        for i in 1:n_simulations
            line_xx = [plot_simulations_data[i,:sig_xx_lin], plot_simulations_data[i,:sig_xx_nonlin]]
            line_zz = [plot_simulations_data[i,:sig_zz_lin], plot_simulations_data[i,:sig_zz_nonlin]]
            plot!(p, line_xx, line_zz, color=:gray, style=:dash, label=:none)
        end
        scatter!(p, plot_simulations_data[!,:sig_xx_lin], plot_simulations_data[!,:sig_zz_lin], zcolor=plot_simulations_data[!,:sig_xz_lin], m = (:heat, :ltriangle), label="linear max")
    end
    names = map(plot_simulations_data[!,:simulation]) do s
        return split(s,'-')[end]
    end
	if show_text
		scatter!(p, plot_simulations_data[!,:sig_xx_nonlin], plot_simulations_data[!,:sig_zz_nonlin], zcolor=plot_simulations_data[!,:sig_xz_nonlin], m = (:heat), label="overall max", series_annotations = Plots.text.(names, 3, :gray))
	else
		scatter!(p, plot_simulations_data[!,:sig_xx_nonlin], plot_simulations_data[!,:sig_zz_nonlin], zcolor=plot_simulations_data[!,:sig_xz_nonlin], m = (:heat), label="overall max")
    end
    save_plot || file != "scatter_sampling.pdf" ? savefig(p,joinpath("figures",file)) : nothing
    return p
end

function scatter_sampling!(p::Plots.Plot,samp::Sampling; show_text=true, show_linear=true, title="", xlims=:none, ylims=:none) 
    plot_simulations_data = CSV.read("plot_failure_data.dat")
    n_simulations = nrow(plot_simulations_data)
    if show_linear
        for i in 1:n_simulations
            line_xx = [plot_simulations_data[i,:sig_xx_lin], plot_simulations_data[i,:sig_xx_nonlin]]
            line_zz = [plot_simulations_data[i,:sig_zz_lin], plot_simulations_data[i,:sig_zz_nonlin]]
            plot!(p, line_xx, line_zz, color=:gray, style=:dash, label=:none)
        end
        scatter!(p, plot_simulations_data[!,:sig_xx_lin], plot_simulations_data[!,:sig_zz_lin], zcolor=plot_simulations_data[!,:sig_xz_lin], m = (:heat, :ltriangle), label="linear max")
    end
    names = map(plot_simulations_data[!,:simulation]) do s
        return split(s,'-')[end]
    end
	if show_text
		scatter!(p, plot_simulations_data[!,:sig_xx_nonlin], plot_simulations_data[!,:sig_zz_nonlin], zcolor=plot_simulations_data[!,:sig_xz_nonlin], m = (:heat), label="overall max", xlims=xlims, ylims=ylims, legend=:bottomleft, series_annotations = Plots.text.(names, 3, :gray))
	else
		scatter!(p, plot_simulations_data[!,:sig_xx_nonlin], plot_simulations_data[!,:sig_zz_nonlin], zcolor=plot_simulations_data[!,:sig_xz_nonlin], m = (:heat), label="overall max", xlims=xlims, ylims=ylims, legend=:bottomleft)
    end
    save_plot || file != "scatter_sampling.pdf" ? savefig(p,joinpath("figures",file)) : nothing
    return p
end

function plot_history(samp::Sampling; title="", save_plot=false, file="stresses_history.pdf")
    simulations = filter_simulations(samp, true)
    p = plot(title=title)
    for s in values(simulations)
        simulation_path = joinpath("simulations",s.name)
        stresses = JSON.parsefile(joinpath(simulation_path,"stresses","stresses.dat"))
        plot!(p,stresses["sig_11"],stresses["sig_33"])
    end
    save_plot || file != "stresses_history.pdf" ? savefig(p,joinpath("figures",file)) : nothing
    return p
end

function contour_lourenco(samp::Sampling,xlims::Tuple{Number,Number},ylims::Tuple{Number,Number}; save_plot=false, file="contour_lourenco.pdf")
    parameters = JSON.parsefile(joinpath(samp.path,"model_data","lourenco_parameters_optim.dat"))
    x = xlims[1]:0.1:xlims[2]
    y = ylims[1]:0.1:ylims[2]
    n_x = length(x)
    n_y = length(y)
    τ = zeros(n_y,n_x)
    for i in 1:n_y
        for j in 1:n_x
            τ[i,j] = τ_lourenco(x[j],y[i],Lourenco(parameters["f_tx"], parameters["f_tz"], parameters["f_mx"], parameters["f_mz"], parameters["f_α"], parameters["f_β"], parameters["f_γ"]))
        end
    end
    c = contour(x,y,τ,color=:heat)
    save_plot || file != "contour_lourenco.pdf" ? savefig(c,joinpath("figures",file)) : nothing
    return c
end

function contour_lourenco!(p::Plots.Plot,samp::Sampling,xlims::Tuple{Number,Number},ylims::Tuple{Number,Number}; save_plot=false, file="contour_lourenco.pdf")
    parameters = JSON.parsefile(joinpath(samp.path,"model_data","lourenco_parameters_optim.dat"))
    x = xlims[1]:0.1:xlims[2]
    y = ylims[1]:0.1:ylims[2]
    n_x = length(x)
    n_y = length(y)
    τ = zeros(n_y,n_x)
    for i in 1:n_y
        for j in 1:n_x
            τ[i,j] = τ_lourenco(x[j],y[i],Lourenco(parameters["f_tx"], parameters["f_tz"], parameters["f_mx"], parameters["f_mz"], parameters["f_α"], parameters["f_β"], parameters["f_γ"]))
        end
    end
    save_plot || file != "contour_lourenco.pdf" ? savefig(c,joinpath("figures",file)) : nothing
    contour!(p,x,y,τ,color=:heat)
    return p
end