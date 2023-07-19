abstract type Curve end

distance_squared(x::Point{Dim}, y::Point{Dim}) where {Dim} = sum((x .- y) .^ 2)
distance_squared(curve::Curve, p) = distance_squared(projection(curve, p), p)

points(curve::Curve) = curve.points
endpoints(curve::Curve) = (points(curve)[begin], points(curve)[end])

Base.broadcastable(c::Curve) = Ref(c)

"""
    projection(object, x) -> x′

Project `x` onto `object`, and return the resulting point `x′`.
"""
projection(object, x) = object(projection_parameter(object, x))

"""
    projection_parameter(parametric, x) -> t

Project `x` onto `parametric`, and return the corresponding value `t` in `parametric`'s parameter space.
"""
function projection_parameter end
