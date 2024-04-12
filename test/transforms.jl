@testset "Basic transforms" begin
  @testset "Translations" begin
    tr = Translation(1.0, 3.0)
    tr_inv = inv(tr)
    @test tr ∘ tr_inv == Translation(0.0, 0.0)
    @test tr(Point(1.0, 2.0)) == Point(2.0, 5.0)
    @test zero(Translation{2,Float64})(Point(1.0, 2.0)) == Point(1.0, 2.0)
  end

  @testset "Scalings" begin
    sc = Scaling(1.0, 2.0)
    sc_inv = inv(sc)
    @test sc ∘ sc_inv == Scaling(1.0, 1.0)
    @test sc(Point(1.0, 2.0)) == Point(1.0, 4.0)
    @test one(Scaling{2,Float64})(Point(1.0, 2.0)) == Point(1.0, 2.0)

    us = UniformScaling(2.0)
    @test us ∘ inv(us) == UniformScaling(1.0)
    @test us(Point(1.0, 2.0)) == Point(2.0, 4.0)
    @test one(UniformScaling{Float64})(Point(1.0, 2.0)) == Point(1.0, 2.0)
  end

  @testset "Rotations" begin
    @testset "Rotation planes" begin
      n = zero(Point3)
      p = RotationPlane(n)
      @test norm(p.u) == norm(p.v) == 1
      @test RotationPlane((1, 0, 0)) == RotationPlane((0, 0, 1), (0, -1, 0))
      @test RotationPlane((0, 0, 1)) == RotationPlane((0, -1, 0), (1, 0, 0))
    end
  
    @testset "Quaternion" begin
      rot = Quaternion()
      @test iszero(rot)
      @test rot == Rotation{3}()
      plane = RotationPlane((1, 0, 0), (0, 1, 0))
      rot = Quaternion(plane, 45°)
      @test rot == Rotation(plane, 45°)
      p = Point3(0.2, 0.2, 1.0)
      p′ = apply_rotation(p, rot)
      @test p′.z == p.z
      @test p′[1:2] ≈ Point(0, 0.2sqrt(2))
      @test apply_rotation(p, Quaternion(plane, 0)) == p
      rot = Quaternion(RotationPlane(Tuple(rand(3))), 1.5)
      @test apply_rotation(p, rot) ≉ p
      @test apply_rotation(apply_rotation(p, rot), inv(rot)) ≈ p

      for i in 1:100
        q = rand(Quaternion)
        matrix = SMatrix{3,3}(q)
        p = rand(Point3)
        @test matrix * p ≈ apply_rotation(p, q)
        @test Quaternion(matrix) ≈ q
      end

      for i in 1:100
        from = rand(Point3)
        to = rand(Point3)
        q = Rotation(from, to)
        @test normalize(apply_rotation(from, q)) ≈ normalize(to)
        @test normalize(apply_rotation(to, inv(q))) ≈ normalize(from)
      end
    end
  end

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

  @testset "Transforms" begin
    tr = Transform()
    p = Point(1.2, 1.6, -0.1)
    @test apply_transform(p, tr) ≈ p
    tr = Transform(Translation(-0.2, -0.6, 1.3), Rotation(RotationPlane((0.5, 0.4, 0.3)), 40°), Scaling(1.3, 2.0, 5.0))
    p′ = apply_transform(p, tr)
    p′′ = apply_transform_inverse(p′, tr)
    @test p′′ ≈ p
    trf32 = convert(Transform{3,Float32,Quaternion{Float32}}, tr)
    @test apply_transform_inverse(apply_transform(p, trf32), trf32) ≈ p rtol=1e-6

    for i in 1:100
      tr = rand(Transform{3})
      matrix = SMatrix{4,4}(tr)
      tr2 = Transform(matrix)
      @test tr2 ≈ tr
      p = rand(Point3)
      p1 = apply_transform(p, tr)
      p2 = euclidean(matrix * Point4(p..., 1))
      @test p1 ≈ p2
      p1_inv = apply_transform_inverse(p1, tr)
      p2_inv = euclidean(matrix \ Point4(p2..., 1))
      @test p1_inv ≈ p
      @test p2_inv ≈ p
    end
  end
end;
