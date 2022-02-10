using ServiceMeshLearning, Flux

hyperparams = Dict(pairs((;
    # Set params
    tag = "HO_20210_125212",
    env = :simpleflipsplit4,

    # Optimized params,
    lr_alpha = 5.0e-5,
    target_entropy = 10.0,
    frames = 3,
    γ = 0.9,
    τ = 0.002,
    start_steps = 50000,
    update_after = 100,
    replay_size = 500000,
    hidden_units_policy = 100,
    hidden_units_value = 150,
    hidden_layers_policy = 1,
    hidden_layers_value = 4,
    batch_size = 200,
    update_freq = 24,
    actfun = σ,
    reward_scaling = 1.0,
    closing_cost = 0.5,

    # Always
    logging = true,
    verbose = true,
    seed = 24837293,
    timesteps = 15_000_000,
    start_policy = :SimpleAgent,
)))

# Run RL + baselines locally with logging and different seed


for agent in [:SimpleAgent, :K8sAgent, :OracleAgent, :SAC]
    run_experiment(; 
        hyperparams...,
        alg=agent,
    )
end
