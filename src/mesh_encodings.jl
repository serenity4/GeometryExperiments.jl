abstract type TriangleMeshEncoding end

struct TriangleStrip{I} <: TriangleMeshEncoding
    indices::I
end

struct TriangleFan{I} <: TriangleMeshEncoding
    indices::I
end

@auto_hash_equals struct TriangleList <: TriangleMeshEncoding
    indices::Vector{SVector{3,Int}}
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
