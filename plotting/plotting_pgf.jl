## Setup
import Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

using Measures, LaTeXStrings

using Plots
pgfplotsx()
default(size=(350, 240))

cd(@__DIR__)
include("readdata.jl")
mkpath("./fig")

## Load 2v2 data
#exp_path = joinpath(homedir(), "servicemesh_results", "simpleflipsplit2v2", "HO_220201_194358_new_rand_alg")
exp_path = joinpath(homedir(), "servicemesh_results", "simpleflipsplit2v2uneven", "custom", "2v2uneven_min1scale")
microservices = 4

data_paths = read_all(exp_path)

datas = [loaddata(data_paths[k]) for k in keys(data_paths)]
data_names = ["Kubernetes" "Mesh aware" "RL agent" "Reactive"]

smoothing_window = 1000
downsampling = 1000
days = 100
final_sample = days * 24 * 60 # We sample every minute
sample_range = 1:downsampling:final_sample


t = gettime(datas[1])[sample_range]


## Reward plot
reward_data = getvalues.(datas, "training/reward"; smoothing_window, sample_range)
reward_plot = plot(t, reward_data, title="Reward", xaxis="Time [Days]", ylim=[20, 40], label=data_names, legend=:bottomright, legend_column=2)
savefig(reward_plot, "fig/double_reward.tex")

## Missed jobs
missed_data = getvalues.(datas, "Job1/missed"; smoothing_window, sample_range)
missed_data .+= getvalues.(datas, "Job2/missed"; smoothing_window, sample_range)
missed_plot = plot(t, missed_data, title="Missed deadlines", yaxis="Missed [jobs/s]", xaxis="Time [Days]", ylim=[0, 0.2], label=data_names, legend=:topright)
savefig(missed_plot, "fig/double_missed.tex")

## Arrivals
arrivals_data = [getvalues(datas[1], "Job$i/arrivals"; smoothing_window, sample_range) for i in 1:2]
arrivals_data_full = [getvalues(datas[1], "Job$i/arrivals"; smoothing_window=1, sample_range) for i in 1:2]
arrivals_plot = plot(t, arrivals_data, color=[:black :purple], linestyle=[:solid :dash], title="Job arrivals", yaxis="[jobs/s]", xaxis="Time [Days]", ylim=[0, 4], label=[L"W_1" L"W_2"], legend=:topright, size=(230,170))
plot!(arrivals_plot, t, arrivals_data_full, color=[:black :purple], linestyle=[:solid :dash], alpha=0.3, label="")
savefig(arrivals_plot, "fig/double_arrivals.tex")

## Combined scale and util but separate ms 4
begin
    ## M1
    p = plot(layout=(2, 1), show=true, size=(250, 200), link=:x, bottommargin=-7mm, topmargin=-7mm)

    data = getvalues.(datas, "MS1/scale"; smoothing_window, sample_range)
    plot!(p[1], t, data, yaxis="Scale", label="", xformatter=_->"", title=L"M_1", yrange=(0.5, 7.0))

    data = getvalues.(datas, "MS1/utilization"; smoothing_window, sample_range)
    plot!(p[2], t, [min.(1, d) for d in data], xformatter=_->"", label="", yaxis="Utilization", yrange=(0.3, 1.0))

    savefig(p, "fig/double_scale_util_1.tex")
    display(p)

    ## M2
    p = plot(layout=(2, 1), show=true, size=(250, 200), link=:x, bottommargin=-7mm, topmargin=-7mm)

    data = getvalues.(datas, "MS2/scale"; smoothing_window, sample_range)
    plot!(p[1], t, data, label="", xformatter=_->"", yformatter=_->"", title=L"M_2", yrange=(0.5, 7.0))

    data = getvalues.(datas, "MS2/utilization"; smoothing_window, sample_range)
    plot!(p[2], t, [min.(1, d) for d in data], xformatter=_->"", yformatter=_->"", label="", yrange=(0.3, 1.0))

    savefig(p, "fig/double_scale_util_2.tex")
    display(p)

    ## M3
    p = plot(layout=(2, 1), show=true, size=(250, 200), link=:x, bottommargin=-7mm, topmargin=-7mm)

    data = getvalues.(datas, "MS3/scale"; smoothing_window, sample_range)
    plot!(p[1], t, data, label=data_names, xformatter=_->"", yaxis="Scale", title=L"M_3", yrange=(0.5, 7.0), legend=:outerleft, legend_column=1)

    data = getvalues.(datas, "MS3/utilization"; smoothing_window, sample_range)
    plot!(p[2], t, [min.(1, d) for d in data], xaxis="Time [days]", label="", yaxis="Utilization", yrange=(0.3, 1.0))

    savefig(p, "fig/double_scale_util_3.tex")
    display(p)

    ## M4
    p = plot(layout=(2, 1), show=true, size=(250, 200), link=:x, bottommargin=-7mm, topmargin=-7mm)

    data = getvalues.(datas, "MS4/scale"; smoothing_window, sample_range)
    plot!(p[1], t, data, label="", xformatter=_->"", yformatter=_->"", title=L"M_4", yrange=(0.5, 7.0))

    data = getvalues.(datas, "MS4/utilization"; smoothing_window, sample_range)
    plot!(p[2], t, [min.(1, d) for d in data], yformatter=_->"", xaxis="Time [days]", label="", yrange=(0.3, 1.0))

    savefig(p, "fig/double_scale_util_4.tex")
    display(p)
