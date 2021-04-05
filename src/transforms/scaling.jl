struct Scaling{Dim,T} <: Transform{T}
  vec::Vec{Dim,T}
end
Scaling(vals::T...) where {T} = Scaling(Vec{length(vals),T}(vals))
Scaling(vec::AbstractVector) where {Dim,T} = Scaling(Vec{length(vec),eltype(vec)}(vals))
(s::Scaling)(p::Vec) = s.vec * p

Base.inv(s::Scaling) = typeof(s)(inv.(s.vec))

const Scaled{O,Dim,T} = Transformed{O,Scaling{Dim,T}}
Scaled(obj::O, transf::Scaling{Dim,T}) where {O,Dim,T} = Scaled{O,Dim,T}(obj, transf)
