mutable struct GuidedPolicy{
    P1 <: AbstractPolicy, 
    P2 <: AbstractPolicy
} <: AbstractPolicy
    learner::P1
    teacher::P2
    norm_limit::Float32
    update_norm_limit::Bool
    target_ratio::Float32
    actor_history::Vector{Bool} # True if learner took action, false if not
    history_ptr::Int
end
function GuidedPolicy(
    learner, teacher;
    norm_limit=2f0,
    update_norm_limit=false,
    history_length=3600,
    target_ratio=0.95f0,
    kwargs...
)  
    GuidedPolicy(
        learner, 
        teacher, 
        norm_limit, 
        update_norm_limit, 
        target_ratio, 
        Vector{Bool}(undef, update_norm_limit ? history_length : 1),
        0
    )
end

function (p::GuidedPolicy)(env)
    A = action_space(env[!])
    alow = [x.left for x in A]
    ahigh = [x.right for x in A]

    a = p.learner(env)
    ascaled = 0.5 .* (p.learner(env) .+ 1) .* (ahigh .- alow) .+ alow
    p.history_ptr = (p.history_ptr % length(p.actor_history)) + 1
    last_a = map(ms -> length(ms.target_nodes), env[!].microservices)
    normsq = sum(abs2, (ascaled .- last_a))
    p.actor_history[p.history_ptr] = normsq / length(a) < p.norm_limit^2
    if p.update_norm_limit
        p.norm_limit *= mean(p.actor_history) / p.target_ratio
    end
    if !p.actor_history[p.history_ptr]
        a = 2 .* (p.teacher(env[!]) .- alow) ./ (ahigh .- alow) .- 1
    end
    return a
end

function RLBase.update!(
    p::GuidedPolicy,
    traj::CircularArraySARTTrajectory,
    env::AbstractEnv,
    stage::PreActStage,
)
    update!(p.learner, traj, env, stage)
    update!(p.teacher, traj, env, stage)
end