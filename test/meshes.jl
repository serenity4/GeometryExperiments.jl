struct PosUV{P<:Point}
  pos::P
  uv::P2
end

GeometryExperiments.location(attr::PosUV) = attr.pos
GeometryExperiments.vertex_attribute(attr::PosUV) = attr
Base.:(+)(p1::PosUV, p2::PosUV) = PosUV(p1.pos + p2.pos, p1.uv + p2.uv)
Base.:(*)(p::PosUV, w::Float64) = PosUV(p.pos .* w, p.uv .* w)

quad_mesh() = Mesh{P2}(P2[(-1, -1), (-1, 1), (1, 1), (1, -1)], [(1, 2), (2, 3), (3, 4), (4, 1)], [[1, 2, 3, 4]])
quad_mesh_ccw() = Mesh{P2}(P2[(-1, -1), (-1, 1), (1, 1), (1, -1)], [(1, 2), (2, 3), (3, 4), (4, 1)], [[1, 4, 3, 2]])
quad_mesh_uv() =
  Mesh{PosUV{P2}}(
    PosUV.(P2[(-1, -1), (-1, 1), (1, 1), (1, -1)], P2[(0, 0), (1, 0), (1, 1), (0, 1)]),
    [(1, 2), (2, 3), (3, 4), (4, 1)],
    [[1, 2, 3, 4]],
  )
quad_mesh_tri() = Mesh{P2}(P2[(-1, -1), (-1, 1), (1, 1), (1, -1)], [(1, 2), (2, 3), (3, 4), (4, 1), (1, 3)], [[1, 2, 5], [3, 4, 5]])

