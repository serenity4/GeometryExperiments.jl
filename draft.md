There is currently no handy way of working with geometry transforms such as rotation, translation and scaling. I'd like to present you [an approach](https://github.com/serenity4/GeometryExperiments.jl) that I find the most elegant to implement a clean and robust solution for Meshes.jl.

**Observations**

Some objects in Meshes.jl embed transform information in their data structures. This is, for example, the case with:
- `Plane`, `Sphere`, `Ball`, `Box`, `Line`, `Cylinder`, `Ray`: translation
- `Ellipsoid`: translation + rotation

Additionally, neighborhoods are defined with `Ellipsoid` and `NormBall`, which are basically just a way to define metrics from ellipsoids and balls ////

This could simplify a few things. For example, we have some primitive objects such as `Plane` and `Sphere` which embed a position vector in their structure. However, if one wants to exploit the geometry of a sphere or a plane, without using their position, this null position vector has to be specified and carried around in an unnatural way. Furthermore, this position vector assumes a coordinate system that may or may not exist, and which must be coherent between objects. I think we can do better by defining geometries that do not depend on any position (i.e. implicitly defined around the "origin", though such origin is not of interest) nor rotation nor any transform of any kind, and build *views* of such primitives that correspond to their transformed versions.

For example, ellipsoids and spheres could be redefined as
```julia
struct Ellipsoid{Dim,T} <: Primitive{Dim,T}
    # corresponds to a non-uniform scaling of a sphere
    radii::SVector{Dim,T}
end

# note the superfluous Dim parameter. Maybe we should remove Dim for the Primitive type?
struct Sphere{Dim,T} <: Primitive{Dim,T}
    radius::T
end
```

Even there, we could just note that an ellipsoid is just a (non-uniformly) scaled version of a sphere, and so

```julia
ellipsoid(radii) = Scaled(Sphere(one(eltype(radii))), radii)
```

We could obtain the current `Box` type by a similar argument involving a scaling and a translation from a generic `HyperCube` (that is, a cube in any dimension, cf [Wikipedia](https://en.wikipedia.org/wiki/Hypercube)).
This `Scaled` would be just a view of the 

**Integration plans**

We can proceed in several ways:
- integrate transforms only, maybe rewrite primitives later: this is the less breaking, but requires additional work to interface with already transformed primitives (e.g. `Meshes.Sphere` which has a position field.)
- integrate transforms and redefine primitives all in one go, but with type aliases and overloading `Base.getproperty` with a deprecation warning to minimize breaking changes: this is probably the wisest way to proceed while integrating all the functionality introduced by the proposal.
