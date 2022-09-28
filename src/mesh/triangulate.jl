function triangulate!(mesh::Mesh)
  diff = MeshDiff(mesh)
  for face in faces(mesh)
    istri(face) && continue
    if isquad(face)
      triangulate_quad!(diff, face)
    else
      error("Only meshes consisting of triangles and quadrilaterals are supported for triangulation.")
    end
  end
  apply!(diff)
end

function triangulate_quad!(diff::MeshDiff, face::MeshFace)
  rem_face!(diff, face)
  c1, c2, c3, c4 = collect(edge_cycle(diff.mesh, face))
  e5 = add_edge!(diff, c2.next, c4.next)
  add_face!(diff, [c1.edge, c2.edge, e5])
  add_face!(diff, [e5, c3.edge, c4.edge])
end
