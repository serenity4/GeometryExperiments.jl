@testset "Curves" begin
  @testset "Bezier curves" begin
    T = Float64
    b = BezierCurve()
    points = P2[(0, 0), (0.5, 1), (1, 0)]
    @test b(T(0), points) == P2(0, 0)
    @test b(T(1), points) == P2(1, 0)
    @test b(T(0.5), points) == P2(0.5, 0.5)
    @test b(T(0.5), points) == P2(0.5, 0.5)
  end

  @testset "Patches" begin
    p = Patch(BezierCurve(), 3)
    points = P2[(0, 0), (0.5, 1), (1, 0), (1.5, -1), (2, 0)]
    @test p(0, points) == P2(0, 0)
    @test p(0.25, points) == P2(0.5, 0.5)
    @test p(0.5, points) == P2(1, 0)
    @test p(0.75, points) == P2(1.5, -0.5)
    @test p(1, points) == P2(2, 0)
    @test split(points, p) == [@view(points[1:3]), @view(points[3:5])]
    @test curve_points(p, points) == @view points[1:3]
    @test curve_points(p, points, 1) == @view points[3:5]
  end
end;
