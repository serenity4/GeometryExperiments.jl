"""
A vector type which can have items deleted without modifying indices of other values.

Features include:
- No hashing is ever performed to access its contents.
- The underlying buffer is contiguous in memory.
- No allocations occur when retrieving elements by indices from that container or when iterating on the whole container.
- Elements can be deleted from the container without having to worry about indices of other elements being shifted.

It is furthermore optimized to reuse indices of previously deleted elements when the number of deleted elements is greater than
the number of live elements in the collection. For this reason, `push!` is O(n/2) in the worst case scenario (which should *very* rarely happen).

Note that buffer slots are never deleted by purpose, except with `empty!`. Therefore, if the container grows then shrinks logically, memory won't be freed automatically.
In this case, you must `empty!` the container manually or build another one.
"""
struct GranularVector{T,V<:AbstractVector{Union{Nothing,T}}} <: AbstractVector{T}
  vec::V
  nothing_count::Base.RefValue{Int}
  current_hole::Base.RefValue{Int}
  granularity::Float64
end

const DEFAULT_GRANULARITY = 0.5

GranularVector{T,V}(vec::V, granularity = DEFAULT_GRANULARITY) where {T,V} = GranularVector(vec, Ref(count(isnothing, vec)), Ref(0), granularity)
GranularVector(vec::AbstractVector{Union{T,Nothing}}, granularity = DEFAULT_GRANULARITY) where {T} = GranularVector{T,typeof(vec)}(vec, granularity)
GranularVector(vec::AbstractVector{T}; granularity = DEFAULT_GRANULARITY) where {T} =
  GranularVector(convert(Vector{Union{Nothing,T}}, vec), granularity)
GranularVector{T}(; granularity = DEFAULT_GRANULARITY) where {T} = GranularVector(T[]; granularity)

Base.eltype(::Type{<:GranularVector{T}}) where {T} = T

@inline Base.getindex(gvec::GranularVector{T}, i) where {T} = getindex(gvec.vec, i)::T

function Base.setindex!(gvec::GranularVector, val, i) where {T}
  was_nothing = isnothing(gvec.vec[i])
  gvec.vec[i] = val
  if was_nothing
    gvec.nothing_count[] -= 1
  end
  gvec
end

Base.eachindex(gvec::GranularVector) = Iterators.Filter(i -> !isnothing(gvec.vec[i]), eachindex(gvec.vec))

function Base.deleteat!(gvec::GranularVector, i)
  isnothing(gvec.vec[i]) && return gvec
  gvec.vec[i] = nothing
  gvec.nothing_count[] += 1
  gvec
end

function Base.empty!(gvec::GranularVector)
  empty!(gvec.vec)
  gvec.nothing_count[] = 0
  gvec.current_hole[] = 0
  gvec
end

Base.length(gvec::GranularVector) = length(gvec.vec) - gvec.nothing_count[]
Base.size(gvec::GranularVector) = (length(gvec),)

function Base.push!(gvec::GranularVector, item)
  if gvec.nothing_count[] < gvec.granularity * length(gvec.vec)
    push!(gvec.vec, item)
  else
    i = next_hole!(gvec)
    @inbounds gvec.vec[i] = item
    gvec.nothing_count[] -= 1
  end
  gvec
end

function Base.push!(gvec::GranularVector, item, items...)
  push!(gvec, item)
  for item in items
    push!(gvec, item)
  end
  gvec
end

Base.append!(gvec::GranularVector, items) = foldl(push!, items; init = gvec)

function next_hole!(gvec::GranularVector)
  @assert !iszero(gvec.nothing_count[]) || isempty(gvec)
  gvec.current_hole[] += 1
  for i in gvec.current_hole[]:lastindex(gvec.vec)
    if isnothing(@inbounds gvec.vec[i])
      gvec.current_hole[] = i
      return i
    end
  end

  # Give up and create an artifical "hole" at the end of the vector.
  gvec.current_hole[] = 0
  push!(gvec.vec, nothing)
  gvec.nothing_count[] += 1
  lastindex(gvec.vec)
end

function Base.iterate(gvec::GranularVector)
  for i in eachindex(gvec.vec)
    @inbounds val = gvec.vec[i]
    !isnothing(val) && return (val, i + 1)
  end
end

function Base.iterate(gvec::GranularVector, state::Integer)
  for i in state:lastindex(gvec.vec)
    @inbounds val = gvec.vec[i]
    !isnothing(val) && return (val, i + 1)
  end
end

function Base.show(io::IO, ::MIME"text/plain", gvec::GranularVector)
  print(io, typeof(gvec))
  n = length(gvec)
  if n > 100
    print(io, "($n elements)")
  else
    print(io, "([", join(collect(gvec), ", "), "])")
  end
end
