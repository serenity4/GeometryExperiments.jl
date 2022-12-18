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
end;
