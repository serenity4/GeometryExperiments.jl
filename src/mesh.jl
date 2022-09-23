const VertexIndex = Int
const EdgeIndex = Int
const FaceIndex = Int

index(element) = element.index
index(i::Int) = i

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
  vertices::Dictionary{VertexIndex,MeshVertex}
  edges::Dictionary{EdgeIndex,MeshEdge}
  faces::Dictionary{FaceIndex,MeshFace}
  # Use a dictionary to allow holes in indices.
  vertex_attributes::Dictionary{VertexIndex,VT}
  edge_attributes::Dictionary{EdgeIndex,ET}
  face_attributes::Dictionary{FaceIndex,FT}
  Mesh{VT,ET,FT}() where {VT,ET,FT} =
    new{VT,ET,FT}(
      Dictionary{VertexIndex,MeshVertex}(),
      Dictionary{EdgeIndex,MeshEdge}(),
      Dictionary{FaceIndex,MeshFace}(),
      Dictionary{VertexIndex,VT}(),
      Dictionary{EdgeIndex,ET}(),
      Dictionary{FaceIndex,FT}(),
    )
end

function get_vertex(mesh::Mesh, index::VertexIndex)
  x = get(mesh.vertices, index, nothing)
  !isnothing(x) || error("Vertex $index not found")
  x
end

function get_edge(mesh::Mesh, index::EdgeIndex)
  x = get(mesh.edges, index, nothing)
  !isnothing(x) || error("Edge $index not found")
  x
end

function get_face(mesh::Mesh, index::FaceIndex)
  x = get(mesh.faces, index, nothing)
  !isnothing(x) || error("Face $index not found")
  x
end

edges(mesh::Mesh, vertex::MeshVertex) = getindices(mesh.edges, vertex.edges)
edges(mesh::Mesh, face::MeshFace) = getindices(mesh.edges, face.edges)
faces(mesh::Mesh, edge::MeshEdge) = getindices(mesh.faces, edge.faces)

vertices(mesh::Mesh) = mesh.vertices
edges(mesh::Mesh) = mesh.edges
faces(mesh::Mesh) = mesh.faces

function adjacent_faces(mesh::Mesh, face::MeshFace)
  faces = MeshFace[]
  for edge in edges(mesh, face)
    for f in faces(mesh, edge)
      f ≠ face && push!(faces, f)
    end
  end
  faces
end

vertices(mesh::Mesh, edge::MeshEdge) = (get_vertex(mesh, edge.src), get_vertex(mesh, edge.dst))

function vertices(mesh::Mesh, face::MeshFace)
  vertices = MeshVertex[]
  for edge in edges(mesh, face)
    push!(vertices, get_vertex(mesh, edge.src))
  end
  vertices
end

function new_element!(d::Dictionary, index::Int, value)
  haskey(d, index) && return false
  insert!(d, index, value)
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
  for face in faces(mesh, edge)
    add_edge!(face, edge)
  end
  true
end

add_face!(edge::MeshEdge, face::MeshFace) = push!(edge.faces, face.index)

function add_face!(mesh::Mesh, face::MeshFace)
  new_element!(mesh.faces, face.index, face) || return false
  for e in face.edges
    edge = get_edge(mesh, e)
    add_face!(edge, face)
  end
  true
end

function add_vertex!(mesh::Mesh, v)
  vertex = mesh_vertex(mesh, v)
  @assert add_vertex!(mesh, vertex)
  attr = vertex_attribute(v)
  !isnothing(attr) && set!(mesh.vertex_attributes, vertex.index, attr)
  vertex
end

lastindex_dict(d::Dictionary) = isempty(d) ? 0 : lastindex(d)
nextindex(d::Dictionary) = lastindex_dict(d) + 1

mesh_vertex(mesh::Mesh, ::Any) = MeshVertex(nextindex(mesh.vertices))

function add_edge!(mesh::Mesh, e)
  edge = mesh_edge(mesh, e)
  @assert add_edge!(mesh, edge)
  attr = edge_attribute(e)
  !isnothing(attr) && set!(mesh.edge_attributes, edge.index, attr)
  edge
end

add_edge!(mesh, src, dst) = add_edge!(mesh, src => dst)

mesh_edge(mesh::Mesh, e) = MeshEdge(nextindex(mesh.edges), src(e), dst(e))

