@struct_isapprox struct Translation{Dim,T} <: Transformation
  vec::Point{Dim,T}
end
Translation{T}(vals::T...) where {T} = Translation(Point{length(vals),T}(vals))
Translation{T}(vals...) where {T} = Translation{T}(convert.(T, vals)...)
Translation(vals::T...) where {T} = Translation(Point{length(vals),T}(vals))
Translation(vec::AbstractVector) = Translation(Point{length(vec),eltype(vec)}(vec))
(t::Translation)(p::AbstractVector) = t.vec + p
(t::Translation{Dim})(x::Number) where {Dim} = t(@SVector fill(x, Dim))

Base.:∘(t1::Translation, t2::Translation) = Translation(t1.vec .+ t2.vec)

rand(rng::AbstractRNG, ::SamplerType{Translation{Dim}}) where {Dim} = rand(rng, Translation{Dim,Float64})
rand(rng::AbstractRNG, ::SamplerType{Translation{Dim,T}}) where {Dim,T} = Translation(rand(rng, SVector{Dim,T}))

Translation{Dim,T}() where {Dim,T} = Translation{Dim,T}(@SVector zeros(T, Dim))
Base.inv(tr::Translation) = Translation(-tr.vec)
Base.zero(::Type{Translation{Dim,T}}) where {Dim,T} = Translation{Dim,T}()

const Translated{O,Dim,T} = Transformed{O,Translation{Dim,T}}
Translated(obj::O, transf::Translation{Dim,T}) where {O,Dim,T} = Translated{O,Dim,T}(obj, transf)

apply_translation(p, translation::Translation) = translation(p)

Base.convert(::Type{Translation{Dim,T}}, tr::Translation{Dim}) where {Dim,T} = Translation(convert(Point{Dim,T}, tr.vec))
