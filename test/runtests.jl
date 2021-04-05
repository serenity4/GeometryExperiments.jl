using GeometryExperiments
using Test

@testset "GeometryExperiments.jl" begin
    @test Transformed(HyperCube(0.2), Scaling(1., 2., 3.)) === Box(0.2, Scaling(1., 2., 3.))
end
