using GeometryExperiments: compactify, decompactify

@testset "Curves" begin
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
    curve = BezierCurve(P2[(0, 0), (0.5, 1), (1, 0)])
    @test collect(project.(curve, curve.points)) == tuple.(0:0.5:1, curve.(0:0.5:1))
    patch = Patch{BezierCurve,3}(P2[(0, 0), (0.5, 1), (1, 0), (1.5, -1), (2, 0)])
    @test project(patch, P2(0, 0)) == (0, P2(0, 0))
  end
end;
