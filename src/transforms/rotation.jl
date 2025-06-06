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

"Quaternion, using an WXYZ convention (real part first, then pure part)."
struct Quaternion{T} <: Rotation{3,T}
  coords::SVector{4,T}
end

Base.getindex(q::Quaternion, i::Integer) = q.coords[i]
Base.iterate(q::Quaternion) = iterate(q.coords)
Base.iterate(q::Quaternion, state) = iterate(q.coords, state)
Base.length(q::Quaternion) = length(q.coords)

function Base.getproperty(q::Quaternion, name::Symbol)
  name === :w && return getfield(q, :coords)[1]
  name === :x && return getfield(q, :coords)[2]
  name === :y && return getfield(q, :coords)[3]
  name === :z && return getfield(q, :coords)[4]
  getfield(q, name)
end

function Base.isapprox(x::Quaternion, y::Quaternion; kwargs...)
  isapprox(x.w, y.w; kwargs...) || isapprox(x.w, -y.w; kwargs...) || return false
  Δx, Δy = x.coords, y.coords
  isapprox(@view(Δx[2:4]), @view(Δy[2:4]); kwargs...) || isapprox(@view(Δx[2:4]), -@view(Δy[2:4]); kwargs...)
end

Base.:(*)(q1::Quaternion, q2::Quaternion) = quaternion_from_rotor(@ga 3 SVector{4} begin
  q1 = q1.w::e + inverse_dual(q1.x::e1 + q1.y::e2 + q1.z::e3)
  q2 = q2.w::e + inverse_dual(q2.x::e1 + q2.y::e2 + q2.z::e3)
  (q1 ⟑ q2)::(0 + 2)
end)
Base.inv(q::Quaternion{T}) where {T} = quaternion_from_rotor(@ga 3 SVector{4,T} inverse(q.w::e + inverse_dual(q.x::e1 + q.y::e2 + q.z::e3))::(0 + 2))
Base.zero(::Type{T}) where {T<:Quaternion} = T() # XXX addition is not defined, technically
Base.one(::Type{T}) where {T<:Quaternion} = T()
Base.zero(q::Quaternion) = zero(typeof(q))
Base.one(q::Quaternion) = zero(typeof(q))

function Quaternion(coords::AbstractArray)
  length(coords) == 3 && return @invoke Quaternion(coords::Any)
  length(coords) == 4 || error("Expected 4 coordinates, got $(length(coords)) coordinates instead")
  Quaternion(SVector{4,eltype(coords)}(coords))
end
Quaternion{T}(q₀, q₁, q₂, q₃) where {T} = Quaternion(SVector{4,T}(q₀, q₁, q₂, q₃))
Quaternion(q₀, q₁, q₂, q₃) = Quaternion(SVector(q₀, q₁, q₂, q₃))
Quaternion(axis) = Quaternion(RotationPlane(normalize(axis)), norm(axis))
Quaternion{T}() where {T} = Quaternion{T}(one(T), zero(T), zero(T), zero(T))
Quaternion() = Quaternion{Float64}()

LinearAlgebra.norm(q::Quaternion) = norm(q.coords)
LinearAlgebra.normalize(q::Quaternion) = Quaternion(q.coords ./ norm(q))

rand(rng::AbstractRNG, ::SamplerType{Quaternion}) = rand(rng, Quaternion{Float64})
rand(rng::AbstractRNG, ::SamplerType{Quaternion{T}}) where {T} = normalize(Quaternion{T}(rand(rng, SVector{4,T})))

function Quaternion(plane::RotationPlane{3,T}, angle::Real) where {T}
  # Define rotation bivector which encodes a rotation in the given plane by the specified angle.
  ϕ = @ga 3 SVector{3} angle::0 ⟑ (plane.u::1 ∧ plane.v::1)
  # Define rotation generator to be applied to perform the operation.
  quaternion_from_rotor(@ga 3 SVector{4} exp((ϕ::2) / $(2one(T))::0)::(0 + 2))
