@testset "Projections" begin
  p = Projection{2}(HyperSphere(HyperSphere(0.0)(Point(0.2, 0.2))))
  @test Point(0.1, 0.1) ∈ p
  @test Point(0.1, 2.0) ∉ p
  @test Point(0.1, 2.0, 0.0) ∉ p
  @test Point(0.1, 0.1, 0.0) ∈ p
  @test Point(0.1, 0.1, 0.1) ∉ p
  @test p(Point(0.2, 0.2)) == 0.0
  @test p(Point(0.2, 0.2, 0.0)) == 0.0
  @test p(Point(0.2, 0.2, 0.5)) == 0.5
  @test p(Point(0.2, 0.2, 0.5, 0.3)) == HyperSphere(0.0)(Point(0.5, 0.3))
end;
