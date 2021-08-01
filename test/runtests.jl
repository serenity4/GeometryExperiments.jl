using GeometryExperiments
using Test

const P2 = Point{2,Float64}
const P3 = Point{3,Float64}

@testset "GeometryExperiments.jl" begin
    @testset "Transforms" begin
        @testset "Translations" begin
            tr = Translation(1., 3.)
            tr_inv = inv(tr)
            @test tr ∘ tr_inv == Translation(0., 0.)
            @test tr(Point(1., 2.)) == Point(2., 5.)
        end

        @testset "Scalings" begin
            sc = Scaling(1., 2.)
            sc_inv = inv(sc)
            @test sc ∘ sc_inv == Scaling(1., 1.)
            @test sc(Point(1., 2.)) == Point(1., 4.)

            us = UniformScaling(2.)
            @test us ∘ inv(us) == UniformScaling(1.)
            @test us(Point(1., 2.)) == Point(2., 4.)
        end

        @testset "Rotations" begin
        end

        @testset "Composition" begin
            @test Translation(2., 3.) ∘ Translation(1., 2.) == Translation(3., 5.)
            @test Scaling(2., 3.) ∘ Scaling(1., 2.) == Scaling(2., 6.)

            tr = Translation(1., 2.) ∘ Scaling(1., 2.) ∘ Translation(-1., -2.)
            @test all(transforms(tr) .== [Translation(1., 2.), Scaling(1., 2.), Translation(-1., -2.)])

            tr = Scaling(2., 3.) ∘ Translation(1., 2.)
            @test tr(Point(0., 0.)) == Point(2., 6.)

            p = Point(1., 2.)
            @test (inv(tr) ∘ tr)(p) == p
        end
    end

    @testset "Geometry" begin
        eval_sph(radius, p::Point) = hypot(p...) - radius

        p = Point(0., 1., 0.)

        hc = HyperCube(0.2)
        @test p ∉ hc
        @test Point(0., 0., 0.) ∈ hc
        @test Translated(hc, Translation(0., 0., 0.))(p) == hc(p) == 0.8
        @test Translated(hc, Translation(0.05, 1., 0.))(p) ≈ -0.15
        @test Transformed(hc, Scaling(1., 2., 3.)) === Box(0.2, Scaling(1., 2., 3.))

        sph = HyperSphere(0.2)
        @test p ∉ sph
        @test Point(0., 0., 0.) ∈ sph
        @test sph(Point(0.3, 0.4, 0.5)) == eval_sph(0.2, Point(0.3, 0.4, 0.5))
        @test sph(Point(0.5, 0.2)) == eval_sph(0.2, Point(0.5, 0.2))
        @test Translated(sph, Translation(0., 0., 0.))(p) == sph(p) == 0.8
        @test Translated(sph, Translation(0.05, 1., 0.))(p) ≈ -0.15
        @test p ∈ Translated(sph, Translation(0.05, 1., 0.))

        elps = Ellipsoid(0.2, Scaling(1., 2., 3.))
        @test Scaled(sph, Scaling(1., 2., 3.)) === elps
        @test elps ≈ Ellipsoid(Point(0.2, 0.4, 0.6))
        @test p ∉ elps

        @testset "Projections" begin
            p = Projection{2}(HyperSphere(eval_sph(0., Point(0.2, 0.2))))
            @test Point(0.1,0.1) ∈ p
            @test Point(0.1,2.) ∉ p
            @test Point(0.1,2.,0.) ∉ p
            @test Point(0.1,0.1,0.) ∈ p
            @test Point(0.1,0.1,0.1) ∉ p
            @test p(Point(0.2,0.2)) == 0.
            @test p(Point(0.2,0.2,0.)) == 0.
            @test p(Point(0.2,0.2,0.5)) == 0.5
            @test p(Point(0.2,0.2,0.5,0.3)) == eval_sph(0., Point(0.5,0.3))
        end
    end

    @testset "Point sets" begin
        set = PointSet([Point(0., 0.), Point(1., 0.), Point(0., 1.), Point(1., 1.)])
        set2 = PointSet([Point(0., 0.5), Point(0.5, 0.), Point(0.5, 1.), Point(1., 0.5)])
        @test boundingelement(set) == Translated(Scaled(HyperCube(1.), Scaling(0.5, 0.5)), Translation(0.5, 0.5))
        @test boundingelement(set) == boundingelement(set2)

        set = PointSet([Point(-1., -1.), Point(1., -1.), Point(-1., 1.), Point(1., 1.)])
        @test boundingelement(set) == Translated(Scaled(HyperCube(1.), Scaling(1., 1.)), Translation(0., 0.))
        @test Scaling(1., 1.)(set) == set
        @test Translation(0., 0.)(set) == set
        (Scaling(1., 1.) ∘ Translation(0., 0.))(set) == set

        set = PointSet([Point(0., 0., 0.), Point(1., 0., 0.), Point(0., 1., 0.), Point(0., 0., 1.), Point(1., 1., 0.), Point(1., 0., 1.), Point(0., 1., 1.), Point(1., 1., 1.)])
        @test boundingelement(set) == Translated(Scaled(HyperCube(1.), Scaling(0.5, 0.5, 0.5)), Translation(0.5, 0.5, 0.5))

        @test PointSet(HyperCube, P2) == PointSet(P2[(-1,-1),(1,-1),(-1,1),(1,1)])
        @test PointSet(HyperCube(0.5), P2) == PointSet(P2[(-0.5,-0.5),(0.5,-0.5),(-0.5,0.5),(0.5,0.5)])
        @test PointSet(HyperCube, P3) == PointSet(P3[(-1,-1,-1),(1,-1,-1),(-1,1,-1),(1,1,-1),(-1,-1,1),(1,-1,1),(-1,1,1),(1,1,1)])

        @testset "Nearest" begin
            set = PointSet([Point(0., 1.), Point(0.5, 0.5), Point(1., 0)])
            @test sort_nearest(set, Point(1., 0.75)) == set.points[[2, 3, 1]]
        end
    end

    @testset "Curves" begin
        @testset "Bezier curves" begin
            T = Float64
            b = BezierCurve()
            points = P2[(0,0),(0.5,1),(1,0)]
            @test b(T(0), points) == P2(0,0)
            @test b(T(1), points) == P2(1,0)
            @test b(T(0.5), points) == P2(0.5,0.5)
            @test b(T(0.5), points) == P2(0.5,0.5)
            @test_throws DomainError(T(-0.1), "b(t) is not defined for t outside [0, 1].") b(T(-0.1), points)
            @test_throws DomainError(T(1.2), "b(t) is not defined for t outside [0, 1].") b(T(1.2), points)
        end

        @testset "Patches" begin
            p = Patch(BezierCurve(), 3)
            points = P2[(0,0),(0.5,1),(1,0), (1.5,-1),(2,0)]
            @test p(0, points) == P2(0,0)
            @test p(0.25, points) == P2(0.5, 0.5)
            @test p(0.5, points) == P2(1,0)
            @test p(0.75, points) == P2(1.5, -0.5)
            @test p(1, points) == P2(2,0)
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
        @test TriangleList(fan) == list
    end
end
