abstract type Transform{T} end

struct Transformed{O,TR<:Transform}
  obj::O
  transf::TR
  Transformed{O,TR}(obj::O, args...) where {O,TR} = Transformed{O,TR}(obj, TR(args...))
  Transformed{O,TR}(obj::O, transf::TR) where {O,TR} = new{O,TR}(obj, transf)
  Transformed(obj::O, transf::TR) where {O,TR} = Transformed{O,TR}(obj, transf)
end

include("transforms/scaling.jl")
include("transforms/translation.jl")
include("transforms/rotation.jl")

can_apply(::Type{<:Transform}, ::Type{<:Any}) = false
apply(t::Rotation, obj) = error("Cannot apply transformation $t to $obj.")

can_apply(::Type{<:Translation}, ::Type{<:Translation}) = true
apply(t1::T, t2::T) where {T<:Translation} = T(t2(t1.vec))

struct ComposedTransform{T1<:Transform,T2<:Transform}
  t1::T1
  t2::T2
end

(t::ComposedTransform)(p) = t.t2(t.t1(p))

Base.inv(t::ComposedTransform) = ComposedTransform(inv(t.t2), inv(t.t1))
