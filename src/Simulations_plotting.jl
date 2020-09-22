function scatter_sampling(samp::Sampling; show_text=true, show_linear=true, title="", xlims=:none, ylims=:none) 
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
	if show_text
		scatter!(p, plot_simulations_data[!,:sig_xx_nonlin], plot_simulations_data[!,:sig_zz_nonlin], zcolor=plot_simulations_data[!,:sig_xz_nonlin], m = (:heat), label="overall max", series_annotations = Plots.text.(plot_simulations_data["simulation"], 3, :gray, :topleft))
	else
		scatter!(p, plot_simulations_data[!,:sig_xx_nonlin], plot_simulations_data[!,:sig_zz_nonlin], zcolor=plot_simulations_data[!,:sig_xz_nonlin], m = (:heat), label="overall max")
    end
    return p
end