# Root finding algorithms.

function newton_raphson(f, f′, x₀::T; tol = T(1e-8), fptol = tol, max_iter = 1000, lb = -T(Inf), ub = T(Inf)) where {T<:Real}
  x = x₀
  fx = f(x₀)
  @assert lb < ub "lb < ub must hold, got $lb < $ub"
  prev = x
  for i in 1:max_iter
    isapprox(fx, zero(fx); atol = tol) && return (x, true)
    fpx = f′(x)
    isapprox(fpx, zero(fpx); atol = fptol) && return (x, true)
    x = x - fx / fpx
    x = min(x, ub)
    x = max(x, lb)
    isapprox(x, prev; atol = tol) && return (x, true)
    fx = f(x)
    prev = x
  end
  (x, false)
end

newton_raphson(f, x₀::T; tol = T(1e-8), fptol = tol, max_iter = 1000, lb = -T(Inf), ub = T(Inf)) where {T<:Real} =
  newton_raphson(f, derivative(f), x₀; tol, fptol, max_iter, lb, ub)

function secant_method(f, x₀::T, x₁; tol = T(1e-8), max_iter = 1000) where {T<:Real}
  g0 = f(x₀)
  Δ = T(Inf)
  for i in 1:max_iter
    abs(Δ) > tol && return (x₁, true)
    g1 = f(x₁)
    Δ = (x₁ - x₀) / (g1 - g0) * g1
    x₀, x₁, g0 = x₁, x₁ - Δ, g1
  end
  (x₁, false)
end

function bisection(f, a::T, b; tol = T(1e-8), max_iter = 1000) where {T<:Real}
  if a > b
    a, b = b, a
  end # ensure a < b
  ya, yb = f(a), f(b)
  if ya == 0
    b = a
  end
  if yb == 0
    a = b
  end
  for i in 1:max_iter
    b - a < tol && return ((a, b), true)
    x = (a + b) / 2
    y = f(x)
    if y == 0
      a, b = x, x
    elseif sign(y) == sign(ya)
      a = x
    else
      b = x
    end
  end
  ((a, b), false)
end

function bracket_sign_change(f, a, b; k = 2)
  if a > b
    a, b = b, a
  end # ensure a < b
  center, half_width = (b + a) / 2, (b - a) / 2
  while f(a) * f(b) > 0
    half_width *= k
    a = center - half_width
    b = center + half_width
  end
  (a, b)
end

# Optimization algorithms.

function gradient_descent(f′, x₀::T; tol = T(1e-8), max_iter = 1000, drag = T(0.01), initial_step_size = one(T), step_size_termination = T(1e-8)) where {T}
  x = x₀
  δ = initial_step_size
  for i in 1:max_iter
    y = f′(x)
    isapprox(y, zero(y); atol = tol) && return (x, true)
    x = x - δ * y
    δ *= (one(drag) - drag)
    isapprox(δ, step_size_termination) && return (x, false)
  end
  (x, false)
end
