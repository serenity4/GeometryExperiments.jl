abstract type Primitive{T} end

struct NormedPrimitive{N,T} <: Primitive{T}
  radius::T
  NormedPrimitive{N}(radius::T) where {N,T} = new{N,T}(radius)
end

norm(p::Point, ::Type{<:NormedPrimitive{N}}) where {N} = norm(coordinates(p), N)

(np::NormedPrimitive)(p) = norm(p, typeof(np)) - np.radius

const HyperSphere{T} = NormedPrimitive{2,T}
const HyperCube{T} = NormedPrimitive{Inf,T}

const Ellipsoid{Dim,T} = Scaled{HyperSphere{T},Dim,T}
Ellipsoid(radius::T, transf::Scaling{Dim,T}) where {Dim,T} = Ellipsoid{Dim,T}(HyperSphere(radius), transf)

# A box around the origin. This is not the same as `Meshes.Box`, it is missing the translation part.
const Box{Dim,T} = Scaled{HyperCube{T},Dim,T}
Box(radius::T, transf::Scaling{Dim,T}) where {Dim,T} = Box{Dim,T}(HyperCube(radius), transf)

can_apply(::Type{<:Scaling}, ::Type{<:NormedPrimitive}) = true
apply(t::Scaling, s::NormedPrimitive) = typeof(s)(norm(s, t.vec) * s.radius)

can_apply(::Type{<:Rotation}, ::Type{<:HyperSphere}) = true
apply(t::Rotation, s::HyperSphere) = s
