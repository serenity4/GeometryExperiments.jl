abstract type Transformation end

Base.broadcastable(tr::Transformation) = Ref(tr)

struct ComposedTransform{TR1<:Transformation,TR2<:Transformation} <: Transformation
  """
  Outer transform.
  """
  t1::TR1
  """
  Inner transform.
  """
  t2::TR2
end
(t::ComposedTransform)(p::Union{Number,AbstractVector}) = t.t1(t.t2(p))

AbstractTrees.children(tr::ComposedTransform) = (tr.t1, tr.t2)

transforms(tr::ComposedTransform) = Leaves(tr)

Base.:(∘)(t1::Transformation, t2::Transformation) = ComposedTransform(t1, t2)

Base.inv(t::ComposedTransform) = inv(t.t2) ∘ inv(t.t1)

struct Transformed{O,TR<:Transformation}
  obj::O
  transf::TR
  Transformed{O,TR}(obj::O, args...) where {O,TR<:Transformation} = Transformed{O,TR}(obj, TR(args...))
  Transformed{O,TR}(obj::O, transf::TR) where {O,TR<:Transformation} = new{O,TR}(obj, transf)
  Transformed{TR1,TR2}(obj::TR1, transf::TR2) where {TR1<:Transformed,TR2<:Transformation} = Transformed(obj.obj, transf ∘ obj.transf)
  Transformed(obj::O, transf::TR) where {O,TR<:Transformation} = Transformed{O,TR}(obj, transf)
end
(tr::Transformed)(p) = tr.obj(inv(tr.transf)(p))

Base.isapprox(x::Transformed, y::Transformed) = typeof(x) == typeof(y) && x.obj ≈ y.obj && x.transf ≈ y.transf

include("transforms/scaling.jl")
include("transforms/translation.jl")
include("transforms/rotation.jl")

"""
Linear transformation in Euclidean space.

A `Transform` encodes a linear operation obtained by scaling, rotating and translating an object,
in this particular order. Scaling and rotation are defined around the origin; rotation around another object
must be encoded as a rotation first and then a translation.

To apply the transform to a point, use `apply_transform(p, transform)`
To apply the inverse of this transform to a point, use `apply_transform_inverse(p, transform)`.
"""
@struct_hash_equal_isapprox struct Transform{Dim,T,R<:Rotation{Dim,T}}
  translation::Translation{Dim,T}
  rotation::R
  scaling::Scaling{Dim,T}
end

Transform{3,T}(; translation = zero(Translation{3,T}), rotation = zero(Quaternion{T}), scaling = one(Scaling{3,T})) where {T} = Transform{3,T,typeof(rotation)}(translation, rotation, scaling)
Transform{3}(; kwargs...) = Transform{3,Float64}(; kwargs...)
Transform(; kwargs...) = Transform{3}(; kwargs...)

function apply_transform(p::Point{Dim}, (; translation, rotation, scaling)::Transform{Dim}) where {Dim}
  pₛ = apply_scaling(p, scaling)
  pᵣ = apply_rotation(pₛ, rotation)
  pₜ = apply_translation(pᵣ, translation)
  pₜ
end

apply_transform(p, tr::Transform{Dim,T}) where {Dim,T} = apply_transform(convert(Point{Dim,T}, p), tr)
apply_transform_inverse(p, tr::Transform{Dim,T}) where {Dim,T} = apply_transform_inverse(convert(Point{Dim,T}, p), tr)

function apply_transform_inverse(p::Point{Dim}, (; translation, rotation, scaling)::Transform{Dim}) where {Dim}
  pₜ = apply_translation(p, inv(translation))
  pᵣ = apply_rotation(pₜ, inv(rotation))
  pₛ = apply_scaling(pᵣ, inv(scaling))
  pₛ
end

function Base.convert(::Type{Transform{Dim,T,R}}, tr::Transform{Dim}) where {Dim,T,R<:Rotation{Dim,T}}
  Transform(convert(Translation{Dim,T}, tr.translation), convert(R, tr.rotation), convert(Scaling{Dim,T}, tr.scaling))
end