end

function quaternion_from_rotor(rotor::SVector{4})
  scalar, bivector... = rotor
  pure_part = @ga 3 Tuple dual(bivector::2)::1
  Quaternion(scalar, pure_part...)
end

Quaternion(from::Point{3}, to::Point{3}) = Quaternion(promote(from, to)...)
function Quaternion(from::Point{3,T}, to::Point{3,T}) where {T}
  from, to = normalize(from), normalize(to)
  # Adding 1::e halves the angle of rotation, that would otherwise be `2 * angle(from, to)`.
  # We'll normalize afterwards just in case.
  q = quaternion_from_rotor(@ga 3 SVector{4} (from::1 ⟑ to::1 + 1::e)::(0 + 2))
  normalize(q)
end

# From https://d3cw3dd2w32x2b.cloudfront.net/wp-content/uploads/2015/01/matrix-to-quat.pdf.
function Quaternion(matrix::SMatrix{3, 3})
  q = if matrix[3, 3] < 0
    if matrix[1, 1] > matrix[2, 2]
      Quaternion(
        matrix[2, 3] - matrix[3, 2],
        1 + matrix[1, 1] - matrix[2, 2] - matrix[3, 3],
        matrix[1, 2] + matrix[2, 1],
        matrix[3, 1] + matrix[1, 3],
      )
    else
      Quaternion(
        matrix[3, 1] - matrix[1, 3],
        matrix[1, 2] + matrix[2, 1],
        1 - matrix[1, 1] + matrix[2, 2] - matrix[3, 3],
        matrix[2, 3] + matrix[3, 2],
      )
    end
  else
    if matrix[1, 1] < matrix[2, 2]
      Quaternion(
        matrix[1, 2] - matrix[2, 1],
        matrix[3, 1] + matrix[1, 3],
        matrix[2, 3] + matrix[3, 2],
        1 - matrix[1, 1] - matrix[2, 2] + matrix[3, 3],
      )
    else
      Quaternion(
        1 + matrix[1, 1] + matrix[2, 2] + matrix[3, 3],
        matrix[2, 3] - matrix[3, 2],
        matrix[3, 1] - matrix[1, 3],
        matrix[1, 2] - matrix[2, 1],
      )
    end
  end
  normalize(q)
end

# https://en.wikipedia.org/wiki/Quaternions_and_spatial_rotation
function SMatrix{3,3}(q::Quaternion)
  q₀, q₁, q₂, q₃ = normalize(q)
  @SMatrix [
    2(q₀^2 + q₁^2) - 1 2(q₁*q₂ - q₀*q₃) 2(q₁*q₃ + q₀*q₂);
    2(q₁*q₂ + q₀*q₃) 2(q₀^2 + q₂^2) - 1 2(q₂*q₃ - q₀*q₁);
    2(q₁*q₃ - q₀*q₂) 2(q₂*q₃ + q₀*q₁) 2(q₀^2 + q₃^2) - 1;
  ]
end

Rotation(axis) = Quaternion(axis)
Rotation(plane::RotationPlane{3}, angle::Real) = Quaternion(plane, angle)
Rotation(from::Point{3}, to::Point{3}) = Quaternion(from, to)
Rotation{3,T}() where {T} = Quaternion{T}()
Rotation{3}() = Quaternion()

function apply_rotation(p, q::Quaternion)
  length(p) == 3 || throw(ArgumentError("Expected 3-component vector in rotation by quaternion, got `$p` with length $(length(p))"))
  @ga 3 typeof(p) begin
    q = q.w::e + inverse_dual(q.x::e1 + q.y::e2 + q.z::e3)
    inverse(q) ⟑ p::1 ⟑ q
  end
end

Base.convert(::Type{Quaternion{T}}, q::Quaternion) where {T} = Quaternion(convert(SVector{4,T}, q.coords))
Base.convert(::Type{Rotation{3,T}}, q::Quaternion) where {T} = convert(Quaternion{T}, q)
