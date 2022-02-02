module GeometryExperiments

using StaticArrays: SVector, @SVector
using AbstractTrees
import LinearAlgebra: norm
import Base: in, inv, ≈, ==
using AutoHashEquals

const Point{Dim,T} = SVector{Dim,T}

include("transforms.jl")
include("projection.jl")
include("primitives.jl")
include("intersections.jl")
include("pointsets.jl")
include("coordinate_systems.jl")

include("curves.jl")
include("bezier.jl")

include("mesh_encodings.jl")

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
    Box,
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

    # mesh encodings
    TopologyClass,
    Line, Triangle,
    IndexEncoding,
    Strip, Fan, IndexList,
    TriangleStrip, TriangleFan, TriangleList,
    LineStrip, LineList,
    MeshEncoding, MeshVertexEncoding


end # module
