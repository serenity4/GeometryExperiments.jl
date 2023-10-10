@testset "Bounding elements" begin
  set = PointSet(P2[(0.0, 0.0), (1.0, 0.0), (0.0, 1.0), (1.0, 1.0)])
  box = boundingelement(set)
  @test box == Box(P2(0, 0), P2(1, 1))
  set2 = PointSet(P2[(0.0, 0.5), (0.5, 0.0), (0.5, 1.0), (1.0, 0.5)])
  @test boundingelement(set2) == box
  @test boundingelement((set, set2)) == box

  set3 = PointSet(P2[(-0.3, -0.9), (0.9, -0.9), (-0.5, 1.1), (0.9, 1.1)])
  box2 = boundingelement(set3)
  @test box2 == Box(P2(-0.5, -0.9), P2(0.9, 1.1))
  box3 = boundingelement(box, box2)
  @test box3 == boundingelement(box2, box) == boundingelement((box2, box)) == boundingelement([box2, box])
  @test box3 == Box(P2(-0.5, -0.9), P2(1.0, 1.1))
end;
