using PyPlot
using LaTeXStrings

function plot_RT_LR(df)

	figure()
	ax = gca()

	RT_L_v = filter(x -> x > 0.0, df[(df.trial_type .== "FR") .& (df.side .== "L"), :RT])

	RT_R_v = filter(x -> x > 0.0, df[(df.trial_type .== "FR") .& (df.side .== "R"), :RT])

	hist(RT_L_v, 50, alpha = 0.5, color = "b", label = "Left", density = true)
	hist(RT_R_v, 50, alpha = 0.5, color = "darkorange", label = "Right", density = true)

	axvline(median(RT_L_v), color = "b", linestyle = ":")
	axvline(median(RT_R_v), color = "darkorange", linestyle = ":")

	Mx = matplotlib.ticker.MultipleLocator(5)
	ax.xaxis.set_major_locator(Mx)

	ax.xaxis.set_tick_params(which="major", labelsize = 12)
	ax.yaxis.set_tick_params(which="major", labelsize = 12)

	xlabel("RT [sec]", fontsize = 18)
	legend(fontsize = 18, frameon = false)

	show()
end

function plot_RT_CS(df)

	figure()
	ax = gca()

	RT_FR_v = filter(x -> x > 0.0, 
					df[(df.trial_type .== "FR"), :RT])

	RT_FR_tone_v = filter(x -> x > 0.0, 
						df[((df.trial_type .== "FR+Tone") .| (df.trial_type .== "FR+Tone+Shock")), :RT])

	hist(RT_FR_v, 50, alpha = 0.5, color = "b", label = "FR", density = true)
	hist(RT_FR_tone_v, 50, alpha = 0.5, color = "darkorange", label = "FR+Tone", density = true)

	axvline(median(RT_FR_v), color = "b", linestyle = ":")
	axvline(median(RT_FR_tone_v), color = "darkorange", linestyle = ":")

	Mx = matplotlib.ticker.MultipleLocator(5)
	ax.xaxis.set_major_locator(Mx)

	ax.xaxis.set_tick_params(which="major", labelsize = 12)
	ax.yaxis.set_tick_params(which="major", labelsize = 12)

	xlabel("RT [sec]", fontsize = 18)
	legend(fontsize = 18, frameon = false)

	show()	
end

function plot_LP(df)

	cm = get_cmap(:tab20)

	n_sessions = maximum(df.session)
	ID_v = unique(df.ID)

	figure()
	ax = gca()

	for s = 1 : n_sessions
		for ID in ID_v

			LP_FR_v = filter(x -> x > 0.0, 
								df[(df.trial_type .== "FR") .& 
									(df.ID .== ID) .& 
									(df.session .== s), 
									:LP_CS])

			LP_FR_tone_v = filter(x -> x > 0.0, 
								df[((df.trial_type .== "FR+Tone") .| (df.trial_type .== "FR+Tone+Shock")) .& 
									(df.ID .== ID) .& 
									(df.session .== s), 
									:LP_CS])

			μ_diff_LP = mean(LP_FR_tone_v) - mean(LP_FR_v)
			σ_diff_LP = sqrt(var(LP_FR_tone_v)/length(LP_FR_tone_v) + var(LP_FR_v)/length(LP_FR_v))

			ID_idx = findlast(isequal('_'), ID)
			errorbar(s + parse(Int,ID[ID_idx + 1 : end])/length(ID_v) + (s-1), μ_diff_LP, yerr = σ_diff_LP, 
					color = cm(parse(Int,ID[ID_idx + 1 : end])/length(ID_v)), fmt = "o")
		end

		grp_LP_FR_v = filter(x -> x > 0.0, 
								df[(df.trial_type .== "FR") .& 
									(df.session .== s), 
									:LP_CS])

		grp_LP_FR_tone_v = filter(x -> x > 0.0, 
								df[((df.trial_type .== "FR+Tone") .| (df.trial_type .== "FR+Tone+Shock")) .& 
									(df.session .== s), 
									:LP_CS])

		errorbar(s - 0.2 + (s-1), mean(grp_LP_FR_tone_v) - mean(grp_LP_FR_v), 
				yerr = sqrt(var(grp_LP_FR_tone_v)/length(grp_LP_FR_tone_v) + var(grp_LP_FR_v)/length(grp_LP_FR_v)), 
				color = "k", fmt = "o")
	end

	axhline(0.0, color = "k", linestyle = "--")

	ax.set_xticks([s + (s-1) for s = 1:n_sessions])
	ax.xaxis.set_tick_params(which="major", labelsize = 12)
	ax.yaxis.set_tick_params(which="major", labelsize = 12)

	xlabel("session", fontsize = 18)
	ylabel(L"LP_{FR+Tone} - LP_{FR}", fontsize = 18)
	#legend(fontsize = 18, frameon = false, bbox_to_anchor = (1.01, 1), loc = "upper left")

	show()
end

