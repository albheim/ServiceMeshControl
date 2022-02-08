
Base.@kwdef mutable struct Microservice
    target_nodes::Int = 1
    running_nodes::Int = 1
    booting_nodes::Vector{Float64} = Vector{Float64}()
    closing_nodes::Vector{Float64} = Vector{Float64}()
    queue::Vector{Job} = Vector{Job}() # Waiting jobs and jobs being worked on are in this
    boot_time::Float64
    close_time::Float64
    min_scale::Int
    max_scale::Int
    max_queue::Int
    instance_cost::Float64
end

function Base.show(io::IO, ms::Microservice)
    print(io, "MS($(ms.running_nodes)->$(ms.target_nodes), +$(ms.booting_nodes), -$(ms.closing_nodes), $(ms.queue))")
end
function Base.show(io::IO, mss::Vector{Microservice})
    println("Microservices: ")
    for ms in mss
        println(io, ms)
    end
end

function scale(ms::Microservice, a)
    ms.target_nodes = a
    if ms.running_nodes < a
        # We have to few nodes running, check running + booting
        if ms.running_nodes + length(ms.booting_nodes) < a
            # Need more booting
            n_boot = a - ms.running_nodes - length(ms.booting_nodes)
            append!(ms.booting_nodes, fill(ms.boot_time, n_boot))
        elseif a < ms.running_nodes + length(ms.booting_nodes)
            # Too many booting
            n_remove =  length(ms.booting_nodes) - (a - ms.running_nodes)
            deleteat!(ms.booting_nodes, length(ms.booting_nodes) - n_remove + 1 : length(ms.booting_nodes))
            append!(ms.closing_nodes, fill(ms.close_time, n_remove))
        end
    elseif a < ms.running_nodes
        # We have to many nodes, close all booting and any additional
        n_close = ms.running_nodes - a + length(ms.booting_nodes)
        ms.running_nodes = a # Currently we immideately scale down, but this also makes jobs not be worked on
        append!(ms.closing_nodes, fill(ms.close_time, n_close))
        empty!(ms.booting_nodes)
    end
end