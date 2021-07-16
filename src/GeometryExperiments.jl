module GeometryExperiments

using StaticArrays: SVector
using AbstractTrees
import LinearAlgebra: norm
import Base: in, inv, ≈, ==

const Point{Dim,T} = SVector{Dim,T}

include("transforms.jl")
include("projection.jl")
include("primitives.jl")
include("intersections.jl")
include("pointsets.jl")
include("connectivity.jl")
include("coordinate_systems.jl")

include("curves.jl")
include("bezier.jl")

export

    Point,

    # transforms
    Transform, Transformed,
    Scaling, Scaled,
    Rotation, Rotated,
    RotationType, Quaternion,
    Translation, Translated,
    ComposedTransform,
    transforms,

    # projections
    Projection,

    # primitives
    NormedPrimitive,
    HyperSphere, HyperCube,
    Ellipsoid,
    Box,
    Circle, Square,

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
    curve_points


end # module
