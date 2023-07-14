using GeometryExperiments
using GLMakie

points = P2[(0.2, 0.4), (0.8, 0.9), (1, 0)]
segment = Segment(points[1:2]...)
x = P2(0.1231, 0.8432)

fig = Figure(resolution = (800, 800))
layout = fig[1, 1]
axis = Axis(layout)
xlims!(axis, 0, 1)
ylims!(axis, 0, 1)
lines!(axis, segment; color = :red)
_, x′ = project(segment, x)
scatter!(axis, [x, x′]; color = [:green, :red])
lines!(axis, Segment(x, x′); color = :green)
fig

patch = Patch{BezierCurve,3}(P2[(0, 0), (0.5, 1), (1, 0), (1.5, -1), (2, 0)])
fig = Figure(resolution = (800, 800))
layout = fig[1, 1]
axis = Axis(layout)
lines!(axis, patch)
scatter!(axis, patch; color = :green)
