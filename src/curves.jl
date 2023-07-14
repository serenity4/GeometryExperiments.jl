abstract type Curve end

distance_squared(x::Point{Dim}, y::Point{Dim}) where {Dim} = sum((x .- y) .^ 2)
distance_squared(curve::Curve, p) = distance_squared(project(curve, p)[2], p)

Base.broadcastable(c::Curve) = Ref(c)

function project(line::Line, p::T) where {T<:Point{2}}
  vec = @pga2 (weight_left_complement(line::2) ∧ point(p)) ∨ line::2
  (zero(eltype(T)), T(euclidean(vec)))
end
