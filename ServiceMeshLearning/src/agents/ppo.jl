# Generate a Agent with PPOPolicy based on inner env
function create_agent(
    ::Val{:PPO}; 
    update_freq=256, 
    n_env=1, 
    seed=37, 
    kwargs...
)
    rng = StableRNG(seed)
    inner_env = create_env()
    ns = length(state_space(inner_env))
    na = length(action_space(inner_env))

    init = glorot_uniform(rng)
    return Agent(
        policy = PPOPolicy(
            approximator = ActorCritic(
                actor = GaussianNetwork(
                    pre = Chain(
                        Dense(ns, 64, relu; init = init),
                        Dense(64, 64, relu; init = init),
                    ),
                    μ = Chain(
                        Dense(64, na, tanh; init = init), 
                    ),
                    logσ = Chain(
                        Dense(64, na; init = init),
                        x -> clamp.(x, eltype(x)(-10), eltype(x)(1)), # Constrain variance, don't want zero and don't want too big
                    )
                ),
                critic = Chain(
                    Dense(ns, 64, relu; init = init),
                    Dense(64, 64, relu; init = init),
                    Dense(64, 1; init = init),
                ),
                optimizer = ADAM(3e-4),
            ) |> cpu,
            update_freq = update_freq,
            n_random_start = 0,
            update_step = 0,
            γ = 0.99f0,
            λ = 0.95f0,
            clip_range = 0.2f0,
            max_grad_norm = 0.5f0,
            n_microbatches = 32,
            n_epochs = 10, # Collect update_freq*n_env data points, loop over them n_epochs times and randomly split into n_microbatches smaller updates each loop
            actor_loss_weight = 1.0f0,
            critic_loss_weight = 0.5f0,
            entropy_loss_weight = 0.00f0,
            dist = Normal,
            rng = rng,
        ),
        trajectory = PPOTrajectory(;
            capacity = update_freq,
            state = Matrix{Float32} => (ns, n_env),
            action = Matrix{Float32} => (na, n_env),
            action_log_prob = Vector{Float32} => (n_env,),
            reward = Vector{Float32} => (n_env,),
            terminal = Vector{Bool} => (n_env,),
        ),
    )
end