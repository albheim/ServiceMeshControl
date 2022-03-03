## Setup
import Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

using Plots
pgfplotsx()
default(size=(380, 270))

include(joinpath(@__DIR__, "readdata.jl"))

## Load data

# exp_path = joinpath(homedir(), "servicemesh_results", "simpleflipsplit2v2", "HO_220201_194358_new_rand_alg")
# runtag = "flipsplit2v2"
# microservices = 4

exp_path = joinpath(homedir(), "servicemesh_results", "simpleflip", "HO_220224_154551", "2longsimpleflip")
runtag = "simple"
microservices = 2

data_paths = read_all(exp_path)

datas = [loaddata(data_paths[k]) for k in keys(data_paths)]
data_names = reshape(String.(keys(data_paths)), (1, :))

## Plotting
downsampling = 500

t = gettime(datas[1])[1:downsampling:end]

# CLEANUP
cd(joinpath(homedir(), "git", "servicemesh_overleaf_paper"))

mkpath("./fig")

# Reward
reward_data = getvalues.(datas, "training/reward"; smoothing_window=500, downsampling)
reward_plot = plot(t, reward_data, title="Reward", xaxis="Time [Days]", ylim=[10, 30], label=data_names, legend=:bottomright)
savefig(reward_plot, "fig/$(runtag)_reward.tex")

# For each MS 
for i in 1:microservices
    # Scale
    scale_data = getvalues.(datas, "MS$i/scale"; smoothing_window=500, downsampling)
    scale_plot = plot(title="MS$i", yaxis="Scale", xaxis="Time [Days]", label=data_names, ylim=[1, 5])
    for j in 1:4
        plot!(scale_plot, t, scale_data[j], color=j, label=data_names[j])
    end
    savefig(scale_plot, "fig/$(runtag)_scale_$i.tex")
    display(scale_plot)

    # Util
    util_data = getvalues.(datas, "MS$i/utilization"; smoothing_window=500, downsampling)
    util_plot = plot(title="MS$i", yaxis="Utilization", xaxis="Time [Days]", label=data_names, ylim=[0, 1])
    for j in 1:4
        plot!(util_plot, t, util_data[j], color=j, label=data_names[j])
    end
    savefig(util_plot, "fig/$(runtag)_util_$i.tex")
    display(util_plot)

    # Load/Scale
    f(a, b) = a .* b
    load_data = f.(scale_data, util_data)
    load_plot = plot(title="MS$i", yaxis="Load", xaxis="Time [Days]", label=data_names)
    for j in 1:4
        plot!(load_plot, t, scale_data[j], color=j, label=data_names[j])
        plot!(load_plot, t, load_data[j], color=j, linestyle=:dash, label="")
    end
    plot!(load_plot, [1], [0], label="Scale", color="black")
    plot!(load_plot, [1], [0], linestyle=:dash, label="Load", color="black")
    savefig(load_plot, "fig/$(runtag)_load_$i.tex")
    display(load_plot)
end



nothing