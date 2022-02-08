function create_env(; seed=37, microservices=2, env=:default, dt=0.5, kwargs...)
    boot_time=2.0
    instance_cost=1.0
    if env === :simple
        dt = 1.0
        jobtypes = JobParams[
            #JobParams([1], [0.1], 100, 10, ConstantArrival(5))
            JobParams(
                path=[1], 
                time=[1.0], 
                deadline=2.0, 
                value=10.0, 
                arrival=SinusArrival(40 * dt, 35 * dt, 6*3600)
                #ConstantArrival(200 * dt)
            )
        ]
        ServiceMeshEnv(;
            microservices = 1, 
            jobtypes = jobtypes,
            max_scale = 100, 
            max_queue = 100, 
            boot_time = 2.0, 
            dt = dt,
            instance_cost = instance_cost, 
            seed = seed,
            kwargs...
        )
    elseif env === :default
        dt = 0.5
        jobtypes = JobParams[
            #JobParams([1], [0.1], 100, 10, ConstantArrival(5))
            JobParams(
                path=[1, 2, 3], 
                time=[0.5, 0.5, 0.5], 
                deadline=4.0, 
                value=10.0, 
                # arrival=PoissonWrapper(SinusArrival(100 * dt, 75 * dt, 24*3600)),
                arrival=SinusArrival(100 * dt, 75 * dt, 24*3600),
            ),
            JobParams(
                path=[1, 3], 
                time=[0.5, 1.0], 
                deadline=3.0, 
                value=10.0, 
                # arrival=PoissonWrapper(SinusArrival(75 * dt, 60 * dt, 24*3600)),
                arrival=SinusArrival(75 * dt, 60 * dt, 24*3600),
            ),
        ]
        ServiceMeshEnv(;
            microservices = 3, 
            jobtypes = jobtypes,
            max_scale = 200, 
            max_queue = 100, 
            boot_time = boot_time, 
            dt = dt,
            instance_cost = instance_cost, 
            seed = seed,
            kwargs...
        )
    elseif env === :designed
        dt = 0.1
        jobtypes = JobParams[
            JobParams(
                path=[1, 2, 3], 
                time=[0.1, 0.2, 0.5], 
                deadline=1.0, 
                value=10.0, 
                # arrival=PoissonWrapper(SinusArrival(100 * dt, 75 * dt, 24*3600)),
                arrival=SinusArrival(100 * dt, 75 * dt, 24*3600),
            ),
            JobParams(
                path=[1, 3], 
                time=[0.1, 0.1], 
                deadline=1.0, 
                value=10.0, 
                # arrival=PoissonWrapper(SinusArrival(75 * dt, 60 * dt, 24*3600)),
                arrival=SinusArrival(75 * dt, 60 * dt, 24*3600),
            ),
        ]
        ServiceMeshEnv(;
            microservices = 3, 
            jobtypes = jobtypes,
            max_scale = 80, 
            max_queue = 50, 
            boot_time = boot_time, 
            dt = dt,
            instance_cost = instance_cost, 
            seed = seed,
            kwargs...
        )
    elseif env === :simpleflipsplit4
        dt = 1.0
        instance_cost = 1.0
        jobtypes = JobParams[
            JobParams(
                path = [1, 2, 4],
                time = Float64[1, 1, 1],
                deadline = 3.5, 
                value = 3 * (instance_cost + 1) + 6, # In case of booting factor 2 could help with not finding strange minima?
                arrival = FlippingArrival(dt/10, 0:3), # On average flip every 10 seconds and take step to neighbouring load in range 
            ),
            JobParams(
                path = [1, 3, 4],
                time = Float64[1, 1, 1],
                deadline = 3.5, 
                value = 3 * (instance_cost + 1) + 6, # In case of booting factor 2 could help with not finding strange minima?
                arrival = FlippingArrival(dt/10, 0:3), # On average flip every 10 seconds and take step to neighbouring load in range 
            ),
        ]
        ServiceMeshEnv(;
            kwargs...,
            microservices = 4, 
            jobtypes = jobtypes,
            min_scale = 0,
            max_scale = 10, 
            max_queue = 5, 
            close_time = 0.0, 
            boot_time = 1.0, 
            dt = dt,
            instance_cost = instance_cost, 
            seed = seed,
        )
    elseif env === :simpleflipsplit2
        dt = 1.0
        instance_cost = 1.0
        jobtypes = JobParams[
            JobParams(
                path = [1, 2, 3],
                time = Float64[1, 1, 1],
                deadline = 3.5, 
                value = 3 * (instance_cost + 1) + 6, # In case of booting factor 2 could help with not finding strange minima?
                arrival = FlippingArrival(dt/10, 0:3), # On average flip every 10 seconds and take step to neighbouring load in range 
            ),
            JobParams(
                path = [1, 3, 4],
                time = Float64[1, 1, 1],
                deadline = 3.5, 
                value = 3 * (instance_cost + 1) + 6, # In case of booting factor 2 could help with not finding strange minima?
                arrival = FlippingArrival(dt/10, 0:3), # On average flip every 10 seconds and take step to neighbouring load in range 
            ),
        ]
        ServiceMeshEnv(;
            kwargs...,
            microservices = 4, 
            jobtypes = jobtypes,
            min_scale = 0,
            max_scale = 10, 
            max_queue = 5, 
            close_time = 0.0, 
            boot_time = 1.0, 
            dt = dt,
            instance_cost = instance_cost, 
            seed = seed,
        )
    elseif env === :simpleflipsplit4
        dt = 1.0
        instance_cost = 1.0
        jobtypes = JobParams[
            JobParams(
                path = [1, 2, 4],
                time = Float64[1, 1, 1],
                deadline = 3.5, 
                value = 3 * (instance_cost + 1) + 6, # In case of booting factor 2 could help with not finding strange minima?
                arrival = FlippingArrival(dt/10, 0:3), # On average flip every 10 seconds and take step to neighbouring load in range 
            ),
            JobParams(
                path = [1, 3, 4],
                time = Float64[1, 1, 1],
                deadline = 3.5, 
                value = 3 * (instance_cost + 1) + 6, # In case of booting factor 2 could help with not finding strange minima?
                arrival = FlippingArrival(dt/10, 0:3), # On average flip every 10 seconds and take step to neighbouring load in range 
            ),
        ]
        ServiceMeshEnv(;
            kwargs...,
            microservices = 4, 
            jobtypes = jobtypes,
            min_scale = 0,
            max_scale = 10, 
            max_queue = 5, 
            close_time = 0.0, 
            boot_time = 1.0, 
            dt = dt,
            instance_cost = instance_cost, 
            seed = seed,
        )
    elseif env === :simpleflipsplit
        dt = 1.0
        instance_cost = 1.0
        jobtypes = JobParams[
            JobParams(
                path = [1, 2],
                time = Float64[1, 1],
                deadline = 2.5, 
                value = 2 * (instance_cost + 1) + 6, # In case of booting factor 2 could help with not finding strange minima?
                arrival = FlippingArrival(dt/10, 0:3), # On average flip every 10 seconds and take step to neighbouring load in range 
            ),
            JobParams(
                path = [1, 3],
                time = Float64[1, 1],
                deadline = 2.5, 
                value = 2 * (instance_cost + 1) + 6, # In case of booting factor 2 could help with not finding strange minima?
                arrival = FlippingArrival(dt/10, 0:3), # On average flip every 10 seconds and take step to neighbouring load in range 
            ),
        ]
        ServiceMeshEnv(;
            kwargs...,
            microservices = 3, 
            jobtypes = jobtypes,
            min_scale = 0,
            max_scale = 10, 
            max_queue = 5, 
            close_time = 0.0, 
            boot_time = 1.0, 
            dt = dt,
            instance_cost = instance_cost, 
            seed = seed,
        )
    elseif env === :simpleflip
        dt = 1.0
        instance_cost = 1.0
        jobtypes = JobParams[
            JobParams(
                path = collect(1:microservices), 
                time = ones(microservices), 
                deadline = microservices + 0.5, 
                value = microservices * (instance_cost + 1) + 6, # In case of booting factor 2 could help with not finding strange minima?
                arrival = FlippingArrival(dt/10, 0:3), # On average flip every 10 seconds and take step to neighbouring load in range 
            ),
        ]
        ServiceMeshEnv(;
            kwargs...,
            microservices = microservices, 
            jobtypes = jobtypes,
            min_scale = 0,
            max_scale = 10, 
            max_queue = 5, 
            close_time = 0.0, 
            boot_time = 1.0, 
            dt = dt,
            instance_cost = instance_cost, 
            seed = seed,
        )
    elseif env === :simplestream
        dt = 1.0
        jobtypes = JobParams[
            JobParams(
                path = [1, 2], 
                time = [1.0, 1.0], 
                deadline = 1.5, 
                value = 100.0, 
                arrival = StreamArrival(dt/10, 20.0), # every 100 s on avg there is a 20 s load stream added taking 1 machine for each step
            ),
        ]
        ServiceMeshEnv(;
            microservices = 2, 
            jobtypes = jobtypes,
            max_scale = 10, 
            max_queue = 5, 
            boot_time = 1.0, 
            dt = dt,
            instance_cost = 10.0, 
            seed = seed,
            kwargs...
        )
    elseif env === :stream
        dt = 0.1
        jobtypes = JobParams[
            JobParams(
                path=[1, 2, 3], 
                time=[0.1, 0.2, 0.5], 
                deadline=1.0, 
                value=10.0, 
                arrival=StreamArrival(dt/100, 100.0), # every 100 s on avg there is a 100 s load stream added taking 1 machine
            ),
            # JobParams(
            #     path=[1, 3], 
            #     time=[0.5, 5.0], 
            #     deadline=8.0, 
            #     value=10.0, 
            #     arrival=StreamArrival(0.5, 2.0, 1.0),
            # ),
        ]
        ServiceMeshEnv(;
            microservices = 3, 
            jobtypes = jobtypes,
            max_scale = 10, 
            max_queue = 1, 
            boot_time = boot_time, 
            dt = dt,
            instance_cost = instance_cost, 
            seed = seed,
            kwargs...
        )
    else
        throw(ArgumentError("no env for that tag."))
    end
