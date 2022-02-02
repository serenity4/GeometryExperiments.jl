abstract type RotationType{T} end

"""
    Rotation(Quaternion(1., 0., 0., 0.))

Rotation around the origin implemented from a rotation type `R`.
`R` can be any kind of rotation which implements a method for
`rotate(x, r::R) where {R<:RotationType}`. In 3D, this can be
`Quaternion` or `Euler`, for example.
"""
struct Rotation{T,R<:RotationType{T}} <: Transform
  rot::R
end
(r::Rotation)(p::AbstractVector) = r.rot * p

Base.isapprox(x::Rotation, y::Rotation) = x.rot ≈ y.rot

Base.inv(r::Rotation) = typeof(r)(-r.rot)

const Rotated{O,R<:Rotation} = Transformed{O,R}
Rotated(obj::O, transf::R) where {O,R} = Rotated{O,R}(obj, transf)

struct Quaternion{T} <: RotationType{T}
  coords::SVector{4,T}
end

Quaternion(coords::AbstractArray) = Quaternion(SVector{length(coords),eltype(coords)}(coords))
Quaternion(coords::Vararg{T}) where {T} = Quaternion(SVector{length(coords),T}(coords))
