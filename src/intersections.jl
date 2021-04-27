in(p::Point, obj::NormedPrimitive) = obj(p) ≤ 0
in(p::Point, tr::Transformed) = tr(p) ≤ 0
in(p::Point{N}, proj::Projection{N}) where {N} = p in proj.obj

function in(p::Point{Dim,T}, proj::Projection{N}) where {Dim,T,N}
    _p = coordinates(p)
    if Dim < N
        Point(SVector{N,T}(i <= Dim ? _p[i] : zero(T) for i in 1:N)) in proj
    else # Dim > N
        all(iszero, @view(_p[N+1:Dim])) && Point(@view(_p[1:N])) in proj
    end
end
