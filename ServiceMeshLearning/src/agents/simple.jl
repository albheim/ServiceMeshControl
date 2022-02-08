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
    scaling_period::Float64
    scaledown_memory::Int
end
create_agent(::Val{:K8sAgent}; desired_util=0.8, scaling_period=15.0, kwargs...) = K8sAgent(desired_util, scaling_period, 0)

function (agent::K8sAgent)(env::AbstractEnv)
    env = env[!]
    a = Int[ms.target_nodes for ms in env.microservices]
    for (i, ms) in enumerate(env.microservices)
        desired = ceil(Int, length(ms.queue) / agent.desired_util)
        if desired > ms.target_nodes
            a[i] = min(desired, max(2 * a[i], a[i] + 4)) # Allowed to double or +4 in size, whichever is larger
        elseif desired < ms.target_nodes
            if agent.scaledown_memory < desired
                agent.scaledown_memory = desired
            end
            if mod(env.time, agent.scaling_period) < env.steplength
                a[i] = agent.scaledown_memory # Allowed to fully scale down, if largest action during scaling period wanted so
                agent.scaledown_memory = 0
            end
        end
    end
    lowas = [as.left for as in env.action_space]
    highas = [as.right for as in env.action_space]
    return clamp.(a, lowas, highas)
end


"""
    Oracle

Optimal agent with assumption of knowledge of graph and delays, hardcoded for simpleflip env
"""
mutable struct OracleAgent <: AbstractPolicy
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
