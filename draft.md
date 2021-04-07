There is currently no handy way of working with geometry transforms such as rotation, translation and scaling. I'd like to present you [an approach](https://github.com/serenity4/GeometryExperiments.jl) to implement a clean and robust solution for Meshes.jl.

**Observations**

Some objects in Meshes.jl embed transform information in their data structures. This is, for example, the case with:
- `Plane`, `Sphere`, `Ball`, `Box`, `Line`, `Segment`, `Cylinder`, `Ray`: translation
- `Ellipsoid`: translation + rotation

Additionally, neighborhoods are defined with `Ellipsoid` and `NormBall`, which seem to be a way to define metrics from ellipsoids and balls. For partitions, `BallPartition` yet again defines a ball structure with a metric, with the exact same fields as `NormBall`.

To take the most obvious example, we see that there are multiple uses of a spherical/ball-like structure. `Sphere` describes a sphere in N-D space, `NormBall` and `BallPartition` describe a spherical metric, the difference between the latter two being for dispatch. Instead, I'd like to define a sphere-like object, and have the same type being passed around. `Sphere` is a translated sphere, `NormBall`/`BallPartition` use the implicit sphere representation ($x^2 + y^2 \leq R^2$ in two dimensions).

**The idea**

I'd like to unify the primitive, neighborhood, and other related types that depend on the same implicit representation, be it boxes or spheres, and introduce transforms along the way to build structures of geometrical importance. To give a few examples, the current `Meshes.Box` can be thought of a translated hypercube with an anisotropic scaling, an ellipsoid is defined as a scaled sphere, and `Meshes.Ellipsoid` (used for neighborhood searches) is a rotated ellipsoid.

It appears immediately that we can't use the current primitives to achieve this. The current `Meshes.Sphere` embeds a translation in its structure, and there is no hypercube primitive (only the box, which is the scaled and translated version). I think we can do better by defining geometries that do not depend on any position (i.e. implicitly defined around the "origin", though such origin is not of interest) nor rotation nor any transform of any kind, and build *views* of such primitives that correspond to their transformed versions.

**Primitives**

Let me introduce the following types:

```julia
import LinearAlgebra: norm

abstract type Primitive{T} end

struct NormedPrimitive{N,T} <: Primitive{T}
  radius::T
  NormedPrimitive{N}(radius::T) where {N,T} = new{N,T}(radius)
end

norm(A, ::Type{<:NormedPrimitive{N}}) where {N} = norm(A, N)

(np::NormedPrimitive)(p) = norm(p, np) - np.radius
```

We can build hyperspheres and hypercubes with special parametrizations of `NormedPrimitive`, setting the norm order `N`:

```julia
const HyperSphere{T} = NormedPrimitive{2,T}
const HyperCube{T} = NormedPrimitive{Inf,T}
```

Good. Those will be our building blocks that we will transform to generate more geometries. We now need to define transforms, which is originally what the proposal is about.

**Transforms**

I like to think of transforms as actions that can be applied to objects:

```julia
abstract type Transform{T} end

struct Transformed{O,TR<:Transform}
  obj::O
  transf::TR
end
```

We need to implement a few `Transform`s to actually do something. Let's implement the `Scaling` and `Translation` transforms:

```julia
using Meshes: Vec

struct Scaling{Dim,T} <: Transform{T}
  vec::Vec{Dim,T}
end
(s::Scaling)(p::Vec) = s.vec * p

struct Translation{Dim,T} <: Transform{T}
  vec::Vec{Dim,T}
end
(t::Translation)(p) = t.vec + p
```

The rotation transform is a bit more difficult, and does not have a clean generic expression using traditional linear algebra. Furthermore, there are many ways to implement rotations, so we'll parametrize on that:

```julia
abstract type RotationType{T} end

# for example, in 3D, we can use quaternions
struct Quaternion{T} <: RotationType{T}
  quat::SVector{4,T}
end

Base.:*(q::Quaternion, p) = ...

struct Rotation{T,R<:RotationType{T}} <: Transform{T}
  rot::R
end
(r::Rotation)(p) = r.rot * p

```

There, we have the three main transforms of interest in geometry processing: rotation, translation and scaling. Note that the scaling we defined is anisotropic, i.e. we can scale differently in each axis. To get a uniform scaling, you just need to have all scaling values be the same. A special type could be defined to avoid carrying duplicate data around, but we won't bother with it there.

We'll set up type aliases for convenience:

```julia
const Translated{O,Dim,T} = Transformed{O,Translation{Dim,T}}
const Scaled{O,Dim,T} = Transformed{O,Scaling{Dim,T}}
const Rotated{O,R<:RotationType} = Transformed{O,R}
```

With these in hand, it is possible to generate objects from our primitives:

```julia
const Ellipsoid{Dim,T} = Scaled{HyperSphere{T},Dim,T}
const Box{Dim,T} = Scaled{HyperCube{T},Dim,T}
```

Note that `Box` is not a translated type as it is for `Meshes.Box`. This one can be defined as

```julia
const Meshes.Box{Dim,T} = Translated{Box{Dim,T},Dim,T}
```

**Integration plans**

We can proceed in several ways:
- integrate transforms only, maybe rewrite primitives later: this is the less breaking, but requires additional work to interface with already transformed primitives (e.g. `Meshes.Sphere` which has a position field).
- integrate transforms and redefine primitives all in one go, potentially overloading `Base.getproperty` with a deprecation warning to minimize breaking changes on impacted structures: this is probably the wisest way to proceed while integrating all the functionality introduced by the proposal.