end


















## Load simple data 2
exp_path = joinpath(homedir(), "servicemesh_results", "simpleflip", "HO_220224_154551", "2longsimpleflip")
microservices = 2

data_paths = read_all(exp_path)

datas = [loaddata(data_paths[k]) for k in keys(data_paths)]

## Reward plot
reward_data = getvalues.(datas, "training/reward"; smoothing_window, sample_range)
reward_plot = plot(t, reward_data, title="Reward", xaxis="Time [Days]", ylim=[7, 13], label=data_names, legend=:topleft, legend_column=2)
savefig(reward_plot, "fig/simple2_reward.tex")

## Arrival jobs
arrival_data = getvalues(datas[1], "Job1/arrivals"; smoothing_window, sample_range)
arrival_full_data = getvalues(datas[1], "Job1/arrivals"; smoothing_window=1, sample_range)
arrival_plot = plot(t, arrival_full_data, title="Job arrivals", yaxis="[jobs/s]", xaxis="Time [Days]", linecolor=:black, alpha=0.1, ylim=[0, 4], label="Sampled data", size=(250, 200), legend=:outertop)
plot!(arrival_plot, t, arrival_data, label="Smoothed data", linecolor=:black)
savefig(arrival_plot, "fig/simple2_arrivals.tex")

## Lost jobs
missed_data = getvalues.(datas, "Job1/missed"; smoothing_window, sample_range)
missed_plot = plot(t, missed_data, title="Missed deadlines", yaxis="[jobs/s]", xaxis="Time [Days]", ylim=[0, 0.1], label=data_names, legend=:topright)
savefig(missed_plot, "fig/simple2_missed.tex")
dropped_data = getvalues.(datas, "Job1/dropped"; smoothing_window, sample_range)
lost_plot = plot(t, missed_data .+ dropped_data, title="Lost jobs", yaxis="[jobs/s]", xaxis="Time [Days]", ylim=[0, 0.1], label=data_names, legend=:topright)
savefig(lost_plot, "fig/simple2_lost.tex")

## Lost/arrival jobs
lost_arrival_data = [100 .* lost_data[i] ./ (arrival_data[i] .+ 0.0001) for i in 1:4]
lost_arrival_plot = plot(t, lost_arrival_data, title="Percentage of lost jobs", yaxis="[%]", xaxis="Time [Days]", ylim=[0, 5], label=data_names, legend=:topright)
savefig(lost_arrival_plot, "fig/simple2_lost_arrival.tex")

## Combined scale and util but separate ms 2
begin
    p = plot(layout=(2, 1), yrange=(1.0, 6.0), show=true, size=(250, 200), link=:x, bottommargin=-5mm, topmargin=-5mm)

    data = getvalues.(datas, "MS1/scale"; smoothing_window, sample_range)
    plot!(p[1], t, data, yaxis="Scale", label=data_names, xformatter=_->"", legend=:outertop, title=L"M_1", yrange=(1.0, 6.0), legend_column=1)

    # util
    data = getvalues.(datas, "MS1/utilization"; smoothing_window, sample_range)
    plot!(p[2], t, [min.(1, d) for d in data], xaxis="Time [days]", label="", yaxis="Utilization", yrange=(0.4, 1.0))

    savefig(p, "fig/simple2_scale_util_1.tex")
    display(p)

    p = plot(layout=(2, 1), yrange=(1.0, 6.0), show=true, size=(250, 200), link=:x, bottommargin=-5mm, topmargin=-5mm)

    data = getvalues.(datas, "MS2/scale"; smoothing_window, sample_range)
    plot!(p[1], t, data, label="", xformatter=_->"", yformatter=_->"", legend=:outertop, title=L"M_2", yrange=(1.0, 6.0), legend_column=1)

    # util
    data = getvalues.(datas, "MS2/utilization"; smoothing_window, sample_range)
    plot!(p[2], t, [min.(1, d) for d in data], yformatter=_->"", xaxis="Time [days]", label="", yrange=(0.4, 1.0))

    savefig(p, "fig/simple2_scale_util_2.tex")
    display(p)
