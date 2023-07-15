function dimension_from_points(points...)
  ns = length.(points)
  allequal(ns) || error("All points must have the same length (got lengths $ns)")
  first(ns)
end

struct Line{Dim,T,D,N} <: AlgebraicEntity
  segment::Segment{Dim,T}
  data::Bivector{T,D,N}
end

Line{Dim}(segment, data::Bivector{T,D,N}) where {Dim,T,D,N} = Line{Dim,T,D,N}(segment, data)

function Line(A, B)
  d = dimension_from_points(A, B)
  segment = Segment(Point(A), Point(B))
  d == 2 && return Line{2}(segment, @pga2 point(A) ∧ point(B))
  d == 3 && return Line{3}(segment, @pga3 point(A) ∧ point(B))
  error("Only two and three-dimensional Euclidean spaces are supported")
end

function project(line::Line, p::T) where {T<:Point{2}}
  vec = @pga2 (weight_left_complement(line::2) ∧ point(p)) ∨ line::2
  (zero(eltype(T)), T(euclidean(vec)))
end

(line::Line)(t) = line.segment(t)
