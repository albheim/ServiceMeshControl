import Pkg
Pkg.activate(@__DIR__)

include(joinpath(@__DIR__, "readdata.jl"))

# Changing experiment
env_name = "double_new"
n_ms = 4
n_workloads = 3

tag = "50days"

exp_path = joinpath(homedir(), "servicemesh_results", env_name, tag)

data_paths = read_all(exp_path)

datas = [loaddata(data_paths[k]) for k in keys(data_paths)]
data_names = ["k8s" "oracle" "rl" "simple"]

ts = gettime(datas[1])

smoothing_window = 1000
downsampling = 1000
days = 50
final_sample = days * 24 * 60 # We sample every minute
sample_range = 1:downsampling:final_sample
#sample_range = 1:downsampling:length(ts)

t = ts[sample_range]

reward_data = getvalues.(datas, "training/reward"; smoothing_window, sample_range)
missed_data = sum(i -> getvalues.(datas, "Job$i/missed"; smoothing_window, sample_range), 1:n_workloads)
arrivals_data = [getvalues(datas[1], "Job$i/arrivals"; smoothing_window, sample_range) for i in 1:n_workloads]
arrivals_data_full = [getvalues(datas[1], "Job$i/arrivals"; smoothing_window=1, sample_range) for i in 1:n_workloads]
scale = [getvalues.(datas, "MS$(i)/scale"; smoothing_window, sample_range) for i in 1:n_ms]
util = [getvalues.(datas, "MS$(i)/utilization"; smoothing_window, sample_range) for i in 1:n_ms]

data = [["time"; t];;]
for i in eachindex(data_names)
    name = data_names[i]
    data = hcat(data, ["$(name)_reward"; reward_data[i]])
    data = hcat(data, ["$(name)_missed"; missed_data[i]])
    for j in 1:n_ms
        data = hcat(data, ["$(name)_scale$j"; scale[j][i]])
        data = hcat(data, ["$(name)_util$j"; util[j][i]])
    end
end
for i in 1:n_workloads
    data = hcat(data, ["arrivals$(i)_mean"; arrivals_data[i]])
    data = hcat(data, ["arrivals$(i)"; arrivals_data_full[i]])
end


writedlm(joinpath(exp_path, "plot_data.csv"), data, ',')



# Testing
using Plots
plot(t, reward_data, label=data_names)
plot(t, arrivals_data)
plot(t, missed_data, label=data_names, ylim=[0, 0.1])

p1 = plot(t, scale[1], label=data_names)
p2 = plot(t, scale[2], label=data_names)
p3 = plot(t, scale[3], label=data_names)
p4 = plot(t, scale[4], label=data_names)
plot(p1, p2, p3, p4, layout=4)

# expected colnames
# time,k8s_scale1,oracle_scale1,rl_scale1,simple_scale1,k8s_util1,oracle_util1,rl_util1,simple_util1,k8s_scale2,oracle_scale2,rl_scale2,simple_scale2,k8s_util2,oracle_util2,rl_util2,simple_util2,k8s_scale3,oracle_scale3,rl_scale3,simple_scale3,k8s_util3,oracle_util3,rl_util3,simple_util3,k8s_scale4,oracle_scale4,rl_scale4,simple_scale4,k8s_util4,oracle_util4,rl_util4,simple_util4,arrivals1_mean,arrivals2_mean,arrivals1,arrivals2,k8s_missed,oracle_missed,rl_missed,simple_missed,k8s_reward,oracle_reward,rl_reward,simple_reward
