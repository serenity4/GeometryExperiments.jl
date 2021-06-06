struct PointSet{Dim,T,V<:AbstractVector{Point{Dim,T}}}
    points::V
end

(==)(x::PointSet, y::PointSet) = x.points == y.points

function centroid(set::PointSet)
    points = set.points
    sum(points) / length(points)
end

function boundingelement(set::PointSet{Dim}) where {Dim}
    c = centroid(set)
    coords = map(1:Dim) do i
        maximum(getindex.(set.points, i))
    end
    scale = Scaling(coords - c)
    Translated(Scaled(HyperCube(1.), scale), Translation(c))
end

@generated function PointSet(obj::Type{HyperCube}, P::Type{Point{Dim,T}}) where {Dim,T}
    idxs = CartesianIndices(ntuple(i -> -1:2:1, Dim))
    tuples = getproperty.(idxs, :I)
    :(PointSet(SVector{$(2^Dim),Point{$Dim,$T}}($(tuples...))))
end

PointSet(obj::HyperCube, P) = PointSet(typeof(obj), P)

function PointSet(transf::Transformed{HyperCube,<:Transform{T}}, ::Val{Dim}) where {Dim,T}
    set = PointSet(HyperCube, Point{Dim,T})
    Transformed(set, transf.transf)
end
