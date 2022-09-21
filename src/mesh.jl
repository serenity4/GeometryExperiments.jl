const VertexIndex = Int
const EdgeIndex = Int
const FaceIndex = Int

struct MeshVertex
  index::VertexIndex
  edges::Vector{EdgeIndex}
end
MeshVertex(index::VertexIndex) = MeshVertex(index, EdgeIndex[])

struct MeshEdge
  index::EdgeIndex
  src::VertexIndex
  dst::VertexIndex
  faces::Vector{FaceIndex}
end
MeshEdge(index::EdgeIndex, src::VertexIndex, dst::VertexIndex) = MeshEdge(index, src, dst, FaceIndex[])

struct MeshFace
  index::FaceIndex
  edges::Vector{EdgeIndex}
end

struct Mesh{VT,ET,FT}
  vertices::Vector{Optional{MeshVertex}}
  edges::Vector{Optional{MeshEdge}}
  faces::Vector{Optional{MeshFace}}
  # Use a dictionary to allow holes in indices.
  vertex_attributes::Dict{VertexIndex,VT}
  edge_attributes::Dict{EdgeIndex,ET}
  face_attributes::Dict{FaceIndex,FT}
  Mesh{VT,ET,FT}() where {VT,ET,FT} =
    new{VT,ET,FT}(MeshVertex[], MeshEdge[], MeshFace[], Dict{VertexIndex,VT}(), Dict{EdgeIndex,ET}(), Dict{FaceIndex,FT}())
end

function get_vertex(mesh::Mesh, index::VertexIndex)
  x = mesh.vertices[index]
  !isnothing(x) || error("Vertex $index not found")
  x
end

function get_edge(mesh::Mesh, index::EdgeIndex)
  x = mesh.edges[index]
  !isnothing(x) || error("Edge $index not found")
  x
end

function get_face(mesh::Mesh, index::FaceIndex)
  x = mesh.faces[index]
  !isnothing(x) || error("Face $index not found")
  x
end

edges(mesh::Mesh, vertex::MeshVertex) = @view mesh.edges[vertex.edges]
edges(mesh::Mesh, face::MeshFace) = @view mesh.edges[face.edges]
faces(mesh::Mesh, edge::MeshEdge) = @view mesh.faces[edge.faces]

function vertices(mesh::Mesh)
  vertices = MeshVertex[]
  for vertex in mesh.vertices
    !isnothing(vertex) && push!(vertices, vertex)
  end
  vertices
end

function edges(mesh::Mesh)
  edges = MeshEdge[]
  for edge in mesh.edges
    !isnothing(edge) && push!(edges, edge)
  end
  edges
end

function faces(mesh::Mesh)
  faces = MeshFace[]
  for face in mesh.faces
    !isnothing(face) && push!(faces, face)
  end
  faces
end

function adjacent_faces(mesh::Mesh, face::MeshFace)
  faces = MeshFace[]
  for edge in edges(mesh, face)
    for f in faces(mesh, edge)
      f ≠ face && push!(faces, f)
    end
  end
  faces
end

function new_element!(vector::Vector, index::Int, value)
  if in(index, first(axes(vector)))
    existing = vector[index]
    !isnothing(existing) && return false
  else
    resize!(vector, index)
  end
  vector[index] = value
  true
end

add_vertex!(mesh::Mesh, vertex::MeshVertex) = new_element!(mesh.vertices, vertex.index, vertex)

add_edge!(vertex::MeshVertex, edge::MeshEdge) = push!(vertex.edges, edge.index)
add_edge!(face::MeshFace, edge::MeshEdge) = push!(face.edges, edge.index)

function add_edge!(mesh::Mesh, edge::MeshEdge)
  new_element!(mesh.edges, edge.index, edge) || return false
  src = get_vertex(mesh, edge.src)
  add_edge!(src, edge)
  dst = get_vertex(mesh, edge.dst)
  add_edge!(dst, edge)
  push!(mesh.edges, edge)
  for face in faces(mesh, edge)
    add_edge!(face, edge)
  end
  true
