abstract type Curve end

distance_squared(x::Point{Dim}, y::Point{Dim}) where {Dim} = sum((x .- y) .^ 2)
distance_squared(curve::Curve, p) = distance_squared(project(curve, p)[2], p)

points(curve::Curve) = curve.points
endpoints(curve::Curve) = (points(curve)[begin], points(curve)[end])

Base.broadcastable(c::Curve) = Ref(c)
