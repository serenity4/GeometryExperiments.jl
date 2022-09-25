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
  e1, e2, e3, e4 = edges(diff.mesh, face)
  e5 = add_edge!(diff, dst(e1), dst(e2))
  add_face!(diff, [e1, e2, e5])
  add_face!(diff, [e5, e3, e4])
end