end

add_face!(edge::MeshEdge, face::MeshFace) = push!(edge.faces, face)

function add_face!(mesh::Mesh, face::MeshFace)
  new_element!(mesh.faces, face.index, face) || return false
  for e in face.edges
    edge = get_edge(mesh, e)
    add_face!(edge, face)
  end
  true
end

position(mesh::Mesh, vertex::MeshVertex) = position(mesh.vertex_attributes[vertex.index])
position(p::Point) = p

function add_vertex!(mesh::Mesh, v)
  vertex = mesh_vertex(mesh, v)
  add_vertex!(mesh, vertex) || return false
  attr = vertex_attribute(v)
  !isnothing(attr) && (mesh.vertex_attributes[vertex.index] = attr)
  true
end

vertex_attribute(v::Point) = v
mesh_vertex(mesh::Mesh, ::Any) = MeshVertex(nextind(mesh.vertices, lastindex(mesh.vertices)))

function add_edge!(mesh::Mesh, e)
  edge = mesh_edge(mesh, e)
  add_edge!(mesh, edge) || return false
  attr = edge_attribute(e)
  !isnothing(attr) && (mesh.edge_attributes[edge.index] = attr)
  true
end

edge_attribute(e) = nothing
mesh_edge(mesh::Mesh, e::Pair{<:Integer,<:Integer}) = MeshEdge(nextind(mesh.edges, lastindex(mesh.edges)), e.first, e.second)

function mesh_edge(mesh, e)
  error(
    """
    No method defined for `mesh_edge(::Mesh, ::$(typeof(e)))`.

    You must either define such a method or provide an edge of type `MeshEdge` with `add_edge!(::Mesh, ::MeshEdge)`.
    """,
  )
end

function add_face!(mesh::Mesh, f)
  face = mesh_face(mesh, f)
  add_face!(mesh, face) || return false
  attr = face_attribute(f)
  !isnothing(attr) && (mesh.face_attributes[face.index] = attr)
  true
end

face_attribute(f) = nothing
mesh_face(mesh::Mesh, e::AbstractVector{<:Integer}) = MeshFace(nextind(mesh.faces, lastindex(mesh.faces)), e)

function mesh_face(mesh, e)
  error(
    """
    No method defined for `mesh_face(::Mesh, ::$(typeof(e)))`.

    You must either define such a method or provide a face of type `MeshFace` with `add_face!(::Mesh, ::MeshFace)`.
    """,
  )
end

function delete_element!(vector::Vector, attributes::Dict, index::Int)
  haskey(attributes, index) && delete!(attributes, index)
  in(index, first(axes(vector))) || return false
  if index == lastindex(vector)
    # Shrink the vector.
    last = findlast(!isnothing, vector)
    resize!(vector, last)
  else
    vector[index] = nothing
  end
  true
end

rem_face!(mesh::Mesh, vertex::MeshVertex) = delete_element!(mesh.vertices, mesh.vertex_attributes, vertex.index)
rem_edge!(mesh::Mesh, edge::MeshEdge) = delete_element!(mesh.edges, mesh.edge_attributes, edge.index)
rem_vertex!(mesh::Mesh, face::MeshFace) = delete_element!(mesh.faces, mesh.face_attributes, face.index)

function Mesh{VT,ET,FT}(vertices, edges, faces) where {VT,ET,FT}
  mesh = Mesh{VT,ET,FT}()
  for vertex in vertices
    add_vertex!(mesh, vertex)
  end
  for edge in edges
    add_edge!(mesh, edge)
  end
  for face in faces
    add_face!(mesh, face)
  end
  mesh
end

Mesh{VT,ET}(vertices, edges, faces) where {VT,ET} = Mesh{VT,ET,Nothing}(vertices, edges, faces)
Mesh{VT}(vertices, edges, faces) where {VT} = Mesh{VT,Nothing,Nothing}(vertices, edges, faces)
Mesh(vertices, edges, faces) = Mesh{Nothing,Nothing,Nothing}(vertices, edges, faces)