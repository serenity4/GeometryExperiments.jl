@testset "Point sets" begin
  set = PointSet(P2[(0.0, 0.0), (1.0, 1.0)])
  @test set == PointSet(Point(0.0, 0.0), Point(1.0, 1.0))
  @test set == PointSet(Point(0, 0.0), Point(1.0f0, 1.0f0))

  set = PointSet(P2[(0.0, 0.0), (1.0, 0.0), (0.0, 1.0), (1.0, 1.0)])
  @test centroid(set) == Point(0.5, 0.5)
  @test centroid(set) == centroid(Point(0.0, 0.0), Point(1.0, 0.0), Point(0.0, 1.0), Point(1.0, 1.0))

  set = PointSet(P2[(-1.0, -1.0), (1.0, -1.0), (-1.0, 1.0), (1.0, 1.0)])
  @test Scaling(1.0, 1.0)(set) == set
  @test Translation(0.0, 0.0)(set) == set
  (Scaling(1.0, 1.0) ∘ Translation(0.0, 0.0))(set) == set

  hc = Translated(HyperCube(0.5), Translation(0.5, 0.5, 0.5))
  set = PointSet(hc, P3)
  @test centroid(set) == 0.5 .* ones(P3)

  @test PointSet(HyperCube, P2) == PointSet(P2[(-1, -1), (1, -1), (-1, 1), (1, 1)])
  @test PointSet(HyperCube(0.5), P2) == PointSet(P2[(-0.5, -0.5), (0.5, -0.5), (-0.5, 0.5), (0.5, 0.5)])
  @test PointSet(HyperCube, P3) == PointSet(P3[(-1, -1, -1), (1, -1, -1), (-1, 1, -1), (1, 1, -1), (-1, -1, 1), (1, -1, 1), (-1, 1, 1), (1, 1, 1)])

  @testset "Nearest" begin
    set = PointSet([Point(0.0, 1.0), Point(0.5, 0.5), Point(1.0, 0)])
    @test sort_nearest(set, Point(1.0, 0.75)) == set.points[[2, 3, 1]]
  end
end;
