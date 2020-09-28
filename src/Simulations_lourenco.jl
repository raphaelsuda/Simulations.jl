mutable struct Lourenco
	f_tx
	f_tz
	f_mx
	f_mz
	f_α
	f_β
	f_γ
	
	function Lourenco(f_tx, f_tz, f_mx, f_mz, f_α, f_β, f_γ)
		return new(f_tx, f_tz, f_mx, f_mz, f_α, f_β, f_γ)
	end

	function Lourenco(data_path::String)
		data = readdlm(data_path)
		return new(data[1], data[2], data[3], data[4], data[5], data[6], data[7])
	end
end

# function for calculating the parameter α
function α_lourenco(l::Lourenco)
	f_tx = l.f_tx
	f_tz = l.f_tz
	f_α = l.f_α
	α = 1/9 * (1 + 4 * f_tx/f_α) * (1 + 4 * f_tz/f_α)
	return α
end

# function for calculating the parameter β
function β_lourenco(l::Lourenco)
	f_mx = l.f_mx
	f_mz = l.f_mz
	f_β = l.f_β
	β = (1/f_β^2 - 1/f_mx^2 - 1/f_mz^2) * f_mx * f_mz
	return β
end

# function for calculating the parameter γ
function γ_lourenco(l::Lourenco)
	f_mx = l.f_mx
	f_mz = l.f_mz
	f_γ = l.f_γ
	β = β_lourenco(l)
	γ = (16/f_γ^2 - 9 * (1/f_mx^2 + β/(f_mx * f_mz) + 1/f_mz^2)) * f_mx * f_mz
	return γ
end

function τ1_lourenco(σ_x::Number,σ_z::Number,l::Lourenco)
	f_tx = l.f_tx
	f_tz = l.f_tz
	α = α_lourenco(l)
	c1 = 1/α * (σ_x - f_tx) * (σ_z - f_tz)
	if c1 < 0
		τ1 = NaN
	else
		τ1 = sqrt(c1)
	end
	return τ1
end

function A_lourenco(l::Lourenco)
	f_mx = l.f_mx
	A = 1/f_mx^2
	return A
end

function B_lourenco(l::Lourenco)
	f_mx = l.f_mx
	f_mz = l.f_mz
	β = β_lourenco(l)
	B = β/(f_mx * f_mz)
	return B
end

function C_lourenco(l::Lourenco)
	f_mz = l.f_mz
	C = 1/f_mz^2
	return C
end

function D_lourenco(l::Lourenco)
	f_mx = l.f_mx
	f_mz = l.f_mz
	γ = γ_lourenco(l)
	D = γ/(f_mx * f_mz)
	return D
end

function τ2_lourenco(σ_x::Number, σ_z::Number, l::Lourenco)
	A = A_lourenco(l)
	B = B_lourenco(l)
	C = C_lourenco(l)
	D = D_lourenco(l)
	c1 = 1/D * (1 - A * σ_x^2 - B * σ_x * σ_z - C * σ_z^2)
	if c1 < 0
		τ2 = NaN
	else
		τ2 = sqrt(c1)
	end
	return τ2
end

function τ_lourenco(σ_x::Number, σ_z::Number, l::Lourenco)
	τ1 = τ1_lourenco(σ_x, σ_z, l)
	τ2 = τ2_lourenco(σ_x, σ_z, l)
	if isnan(τ2)
		τ = NaN
	else
		τ = minimum([τ1, τ2])
	end
	return τ
end

function τ_diff(σ_x::Number, σ_z::Number, τ::Number, l::Lourenco)
	τ_model = τ_lourenco(σ_x, σ_z, l)
	τ_model = map(τ_model) do t
		if isnan(t)
			return 0
		end
		return t
	end
	return τ - τ_model
end

function τ_sum(σ_x::Array{Float64}, σ_z::Array{Float64}, τ::Array{Float64}, l::Lourenco)
	n = length(σ_x)
	diff = zeros(n)
	for i in 1:n
		diff[i] = τ_diff(σ_x[i], σ_z[i], τ[i], l)
	end
	return sum(diff.^2)
end

function optimize_lourenco(samp::Sampling, optimizer::Optim.AbstractOptimizer; start_values=[0.0,0.0,0.0,0.0,0.0,0.0,0.0])
	df = CSV.read(joinpath(samp.path,"plot_failure_data.dat"))
	σ_x_models = collect(df[!,:sig_xx_nonlin])
	σ_z_models = collect(df[!,:sig_zz_nonlin])
	τ_models = collect(df[!,:sig_xz_nonlin])
	n_models = length(τ_models)
	f(x) = τ_sum(σ_x_models, σ_z_models, τ_models, Lourenco(x[1], x[2], x[3], x[4], x[5], x[6], x[7]))
	res = optimize(f, start_values, optimizer)
	results = Optim.minimizer(res)
	τ_mean = mean(τ_models)
	SS_tot = sum((τ_models[i] - τ_mean)^2 for i in 1:n_models)
	SS_res = Optim.minimum(res)
	CoD = 1 - SS_res/SS_tot
	f_tx, f_tz, f_mx, f_mz, f_α, f_β, f_γ = results[1], results[2], results[3], results[4], results[5], results[6], results[7]
	lourenco_parameters_optim = Dict("f_tx" => results[1],"f_tz" => results[2],"f_mx" => results[3],"f_mz" => results[4],"f_α" => results[5],"f_β" => results[6],"f_γ" => results[7])
	@info "Solution candidate:"
	println("   f_tx = $(round(f_tx,digits=3)) MPa")
	println("   f_tz = $(round(f_tz,digits=3)) MPa")
	println("   f_mx = $(round(f_mx,digits=3)) MPa")
	println("   f_mz = $(round(f_mz,digits=3)) MPa")
	println("    f_α = $(round(f_α,digits=3)) MPa")
	println("    f_β = $(round(f_β,digits=3)) MPa")
	println("    f_γ = $(round(f_γ,digits=3)) MPa")
	println("  ----------------------")
	println("    CoD = $(round(CoD,digits=3))")
	open(joinpath(samp.path, "model_data", "lourenco_parameters_optim.dat"),"w") do f
		JSON.print(f,lourenco_parameters_optim)
	end
	return nothing
end
