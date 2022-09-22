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

mutable struct MeshDiff{VT,ET,FT}
  const mesh::Mesh{VT,ET,FT}
  applied::Bool

  vertex_index::Int
  edge_index::Int
  face_index::Int

  const vertex_additions::Vector{PackedAttribute{MeshVertex,VT}}
  const edge_additions::Vector{PackedAttribute{MeshEdge,ET}}
  const face_additions::Vector{PackedAttribute{MeshFace,FT}}

  const vertex_deletions::Vector{MeshVertex}
  const edge_deletions::Vector{MeshEdge}
  const face_deletions::Vector{MeshFace}

  MeshDiff(mesh::Mesh{VT,ET,FT}) where {VT,ET,FT} =
    new{VT,ET,FT}(
      mesh,
      false,
      lastindex_dict(mesh.vertices),
      lastindex_dict(mesh.edges),
      lastindex_dict(mesh.faces),
      PackedAttribute{MeshVertex,VT}[],
      PackedAttribute{MeshEdge,ET}[],
      PackedAttribute{MeshFace,FT}[],
      MeshVertex[],
      MeshEdge[],
      MeshFace[],
    )
end

function Base.show(io::IO, mime::MIME"text/plain", diff::MeshDiff)
  print(io, MeshDiff, '(', diff.mesh, ") with:")

  if !isempty(diff.vertex_additions)
    println(io, '\n')
    printstyled(io, "+ ", length(diff.vertex_additions), " vertices: "; color = :green)
    print_vector(io, diff.vertex_additions)
  end
  if !isempty(diff.edge_additions)
    println(io, '\n')
    printstyled(io, "+ ", length(diff.edge_additions), " edges: "; color = :green)
    print_vector(io, diff.edge_additions)
  end
  if !isempty(diff.face_additions)
    println(io, '\n')
    printstyled(io, "+ ", length(diff.face_additions), " faces: "; color = :green)
    print_vector(io, diff.face_additions)
  end

  if !isempty(diff.vertex_deletions)
    println(io, '\n')
    printstyled(io, "- ", length(diff.vertex_deletions), " vertices: "; color = :red)
    print_vector(io, diff.vertex_deletions)
  end
  if !isempty(diff.edge_deletions)
    println(io, '\n')
    printstyled(io, "- ", length(diff.edge_deletions), " edges: "; color = :red)
    print_vector(io, diff.edge_deletions)
  end
  if !isempty(diff.face_deletions)
    println(io, '\n')
    printstyled(io, "- ", length(diff.face_deletions), " faces: "; color = :red)
    print_vector(io, diff.face_deletions)
  end

  println(io)
end

print_vector(io::IO, vec::Vector) = print(io, eltype(vec), "[", join([sprintc_mime(show, el) for el in vec], ", "), "]")

@inline check_not_applied(diff::MeshDiff) = !diff.applied || error("The diff has already been applied.")

function apply!(diff::MeshDiff)
  (; mesh) = diff
  isapplied(diff) && return mesh

  # Perform additions first, so that deletions that impact
  # additions will remove these additions instead of referencing
  # deleted geometry with new additions which will error.
  add_vertices!(mesh, diff.vertex_additions)
  add_edges!(mesh, diff.edge_additions)
  add_faces!(mesh, diff.face_additions)

  rem_faces!(mesh, diff.face_deletions)
  rem_edges!(mesh, diff.edge_deletions)
  rem_vertices!(mesh, diff.vertex_deletions)

  diff.applied = true

  mesh
end

isapplied(diff::MeshDiff) = diff.applied
vertices(diff::MeshDiff) = vertices(diff.mesh)
edges(diff::MeshDiff) = edges(diff.mesh)
faces(diff::MeshDiff) = faces(diff.mesh)

mesh_vertex(diff::MeshDiff) = MeshVertex(diff.vertex_index)
mesh_edge(diff::MeshDiff, edge) = MeshEdge(diff.edge_index, src(edge), dst(edge))
mesh_face(diff::MeshDiff, face) = MeshFace(diff.face_index, face_edges(face))

function add_vertex!(diff::MeshDiff, vertex = nothing)
  check_not_applied(diff)
  index = (diff.vertex_index += 1)
  new_vertex = mesh_vertex(diff)
  push!(diff.vertex_additions, PackedAttribute(new_vertex, vertex_attribute(vertex)))
  new_vertex
end

function add_edge!(diff::MeshDiff, edge)
  check_not_applied(diff)
  index = (diff.edge_index += 1)
  new_edge = mesh_edge(diff, edge)
  push!(diff.edge_additions, PackedAttribute(new_edge, edge_attribute(edge)))
  new_edge
end

function add_face!(diff::MeshDiff, face)
  check_not_applied(diff)
  index = (diff.face_index += 1)
  new_face = mesh_face(diff, face)
  push!(diff.face_additions, PackedAttribute(new_face, face_attribute(face)))
  new_face
end

function rem_vertex!(diff::MeshDiff, vertex::MeshVertex)
  check_not_applied(diff)
  push!(diff.vertex_deletions, vertex)
  nothing
end

function rem_edge!(diff::MeshDiff, edge::MeshEdge)
  check_not_applied(diff)
  push!(diff.edge_deletions, edge)
  nothing
end

function rem_face!(diff::MeshDiff, face::MeshFace)
  check_not_applied(diff)
  push!(diff.face_deletions, face)
  nothing
end

function subdivide!(mesh::Mesh)
  diff = MeshDiff(mesh)

  for face in faces(mesh)
    center_vertex = add_vertex!(diff, centroid(mesh, face))
    border_vertices = VertexIndex[]
    edges_from_center = EdgeIndex[]
    for edge in edges(mesh, face)
      rem_edge!(diff, edge)
      midedge_vertex = add_vertex!(diff, centroid(mesh, edge))
      push!(border_vertices, index(midedge_vertex), dst(edge))
      new_edge = add_edge!(diff, center_vertex, midedge_vertex)
      push!(edges_from_center, index(new_edge))
    end
    border_edges = map(enumerate(border_vertices)) do (i, v)
      index(add_edge!(diff, v, border_vertices[mod1(i + 1, lastindex(border_vertices))]))
    end
    for i in eachindex(edges_from_center)
      add_face!(
        diff,
        EdgeIndex[
          edges_from_center[i],
          border_edges[2i - 1],
          border_edges[mod1(2i, lastindex(border_edges))],
          # Note that this edge should be flipped for a consistent ordering in a directed setting.
          edges_from_center[mod1(i + 1, lastindex(edges_from_center))],
        ],
      )
    end
  end

  apply!(diff)
end
