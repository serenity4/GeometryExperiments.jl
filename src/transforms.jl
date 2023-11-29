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
@struct_hash_equal struct Transform{Dim,T,R<:Rotation{Dim,T}}
  translation::Translation{Dim,T}
  rotation::R
  scaling::Scaling{Dim,T}
end

Base.isapprox(x::Transform, y::Transform) = isapprox(x.translation, y.translation) && isapprox(x.rotation, y.rotation) && isapprox(x.scaling, y.scaling)

Transform{3,T}(; translation = zero(Translation{3,T}), rotation = zero(Quaternion{T}), scaling = one(Scaling{3,T})) where {T} = Transform{3,T,typeof(rotation)}(translation, rotation, scaling)
Transform{3}(; kwargs...) = Transform{3,Float64}(; kwargs...)
Transform(; kwargs...) = Transform{3}(; kwargs...)

Transform(matrix::SMatrix{4,4}) = Transform{3}(matrix)
Transform{3}(matrix::SMatrix{4,4,T}) where {T} = Transform{3,T}(matrix)

function Transform{3,T}(matrix::SMatrix{4,4}) where {T}
  one_to_three = @SVector [1, 2, 3]
  translation = Translation(matrix[one_to_three, 4])
  rotation, scaling = extract_rotation_and_scale(matrix)
  Transform{3,T,Quaternion{T}}(translation, rotation, scaling)
end

# Uses the polar decomposition technique (https://en.wikipedia.org/wiki/Polar_decomposition)
# Adapted from https://callumhay.blogspot.com/2010/10/decomposing-affine-transforms.html
function extract_rotation_and_scale(matrix::SMatrix{4,4})
  T = eltype(matrix)
  matrix_without_translation = MMatrix(matrix)
  matrix_without_translation[@SVector([1, 2, 3]), 4] .= 0
  rotation = SMatrix(matrix_without_translation)
  for i in 1:100
    prev = rotation
    rotation = 0.5one(T) * (rotation + inv(transpose(rotation)))
    norm(rotation - prev) < 2eps(T) && break
  end

  to_3x3(mat) = mat[@SVector([1, 2, 3]), @SVector([1, 2, 3])]

  # Extract scaling while taking into account any reflections.

  ## Scale is just the diagonal of the matrix without the rotation.
  scale_matrix = rotation \ matrix_without_translation
  scale = diag(to_3x3(scale_matrix))

  ## Now figure out whether the orthogonal transformation is proper (i.e. even number of reflections)
  ## or improper (odd number of reflection).
  i, j, k = ntuple(i -> normalize(matrix_without_translation[@SVector([1, 2, 3]), i]), 3)
  normed_3x3 = @SMatrix [
    i[1] j[1] k[1];
    i[2] j[2] k[2];
    i[3] j[3] k[3];
  ]

  ## If improper, we'll have to encode that in the scaling.
  if det(normed_3x3) < zero(T)
    # Negate an arbitrary component to make an odd number of reflections.
    scale = setindex(scale, -scale.x, 1)
  end

  Quaternion(to_3x3(rotation)), Scaling(scale)
end

function SMatrix{4,4}(tr::Transform{3,T}) where {T}
  translation = tr.translation.vec
  R = SMatrix{3,3}(tr.rotation) * diagm(tr.scaling.vec)

  @SMatrix T[
    R[1, 1] R[1, 2] R[1, 3] translation[1];
    R[2, 1] R[2, 2] R[2, 3] translation[2];
    R[3, 1] R[3, 2] R[3, 3] translation[3];
    zero(T) zero(T) zero(T) one(T);
  ]
end

rand(rng::AbstractRNG, ::SamplerType{Transform{Dim}}) where {Dim} = rand(rng, Transform{Dim,Float64})
rand(rng::AbstractRNG, ::SamplerType{Transform{Dim,T}}) where {Dim,T} = rand(rng, Transform{Dim,Float64,Quaternion{T}})
rand(rng::AbstractRNG, ::SamplerType{Transform{Dim,T,R}}) where {Dim,T,R} = Transform(rand(rng, Translation{Dim,T}), rand(rng, R), rand(rng, Scaling{Dim,T}))

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