function plot_miss(df)

	cm = get_cmap(:tab20)

	n_sessions = maximum(df.session)
	ID_v = unique(df.ID)

	figure()
	ax = gca()

	for s = 1 : n_sessions

		grp_miss_FR_v = Float64[]
		grp_miss_FR_tone_v = Float64[]

		for ID in ID_v

			miss_FR = count(x -> x == "started", 
							df[(df.trial_type .== "FR") .& 
								(df.ID .== ID) .& 
								(df.session .== s), 
								:outcome])

			miss_FR_tone = count(x -> x == "started", 
								df[((df.trial_type .== "FR+Tone") .| (df.trial_type .== "FR+Tone+Shock")) .& 
									(df.ID .== ID) .& 
									(df.session .== s), 
									:outcome])

			n_FR = length(df[(df.trial_type .== "FR") .& 
								(df.ID .== ID) .& 
								(df.session .== s), 
								:outcome])

			n_FR_tone = length(df[((df.trial_type .== "FR+Tone") .| (df.trial_type .== "FR+Tone+Shock")) .& 
									(df.ID .== ID) .& 
									(df.session .== s), 
									:outcome])

			diff_miss = 100.0*(miss_FR_tone/n_FR_tone - miss_FR / n_FR)

			ID_idx = findlast(isequal('_'), ID)
			errorbar(s + parse(Int,ID[ID_idx + 1 : end])/length(ID_v) + (s-1), diff_miss, 
					color = cm(parse(Int,ID[ID_idx + 1 : end])/length(ID_v)), fmt = "o")

			push!(grp_miss_FR_v, 100.0*miss_FR/n_FR)
			push!(grp_miss_FR_tone_v, 100.0*miss_FR_tone/n_FR_tone)
		end

		errorbar(s - 0.2 + (s-1), mean(grp_miss_FR_tone_v) - mean(grp_miss_FR_v), 
				yerr = sqrt(var(grp_miss_FR_tone_v)/length(grp_miss_FR_tone_v) + var(grp_miss_FR_v)/length(grp_miss_FR_v)), 
				color = "k", fmt = "o")
	end

	axhline(0.0, color = "k", linestyle = "--")

	ax.set_xticks([s + (s-1) for s = 1:n_sessions])
	ax.xaxis.set_tick_params(which="major", labelsize = 12)
	ax.yaxis.set_tick_params(which="major", labelsize = 12)

	xlabel("session", fontsize = 18)
	ylabel(L"O_{FR+Tone} - O_{FR} \ [\%]", fontsize = 18)

	show()
end

function plot_LP_group(df)

	cm = get_cmap(:tab20)

	n_sessions = maximum(df.session)
	ID_v = unique(df.ID)

	figure()
	ax = gca()

	for s = 1 : n_sessions

		grp_fh_LP_FR_v = Int64[]
		grp_sh_LP_FR_v = Int64[]

		grp_fh_LP_FR_tone_v = Int64[]
		grp_sh_LP_FR_tone_v = Int64[]

		for ID in ID_v

			n_trials = maximum(df.trial[(df.ID .== ID) .& (df.session .== s)])

			fh_LP_FR_v = filter(x -> x > 0.0, 
								df[(df.trial_type .== "FR") .& 
									(df.ID .== ID) .& 
									(df.session .== s) .&
									(1 .<= df.trial .<= Int(floor(n_trials/2))), 
									:LP_CS])

			fh_LP_FR_tone_v = filter(x -> x > 0.0, 
								df[((df.trial_type .== "FR+Tone") .| (df.trial_type .== "FR+Tone+Shock")) .& 
									(df.ID .== ID) .& 
									(df.session .== s) .&
									(1 .<= df.trial .<= Int(floor(n_trials/2))), 
									:LP_CS])

			append!(grp_fh_LP_FR_v, fh_LP_FR_v)
			append!(grp_fh_LP_FR_tone_v, fh_LP_FR_tone_v)

			sh_LP_FR_v = filter(x -> x > 0.0, 
								df[(df.trial_type .== "FR") .& 
									(df.ID .== ID) .& 
									(df.session .== s) .&
									(Int(floor(n_trials/2)) .< df.trial .<= n_trials), 
									:LP_CS])

			sh_LP_FR_tone_v = filter(x -> x > 0.0, 
								df[((df.trial_type .== "FR+Tone") .| (df.trial_type .== "FR+Tone+Shock")) .& 
									(df.ID .== ID) .& 
									(df.session .== s) .&
									(Int(floor(n_trials/2)) .< df.trial .<= n_trials), 
									:LP_CS])

			append!(grp_sh_LP_FR_v, sh_LP_FR_v)
			append!(grp_sh_LP_FR_tone_v, sh_LP_FR_tone_v)
		end

		errorbar(s + (s-1), mean(grp_fh_LP_FR_tone_v) - mean(grp_fh_LP_FR_v), 
				yerr = sqrt(var(grp_fh_LP_FR_tone_v)/length(grp_fh_LP_FR_tone_v) + var(grp_fh_LP_FR_v)/length(grp_fh_LP_FR_v)), 
				color = "k", fmt = "o")

		errorbar(s + (s-1) + 0.2, mean(grp_sh_LP_FR_tone_v) - mean(grp_sh_LP_FR_v), 
				yerr = sqrt(var(grp_sh_LP_FR_tone_v)/length(grp_sh_LP_FR_tone_v) + var(grp_sh_LP_FR_v)/length(grp_sh_LP_FR_v)), 
				color = "k", fmt = "o")
	end
	axhline(0.0, color = "k", linestyle = "--")

	ax.set_xticks([s + (s-1) for s = 1:n_sessions])
	ax.xaxis.set_tick_params(which="major", labelsize = 12)
	ax.yaxis.set_tick_params(which="major", labelsize = 12)

	ylabel(L"LP_{FR+Tone} - LP_{FR}", fontsize = 18)

	show()
