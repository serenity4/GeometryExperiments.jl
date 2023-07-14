function newton_raphson(f, f′, x₀; tol = 1e-8, max_iter = 1000)
  x = x₀
  fx = f(x₀)
  for i in 1:max_iter
    isapprox(fx, zero(fx); atol = tol) && return (x, true)
    fpx = f′(x)
    isapprox(fpx, zero(fpx); atol = tol) && return (x, true)
    x = x - fx / fpx
    fx = f(x)
  end
  (x, false)
end

newton_raphson(f, x₀; tol = 1e-8, max_iter = 1e3) = newton_raphson(f, x -> ForwardDiff.derivative(f, x), x₀; tol, max_iter)
