using GeometryExperiments
using Test

const P2 = Point{2,Float64}
const P3 = Point{3,Float64}

@testset "GeometryExperiments.jl" begin
  @testset "Basic transforms" begin
    @testset "Translations" begin
      tr = Translation(1.0, 3.0)
      tr_inv = inv(tr)
      @test tr ∘ tr_inv == Translation(0.0, 0.0)
      @test tr(Point(1.0, 2.0)) == Point(2.0, 5.0)
      @test identity(Translation{2,Float64})(Point(1.0, 2.0)) == Point(1.0, 2.0)
    end

    @testset "Scalings" begin
      sc = Scaling(1.0, 2.0)
      sc_inv = inv(sc)
      @test sc ∘ sc_inv == Scaling(1.0, 1.0)
      @test sc(Point(1.0, 2.0)) == Point(1.0, 4.0)
      @test identity(Scaling{2,Float64})(Point(1.0, 2.0)) == Point(1.0, 2.0)

      us = UniformScaling(2.0)
      @test us ∘ inv(us) == UniformScaling(1.0)
      @test us(Point(1.0, 2.0)) == Point(2.0, 4.0)
      @test identity(UniformScaling{Float64})(Point(1.0, 2.0)) == Point(1.0, 2.0)
    end

    @testset "Rotations" begin end

    @testset "Composition" begin
      @test Translation(2.0, 3.0) ∘ Translation(1.0, 2.0) == Translation(3.0, 5.0)
      @test Scaling(2.0, 3.0) ∘ Scaling(1.0, 2.0) == Scaling(2.0, 6.0)

      trs = [Translation(1.0, 2.0), Scaling(1.0, 2.0), Translation(-1.0, -2.0)]
      tr = ∘(trs...)
      @test all(transforms(tr) .== trs)

      tr = Scaling(2.0, 3.0) ∘ Translation(1.0, 2.0)
      @test tr(Point(0.0, 0.0)) == Point(2.0, 6.0)

      p = Point(1.0, 2.0)
      @test (inv(tr) ∘ tr)(p) == p
    end
  end

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
  end

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
  end

  @testset "Point sets" begin
    set = PointSet([Point(0.0, 0.0), Point(1.0, 0.0), Point(0.0, 1.0), Point(1.0, 1.0)])
    set2 = PointSet([Point(0.0, 0.5), Point(0.5, 0.0), Point(0.5, 1.0), Point(1.0, 0.5)])
    @test boundingelement(set) == Translated(Scaled(HyperCube(1.0), Scaling(0.5, 0.5)), Translation(0.5, 0.5))
    @test boundingelement(set) == boundingelement(set2)

    set = PointSet([Point(-1.0, -1.0), Point(1.0, -1.0), Point(-1.0, 1.0), Point(1.0, 1.0)])
    @test boundingelement(set) == Translated(Scaled(HyperCube(1.0), Scaling(1.0, 1.0)), Translation(0.0, 0.0))
    @test Scaling(1.0, 1.0)(set) == set
    @test Translation(0.0, 0.0)(set) == set
    (Scaling(1.0, 1.0) ∘ Translation(0.0, 0.0))(set) == set

    hc = Translated(HyperCube(0.5), Translation(0.5, 0.5, 0.5))
    set = PointSet(hc, P3)
    be = boundingelement(set)
    @test isa(be, Transformed{<:HyperCube})
    @test origin(be) == 0.5 .* ones(P3)
    @test radius(be) == 0.5 .* ones(P3)
    @test all(be.(set) .== 0 .== hc.(set))

    @test PointSet(HyperCube, P2) == PointSet(P2[(-1, -1), (1, -1), (-1, 1), (1, 1)])
    @test PointSet(HyperCube(0.5), P2) == PointSet(P2[(-0.5, -0.5), (0.5, -0.5), (-0.5, 0.5), (0.5, 0.5)])
    @test PointSet(HyperCube, P3) == PointSet(P3[(-1, -1, -1), (1, -1, -1), (-1, 1, -1), (1, 1, -1), (-1, -1, 1), (1, -1, 1), (-1, 1, 1), (1, 1, 1)])

    @testset "Nearest" begin
      set = PointSet([Point(0.0, 1.0), Point(0.5, 0.5), Point(1.0, 0)])
      @test sort_nearest(set, Point(1.0, 0.75)) == set.points[[2, 3, 1]]
    end
  end

  @testset "Curves" begin
    @testset "Bezier curves" begin
      T = Float64
      b = BezierCurve()
      points = P2[(0, 0), (0.5, 1), (1, 0)]
      @test b(T(0), points) == P2(0, 0)
      @test b(T(1), points) == P2(1, 0)
      @test b(T(0.5), points) == P2(0.5, 0.5)
      @test b(T(0.5), points) == P2(0.5, 0.5)
      @test_throws DomainError(T(-0.1), "b(t) is not defined for t outside [0, 1].") b(T(-0.1), points)
      @test_throws DomainError(T(1.2), "b(t) is not defined for t outside [0, 1].") b(T(1.2), points)
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
  end

  @testset "Mesh encodings" begin
    strip = TriangleStrip(1:5)
    list = TriangleList([(1, 2, 3), (2, 4, 3), (3, 4, 5)])
    @test TriangleList(strip) == list

    fan = TriangleFan(1:5)
    list = TriangleList([(1, 2, 3), (1, 3, 4), (1, 4, 5)])
    @test GeometryExperiments.topology_class(typeof(fan)) == Triangle
    @test TriangleList(fan) == list

    @test MeshVertexEncoding(P2[(1.2, 1.4), (0.1, 0.2), (0.3, 0.4), (0.5, 0.2)], Triangle) isa MeshVertexEncoding{<:TriangleStrip,P2}
    @test MeshVertexEncoding(fan, P2[(1.2, 1.4), (0.1, 0.2), (0.3, 0.4), (0.5, 0.2)]) isa MeshVertexEncoding{<:TriangleFan,P2}

    strip = LineStrip(1:5)
    @test GeometryExperiments.topology_class(typeof(strip)) == Line
    @test LineList(strip) == LineList([(1, 2), (2, 3), (3, 4), (4, 5)])
  end
end
