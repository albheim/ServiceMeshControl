function create_agent(
    ::Val{:DDPG};
    env,
    seed=37,
    kwargs...
)
    rng = StableRNG(seed)

    ns = length(state(env))
    na = length(action_space(env))

    init = glorot_uniform(rng)

    create_actor() = Chain(
        Dense(ns, 30, relu; init = init),
        Dense(30, 30, relu; init = init),
        Dense(30, na; init = init),
        softmax
    )

    create_critic() = Chain(
        Dense(ns + na, 30, relu; init = init),
        Dense(30, 30, relu; init = init),
        Dense(30, 1; init = init),
    )

    return Agent(
        policy = DDPGPolicy(
            behavior_actor = NeuralNetworkApproximator(
                model = create_actor(),
                optimizer = ADAM(),
            ),
            behavior_critic = NeuralNetworkApproximator(
                model = create_critic(),
                optimizer = ADAM(),
            ),
            target_actor = NeuralNetworkApproximator(
                model = create_actor(),
                optimizer = ADAM(),
            ),
            target_critic = NeuralNetworkApproximator(
                model = create_critic(),
                optimizer = ADAM(),
            ),
            γ = 0.99f0,
            ρ = 0.995f0,
            na = na,
            batch_size = 64,
            start_steps = 1000,
            start_policy = RandomPolicy(Space([-1.0..1.0 for i in 1:na]); rng = rng),
            update_after = 1000,
            update_freq = 1,
            act_limit = 1.0,
            act_noise = 0.01,
            rng = rng,
        ),
        trajectory = CircularArraySARTTrajectory(
            capacity = 10000,
            state = Vector{Float32} => (ns,),
            action = Float32 => (na,),
        ),
    )
end