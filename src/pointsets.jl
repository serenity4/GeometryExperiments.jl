struct PointSet{Dim,T,V<:AbstractVector{Point{Dim,T}}}
  points::V
end

Base.length(set::PointSet) = length(set.points)
Base.iterate(set::PointSet) = iterate(set.points)
Base.iterate(set::PointSet, state) = iterate(set.points, state)
Base.:(==)(x::PointSet, y::PointSet) = x.points == y.points

(transf::Transform)(set::PointSet) = PointSet(map(transf, set))

centroid(set::PointSet) = sum(set) / length(set)

function boundingelement(set::PointSet{Dim}) where {Dim}
  c = centroid(set)
  coords = map(1:Dim) do i
    maximum(getindex.(set, i))
  end
  scale = Scaling(coords - c)
  Translated(Scaled(HyperCube(1.0), scale), Translation(c))
end

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

function Base.show(io::IO, set::PointSet{Dim,T}) where {Dim,T}
  print(io, "PointSet{$Dim,$T}(", join(set, ", "), ')')
end
