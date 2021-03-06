abstract type IndexEncoding end

Base.eltype(encoding::IndexEncoding) = eltype(encoding.indices)
Base.collect(encoding::IndexEncoding) = collect(encoding.indices)

abstract type PrimitiveTopology end

struct LinePrimitive <: PrimitiveTopology end
struct TrianglePrimitive <: PrimitiveTopology end

parametric_dimension(::Type{LinePrimitive}) = 2
parametric_dimension(::Type{TrianglePrimitive}) = 3

struct Strip{C<:PrimitiveTopology,I} <: IndexEncoding
  indices::I
end

primitive_topology(::Type{<:Strip{C}}) where {C} = C

Strip{C}(indices) where {C} = Strip{C,typeof(indices)}(indices)

const LineStrip = Strip{LinePrimitive}
const TriangleStrip = Strip{TrianglePrimitive}

struct Fan{C<:PrimitiveTopology,I} <: IndexEncoding
  indices::I
end

primitive_topology(::Type{<:Fan{C}}) where {C} = C

Fan{C}(indices) where {C} = Fan{C,typeof(indices)}(indices)

const TriangleFan = Fan{TrianglePrimitive}

@auto_hash_equals struct IndexList{C<:PrimitiveTopology,Dim,T} <: IndexEncoding
  indices::Vector{SVector{Dim,T}}
end

primitive_topology(::Type{<:IndexList{C}}) where {C} = C

const LineList = IndexList{LinePrimitive}
const TriangleList = IndexList{TrianglePrimitive}

function IndexList{C}(indices) where {C<:PrimitiveTopology}
  IndexList{C,parametric_dimension(C),eltype(eltype(indices))}(indices)
end

function TriangleList(encoding::TriangleFan, T = Int)
  indices = encoding.indices
  origin = first(indices)
  list = map(2:(lastindex(indices) - 1)) do i
    SVector{3,T}(origin, indices[i], indices[i + 1])
  end
  TriangleList(list)
end

function TriangleList(encoding::TriangleStrip, T = Int)
  indices = encoding.indices
  list = map(1:(lastindex(indices) - 2)) do i
    SVector{3,T}(indices[i], indices[i + 1 + (i - 1) % 2], indices[i + 2 - (i - 1) % 2])
  end
  TriangleList(list)
end

function LineList(encoding::LineStrip, T = Int)
  indices = encoding.indices
  LineList([SVector{2,T}(indices[i], indices[i + 1]) for i in 1:(length(indices) - 1)])
end

"""
Mesh represented with vertex and index data.
"""
struct VertexMesh{I<:IndexEncoding,T}
  indices::I
  vertex_data::Vector{T}
end

VertexMesh(vertex_data, ::Type{C}) where {C<:PrimitiveTopology} = VertexMesh(Strip{C}(1:length(vertex_data)), vertex_data)

function VertexMesh(encoding::IndexEncoding, vertex_data)
  VertexMesh{typeof(encoding),eltype(vertex_data)}(encoding, vertex_data)
end
