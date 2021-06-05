struct PointSet{Dim,T,V<:AbstractVector{Point{Dim,T}}}
    points::V
end

function centroid(set::PointSet)
    points = set.points
    sum(points) / length(points)
end

function boundingelement(set::PointSet{Dim}) where {Dim}
    c = centroid(set)
    loc = Translation(c)
    # primitive = Translated(HyperCube(0.), loc)
    # dist, idx = findmin(map(primitive, set.points))
    coords = map(1:Dim) do i
        maximum(getindex.(set.points, i))
    end
    scale = Scaling(coords - c)
    Translated(Scaled(HyperCube(1.), scale), loc)
end
