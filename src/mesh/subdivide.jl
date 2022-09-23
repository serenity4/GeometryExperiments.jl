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
      index(add_edge!(diff, v, border_vertices[mod1(i + 1, end)]))
    end
    for i in eachindex(edges_from_center)
      add_face!(
        diff,
        EdgeIndex[
          edges_from_center[i],
          border_edges[2i - 1],
          border_edges[mod1(2i, end)],
          # Note that this edge should be flipped for a consistent ordering in a directed setting.
          edges_from_center[mod1(i + 1, end)],
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
