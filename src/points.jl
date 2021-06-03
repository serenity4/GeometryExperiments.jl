struct Point{Dim,T}
    vec::SVector{Dim,T}
end

Point(val::Real...) = Point(collect(val))
_coordtype(::Type{Point{Dim,T}}) where {Dim,T} = SVector{Dim,T}

for op in (:+, :-, :/)
    @eval Base.$op(x::Point, y::Point) = Point($op(x.vec, y.vec))
end

Base.:*(x::Point, y::Point) = Point(x.vec .* y.vec)

Base.zero(T::Type{<:Point}, args...; kwargs...) = T(zero(_coordtype(T), args...; kwargs...))
Base.eltype(T::Type{<:Point}) = eltype(_coordtype(T))

P2 = Point{2,Float64}
P2I = Point{2,Int}

p1 = P2((1., 2.))
p2 = P2I((1, 3))

"""
Return all corners of the box.
"""
@generated function vertices(b::Box{Dim,T}) where {Dim,T}
  list = CartesianIndices(ntuple(i -> iseven(i) ? (1:2) : reverse(1:2), Dim))
  tuples = map(list) do idxs
    coords = map(1:Dim) do i
      point = idxs[i] == 1 ? :A : :B
      :($point[$i])
    end
    Expr(:tuple, coords...)
  end
  quote
    A, B = coordinates(b.min), coordinates(b.max)
    Point{$Dim,$T}[$(tuples...)]
  end
end
