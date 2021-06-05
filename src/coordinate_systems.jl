abstract type CoordinateSystem end

(tr::Transformed{<:CoordinateSystem})(p) = tr.obj(tr.transf(p))

struct Cartesian <: CoordinateSystem end

(c::Cartesian)(p) = p
