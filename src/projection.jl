"""
Projection of an object of type `O` onto the first `N` dimensions.
"""
struct Projection{N,O}
    obj::O
end

Projection{N}(obj::O) where {N,O} = Projection{N,O}(obj)

(proj::Projection{N})(p::Point{N}) where {N} = proj.obj(p)

function (proj::Projection{N})(p::Point{Dim,T}) where {N,Dim,T}
    _p = coordinates(p)
    if Dim < N
        pnew = Point(SVector{N,T}(i <= Dim ? _p[i] : zero(T) for i in 1:N))
        proj.obj(pnew)
    else # Dim > N
        pnew = Point(@views _p[N+1:Dim])
        obj = proj.obj
        if obj isa Transformed{<:NormedPrimitive}
            ptype = typeof(obj.obj)
            ptype(zero(T))(pnew)
        elseif obj isa NormedPrimitive
            ptype = typeof(obj)
            ptype(zero(T))(pnew)
        else
            proj.obj(pnew)
        end
    end
end
