using Test
using ServiceMesh
using ReinforcementLearningBase

@testset "ReinforcementLearning interface test" begin
    env = ServiceMeshEnv(
        microservices = 3, 
        maxinstances = 100, 
        maxqueue = 10, 
        steplength = 1, 
        boottime = 3, 
        instancecost = 0.05, 
        jobtypes = [
            JobParams(1, [1, 2, 3], [2, 3, 5], ones(3), 100, 10.0, SingleArrival(5))
            JobParams(2, [1, 3], [5, 1], ones(2), 100, 10.0, SingleArrival(15))
        ],
        seed = 37,
    )
    
    @test RLBase.test_interfaces!(env)
end

@testset "Test Propagation" begin
    env = ServiceMeshEnv(
        microservices = 3, 
        maxinstances = 100, 
        maxqueue = 10, 
        steplength = 1, 
        boottime = 3, 
        instancecost = 0.05, 
        jobtypes = [
            JobParams(1, [1, 2, 3], [2, 3, 5], ones(3), 100, 10.0, SingleArrival(5))
            JobParams(2, [1, 3], [5, 1], ones(2), 100, 10.0, SingleArrival(15))
        ],
        seed = 37,
    )

    action = fill(5, 3)

    @test state(env) = []
end