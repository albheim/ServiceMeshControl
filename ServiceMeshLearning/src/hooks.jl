mutable struct LogEnvFieldsEveryNStep <: AbstractHook
    n::Int
    t::Int
    fields::Vector{Symbol}
    lg::TBLogger
end
function LogEnvFieldsEveryNStep(save_dir, fields; n=1, t=0)
    lg = TBLogger(joinpath(save_dir, "tb_log"), min_level = Logging.Info)
    LogEnvFieldsEveryNStep(n, t, fields, lg)
end
function (hook::LogEnvFieldsEveryNStep)(::PostActStage, agent, env)
    hook.t += 1
    hook.t % hook.n != 0 && return

    while typeof(env) <: AbstractEnvWrapper
        env = env.env
    end

    with_logger(hook.lg) do 
        for field in hook.fields
            @info "env_fields" field = getfield(env, field) log_step_increment = 0
        end
        @info "increment" log_step_increment=hook.n
    end
end

# Helper methods to get to base env for logging
Base.getindex(env::MultiThreadEnv, ::typeof(!)) = env[1][!]

mutable struct LogEveryNStep <: AbstractHook
    n::Int
    t::Int
    lg::TBLogger{String, IOStream}
end
function LogEveryNStep(save_dir::String; n=1)
    lg = TBLogger(joinpath(save_dir, "tb_log"), min_level = Logging.Info)
    LogEveryNStep(n, 0, lg)
end
function (hook::LogEveryNStep)(::PostActStage, agent, env)
    hook.t += 1
    hook.t % hook.n != 0 && return

    with_logger(hook.lg) do 
        log_agent(agent)
        log_env(env[!])
        @info "increment" log_step_increment=hook.n
    end
end

log_agent(::AbstractPolicy) = nothing
log_agent(a::Agent{<:AbstractPolicy}) = log_agent(a.policy)
function log_agent(policy::PPOPolicy)
    @info(
        "training", 
        actor_loss = policy.actor_loss[end, end],
        critic_loss = policy.critic_loss[end, end],
        entropy_loss = policy.entropy_loss[end, end], 
        total_loss = policy.loss[end, end], 
        log_step_increment = 0
    )
end
function log_agent(policy::SACPolicy)
    @info(
        "training", 
        reward_term = policy.reward_term,
        entropy_term = policy.entropy_term,
        alpha = policy.α,
        log_step_increment = 0
    )
end
function log_agent(agent::GuidedPolicy)
    @info(
        "training", 
        learner_action = agent.actor_history[agent.history_ptr],
        log_step_increment = 0
    )
    log_agent(agent.learner)
    log_agent(agent.teacher)
end
function log_env(env::ServiceMeshEnv)
    for (i, ms) in enumerate(env.microservices)
        @info(
            "MS$(i)", 
            scale = ms.running_nodes,
            queue = max(0, length(ms.queue) - ms.running_nodes),
            booting = env.booting,
            closing = env.closing,
            processed_jobs = env.processed_jobs[i],
            utilization = ms.running_nodes == 0 ? isempty(ms.queue) ? 1 : ms.max_queue : length(ms.queue) / ms.running_nodes,
            log_step_increment = 0
        )
    end
    for i in eachindex(env.jobtypes)
        @info(
            "Job$(i)",
            arrivals = env.arrivals[i],
            dropped = env.dropped_jobs[i],
            finished = env.finished_jobs[i],
            missed = env.missed_deadlines[i],
            log_step_increment = 0
        )
    end
    @info(
        "other", 
        time = env.time, 
        log_step_increment = 0
    )
    @info(
        "training", 
        profit = reward(env[!]), # Reward of base env is pure profit, other stuff is added in wrappers
        reward = reward(env), 
        log_step_increment = 0
    )
end

"""
    Keep track of a running average of the reward over a number of steps `n`.
"""
mutable struct RunningReward{F} <: AbstractHook
    rewards::Vector{Float64}
    pointer::Int
    envmap::F
end
function RunningReward(n; envmap=identity)
    RunningReward(zeros(n), 1, envmap)
end
function (hook::RunningReward)(::PostActStage, agent, env)
    hook.rewards[hook.pointer] = mean(reward(hook.envmap(env))) # mean in case of MultiThreadEnv
    hook.pointer %= length(hook.rewards)
    hook.pointer += 1
end