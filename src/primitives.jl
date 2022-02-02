abstract type Primitive{T} end

struct NormedPrimitive{P,T} <: Primitive{T}
  radius::T
  NormedPrimitive{P,T}(radius::T) where {P,T} = new{P,T}(radius)
  NormedPrimitive{P}(radius::T) where {P,T} = NormedPrimitive{P,T}(radius)
end

Base.eltype(::NormedPrimitive{P,T}) where {P,T} = T
norm(p::Point, ::Type{<:NormedPrimitive{P}}) where {P} = norm(p, P)
origin(np::NormedPrimitive) = zero(eltype(np))
radius(tr::NormedPrimitive) = tr.radius
origin(tr::Transformed{<:NormedPrimitive}) = tr.transf(origin(tr.obj))
radius(tr::Transformed{<:NormedPrimitive}) = tr.transf(radius(tr.obj))

(np::NormedPrimitive)(p) = norm(p, typeof(np)) - np.radius

(≈)(x::NormedPrimitive, y::NormedPrimitive) = typeof(x) == typeof(y) && x.radius ≈ y.radius

const HyperSphere{T} = NormedPrimitive{2,T}

norm(p::Point, ::Type{<:HyperSphere}) = hypot(p...)

const HyperCube{T} = NormedPrimitive{Inf,T}

"""
    Ellipsoid(semiaxes)

An ellipsoid with semi-axes `semiaxes`.
Is equivalent to a scaled [`HyperSphere`](@ref).
"""
const Ellipsoid{Dim,T} = Scaled{HyperSphere{T},Dim,T}
Ellipsoid(radius::T, transf::Scaling{Dim,T}) where {Dim,T} = Ellipsoid{Dim,T}(HyperSphere(radius), transf)

function Ellipsoid(semiaxes::AbstractVector)
  radius = norm(semiaxes, HyperSphere)
  Ellipsoid(radius, Scaling(semiaxes ./ radius))
end
Ellipsoid(semiaxes::Number...) = Ellipsoid(collect(semiaxes))

(≈)(x::Ellipsoid, y::Ellipsoid) = x.obj.radius .* x.transf.vec ≈ y.obj.radius .* y.transf.vec

Base.show(io::IO, elps::Ellipsoid{Dim,T}) where {Dim,T} = print(io, "Ellipsoid{$Dim, $T}($(elps.transf.vec .* elps.obj.radius))")

# A box around the origin. This is not the same as `Meshes.Box`, it is missing the translation part.
const Box{Dim,T} = Scaled{HyperCube{T},Dim,T}
Box(radius::T, transf::Scaling{Dim,T}) where {Dim,T} = Box{Dim,T}(HyperCube(radius), transf)

const Circle{T} = Projection{2,HyperSphere{T}}
const Square{T} = Projection{2,HyperCube{T}}

struct BoxTransform{F,T} <: Transform
  from::F
  to::T
end

function (tr::BoxTransform)(p)
  ratio = Scaling(Translation(-origin(tr.to))(radius(tr.to))) ∘ inv(Scaling(Translation(-origin(tr.from))(radius(tr.from))))
  transf = Translation(origin(tr.to)) ∘ ratio ∘ Translation(-origin(tr.from))
  transf(p)
end
