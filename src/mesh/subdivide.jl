function subdivide!(mesh::Mesh)
  diff = MeshDiff(mesh)

  processed_edges = Dictionary{MeshEdge,Tuple{MeshVertex,MeshEdge,MeshEdge}}()

  for face in faces(mesh)
    rem_face!(diff, face)
    center_vertex = add_vertex!(diff, centroid(mesh, face))
    final_edges = EdgeIndex[]
    for (prev, next, edge, swapped) in edge_cycle(mesh, face)
      if !haskey(processed_edges, edge)
        rem_edge!(diff, edge)
        midedge_vertex = add_vertex!(diff, centroid(mesh, edge))
        e1 = add_edge!(diff, prev, midedge_vertex)
        e2 = add_edge!(diff, midedge_vertex, next)
        insert!(processed_edges, edge, (midedge_vertex, e1, e2))
      else
        midedge_vertex, e1, e2 = processed_edges[edge]
        # Swap edges if they were computed in the opposite direction of iteration.
        if src(e1) == index(next)
          e1, e2 = e2, e1
        end
      end
      edge_from_center = add_edge!(diff, center_vertex, midedge_vertex)
      push!(final_edges, index(e1), index(edge_from_center), index(e2))
    end
    nf = length(face.edges)
    for i in 0:(nf - 1)
      add_face!(
        diff,
        [
          final_edges[3i + 2],
          final_edges[3i + 3],
          final_edges[mod1(3i + 4, lastindex(final_edges))],
          final_edges[mod1(3i + 5, lastindex(final_edges))],
        ],
      )
    end
  end

  apply!(diff)
end

function subdivide!(mesh, iterations::Integer)
  for _ in 1:iterations
    subdivide!(mesh)
  end
  mesh
end
