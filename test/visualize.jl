using GeometryExperiments
using GLMakie

function plot_intersection!(axis, object, x; color = :green)
  _, x′ = project(object, x)
  lines!(axis, Segment(x, x′); color)
  scatter!(axis, [x, x′]; color = [color, :red])
end

points = P2[(0.2, 0.4), (0.8, 0.9), (1, 0)]
segment = Segment(points[1:2]...)
patch = Patch{BezierCurve,3}(P2[(0, 0), (0.5, 1), (1, 0), (1.5, -1), (2, 0)])
x = P2(0.1231, 0.8432)

fig = Figure(resolution = (800, 800))
layout = fig[1, 1]
axis = Axis(layout)
xlims!(axis, 0, 1)
ylims!(axis, 0, 1)
lines!(axis, segment; color = :red)
plot_intersection!(axis, segment, x)
fig

fig = Figure(resolution = (800, 800))
layout = fig[1, 1]
axis = Axis(layout)
lines!(axis, patch)
scatter!(axis, patch; color = :green)
plot_intersection!(axis, patch, P2(1.0, 1.0); color = :purple)
plot_intersection!(axis, patch, P2(0.0, -1.0); color = :purple)
plot_intersection!(axis, patch, P2(1.6, -0.3); color = :purple)
plot_intersection!(axis, patch, P2(1.4, 0.3); color = :purple)
fig
