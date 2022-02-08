
mutable struct HoldActionPolicy{P<:AbstractPolicy} <: AbstractPolicy
    policy::P
    last_action::Vector{Float32}
    action_interval::Int
    counter::Int
end

HoldActionPolicy(; policy::AbstractPolicy, action_interval::Int) = 
    HoldActionPolicy(policy, Vector{Float32}(undef, 0), action_interval, 0)

function (p::HoldActionPolicy)(env)
    if p.counter == 0
        p.last_action = p.policy(env)
        p.counter = p.action_interval
    end
    p.counter -= 1
    p.last_action # TODO shoudl this be copied?
end

function RLBase.update!(
    p::HoldActionPolicy,
    traj::CircularArraySARTTrajectory,
    env::AbstractEnv,
    stage::PreActStage,
)
    update!(p.policy, traj, env, stage)
end

log_agent(p::HoldActionPolicy) = log_agent(p.policy)