end

function state_action_scaling_wrapper(env; frames=1, reward_scaling=0.001, closing_cost=0.0, state_smoothing=0.0, kwargs...)
    A = action_space(env)
    alow = [x isa UnitRange ? x.start : x.left for x in A]
    ahigh = [x isa UnitRange ? x.stop : x.right for x in A]
    S = state_space(env)
    slow = [x.left for x in S]
    shigh = [x.right for x in S]

    wrapped_env = env
    if closing_cost != 0
        wrapped_env = RewardOverriddenEnv(wrapped_env, 
            function(env)
                num_closing = sum(ms->length(ms.closing_nodes), env.microservices)
                reward(env) - closing_cost * num_closing
            end
        )
    end

    wrapped_env = ActionTransformedEnv(
        StateTransformedEnv(
            RewardTransformedEnv(wrapped_env, x -> x * reward_scaling);
            state_mapping = x -> 2 .* (x .- slow) ./ (shigh .- slow) .- 1,
            state_space_mapping = x -> Space([-1f0..1f0 for _ in x])
        ); 
        action_mapping = x -> round.(Int, clamp.(alow .+ (x .+ 1) .* 0.5 .* (ahigh .- alow), alow, ahigh)),
        action_space_mapping = x -> Space([-1f0..1f0 for _ in x])
    ) 

    if frames != 1
        wrapped_env = StateStackedEnv(wrapped_env; n=frames) 
    elseif state_smoothing != 0
        wrapped_env = SmoothedStateEnv(wrapped_env; smoothing=state_smoothing)
    end

    return wrapped_env
