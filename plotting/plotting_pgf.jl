## Setup
import Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

using Measures, LaTeXStrings

using Plots
pgfplotsx()
default(size=(380, 270))

include(joinpath(@__DIR__, "readdata.jl"))

cd(joinpath(homedir(), "git", "servicemesh_overleaf_paper"))
mkpath("./fig")

## Load 2v2 data
exp_path = joinpath(homedir(), "servicemesh_results", "simpleflipsplit2v2", "HO_220201_194358_new_rand_alg")

data_paths = read_all(exp_path)

datas = [loaddata(data_paths[k]) for k in keys(data_paths)]
data_names = ["K8s Scaler" "Oracle" "SAC" "Reactive"]

downsampling = 5000
smoothing_window = 1000

t = gettime(datas[1])[1:downsampling:end]


## Reward plot
reward_data = getvalues.(datas, "training/reward"; smoothing_window, downsampling)
reward_plot = plot(t, reward_data, title="Reward", xaxis="Time [Days]", ylim=[10, 30], label=data_names, legend=:bottomright)
savefig(reward_plot, "fig/2v2_reward.tex")

## Combined fig for 4 scale
scale_plot = let p = plot(layout=(1, 4), link=:y, yrange=(1.0, 6.0), show=true, margin=-8mm, size=(700, 200))

    data = getvalues.(datas, "MS1/scale"; smoothing_window, downsampling)
    plot!(p[1], t, data, xaxis="Time [days]", yaxis="Scale", label="", title=L"M_1")

    data = getvalues.(datas, "MS2/scale"; smoothing_window, downsampling)
    plot!(p[2], t, data, yformatter=_->"", label="", title=L"M_2")

    data = getvalues.(datas, "MS3/scale"; smoothing_window, downsampling)
    plot!(p[3], t, data, yformatter=_->"", label="", title=L"M_3")

    data = getvalues.(datas, "MS4/scale"; smoothing_window, downsampling)
    plot!(p[4], t, data, legend=:outerbottomleft, label=data_names, legend_column=length(data_names), yformatter=_->"", title=L"M_4")
end

savefig(scale_plot, "fig/2v2_scale.tex")

## Combined fig for 4 util
util_plot = let p = plot(layout=(1, 4), link=:y, yrange=(0.4, 1.0), show=true, margin=-7mm, size=(700, 200))

    data = getvalues.(datas, "MS1/utilization"; smoothing_window, downsampling)
    plot!(p[1], t, data, xaxis="Time [days]", yaxis="Utilization", label="", title=L"M_1")

    data = getvalues.(datas, "MS2/utilization"; smoothing_window, downsampling)
    plot!(p[2], t, data, yformatter=_->"", label="", title=L"M_2")

    data = getvalues.(datas, "MS3/utilization"; smoothing_window, downsampling)
    plot!(p[3], t, data, yformatter=_->"", label="", title=L"M_3")

    data = getvalues.(datas, "MS4/utilization"; smoothing_window, downsampling)
    plot!(p[4], t, data, legend=:outerbottomleft, label=data_names, legend_column=length(data_names), yformatter=_->"", title=L"M_4")
end

savefig(util_plot, "fig/2v2_util.tex")

















## Load simple data 2
exp_path = joinpath(homedir(), "servicemesh_results", "simpleflip", "HO_220224_154551", "2longsimpleflip")

data_paths = read_all(exp_path)

datas = [loaddata(data_paths[k]) for k in keys(data_paths)]

t = gettime(datas[1])[1:downsampling:end]

## Reward plot
reward_data = getvalues.(datas, "training/reward"; smoothing_window, downsampling)
reward_plot = plot(t, reward_data, title="Reward", xaxis="Time [Days]", ylim=[7, 13], label=data_names, legend=:topleft, legend_column=2)
savefig(reward_plot, "fig/simple2_reward.tex")

## Combined fig for 2 scale
scale_util_plot = let p = plot(layout=(2, 2), show=true, size=(350, 400), leftmargin=-8mm, rightmargin=-8mm)

    data = getvalues.(datas, "MS1/scale"; smoothing_window, downsampling)
    plot!(p[1], t, data, yrange=(0.0, 5.0), yaxis="Scale", label="", title=L"M_1", linestyle=[:solid :dash :dot :dashdot])

    data = getvalues.(datas, "MS2/scale"; smoothing_window, downsampling)
    plot!(p[2], t, data, yformatter=_->"", yrange=(0.0, 4.0), label="", title=L"M_2", linestyle=[:solid :dash :dot :dashdot])

    data = getvalues.(datas, "MS1/utilization"; smoothing_window, downsampling)
    plot!(p[3], t, data, xaxis="Time [days]", yaxis="Utilization", yrange=(0.4, 1.2), label="", linestyle=[:solid :dash :dot :dashdot])

    data = getvalues.(datas, "MS2/utilization"; smoothing_window, downsampling)
    plot!(p[4], t, data, yformatter=_->"", yrange=(0.4, 1.2), legend=:outertop, label=data_names, legend_column=length(data_names), linestyle=[:solid :dash :dot :dashdot])
