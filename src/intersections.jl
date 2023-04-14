function dimension_from_points(points...)
  ns = length.(points)
  allequal(ns) || error("All points must have the same length (got lengths $ns)")
  first(ns)
end

struct Line{D,T,N} <: AlgebraicEntity
  data::Bivector{T,D,N}
end

function Line(A, B)
  d = dimension_from_points(A, B)
  d == 2 && return Line(@pga2 point(A) ∧ point(B))
  d == 3 && return Line(@pga3 point(A) ∧ point(B))
  error("Only two and three-dimensional Euclidean spaces are supported")
end

Base.intersect(l1::Line{3}, l2::Line{3}) = @pga2 l1::Bivector ∨ l2::Bivector

struct Plane{D,T,N} <: AlgebraicEntity
  data::Trivector{T,D,N}
end

function Plane(A, B, C)
  d = dimension_from_points(A, B, C)
  d == 2 && return Plane(@pga2 point(A) ∧ point(B) ∧ point(C))
  d == 3 && return Plane(@pga3 point(A) ∧ point(B) ∧ point(C))
  error("Only two and three-dimensional Euclidean spaces are supported")
end

using Combinatorics: permutations

binary_combinations(x) = [collect(permutations(x, 2)); [[obj, obj] for obj in x]]

for ((T1, ST1), (T2, ST2)) in binary_combinations([:Line => :Bivector, :Plane => :Trivector])
  @eval Base.intersect(x::$T1{4}, y::$T2{4}) = @pga3 x::$ST1 ∨ y::$ST2
end

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
