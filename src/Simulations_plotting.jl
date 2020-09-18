function scatter_sampling(samp::Sampling; show_text=true, show_linear=true)
    plot_simulations_data = CSV.read("plot_simulations_data.dat")
    n_simulations = nrow(plot_simulations_data)
    if show_linear
        for i in 1:n_simulations
            line_xx = [plot_simulations_data[i,:sig_xx_lin] plot_simulations_data[i,:sig_xx_nonlin]]
            line_zz = [plot_simulations_data[i,:sig_zz_lin] plot_simulations_data[i,:sig_zz_nonlin]]
            plot!(p, line_xx, line_zz, color=:gray, style=:dash)
        end
        scatter!(p, plot_simulations_data[!,:sig_xx_lin], plot_simulations_data[!,:sig_zz_lin], zcolor=plot_simulations_data[!,:sig_xz_lin], markershape=:ltriangle)
    end
	if show_text
		scatter!(p, plot_simulations_data[!,:sig_xx_nonlin], plot_simulations_data[!,:sig_zz_nonlin], zcolor=plot_simulations_data[!,:sig_xz_nonlin])
	else
		scatter!(p, plot_simulations_data[!,:sig_xx_nonlin], plot_simulations_data[!,:sig_zz_nonlin], zcolor=plot_simulations_data[!,:sig_xz_nonlin])
    end
    return nothing
end