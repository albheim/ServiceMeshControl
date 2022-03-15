using TensorBoardLogger, ValueHistories, DelimitedFiles

function load_ho_values(path)
    (data, header) = readdlm(path, ','; header=true)
end

function loaddata(path)
    hist = MVHistory()
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

function read_all(exp_path)
    dict = Dict{String,String}()
    for (root, dirs, files) in walkdir(exp_path)
        for d in dirs
            if d == "tb_log"
                dict[splitpath(root)[end-1]] = joinpath(root, d)
            end
        end
    end
    dict
end