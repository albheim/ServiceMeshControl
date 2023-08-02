using ServiceMeshLearning, Flux

hyperparams = Dict(pairs((;
    # Set params
    tag = "50days",
    env = :double_value,

    # Optimized params
    lr_alpha = 5.0e-5,
    target_entropy = 10,
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
    timesteps = 60*60*24*50,
    start_policy = :RandomAgent,
)))

# Run RL + baselines locally with logging and different seed

for agent in [:SAC, :SimpleAgent, :K8sAgent, :OracleAgent]
    run_experiment(; 
        hyperparams...,
        alg=agent,
    )
end
