using GeometryExperiments
using GLMakie

function plot_projection!(axis, object, x; color = :green)
  _, x′ = project(object, x)
  lines!(axis, Segment(x, x′); color)
  scatter!(axis, [x, x′]; color = [color, :red])
end

points = P2[(0.2, 0.4), (0.8, 0.9), (1, 0)]
segment = Segment(points[1:2]...)
patch = Patch{BezierCurve,3}(P2[(0, 0), (0.5, 1), (1, 0), (1.5, -1), (2, 0)])
x = P2(0.1231, 0.8432)

# Point projection on segment.
fig = Figure(resolution = (800, 800))
layout = fig[1, 1]
axis = Axis(layout)
xlims!(axis, 0, 1)
ylims!(axis, 0, 1)
lines!(axis, segment; color = :red)
plot_projection!(axis, segment, x)
fig

# Point projection on Bezier patches.
fig = Figure(resolution = (800, 800))
layout = fig[1, 1]
axis = Axis(layout)
lines!(axis, patch)
scatter!(axis, patch; color = :green)
plot_projection!(axis, patch, P2(1.0, 1.0); color = :purple)
plot_projection!(axis, patch, P2(0.0, -1.0); color = :purple)
plot_projection!(axis, patch, P2(1.6, -0.3); color = :purple)
plot_projection!(axis, patch, P2(1.4, 0.3); color = :purple)
fig

# Curve-line intersections.
fig = Figure(resolution = (800, 800))
layout = fig[1, 1]
axis = Axis(layout)
xlims!(axis, 0, 1)
ylims!(axis, 0, 1)
curve = BezierCurve(P2[(0.4, 0.7), (0.1, 0.6), (0.6, 0.3)])
lines!(axis, curve)
scatter!(axis, curve; color = :green)
line = Line(P2(0.3, 0), P2(0.5, 0.25))
lines!(axis, line; color = :red)
p = intersect(curve, line)::Point2
scatter!(axis, [p]; color = :red)
line = Line(P2(0, 0), P2(0.33, 0.6))
lines!(axis, line; color = :purple)
p = intersect(curve, line)::NTuple{2,Point2}
scatter!(axis, collect(p); color = :purple)
line = Line(P2(0, 0.5), P2(1, 0))
lines!(axis, line; color = :black)
p = intersect(curve, line)::Nothing
fig
