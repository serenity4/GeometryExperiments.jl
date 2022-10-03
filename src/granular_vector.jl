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
struct GranularVector{T,V<:AbstractVector{Union{Nothing,T}}}
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

@inline function Base.getindex(gvec::GranularVector{T}, i) where {T}
  val = getindex(gvec.vec, i)
  !isnothing(val) || error("Index $i not assigned in $gvec")
  val
end

inrange(gvec::GranularVector, index) = in(index, first(axes(gvec.vec)))
isdefined(gvec::GranularVector, index) = !isnothing(gvec.vec[index])
Base.isassigned(gvec::GranularVector, index::Integer) = inrange(gvec, index) && isdefined(gvec, index)

function Base.setindex!(gvec::GranularVector, val, i)
  was_nothing = !isdefined(gvec, i)
  gvec.vec[i] = val
  if was_nothing
    gvec.nothing_count[] -= 1
  end
  gvec
end

Base.eachindex(gvec::GranularVector) = Iterators.Filter(i -> !isnothing(gvec.vec[i]), eachindex(gvec.vec))

function Base.deleteat!(gvec::GranularVector, i)
  !isdefined(gvec, i) && return gvec
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

nextind!(gvec::GranularVector) = iszero(gvec.nothing_count[]) ? lastindex(gvec.vec) + 1 : next_hole!(gvec)

function Base.insert!(gvec::GranularVector, index, item)
  if inrange(gvec, index)
    !isdefined(gvec, index) || error("Index $index has already been assigned")
    gvec[index] = item
  else
    grow_insert!(gvec, index, item)
  end
end

function Base.resize!(gvec::GranularVector, n)
  nl = lastindex(gvec.vec)
  resize!(gvec.vec, n)
  gvec.nothing_count[] += n - nl
  for i in (nl + 1):n
    @inbounds gvec.vec[i] = nothing
  end
  gvec
end

function grow_insert!(gvec::GranularVector, index, item)
  n = lastindex(gvec.vec)
  if index == n + 1
    push!(gvec.vec, item)
  else
    resize!(gvec, index)
    gvec[index] = item
  end
end

function Dictionaries.set!(gvec::GranularVector, index, item)
  if isassigned(gvec, index)
    gvec[index] = item
  else
    insert!(gvec, index, item)
  end
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

struct GranularVectorView{GV<:GranularVector,I}
  parent::GV
  indices::I
end

Base.getindex(gview::GranularVectorView, index) = getindex(gview.parent, gview.indices[index])
Base.setindex!(gview::GranularVectorView, value, index) = setindex!(gview.parent, value, gview.indices[index])

function Base.iterate(gview::GranularVectorView, i::Integer = 1)
  i > length(gview.indices) && return nothing
  index = gview.indices[i]
  isdefined(gview.parent, index) || return iterate(gview, i + 1)
  (gview.parent[index], i + 1)
end

# The size is unknown because we force views to ignore any undefined values,
# which may have been made undefined after the view was created.
Base.IteratorSize(::Type{<:GranularVectorView}) = Iterators.SizeUnknown()
Base.eltype(gview::GranularVectorView) = eltype(gview.parent)

Base.view(gvec::GranularVector, indices) = GranularVectorView(gvec, indices)

function Base.show(io::IO, ::MIME"text/plain", gvec::GranularVector)
  print(io, typeof(gvec))
  n = length(gvec)
  if n > 100
    print(io, "($n elements)")
  else
    print(io, "([", join(collect(gvec), ", "), "])")
  end
end
