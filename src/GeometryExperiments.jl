module GeometryExperiments

using Meshes: Point, Vec, coordinates
using StaticArrays: SVector
using AbstractTrees
import LinearAlgebra: norm
import Base: in, inv, ≈

include("transforms.jl")
include("projection.jl")
include("primitives.jl")
include("intersections.jl")
include("coordinate_systems.jl")

export
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

    # coordinate systems
    CoordinateSystem,
    Cartesian


end # module
