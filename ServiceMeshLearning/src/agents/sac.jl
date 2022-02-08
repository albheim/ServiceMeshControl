function create_agent(
    ::Val{:SAC}; 
    env,
    seed=37, 
    lr_alpha=0.0001f0, 
    alpha=0.2f0,
    γ=0.99f0,
    τ = 0.005f0,
    target_entropy=0.5, # length(action_space(env)) orig
    replay_size=100000, # 10000 orig
    start_steps = 10000,
    update_after = 1000,
    hidden_units_policy=100, # 30 orig
    hidden_units_value=100, # 30 orig
    update_freq=10, # 50 orig
    batch_size=128, # 32 orig
    action_interval=1,
    hidden_layers_policy=2,
    hidden_layers_value=2,
    action_smoothing=0f0,
    clampfun=clamp,
    actfun=relu,
    start_policy=:RandomAgent,
    kwargs...
)
    rng = StableRNG(seed)

    ns = length(state(env))
    na = length(action_space(env))

    init = glorot_uniform(rng)

    create_policy_net() = NeuralNetworkApproximator(
        model = GaussianNetwork(
            pre = Chain(
                Dense(ns, hidden_units_policy, actfun; init=init), 
                [Dense(hidden_units_policy, hidden_units_policy, actfun; init=init) for i in 2:hidden_layers_policy]...,
            ),
            μ = Chain(Dense(hidden_units_policy, na; init=init)),
            logσ = Chain(
                Dense(hidden_units_policy, na; init=init),
                x -> clampfun.(x, -10f0, 3f0),
            ),
            # min_σ = 1f-10,
            # max_σ = 1f3, 
            # Not setting them means -Inf32..Inf32
        ),
        optimizer = ADAM(0.003),
    )

    create_q_net() = NeuralNetworkApproximator(
        model = Chain(
            Dense(ns + na, hidden_units_value, actfun; init=init),
            [Dense(hidden_units_value, hidden_units_value, actfun; init=init) for i in 2:hidden_layers_value]...,
            Dense(hidden_units_value, 1; init=init),
        ),
        optimizer = ADAM(0.003),
    )

    policy = SACPolicy(
        policy = create_policy_net(),
        qnetwork1 = create_q_net(),
        qnetwork2 = create_q_net(),
        target_qnetwork1 = create_q_net(),
        target_qnetwork2 = create_q_net(),
        γ = Float32(γ),
        τ = Float32(τ),
        α = Float32(alpha), 
        batch_size = batch_size,
        start_steps = start_steps,
        update_after = update_after,
        update_freq = update_freq,
        start_policy = create_agent(Val(start_policy); env),
        automatic_entropy_tuning = true,
        lr_alpha = Float32(lr_alpha),
        action_dims = target_entropy, 
        rng = rng,
    )

    if action_smoothing > 0
        policy = RunningAvgPolicy(
            policy = policy,
            smoothing = action_smoothing,
            na = na,
        )
    elseif action_interval > 1
        policy = HoldActionPolicy(
            policy = policy,
            action_interval = action_interval,
        )
    end

    Agent(
        policy = policy,
        trajectory = CircularArraySARTTrajectory(
            capacity = replay_size,
            state = Vector{Float32} => (ns,),
            action = Vector{Float32} => (na,),
        ),
    )
end