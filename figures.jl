using CairoMakie
using ColorSchemes
using LaTeXStrings
using Unicode
using CSV
using DataFrames
using Statistics
using Turing
using Serialization
using StatsBase: ecdf

include("read.jl")
include("glm.jl")

function RT_FR_training()

	fig_sz_inch = (6.4, 4.8)
	font_sz = 12

	df = read_FR("./FR_last/")

	RT = df[df.outcome, :RT]

	f = Figure(resolution = 72 .* fig_sz_inch, fontsize=font_sz)

	ax = Axis(f[1,1], 
			xticks=[0,5,8,10,15,20,25,30],
			xlabel="Response Time [sec]",
			yticks=([0, ecdf(RT)(8), 0.5, 1], ["0.0","0.156","0.5","1.0"]),
			ylabel="ECDF")

	ecdfplot!(ax, RT, colormap=:seaborn_colorblind6)

	vlines!(ax, 8; ymax=ecdf(RT)(8), color=:black, linestyle=:dash)
	hlines!(ax, ecdf(RT)(8); xmax=8/30, color=:black, linestyle=:dash)

	ylims!(ax, 0, 1)
	xlims!(ax, 0, 30)

	save("./figures/RT_FR_training.eps",f, pt_per_unit = 1)
end

function group_posterior_tone(model, chain)

	fig_sz_inch = (6.4,4)
	font_sz = 12

	colormap = ColorSchemes.seaborn_colorblind6.colors

	n_conditions = 4

	chain_prior = sample(model, Prior(), 1200)
	df_prior = DataFrame(chain_prior)
	df = DataFrame(chain)

	f = Figure(resolution = 72 .* fig_sz_inch, fontsize=font_sz)

	ga = f[1, 1] = GridLayout()
	gb = f[1, 2] = GridLayout()

	ax = [
		Axis(ga[1,1],
			xlabel="Condition",
			xticks=(0:4, ["Prior", "B,\n0.2", "0.2", "B,\n0.3", "0.3"]),
			ylabel="Cohort-level RT [sec]"),
		Axis(gb[1,1],
			xlabel="Condition",
			xticks=(1:2, ["0.2", "0.3"]),
			ylabel="Difference in cohort-level RT [sec]")
		]

	for i = 1:n_conditions

		var_name = "μ_a[$i]"
		violin!(ax[1], fill(i, length(df[!, var_name])), exp.(df[!, var_name]);
				color=colormap[i], side=:right)
	end

	violin!(ax[1], fill(0, length(df_prior[!, "μ_a[1]"])), exp.(df_prior[!, "μ_a[1]"]);
			side=:right, color=(:slategray, 0.4))

	ylims!(ax[1], 0.0, 40.0)

	violin!(ax[2], fill(1, length(df[!, "μ_a[1]"])), exp.(df[!, "μ_a[2]"])-exp.(df[!, "μ_a[1]"]);
			 color=colormap[2], side=:right)

	violin!(ax[2], fill(2, length(df[!, "μ_a[3]"])), exp.(df[!, "μ_a[4]"])-exp.(df[!, "μ_a[3]"]);
			 color=colormap[4], side=:right)

	hlines!(ax[2], 0.0; color=:black, linestyle=:dash)

	for (label, layout) in zip(["A", "B"], [ga, gb])
	    Label(layout[1, 1, TopLeft()], label,
	        textsize = 18,
	        halign = :right)
	end

	colgap!(f.layout, Relative(0.02))

	save("./figures/group_post_tone.eps", f, pt_per_unit = 1)
end

function subject_posterior_tone(model, chain)

	fig_sz_inch = (6.4,4)
	font_sz = 12

	colormap = ColorSchemes.seaborn_colorblind6.colors

	df = DataFrame(chain)

	f = Figure(resolution = 72 .* fig_sz_inch, fontsize=font_sz)

	ga = f[1, 1] = GridLayout()
	gb = f[1, 2] = GridLayout()

	ax = [
		Axis(ga[1,1],
			xlabel="Subject",
			ylabel="Difference in subject-level RT [sec]",
			title="0.2"),
		Axis(gb[1,1],
			xlabel="Subject",
			ylabel="Difference in subject-level RT [sec]",
			title="0.3")
		]

	for (c, ax_id) in zip([2,4], ax)

		RT = map(1:16) do ID 
				exp.(df[!,Unicode.normalize("μ_a[$c]")] .+
					df[!,Unicode.normalize("ā[$c,$ID]")] .*
					df[!,Unicode.normalize("σ_a[$c]")]) -
				exp.(df[!,Unicode.normalize("μ_a[$(c-1)]")] .+
					df[!,Unicode.normalize("ā[$(c-1),$ID]")] .*
					df[!,Unicode.normalize("σ_a[$(c-1)]")])
			end	

		for i = 1:16
			violin!(ax_id, fill(i, length(RT[i])), RT[i]; 
					color=colormap[c], side=:right)
		end
		
		hlines!(ax_id, 0.0; color=:black, linestyle=:dash)
		ylims!(ax_id, -7.0, 7.0)
	end

	for (label, layout) in zip(["A", "B"], [ga, gb])
	    Label(layout[1, 1, TopLeft()], label,
	        textsize = 18,
	        halign = :right)
	end

	hideydecorations!(ax[2], grid=false)

	colgap!(f.layout, Relative(0.02))

	save("./figures/subj_post_tone.eps", f, pt_per_unit = 1)
