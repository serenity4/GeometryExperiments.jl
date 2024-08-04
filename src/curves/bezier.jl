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

function derivative(curve::BezierCurve, t::Real)
  degree(curve) == 2 && return begin
    p₁, p₂, p₃ = curve.points
    2(1 - t) .* (p₂ - p₁) .+ 2t .* (p₃ - p₂)
  end
  ForwardDiff.derivative(curve, t)
end

function projection_parameter(curve::BezierCurve, p::Point{2,T}) where {T}
  degree(curve) == 2 || error("Projection only supported for quadratic Bezier curves")
  f(t) = distance_squared(curve(t), p)
  orthogonality_condition(t) = begin
    C = curve(t)
    C′ = derivative(curve, t)
    C′ ⋅ (C - p)
  end

  # XXX: This tried to avoid Newton-Raphson when the problem is badly conditioned, but it seems like it's not that much more efficient and requires fine-tuning.

  # p₁, p₂, p₃ = curve.points
  # area = 0.5 * abs(@ga 2 T (p₂::1 - p₁::1) ∧ (p₃::1 - p₁::1))
  # d = maximum(f, (0.0, 0.5, 1.0))
  # fp = minimum(abs ∘ derivative(orthogonality_condition), (0.0, 0.5, 1.0))
  # if d^2 / area > 10 || abs(fp) < 0.05
  #   # Don't even try Newton-Raphson, as it is more likely to fail under these conditions.
  #   ((a, b), converged) = bisection(orthogonality_condition, 0.0, 1.0)
  #   t = (a + b) / 2
  # else
  #   ((a, b), converged) = bisection(orthogonality_condition, 0.0, 1.0; max_iter = 3)
  #   t = (a + b) / 2
  #   if !converged
  #     (t, converged) = newton_raphson(orthogonality_condition, t; lb = 0.0, ub = 1.0, max_iter = 10)
  #   end
  #   if !converged
  #     ((a, b), converged) = bisection(orthogonality_condition, 0.0, 1.0)
  #     t = (a + b) / 2
  #   end
  # end

  ((a, b), converged) = bisection(orthogonality_condition, zero(T), one(T); max_iter = 3)
  t = (a + b) / 2
  if !converged
    (t, converged) = newton_raphson(orthogonality_condition, t; lb = zero(T), ub = one(T), max_iter = 10)
    if !converged
      ((a, b), converged) = bisection(orthogonality_condition, zero(T), one(T); max_iter = 100)
      t = (a + b) / 2
    end
  end

  d = f(t)
  @assert converged "Local descent did not converge: last estimate is $t for point projection of $p, with a distance of $d"
  # The orthogonality condition will not hold if one of the endpoints has the minimum distance.
  # If that is the case, return the relevant endpoint.
  (dmin, i) = findmin(cp -> distance_squared(cp, p), endpoints(curve))

  dmin < d && return i - one(T)
  t
end

Base.intersect(line::Line{2}, bezier::BezierCurve{2}) = intersect(bezier, line)
function Base.intersect(bezier::BezierCurve, line::Line{2,T}) where {T}
  degree(bezier) == 2 || error("Intersections between a line and a Bézier curve are only supported for quadratic curves")
  # Uses part of the technique from GPU-Centered Font Rendering Directly from Glyph Outlines, E. Lengyel, 2017.
  direction = Point{2,T}((@pga2 weight(line::2))[2:3])
  α = atan(direction[2], direction[1])
  rotor = @ga 2 exp(-(($(T(-0.5))*α)::e̅))
  origin = projection(line, zero(Point{2,T}))

  points = (point -> @ga 2 Point{2,T} (point::1 - origin::1) << rotor::(0, 2)).(bezier.points)
  ((x₁, y₁), (x₂, y₂), (x₃, y₃)) = points

  # Cast a ray in the X direction.
  code = classify_bezier_curve((y₁, y₂, y₃))
  iszero(code) && return nothing
  (t₁, t₂) = compute_roots(y₁ - 2y₂ + y₃, y₁ - y₂, y₁)
  0 ≤ t₁ ≤ 1 || (t₁ = T(NaN))
  0 ≤ t₂ ≤ 1 || (t₂ = T(NaN))
  isnan(t₁) && isnan(t₂) && return nothing
  isnan(t₁) && return bezier(t₂)
  isnan(t₂) && return bezier(t₁)
  (bezier(t₁), bezier(t₂))
end

function classify_bezier_curve(points)
  (x₁, x₂, x₃) = points
  rshift = ifelse(x₁ > 0, 1 << 1, 0) + ifelse(x₂ > 0, 1 << 2, 0) + ifelse(x₃ > 0, 1 << 3, 0)
  (0x2e74 >> rshift) & 0x0003
end

function compute_roots(a, b, c)
  T = typeof(a)
  if isapprox(a, zero(a), atol = T(1e-7))
    t₁ = t₂ = c / 2b
    return (t₁, t₂)
  end
  Δ = b^2 - a * c
  Δ < 0 && return (T(NaN), T(NaN))
  δ = sqrt(Δ)
  t₁ = (b - δ) / a
  t₂ = (b + δ) / a
  (t₁, t₂)
end
