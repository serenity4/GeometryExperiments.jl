There is currently no handy way of working with geometry transforms such as rotation, translation and scaling. I'd like to present an approach to implement composable transforms for Meshes.jl. Geometric primitives are redesigned in the process, as many of them are naturally expressed in terms of transforms of other primitives. Code implementing these ideas can be found on [this repo](https://github.com/serenity4/GeometryExperiments.jl).

**Context**

Some objects in Meshes.jl embed transform information in their data structures. Notably, the origin of many objects are included in their types, providing information about a translation transform. Types include `Plane`, `Sphere`, `Ball`, `Box`, `Line`, `Segment`, `Cylinder`, and `Ray`.

Neighborhoods are defined with `Ellipsoid` and `NormBall`, two types that encode metrics attached to ellipsoids and balls. For partitions, `BallPartition` yet again defines a ball structure with a metric, with the exact same fields as `NormBall`. We see that there are multiple uses of a spherical/ball-like structure. `Sphere` describes a sphere in N-D space, `NormBall` and `BallPartition` describe a spherical metric (the difference between the latter two being for dispatch). Instead, I'd like to define a sphere-like object, and have the same type being passed around. `Sphere` is a translated sphere, `NormBall`/`BallPartition` use the implicit sphere representation ($x^2 + y^2 \leq R^2$ in two dimensions) with a particular metric.

**The idea**

I'd like to have primitives that are reusable, decoupling their implicit representation (be it boxes or spheres) from transform data. These primitives could then be used to build other primitives, using transforms. To give a few examples, the current `Meshes.Box` is a scaled and translated hypercube, an ellipsoid is a scaled hypersphere, and `Meshes.Ellipsoid` (used for neighborhood searches) is a rotated ellipsoid. I'd like to remove the transform (rotation/translation/scaling) data from these structures.

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

Those will be our building blocks that we will transform to generate more geometries. We now need to define transforms, which is originally what the proposal is about.

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
(s::Scaling)(p) = s.vec * p

# would be handy to have that in Meshes.jl
Base.:*(x::Vec{Dim,T}, y::Point{Dim,T}) where {Dim,T} = typeof(y)(x .* coordinates(y))

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

Note that `Box` is not a translated type like `Meshes.Box`. The latter could be defined as

```julia
const Meshes.Box{Dim,T} = Translated{Box{Dim,T},Dim,T}
```

**Operations on transforms**

<!-- TODO -->

**Summary**

The proposal is about:
- add transforms.
- redefine current primitives taking advantage of transforms.

Pros:
- Primitives:
  - are more lightweight.
  - are more composable: that is consequence of their lightweightness. You don't need to redefine e.g. a ball type for a neighborhood search, you can use the `HyperSphere` primitive directly.
- Transforms:
  - are composable.
  - are explicit (no hidden transform within objects).
  - may be merged arbitrarily: that needs yet to be implemented. You may explicitly use matrices to compose transforms in theory, however it is not straightforward. To include scaling you would need to work with homogeneous coordinates ((n+1) x (n+1) matrices in n-D). Geometric algebra can help with a more sparse representation (its transform objects are smaller than dense matrices), but no Julia library currently exist that is production ready.

Cons:
- Increased verbosity for some uses. For example, `Meshes.Box` must explicitly be a `Translated{Box}`. Type aliases may help if, for some primitives, their transformed version is often used.
- Other? (please let me know)

Areas of improvements (for further study, if/once this proposal is implemented):
- Allow norms that are not p-norms for `NormedPrimitive` primitives.
- Allow merge of transforms (cf above).
- Reuse primitive types in other parts of Meshes.jl (thinking of neighborhoods, which may need a refactor).

**Integration plans**

We can proceed in several ways:
- add transforms only, maybe rewrite primitives later: this is probably the less breaking, but requires additional work to interface with already transformed primitives (e.g. `Meshes.Sphere` which has a position field, `Meshes.Box` etc).
- add transforms and redefine primitives all in one go: this is the easiest to implement, if we don't care about breaking a lot of things at once it's perfect. Otherwise we may introduce deprecations warnings, but since we're not 1.0 yet maybe we shouldn't bother with those, just make a detailed changelog to help the transition.