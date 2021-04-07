abstract type Transform{T} end

struct IdentityTransform{T} <: Transform{T} end

Base.identity(::Type{<:Transform{T}}) where {T} = IdentityTransform{T}()

struct ComposedTransform{T,TR1<:Transform{T},TR2<:Transform{T}} <: Transform{T}
  """
  Inner transform.
  """
  t1::TR1
  """
  Outer transform.
  """
  t2::TR2
end
(t::ComposedTransform)(p) = t.t2(t.t1(p))

collapse(t::ComposedTransform) = foldl(collapse, maybe_apply(t), init=identity(typeof(t)))

can_apply(::Type{<:IdentityTransform}, ::Type{<:Transform}) = true
apply(::IdentityTransform, tr::Transform) = tr
can_apply(::Type{<:Transform}, ::Type{<:IdentityTransform}) = true
apply(tr::Transform, ::IdentityTransform) = tr

inv(t::ComposedTransform) = ComposedTransform(inv(t.t2), inv(t.t1))

struct Transformed{O,TR<:Transform}
  obj::O
  transf::TR
  Transformed{O,TR}(obj::O, args...) where {O,TR} = Transformed{O,TR}(obj, TR(args...))
  Transformed{O,TR}(obj::O, transf::TR) where {O,TR} = new{O,TR}(obj, transf)
  Transformed(obj::TR1, transf::TR2) where {TR1<:Transformed,TR2<:Transform} = Transformed(obj.obj, ComposedTransform(transf, obj.transf))
  Transformed(obj::O, transf::TR) where {O,TR} = Transformed{O,TR}(obj, transf)
end
(tr::Transformed)(p) = tr.obj(inv(tr.transf)(p))

maybe_apply(tr::ComposedTransform{TR1,TR2}) where {TR1,TR2} = can_apply(TR1, TR2) ? apply(tr.t1, tr.t2) : tr

include("transforms/scaling.jl")
include("transforms/translation.jl")
include("transforms/rotation.jl")

can_apply(::Type{<:Transform}, ::Type{<:Any}) = false
apply(t::Rotation, obj) = error("Cannot apply transformation $t to $obj.")

can_apply(::Type{<:Translation}, ::Type{<:Translation}) = true
apply(t1::T, t2::T) where {T<:Translation} = T(t2(t1.vec))
