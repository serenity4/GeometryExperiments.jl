using GeometryExperiments
using GeometryExperiments: index
using Test

const GE = GeometryExperiments
const P2 = Point2
const P3 = Point3

quad_mesh() = Mesh{P2}(P2[(-1, -1), (1, -1), (1, 1), (-1, 1)], [(1, 2), (2, 3), (3, 4), (4, 1)], [[1, 2, 3, 4]])
quad_mesh_tri() = Mesh{P2}(P2[(-1, -1), (1, -1), (1, 1), (-1, 1)], [(1, 2), (2, 3), (3, 4), (4, 1), (1, 3)], [[1, 2, 5], [3, 4, 5]])

@testset "GeometryExperiments.jl" begin
  @testset "Basic transforms" begin
    @testset "Translations" begin
      tr = Translation(1.0, 3.0)
      tr_inv = inv(tr)
      @test tr ∘ tr_inv == Translation(0.0, 0.0)
      @test tr(Point(1.0, 2.0)) == Point(2.0, 5.0)
      @test identity(Translation{2,Float64})(Point(1.0, 2.0)) == Point(1.0, 2.0)
    end

    @testset "Scalings" begin
      sc = Scaling(1.0, 2.0)
      sc_inv = inv(sc)
      @test sc ∘ sc_inv == Scaling(1.0, 1.0)
      @test sc(Point(1.0, 2.0)) == Point(1.0, 4.0)
      @test identity(Scaling{2,Float64})(Point(1.0, 2.0)) == Point(1.0, 2.0)

      us = UniformScaling(2.0)
      @test us ∘ inv(us) == UniformScaling(1.0)
      @test us(Point(1.0, 2.0)) == Point(2.0, 4.0)
      @test identity(UniformScaling{Float64})(Point(1.0, 2.0)) == Point(1.0, 2.0)
    end

    @testset "Rotations" begin end

    @testset "Composition" begin
      @test Translation(2.0, 3.0) ∘ Translation(1.0, 2.0) == Translation(3.0, 5.0)
      @test Scaling(2.0, 3.0) ∘ Scaling(1.0, 2.0) == Scaling(2.0, 6.0)

      trs = [Translation(1.0, 2.0), Scaling(1.0, 2.0), Translation(-1.0, -2.0)]
      tr = ∘(trs...)
      @test all(transforms(tr) .== trs)

      tr = Scaling(2.0, 3.0) ∘ Translation(1.0, 2.0)
      @test tr(Point(0.0, 0.0)) == Point(2.0, 6.0)

      p = Point(1.0, 2.0)
      @test (inv(tr) ∘ tr)(p) == p
    end
  end

  @testset "Primitives" begin
    p = Point(0.0, 1.0, 0.0)

    hc = HyperCube(0.2)
    @test origin(hc) == 0.0
    @test radius(hc) == 0.2
    @test p ∉ hc
    @test origin(hc) ∈ hc

    b1 = Box(0.2, Scaling(1.0, 2.0, 3.0))
    @test b1 === Scaled(hc, Scaling(1.0, 2.0, 3.0))
    b2 = Box(Scaling(0.2 .* Point(1.0, 2.0, 3.0)))
    @test origin(b1) == origin(b2) && radius(b1) == radius(b2)
    b3 = Translated(b2, Translation(0.4, 0.4, 0.4))
    b4 = box(0.4 .+ Point(-0.2, -0.4, -0.6), 0.4 .+ Point(0.2, 0.4, 0.6))
    @test origin(b4) ≈ origin(b3)
    @test radius(b4) ≈ radius(b3)

    @test Translated(hc, Translation(0.05, 1.0, 0.0))(p) ≈ -0.15

    hc = Scaled(HyperCube(0.2), Scaling(1.0, 2.0))
    @test origin(hc) == Point(0.0, 0.0)
    @test radius(hc) == Point(0.2, 0.4)
    hc = Translated(hc, Translation(0.3, 0.4))
    @test origin(hc) == Point(0.3, 0.4)
    @test radius(hc) == Point(0.2, 0.4)

    sph = HyperSphere(0.2)
    @test p ∉ sph
    @test zero(P3) ∈ sph
    @test Translated(sph, Translation(0.0, 0.0, 0.0))(p) == sph(p) == 0.8
    @test Translated(sph, Translation(0.05, 1.0, 0.0))(p) ≈ -0.15
    @test p ∈ Translated(sph, Translation(0.05, 1.0, 0.0))

    elps = Ellipsoid(0.2, Scaling(1.0, 2.0, 3.0))
    @test Scaled(sph, Scaling(1.0, 2.0, 3.0)) === elps
    @test elps ≈ Ellipsoid(Point(0.2, 0.4, 0.6))
    @test p ∉ elps
    @test origin(elps) ∈ elps
  end

  @testset "Advanced transforms" begin
    function test_mapping(p1, pres, from, to)
      @test p1 ∈ from
      p2 = tr(p1)
      @test p2 ∈ to
      @test p2 == pres
    end
    from = Translated(HyperCube(1.0), Translation(-5.0, -5.0, -5.0))
    to = Translated(Scaled(HyperCube(2.0), Scaling(2.0, 3.0, 4.0)), Translation(7.0, 7.0, 7.0))
    tr = BoxTransform(from, to)
    test_mapping(origin(from), origin(to), from, to)

    for (p1, pres) in zip(PointSet(from, P3), PointSet(to, P3))
      test_mapping(p1, pres, from, to)
    end
  end

  @testset "Projections" begin
    p = Projection{2}(HyperSphere(HyperSphere(0.0)(Point(0.2, 0.2))))
    @test Point(0.1, 0.1) ∈ p
    @test Point(0.1, 2.0) ∉ p
    @test Point(0.1, 2.0, 0.0) ∉ p
    @test Point(0.1, 0.1, 0.0) ∈ p
    @test Point(0.1, 0.1, 0.1) ∉ p
    @test p(Point(0.2, 0.2)) == 0.0
    @test p(Point(0.2, 0.2, 0.0)) == 0.0
    @test p(Point(0.2, 0.2, 0.5)) == 0.5
    @test p(Point(0.2, 0.2, 0.5, 0.3)) == HyperSphere(0.0)(Point(0.5, 0.3))
  end

  @testset "Point sets" begin
    set = PointSet([Point(0.0, 0.0), Point(1.0, 1.0)])
    @test set == PointSet(Point(0.0, 0.0), Point(1.0, 1.0))
    @test set == PointSet(Point(0, 0.0), Point(1.0f0, 1.0f0))

    set = PointSet([Point(0.0, 0.0), Point(1.0, 0.0), Point(0.0, 1.0), Point(1.0, 1.0)])
    @test centroid(set) == Point(0.5, 0.5)
    @test centroid(set) == centroid(Point(0.0, 0.0), Point(1.0, 0.0), Point(0.0, 1.0), Point(1.0, 1.0))

    set2 = PointSet([Point(0.0, 0.5), Point(0.5, 0.0), Point(0.5, 1.0), Point(1.0, 0.5)])
    @test boundingelement(set) == Translated(Scaled(HyperCube(1.0), Scaling(0.5, 0.5)), Translation(0.5, 0.5))
    @test boundingelement(set) == boundingelement(set2)

    set = PointSet([Point(-1.0, -1.0), Point(1.0, -1.0), Point(-1.0, 1.0), Point(1.0, 1.0)])
    @test boundingelement(set) == Translated(Scaled(HyperCube(1.0), Scaling(1.0, 1.0)), Translation(0.0, 0.0))
    @test Scaling(1.0, 1.0)(set) == set
    @test Translation(0.0, 0.0)(set) == set
    (Scaling(1.0, 1.0) ∘ Translation(0.0, 0.0))(set) == set

    hc = Translated(HyperCube(0.5), Translation(0.5, 0.5, 0.5))
    set = PointSet(hc, P3)
    be = boundingelement(set)
    @test isa(be, Transformed{<:HyperCube})
    @test origin(be) == 0.5 .* ones(P3)
    @test radius(be) == 0.5 .* ones(P3)
    @test all(be.(set) .== 0 .== hc.(set))

    @test PointSet(HyperCube, P2) == PointSet(P2[(-1, -1), (1, -1), (-1, 1), (1, 1)])
    @test PointSet(HyperCube(0.5), P2) == PointSet(P2[(-0.5, -0.5), (0.5, -0.5), (-0.5, 0.5), (0.5, 0.5)])
    @test PointSet(HyperCube, P3) == PointSet(P3[(-1, -1, -1), (1, -1, -1), (-1, 1, -1), (1, 1, -1), (-1, -1, 1), (1, -1, 1), (-1, 1, 1), (1, 1, 1)])

    @testset "Nearest" begin
      set = PointSet([Point(0.0, 1.0), Point(0.5, 0.5), Point(1.0, 0)])
      @test sort_nearest(set, Point(1.0, 0.75)) == set.points[[2, 3, 1]]
    end
  end

  @testset "Curves" begin
    @testset "Bezier curves" begin
      T = Float64
      b = BezierCurve()
      points = P2[(0, 0), (0.5, 1), (1, 0)]
      @test b(T(0), points) == P2(0, 0)
      @test b(T(1), points) == P2(1, 0)
      @test b(T(0.5), points) == P2(0.5, 0.5)
      @test b(T(0.5), points) == P2(0.5, 0.5)
      @test_throws DomainError(T(-0.1), "b(t) is not defined for t outside [0, 1].") b(T(-0.1), points)
      @test_throws DomainError(T(1.2), "b(t) is not defined for t outside [0, 1].") b(T(1.2), points)
    end

    @testset "Patches" begin
      p = Patch(BezierCurve(), 3)
      points = P2[(0, 0), (0.5, 1), (1, 0), (1.5, -1), (2, 0)]
      @test p(0, points) == P2(0, 0)
      @test p(0.25, points) == P2(0.5, 0.5)
      @test p(0.5, points) == P2(1, 0)
      @test p(0.75, points) == P2(1.5, -0.5)
      @test p(1, points) == P2(2, 0)
      @test split(points, p) == [@view(points[1:3]), @view(points[3:5])]
      @test curve_points(p, points) == @view points[1:3]
      @test curve_points(p, points, 1) == @view points[3:5]
    end
  end

  include("granular_vector.jl")

  @testset "Meshes" begin
    # Direct mutation and utilities.

    mesh = quad_mesh()
    @test MeshStatistics(mesh) == MeshStatistics(4, 4, 1)
    face = first(faces(mesh))
    @test centroid(mesh, face) ≈ zero(P2)
    @test centroid(mesh) == centroid(mesh, face)
    @test centroid(mesh, first(edges(mesh))) == P2(0, -1)

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
    @test length(mesh.vertices) == 4 == length(vertices(mesh))
    @test length(mesh.edges) == 5 == length(edges(mesh))
    @test length(mesh.faces) == 2 == length(faces(mesh))
    face = first(mesh.faces)
    @test centroid(mesh, first(mesh.faces)) == centroid(P2[(-1, -1), (1, -1), (1, 1)])
    @test iszero(centroid(mesh))

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
    @test getindex.(cycle, 3) == collect(edges(mesh, f))
    @test union(getindex.(cycle, 1), getindex.(cycle, 2)) == vertices(mesh, f)
    @test all(!, getindex.(cycle, 4))

    mesh = quad_mesh_tri()
    @test ishomogeneous(mesh)
    @test allunique(mesh)
    f1 = first(faces(mesh))
    cycle = collect(edge_cycle(mesh, f1))
    @test getindex.(cycle, 3) == collect(edges(mesh, f1))
    @test union(getindex.(cycle, 1), getindex.(cycle, 2)) == vertices(mesh, f1)
    @test getindex.(cycle, 4) == [false, false, true]

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

    @test MeshStatistics(mesh) == MeshStatistics(subdivide!(quad_mesh(), 5))
    @test ishomogeneous(mesh)
    @test allunique(mesh)
  end

  @testset "Mesh encodings" begin
    strip = TriangleStrip(1:5)
    list = TriangleList([(1, 2, 3), (2, 4, 3), (3, 4, 5)])
    @test TriangleList(strip) == list

    fan = TriangleFan(1:5)
    list = TriangleList([(1, 2, 3), (1, 3, 4), (1, 4, 5)])
    @test GeometryExperiments.primitive_topology(typeof(fan)) == TrianglePrimitive
    @test TriangleList(fan) == list

    @test VertexMesh(P2[(1.2, 1.4), (0.1, 0.2), (0.3, 0.4), (0.5, 0.2)], TrianglePrimitive) isa VertexMesh{<:TriangleStrip,P2}
    @test VertexMesh(fan, P2[(1.2, 1.4), (0.1, 0.2), (0.3, 0.4), (0.5, 0.2)]) isa VertexMesh{<:TriangleFan,P2}

    strip = LineStrip(1:5)
    @test GeometryExperiments.primitive_topology(typeof(strip)) == LinePrimitive
    @test LineList(strip) == LineList([(1, 2), (2, 3), (3, 4), (4, 5)])
  end
end;
