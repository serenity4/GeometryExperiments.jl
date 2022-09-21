function subdivide!(mesh::Mesh)
  for face in faces(mesh)
    p = centroid(mesh, face)
    rem_face!(mesh, face)
    new_vertex = add_vertex!(mesh, p)
    prev_edge_centroid = nothing
    for edge in edges(mesh, face)
      edge_centroid = centroid(mesh, edge)
      new_vertex_on_edge = add_vertex!(mesh, edge_centroid)
      add_edge!(mesh, new_vertex, new_vertex_on_edge)
      !isnothing(prev_edge_centroid) && add_face!(mesh, p, prev_edge_centroid, first(edge), edge_centroid)
      prev_edge_centroid = edge_centroid
    end
  end
  mesh
end
