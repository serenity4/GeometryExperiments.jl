struct Translation{Dim,T} <: Transform{T}
  vec::Point{Dim,T}
end
Translation(vals::T...) where {T} = Translation(Point{length(vals),T}(vals))
Translation(vec::AbstractVector) where {Dim,T} = Translation(Point{length(vec),eltype(vec)}(vals))
(t::Translation)(p) = t.vec + p

Base.:∘(t1::Translation, t2::Translation) = Translation(t1.vec .+ t2.vec)

(≈)(x::Translation, y::Translation) = x.vec ≈ y.vec

inv(tr::Translation) = Translation(-tr.vec)

const Translated{O,Dim,T} = Transformed{O,Translation{Dim,T}}
Translated(obj::O, transf::Translation{Dim,T}) where {O,Dim,T} = Translated{O,Dim,T}(obj, transf)