end

savefig(scale_util_plot, "fig/simple2_scale_util.tex")

## Combined fig for 2 util
util_plot = let p = plot(layout=(1, 3), link=:y, yrange=(0.4, 1.0), show=true, margin=-7mm, size=(700, 200))

    data = getvalues.(datas, "MS1/utilization"; smoothing_window, downsampling)
    plot!(p[1], t, data, xaxis="Time [days]", yaxis="Utilization", label="", title=L"M_1")

    data = getvalues.(datas, "MS2/utilization"; smoothing_window, downsampling)
    plot!(p[2], t, data, yformatter=_->"", label="", title=L"M_2")

    data = getvalues.(datas, "MS3/utilization"; smoothing_window, downsampling)
    plot!(p[3], t, data, legend=:outerbottomleft, label=data_names, legend_column=length(data_names), yformatter=_->"", title=L"M_3")
end

savefig(util_plot, "fig/simple_util.tex")












## Load simple data 3
exp_path = joinpath(homedir(), "servicemesh_results", "simpleflipL3", "HO_220224_154551", "len3")

data_paths = read_all(exp_path)

datas = [loaddata(data_paths[k]) for k in keys(data_paths)]

t = gettime(datas[1])[1:downsampling:end]

## Reward plot
reward_data = getvalues.(datas, "training/reward"; smoothing_window, downsampling)
reward_plot = plot(t, reward_data, title="Reward", xaxis="Time [Days]", ylim=[10, 30], label=data_names, legend=:bottomright)
savefig(reward_plot, "fig/simple_reward.tex")

## Combined fig for scale
scale_plot = let p = plot(layout=(1, 3), link=:y, yrange=(1.0, 6.0), show=true, margin=-8mm, size=(700, 200))

    data = getvalues.(datas, "MS1/scale"; smoothing_window, downsampling)
    plot!(p[1], t, data, xaxis="Time [days]", yaxis="Scale", label="", title=L"M_1")

    data = getvalues.(datas, "MS2/scale"; smoothing_window, downsampling)
    plot!(p[2], t, data, yformatter=_->"", label="", title=L"M_2")

    data = getvalues.(datas, "MS3/scale"; smoothing_window, downsampling)
    plot!(p[3], t, data, legend=:outerbottomleft, label=data_names, legend_column=length(data_names), yformatter=_->"", title=L"M_3")
end

savefig(scale_plot, "fig/simple_scale.tex")

## Combined fig for util
util_plot = let p = plot(layout=(1, 3), link=:y, yrange=(0.4, 1.0), show=true, margin=-7mm, size=(700, 200))

    data = getvalues.(datas, "MS1/utilization"; smoothing_window, downsampling)
    plot!(p[1], t, data, xaxis="Time [days]", yaxis="Utilization", label="", title=L"M_1")

    data = getvalues.(datas, "MS2/utilization"; smoothing_window, downsampling)
    plot!(p[2], t, data, yformatter=_->"", label="", title=L"M_2")

    data = getvalues.(datas, "MS3/utilization"; smoothing_window, downsampling)
    plot!(p[3], t, data, legend=:outerbottomleft, label=data_names, legend_column=length(data_names), yformatter=_->"", title=L"M_3")
end

savefig(util_plot, "fig/simple_util.tex")












## Read ho data
data, labels = load_ho_values(joinpath(homedir(), "servicemesh_results", "simpleflipL3", "HO_220309_105934_len3", "ho_search", "ho_data.csv"))
idxs = [3, 5]
ho_plot = scatter(data[:, idxs], data[:, end], xlabel=reshape(labels[idxs], 1, :), layout=(1, 2), size=(320, 200), label="", alpha=0.2, show=true, margin=-5mm)
plot!(ho_plot[1], ylabel="Relative reward", title="Hyperparameter tuning")
savefig(ho_plot, "fig/ho.tex")



nothing