using GeometryExperiments
using GeometryExperiments: ensure_cyclic_edges!

const P2 = Point2
const P3 = Point3

quad_mesh() = Mesh{P2}(P2[(-1, -1), (1, -1), (1, 1), (-1, 1)], [(1, 2), (2, 3), (3, 4), (4, 1)], [[1, 2, 3, 4]])
quad_mesh_tri() = Mesh{P2}(P2[(-1, -1), (1, -1), (1, 1), (-1, 1)], [(1, 2), (2, 3), (3, 4), (4, 1), (1, 3)], [[1, 2, 5], [3, 4, 5]])

using BenchmarkTools

mesh = quad_mesh_tri()
@btime ensure_cyclic_edges!(face, $mesh) setup = face = MeshFace(3, [1, 3, 4, 2])
