module GeometryExperiments

using StaticArrays: SVector, @SVector, setindex
using AbstractTrees
using Dictionaries
using LinearAlgebra
using SymbolicGA
using PrecompileTools
using CompileTraces
import ForwardDiff
using StructEquality

derivative(f::F, x) where {F} = ForwardDiff.derivative(f, x)
derivative(f::F) where {F} = t -> derivative(f, t)

const Point{Dim,T} = SVector{Dim,T}
const Optional{T} = Union{T,Nothing}

for i in 2:4
  for T in (Float32, Float64)
    sym = Symbol(:Point, i, T === Float64 ? "" : 'f')
    @eval const $sym = Point{$i,$T}
    @eval export $sym
  end
end

include("utils.jl")
include("solve.jl")
include("algebras.jl")

include("transforms.jl")
include("projection.jl")
include("primitives.jl")
include("pointsets.jl")

include("curves.jl")
include("curves/segment.jl")
include("curves/line.jl")
include("curves/bezier.jl")
include("curves/patch.jl")

include("intersections.jl")

include("granular_vector.jl")
include("mesh.jl")
include("mesh/attributes.jl")
include("mesh/diff.jl")
include("mesh/iteration.jl")
include("mesh/encodings.jl")
include("mesh/triangle_mesh.jl")
include("mesh/subdivide.jl")
include("mesh/triangulate.jl")
include("mesh/loading.jl")

include("camera.jl")

@compile_workload @compile_traces "precompilation_traces.jl"

export
  Point,

  # transforms
  Transform, Transformed,
  Scaling, Scaled, UniformScaling,
  Rotation, Rotated,
  RotationType, Quaternion,
  Translation, Translated,
  ComposedTransform,
  BoxTransform,
  transforms,

  # projections
  Projection,

  # primitives
  NormedPrimitive,
  HyperSphere, HyperCube,
  Ellipsoid,
  Box, box,
  Circle, Square,
  origin, radius,

  # pointsets
  PointSet,
  centroid,
  boundingelement,
  nearest,
  sort_nearest,

  # curves
  Segment,
  Curve,
  BezierCurve,
  BezierEvalMethod,
  Horner, FixedDegree,
  Patch,
  startindex,
  curve_points,

  # intersections
  projection_parameter,
  projection,
  Line,
  Plane,
  euclidean,

  # meshes
  Polytope,
  Mesh, MeshDiff, MeshStatistics,
  ishomogeneous, ismanifold,
  isquad, istri,
  location,
  vertices, adjacent_vertices,
  edges,
  faces, adjacent_faces,
  add_vertex!, add_edge!, add_face!,
  add_vertices!, add_edges!, add_faces!,
  rem_vertex!, rem_edge!, rem_face!,
  rem_vertices!, rem_edges!, rem_faces!,
  MeshVertex, MeshEdge, MeshFace,
  nv, ne, nf,
  apply!,
  edge_cycle,
  orientation, FaceOrientation, FACE_ORIENTATION_CLOCKWISE, FACE_ORIENTATION_COUNTERCLOCKWISE,
  nonorientable_faces, face_orientations,
  PrimitiveTopology,
  LinePrimitive, TrianglePrimitive,
  IndexEncoding,
  Strip, Fan, IndexList,
  TriangleStrip, TriangleFan, TriangleList,
  LineStrip, LineList,
  VertexMesh,
  Vertex, TriangleMesh,
  SubdivisionAlgorithm, UniformSubdivision,
  subdivide!, triangulate!,
  load_gltf,

  # camera
  PinholeCamera


end # module
