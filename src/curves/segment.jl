struct Segment{Dim,T} <: Curve
  a::Point{Dim,T}
  b::Point{Dim,T}
end

Base.length(::Type{<:Segment}) = 2

function projection_parameter(segment::Segment{2}, p::Point{2})
  p′ = projection(Line(segment.a, segment.b), p)
  clamp(coordinate(segment, p′), 0, 1)
end

function coordinate(segment::Segment{2}, p::Point{2})
  segment.a ≈ segment.b && return 0.5one(eltype(p))
  @ga 2 eltype(p) ((p::1 - segment.a::1) / (segment.b::1 - segment.a::1))::0
end

(segment::Segment)(t) = lerp(segment.a, segment.b, t)
