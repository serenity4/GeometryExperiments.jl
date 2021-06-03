module GeometryExperiments

# using Meshes: Point, Vec, coordinates
using MLStyle
using StaticArrays: SVector
using AbstractTrees
import LinearAlgebra: norm
import Base: in, inv, ≈

include("utils.jl")
include("points.jl")
# include("transforms.jl")
# include("primitives.jl")
# include("intersections.jl")
# include("coordinate_systems.jl")

export
    # transforms
    Transform, Transformed,
    Scaling, Scaled,
    Rotation, Rotated,
    RotationType, Quaternion,
    Translation, Translated,
    ComposedTransform,
    transforms,

    # primitives
    Point,
    NormedPrimitive,
    HyperSphere, HyperCube,
    Ellipsoid,
    Box,

    # coordinate systems
    CoordinateSystem,
    Cartesian


end # module
