struct PointSet{Dim,T,V<:AbstractVector{Point{Dim,T}}}
  points::V
end

Base.IteratorEltype(::PointSet) = Base.HasEltype()
Base.eltype(set::PointSet{Dim,T}) where {Dim,T} = Point{Dim,T}
Base.length(set::PointSet) = length(set.points)
Base.iterate(set::PointSet) = iterate(set.points)
Base.iterate(set::PointSet, state) = iterate(set.points, state)
Base.keys(set::PointSet) = keys(set.points)
Base.:(==)(x::PointSet, y::PointSet) = x.points == y.points

(transf::Transformation)(set::PointSet) = PointSet(map(transf, set))

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

boundingelement(set::PointSet) = Box(compute_bounds(set.points)...)

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
