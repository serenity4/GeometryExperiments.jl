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
  vertices::GranularVector{MeshVertex}
  edges::GranularVector{MeshEdge}
  faces::GranularVector{MeshFace}
  # Use a dictionary to allow for missing attributes.
  vertex_attributes::Dictionary{VertexIndex,VT}
  edge_attributes::Dictionary{EdgeIndex,ET}
  face_attributes::Dictionary{FaceIndex,FT}
  Mesh{VT,ET,FT}() where {VT,ET,FT} =
    new{VT,ET,FT}(
      GranularVector{MeshVertex}(),
      GranularVector{MeshEdge}(),
      GranularVector{MeshFace}(),
      Dictionary{VertexIndex,VT}(),
      Dictionary{EdgeIndex,ET}(),
      Dictionary{FaceIndex,FT}(),
    )
end

edges(mesh::Mesh, vertex::MeshVertex) = view(mesh.edges, vertex.edges)
edges(mesh::Mesh, face::MeshFace) = view(mesh.edges, face.edges)
faces(mesh::Mesh, edge::MeshEdge) = view(mesh.faces, edge.faces)

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

vertices(mesh::Mesh, edge::MeshEdge) = (mesh.vertices[edge.src], mesh.vertices[edge.dst])

function vertices(mesh::Mesh, face::MeshFace)
  vertices = MeshVertex[]
  for edge in edges(mesh, face)
    push!(vertices, mesh.vertices[edge.src])
  end
  vertices
end

function add_vertex!(mesh::Mesh, vertex::MeshVertex)
  insert!(mesh.vertices, vertex.index, vertex)
  nothing
end

add_edge!(vertex::MeshVertex, edge::MeshEdge) = push!(vertex.edges, edge.index)
add_edge!(face::MeshFace, edge::MeshEdge) = push!(face.edges, edge.index)

function add_edge!(mesh::Mesh, edge::MeshEdge)
  insert!(mesh.edges, edge.index, edge)
  src = mesh.vertices[edge.src]
  add_edge!(src, edge)
  dst = mesh.vertices[edge.dst]
  add_edge!(dst, edge)
  for face in faces(mesh, edge)
    add_edge!(face, edge)
  end
end

add_face!(edge::MeshEdge, face::MeshFace) = push!(edge.faces, face.index)

function add_face!(mesh::Mesh, face::MeshFace)
  insert!(mesh.faces, face.index, face)
  for edge in edges(mesh, face)
    add_face!(edge, face)
  end
end

function add_vertex!(mesh::Mesh, v)
  vertex = mesh_vertex(mesh, v)
  add_vertex!(mesh, vertex)
  attr = vertex_attribute(v)
  !isnothing(attr) && insert!(mesh.vertex_attributes, vertex.index, attr)
  vertex
end

mesh_vertex(mesh::Mesh, ::Any) = MeshVertex(nextind!(mesh.vertices))

function add_edge!(mesh::Mesh, e)
  edge = mesh_edge(mesh, e)
  add_edge!(mesh, edge)
  attr = edge_attribute(e)
  !isnothing(attr) && insert!(mesh.edge_attributes, edge.index, attr)
  edge
end

add_edge!(mesh, src, dst) = add_edge!(mesh, src => dst)

mesh_edge(mesh::Mesh, e) = MeshEdge(nextind!(mesh.edges), src(e), dst(e))

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
  add_face!(mesh, face)
  attr = face_attribute(f)
  !isnothing(attr) && insert!(mesh.face_attributes, face.index, attr)
  face
end

mesh_face(mesh::Mesh, face) = MeshFace(nextind!(mesh.faces), face_edges(face))
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

function delete_element!(gvec::GranularVector, attributes::Dictionary, index::Int)
  isdefined(gvec, index) && deleteat!(gvec, index)
  haskey(attributes, index) && delete!(attributes, index)
  nothing
end

function rem_vertex!(mesh::Mesh, vertex::MeshVertex)
  vedges = edges(mesh, vertex)
  if !isempty(vedges)
    rem_edges!(mesh, collect(vedges))
  end
  delete_element!(mesh.vertices, mesh.vertex_attributes, vertex.index)
end

function rem_edge!(mesh::Mesh, edge::MeshEdge)
  isdefined(mesh.edges, edge.index) || return
  for vertex in vertices(mesh, edge)
    i = findfirst(==(edge.index), vertex.edges)
    deleteat!(vertex.edges, i)
  end
  efaces = faces(mesh, edge)
  if !isempty(efaces)
    rem_faces!(mesh, collect(efaces))
  end
  delete_element!(mesh.edges, mesh.edge_attributes, edge.index)
end

function rem_face!(mesh::Mesh, face::MeshFace)
  isdefined(mesh.faces, face.index) || return
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

rem_vertices!(mesh) = rem_vertices!(mesh, vertices(mesh))
rem_edges!(mesh) = rem_edges!(mesh, edges(mesh))
rem_faces!(mesh) = rem_faces!(mesh, faces(mesh))

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
