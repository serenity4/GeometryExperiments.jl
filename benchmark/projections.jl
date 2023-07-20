using GeometryExperiments
using GeometryExperiments: distance_squared
using BenchmarkTools

const P2 = Point2

curve = BezierCurve(rand(P2, 3))
distance(curve, p) = sqrt(distance_squared(curve, p))
closest_distance(p) = distance(curve, p)

# Benchamrking.
xs = ys = 0:0.02:1
grid = [P2(x, y) for x in xs, y in ys]
res = zeros(size(grid))
@btime $res .= $distance.($(Ref(curve)), $grid);

# Profiling.

function profile()
  curve = BezierCurve(rand(P2, 3))
  closest_distance(p) = distance(curve, p)

  # Benchamrking.
  xs = ys = 0:0.0005:1
  grid = [P2(x, y) for x in xs, y in ys]
  res = zeros(size(grid))
  @profview @time res .= closest_distance.(grid)
end

profile()
