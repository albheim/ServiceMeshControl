## Local imports 
using Plots, Dates
gr()

## Environment setup
using DistributedEnvironments

nodes = readlines("/var/local/hosts")[1:16]
@initcluster nodes sync=true workers_per_machine=1

@everywhere using ServiceMeshLearning, Hyperopt, Flux

## Experiment setup
@everywhere function runexp(; tag="test", seed_iterations=1, seed=37, relative=:none, env=:simpleflip, alg=:SAC, logging=false, kwargs...)
    println("starting - tag=$(tag)")
    t = time()
    value = 0
    for seed_offset in 1:seed_iterations
        value += run_experiment(; 
            kwargs...,

            alg = alg, 
            env = env,

            seed = seed + seed_offset,
            tag = tag,
            verbose = false,
            logging = logging,
            log_every = 600,
        )
    end

    if relative != :none
        relative_value = 0
        for seed_offset in 1:seed_iterations
            relative_value += run_experiment(; 
                kwargs...,

                alg = relative, 
                env = env,

                seed = seed + seed_offset,
                tag = tag,
                verbose = false,
                logging = false,
                log_every = 600,
            )
        end
        value /= relative_value
    end

    println("finished - value=$value - tag=$(tag) - time=$(time()-t)")

    value
end

tag = joinpath("HO_$(Dates.format(now(), "yymmdd_HHMMSS"))_seedsearch", "ho_search")

@everywhere ho_params = Dict(pairs((;
    relative = :SimpleAgent,
    env = :complex,
    logging = true,
    timesteps = 5_000_000,
    #seed_iterations = 1,
    seed = 37,
    basepath = joinpath(homedir(), "servicemesh_results"),
    tag = $tag,
)))

## Run experiment
ho = @phyperopt for i = 20, 
        lr_alpha = [1f-5, 5f-5, 1f-4],
        target_entropy = [7f0, 10f0],
        # frames = 2:3,
        # state_smoothing = 0.1:0.2:1.0,
        γ = [0.9f0, 0.99f0, 0.999f0],
        τ = [0.002f0, 0.005f0, 0.01f0],
        # start_steps = [1000, 10_000, 50_000],
        # update_after = [100, 1000, 10_000],
        # seed = 4:7,
        # replay_size = [100_000, 500_000, 1_000_000],
        # hidden_units_policy = [20, 50, 100, 150],
        # hidden_units_value = [50, 100, 150],
        # hidden_layers_policy = 1:3,
        # hidden_layers_value = 2:4,
        # action_interval = 1,#1:5,
        # action_smoothing = 0f0,#[0.0f0, 0.2f0, 0.5f0, 0.7f0, 0.9f0],
        batch_size = [100, 150, 200],
        # update_freq = [8, 16, 24],
        # actfun = [sigmoid, elu, relu],
        # start_policy = [:RandomAgent, :SimpleAgent],
        reward_scaling = [0.1, 0.5, 1.0]

    # The running reward returned here is on the base reward without added stuff from reward wrappers
    # It is also relative to the SimpleAgent reward
    runexp(;
        # Default values
        ho_params...,
        tag = joinpath("$(ho_params[:tag])", "$(i)"),

        # Set values
        seed_iterations = 5,
        actfun = elu,
        update_freq = 10,
        frames = 2,
        hidden_layers_policy = 2, 
        hidden_units_policy = 50, 
        hidden_layers_value = 4, 
        hidden_units_value = 50, 
        start_steps = 50_000, 
        update_after = 1000,
        replay_size = 500_000, 

        # HO values
        lr_alpha, target_entropy, 
        #state_smoothing,
        γ, τ,
        #action_interval, action_smoothing, 
        batch_size, 
        reward_scaling,
        #start_policy,
    )
end 

## Visualize and save experiment
plot(ho, size=(1200, 900))

fpath = joinpath("$(ho_params[:basepath])", "$(ho_params[:env])", "$(ho_params[:tag])")
mkpath(fpath)
open(joinpath(fpath, "HO_maximizer.txt"), "w") do io
    println(io, "# Set params")
    for (k, v) in ho_params
        println(io, "$k = $v,")
    end
    println(io, "\n# Optimized params")
    for (k, v) in zip(ho.params, ho.maximizer)
        println(io, "$k = $v,")
    end
    # printmax(io, ho)
end

using BSON
BSON.@save joinpath("$(ho_params[:basepath])", "$(ho_params[:env])", "$(ho_params[:tag])", "HO_maximizer.bson") ho=ho
