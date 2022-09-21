function subdivide!(mesh::Mesh)
  for face in faces(mesh)
    p = centroid(mesh, face)
    new_vertex = add_vertex!(mesh, p)
    face_edges = edges(mesh, face)
    rem_face!(mesh, face)
    final_face_vertices = VertexIndex[]
    edges_from_center = EdgeIndex[]
    for edge in face_edges
      edge_centroid = centroid(mesh, edge)
      new_vertex_on_edge = add_vertex!(mesh, edge_centroid)
      push!(final_face_vertices, new_vertex_on_edge.index, edge.dst)
      push!(edges_from_center, add_edge!(mesh, new_vertex => new_vertex_on_edge).index)
      rem_edge!(mesh, edge)
    end
    new_edges = EdgeIndex[]
    for (i, v) in enumerate(final_face_vertices)
      push!(new_edges, add_edge!(mesh, v => final_face_vertices[mod1(i + 1, lastindex(final_face_vertices))]).index)
    end
    for i in eachindex(edges_from_center)
      add_face!(
        mesh,
        EdgeIndex[
          edges_from_center[i],
          new_edges[2i - 1],
          new_edges[mod1(2i, lastindex(new_edges))],
          edges_from_center[mod1(i + 1, lastindex(edges_from_center))],
        ],
      )
    end
  end
  mesh
end
