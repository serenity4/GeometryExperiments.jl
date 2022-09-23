struct PackedAttribute{T,A}
  element::T
  attribute::A
end

vertex_attribute(packed::PackedAttribute{MeshVertex}) = packed.attribute
edge_attribute(packed::PackedAttribute{MeshEdge}) = packed.attribute
face_attribute(packed::PackedAttribute{MeshFace}) = packed.attribute

mesh_vertex(packed::PackedAttribute{MeshVertex}) = packed.element
mesh_edge(packed::PackedAttribute{MeshEdge}) = packed.element
mesh_face(packed::PackedAttribute{MeshFace}) = packed.element

index(packed::PackedAttribute) = index(packed.element)
src(packed::PackedAttribute{MeshEdge}) = src(packed.element)
dst(packed::PackedAttribute{MeshEdge}) = dst(packed.element)
face_edges(packed::PackedAttribute{MeshFace}) = face_edges(packed.element)

function Base.show(io::IO, ::MIME"text/plain", attr::PackedAttribute)
  print(io, attr.element)
  printstyled(io, " => ", attr.attribute; color = isnothing(attr.attribute) ? :light_black : :magenta)
end

vertex_attribute(::Any) = nothing
edge_attribute(::Any) = nothing
face_attribute(::Any) = nothing

vertex_attribute(v::Point) = v

location(mesh::Mesh, vertex::MeshVertex) = location(mesh.vertex_attributes[vertex.index])
location(p::Point) = p

centroid(mesh::Mesh, edge::MeshEdge) = centroid(location(mesh, mesh.vertices[edge.src]), location(mesh, mesh.vertices[edge.dst]))
centroid(mesh::Mesh, face::MeshFace) = centroid((location(mesh, vertex) for vertex in vertices(mesh, face)))
centroid(mesh::Mesh) = centroid((location(mesh, vertex) for vertex in vertices(mesh)))
