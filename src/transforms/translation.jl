struct Translation{Dim,T} <: Transformation
  vec::Point{Dim,T}
end
Translation(vals::T...) where {T} = Translation(Point{length(vals),T}(vals))
Translation(vec::AbstractVector) = Translation(Point{length(vec),eltype(vec)}(vals))
(t::Translation)(p::AbstractVector) = t.vec + p
(t::Translation{Dim})(x::Number) where {Dim} = t(@SVector fill(x, Dim))

Base.:∘(t1::Translation, t2::Translation) = Translation(t1.vec .+ t2.vec)

Base.isapprox(x::Translation, y::Translation) = x.vec ≈ y.vec

Base.inv(tr::Translation) = Translation(-tr.vec)
Base.zero(::Type{Translation{Dim,T}}) where {Dim,T} = Translation(@SVector zeros(T, Dim))

const Translated{O,Dim,T} = Transformed{O,Translation{Dim,T}}
Translated(obj::O, transf::Translation{Dim,T}) where {O,Dim,T} = Translated{O,Dim,T}(obj, transf)

apply_translation(p::Point, translation::Translation) = translation(p)

Base.convert(::Type{Translation{Dim,T}}, tr::Translation{Dim}) where {Dim,T} = Translation(convert(Point{Dim,T}, tr.vec))
