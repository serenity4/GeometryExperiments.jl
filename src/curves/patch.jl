"""
Patch made by "gluing" curves together.

If `compact` is set to true, each curve starts from the point of the last curve, assumed to be on the curve.
"""
@struct_hash_equal_isequal_isapprox struct Patch{C<:Curve,N,V} <: Curve
  points::V
  compact::Bool
end
function Patch{C,N}(points::V; compact::Bool = true) where {C,N,V}
  compact && (length(points) - N) % (N - 1) ≠ 0 &&
    throw(ArgumentError("A patch constructed with the option `compact = true` does not have a correct number of points."))
  Patch{C,N,V}(points, compact)
end

Base.iterate(patch::Patch, i = 1) = (i > lastindex(patch) ? nothing : (patch[i], i + 1))

function Base.length(patch::Patch)
  nₚ = length(patch.points)
  if patch.compact
    1 + Int((nₚ - points_per_curve(patch)) / (points_per_curve(patch) - 1))
  else
    Int(nₚ / points_per_curve(patch))
  end
end

points_per_curve(::Patch{<:Any,N}) where {N} = N

Base.eltype(patch::Patch) = typeof(patch[1])
Base.IteratorEltype(::Patch) = Base.HasEltype()
Base.firstindex(patch::Patch) = 1
Base.lastindex(patch::Patch) = length(patch)
Base.eachindex(patch::Patch) = firstindex(patch):lastindex(patch)

Base.getindex(patch::Patch{C}, i::Int) where {C} = C(curve_points(patch, i))

function (patch::Patch{C})(t) where {C}
  nc = length(patch)
  i = 1 + clamp(Int(t ÷ (1 / nc)), 0, nc - 1)
  curve = patch[i]
  curve(nc * (t - (i - 1) / nc))
end

function curve_points(patch::Patch, i::Int)
  n = points_per_curve(patch)
  start = patch.compact ? 1 + (i - 1) * (n - 1) : 1 + (i - 1) * n
  @view patch.points[start:(start + n - 1)]
end

function decompactify(patch::Patch{C,N}) where {C,N}
  patch.compact || return patch
  points = foldl((x, y) -> append!(x, y.points), patch; init = typeof(patch.points)())
  Patch{C,N}(points; compact = false)
end

function compactify(patch::Patch{C,N}) where {C,N}
  patch.compact && return patch
  n = points_per_curve(patch)
  points = typeof(patch.points)()
  append!(points, patch[1].points)
  for i in 2:lastindex(patch)
    append!(points, @view patch[i].points[2:end])
  end
  Patch{C,N}(points; compact = true)
end

function project(patch::Patch, p::Point{2,T}) where {T}
  curve = argmin(curve -> minimum(cp -> distance_squared(cp, p), curve.points), patch)
  project(curve, p)
end
