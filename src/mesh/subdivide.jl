abstract type SubdivisionAlgorithm end

struct UniformSubdivision <: SubdivisionAlgorithm
  iterations::Int
end

struct CatmullClarkSubdivision <: SubdivisionAlgorithm
  iterations::Int
  strength::Float64
end

function MeshDiff(mesh::Mesh, subdivision::UniformSubdivision)
  diff = MeshDiff(mesh)
  processed_edges = Dictionary{MeshEdge,Tuple{MeshVertex,MeshEdge,MeshEdge}}()

  for face in faces(mesh)
    rem_face!(diff, face)
    n = nv(face)
    center_attribute = linear_combination((attribute(mesh, v) for v in vertices(mesh, face)), ntuple(Returns(1.0 / n), n))
    center_vertex = add_vertex!(diff, center_attribute)
    connect_face_center!!(diff, processed_edges, face, center_vertex)
  end
  diff
end

function connect_face_center!!(diff::MeshDiff, processed_edges, face::MeshFace, center::MeshVertex)
  (; mesh) = diff
  final_edges = EdgeIndex[]
  for (prev, next, edge, swapped) in edge_cycle(mesh, face)
    if !haskey(processed_edges, edge)
      rem_edge!(diff, edge)
      midedge_attribute = interpolate_linear(mesh.vertex_attributes[src(edge)], mesh.vertex_attributes[dst(edge)], 0.5)
      midedge_vertex = add_vertex!(diff, midedge_attribute)
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
    edge_from_center = add_edge!(diff, center, midedge_vertex)
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

subdivide!(mesh::Mesh, alg = UniformSubdivision(1)) = apply!(mesh, alg)

function apply!(mesh::Mesh, alg::SubdivisionAlgorithm)
  for _ in 1:(alg.iterations)
    apply!(MeshDiff(mesh, alg))
  end
  mesh
end

interpolate_linear(p1, p2, t) = p1 * (1 - t) + p2 * t
linear_combination(ps, ts) = sum(p * t for (p, t) in zip(ps, ts))
