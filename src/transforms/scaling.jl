struct Scaling{Dim,T} <: Transform{T}
  vec::Vec{Dim,T}
end
Scaling(vals::T...) where {T} = Scaling(Vec{length(vals),T}(vals))
Scaling(vec::AbstractVector) where {Dim,T} = Scaling(Vec{length(vec),eltype(vec)}(vals))
(s::Scaling)(p) = s.vec * p

# type piracy; to add in Meshes
Base.:*(x::Vec{Dim,T}, y::Point{Dim,T}) where {Dim,T} = typeof(y)(x .* coordinates(y))

inv(s::Scaling) = Scaling(inv.(s.vec))

const Scaled{O,Dim,T} = Transformed{O,Scaling{Dim,T}}
Scaled(obj::O, transf::Scaling{Dim,T}) where {O,Dim,T} = Scaled{O,Dim,T}(obj, transf)
