struct PackedAttribute{T,A}
  element::T
  attribute::A
end

vertex_attribute(packed::PackedAttribute{MeshVertex}) = packed.attribute
edge_attribute(packed::PackedAttribute{MeshEdge}) = packed.attribute
face_attribute(packed::PackedAttribute{MeshFace}) = packed.attribute

mesh_vertex(::Mesh, packed::PackedAttribute{MeshVertex}) = packed.element
mesh_edge(::Mesh, packed::PackedAttribute{MeshEdge}) = packed.element
mesh_face(::Mesh, packed::PackedAttribute{MeshFace}) = packed.element

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

"Describe how vertex normals should be computed for a given mesh."
abstract type SmoothingStrategy end

# XXX
struct SmoothingAuto <: SmoothingStrategy
  angle::Float64
end

"Angle between `(O,x)` and `(O, y)` with `O` the origin of the Euclidean space."
angle(x::Point, y::Point) = atan(x × y, x ⋅ y)

"Compute vertex normals for a triangle mesh."
function compute_vertex_normals(mesh::Mesh, smoothing = SmoothingAuto(0))
  normals = Point3[]
  for vertex in vertices(mesh)
    value = zero(Point3)
    for face in faces(mesh, vertex)
      p₁, p₂, p₃ = (location(mesh, vertex) for vertex in vertices(mesh, face))
      u, v = p₂ - p₁, p₃ - p₁
      # FIXME: This is not correct.
      if abs(angle(u, v)) > deg2rad(smoothing.angle)
        value = value .+ u × v
      end
    end
    push!(normals, normalize(value))
  end
  normals
end
