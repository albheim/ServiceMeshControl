
mutable struct RunningAvgPolicy{P<:AbstractPolicy} <: AbstractPolicy
    policy::P
    running_avg::Vector{Float32}
    smoothing::Float32
end

RunningAvgPolicy(; policy::AbstractPolicy, smoothing::Float32, na::Int) = 
    RunningAvgPolicy(policy, zeros(Float32, na), smoothing)

function (p::RunningAvgPolicy)(env)
    a = p.policy(env)
    p.running_avg .= p.smoothing .* p.running_avg .+ (1 .- p.smoothing) .* a
end

function RLBase.update!(
    p::RunningAvgPolicy,
    traj::CircularArraySARTTrajectory,
    env::AbstractEnv,
    stage::PreActStage,
)
    update!(p.policy, traj, env, stage)
end

log_agent(p::RunningAvgPolicy) = log_agent(p.policy)