end













## Load simple data 3
exp_path = joinpath(homedir(), "servicemesh_results", "simpleflipL3min1", "custom", "len3min1nofracval")
microservices = 3

data_paths = read_all(exp_path)

datas = [loaddata(data_paths[k]) for k in keys(data_paths)]

## Reward plot
reward_data = getvalues.(datas, "training/reward"; smoothing_window, sample_range)
reward_plot = plot(t, reward_data, title="Reward", xaxis="Time [Days]", ylim=[8, 19], label=data_names, legend=:bottomright, legend_column=2)
savefig(reward_plot, "fig/simple_reward.tex")

## Arrival jobs
arrival_data = getvalues(datas[1], "Job1/arrivals"; smoothing_window, sample_range)
arrival_full_data = getvalues(datas[1], "Job1/arrivals"; smoothing_window=1, sample_range)
arrival_plot = plot(t, arrival_full_data, title="Job arrivals", yaxis="[jobs/s]", xaxis="Time [Days]", linecolor=:black, alpha=0.1, ylim=[0, 4], label="Sampled data", size=(250, 200), legend=:top)
plot!(arrival_plot, t, arrival_data, label="Smoothed data", linecolor=:black)
savefig(arrival_plot, "fig/simple_arrivals.tex")

## Missed jobs
missed_data = getvalues.(datas, "Job1/missed"; smoothing_window, sample_range)
missed_plot = plot(t, missed_data, title="Missed deadlines", yaxis="Missed [jobs/s]", xaxis="Time [Days]", ylim=[0, 0.1], label=data_names, legend=:topright)
savefig(missed_plot, "fig/simple_missed.tex")

## Combined scale and util but separate ms 2
begin
    ## M1
    p = plot(layout=(2, 1), yrange=(1.0, 6.0), show=true, size=(250, 200), link=:x, bottommargin=-5mm, topmargin=-5mm)

    data = getvalues.(datas, "MS1/scale"; smoothing_window, sample_range)
    plot!(p[1], t, data, yaxis="Scale", label="", xformatter=_->"", title=L"M_1", yrange=(1.0, 5.0))

    data = getvalues.(datas, "MS1/utilization"; smoothing_window, sample_range)
    plot!(p[2], t, [min.(1, d) for d in data], xaxis="Time [days]", label="", yaxis="Utilization", yrange=(0.3, 0.9))

    savefig(p, "fig/simple_scale_util_1.tex")
    display(p)

    ## M2
    p = plot(layout=(2, 1), yrange=(1.0, 6.0), show=true, size=(250, 200), link=:x, bottommargin=-5mm, topmargin=-5mm)

    data = getvalues.(datas, "MS2/scale"; smoothing_window, sample_range)
    plot!(p[1], t, data, label="", xformatter=_->"", yformatter=_->"", title=L"M_2", yrange=(1.0, 5.0))

    data = getvalues.(datas, "MS2/utilization"; smoothing_window, sample_range)
    plot!(p[2], t, [min.(1, d) for d in data], yformatter=_->"", xaxis="Time [days]", label="", yrange=(0.3, 0.9))

    savefig(p, "fig/simple_scale_util_2.tex")
    display(p)

    ## M3
    p = plot(layout=(2, 1), yrange=(1.0, 6.0), show=true, size=(250, 200), link=:x, bottommargin=-5mm, topmargin=-5mm)

    data = getvalues.(datas, "MS3/scale"; smoothing_window, sample_range)
    plot!(p[1], t, data, label=data_names, xformatter=_->"", yformatter=_->"", title=L"M_3", yrange=(1.0, 5.0), legend=:right, legend_column=1)

    data = getvalues.(datas, "MS3/utilization"; smoothing_window, sample_range)
    plot!(p[2], t, [min.(1, d) for d in data], yformatter=_->"", xaxis="Time [days]", label="", yrange=(0.3, 0.9))

    savefig(p, "fig/simple_scale_util_3.tex")
    display(p)
end












## Read ho data
data, labels = load_ho_values(joinpath(homedir(), "servicemesh_results", "simpleflipL3", "HO_220309_105934_len3", "ho_search", "ho_data.csv"))
idxs = [3, 5]
ho_plot = scatter(data[:, idxs], data[:, end], xlabel=reshape(labels[idxs], 1, :), layout=(1, 2), size=(320, 200), label="", alpha=0.2, show=true, margin=-5mm)
plot!(ho_plot[1], ylabel="Relative reward", title="Hyperparameter tuning")
savefig(ho_plot, "fig/ho.tex")



nothing