end

create_wrapped_env(; kwargs...) = state_action_scaling_wrapper(create_env(; kwargs...); kwargs...)


# StateStacked wrapper
mutable struct StateStackedEnv{E<:AbstractEnv, T} <: AbstractEnvWrapper
    env::E
    state::Matrix{T}
    ptr::Int
end

StateStackedEnv(env; n=1) = 
    StateStackedEnv(env, repeat(state(env), 1, n), 1)

function (env::StateStackedEnv)(a) 
    env[](a)
    env.ptr %= size(env.state, 2)
    env.ptr += 1
    env.state[:, env.ptr] .= state(env[])
    nothing
end

RLBase.state(env::StateStackedEnv) = vcat(
    reshape(env.state[:, (env.ptr+1):end], :),
    reshape(env.state[:, 1:env.ptr], :)
)

RLBase.state_space(env::StateStackedEnv, args...; kwargs...) = 
    Space(vcat((state_space(env.env, args...; kwargs...).s for i in 1:size(env.state, 2))...))


# RunningState wrapper
mutable struct SmoothedStateEnv{E<:AbstractEnv, T} <: AbstractEnvWrapper
    env::E
    running_state::Vector{T}
    smoothing::Float64
end

SmoothedStateEnv(env; smoothing) = 
    SmoothedStateEnv(env, state(env), smoothing)

function (env::SmoothedStateEnv)(a) 
    env[](a)
    env.running_state .= (1 - env.smoothing) * env.running_state + env.smoothing * state(env[])
    nothing
end

RLBase.state(env::SmoothedStateEnv) = vcat(
    env.running_state,
    state(env[])
)

RLBase.state_space(env::SmoothedStateEnv, args...; kwargs...) = 
    Space(vcat((state_space(env.env, args...; kwargs...).s for i in 1:2)...))