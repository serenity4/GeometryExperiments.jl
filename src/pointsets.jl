struct PointSet{Dim,T,V<:AbstractVector{Point{Dim,T}}}
  points::V
end

Base.length(set::PointSet) = length(set.points)
Base.iterate(set::PointSet) = iterate(set.points)
Base.iterate(set::PointSet, state) = iterate(set.points, state)
Base.:(==)(x::PointSet, y::PointSet) = x.points == y.points

(transf::Transform)(set::PointSet) = PointSet(map(transf, set))

centroid(p::Primitive) = origin(p)
centroid(tr::Transformed) = tr.transf(centroid(tr.obj))
centroid(set::PointSet) = sum(set) / length(set)
centroid(args...) = centroid(PointSet(args...))

# Faster version for generators.
function centroid(args::Base.Generator)
  n = 0
  res = nothing
  for arg in args
    n += 1
    isnothing(res) ? (res = arg) : (res += arg)
  end
  @assert !iszero(n)
  res / n
end

PointSet(points::T...) where {T<:Point} = PointSet(SVector{length(points),T}(collect(points)))
PointSet(points::Point...) = PointSet(promote(points...)...)
PointSet(points::V) where {Dim,T,V<:SVector{<:Any,Point{Dim,T}}} = PointSet{Dim,T,V}(points)

function boundingelement(set::PointSet{Dim,T}) where {Dim,T}
  min = zero(Point{Dim,T})
  max = zero(Point{Dim,T})
  for i in 1:Dim
    (mi, ma) = extrema(x -> getindex(x, i), set.points)
    min = setindex(min, mi, i)
    max = setindex(max, ma, i)
  end
  Box(min, max)
end

PointSet(box::Box{Dim,T}) where {Dim,T} = PointSet(sdf(box), Point{Dim,T})
@generated function PointSet(::Type{<:HyperCube}, P::Type{Point{Dim,T}}) where {Dim,T}
  idxs = CartesianIndices(ntuple(i -> -1:2:1, Dim))
  tuples = getproperty.(idxs, :I)
  :(PointSet(SVector{$(2^Dim),Point{$Dim,$T}}($(tuples...))))
end

PointSet(obj::HyperCube, P) = UniformScaling(radius(obj))(PointSet(typeof(obj), P))
PointSet(obj::Transformed, P) = obj.transf(PointSet(obj.obj, P))

function sort_nearest(set::PointSet, point, dist = HyperSphere(0.0))
  f = Translated(dist, Translation(point))
  dists = f.(set)
  indices = sortperm(dists)
  set.points[indices]
end

nearest(set::PointSet, point) = argmin(x -> distance_squared(x, point), set)

function Base.show(io::IO, set::PointSet{Dim,T}) where {Dim,T}
  print(io, "PointSet{$Dim,$T}(", join(set, ", "), ')')
end
