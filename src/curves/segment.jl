struct Segment{Dim,T} <: Curve
  a::Point{Dim,T}
  b::Point{Dim,T}
end

Base.length(::Type{<:Segment}) = 2

function project(segment::Segment{2}, p::Point{2})
  _, p′ = project(Line(segment.a, segment.b), p)
  c = coordinate(segment, p′)
  c < 0 ? (0, segment.a) : c > 1 ? (1, segment.b) : (c, p′)
end

function coordinate(segment::Segment{2}, p::Point{2})
  (@ga 2 ((p::1 - segment.a::1) / (segment.b::1 - segment.a::1))::0)[]
end
