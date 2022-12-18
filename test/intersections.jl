ENV["JULIA_DEBUG"] = "SymbolicGA"
ENV["JULIA_DEBUG"] = ""

@testset "Intersections" begin
  x = (0.0, 0.0)
  y = (1.0, 1.0)
  y′ = (2.0, 1.0)
  z = (1.0, 0.0)
  z′ = (2.0, 0.0)
  L1 = Line(x, y)
  L2 = Line(z, y)
  L3 = Line(z′, y′)
  I = intersect(L1, L2)
  @test euclidean(I) == (1.0, 1.0)
  I = intersect(L2, L3)
  @test iszero(I[3])
  for L in (L1, L2, L3)
    I = intersect(L, L)
    @test all(iszero, I)
  end

  x = (x..., 0.0)
  y = (y..., 0.0)
  y′ = (y′..., 0.0)
  z = (z..., 0.0)
  z′ = (z′..., 0.0)
  L1 = Line(x, y)
  L2 = Line(z, y)
  L3 = Line(z′, y′)
  P = Plane(x, y, z)
  for L in (L1, L2, L3)
    I = intersect(L, P)
    @test all(iszero, I)
  end

  a = (0.0, 0.0, 0.0)
  b = (1.0, 0.0, 0.0)
  c = (1.0, 0.0, 1.0)
  d = (1.0, 1.0, 1.0)
  P = Plane(b, c, d)
  L1 = Line(a, b)
  I = intersect(L1, P)
  @test euclidean(I) == b
  @test I[end] == 1.0
  I = intersect(Line(b, a), P)
  @test euclidean(I) == b
  @test I[end] == -1.0
end;
