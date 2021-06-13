struct Scaling{Dim,T} <: Transform{T}
  vec::Point{Dim,T}
end
Scaling(vals::T...) where {T} = Scaling(Point{length(vals),T}(vals))
Scaling(vec::AbstractVector) where {Dim,T} = Scaling(Point{length(vec),eltype(vec)}(vec))
(s::Scaling)(p::AbstractVector) = s.vec .* p

Base.:∘(t1::Scaling, t2::Scaling) = Scaling(t1.vec .* t2.vec)

(≈)(x::Scaling, y::Scaling) = x.vec ≈ y.vec

inv(s::Scaling) = Scaling(inv.(s.vec))

const Scaled{O,Dim,T} = Transformed{O,Scaling{Dim,T}}
Scaled(obj::O, transf::Scaling{Dim,T}) where {O,Dim,T} = Scaled{O,Dim,T}(obj, transf)

Base.show(io::IO, s::Scaled{O,Dim,T}) where {O,Dim,T} = print(io, "Scaled{$O, $Dim, $T}($(s.obj), $(s.transf))")
