@struct_isapprox struct Scaling{Dim,T} <: Transformation
  vec::Point{Dim,T}
end
Scaling(vals::T...) where {T} = Scaling(Point{length(vals),T}(vals))
Scaling(vec::AbstractVector) = Scaling(Point{length(vec),eltype(vec)}(vec))
(s::Scaling)(p::AbstractVector) = s.vec .* p
(s::Scaling{Dim})(x::Number) where {Dim} = s(@SVector fill(x, Dim))
LinearAlgebra.norm(s::Scaling) = norm(s.vec)
LinearAlgebra.normalize(s::Scaling) = Scaling(normalize(s.vec))

Base.:(∘)(t1::Scaling, t2::Scaling) = Scaling(t1.vec .* t2.vec)

rand(rng::AbstractRNG, ::SamplerType{Scaling{Dim}}) where {Dim} = rand(rng, Scaling{Dim,Float64})
rand(rng::AbstractRNG, ::SamplerType{Scaling{Dim,T}}) where {Dim,T} = Scaling(rand(rng, SVector{Dim,T}))

Scaling{Dim,T}() where {Dim,T} = Scaling{Dim,T}(@SVector ones(T, Dim))
Base.inv(s::Scaling) = Scaling(inv.(s.vec))
Base.one(::Type{Scaling{Dim,T}}) where {Dim,T} = Scaling{Dim,T}()

const Scaled{O,Dim,T} = Transformed{O,Scaling{Dim,T}}
Scaled(obj::O, transf::Scaling{Dim,T}) where {O,Dim,T} = Scaled{O,Dim,T}(obj, transf)

Base.show(io::IO, s::Scaled{O,Dim,T}) where {O,Dim,T} = print(io, "Scaled{$O, $Dim, $T}($(s.obj), $(s.transf))")

struct UniformScaling{T} <: Transformation
  factor::T
end
(s::UniformScaling)(p::AbstractVector) = s.factor .* p

Base.:(∘)(t1::UniformScaling, t2::UniformScaling) = UniformScaling(t1.factor * t2.factor)

Base.inv(s::UniformScaling) = UniformScaling(inv(s.factor))
Base.one(::Type{UniformScaling{T}}) where {T} = UniformScaling(one(T))

apply_scaling(p, scaling::Union{Scaling,UniformScaling}) = scaling(p)

Base.convert(::Type{Scaling{Dim,T}}, sc::Scaling{Dim}) where {Dim,T} = Scaling(convert(Point{Dim,T}, sc.vec))
