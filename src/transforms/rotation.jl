abstract type RotationType{T} end

"""
    Rotation(Quaternion(1., 0., 0., 0.))

Rotation around the origin implemented from a rotation type `R`.
`R` can be any kind of rotation which implements a method for
`rotate(x, r::R) where {R<:RotationType}`. In 3D, this can be
`Quaternion` or `Euler`, for example.
"""
struct Rotation{T,R<:RotationType{T}} <: Transform{T}
  rot::R
end

Base.inv(r::Rotation) = typeof(r)(-r.rot)

const Rotated{O,R} = Transformed{O,R}

struct Quaternion{T} <: RotationType{T}
  coords::SVector{4,T}
end

Quaternion(coords::Vararg{T}) where {T} = Quaternion(SVector{length(coords),T}(coords))

rotate(x, q::Quaternion) = q * x # not implemented here
