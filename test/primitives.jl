@testset "Primitives" begin
  p = Point(0.0, 1.0, 0.0)

  hc = HyperCube(0.2)
  @test origin(hc) == 0.0
  @test radius(hc) == 0.2
  @test p ∉ hc
  @test origin(hc) ∈ hc

  b1 = Box(0.2, Scaling(1.0, 2.0, 3.0))
  @test b1 === Scaled(hc, Scaling(1.0, 2.0, 3.0))
  b2 = Box(Scaling(0.2 .* Point(1.0, 2.0, 3.0)))
  @test origin(b1) == origin(b2) && radius(b1) == radius(b2)
  b3 = Translated(b2, Translation(0.4, 0.4, 0.4))
  b4 = box(0.4 .+ Point(-0.2, -0.4, -0.6), 0.4 .+ Point(0.2, 0.4, 0.6))
  @test origin(b4) ≈ origin(b3)
  @test radius(b4) ≈ radius(b3)

  @test Translated(hc, Translation(0.05, 1.0, 0.0))(p) ≈ -0.15

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
