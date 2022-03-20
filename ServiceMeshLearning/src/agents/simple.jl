"""
    ConstantAgent

Takes constant actions.
"""
struct ConstantAgent <: AbstractPolicy
    scale::Int
end
create_agent(::Val{ConstantAgent}; scale=50, kwargs...) = ConstantAgent(scale)

function (a::ConstantAgent)(env::AbstractEnv)
    fill(a.scale, length(action_space(env)))
end

"""
    RandomAgent

Takes random actions.
"""
struct RandomAgent <: AbstractPolicy
    rng::AbstractRNG
end
create_agent(::Val{:RandomAgent}; seed = 37, kwargs...) = RandomAgent(StableRNG(seed))

function (a::RandomAgent)(env::AbstractEnv)
    round.(Int, rand.(a.rng, action_space(env)))
end

""" 
    SinusAgent

`period` is the period in steps, the whole curve will be between `0` and `2*amplitude`
"""
mutable struct SinusAgent <: AbstractPolicy
    period::Float64
    amplitude::Float64
    step::Int
end
create_agent(::Val{:SinusAgent}; period=1000, amplitude=40.0, kwargs...) = SinusAgent(period, amplitude, 0)

function (a::SinusAgent)(env::AbstractEnv)
    a.step += 1
    round.(Int, a.amplitude .* (1 .+ sin(a.step * 2π / a.period)) .+ ones(length(action_space(env))))
end

"""
    SimpleAgent

Something similar to the k8s scaler
"""
struct SimpleAgent <: AbstractPolicy
    down::Float64
    up::Float64
end
create_agent(::Val{:SimpleAgent}; down = 0.5, up = 0.8, kwargs...) = SimpleAgent(down, up)

function (agent::SimpleAgent)(env::AbstractEnv)
    env = env[!]
    a = Int[ms.running_nodes for ms in env.microservices]
    for (i, ms) in enumerate(env.microservices)
        util = length(ms.queue) / ms.running_nodes
        if util < agent.down
            a[i] -= 1
        elseif util > agent.up
            a[i] += 1
        end
    end
    lowas = [as.left for as in env.action_space]
    highas = [as.right for as in env.action_space]
    return clamp.(a, lowas, highas)
end

# Guided
function create_agent(::Val{:Guided}; 
    learner, teacher, 
    kwargs...
)
    learner = create_agent(Val(learner); kwargs...)
    teacher = create_agent(Val(teacher); kwargs...)
    GuidedPolicy(learner, teacher; kwargs...)
end


"""
    K8sAgent

Something similar to the k8s scaler
"""
mutable struct K8sAgent <: AbstractPolicy
    desired_util::Float64
    step_tolerance::Float64
    scale_memory::Matrix{Int}
    mem_ptr::Int
end
create_agent(::Val{:K8sAgent}; desired_util=0.8, stabilization_steps=300, step_tolerance=0.1, env, kwargs...) = K8sAgent(desired_util, step_tolerance, zeros(Int, length(env.microservices), stabilization_steps), 1)

function (agent::K8sAgent)(env::AbstractEnv)
    env = env[!]

    newptr = mod(agent.mem_ptr, size(agent.scale_memory, 2)) + 1
    for (i, ms) in enumerate(env.microservices)
        rn = max(1e-6, ms.running_nodes) # To avoid problems when running_nodes == 0
        util = min(1, length(ms.queue) / rn)
        ratio = util / agent.desired_util
        if abs(ratio - 1) < agent.step_tolerance # No new action if within limit
            agent.scale_memory[i, newptr] = agent.scale_memory[i, agent.mem_ptr]
        else # Record new desired action
            agent.scale_memory[i, newptr] = ceil(Int, rn * ratio)
        end
    end

    agent.mem_ptr = newptr

    a = vec(maximum(agent.scale_memory, dims=2)) # Take max of desired action in window

    lowas = [as.left for as in env.action_space]
    highas = [as.right for as in env.action_space]
    return clamp.(a, lowas, highas)
end


"""
    Oracle

Optimal agent with assumption of knowledge of graph and delays, hardcoded for simpleflip env
"""
struct OracleAgent <: AbstractPolicy
end
create_agent(::Val{:OracleAgent}; kwargs...) = OracleAgent()

function (agent::OracleAgent)(env::AbstractEnv)
    env = env[!]
    a = zeros(Int, length(env.microservices))
    q = map(ms -> length(ms.queue), env.microservices)
    for tidx in 1:length(env.jobtypes)
        q = map(ms -> count(job -> job.typeindex == tidx, ms.queue), env.microservices[env.jobtypes[tidx].path])
        a[env.jobtypes[tidx].path] .+= [q[1] + 1; [max(q[i-1], q[i]) for i in 2:length(q)]]
    end
    lowas = [as.left for as in env.action_space]
    highas = [as.right for as in env.action_space]
    return clamp.(a, lowas, highas)
end


"""
    Loaded

Loads bson saved policy and acts on it using mean values of actions
"""
struct LoadedAgent{P<:GaussianNetwork} <: AbstractPolicy
    policy::P
end
function create_agent(::Val{:LoadedAgent}; loadpath::String, kwargs...)
    # Expects SAC, probably works with others with gaussian net
    # Though make sure the correct env is used then
    dict = BSON.load(loadpath)
    LoadedAgent(dict[:policy].policy.model)
end
function (agent::LoadedAgent)(env::AbstractEnv)
    s = state(env)
    action_mean, action_std = agent.policy(s)
    return action_mean
end

""" 
    Wrapped

Wraps an env that returns from the inner action space, to a normalized action space.
"""
struct WrappedAgent{P<:AbstractPolicy,F<:Function} <: AbstractPolicy
    policy::P
    action_transform::F
end
function create_agent(::Val{:WrappedAgent}; env, wrapped_policy, kwargs...)
    A = action_space(env)
    alow = [x isa UnitRange ? x.start : x.left for x in A]
    ahigh = [x isa UnitRange ? x.stop : x.right for x in A]

    action_mapping(a) = 2 .* (a .- alow) ./ (ahigh .- alow) .- 1
    inner_agent = create_agent(Val(wrapped_policy); env=env[!], kwargs...)

    WrappedAgent(inner_agent, action_mapping)
end
function (agent::WrappedAgent)(env::AbstractEnv)
    a = agent.policy(env[!]) # Get action based on base env
    return agent.action_transform(a)
end