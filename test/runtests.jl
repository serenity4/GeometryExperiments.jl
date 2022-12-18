using GeometryExperiments
using GeometryExperiments: index
using Test

const GE = GeometryExperiments
const P2 = Point2
const P3 = Point3

@testset "GeometryExperiments.jl" begin
  include("transforms.jl")
  include("primitives.jl")
  include("projections.jl")
  include("curves.jl")
  include("granular_vector.jl")
  include("meshes.jl")
end;
