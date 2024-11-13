@testset "Primitives" begin
  @testset "Normed primitives" begin
    p = Point(0.0, 1.0, 0.0)
    hc = HyperCube(0.2)
    @test origin(hc) == 0.0
    @test radius(hc) == 0.2
    @test p ∉ hc
    @test origin(hc) ∈ hc
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
  end

  @testset "Boxes" begin
    b = Box(P2(0.1, 0.2))
    @test b.top_right == P2(0.1, 0.2)
    @test b.bottom_left == P2(-0.1, -0.2)
    @test b.width == 0.2
    @test b.height == 0.4

    b1 = Box(P3(0.2, 0.4, 0.6))
    @test convert(Box{3,Float32}, b1) == Box(Point3f(0.2, 0.4, 0.6))
    @test b1 == Box(P3(-0.2, -0.4, -0.6), P3(0.2, 0.4, 0.6))
    @test centroid(b1) == zero(P3)
    b2 = b1 + P3(0.1, 0.7, 0.4)
    @test centroid(b1) in b1
    @test centroid(b2) ≈ centroid(b1) + P3(0.1, 0.7, 0.4)

    b = Box(P2(Inf, Inf))
    @test b == Box(P2(-Inf, -Inf), P2(Inf, Inf))
    @test all(isnan, centroid(b))
    @test in(zero(P2), b)
    @test in(P2(100000, 100000), b)
    @test in(P2(-100000, -100000), b)
    @test in(P2(Inf, Inf), b)
    @test in(P2(-Inf, -Inf), b)
  end

  @testset "Advanced transforms" begin
    function test_mapping(p1, pres, from, to)
      @test p1 ∈ from
      p2 = tr(p1)
      @test p2 ∈ to
      @test p2 ≈ pres
    end
    p1, p2, p3, p4 = P3[(10.0, 10.0, 10.0), (-5.0, -5.0, -5.0), (8.0, 12.0, 16.0), (7.0, 7.0, 7.0)]
    from = Box(-p1 + p2, p1 + p2)
    to = Box(-p3 + p4, p3 + p4)
    tr = BoxTransform(from, to)
    test_mapping(centroid(from), centroid(to), from, to)

    for (p1, pres) in zip(PointSet(from), PointSet(to))
      test_mapping(p1, pres, from, to)
    end
  end
end;
