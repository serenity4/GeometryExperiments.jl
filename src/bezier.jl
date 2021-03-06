# extracted from Meshes.jl

"""
Evaluation method used to obtain a point along
a Bézier curve from a parametric expression.
"""
abstract type BezierEvalMethod end

"""
Approximate evaluation using Horner's method.
Recommended for a large number of control points,
if you can afford a precision loss.
See https://en.wikipedia.org/wiki/Horner%27s_method.
"""
struct Horner <: BezierEvalMethod end

struct BezierCurve{M<:BezierEvalMethod} <: Curve
  method::M
end

BezierCurve() = BezierCurve(Horner())

degree(p) = length(p) - 1

"""
Apply Horner's method on the monomial representation of the
Bézier curve B = ∑ᵢ aᵢtⁱ with i ∈ [0, n], n the degree of the
curve, aᵢ = binomial(n, i) * pᵢ * t̄ⁿ⁻ⁱ and t̄ = (1 - t).
Horner's rule recursively reconstructs B from a sequence bᵢ
with bₙ = aₙ and bᵢ₋₁ = aᵢ₋₁ + bᵢ * t until b₀ = B.
"""
function (curve::BezierCurve{Horner})(t, points)
  if t < 0 || t > 1
    throw(DomainError(t, "b(t) is not defined for t outside [0, 1]."))
  end
  d = length(points)
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
    aᵢ₋₁ = cᵢ₋₁ * pᵢ₋₁ * t̄ⁿ⁻ⁱ
    bᵢ₋₁ = aᵢ₋₁ + bᵢ₋₁ * t
  end

  b₀ = bᵢ₋₁
  b₀
end
