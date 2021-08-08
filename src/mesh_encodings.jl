abstract type IndexEncoding end

Base.eltype(encoding::IndexEncoding) = eltype(encoding.indices)
Base.collect(encoding::IndexEncoding) = collect(encoding.indices)

abstract type TopologyClass end

struct Line <: TopologyClass end
struct Triangle <: TopologyClass end

parametric_dimension(::Type{Line}) = 2
parametric_dimension(::Type{Triangle}) = 3

struct Strip{C<:TopologyClass,I} <: IndexEncoding
    indices::I
end

topology_class(::Type{<:Strip{C}}) where {C} = C

Strip{C}(indices) where {C} = Strip{C,typeof(indices)}(indices)

const LineStrip = Strip{Line}
const TriangleStrip = Strip{Triangle}

struct Fan{C<:TopologyClass,I} <: IndexEncoding
    indices::I
end

topology_class(::Type{<:Fan{C}}) where {C} = C

Fan{C}(indices) where {C} = Fan{C,typeof(indices)}(indices)

const TriangleFan = Fan{Triangle}

@auto_hash_equals struct IndexList{C<:TopologyClass,Dim,T} <: IndexEncoding
    indices::Vector{SVector{Dim,T}}
end

topology_class(::Type{<:IndexList{C}}) where {C} = C

const LineList = IndexList{Line}
const TriangleList = IndexList{Triangle}

function IndexList{C}(indices) where {C<:TopologyClass}
    IndexList{C,parametric_dimension(C),eltype(eltype(indices))}(indices)
end

function TriangleList(encoding::TriangleFan, T=Int)
    indices = encoding.indices
    origin = first(indices)
    list = map(2:lastindex(indices) - 1) do i
        SVector{3,T}(origin, indices[i], indices[i + 1])
    end
    TriangleList(list)
end

function TriangleList(encoding::TriangleStrip, T=Int)
    indices = encoding.indices
    list = map(1:lastindex(indices) - 2) do i
        SVector{3,T}(indices[i], indices[i + 1 + (i - 1) % 2], indices[i + 2 - (i - 1) % 2])
    end
    TriangleList(list)
end

function LineList(encoding::LineStrip, T=Int)
    indices = encoding.indices
    LineList([SVector{2,T}(indices[i], indices[i+1]) for i in 1:length(indices) - 1])
end

abstract type MeshEncoding end

"""
Mesh encoded by vertex data and vertex indices.
"""
struct MeshVertexEncoding{I<:IndexEncoding,T}
    encoding::I
    vertex_data::Vector{T}
end

MeshVertexEncoding(vertex_data, ::Type{C}) where {C<:TopologyClass} = MeshVertexEncoding(Strip{C}(1:length(vertex_data)), vertex_data)

function MeshVertexEncoding(encoding::IndexEncoding, vertex_data)
    MeshVertexEncoding{typeof(encoding),eltype(vertex_data)}(encoding, vertex_data)
end
