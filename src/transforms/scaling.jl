struct Scaling{Dim,T} <: Transform
  vec::Point{Dim,T}
end
Scaling(vals::T...) where {T} = Scaling(Point{length(vals),T}(vals))
Scaling(vec::AbstractVector) where {Dim,T} = Scaling(Point{length(vec),eltype(vec)}(vec))
(s::Scaling)(p::AbstractVector) = s.vec .* p
(s::Scaling{Dim})(x::Number) where {Dim} = s(@SVector fill(x, Dim))

Base.:(∘)(t1::Scaling, t2::Scaling) = Scaling(t1.vec .* t2.vec)

Base.isapprox(x::Scaling, y::Scaling) = x.vec ≈ y.vec

Base.inv(s::Scaling) = Scaling(inv.(s.vec))
Base.identity(::Type{Scaling{Dim,T}}) where {Dim,T} = Scaling(@SVector ones(T, Dim))

const Scaled{O,Dim,T} = Transformed{O,Scaling{Dim,T}}
Scaled(obj::O, transf::Scaling{Dim,T}) where {O,Dim,T} = Scaled{O,Dim,T}(obj, transf)

Base.show(io::IO, s::Scaled{O,Dim,T}) where {O,Dim,T} = print(io, "Scaled{$O, $Dim, $T}($(s.obj), $(s.transf))")

struct UniformScaling{T} <: Transform
  factor::T
end
(s::UniformScaling)(p::AbstractVector) = s.factor .* p

Base.:(∘)(t1::UniformScaling, t2::UniformScaling) = UniformScaling(t1.factor * t2.factor)

Base.inv(s::UniformScaling) = UniformScaling(inv(s.factor))
Base.identity(::Type{UniformScaling{T}}) where {T} = UniformScaling(one(T))
