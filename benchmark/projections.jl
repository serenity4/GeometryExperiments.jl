using GeometryExperiments
using GeometryExperiments: distance_squared
using BenchmarkTools

curve = BezierCurve(rand(P2, 3))
closest_distance = (p -> sqrt(distance_squared(curve, p)))

# Benchamrking.
xs = ys = 0:0.02:1
grid = [P2(x, y) for x in xs, y in ys]
res = zeros(size(grid))
@btime $res .= $closest_distance.($grid);

# Profiling.
xs = ys = 0:0.0005:1
grid = [P2(x, y) for x in xs, y in ys]
res = zeros(size(grid))
@profview res .= closest_distance.(grid)
