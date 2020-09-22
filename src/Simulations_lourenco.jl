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