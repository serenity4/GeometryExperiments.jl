gltf_file(filename) = joinpath(pkgdir(GeometryExperiments), "test", "assets", filename)
load_gltf(filename) = GLTF.load(gltf_file(filename))

@testset "GLTF loading" begin
  cube = load_gltf("cube.gltf")
  blob = load_gltf("blob.gltf")

  @testset "Mesh loading" begin
    mesh = VertexMesh(cube)
    @test isa(mesh, VertexMesh{UInt16,<:AbstractArray{Point3f},<:AbstractArray{Point3f}})
    @test nv(mesh) == 24

    mesh = VertexMesh(blob)
    @test isa(mesh, VertexMesh{UInt16,<:AbstractArray{Point3f},<:AbstractArray{Point3f}})
    @test nv(mesh) == 8249
  end

  @testset "Transforms" begin
    tr = Transform(only(cube.nodes))
    @test tr === Transform{3,Float32}()

    light, camera, sphere = blob.nodes

    tr = Transform(light)
    @test tr.translation === Translation{Float32}(4.0256276, 4.5642242, -0.28052378)
    @test tr.rotation ≈ Quaternion{Float32}(0.5232754945755005, -0.28416627645492554, 0.7269423007965088, 0.34203392267227173)
    @test tr.scaling === one(Scaling{3,Float32})

    tr = Transform(camera)
    @test tr.translation === Translation{Float32}(4.1198707, 3.02657, 4.3737516)
    @test tr.rotation ≈ Quaternion{Float32}(0.9214012026786804, -0.17110589146614075, 0.3430515229701996, 0.0637064203619957)
    @test tr.scaling === one(Scaling{3,Float32})

    tr = Transform(sphere)
    @test tr.translation === Translation{Float32}(0.8281484, 0.8672217, 0.32707256)
    @test tr.rotation ≈ zero(Quaternion{Float32})
    @test tr.scaling === one(Scaling{3,Float32})
  end
end;
