# extracted from Meshes.jl

"""
Evaluation method used to obtain a point along
a Bézier curve from a parametric expression.
"""
abstract type BezierEvalMethod end

"""
Fast evaluation in the case of a fixed small number `N` of control points.
"""
struct FixedDegree{N} <: BezierEvalMethod
  FixedDegree{N}() where {N} = N > 1 ? new() : throw(ArgumentError("`N` must be greater than 1"))
end
FixedDegree(n::Int) = FixedDegree{n}()

"""
Approximate evaluation using Horner's method.
Recommended for a large number of control points,
if you can afford a precision loss.
See https://en.wikipedia.org/wiki/Horner%27s_method.
"""
struct Horner <: BezierEvalMethod end

@struct_hash_equal_isequal_isapprox struct BezierCurve{P,M<:BezierEvalMethod} <: Curve
  points::P
  method::M
end

BezierCurve(points) = BezierCurve(points, Horner())

Base.length(::Type{<:BezierCurve{P}}) where {P} = length(P)
Base.length(curve::BezierCurve) = length(curve.points)

(curve::BezierCurve)(t) = curve(t, Horner())

degree(p) = length(p) - 1

lerp(a, b, t) = (one(t) - t) .* a .+ t .* b

@generated function (curve::BezierCurve{<:Any,FixedDegree{N}})(t) where {N}
  N == 2 && return :(lerp(curve.points[1], curve.points[2], t))
  pa = Expr(:tuple, (:(curve.points[$i]) for i in 1:(N - 1))...)
  pb = Expr(:tuple, (:(curve.points[$i]) for i in 2:N)...)
  m = FixedDegree{N - 1}()
  :(lerp(BezierCurve($pa, $m)(t), BezierCurve($pb, $m)(t), t))
end

"""
Apply Horner's method on the monomial representation of the
Bézier curve B = ∑ᵢ aᵢtⁱ with i ∈ [0, n], n the degree of the
curve, aᵢ = binomial(n, i) * pᵢ * t̄ⁿ⁻ⁱ and t̄ = (1 - t).
Horner's rule recursively reconstructs B from a sequence bᵢ
with bₙ = aₙ and bᵢ₋₁ = aᵢ₋₁ + bᵢ * t until b₀ = B.
"""
function ((; points)::BezierCurve{<:Any,Horner})(t)
  T = eltype(eltype(points))
  t̄ = one(T) - t
  n = degree(points)
  pₙ = last(points)
  aₙ = pₙ

  # initialization with i = n + 1, so bᵢ₋₁ = bₙ = aₙ
  bᵢ₋₁ = aₙ
  cᵢ₋₁ = one(T)
  t̄ⁿ⁻ⁱ = one(T)
  for i in n:-1:1
    cᵢ₋₁ *= i / (n - i + one(T))
    pᵢ₋₁ = points[i]
    t̄ⁿ⁻ⁱ *= t̄
    aᵢ₋₁ = cᵢ₋₁ .* pᵢ₋₁ .* t̄ⁿ⁻ⁱ
    bᵢ₋₁ = aᵢ₋₁ .+ bᵢ₋₁ .* t
  end

  b₀ = bᵢ₋₁
  b₀
end

function project(curve::BezierCurve, p::Point{2,T}) where {T}
  degree(curve) == 2 || error("Projection only supported for quadratic Bezier curves")
  t, converged = newton_raphson(0.5) do t
    distance_squared(curve(t), p)
  end
  @assert converged "Newton-Raphson did not converge"
  t = clamp(t, zero(T), one(T))
  (t, curve(t))
end
