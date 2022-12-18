macro pga2(args...)
  definitions = quote
    embed(x) = x[1]::e1 + x[2]::e2
    magnitude2(x) = x ⦿ x
    point(x) = embed(x) + 1.0::e3
  end
  varinfo = parse_variable_info(definitions; warn_override = false)
  esc(codegen_expression((2, 0, 1), args...; varinfo))
end

macro pga3(args...)
  definitions = quote
    embed(x) = x[1]::e1 + x[2]::e2 + x[3]::e3
    magnitude2(x) = x ⦿ x
    point(x) = embed(x) + 1.0::e4
  end
  varinfo = parse_variable_info(definitions; warn_override = false)
  esc(codegen_expression((3, 0, 1), args...; varinfo))
end

euclidean(kvec::KVector{1,<:Any,D}) where {D} = kvec[begin:(end - 1)] ./ kvec[end]

abstract type AlgebraicEntity end

SymbolicGA.getcomponent(entity::AlgebraicEntity, i) = SymbolicGA.getcomponent(entity.data, i)
SymbolicGA.getcomponent(entity::AlgebraicEntity) = SymbolicGA.getcomponent(entity.data)

function dimension_from_points(points...)
  ns = length.(points)
  allequal(ns) || error("All points must have the same length (got lengths $ns)")
  first(ns)
end

struct Line{D,T,N} <: AlgebraicEntity
  data::KVector{2,T,D,N}
end

function Line(A, B)
  d = dimension_from_points(A, B)
  d == 2 && return Line(@pga2 point(A) ∧ point(B))
  d == 3 && return Line(@pga3 point(A) ∧ point(B))
  error("Only two and three-dimensional Euclidean spaces are supported")
end

Base.intersect(l1::Line{3}, l2::Line{3}) = @pga2 l1::Bivector ∨ l2::Bivector
Base.intersect(l1::Line{4}, l2::Line{4}) = @pga3 l1::Bivector ∨ l2::Bivector

struct Plane{D,T,N} <: AlgebraicEntity
  data::KVector{3,T,D,N}
end

function Plane(A, B, C)
  d = dimension_from_points(A, B, C)
  d == 2 && return Plane(@pga2 point(A) ∧ point(B) ∧ point(C))
  d == 3 && return Plane(@pga3 point(A) ∧ point(B) ∧ point(C))
  error("Only two and three-dimensional Euclidean spaces are supported")
end

Base.intersect(l::Line{4}, p::Plane{4}) = @pga3 l::Bivector ∨ p::Trivector
Base.intersect(p::Plane{4}, l::Line{4}) = @pga3 p::Trivector ∨ l::Bivector

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
