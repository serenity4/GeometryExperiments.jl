abstract type Primitive{T} end

struct NormedPrimitive{P,T} <: Primitive{T}
  radius::T
  NormedPrimitive{P,T}(radius::T) where {P,T} = new{P,T}(radius)
  NormedPrimitive{P}(radius::T) where {P,T} = NormedPrimitive{P,T}(radius)
end

Base.eltype(::NormedPrimitive{P,T}) where {P,T} = T
LinearAlgebra.norm(p, ::Type{<:NormedPrimitive{P}}) where {P} = norm(p, P)
origin(np::NormedPrimitive) = zero(eltype(np))
radius(tr::NormedPrimitive) = tr.radius
origin(tr::Transformed{<:NormedPrimitive}) = tr.transf(origin(tr.obj))
radius(tr::Transformed{<:NormedPrimitive}) = tr.transf(radius(tr.obj)) - origin(tr)

(np::NormedPrimitive)(p) = norm(p, typeof(np)) - np.radius

Base.isapprox(x::NormedPrimitive, y::NormedPrimitive) = typeof(x) == typeof(y) && x.radius ≈ y.radius

"Hypersphere centered around the origin"
const HyperSphere{T} = NormedPrimitive{2,T}

LinearAlgebra.norm(p::Point, ::Type{<:HyperSphere}) = hypot(p...)

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

Base.isapprox(x::Ellipsoid, y::Ellipsoid) = x.obj.radius .* x.transf.vec ≈ y.obj.radius .* y.transf.vec

Base.show(io::IO, elps::Ellipsoid{Dim,T}) where {Dim,T} = print(io, "Ellipsoid{$Dim, $T}($(elps.transf.vec .* elps.obj.radius))")

@struct_hash_equal_isapprox struct Box{Dim,T} <: Primitive{T}
  min::Point{Dim,T}
  max::Point{Dim,T}
end

Box{Dim,T}(semidiag::Point) where {Dim,T} = Box{Dim,T}(-semidiag, semidiag)
Box{Dim,T}(semidiag) where {Dim,T} = Box{Dim,T}(Point{Dim,T}(semidiag))
Box(semidiag::Point{Dim,T}) where {Dim,T} = Box{Dim,T}(semidiag)

function Base.getproperty(box::Box{2}, name::Symbol)
  name === :width && return box.max[1] - box.min[1]
  name === :height && return box.max[2] - box.min[2]
  name === :bottom_left && return box.min
  name === :bottom_right && return Point(box.max[1], box.min[2])
  name === :top_left && return Point(box.min[1], box.max[2])
  name === :top_right && return box.max
  getfield(box, name)
end

Base.propertynames(box::Box{2}) = (:min, :max, :width, :height, :bottom_left, :bottom_right, :top_left, :top_right)

Base.convert(::Type{Box{Dim,T}}, box::Box{Dim,T}) where {Dim,T} = box
Base.convert(::Type{Box{Dim,T1}}, box::Box{Dim,T2}) where {Dim,T1,T2} = Box(convert(Point{Dim,T1}, box.min), convert(Point{Dim,T1}, box.max))

Base.:(-)(box::Box{Dim}, origin::Point{Dim}) where {Dim} = Box(box.min - origin, box.max - origin)
Base.:(+)(box::Box{Dim}, origin::Point{Dim}) where {Dim} = Box(box.min + origin, box.max + origin)

sdf(box::Box) = Translated(Scaled(HyperCube(1), Scaling(box.max - centroid(box))), Translation(centroid(box)))
centroid(box::Box) = (box.min + box.max) / 2

boundingelement(box::Box) = box
boundingelement(x::Box, y::Box) = boundingelement(PointSet(@SVector [x.min, x.max, y.min, y.max]))
function boundingelement(geometries)
  init, rest = Iterators.peel(geometries)
  foldl((x, y) -> boundingelement(x, boundingelement(y)), rest; init = boundingelement(init))
end

function compute_bounds(points::AbstractVector{P}) where {Dim,P<:Point{Dim}}
  min = zero(P)
  max = zero(P)
  for i in 1:Dim
    (mi, ma) = extrema(x -> getindex(x, i), points)
    min = setindex(min, mi, i)
    max = setindex(max, ma, i)
  end
  (min, max)
end

const Circle{T} = Projection{2,HyperSphere{T}}
const Square{T} = Projection{2,HyperCube{T}}

struct BoxTransform{F<:Box,T<:Box} <: Transformation
  from::F
  to::T
end

function (tr::BoxTransform)(p)
  c1, c2 = (centroid(tr.from), centroid(tr.to))
  ratio = Scaling((tr.to.max - c2)) ∘ inv(Scaling(tr.from.max - c1))
  transf = Translation(c2) ∘ ratio ∘ Translation(-c1)
  transf(p)
end
