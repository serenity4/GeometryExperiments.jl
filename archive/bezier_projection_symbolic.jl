#=

This file is kept in the case that the approach to computing the projection from a point onto a quadratic Bezier curve is still relevant in the future, e.g. from a performance standpoint.

The approach is essentially as follows:
- Analytically construct the polynomial corresponding to the squared distance between a point and a point on the Bezier curve as a function of the curve parameter `t`. For simplicity, the point will be assumed to be the origin, numerically we'll just have to shift the Bezier control points. So this amounts to computing ||C(t)||². This polynomial will be a quartic for a quadratic Bezier curve, and a quintic for a cubic Bezier curve (and so on).
- We seek to find the global minimum of this polynomial. For that, analytically compute the derivative of this polynomial.
- Then, find the roots of this (now of one degree less, e.g. cubic) polynomial.
- Since we won't know which are global minima, evaluate the squared distance function at every root and at the endpoints, and return the parameter corresponding to the minimum.

Below are a few functions to get started.

It's probably best to abstract over the coefficients of the polynomial by grouping its terms in front of every successive power of `t` instead of messing with `x1`, `x2` etc all the way.

=#

# These functions are only for one coordinate at a time, and assuming the point to project is the origin.

function quadratic_bezier_norm(t, x1, x2, x3)
  x1^2 - 4t * x1^2 + 6t^2 * x1^2 - 4t^3 * x1^2 + t^4 * x1^2 + 4t * x1 * x2 - 12t^2 * x1 * x2 + 12t^3 * x1 * x2 - 4t^4 * x1 * x2 + 4t^2 * x2^2 -
  8t^3 * x2^2 + 4t^4 * x2^2 + 2t^2 * x1 * x3 - 4t^3 * x1 * x3 + 2t^4 * x1 * x3 + 4t^3 * x2 * x3 - 4t^4 * x2 * x3 + t^4 * x3^2
end

# XXX: do that for any quadratic polynomial, using its coefficients instead of this ugly monstruosity?
function quadratic_bezier_norm_derivative(t, x1, x2, x3)
  12t * (x1^2) + 4x1 * x2 + 4(t^3) * (x1^2 + x3^2) + 8t * (x2^2) + 16(t^3) * (x2^2) + 4t * x1 * x3 + 8x1 * x3 * (t^3) + 12x2 * x3 * (t^2) +
  36x1 * x2 * (t^2) - 4(x1^2) - 12(t^2) * (x1^2) - 24(t^2) * (x2^2) - 24t * x1 * x2 - 12x1 * x3 * (t^2) - 16x1 * x2 * (t^3) - 16x2 * x3 * (t^3)
end

#--

function squared_distance(curve::BezierCurve, t, p)
  ((x1, y1), (x2, y2), (x3, y3)) = curve.points .- Ref(p)
  quadratic_bezier_norm(t, x1, x2, x3) + quadratic_bezier_norm(t, y1, y2, y3)
end

function squared_distance_derivative(curve::BezierCurve, t, p)
  ((x1, y1), (x2, y2), (x3, y3)) = curve.points .- Ref(p)
  quadratic_bezier_norm_derivative(t, x1, x2, x3) + quadratic_bezier_norm_derivative(t, y1, y2, y3)
end

# Some plotting to make sure we get the correct polynomial.

using GLMakie

function plot(; resolution = (800, 800), kwargs...)
  fig = Figure(; resolution, kwargs...)
  layout = fig[1, 1]
  axis = Axis(layout, aspect = 1)
  fig, layout, axis
end

ts = 0:0.01:1
parametric_distance = (t -> GE.distance_squared(curve(t), p))

curve = BezierCurve(rand(P2, 3))
fig, layout, axis = plot()
lines!(axis, curve)
scatter!(axis, curve)
scatter!(axis, p; color = :red)
fig

p = rand(P2)
dist = t -> squared_distance(curve, t, p)
dist′ = t -> squared_distance_derivative(curve, t, p)
fig, layout, axis = plot()
lines!(axis, ts, parametric_distance.(ts))
lines!(axis, ts, dist.(ts); color = :red)
lines!(axis, ts, dist′.(ts); color = :green)
fig

# Have fun with symbolic manipulation if you like.
# These were used to generate the monstruosities above.

using Pkg

Pkg.activate(temp = true)
Pkg.add(["Symbolics", "SymPy"])

using Symbolics

@variables t x1 x2 x3

quartic =
  x1^2 - 4t * x1^2 + 6t^2 * x1^2 - 4t^3 * x1^2 + t^4 * x1^2 + 4t * x1 * x2 - 12t^2 * x1 * x2 + 12t^3 * x1 * x2 - 4t^4 * x1 * x2 + 4t^2 * x2^2 -
  8t^3 * x2^2 + 4t^4 * x2^2 + 2t^2 * x1 * x3 - 4t^3 * x1 * x3 + 2t^4 * x1 * x3 + 4t^3 * x2 * x3 - 4t^4 * x2 * x3 + t^4 * x3^2

cubic = simplify(expand_derivatives(Differential(t)(quartic)))

using SymPy

str = replace(string(cubic), r"(\d)(?=\w)" => s"\1*", r"(\d)\(" => s"\1*(")
ex = sympy.sympify(str)
sympy.simplify(ex)
ex = sympy.sympify("a*t^3 + b*t^2 + c*t + d")

sol = sympy.solve(ex)

for root in map(only ∘ values, sol)
  jex = eval(Meta.parse(sympy.julia_code(root)))
  println(jex)
  println()
end
