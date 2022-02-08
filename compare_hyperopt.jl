using ServiceMeshLearning, Flux, Dates

hyperparams = [
    :lr_alpha => 1.0e-5,
    :target_entropy => 10.0,
    :frames => 3,
    :γ => 0.9,
    :τ => 0.01,
    :start_steps => 500,
    :update_after => 100,
    :replay_size => 1_000,
    :hidden_units_policy => 20,
    :hidden_units_value => 150,
    :hidden_layers_policy => 3,
    :hidden_layers_value => 2,
    :batch_size => 100,
    :update_freq => 8,
    :actfun => σ,
    :reward_scaling => 1.0,
    :closing_cost => 0.0,
    :env => :simpleflipsplit4,
    :tag => "HO_$(Dates.format(now(), "yymmdd_HHMMSS"))",
    :logging => true,
    :verbose => true,
    :seed => 24837293,
    :timesteps => 15_000_000,
    :start_policy => :SimpleAgent,
]

# Run RL + baselines locally with logging and different seed

run_experiment(; 
    hyperparams...,
    alg=:SimpleAgent, 
)

run_experiment(; 
    hyperparams...,
    alg=:K8sAgent, 
)

run_experiment(; 
    hyperparams...,
    alg=:OracleAgent, 
)
    
run_experiment(; 
    hyperparams...,
    alg = :SAC,
)