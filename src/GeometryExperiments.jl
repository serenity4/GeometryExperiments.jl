module GeometryExperiments

using Meshes: Point, Vec
using StaticArrays: SVector
import LinearAlgebra: norm

include("transforms.jl")
include("primitives.jl")
include("coordinate_systems.jl")

export
    # transforms
    Transform, Transformed,
    Scaling, Scaled,
    Rotation, Rotated,
    Translation, Translated,
    ComposedTransform,
    can_apply, apply,

    # primitives
    NormedPrimitive,
    HyperSphere, HyperCube,
    Ellipsoid,
    Box,

    # coordinate systems
    CoordinateSystem,
    Cartesian


end # module
