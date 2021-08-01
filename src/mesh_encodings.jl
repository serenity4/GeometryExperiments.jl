abstract type IndexEncoding end

abstract type TopologyClass end

struct Line <: TopologyClass end
struct Triangle <: TopologyClass end

parametric_dimension(::Type{Line}) = 2
parametric_dimension(::Type{Triangle}) = 3

struct Strip{C<:TopologyClass,I} <: IndexEncoding
    indices::I
end

Strip{C}(indices) where {C} = Strip{C,typeof(indices)}(indices)

const LineStrip = Strip{Line}
const TriangleStrip = Strip{Triangle}

struct Fan{C<:TopologyClass,I} <: IndexEncoding
    indices::I
end

Fan{C}(indices) where {C} = Fan{C,typeof(indices)}(indices)

const TriangleFan = Fan{Triangle}

@auto_hash_equals struct IndexList{C<:TopologyClass,Dim} <: IndexEncoding
    indices::Vector{SVector{Dim,Int}}
end

const LineList = IndexList{Line}
const TriangleList = IndexList{Triangle}

function IndexList{C}(indices) where {C<:TopologyClass}
    IndexList{C,parametric_dimension(C)}(indices)
end

function TriangleList(encoding::TriangleFan)
    indices = encoding.indices
    origin = first(indices)
    list = map(2:lastindex(indices) - 1) do i
        SVector(origin, indices[i], indices[i + 1])
    end
    TriangleList(list)
end

function TriangleList(encoding::TriangleStrip)
    indices = encoding.indices
    list = map(1:lastindex(indices) - 2) do i
        SVector(indices[i], indices[i + 1 + (i - 1) % 2], indices[i + 2 - (i - 1) % 2])
    end
    TriangleList(list)
end

function LineList(encoding::LineStrip)
    indices = encoding.indices
    LineList([SVector(indices[i], indices[i+1]) for i in 1:length(indices) - 1])
end
