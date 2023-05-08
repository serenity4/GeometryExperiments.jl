struct Vertex{L<:AbstractVector,T}
  location::L
  data::T
end

location(vertex::Vertex) = vertex.location

Vertex(location) = Vertex(location, nothing)

struct TriangleMesh{I,VT,L,V<:AbstractVector{Vertex{L,VT}}}
  indices::TriangleList{I}
  vertices::V
end

TriangleMesh(encoding::Union{TriangleStrip,TriangleFan}, vertices::AbstractVector{<:Vertex}) = TriangleMesh(TriangleList(encoding), vertices)
TriangleMesh(encoding, set::PointSet) = TriangleMesh(encoding, Vertex.(set.points))

vertices(mesh::TriangleMesh) = mesh.vertices
