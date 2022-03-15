using ArviZ
using PyPlot
using Turing
using LaTeXStrings
using Serialization

function CS_tone_diagnostics()

	title_sz = 11
	label_sz = 11
	fig_sz_inch = (6.4,6)
	DPI = 600

	label_v = [
				"Baseline (0.2)", 
				"0.2", 
				"Baseline (0.3)",
				"0.3"
				]

	chain = deserialize("CS_tone.jls")

	ArviZ.use_style("seaborn-colorblind")

	idt = from_mcmcchains(chain; 
       					coords=Dict(
       								"condition"=>label_v, 
       								"subject"=>collect(1:16)
       								),
       					dims=Dict(
       							"μ_a"=>["condition"], 
       							"σ_a"=>["condition"], 
       							"ā"=>["condition","subject"]
       							),
       					library="Turing")

	fig, ax = PyPlot.subplots(2,2, figsize=fig_sz_inch)
	
	for i = 1:length(label_v)
		plot_rank(idt; 
			var_names=["μ_a"], 
			coords=Dict("condition"=>label_v[i]), 
			ax=ax[i])

		ax[i].set_title(label_v[i], fontsize=title_sz)
	end

	ax[1].set_xlabel("")
	ax[1].set_ylabel("Chain", fontsize=label_sz)
	ax[1].tick_params(axis="x", labelbottom=false)
	ax[1].tick_params(axis="y", labelsize=label_sz)

	ax[2].set_xlabel("Rank (all chains)", fontsize=label_sz)
	ax[2].set_ylabel("Chain", fontsize=label_sz)
	ax[2].tick_params(axis="both", labelsize=label_sz)

	ax[3].set_xlabel("")
	ax[3].set_ylabel("")
	ax[3].tick_params(axis="both", labelbottom=false, labelleft=false)

	ax[4].set_xlabel("Rank (all chains)", fontsize=label_sz)
	ax[4].set_ylabel("")
	ax[4].tick_params(axis="y", labelleft=false)
	ax[4].tick_params(axis="x", labelsize=label_sz)

	fig.suptitle(latexstring("\$\\mu_c\$ : Cohort mean effect of condition"), fontsize=title_sz+2)
	savefig("./figures/rank_tone.pdf"; dpi=DPI)

	fig, ax = PyPlot.subplots(2,2, figsize=fig_sz_inch)
	
	for i = 1:length(label_v)
		plot_ess(idt; 
			var_names=["μ_a"], 
			coords=Dict("condition"=>label_v[i]), 
			ax=ax[i])

		ax[i].set_title(label_v[i], fontsize=title_sz)
	end

	ax[1].set_xlabel("")
	ax[1].set_ylabel("ESS for small intervals", fontsize=label_sz)
	ax[1].tick_params(axis="x", labelbottom=false)
	ax[1].tick_params(axis="y", labelsize=label_sz)

	ax[2].set_xlabel("Quantile", fontsize=label_sz)
	ax[2].set_ylabel("ESS for small intervals", fontsize=label_sz)
	ax[2].tick_params(axis="both", labelsize=label_sz)

	ax[3].set_xlabel("")
	ax[3].set_ylabel("")
	ax[3].tick_params(axis="both", labelbottom=false, labelleft=false)

	ax[4].set_xlabel("Quantile", fontsize=label_sz)
	ax[4].set_ylabel("")
	ax[4].tick_params(axis="y", labelleft=false)
	ax[4].tick_params(axis="x", labelsize=label_sz)

	fig.suptitle(latexstring("\$\\mu_c\$ : Cohort mean effect of condition"), fontsize=title_sz)
	savefig("./figures/ess_tone.pdf"; dpi=DPI)
end

