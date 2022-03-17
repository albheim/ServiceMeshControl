"""
A simple simulation environment for a service mesh
"""
mutable struct ServiceMeshEnv{AT, R<:AbstractRNG} <: AbstractEnv
    # Mesh
    microservices::Vector{Microservice}

    # Jobs
    jobtypes::Vector{JobParams}

    # Track job data
    arrivals::Vector{Int}
    finished_jobs::Vector{Int}
    missed_deadlines::Vector{Int}
    dropped_jobs::Vector{Int}
    processed_jobs::Vector{Int}
    booting::Int
    closing::Int

    # Time
    time::Float64 
    steplength::Float64 # Will be rounded down to even number of dts approximately
    dt::Float64 

    # Spaces
    action_space::Space{Vector{AT}}
    state_space::Space

    # Other
    rng::R 
end

function ServiceMeshEnv(;
        microservices::Int, 
        min_scale::Int=1,
        max_scale::Int, 
        boot_time::Float64, 
        close_time::Float64 = boot_time, 
        max_queue::Int, 
        instance_cost::Float64, 
        jobtypes::Vector{JobParams},
        steplength::Float64 = 1.0, 
        dt::Float64 = 0.01,
        seed = 37,
        relative_action::Int=0,
        kwargs...
    ) 
    action_space = if relative_action != 0
        Space([-relative_action:relative_action for i in 1:microservices])
    else 
        Space(ClosedInterval[min_scale..max_scale for i in 1:microservices])
    end
    ServiceMeshEnv(
        # Mesh
        [Microservice( 
            boot_time = boot_time,
            close_time = close_time,
            min_scale = min_scale,
            max_scale = max_scale,
            max_queue = max_queue,
            instance_cost = instance_cost,
        ) for i in 1:microservices],

        # Job
        jobtypes, 
        zeros(Int, length(jobtypes)),

        # Track job data
        zeros(Int, length(jobtypes)),
        zeros(Int, length(jobtypes)),
        zeros(Int, length(jobtypes)),
        zeros(Int, microservices), 
        0,
        0,

        # Time
        0.0,
        steplength,
        dt, 
        action_space,
        # Space(ClosedInterval[-1..1 for i in 1:microservices]),
        Space( 
            ClosedInterval{Float64}[
                [min_scale..max_scale for i in 1:microservices]; # Running
                [0..1 for i in 1:microservices]; # Utilization
                # [0..max_queue for i in 1:microservices]; # Queue
                # [1..max_scale for i in 1:microservices]; # Target
                # [0..max_scale for i in 1:microservices]; # Booting
                # [0..max_scale for i in 1:microservices]; # Closing
                # [interval(jobtype.arrival) for jobtype in jobtypes]; # Arrival
            ]
        ),
        StableRNG(seed),
    )
end

""" 
When a job finished execution on one node this finds the next step for it (next node, dropped, done)
"""
function propagate!(env::ServiceMeshEnv, job::Job)
    job.pathindex += 1
    if job.pathindex <= length(env.jobtypes[job.typeindex].path)
        dest = env.jobtypes[job.typeindex].path[job.pathindex]
        if length(env.microservices[dest].queue) < env.microservices[dest].running_nodes + env.microservices[dest].max_queue
            push!(env.microservices[dest].queue, job)
            job.countdown = env.jobtypes[job.typeindex].time[job.pathindex]
        else
            env.dropped_jobs[job.typeindex] += 1
        end
    else
        if env.time - job.arrivaltime < env.jobtypes[job.typeindex].deadline
            env.finished_jobs[job.typeindex] += 1
        else
            env.missed_deadlines[job.typeindex] += 1
        end
    end
end

Random.seed!(env::ServiceMeshEnv, seed) = Random.seed!(env.rng, seed)
RLBase.is_terminated(env::ServiceMeshEnv) = false

function RLBase.reset!(env::ServiceMeshEnv)
    for ms in env.microservices
        ms.target_nodes = 1
        ms.running_nodes = 1 
        empty!(ms.booting_nodes)
        empty!(ms.closing_nodes)
        empty!(ms.queue)
    end

    fill!(env.arrivals, 0)
    fill!(env.finished_jobs, 0)
    fill!(env.missed_deadlines, 0)
    fill!(env.dropped_jobs, 0)
    fill!(env.processed_jobs, 0)
    env.booting = 0
    env.closing = 0

    env.time = 0
