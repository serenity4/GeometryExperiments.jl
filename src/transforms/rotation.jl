abstract type Rotation{Dim,T} end

const Rotated{O,R<:Rotation} = Transformed{O,R}
Rotated(obj::O, transf::R) where {O,R} = Rotated{O,R}(obj, transf)

@struct_hash_equal_isapprox struct RotationPlane{Dim,T}
  u::Point{Dim,T}
  v::Point{Dim,T}
  RotationPlane{Dim,T}(u, v) where {Dim,T} = new(normalize(convert(Point{Dim,T}, u)), normalize(convert(Point{Dim,T}, v)))
end
RotationPlane(u::Point{Dim,T}, v::Point{Dim,T}) where {Dim,T} = RotationPlane{Dim,T}(u, v)
RotationPlane(u, v) = RotationPlane(Point(u), Point(v))

RotationPlane(coords::Real...) = RotationPlane(coords)
RotationPlane(normal) = RotationPlane(convert(Point{3}, normal))
function RotationPlane(normal::Point{3,T}) where {T}
  iszero(normal) && return RotationPlane((1, 0, 0), (0, 1, 0))
  u = @ga 3 Point{3,T} normal::Vector × 1f0::e1
  iszero(u) && (u = @ga 3 Point{3,T} dual(normal::Vector × 1f0::e2))
  v = @ga 3 Point{3,T} dual(normal::Vector × u::Vector)
  RotationPlane(u, v)
end

struct Quaternion{T} <: Rotation{3,T}
  coords::SVector{4,T}
end

Base.getindex(q::Quaternion, i::Integer) = q.coords[i]

Base.inv(q::Quaternion{T}) where {T} = Rotation(@ga 3 SVector{4,T} inverse(q::(0 + 2))::(0 + 2))
Base.zero(::Type{T}) where {T<:Quaternion} = T()
Base.one(::Type{T}) where {T<:Quaternion} = T()
Base.zero(q::Quaternion) = zero(typeof(q))
Base.one(q::Quaternion) = zero(typeof(q))

Quaternion(coords::AbstractArray) = Quaternion(SVector{length(coords),eltype(coords)}(coords))
Quaternion{T}(q₀, q₁, q₂, q₃) where {T} = Quaternion(SVector{4,T}(q₀, q₁, q₂, q₃))
Quaternion(q₀, q₁, q₂, q₃) = Quaternion(SVector(x, y, z, w))
Quaternion(axis) = Quaternion(RotationPlane(normalize(axis)), norm(axis))
Quaternion{T}() where {T} = Quaternion{T}(one(T), zero(T), zero(T), zero(T))
Quaternion() = Quaternion{Float64}()

function Quaternion(plane::RotationPlane{3,T}, angle::Real) where {T}
  # Define rotation bivector which encodes a rotation in the given plane by the specified angle.
  ϕ = @ga 3 SVector{3} angle::0 ⟑ (plane.u::1 ∧ plane.v::1)
  # Define rotation generator to be applied to perform the operation.
  q = @ga 3 SVector{4} exp((ϕ::2) / $(2one(T))::0)::(0 + 2)
  Quaternion(q)
end

Rotation(axis) = Quaternion(axis)
Rotation(plane::RotationPlane{3}, angle::Real) = Quaternion(plane, angle)
Rotation{3,T}() where {T} = Quaternion{T}()
Rotation{3}() = Quaternion()

function apply_rotation(p::Point{3}, q::Quaternion)
  @ga 3 SVector{3} begin
    q::(0 + 2)
    inverse(q) ⟑ p::1 ⟑ q
  end
end

Base.convert(::Type{Quaternion{T}}, q::Quaternion) where {T} = Quaternion(convert(SVector{4,T}, q.coords))