src(edge::MeshEdge) = edge.src
dst(edge::MeshEdge) = edge.dst
src(edge::Union{Pair,Tuple{<:Any,<:Any}}) = index(first(edge))
dst(edge::Union{Pair,Tuple{<:Any,<:Any}}) = index(last(edge))

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
  @assert add_face!(mesh, face)
  attr = face_attribute(f)
  !isnothing(attr) && set!(mesh.face_attributes, face.index, attr)
  face
end

mesh_face(mesh::Mesh, face) = MeshFace(nextindex(mesh.faces), face_edges(face))
face_edges(edges::AbstractVector{<:Integer}) = edges
face_edges(face::MeshFace) = face.edges
face_edges(edges::AbstractVector{MeshEdge}) = index.(edges)

function mesh_face(mesh, e)
  error(
    """
    No method defined for `mesh_face(::Mesh, ::$(typeof(e)))`.

    You must either define such a method or provide a face of type `MeshFace` with `add_face!(::Mesh, ::MeshFace)`.
    """,
  )
end

function delete_element!(d::Dictionary, attributes::Dictionary, index::Int)
  haskey(attributes, index) && delete!(attributes, index)
  haskey(d, index) || return false
  delete!(d, index)
  true
end

function rem_vertex!(mesh::Mesh, vertex::MeshVertex)
  rem_edges!(mesh, edges(mesh, vertex))
  delete_element!(mesh.vertices, mesh.vertex_attributes, vertex.index)
end

function rem_edge!(mesh::Mesh, edge::MeshEdge)
  for vertex in vertices(mesh, edge)
    i = findfirst(==(edge.index), vertex.edges)
    deleteat!(vertex.edges, i)
  end
  rem_faces!(mesh, faces(mesh, edge))
  delete_element!(mesh.edges, mesh.edge_attributes, edge.index)
end

function rem_face!(mesh::Mesh, face::MeshFace)
  for edge in edges(mesh, face)
    i = findfirst(==(face.index), edge.faces)
    deleteat!(edge.faces, i)
  end
  delete_element!(mesh.faces, mesh.face_attributes, face.index)
end

function rem_vertices!(mesh, vertices)
  for vertex in vertices
    rem_vertex!(mesh, vertex)
  end
end

function rem_edges!(mesh, edges)
  for edge in edges
    rem_edge!(mesh, edge)
  end
end

function rem_faces!(mesh, faces)
  for face in faces
    rem_face!(mesh, face)
  end
end

function add_vertices!(mesh, vertices)
  for vertex in vertices
    add_vertex!(mesh, vertex)
  end
end

function add_edges!(mesh, edges)
  for edge in edges
    add_edge!(mesh, edge)
  end
end

function add_faces!(mesh, faces)
  for face in faces
    add_face!(mesh, face)
  end
end

function Mesh{VT,ET,FT}(vertices, edges, faces) where {VT,ET,FT}
  mesh = Mesh{VT,ET,FT}()
  add_vertices!(mesh, vertices)
  add_edges!(mesh, edges)
  add_faces!(mesh, faces)
  mesh
end

Mesh{VT,ET}(vertices, edges, faces) where {VT,ET} = Mesh{VT,ET,Nothing}(vertices, edges, faces)
Mesh{VT}(vertices, edges, faces) where {VT} = Mesh{VT,Nothing,Nothing}(vertices, edges, faces)
Mesh(vertices, edges, faces) = Mesh{Nothing,Nothing,Nothing}(vertices, edges, faces)

rem_vertices!(mesh) = rem_vertices!(mesh, collect(vertices(mesh)))
rem_edges!(mesh) = rem_edges!(mesh, collect(edges(mesh)))
rem_faces!(mesh) = rem_faces!(mesh, collect(faces(mesh)))

struct MeshStatistics
  nv::Int
  ne::Int
  nf::Int
end

nv(mesh) = length(vertices(mesh))
ne(mesh) = length(edges(mesh))
nf(mesh) = length(faces(mesh))

MeshStatistics(mesh) = MeshStatistics(nv(mesh), ne(mesh), nf(mesh))

function Base.show(io::IO, mesh::Mesh)
  print(io, typeof(mesh), "(", nv(mesh), " vertices, ", ne(mesh), " edges, ", nf(mesh), " faces)")
end