function CS_odor_diagnostics()

	title_sz = 11
	label_sz = 11
	fig_sz_inch = (6.4,7)
	DPI = 600

	label_v = [
				"Baseline", 
				"0.2",
				"0.3",
				"Baseline, FF", 
				"0.2, FF",
				"0.3, FF"
				]

	chain = deserialize("CS_odor.jls")

	ArviZ.use_style("seaborn-colorblind")

	idt = from_mcmcchains(chain; 
       					coords=Dict(
       								"condition"=>label_v, 
       								"subject"=>collect(1:16)
       								),
       					dims=Dict(
       							"μ_a"=>["condition"], 
       							"σ_a"=>["condition"], 
       							"ā"=>["condition","subject"]
       							),
       					library="Turing")

	fig, ax = PyPlot.subplots(3,2, figsize=fig_sz_inch)
	
	for i = 1:length(label_v)
		plot_rank(idt; 
			var_names=["μ_a"], 
			coords=Dict("condition"=>label_v[i]), 
			ax=ax[i])

		ax[i].set_title(label_v[i], fontsize=title_sz)
	end

	ax[1].set_xlabel("")
	ax[1].set_ylabel("Chain", fontsize=label_sz)
	ax[1].tick_params(axis="x", labelbottom=false)
	ax[1].tick_params(axis="y", labelsize=label_sz)

	ax[2].set_xlabel("")
	ax[2].set_ylabel("Chain", fontsize=label_sz)
	ax[2].tick_params(axis="x", labelbottom=false)
	ax[2].tick_params(axis="y", labelsize=label_sz)

	ax[3].set_xlabel("Rank (all chains)", fontsize=label_sz)
	ax[3].set_ylabel("Chain", fontsize=label_sz)
	ax[3].tick_params(axis="both", labelsize=label_sz)

	ax[4].set_xlabel("")
	ax[4].set_ylabel("")
	ax[4].tick_params(axis="both", labelbottom=false, labelleft=false)

	ax[5].set_xlabel("")
	ax[5].set_ylabel("")
	ax[5].tick_params(axis="both", labelbottom=false, labelleft=false)

	ax[6].set_xlabel("Rank (all chains)", fontsize=label_sz)
	ax[6].set_ylabel("")
	ax[6].tick_params(axis="x", labelbottom=label_sz)
	ax[6].tick_params(axis="y", labelsize=false)

	subplots_adjust(wspace=0.2, 
                    hspace=0.2)

	fig.suptitle(latexstring("\$\\mu_c\$ : Cohort mean effect of condition"), fontsize=title_sz+2)
	savefig("./figures/rank_odor.pdf"; dpi=DPI)

	fig, ax = PyPlot.subplots(3,2, figsize=fig_sz_inch)
	
	for i = 1:length(label_v)
		plot_ess(idt; 
			var_names=["μ_a"], 
			coords=Dict("condition"=>label_v[i]), 
			ax=ax[i])

		ax[i].set_title(label_v[i], fontsize=title_sz)
	end

	ax[1].set_xlabel("")
	ax[1].set_ylabel("ESS for small intervals", fontsize=label_sz)
	ax[1].tick_params(axis="x", labelbottom=false)
	ax[1].tick_params(axis="y", labelsize=label_sz)

	ax[2].set_xlabel("")
	ax[2].set_ylabel("ESS for small intervals", fontsize=label_sz)
	ax[2].tick_params(axis="x", labelbottom=false)
	ax[2].tick_params(axis="y", labelsize=label_sz)

	ax[3].set_xlabel("Quantile", fontsize=label_sz)
	ax[3].set_ylabel("ESS for small intervals", fontsize=label_sz)
	ax[3].tick_params(axis="both", labelsize=label_sz)

	ax[4].set_xlabel("")
	ax[4].set_ylabel("")
	ax[4].tick_params(axis="both", labelbottom=false, labelleft=false)

	ax[5].set_xlabel("")
	ax[5].set_ylabel("")
	ax[5].tick_params(axis="both", labelbottom=false, labelleft=false)

	ax[6].set_xlabel("Quantile", fontsize=label_sz)
	ax[6].set_ylabel("")
	ax[6].tick_params(axis="x", labelsize=label_sz)
	ax[6].tick_params(axis="y", labelleft=false)

	subplots_adjust(wspace=0.2, 
                    hspace=0.2)

	fig.suptitle(latexstring("\$\\mu_c\$ : Cohort mean effect of condition"), fontsize=title_sz+2)
	savefig("./figures/ess_odor.pdf"; dpi=DPI)
end

function CS_energy_plot()

	title_sz = 11
	label_sz = 11
	fig_sz_inch = (6.4, 3)
	DPI = 600

	ArviZ.use_style("seaborn-colorblind")

	label_tone_v = [
					"Baseline (0.2)", 
					"0.2", 
					"Baseline (0.3)",
					"0.3"
					]

	chain_tone = deserialize("CS_tone.jls")
	idt_tone = from_mcmcchains(chain_tone; 
	       					coords=Dict(
	       								"condition"=>label_tone_v, 
	       								"subject"=>collect(1:16)
	       								),
	       					dims=Dict(
	       							"μ_a"=>["condition"], 
	       							"σ_a"=>["condition"], 
	       							"ā"=>["condition","subject"]
	       							),
	       					library="Turing")

	label_odor_v = [
					"Baseline", 
					"0.2",
					"0.3",
					"Baseline, FF", 
					"0.2, FF",
					"0.3, FF"
					]

	chain_odor = deserialize("CS_odor.jls")
	idt_odor = from_mcmcchains(chain_odor; 
	       					coords=Dict(
	       								"condition"=>label_odor_v, 
	       								"subject"=>collect(1:16)
	       								),
	       					dims=Dict(
	       							"μ_a"=>["condition"], 
	       							"σ_a"=>["condition"], 
	       							"ā"=>["condition","subject"]
	       							),
	       					library="Turing")

	fig, ax = PyPlot.subplots(1,2, figsize=fig_sz_inch)

	plot_energy(idt_tone; ax=ax[1])
	plot_energy(idt_tone; ax=ax[2])

	ax[1].set_title("Experiment 1", fontsize=title_sz)
	ax[2].set_title("Experiment 2", fontsize=title_sz)

	ax[1].legend(frameon=false, fontsize=7)
	ax[2].legend(frameon=false, fontsize=7)

	subplots_adjust(wspace=0.05, left=0.05, right=0.95)
	savefig("./figures/energy.pdf"; dpi=DPI)
end

CS_tone_diagnostics()
CS_odor_diagnostics()
CS_energy_plot()