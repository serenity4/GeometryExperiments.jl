using GeometryExperiments: compactify, decompactify

@testset "Curves" begin
  @testset "Segments" begin
    a = P2(0, 0)
    b = P2(1, 1)
    c = P2(0, 1)
    segment = Segment(a, b)
    @test segment(0.5) == a + (b - a) / 2
  end

  @testset "Bezier curves" begin
    T = Float64
    for method in (Horner(), FixedDegree(3))
      curve = BezierCurve(P2[(0, 0), (0.5, 1), (1, 0)], method)
      @test curve(T(0)) == P2(0, 0)
      @test curve(T(1)) == P2(1, 0)
      @test curve(T(0.5)) == P2(0.5, 0.5)
      @test curve(T(0.5)) == P2(0.5, 0.5)
    end
  end

  @testset "Patches" begin
    points = P2[(0, 0), (0.5, 1), (1, 0), (1.5, -1), (2, 0)]
    patch = Patch{BezierCurve,3}(points)
    @test length(patch) == 2
    @test patch[1] == BezierCurve(P2[(0, 0), (0.5, 1), (1, 0)])
    @test patch[2] == BezierCurve(P2[(1, 0), (1.5, -1), (2, 0)])
    @test collect(patch) == [patch[1], patch[2]]
    @test patch(0) == P2(0, 0)
    @test patch(0.125) ≠ P2(0.25, 0.25)
    @test patch(0.25) == P2(0.5, 0.5)
    @test patch(0.5) == P2(1, 0)
    @test patch(0.75) == P2(1.5, -0.5)
    @test patch(1) == P2(2, 0)
    @test compactify(patch) === patch
    @test decompactify(patch) == Patch{BezierCurve,3}(P2[(0, 0), (0.5, 1), (1, 0), (1, 0), (1.5, -1), (2, 0)]; compact = false)
    @test compactify(decompactify(patch)) == patch
    patch = Patch{BezierCurve,3}(rand(Point2, 13))
    @test compactify(decompactify(patch)) == patch
  end

  @testset "Projections" begin
    segment = Segment(P2(0, 0), P2(1, 1))
    @test projection(segment, P2(0, 1)) ≈ P2(0.5, 0.5)
    curve = BezierCurve(P2[(-0.1, 0), (0.5, 0.4), (1.1, 0)])
    @test projection(curve, curve.points[1]) ≈ curve(0)
    @test projection(curve, curve.points[2]) ≈ curve(0.5)
    @test projection(curve, curve.points[3]) ≈ curve(1)
    curve = BezierCurve(P2[(0.1, 0.1), (0.2, 0.3), (0.3, 0.35)])
    @test projection(curve, P2(0.43, 0.15)) isa P2
    patch = Patch{BezierCurve,3}(P2[(0, 0), (0.5, 1), (1, 0), (1.5, -1), (2, 0)])
    @test projection(patch, P2(0, 0)) ≈ P2(0, 0) atol = 1e-7
    @test projection(patch, P2(0, -1)) ≈ P2(0, 0) atol = 1e-7
    @test projection(patch, P2(1.4, 0.3)) ≈ P2(0.965, 0.067) atol = 0.001
    @test projection(patch, P2(2, 0.5)) ≈ P2(2, 0)
  end

  @testset "Intersections" begin
    curve = BezierCurve(P2[(0.4, 0.7), (0.1, 0.6), (0.6, 0.3)])
    line = Line(P2(0.3, 0), P2(0.5, 0.25))
    @test intersect(curve, line) isa Point2
    @test intersect(curve, line) ≈ intersect(curve, Line(line(1), line(0)))
    line = Line(P2(0, 0), P2(0.33, 0.6))
    @test intersect(curve, line) isa NTuple{2,Point2}
    line = Line(P2(0, 0.5), P2(1, 0))
    @test intersect(curve, line) isa Nothing
    patch = Patch{BezierCurve,3}(P2[(0.0, 0.0), (0.3, 0.45), (0.3, 0.6), (0.3, 0.7), (0.7, 0.7), (0.8, 0.1), (0.0, 0.0)])
    line = Line(P2(0.3, 0.35), P2(0.39, 0.36))
    @test length(intersect(patch, line)) == 2
    @test length(intersect(patch, -line)) == 2
  end
end;
