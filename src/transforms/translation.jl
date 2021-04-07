struct Translation{Dim,T} <: Transform{T}
  vec::Vec{Dim,T}
end
Translation(vals::T...) where {T} = Translation(Vec{length(vals),T}(vals))
Translation(vec::AbstractVector) where {Dim,T} = Translation(Vec{length(vec),eltype(vec)}(vals))
(t::Translation)(p) = t.vec + p

inv(tr::Translation) = Translation(-tr.vec)

const Translated{O,Dim,T} = Transformed{O,Translation{Dim,T}}
Translated(obj::O, transf::Translation{Dim,T}) where {O,Dim,T} = Translated{O,Dim,T}(obj, transf)