end

function plot_miss_group(df)

	cm = get_cmap(:tab20)

	n_sessions = maximum(df.session)
	ID_v = unique(df.ID)

	figure()
	ax = gca()

	for s = 1 : n_sessions

		grp_miss_FR_v = Matrix{Float64}(undef, length(ID_v), 2)
		grp_miss_FR_tone_v = Matrix{Float64}(undef, length(ID_v), 2)

		c = 1
		for ID in ID_v

			n_trials = maximum(df.trial[(df.ID .== ID) .& (df.session .== s)])

			miss_FR = [count(x -> x == "started", 
							df[(df.trial_type .== "FR") .& 
								(df.ID .== ID) .& 
								(df.session .== s) .&
								(1 .<= df.trial .<= Int(floor(n_trials/2))), 
								:outcome]),
						count(x -> x == "started", 
							df[(df.trial_type .== "FR") .& 
								(df.ID .== ID) .& 
								(df.session .== s) .&
								(Int(floor(n_trials/2)) .< df.trial .<= n_trials), 
								:outcome])]

			miss_FR_tone = [count(x -> x == "started", 
								df[((df.trial_type .== "FR+Tone") .| (df.trial_type .== "FR+Tone+Shock")) .& 
									(df.ID .== ID) .& 
									(df.session .== s) .&
									(1 .<= df.trial .<= Int(floor(n_trials/2))), 
									:outcome]),
							count(x -> x == "started", 
								df[((df.trial_type .== "FR+Tone") .| (df.trial_type .== "FR+Tone+Shock")) .& 
									(df.ID .== ID) .& 
									(df.session .== s) .&
									(Int(floor(n_trials/2)) .< df.trial .<= n_trials), 
									:outcome])]

			n_FR = [length(df[(df.trial_type .== "FR") .& 
								(df.ID .== ID) .& 
								(df.session .== s) .&
								(1 .<= df.trial .<= Int(floor(n_trials/2))), 
								:outcome]),
					length(df[(df.trial_type .== "FR") .& 
								(df.ID .== ID) .& 
								(df.session .== s) .&
								(Int(floor(n_trials/2)) .< df.trial .<= n_trials), 
								:outcome])]

			n_FR_tone = [length(df[((df.trial_type .== "FR+Tone") .| (df.trial_type .== "FR+Tone+Shock")) .& 
									(df.ID .== ID) .& 
									(df.session .== s) .&
									(1 .<= df.trial .<= Int(floor(n_trials/2))), 
									:outcome]),
						length(df[((df.trial_type .== "FR+Tone") .| (df.trial_type .== "FR+Tone+Shock")) .& 
									(df.ID .== ID) .& 
									(df.session .== s) .&
									(Int(floor(n_trials/2)) .< df.trial .<= n_trials), 
									:outcome])]

			grp_miss_FR_v[c, 1] = 100.0 * miss_FR[1] / n_FR[1]
			grp_miss_FR_v[c, 2] = 100.0 * miss_FR[2] / n_FR[2]
			grp_miss_FR_tone_v[c, 1] = 100.0 * miss_FR_tone[1] / n_FR_tone[1]
			grp_miss_FR_tone_v[c, 2] = 100.0 * miss_FR_tone[2] / n_FR_tone[2]

			c += 1
		end

		errorbar(s + (s-1), mean(grp_miss_FR_tone_v[:,1]) - mean(grp_miss_FR_v[:,1]), 
				yerr = sqrt(var(grp_miss_FR_tone_v[:,1])/length(grp_miss_FR_tone_v[:,1]) + var(grp_miss_FR_v[:,1])/length(grp_miss_FR_v[:,1])), 
				color = "k", fmt = "o")

		errorbar(s + (s-1) + 0.2, mean(grp_miss_FR_tone_v[:,2]) - mean(grp_miss_FR_v[:,2]), 
				yerr = sqrt(var(grp_miss_FR_tone_v[:,2])/length(grp_miss_FR_tone_v[:,2]) + var(grp_miss_FR_v[:,2])/length(grp_miss_FR_v[:,2])), 
				color = "k", fmt = "o")
	end
	axhline(0.0, color = "k", linestyle = "--")

	ax.set_xticks([s + (s-1) for s = 1:n_sessions])
	ax.xaxis.set_tick_params(which="major", labelsize = 12)
	ax.yaxis.set_tick_params(which="major", labelsize = 12)

	ylabel(L"O_{FR+Tone} - O_{FR} \ [\%]", fontsize = 18)
	show()
end