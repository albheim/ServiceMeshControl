using DistributedEnvironments
using Plots, Dates
gr()

nodes = readlines("/var/local/hosts")
@initcluster nodes sync=true worker_procs=:auto 

@everywhere using ServiceMeshLearning, Hyperopt, Flux

@everywhere function runexp(; tag="test", seed_iterations=1, seed=37, relative=:none, env=:simpleflip, alg=:SAC, logging=false, kwargs...)
    println("starting - tag=$(tag)")
    t = time()
    microservices = 3
    value = sum(seed_offset -> run_experiment(; 
        kwargs...,

        alg = alg, 
        env = env,
        microservices,

        seed = seed + seed_offset,
        tag = tag,
        verbose = false,
        logging = logging,
        log_every = 600,
    ) for seed_offset in 1:seed_iterations)

    if relative != :none
        value /= sum(seed_offset -> run_experiment(; 
            kwargs...,

            alg = relative, 
            env = env,
            microservices,

            seed = seed + seed_offset,
            tag = tag,
            verbose = false,
            logging = false,
            log_every = 600,
        ) for seed_offset in 1:seed_iterations)
    end

    println("finished - value=$value - tag=$(tag) - time=$(time()-t)")

    value
end

@everywhere params = Dict((;
    relative = :SimpleAgent,
    env = :simpleflipsplit4,
    logging = true,
    timesteps = 5_000_000,
    #seed_iterations = 1,
    seed = 37,
    basepath = joinpath(homedir(), "servicemesh_results"),
))
@everywhere params[:tag] = joinpath("$(params[:env])", "HO_$(Dates.format(now(), "yymmdd_HHMMSS"))", "ho_search")

ho = @phyperopt for i = 100, 
        lr_alpha = [1f-5, 5f-5, 1f-4],
        target_entropy = [2f0, 4f0, 7f0, 10f0],
        frames = 2:3,
        #state_smoothing = 0.1:0.2:1.0,
        γ = [0.9f0, 0.99f0, 0.999f0],
        τ = [0.002f0, 0.005f0, 0.01f0],
        start_steps = [1000, 10_000, 50_000],
        update_after = [100, 1000, 10_000],
        #seed = 4:7,
        replay_size = [100_000, 500_000, 1_000_000],
        hidden_units_policy = [20, 50, 100, 150],
        hidden_units_value = [50, 100, 150],
        hidden_layers_policy = 1:3,
        hidden_layers_value = 2:4,
        #action_interval = 1,#1:5,
        #action_smoothing = 0f0,#[0.0f0, 0.2f0, 0.5f0, 0.7f0, 0.9f0],
        batch_size = [100, 150, 200],
        update_freq = [8, 16, 24],
        actfun = [sigmoid, elu, relu],
        reward_scaling = [0.1, 0.5, 1.0],
        closing_cost = [0.0, 0.1, 0.5, 1.0]

    # The running reward returned here is on the base reward without added stuff from reward wrappers
    # It is also relative to the SimpleAgent reward
    runexp(;
        # Default values
        params...,
        tag = joinpath("$(params[:tag])", "$(i)"),

        # HO values
        lr_alpha, target_entropy, 
        frames, 
        #state_smoothing,
        γ, τ,
        start_steps, update_after,
        replay_size, 
        hidden_layers_policy, hidden_units_policy, 
        hidden_layers_value, hidden_units_value, 
        #action_interval, action_smoothing, 
        batch_size, 
        update_freq, actfun,
        reward_scaling,
        closing_cost,
    )
end 

# printmax(ho)
# plot(ho, size=(1200, 900))

BSON.@save joinpath("$(params[:basepath])", "$(params[:tag])") ho=ho
