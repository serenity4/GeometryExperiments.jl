# Studying the speed of PGA vs CGA intersection operations for flat primitives.

using SymbolicGA, BenchmarkTools

@geometric_space pga3 (3, 0, 1) quote
  embed(x) = x[1]::e1 + x[2]::e2 + x[3]::e3
  magnitude2(x) = x ⦿ x
  point(x) = embed(x) + 1.0::e4
end

pga3_extract(x) = x[begin:(end - 1)] ./ x[end]

@geometric_space cga3 (4, 1) quote
  n = 1.0::e4 + 1.0::e5
  n̄ = (-0.5)::e4 + 0.5::e5
  embed(x) = x[1]::e1 + x[2]::e2 + x[3]::e3
  magnitude2(x) = x ⦿ x
  point(x) = embed(x) + (0.5::Scalar * magnitude2(embed(x))) * n + n̄
  weight(X) = -X ⋅ n
  unitize(X) = X / weight(X)
  center(X) = X * n * X
  radius2(X) = (magnitude2(X) / magnitude2(X ∧ n))::Scalar
end

cga3_extract(x) = (@cga3 unitize(x::Vector))[1:(end - 2)]

a = (0.0, 0.0, 0.0)
b = (1.0, 0.0, 0.0)
c = (1.0, 0.0, 1.0)
d = (1.0, 1.0, 1.0)
e = (1.0, 1.0, 0.0)

# PGA
println("\n- Projective Geometric Algebra")
E = @pga3 point(e)
println("    Extraction of Euclidean vector")
@btime pga3_extract($E)

P = @pga3 point(b) ∧ point(c) ∧ point(d)
L = @pga3 point(a) ∧ point(b)
f(L, P) = @pga3 L::Bivector ∨ P::Trivector
println("    Line-plane intersection (point)")
I = @btime f($L, $P)
p = pga3_extract(I)
@assert p == b

# CGA
println("\n- Conformal Geometric Algebra")
E = @cga3 point(e)
println("    Extraction of Euclidean vector")
@btime cga3_extract($E)

P = @cga3 point(b) ∧ point(c) ∧ point(d) ∧ n
L = @cga3 point(a) ∧ point(b) ∧ n
g(L, P) = @cga3 L::Trivector ∨ P::Quadvector
println("    Line-plane intersection (point pair)")
I = @btime g($L, $P)
@cga3 magnitude2(I::Bivector)
@cga3 radius2(dual(I::Vector))
@cga3 center(dual(I::Vector))