end

function group_posterior_odor(model, chain)

	fig_sz_inch = (6.4,4)
	font_sz = 12

	colormap = ColorSchemes.seaborn_colorblind6.colors

	n_conditions = 6
	
	chain_prior = sample(model, Prior(), 1200)
	df_prior = DataFrame(chain_prior)
	df = DataFrame(chain)

	f = Figure(resolution = 72 .* fig_sz_inch, fontsize=font_sz)

	ga = f[1, 1] = GridLayout()
	gb = f[1, 2] = GridLayout()

	ax = [
		Axis(ga[1,1],
			xlabel="Condition",
			xticks=(0:6, ["Prior", 
						"B", 
						"0.2", 
						"0.3", 
						"B,\nFF", 
						"0.3,\nFF", 
						"0.2,\nFF"]),
			ylabel="Cohort-level RT [sec]"),
		Axis(gb[1,1],
			xlabel="Condition",
			xticks=(1:4, ["0.2", "0.3", "0.3, FF", "0.2, FF"]),
			ylabel="Difference in cohort-level RT [sec]")
		]

	for i = 1:n_conditions

		var_name = "μ_a[$i]"
		violin!(ax[1], fill(i, length(df[!, var_name])), exp.(df[!, var_name]);
				color=colormap[i], side=:right)
	end

	violin!(ax[1], fill(0, length(df_prior[!, "μ_a[1]"])), exp.(df_prior[!, "μ_a[1]"]);
			side=:right, color=(:slategray, 0.4))

	ylims!(ax[1], 0.0, 40.0)

	violin!(ax[2], fill(1, length(df[!, "μ_a[1]"])), exp.(df[!, "μ_a[2]"])-exp.(df[!, "μ_a[1]"]);
			 color=colormap[2], side=:right)

	violin!(ax[2], fill(2, length(df[!, "μ_a[1]"])), exp.(df[!, "μ_a[3]"])-exp.(df[!, "μ_a[1]"]);
			 color=colormap[3], side=:right)

	violin!(ax[2], fill(3, length(df[!, "μ_a[4]"])), exp.(df[!, "μ_a[5]"])-exp.(df[!, "μ_a[3]"]);
			 color=colormap[5], side=:right)

	violin!(ax[2], fill(4, length(df[!, "μ_a[4]"])), exp.(df[!, "μ_a[6]"])-exp.(df[!, "μ_a[3]"]);
			 color=colormap[6], side=:right)


	hlines!(ax[2], 0.0; color=:black, linestyle=:dash)

	for (label, layout) in zip(["A", "B"], [ga, gb])
	    Label(layout[1, 1, TopLeft()], label,
	        textsize = 18,
	        halign = :right)
	end

	colgap!(f.layout, Relative(0.02))

	save("./figures/group_post_odor.eps", f, pt_per_unit = 1)
end

