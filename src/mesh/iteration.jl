"""
Iterator on a mesh face which returns a tuple `(prev, next, edge, swapped)`
where `prev` and `next` are the previous and next vertices in the edge cycle,
`edge` the corresponding undirected edge and `swapped` a boolean value indicating
whether the vertices of the undirected edge were swapped to yield `prev` and `next`.

The face must be a complete cycle of connected edges. Edges are not required to be
connected exactly at `dst => src` points; since they are undirected, the last `next`
vertex must simply be included as one of the two endpoints of the next edge in the face.
"""
struct EdgeIterator{M<:Mesh}
  mesh::M
  face::MeshFace
end

struct TraversedEdge
  prev::MeshVertex
  next::MeshVertex
  edge::MeshEdge
  swapped::Bool
end

function Base.iterate((; mesh, face)::EdgeIterator)
  edge = mesh.edges[first(face.edges)]
  # Figure out which vertex to start from based on the orientation of the first edge.
  second_edge = mesh.edges[face.edges[2]]
  is_other_way_around = !in(dst(edge), (src(second_edge), dst(second_edge)))
  vs = vertices(mesh, edge)
  is_other_way_around && (vs = reverse(vs))
  val = TraversedEdge(vs..., edge, false)
  state = (2, val.next, edge)
  (val, state)
end

function Base.iterate((; mesh, face)::EdgeIterator, (i, prev, edge))
  i > length(face.edges) && return nothing
  next_edge = mesh.edges[face.edges[i]]
  if src(next_edge) == index(prev)
    val = TraversedEdge(vertices(mesh, next_edge)..., next_edge, false)
  elseif dst(next_edge) == index(prev)
    val = TraversedEdge(reverse(vertices(mesh, next_edge))..., next_edge, true)
  else
    error(
      "Edge $next_edge disconnected from previous vertex $prev from edge $edge for face $face. The face either does not contain a cycle of edges or does so out of order.",
    )
  end
  state = (i + 1, val.next, next_edge)
  (val, state)
end

Base.length(it::EdgeIterator) = length(it.face.edges)
Base.eltype(::Type{<:EdgeIterator}) = TraversedEdge

edge_cycle(mesh::Mesh, face::MeshFace) = EdgeIterator(mesh, face)

@enum FaceOrientation::UInt8 FACE_ORIENTATION_CLOCKWISE = 1 FACE_ORIENTATION_COUNTERCLOCKWISE = 2

function orientation(mesh::Mesh, face::MeshFace)
  last_vector = nothing
  orientation = nothing
  for (; prev, next) in edge_cycle(mesh, face)
    vector = location(mesh, next) - location(mesh, prev)
    if !isnothing(last_vector)
      n = last_vector × vector
      # If `n` is zero, the points are on the same line.
      if !iszero(n)
        local_orientation = n > 0 ? FACE_ORIENTATION_COUNTERCLOCKWISE : FACE_ORIENTATION_CLOCKWISE
        if isnothing(orientation)
          orientation = local_orientation
        elseif local_orientation ≠ orientation
          # Both CW and CCW orientation, therefore the overall orientation is undefined.
          return nothing
        end
      end
    end
    last_vector = vector
  end
  orientation
end

function orientation(mesh::Mesh)
  ret = nothing
  for face in faces(mesh)
    face_orientation = orientation(mesh, face)
    isnothing(face_orientation) && return nothing
    isnothing(ret) && (ret = face_orientation)
    ret == face_orientation || return nothing
  end
  ret
end

nonorientable_faces(mesh::Mesh) = MeshFace[face for face in faces(mesh) if isnothing(orientation(mesh, face))]

function face_orientations(mesh::Mesh)
  ret = Dictionary{MeshFace,Optional{FaceOrientation}}()
  for face in faces(mesh)
    insert!(ret, face, orientation(mesh, face))
  end
  ret
end
