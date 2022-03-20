using ServiceMeshLearning, Flux

## Len 3
# hyperparams = Dict(pairs((;
#     # Set params
#     tag = joinpath("HO_220313_183523_len3", "len3"),
#     env = :simpleflipL3,
# 
#     # Optimized params
#     lr_alpha = 5.0e-5,
#     target_entropy = 7.0,
#     γ = 0.9,
#     τ = 0.005,
#     hidden_units_policy = 50,
#     hidden_units_value = 150,
#     hidden_layers_policy = 2,
#     hidden_layers_value = 3,
#     batch_size = 250,
#     actfun = σ,
#     reward_scaling = 1.0,
#     update_after = 1000,
#     update_freq = 10,
#     frames = 2,
#     replay_size = 500000,
#     start_steps = 50000,
# 
#     # Always
#     logging = true,
#     verbose = true,
#     seed = 123,
#     timesteps = 20_000_000,
#     start_policy = :RandomAgent,
# )))

## K8s pretrain
# hyperparams = Dict(pairs((;
#     # Set params
#     tag = joinpath("HO_220224_154551", "k8s_long_pretrain"),
#     env = :simpleflipsplit2v2uneven,
# 
#     # Optimized params
#     lr_alpha = 5.0e-5,
#     target_entropy = 10.0,
#     frames = 2,
#     γ = 0.9,
#     τ = 0.01,
#     start_steps = 10_000_000,
#     update_after = 1000,
#     replay_size = 500000,
#     hidden_units_policy = 20,
#     hidden_units_value = 150,
#     hidden_layers_policy = 2,
#     hidden_layers_value = 4,
#     batch_size = 100,
#     update_freq = 8,
#     actfun = elu,
#     reward_scaling = 0.5,
#     closing_cost = 0.0,
# 
#     # Always
#     logging = true,
#     verbose = true,
#     seed = 123,
#     timesteps = 20_000_000,
#     start_policy = :WrappedAgent,
#     wrapped_policy = :K8sAgent,
# )))

hyperparams = Dict(pairs((;
    # Set params
    tag = joinpath("custom", "len3min1nofracval"),
    env = :simpleflipL3min1,

    # Optimized params
    lr_alpha = 5.0e-5,
    target_entropy = 7.5,
    frames = 2,
    γ = 0.93,
    τ = 0.01,
    start_steps = 50000,
    update_after = 1000,
    replay_size = 500000,
    hidden_units_policy = 20,
    hidden_units_value = 120,
    hidden_layers_policy = 2,
    hidden_layers_value = 4,
    batch_size = 100,
    update_freq = 8,
    actfun = elu,
    reward_scaling = 0.5,
    closing_cost = 0.0,

    # Always
    logging = true,
    verbose = true,
    seed = 24837293,
    timesteps = 20_000_000,
    start_policy = :RandomAgent,
)))

# Run RL + baselines locally with logging and different seed

for agent in [:SAC, :SimpleAgent, :K8sAgent, :OracleAgent]
    run_experiment(; 
        hyperparams...,
        alg=agent,
    )
end


# tag = joinpath(hyperparams[:tag], "train_$(seed)")
# run_experiment(; 
#     hyperparams...,
#     tag,
#     alg=:SAC,
# )
# run_experiment(; 
#     hyperparams...,
#     tag,
#     loadpath=??,
#     alg=:LoadedAgent,
# )