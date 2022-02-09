import Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

using Plots, TensorBoardLogger, ValueHistories
pgfplotsx()

function loaddir(dirname)
    
end

function loaddata(tbname)
    hist = MVHistory()
    path = "$(homedir())/servicemesh_results/$(tbname)"
    TensorBoardLogger.map_summaries(path) do tag, iter, val
        push!(hist, Symbol(tag), iter, val)
    end
    hist
end

function getvalues(data, name; smoothing_window=100, downsampling=1)
    values = data[name]
    smoothed = smooth(values.values, smoothing_window)
    return smoothed[1:downsampling:end]
end

function gettime(data)
    data["training/reward"].iterations / (24 * 3600)
end

function smooth(x, window)
    y = similar(x)
    total = 0
    for i in eachindex(x)
        total += x[i]
        if i > window
            total -= x[i-window]
            y[i] = total / window
        else
            y[i] = total / i
        end
    end
    y
end

data = Dict(
    :SAC => "ServiceMesh_simpleflipsplit2/SAC/220201_194358_ho_opt_default/tb_log",
    :K8s => "ServiceMesh_simpleflipsplit2/K8sAgent/220201_185408_ho_opt_default/tb_log",
    :Oracle => "ServiceMesh_simpleflipsplit2/OracleAgent/220201_192035_ho_opt_default/tb_log",
    :Reactive => "ServiceMesh_simpleflipsplit2/SimpleAgent/220201_183801_ho_opt_default/tb_log",
)

datas = [loaddata(data[k]) for k in keys(data)]
names = reshape(String.(keys(data)), (1, :))

downsampling = 500

t = gettime(datas[1])[1:downsampling:end]

mkpath("./fig")

default(size=(380, 270))

# Reward
reward_data = getvalues.(datas, "training/reward"; smoothing_window=500, downsampling)
reward_plot = plot(t, reward_data, title="Reward", xaxis="Time [Days]", ylim=[10, 30], label=names, legend=:bottomright)
savefig(reward_plot, "fig/reward.tex")

# Scale 1
scale1_data = getvalues.(datas, "MS1/scale"; smoothing_window=500, downsampling)
util1_data = getvalues.(datas, "MS1/utilization"; smoothing_window=500, downsampling)
load1_data = map(x -> x[1] .* x[2], zip(scale1_data, util1_data))
scale_plot = plot(title="MS1 scale", yaxis="Scale", xaxis="Time [Days]", label=names, legend=:bottomright, ylim=[2, 6])
for i in 1:4
    plot!(scale_plot, t, scale1_data[i], color=i, label=names[i])
    plot!(scale_plot, t, load1_data[i], color=i, linestyle=:dash, label="")
end
plot!(scale_plot, [1], [0], label="Scale", color="black")
plot!(scale_plot, [1], [0], linestyle=:dash, label="Load", color="black")
savefig(scale_plot, "fig/scale.tex")



