module GeometryExperiments

using StaticArrays: SVector, @SVector
using AbstractTrees
using AutoHashEquals
using Dictionaries
using LinearAlgebra

const Point{Dim,T} = SVector{Dim,T}
const Optional{T} = Union{T,Nothing}

for i in 2:4
  for T in (Float32, Float64)
    sym = Symbol(:Point, i, T === Float64 ? "" : 'f')
    @eval const $sym = Point{$i, $T}
    @eval export $sym
  end
end

include("utils.jl")

include("transforms.jl")
include("projection.jl")
include("primitives.jl")
include("intersections.jl")
include("pointsets.jl")
include("coordinate_systems.jl")

include("curves.jl")
include("bezier.jl")

include("granular_vector.jl")
include("mesh.jl")
include("mesh/attributes.jl")
include("mesh/diff.jl")
include("mesh/iteration.jl")
include("mesh/encodings.jl")
include("mesh/subdivide.jl")
include("mesh/triangulate.jl")

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
  sort_nearest,

  # coordinate systems
  CoordinateSystem,
  Cartesian,

  # curves
  Curve,
  BezierCurve,
  BezierEvalMethod,
  Horner,
  Patch,
  startindex,
  curve_points,

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
  PrimitiveTopology,
  LinePrimitive, TrianglePrimitive,
  IndexEncoding,
  Strip, Fan, IndexList,
  TriangleStrip, TriangleFan, TriangleList,
  LineStrip, LineList,
  VertexMesh,
  SubdivisionAlgorithm, UniformSubdivision,
  subdivide!, triangulate!


end # module
