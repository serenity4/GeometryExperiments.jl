abstract type CoordinateSystem{T} end

(tr::Transformed{<:CoordinateSystem})(p) = tr.obj(tr.transf(p))

struct Cartesian{T} <: CoordinateSystem{T} end

(c::Cartesian)(p) = p
