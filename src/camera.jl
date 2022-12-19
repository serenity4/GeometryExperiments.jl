struct PinholeCamera{O<:KVector{1},P<:KVector{3}}
  optical_center::O
  image_plane::P
end

function PinholeCamera(O, A₁, A₂, A₃)
  n = dimension_from_points(O, A₁, A₂, A₃)
  @assert n == 3
  PinholeCamera(@pga3(point(O)), @pga3 point(A₁) ∧ point(A₂) ∧ point(A₃))
end

function (camera::PinholeCamera)(x::T) where {T}
  @assert length(x) == 3
  T(euclidean(@pga3 (point(x) ∧ camera.optical_center::Vector) ∨ camera.image_plane::Trivector))
end