@testset "Meshes" begin
  # Direct mutation and utilities.

  mesh = quad_mesh()
  @test MeshStatistics(mesh) == MeshStatistics(4, 4, 1)
  face = first(faces(mesh))
  @test centroid(mesh, face) ≈ zero(P2)
  @test centroid(mesh) == centroid(mesh, face)
  @test centroid(mesh, first(edges(mesh))) == P2(-1, 0)
  @test orientation(mesh, face) == orientation(mesh) == FACE_ORIENTATION_CLOCKWISE

  rem_face!(mesh, first(faces(mesh)))
  @test MeshStatistics(mesh) == MeshStatistics(4, 4, 0)

  rem_edges!(mesh)
  @test MeshStatistics(mesh) == MeshStatistics(4, 0, 0)
  @test all(isempty(vertex.edges) for vertex in vertices(mesh))

  rem_vertices!(mesh)
  @test MeshStatistics(mesh) == MeshStatistics(0, 0, 0)

  mesh = quad_mesh()
  rem_vertices!(mesh)
  @test MeshStatistics(mesh) == MeshStatistics(0, 0, 0)

  mesh = quad_mesh()
  v = add_vertex!(mesh, P2(0, 0))
  @test v.index == 5
  @test in(v, vertices(mesh))
  rem_vertex!(mesh, v)
  @test !in(v, vertices(mesh))

  mesh = quad_mesh_tri()
  @test orientation(mesh) == FACE_ORIENTATION_CLOCKWISE
  @test length(mesh.vertices) == 4 == length(vertices(mesh))
  @test length(mesh.edges) == 5 == length(edges(mesh))
  @test length(mesh.faces) == 2 == length(faces(mesh))
  face = first(mesh.faces)
  @test centroid(mesh, first(mesh.faces)) == centroid(P2[(-1, -1), (-1, 1), (1, 1)])
  @test iszero(centroid(mesh))

  mesh_uv = quad_mesh_uv()
  @test centroid(mesh_uv) ≈ zero(P2)

  # Transactional mutation.

  mesh = quad_mesh()
  diff = MeshDiff(mesh)
  stats = MeshStatistics(mesh)
  rem_vertices!(diff)
  rem_edges!(diff)
  rem_faces!(diff)
  @test MeshStatistics(mesh) == stats
  apply!(diff)
  @test MeshStatistics(mesh) == MeshStatistics(0, 0, 0)
  # Test that the diff can be reapplied safely (leading to a no-op).
  apply!(diff)
  @test MeshStatistics(mesh) == MeshStatistics(0, 0, 0)

  mesh = quad_mesh()
  diff = MeshDiff(mesh)
  stats = MeshStatistics(mesh)
  a = add_vertex!(diff, P2(4, 4))
  b = add_vertex!(diff, P2(5, 5))
  c = add_vertex!(diff, P2(5, 4))
  e1 = add_edge!(diff, a, b)
  e2 = add_edge!(diff, b, c)
  e3 = add_edge!(diff, c, a)
  f = add_face!(diff, [e1, e2, e3])
  @test MeshStatistics(mesh) == stats
  apply!(diff)
  @test MeshStatistics(mesh) == MeshStatistics(stats.nv + 3, stats.ne + 3, stats.nf + 1)
  apply!(diff)
  @test MeshStatistics(mesh) == MeshStatistics(stats.nv + 3, stats.ne + 3, stats.nf + 1)

  # Polytope queries.

  mesh = quad_mesh_tri()
  f1, f2 = faces(mesh)
  e1, e2, e3, e4, e5 = edges(mesh)
  v1, v2, v3, v4 = vertices(mesh)
  @test collect(edges(mesh, f1)) == [e1, e2, e5]
  @test collect(edges(mesh, f2)) == [e3, e4, e5]
  @test vertices(mesh, e1) == (v1, v2)
  @test vertices(mesh, e2) == (v2, v3)
  @test vertices(mesh, e3) == (v3, v4)
  @test vertices(mesh, e4) == (v4, v1)
  @test vertices(mesh, e5) == (v1, v3)
  @test vertices(mesh, f1) == [v1, v2, v3]
  @test vertices(mesh, f2) == [v3, v4, v1]
  @test adjacent_vertices(mesh, v1) == [v2, v4, v3]
  @test adjacent_vertices(mesh, v2) == [v1, v3]
  @test adjacent_faces(mesh, f1) == [f2]
  @test adjacent_faces(mesh, f2) == [f1]

  mesh = quad_mesh()
  @test ishomogeneous(mesh)
  @test allunique(mesh)
  f = only(faces(mesh))
  cycle = collect(edge_cycle(mesh, f))
  @test getproperty.(cycle, :edge) == collect(edges(mesh, f))
  @test union(getproperty.(cycle, :prev), getproperty.(cycle, :next)) == vertices(mesh, f)
  @test all(!, getproperty.(cycle, :swapped))

  mesh = quad_mesh_tri()
  @test ishomogeneous(mesh)
  @test allunique(mesh)
  f1 = first(faces(mesh))
  cycle = collect(edge_cycle(mesh, f1))
  @test getproperty.(cycle, :edge) == collect(edges(mesh, f1))
  @test union(getproperty.(cycle, :prev), getproperty.(cycle, :next)) == vertices(mesh, f1)
  @test getproperty.(cycle, :swapped) == [false, false, true]

  # Mesh subdivision.

  mesh = subdivide!(quad_mesh())
  @test MeshStatistics(mesh) == MeshStatistics(9, 12, 4)
  @test all(isquad, faces(mesh))
  @test ishomogeneous(mesh)
  @test allunique(mesh)
  @test length(filter(e -> length(e.faces) == 2, collect(edges(mesh)))) == 4
  @test centroid(mesh) ≈ zero(P2)

  for i in 2:5
    # Number of verts, edges and faces for subdivided quads.
    # See https://blender.stackexchange.com/a/15667.
    subdivide!(mesh)
    @test MeshStatistics(mesh) == MeshStatistics((2^(i + 1) + 2)^2 / 4, 2^i * ((2^(i + 1)) + 2), 4^i)
  end

  @test MeshStatistics(mesh) == MeshStatistics(subdivide!(quad_mesh(), UniformSubdivision(5)))
  @test ishomogeneous(mesh)
  @test allunique(mesh)

  mesh_uv = subdivide!(quad_mesh_uv())
  @test MeshStatistics(mesh_uv) == MeshStatistics(9, 12, 4)
  @test centroid(mesh_uv) ≈ zero(P2)
  # New vertices will have at least one non-integer UV component.
  @test length(filter(attr -> !iszero(attr.uv .% 1), mesh_uv.vertex_attributes)) == 5
  @test ishomogeneous(mesh_uv)
  mesh_uv = subdivide!(quad_mesh_uv(), 3)
  @test ishomogeneous(mesh_uv)

  for mesh in (quad_mesh(), quad_mesh_ccw(), quad_mesh_tri(), quad_mesh_uv())
    orient = orientation(mesh)
    @test !isnothing(orient)
    subdivide!(mesh, 1)
    @test ishomogeneous(mesh)
    @test orientation(mesh) === orient
    subdivide!(mesh, 1)
    @test ishomogeneous(mesh)
    @test orientation(mesh) === orient
  end

  # Mesh triangulation.

  mesh = quad_mesh()
  orient = orientation(mesh)
  triangulate!(mesh)
  @test all(istri, faces(mesh))
  @test ishomogeneous(mesh)
  @test allunique(mesh)
  @test orientation(mesh) === orient
  @test isempty(nonorientable_faces(mesh))
  @test length(unique(face_orientations(mesh))) == 1

  mesh_uv = subdivide!(quad_mesh_uv(), 3)
  orient = orientation(mesh_uv)
  triangulate!(mesh_uv)
  @test ishomogeneous(mesh_uv)
  @test all(istri, faces(mesh_uv))
  @test orientation(mesh_uv) === orient

  @testset "Mesh encodings" begin
    strip = TriangleStrip(1:5)
    list = TriangleList([(1, 2, 3), (2, 4, 3), (3, 4, 5)])
    @test TriangleList(strip) == list

    fan = TriangleFan(1:5)
    list = TriangleList([(1, 2, 3), (1, 3, 4), (1, 4, 5)])
    @test GeometryExperiments.primitive_topology(typeof(fan)) == TrianglePrimitive
    @test TriangleList(fan) == list

    @test isa(VertexMesh(P2[(1.2, 1.4), (0.1, 0.2), (0.3, 0.4), (0.5, 0.2)], TrianglePrimitive), VertexMesh{<:TriangleStrip,P2})
    @test isa(VertexMesh(fan, P2[(1.2, 1.4), (0.1, 0.2), (0.3, 0.4), (0.5, 0.2)]), VertexMesh{<:TriangleFan,P2})

    strip = LineStrip(1:5)
    @test GeometryExperiments.primitive_topology(typeof(strip)) == LinePrimitive
    @test LineList(strip) == LineList([(1, 2), (2, 3), (3, 4), (4, 5)])

    mesh = quad_mesh_tri()
    vmesh = VertexMesh(mesh)
    @test vmesh.indices == TriangleList(Point{3,Int}[(0, 1, 2), (2, 3, 0)])
  end

  @testset "Triangle mesh" begin
    set = PointSet(HyperCube{2}, Point2f)
    points = collect(set)
    mesh = TriangleMesh(TriangleStrip(1:4), points)
    @test isa(mesh, TriangleMesh)
    @test length(vertices(mesh)) == 4
    mesh2 = TriangleMesh(points)
    @test mesh2 == mesh2
    @test mesh2 !== mesh
    mesh3 = TriangleMesh(set)
    @test mesh3 == mesh
    verts = Vertex.(points)
    @test TriangleMesh(verts) === TriangleMesh(verts)
  end

  @testset "Mesh loading" begin
    file = joinpath(pkgdir(GeometryExperiments), "test", "assets", "cube.gltf")
    mesh = load_gltf(file)
    @test isa(mesh, TriangleMesh{TriangleList{UInt16},Point3f})
  end
end;
