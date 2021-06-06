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
include("coordinate_systems.jl")

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

    # coordinate systems
    CoordinateSystem,
    Cartesian


end # module
