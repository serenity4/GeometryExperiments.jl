@testset "Primitives" begin
  p = Point(0.0, 1.0, 0.0)

  hc = HyperCube(0.2)
  @test origin(hc) == 0.0
  @test radius(hc) == 0.2
  @test p ∉ hc
  @test origin(hc) ∈ hc
  @test Translated(hc, Translation(0.05, 1.0, 0.0))(p) ≈ -0.15

  b1 = Box(P3(0.2, 0.4, 0.6))
  @test b1 == Box(P3(-0.2, -0.4, -0.6), P3(0.2, 0.4, 0.6))
  @test centroid(b1) == zero(P3)
  b2 = b1 + P3(0.1, 0.7, 0.4)
  @test centroid(b2) ≈ centroid(b1) + P3(0.1, 0.7, 0.4)

  hc = Scaled(HyperCube(0.2), Scaling(1.0, 2.0))
  @test origin(hc) == Point(0.0, 0.0)
  @test radius(hc) == Point(0.2, 0.4)
  hc = Translated(hc, Translation(0.3, 0.4))
  @test origin(hc) == Point(0.3, 0.4)
  @test radius(hc) == Point(0.2, 0.4)

  sph = HyperSphere(0.2)
  @test p ∉ sph
  @test zero(P3) ∈ sph
  @test Translated(sph, Translation(0.0, 0.0, 0.0))(p) == sph(p) == 0.8
  @test Translated(sph, Translation(0.05, 1.0, 0.0))(p) ≈ -0.15
  @test p ∈ Translated(sph, Translation(0.05, 1.0, 0.0))

  elps = Ellipsoid(0.2, Scaling(1.0, 2.0, 3.0))
  @test Scaled(sph, Scaling(1.0, 2.0, 3.0)) === elps
  @test elps ≈ Ellipsoid(Point(0.2, 0.4, 0.6))
  @test p ∉ elps
  @test origin(elps) ∈ elps

  @testset "Advanced transforms" begin
    function test_mapping(p1, pres, from, to)
      @test p1 ∈ from
      p2 = tr(p1)
      @test p2 ∈ to
      @test p2 == pres
    end
    from = Translated(HyperCube(1.0), Translation(-5.0, -5.0, -5.0))
    to = Translated(Scaled(HyperCube(2.0), Scaling(2.0, 3.0, 4.0)), Translation(7.0, 7.0, 7.0))
    tr = BoxTransform(from, to)
    test_mapping(origin(from), origin(to), from, to)

    for (p1, pres) in zip(PointSet(from, P3), PointSet(to, P3))
      test_mapping(p1, pres, from, to)
    end
  end
end;
