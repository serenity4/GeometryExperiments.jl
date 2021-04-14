abstract type Transform{T} end

Base.broadcastable(tr::Transform) = Ref(tr)

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

AbstractTrees.children(tr::ComposedTransform) = (tr.t1, tr.t2)

transforms(tr::ComposedTransform) = Leaves(tr)

Base.:∘(t1::Transform, t2::Transform) = ComposedTransform(t1, t2)

inv(t::ComposedTransform) = inv(t.t1) ∘ inv(t.t2)

struct Transformed{O,TR<:Transform}
  obj::O
  transf::TR
  Transformed{O,TR}(obj::O, args...) where {O,TR} = Transformed{O,TR}(obj, TR(args...))
  Transformed{O,TR}(obj::O, transf::TR) where {O,TR} = new{O,TR}(obj, transf)
  Transformed(obj::TR1, transf::TR2) where {TR1<:Transformed,TR2<:Transform} = Transformed(obj.obj, transf ∘ obj.transf)
  Transformed(obj::O, transf::TR) where {O,TR} = Transformed{O,TR}(obj, transf)
end
(tr::Transformed)(p) = tr.obj(inv(tr.transf)(p))

include("transforms/scaling.jl")
include("transforms/translation.jl")
include("transforms/rotation.jl")
