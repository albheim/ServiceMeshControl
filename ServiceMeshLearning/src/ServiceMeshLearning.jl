module ServiceMeshLearning

export create_experiment, run_experiment, create_env, create_wrapped_env, create_agent

using Dates
using Distributions
using Flux
using ReinforcementLearning
using Logging, TensorBoardLogger
using Random, StableRNGs
using IntervalSets
using Statistics
using BSON

using ServiceMesh

include("util.jl")
include("agents/guided_policy.jl") # Hooks need this and agents need hooks...
include("hooks.jl")
include("agents/agents.jl")
include("env.jl")


function create_experiment(;
    alg::Symbol = :SAC,
    tag::String = "test",
    timesteps::Int = 1_000_000,
    n_env = 1,
    log_every = 60,
    logging = true,
    running_reward_steps = 3600*24*2, # 2 days?
    verbose=true,
    env=:default,
    kwargs...
)
    if alg === :PPO
        fullenv = MultiThreadEnv(() -> create_wrapped_env(; env, kwargs...), n_env)
    elseif alg in [:SAC, :Guided, :DDPG, :TD3]
        fullenv = create_wrapped_env(; env, kwargs...)
    elseif alg in [:SimpleAgent, :ConstantAgent, :K8sAgent, :OracleAgent]
        fullenv = create_env(; env, kwargs...)
    else
        error("Algorithm $(alg) not in env creation list.")
    end

    agent = create_agent(Val(alg); env=fullenv, n_env=n_env, kwargs...)

    hooks = AbstractHook[RunningReward(running_reward_steps; envmap = env -> env[!])]
    if logging
        curr_time = Dates.format(now(), "yymmdd_HHMMSS")
        save_dir = mkpath(joinpath(homedir(), "servicemesh_results", "$(env)", tag, "$(alg)", "$curr_time"))
        verbose && @show save_dir
        push!(hooks, LogEveryNStep(save_dir; n=log_every))
        push!(hooks, DoOnExit( 
            function(agent, env) 
                # Log all hyperparam data
                open("$(save_dir)/params.txt", "w") do io
                    params = (; alg, tag, timesteps, n_env, log_every, logging, running_reward_steps, verbose, env, kwargs...)
                    join(io, map(k -> "$(k) = $(params[k])", keys(params)), "\n")
                end
                # Log policy if agent has policy field
                if hasproperty(agent, :policy) 
                    BSON.@save "$(save_dir)/policy.bson" policy=agent.policy
                end
            end
        ))
    end
    hooks = ComposedHook(hooks...)

    stop_condition = StopAfterStep(timesteps; is_show_progress=verbose)

    Experiment(agent, fullenv, stop_condition, hooks, "## ServiceMesh $(tag)")
end

function run_experiment(; verbose=true, kwargs...)
    e = create_experiment(; verbose=verbose, kwargs...)
    run(e; describe=verbose)
    return mean(e.hook.hooks[1].rewards)
end

end # module
