abstract type Primitive{T} end

struct NormedPrimitive{P,T} <: Primitive{T}
  radius::T
  NormedPrimitive{P}(radius::T) where {P,T} = new{P,T}(radius)
end

norm(p::Point, ::Type{<:NormedPrimitive{P}}) where {P} = norm(coordinates(p), P)

(np::NormedPrimitive)(p) = norm(p, typeof(np)) - np.radius

const HyperSphere{T} = NormedPrimitive{2,T}
const HyperCube{T} = NormedPrimitive{Inf,T}

"""
    Ellipsoid(semiaxes)

An ellipsoid with semi-axes `semiaxes`.
Is equivalent to a scaled [`HyperSphere`](@ref).
"""
const Ellipsoid{Dim,T} = Scaled{HyperSphere{T},Dim,T}
Ellipsoid(radius::T, transf::Scaling{Dim,T}) where {Dim,T} = Ellipsoid{Dim,T}(HyperSphere(radius), transf)

function Ellipsoid(semiaxes)
  n = norm(semiaxes)
  Ellipsoid(n, semiaxes ./ n)
end

Base.show(io::IO, elps::Ellipsoid{Dim,T}) where {Dim,T} = print(io, "Ellipsoid{$Dim, $T}($(elps.transf.vec .* elps.obj.radius))")

# A box around the origin. This is not the same as `Meshes.Box`, it is missing the translation part.
const Box{Dim,T} = Scaled{HyperCube{T},Dim,T}
Box(radius::T, transf::Scaling{Dim,T}) where {Dim,T} = Box{Dim,T}(HyperCube(radius), transf)

apply(t::Scaling, s::NormedPrimitive) = typeof(s)(norm(s, t.vec) * s.radius)
apply(t::Rotation, s::HyperSphere) = s
