using GeometryExperiments
using GeometryExperiments: distance_squared
using GLMakie

function plot(; resolution = (800, 800), kwargs...)
  fig = Figure(; resolution, kwargs...)
  layout = fig[1, 1]
  axis = Axis(layout, aspect = 1)
  fig, layout, axis
end

function plot_projection!(axis, object, x; color = :green)
  x′ = projection(object, x)
  lines!(axis, Segment(x, x′); color)
  scatter!(axis, [x, x′]; color = [color, :red])
end

points = P2[(0.2, 0.4), (0.8, 0.9), (1, 0)]
segment = Segment(points[1:2]...)
patch = Patch{BezierCurve,3}(P2[(0, 0), (0.5, 1), (1, 0), (1.5, -1), (2, 0)])
x = P2(0.1231, 0.8432)

# Point projection on segment.
fig, layout, axis = plot()
xlims!(axis, 0, 1)
ylims!(axis, 0, 1)
lines!(axis, segment; color = :red)
plot_projection!(axis, segment, x)
fig

# Point projection on Bezier curves.
curve = BezierCurve(P2[(0.1, 0.1), (0.2, 0.3), (0.3, 0.35)])
fig, layout, axis = plot()
lines!(axis, curve)
scatter!(axis, curve; color = :green)
plot_projection!(axis, curve, P2(0, 0); color = :purple)
plot_projection!(axis, curve, P2(0.25, 0.25); color = :purple)
plot_projection!(axis, curve, P2(0.2, 0.2); color = :purple)
plot_projection!(axis, curve, P2(0.4, 0.3); color = :purple)
plot_projection!(axis, curve, P2(0.43, 0.15); color = :purple)
fig

# Point projection on Bezier patches.
fig, layout, axis = plot()
lines!(axis, patch)
scatter!(axis, patch; color = :green)
plot_projection!(axis, patch, P2(1.0, 1.0); color = :purple)
plot_projection!(axis, patch, P2(0.0, -1.0); color = :purple)
plot_projection!(axis, patch, P2(1.6, -0.3); color = :purple)
plot_projection!(axis, patch, P2(1.4, 0.3); color = :purple)
fig

# Curve-line intersections.
fig, layout, axis = plot()
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

# Curve-line intersections.
fig, layout, axis = plot()
xlims!(axis, 0, 1)
ylims!(axis, 0, 1)
patch = Patch{BezierCurve,3}(P2[(0.0, 0.0), (0.3, 0.45), (0.3, 0.6), (0.3, 0.7), (0.7, 0.7), (0.8, 0.1), (0.0, 0.0)])
line = Line(P2(0.3, 0.35), P2(0.39, 0.36))
lines!(axis, patch)
scatter!(axis, patch)
lines!(axis, line)
for p in intersect(line, patch)
  scatter!(axis, [p])
end
fig

### Point-projections on curves. Currently WIP.

ts = 0:0.01:1
xs = ys = 0:0.02:1

curve = BezierCurve(rand(P2, 3))
closest_distance = (p -> sqrt(distance_squared(curve, p)))
bench(t) = @elapsed closest_distance(t)

fig, layout, axis = plot()
# pl = heatmap!(axis, xs, ys, bench.(grid); colormap = :ocean)
pl = heatmap!(axis, xs, ys, closest_distance.(grid); colormap = :ocean)
# pl = contourf!(axis, xs, ys, closest_distance.(grid); colormap = :grays, levels = 30)
lines!(axis, curve; color = :red)
Colorbar(fig[1, 2], pl)
fig
