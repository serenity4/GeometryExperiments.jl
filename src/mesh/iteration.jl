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
  val = TraversedEdge(vertices(mesh, edge)..., edge, false)
  state = (2, dst(edge), edge)
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
