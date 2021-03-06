Base.in(p, obj::NormedPrimitive) = obj(p) ≤ 0
Base.in(p, tr::Transformed) = tr(p) ≤ 0
Base.in(p::Point{N}, proj::Projection{N}) where {N} = p in proj.obj

function Base.in(p::Point{Dim,T}, proj::Projection{N}) where {Dim,T,N}
  if Dim < N
    Point{N,T}(i <= Dim ? p[i] : zero(T) for i in 1:N) in proj
  else # Dim > N
    all(iszero, @view(p[(N + 1):Dim])) && Point{N,T}(@view(p[1:N])) in proj
  end
end
