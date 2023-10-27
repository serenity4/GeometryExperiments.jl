using GeometryExperiments
using GeometryExperiments: index, Point, Point2, Point2f, Box, Mesh
using GLTF
using Test
using SymbolicGA: @ga

const GE = GeometryExperiments
const P2 = Point2
const P3 = Point3

@testset "GeometryExperiments.jl" begin
  include("transforms.jl")
  include("primitives.jl")
  include("pointsets.jl")
  include("boundingelement.jl")
  include("projections.jl")
  include("curves.jl")
  include("granular_vector.jl")
  include("meshes.jl")
  include("intersections.jl")
  include("camera.jl")
end;
