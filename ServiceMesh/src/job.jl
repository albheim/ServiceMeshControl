abstract type AbstractArrival end

# TODO do typing on all times? Or just have floats?
Base.@kwdef struct JobParams{TA<:AbstractArrival}
    path::Vector{Int}
    time::Vector{Float64}
    deadline::Float64
    value::Float64
    arrival::TA
end

struct SinusArrival <: AbstractArrival
    rate_mean::Float64 
    rate_amplitude::Float64
    rate_period::Float64
end
function get_arrivals(rng, arrival::SinusArrival, time) 
    return arrival.rate_mean + arrival.rate_amplitude * sin(time * 2π / arrival.rate_period)
end
interval(a::SinusArrival) = (a.rate_mean - a.rate_amplitude)..(a.rate_mean + a.rate_amplitude)

struct SingleArrival <: AbstractArrival
    time::Int
end
get_arrivals(rng, arrival::SingleArrival, time) = time == arrival.time ? 1 : 0
interval(::SingleArrival) = 0..1

struct ConstantArrival <: AbstractArrival
    rate::Int
end
get_arrivals(rng, arrival::ConstantArrival, time) = arrival.rate
interval(a::ConstantArrival) = (a.rate-1)..(a.rate+1)

struct PoissonWrapper{T<:AbstractArrival} <: AbstractArrival
    arrival::T
end
get_arrivals(rng, arrival::PoissonWrapper, time) = rand(rng, Poisson(get_arrivals(rng, arrival.arrival, time)))
interval(a::PoissonWrapper) = 0..(2*interval(a.arrival).right)

mutable struct StreamArrival <: AbstractArrival
    rate::Float64
    duration::Float64
    arrival_times::Vector{Float64}
    StreamArrival(rate, duration) = new(rate, duration, Vector{Float64}())
end
function get_arrivals(rng, a::StreamArrival, time) 
    if rand(rng) < a.rate
        push!(a.arrival_times, time)
    end
    filter!(t -> t + a.duration > time, a.arrival_times)
    return length(a.arrival_times)
end
interval(a::StreamArrival) = 0..(2*a.rate*a.duration*a.volume)

mutable struct FlippingArrival{T<:AbstractArray} <: AbstractArrival
    rate::Float64
    values::T
    idx::Int
    FlippingArrival(rate, values) = new{typeof(values)}(rate, values, 1)
end
function get_arrivals(rng, a::FlippingArrival, time) 
    if rand(rng) < a.rate 
        a.idx = rand(rng, max(1, a.idx - 1):min(length(a.values), a.idx + 1))
    end
    return a.values[a.idx]
end
interval(a::FlippingArrival) = minimum(a.values)..maximum(a.values)

mutable struct Job
    typeindex::Int
    pathindex::Int
    countdown::Float64 # Countdown used for work done on each node
    arrivaltime::Float64 # Used for checking total time vs deadline
end

Base.show(io::IO, a::Job) = print(io, "Job(tid=$(a.typeindex), pid=$(a.pathindex), cnt=$(a.countdown), start=$(a.arrivaltime))")