function subject_posterior_odor(model, chain)

	fig_sz_inch = (6.4,8)
	font_sz = 12

	colormap = ColorSchemes.seaborn_colorblind6.colors

	df = DataFrame(chain)

	f = Figure(resolution = 72 .* fig_sz_inch, fontsize=font_sz)

	ga = f[1, 1] = GridLayout()
	gb = f[1, 2] = GridLayout()
	gc = f[2, 1] = GridLayout()
	gd = f[2, 2] = GridLayout()

	ax = [
		Axis(ga[1,1],
			xlabel="Subject",
			ylabel="Difference in subject-level RT [sec]",
			title="0.3"),
		Axis(gb[1,1],
			xlabel="Subject",
			ylabel="Difference in subject-level RT [sec]",
			title="0.2"),
		Axis(gc[1,1],
			xlabel="Subject",
			ylabel="Difference in subject-level RT [sec]",
			title="0.3, FF"),
		Axis(gd[1,1],
			xlabel="Subject",
			ylabel="Difference in subject-level RT [sec]",
			title="0.2, FF")
		]

	for (c, c_base, ax_id) in zip([2,3,5,6], [1,1,4,4], ax)

		RT = map(1:16) do ID 
				exp.(df[!,Unicode.normalize("μ_a[$c]")] .+
					df[!,Unicode.normalize("ā[$c,$ID]")] .*
					df[!,Unicode.normalize("σ_a[$c]")]) -
				exp.(df[!,Unicode.normalize("μ_a[$(c-1)]")] .+
					df[!,Unicode.normalize("ā[$(c-1),$ID]")] .*
					df[!,Unicode.normalize("σ_a[$(c-1)]")])
			end	

		for i = 1:16
			violin!(ax_id, fill(i, length(RT[i])), RT[i]; 
					color=colormap[c], side=:right)
		end
		
		hlines!(ax_id, 0.0; color=:black, linestyle=:dash)
		ylims!(ax_id, -7.0, 7.0)
	end

	ylims!(ax[1], -7.0, 7.0)
	ylims!(ax[2], -7.0, 7.0)
	ylims!(ax[3], -15.0, 15.0)
	ylims!(ax[4], -15.0, 15.0)
	

	hidexdecorations!(ax[1], grid=false)
	hidexdecorations!(ax[2], grid=false)	
	hideydecorations!(ax[2], grid=false)
	hideydecorations!(ax[4], grid=false)

	for (label, layout) in zip(["A", "B", "C", "D"], [ga, gb, gc, gd])
	    Label(layout[1, 1, TopLeft()], label,
	        textsize = 18,
	        halign = :right)
	end

	colgap!(f.layout, Relative(0.02))
	rowgap!(f.layout, Relative(0.01))

	save("./figures/subj_post_odor.eps", f, pt_per_unit = 1)
end

function posterior_intercept(model, chain, task)

	fig_sz_inch = (6.4, 4.8)
	font_sz = 12

	chain_prior = sample(model, Prior(), 1200)
	df_prior = DataFrame(chain_prior)
	df = DataFrame(chain)

	f = Figure(resolution = 72 .* fig_sz_inch, fontsize=font_sz)

	ax = Axis(f[1,1],
				xticks=(0:1, ["Prior", "Posterior"]),
				ylabel="Time intercept γ")

	violin!(ax, fill(1, length(df[!, "c"])), df[!, "c"];
			colormap=:seaborn_colorblind, side=:right)

	violin!(ax, fill(0, length(df_prior[!, "c"])), df_prior[!, "c"];
			colormap=:seaborn_colorblind, side=:right)

	save(string("./figures/posterior_intercept_", task, ".eps"), f, pt_per_unit = 1)
end

function prior_predictive(model)

	fig_sz_inch = (6.4,4)
	font_sz = 12

	p = reduce(vcat, [model() for _=1:1500])

	f = Figure(resolution = 72 .* fig_sz_inch, fontsize=font_sz)

	ga = f[1, 1] = GridLayout()
	gb = f[1, 2] = GridLayout()

	ax = [
			Axis(ga[1,1],
				xticks=0:20:100,
				xlabel="Response time [sec]",
				ylabel="Probability"),
			Axis(gb[1,1],
				xticks=0:20:100,
				xlabel="Response time [sec]",
				ylabel="ECDF")
		]
	density!(ax[1], p[p.<100], colormap=:seaborn_colorblind6)
	ecdfplot!(ax[2], p[p.<100], colormap=:seaborn_colorblind6)

	for (label, layout) in zip(["A", "B"], [ga, gb])
	    Label(layout[1, 1, TopLeft()], label,
	        textsize = 18,
	        halign = :right)
	end

	colgap!(f.layout, Relative(0.02))

	save("./figures/prior_predict.eps", f, pt_per_unit = 1)
end


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

model = CS_GLM(df.RT, data)
chain = deserialize("CS_tone.jls")

group_posterior_tone(model, chain)
subject_posterior_tone(model, chain)

file_v = [
		"./CS/odor/food_restricted/02mA/baseline/", 
		"./CS/odor/food_restricted/02mA/odor/", 
		"./CS/odor/food_restricted/03mA/baseline/", 
		"./CS/odor/food_restricted/03mA/odor/",
		"./CS/odor/free_food/03mA/baseline/",
		"./CS/odor/free_food/03mA/odor/",
		"./CS/odor/free_food/02mA/baseline/",
		"./CS/odor/free_food/02mA/odor/"
		]

df = map(
		file -> read_CS(file) |> 
		df -> insertcols!(df, :condition => map_condition(length(df.ID), file)) |>
		df -> add_normalised_trials!(df), 
		file_v
		)

df = vcat(df...)
filter!(x -> x.outcome == "finished", df)

data = CS(df.ID, df.condition, df.t, length(unique(df.ID)), length(unique(df.condition)))

model = CS_GLM(df.RT, data)
chain = deserialize("CS_odor.jls")

group_posterior_odor(model, chain)
subject_posterior_odor(model, chain)

model_prior = CS_GLM(missing, data)
prior_predictive(model_prior)

