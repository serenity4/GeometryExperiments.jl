using GeometryExperiments
using GeometryExperiments: Point, coordinates
using Test

@testset "GeometryExperiments.jl" begin
    @testset "Transforms" begin
        @testset "Translations" begin
            tr = Translation(1., 2.)
            tr_inv = inv(tr)
            @test tr ∘ tr_inv == Translation(0., 0.)
        end

        @testset "Scalings" begin
            sc = Scaling(1., 2.)
            sc_inv = inv(sc)
            @test sc ∘ sc_inv == Scaling(1., 1.)
        end

        @testset "Rotations" begin
        end

        @testset "Composition" begin
            comp = Translation(1., 2.) ∘ Scaling(1., 2.) ∘ Translation(-1., -2.)
            @test all(GeometryExperiments.Leaves(comp) .== [Translation(1., 2.), Scaling(1., 2.), Translation(-1., -2.)])
        end
    end
    @testset "Geometry" begin
        eval_sph(radius, p::Point) = sqrt(sum(coordinates(p).^2)) - radius

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
        @test p ∉ elps
    end
end