end

RLBase.action_space(env::ServiceMeshEnv) = env.action_space
RLBase.state_space(env::ServiceMeshEnv) = env.state_space

function RLBase.state(env::ServiceMeshEnv)
    s = vcat(
        map(ms -> ms.running_nodes, env.microservices), 
        map(ms -> ms.running_nodes == 0 ? (isempty(ms.queue) ? 1.0 : ms.max_queue / 1)  : length(ms.queue) / ms.running_nodes, env.microservices),
        # begin
        #     tmp = map(ms->length(ms.queue), env.microservices)
        #     [tmp[1]; max.(tmp[1:end-1], tmp[2:end])]
        # end, 
        # map(ms->length(ms.queue), env.microservices), 
        # map(ms->ms.target_nodes, env.microservices), 
        # map(ms->length(ms.booting_nodes), env.microservices), 
        # map(ms->length(ms.closing_nodes), env.microservices), 
        # env.arrivals,
    )

    return s
end

function RLBase.reward(env::ServiceMeshEnv)
    value = sum((env.finished_jobs[i] + env.jobtypes[i].missed_value_fraction * env.missed_deadlines[i]) * env.jobtypes[i].value for i in eachindex(env.finished_jobs)) 
    cost = sum((ms.running_nodes + length(ms.booting_nodes) + length(ms.closing_nodes)) * ms.instance_cost for ms in env.microservices)
    return value - cost
end

function (env::ServiceMeshEnv{<:ClosedInterval})(a::Vector{Int}) 
    @assert a in action_space(env)
    _step!(env, a)
end

# For relative actions
function (env::ServiceMeshEnv{<:UnitRange})(a::Vector{Int}) 
    for (i, ms) in enumerate(env.microservices)
        a[i] = clamp(ms.target_nodes + a[i], ms.min_scale, ms.max_scale)
    end

    @assert all(minlim .<= a .<= maxlim)
    _step!(env, a)
end

function _step!(env::ServiceMeshEnv, a)
    # Reset all counting
    fill!(env.finished_jobs, 0)
    fill!(env.missed_deadlines, 0)
    fill!(env.dropped_jobs, 0)
    fill!(env.processed_jobs, 0)
    fill!(env.arrivals, 0)
    env.booting = 0
    env.closing = 0

    # Update target nodes and boot/close towards this, should only be needed before loop
    scale.(env.microservices, a)

    for _ in 1:round(Int, env.steplength / env.dt)
        done_jobs = Job[]
        # Simulate each MS
        for (i, ms) in enumerate(env.microservices)
            # Work on jobs
            done_idx = Int[]
            for i in 1:min(ms.running_nodes, length(ms.queue))
                ms.queue[i].countdown -= env.dt
                if ms.queue[i].countdown <= 0
                    push!(done_idx, i)
                end
            end
            append!(done_jobs, ms.queue[done_idx])
            deleteat!(ms.queue, done_idx)
            env.processed_jobs[i] += length(done_idx)

            # Log here to catch data before done
            env.booting += length(ms.booting_nodes)
            env.closing += length(ms.closing_nodes)

            # Booting
            ms.booting_nodes .-= env.dt
            nb = length(ms.booting_nodes)
            filter!(>(0), ms.booting_nodes)
            ms.running_nodes += nb - length(ms.booting_nodes)
            # Closing
            ms.closing_nodes .-= env.dt
            filter!(>(0), ms.closing_nodes)
        end
        for job in done_jobs
            propagate!(env, job)
        end

        # These are the checked types of jobs when arriving which we can use in state
        new_arrivals = round.(Int, [get_arrivals(env.rng, jobtype.arrival, env.time) for jobtype in env.jobtypes])
        env.arrivals .+= new_arrivals

        # Adds arrivals to queue and shuffle before propagation
        newjobs = vcat((fill(i, n) for (i, n) in enumerate(new_arrivals))...) 
        for jobtypeid in shuffle!(env.rng, newjobs)
            job = Job(jobtypeid, 0, 0, env.time) 
            propagate!(env, job)
        end

        env.time += env.dt
    end
end
