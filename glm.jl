struct CS
	ID::Vector{Int64}
	C::Vector{Int64}
	T::Vector{Float64}
	n_subjects::Int64
	n_conditions::Int64
end

function add_normalised_trials!(df)
	df.t = vcat(map(ID -> df.trial[df.ID.==ID]./maximum(df.trial[df.ID.==ID]), unique(df.ID))...)
	return df
end

function map_condition(trial_type_v::Vector{String}, file)

	condition_v = zeros(Int64, length(trial_type_v))

	if occursin("02mA", file)

		condition_v[trial_type_v.=="FR"] .= 1
		condition_v[trial_type_v.=="FR+Tone"] .= 2
		return condition_v

	elseif occursin("03mA", file)

		condition_v[trial_type_v.=="FR"] .= 3
		condition_v[trial_type_v.=="FR+Tone"] .= 4
		return condition_v

	else
		println("Invalid file name : ", file)
		return -1
	end
end

function map_condition(N_trials::Int64, file)

	condition_d = Dict(
						"./CS/odor/food_restricted/02mA/baseline/" => 1, 
						"./CS/odor/food_restricted/02mA/odor/" => 2, 
						"./CS/odor/food_restricted/03mA/baseline/" => 1, 
						"./CS/odor/food_restricted/03mA/odor/" => 3,
						"./CS/odor/free_food/03mA/baseline/" => 4,
						"./CS/odor/free_food/03mA/odor/" => 5,
						"./CS/odor/free_food/02mA/baseline/" => 4,
						"./CS/odor/free_food/02mA/odor/" => 6
						)

	return fill(condition_d[file], N_trials)
end

#=
@model function CS_GLM(RT, data::CS, ::Type{T} = Float64) where {T}

	if RT === missing
		RT = Vector{T}(undef, length(data.ID))
	end

	μ_a ~ filldist(Normal(2.5, 0.5), data.n_conditions)
	σ_a ~ filldist(Exponential(0.5), data.n_conditions)

	ā ~ filldist(Normal(0, 1), data.n_conditions, data.n_subjects)
	a = @. μ_a + ā * σ_a

	c ~ Normal(0,1)

	σ ~ Exponential(0.5)

	μ = map((ID, C, t) -> a[C, ID] + c*t, data.ID, data.C, data.T)

	RT ~ MvLogNormal(μ, σ)

	return RT
end
=#

@model function CS_GLM(RT, data::CS, ::Type{T} = Float64) where {T}

	if RT === missing
		RT = Vector{T}(undef, length(data.ID))
	end

	μ_a ~ filldist(Normal(2.5, 0.5), data.n_conditions)
	σ_a ~ filldist(Exponential(0.5), data.n_conditions)

	ā ~ filldist(Normal(0, 1), data.n_conditions, data.n_subjects)
	a = @. μ_a + ā * σ_a

	σ ~ Exponential(0.5)

	μ = map((ID, C, t) -> a[C, ID], data.ID, data.C, data.T)

	RT ~ MvLogNormal(μ, σ)

	return RT
end

function run_odor_CS()

	pair_v = [
		"./CS/odor/food_restricted/02mA/baseline/" => 1, 
		"./CS/odor/food_restricted/02mA/odor/" => 2, 
		"./CS/odor/food_restricted/03mA/baseline/" => 1, 
		"./CS/odor/food_restricted/03mA/odor/" => 3,
		"./CS/odor/free_food/03mA/baseline/" => 4,
		"./CS/odor/free_food/03mA/odor/" => 5,
		"./CS/odor/free_food/02mA/baseline/" => 4,
		"./CS/odor/free_food/02mA/odor/" => 6
		]

	df = map(
			p -> read_CS(p[1]) |> 
			df -> insertcols!(df, :condition => fill(p[2], length(df.ID))) |>
			df -> add_normalised_trials!(df), 
			pair_v
			)

	df = vcat(df...)
	filter!(x -> x.outcome == "finished", df)

	data = CS(df.ID, df.condition, df.t, length(unique(df.ID)), length(unique(df.condition)))

	mdl = CS_GLM(df.RT, data)

	chain = sample(mdl, NUTS(), MCMCThreads(), 3000, 4)

	serialize("CS_odor.jls", chain)
end

function run_tone_CS()

	file_v = [
			"./CS/tone/02mA/",
			"./CS/tone/03mA/"
			]

	df = map(
			file -> read_CS(file) |> 
			df -> insertcols!(df, :condition => map_condition(df.trial_type, file)) |>
			df -> add_normalised_trials!(df), 
			file_v
			)

	df = vcat(df...)
	filter!(x -> x.outcome == "finished", df)

	data = CS(df.ID, df.condition, df.t, length(unique(df.ID)), length(unique(df.condition)))

	mdl = CS_GLM(df.RT, data)

	chain = sample(mdl, NUTS(), MCMCThreads(), 3000, 4)

	serialize("CS_tone.jls", chain)
end
